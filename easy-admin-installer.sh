#
# No hashbang here; I know many distros that do not have /usr/bin/env.
# besides, this is a sourceable-script, not meant to be an direct executable one.
#shellcheck disable=SC2148
#
# File: easy-admin-installer.sh
# Title: Create an installer script that handles files and directories.
# Description:
#
#   The primary focus of this bash library intends to ensure the 
#   proper preservation of file #settings while in non-root user mode.
#
#   This script provides a more flexible `install` tool at bash-level
#   for the Easy-Admin.
#
#   Easy-Admin is design with non-root as the primary user in mind 
#   during installation, not admin nor root.
#
#   Because of this non-root/root separation, file permissions get lost
#   if built locally as a non-root user.
#
#   To preserve proper file settings while as non-root, additional
#   capability has been added to `install` (coreutils) utility.
#
#     1. Moving/appending of files
#     2. File and directory settings like ownership/permissions/context
#
#   This bash library only covers the file and directory settings
#   and 'touch' (empty creating of a file).
#
#   for the following coreutils functions:
#
#     - mkdir
#     - touch
#     - chmod
#     - chown
#     - chcon 
#
# Env vars for all functions:
#
#   BUILDROOT= <dirspec>
#     - relative directory specification (dirspec) - does not
#       begin with a '/' char.
#     - absolute dirspec - does begin with a '/' char.
#     - blank is an hard-error condition
#     - '.' can be used but 'build/' is the preferred method.
#
#   FILE_SETTINGS_FILESPEC= <filespec>
#     - if left undefined or empty, no script will be 
#       generated containing the file-permission-setting 
#       activities.
#     - if defined with a filespec, then file is 
#       created and ready for appending of its file 
#       setting commands being done by various functions
#       in this library.
#
#   FILE_SETTING_PERFORM= true | false
#     - true - actually perform file permission 
#              settings on target file under BUILDROOT;
#              only available in root-mode
#     - false - no file permission settings performed 
#               on target file(s) under BUILDROOT 
#     - default - false
#     - undefined - false
#
#   DRY_RUN= defined to anything
#     - defined - tty-equivalent of FILE_SETTINGS_FILESPEC file output.
#
#              Instead of actual operation of file permission settings,
#              it outputs to the local tty/terminal the commands for
#              file permission settings that is being performed.
#
#              FILE_SETTINGS_FILESPEC file output is not impacted by
#              this option.
#
#              Commonly paired with FILE_SETTINGS_FILESPEC 
#              to check-out various code-logic of security-check 
#              or file-permission-changes.
#
# Build Modes:
#
#   There are three common outcomes of any functions 
#   in this scripts. 
#   
#   1. Non-root build 
#
#     Commonly started with BUILDROOT=`build` as a starting (but 
#     relative) directory point.  Commonly paired with $CHROOT_DIR
#     for a package chroot installation.
#
#     Useful as non-root user to generate file settings script as well
#     as layout the root filesystem under 'build' subdirectory containing
#     installed files and subdirectories (all in user's UID ownership).
#
#     Example settings:
#
#       BUILDROOT='build'   # relative path
#       FILE_SETTINGS_FILESPEC='build/openssh-sshd.conf.settings.sh'
#       FILE_SETTING_PERFORM=false  (most commonly due to UID != $USER)
#
#     Relative BUIDLROOT filespec does NOT begin with a directory separator
#     ('/' char).
#
#     Performs all movement-related functions directly down from 
#     within its current working directory ($CWD)
#
#     WARNING out if FILE_SETTINGS_FILESPEC is not ALSO defined.
#     Think about this, where do we put these missing but
#     correlated file settings?  What good is this library?
#
#     All commands related to file settings functions 
#     (UID/GID/perm/SELinux-context) get separately 
#     appended into a separate file script (specified by 
#     FILE_SETTINGS_FILESPEC).  
#
#     File-setting commands can be also be
#     tty-displayed with VERBOSE or DRY_RUN option.
#
#   2. Impact build - absolute BUILDROOT
#
#     Example settings:
#
#       BUILDROOT='/'   # absolute path
#       FILE_SETTINGS_FILESPEC='build/openssh-sshd.conf.settings.sh'
#       FILE_SETTING_PERFORM=true  # (commonly in root-mode; due to UID != $USER)
#
#   3. Security-Check Settings - any BUILDROOT
#
#     Example settings:
#
#       BUILDROOT='build/my_chroot_test/'   # absolute path
#       FILE_SETTINGS_FILESPEC='build/security-settings.corrective.sh'
#       FILE_SETTING_PERFORM=false
#
# Environment Variables:
#
#     CHROOT_DIR - directory specification to a chroot area
#     ANSI_COLOR - enables colorized log messages
#     DEBUG - turns tracing on and additional outputs
#     LS_COLORS - contains customized ANSI color sets
#
#     No environment variables created nor exported.
#
#  Dependencies, by command:
#    basename (coreutils)
#    chgrp (coreutils)
#    chown (coreutils)
#    chmod (coreutils)
#    chcon (coreutils)
#    cp (coreutils)
#    date (coreutils)
#    dirname (coreutils)
#    echo (bash builtin)
#    flock (util-linux)
#    mkdir (coreutils)
#    printf (coreutils)
#    readlink (coreutils)
#    realpath (coreutils)
#    rm (coreutils)
#    touch (coreutils)
#    whereis (util-linux)
#
#  Dependencies, by generic packages:
#    bash
#    coreutils
#    util-linux
#

# Enable tracing as well, especially after a failed run by prefixing "DEBUG=1 ..."
[ "${DEBUG:-0}" = "1" ] && set -x

#
# For ANSI_COLOR, determine if not a UNIX pipe, user-requested, or
# terminal-supported, in that order.
#
if [ ! -t 1 ]; then
  # then turn off color (even if user overrides, turn them off)
  ANSI_COLOR=
else
  # check if end-user provided ultimate override
  if [ -n "$ANSI_COLOR" ]; then
    ANSI_COLOR="${ANSI_COLOR:-}"
  else
    # check if tty supports color (via LS_COLORS env var)
    if [ -n "$LS_COLORS" ]; then
      ANSI_COLOR=1
    else
      ANSI_COLOR=
    fi
  fi
fi


# POSIX-proof 'echo'
# Avoids accidential passing of '\' or '-n' to POSIX echo statement
# Use myecho function to avoid stomping on variables
myecho () ( z=''; for x; do printf "$z%s\n" "$x"; z=' '; done; )

# Corresponding POSIX-proof 'echo -n'
myecho_no_n () ( z=''; for x; do printf "$z%s" "$x"; z=' '; done; )

# Syntax: critical_section <function_name> [ <arg1> [ <arg2> ... ] ]
# Launch single-thread as a critical section
# A better lock against multiple scripts running at same time
# than to use the 'ps aux | grep -c <script-name>'
# Supports 8 arguments
critical_section()
{
  local b retsts

  # Leverage file descriptior 9 as 'high-enough'
  b=$(basename "$0")
  (
    # expand 'flock -n 9 || exit 1' with error message
    flock -n 9
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "Shell $b already running; Aborted."
      exit 1
    fi
    # call the function argument containing its custom critical section function
    $1
  ) 9> "/var/lock/.empty_lock_file_for_$b"
  # Do not create a full file spec variable to replace this static string+$var
  # because any of a var content may contain just a "/".
  rm "/var/lock/.empty_lock_file_for_$b"
}


###############################################################
# Function: real_dirname_noline
#
#
# Description:
#   A safer replacement to dirname
#
#   Extract a directory name from a given filespec
#   without referencing whether such a directory
#   exist or not
#
#   The '..' subdirectory part gets collapased and
#   resolved.
#
#   Those root '/' directory gets capped at 'root'
#   and not escape any 'chroot' jails even trying
#   things like:
#
#     dirname '/etc/../../../chroot/../../var/../../etc/shadow'
#
#   POSIX basename/dirname do not have --zero/-0 CLI
#   argument option, yet we must eat the leading '\n'
#   somehow, so we do this chomping of this suffix
#   here by adding 'x', then chomping those two
#   characters: '\n' and 'x'.
#
#   Those whitespace(s) (tab or space) in any part of
#   a given directory path must be preserved. (mostly good
#   for Windows folks)
#
#   works in all corner cases of filespec
#   having a whitespace suffix or prefix,
#   or having '.', '..', or '/'.
#
# Syntax: real_dirname_noline <filespec>
#
real_dirname_noline()
{
  local filespec dirspec

  # get full filespec from a simple file
  filespec=${1:A}

  # collapse all '..' and weirdo pathways
  filespec="$(realpath -m -- "$filespec")"

  # POSIX dirname ALWAYS adds '\n', so we must strip that off
  # strip off the basename from the full filespec, then append 'x'
  dirspec="$(dirname -- "${filespec}" ; echo x)"

  # strip off both the '\n' and 'x' from result
  dirspec=${dirspec%??}

  # shorter variant
  # dirspec=$(dirname "$filespec" ; echo x); dirspec=${dirspec%??}
  echo "$dirspec"
}


###############################################################
# Flexible mkdir()
# Description:
#   Makes a directory
#
# Arguments:
#   $1 - absolute directory specification in where to create a directory
#
# Globals:
#   BUILDROOT
#   CHROOT_DIR
#   FILE_SETTING_PERFORM
#   DRY_RUN
#
# Outputs:
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with
#                            file permission settings
################################################################
function flex_mkdir() {
  local parent_dir destdir_dirspec
  if [ -z "$BUILDROOT" ]; then
    echo "flex_mkdir: BUILDROOT env var required; aborted."
    # No, we do not check if CHROOT_DIR is used or not here (they're optional)
    exit 3
  fi

  if [ "${1:0:1}" != "/" ]; then
    echo "flex_mkdir: argument '$1' must be an absolute directory path; aborted."
    exit 9
  fi

  # implicitly, BUILDROOT is defined (by an earlier empty test)
  # CHROOT_DIR is an optional feature and needs no additional testing

  # force the caller to ensure that all parent directory already exists
  # that is the caller's primary job.  We're here just to create one
  # subdirectory given an already created parent directory.
  #
  # precheck if parent directory exist ... firstly otherwise error-out
  parent_dir="$(real_dirname_noline "${BUILDROOT}${CHROOT_DIR}${1}")"
  if [ ! -d "$parent_dir" ]; then
    echo "ERROR: Parent directory $parent_dir does not exist."
    echo "ERROR: Unable to create ${BUILDROOT}${CHROOT_DIR}${1} subdirectory."
    exit 9
  fi
  destdir_dirspec="${CHROOT_DIR}${1}"

  # Now we check if this already exist
  if [ -d "${BUILDROOT}$destdir_dirspec" ]; then
    echo "ERROR: Directory $destdir_dirspec already exist; aborted."
    echo "Usually a coding error."
    exit 15
  fi

  # now for the actual file-settings performance
  if [ "$FILE_SETTING_PERFORM" == 'true' ]; then
    if [ -n "$DRY_RUN" ]; then
      printf "mkdir \"%s\"\n" "${BUILDROOT}$destdir_dirspec"
    else
      # We do no error checking for non-root users, if they errored, they errored.
      mkdir "${BUILDROOT}$destdir_dirspec"
    fi
  fi

  # now for the recording of file-settings performance
  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    if [ -n "$VERBOSE" ]; then
      printf "Recording 'mkdir %s' to %s\n" \
        "${destdir_dirspec}" \
        "$FILE_SETTINGS_FILESPEC"
    fi
    printf "mkdir \"%s\"\n" "${BUILDROOT}$destdir_dirspec" \
        >> "$FILE_SETTINGS_FILESPEC"
  fi
  unset parent_dir destdir_dirspec
}

###############################################################
# Flexible ckdir()
#
# Description:
#   For creating subdirectories under `build`
#   that are already found in a typical
#   root filesystem, such as '/etc', '/var/lib'
#
#   This function is called to provide basic
#   rootfs directories before its package got
#   installed.
#
#   They do not get written into FILE_SETTINGS_FILESPEC
#
#   They do not get performed if BUILDROOT
#   is an absolute dirspec (begins with '/').
#
#   Nor do they appear under dry-run
#
# Arguments:
#   $1 - absolute directory specification
#
# Globals:
#   BUILDROOT
#   CHROOT_DIR
#   FILE_SETTING_PERFORM
#   DRY_RUN
#
# Outputs:
#   None
################################################################
function flex_ckdir()
{
  local parent_dir build_chroot_this_dir

  [[ -n "$VERBOSE" ]] && echo "Checking for a defined $1 argument..."
  if [ -z "$1" ]; then
    echo "Must supply argument; aborted."
    exit 13
  fi
  #if [ "${1:0:1}" != "/" ]; then
  #  echo "flex_ckdir: argument '$1' must always be an absolute directory path"
  #  exit 9
  #fi

  # Checking BUILDROOT for correctness
  if [ -n "$BUILDROOT" ]; then
    if [ "${BUILDROOT:0:1}" == '/' ]; then
      echo "WARNING: BUILDROOT is targeting current '/' root file system"
    else
      if [ "${BUILDROOT: -1:1}" == '/' ]; then
        echo "ERROR: BUILDROOT has terminating '/', remove it"
        exit 3
      fi
    fi
  fi

  # Checking CHROOT_DIR for correctness
  if [ -n "$CHROOT_DIR" ]; then
    if [ "${CHROOT_DIR:0:1}" == '/' ]; then
      echo "ERROR: CHROOT_DIR does not start with '/'; remove it."
      exit 9
    else
      if [ "${BUILDROOT: -1:1}" != '/' ]; then
        echo "ERROR: CHROOT_DIR does not end with '/'; add it."
        exit 3
      fi
    fi
  fi

  build_root_this_dir="${BUILDROOT}${CHROOT_DIR}$1"

  # If absolute, tread gently
  if [ "${BUILDROOT:0:1}" == '/' ]; then
    # Used to be No-Op but now we check if the host RootFS already has 
    # these directories, and probably should error out if these
    # directory are not there as expected by this security-script/library
    if [ ! -d "$build_root_this_dir" ]; then
      echo "OS system ${build_root_this_dir} is missing; aborted."

      # If the package is not installed, we have no business recreating directories
      exit 9  # make this a warning at first???
    fi
  else
    # At this point, we are in "relative" 'build/' BUILDROOT mode.
    # All directories that are being created are under this directory

    # precheck if parent directory exist ... firstly otherwise error-out
    parent_dir="$(real_dirname_noline "$build_root_this_dir")"
    if [ ! -d "$parent_dir" ]; then
      echo "ERROR: Parent directory '${parent_dir}' does not exist."
      echo "ERROR: Unable to create '${build_root_this_dir}' subdirectory."
      # So far, we are not making this an error due to passive checking scripts
    fi

    # Check if the requested directory does not exist
    if [ ! -d "$build_root_this_dir" ]; then
      [[ -n "$VERBOSE" ]] && echo "mkdir $build_root_this_dir"

      # create the subdirectory
      mkdir "$build_root_this_dir"
      # no need to dry-run here
    else
      # If this directory already exist, skip it silently
      [[ -n "$VERBOSE" ]] && echo "skipping mkdir $build_root_this_dir; already exist"
    fi
  fi

  # No need to output to FILE_SETTINGS_FILESPEC (it should already be a part of host)
  unset parent_dir build_chroot_this_dir
}

###############################################################
# Flexible chown()
# Description:
#   Change file owner/group
#
# Arguments:
#   $1 - file owner/group name, separated by a colon (':') symbol
#   $2 - file specification of the file whose owner/group needs changing
#
# Globals:
#   BUILDROOT
#   CHROOT_DIR
#   FILE_SETTING_PERFORM
#   DRY_RUN
#
# Outputs:
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with
#                            file permission settings
################################################################
function flex_chown() 
{
  local destdir_filespec

  if [ -z "$BUILDROOT" ]; then
    echo "flex_chown: BUILDROOT env var required; aborted."
    # No, we do not check if CHROOT_DIR is used or not here (they're optional)
    exit 3
  fi

  if [ "${2:0:1}" != "/" ]; then
    echo "flex_chown: argument '$1' must be an absolute directory path; aborted."
    exit 9
  fi

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${2}")"

  # now for the actual file-settings performance
  if [ "$FILE_SETTING_PERFORM" == 'true' ]; then
    # Now do it without the BUILDROOT (as the script will be run at a later time)
    if [ -n "$DRY_RUN" ]; then
      printf "chown %s \"%s\"\n" "${1}" "$destdir_filespec"
    else
      # We do no error checking for non-root users, if they errored, they errored.
      chown $1 "$destdir_filespec"
    fi
  fi

  # now for the recording of file-settings performance
  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    if [ -n "$VERBOSE" ]; then
      printf "Recording 'chown %s %s' to %s\n" \
        "${1}" \
        "${destdir_filespec}" \
        "$FILE_SETTINGS_FILESPEC"
    fi
    # Record command but without BUILDROOT
    printf "chown %s \"%s\"\n" "$1" "$destdir_filespec" \
        >> "$FILE_SETTINGS_FILESPEC"
  fi
  unset destdir_filespec
}

###############################################################
# Flexible chmod()
# Description:
#   Change file mode bits
#
# Arguments:
#   $1 - file mode bits (octal or symbolic mode)
#   $2 - file specification of the file whose file mode bits need changing
#
# Globals:
#   BUILDROOT
#   CHROOT_DIR
#   FILE_SETTING_PERFORM
#   DRY_RUN
#
# Outputs:
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file to
#                            contain file mode bits settings
################################################################
function flex_chmod()
{
  local destdir_filespec

  if [ -z "$BUILDROOT" ]; then
    echo "flex_chmod: BUILDROOT env var required; aborted."
    # No, we do not check if CHROOT_DIR is used or not here (they're optional)
    exit 3
  fi

  if [ "${2:0:1}" != "/" ]; then
    echo "flex_chmod: argument '$1' must be an absolute directory path; aborted."
    exit 9
  fi

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${2}")"

  # now for the actual file-settings performance
  if [ "$FILE_SETTING_PERFORM" == 'true' ]; then
    if [ -n "$DRY_RUN" ]; then
      printf "chmod %s \"%s\"\n" "${1}" "$destdir_filespec"
    else
      # We do no error checking for non-root users, if they errored, they errored.
      chmod $1 "$destdir_filespec"
    fi
  fi

  # now for the recording of file-settings performance
  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    if [ -n "$VERBOSE" ]; then
      printf "Recording 'chmod %s %s' to %s\n" \
        "${1}" \
        "${destdir_filespec}" \
        "$FILE_SETTINGS_FILESPEC"
    fi
    printf "chmod %s \"%s\"\n" "$1" "$destdir_filespec" \
        >> "$FILE_SETTINGS_FILESPEC"
  fi
  unset destdir_filespec
}

###############################################################
# Flexible touch()
#
# Description:
#   Touch filestamp; create a file, if it did not exist
#
# Arguments:
#   $1 - file specification of the file whose access and modification
#        time needs updating.  If the file does not exist, one is 
#        created (or recorded as created).
#
# Globals:
#   BUILDROOT
#   CHROOT_DIR
#   FILE_SETTING_PERFORM
#   DRY_RUN
#
# Outputs:
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file to
#                            contain file mode bits settings
################################################################

function flex_touch() 
{
  local destdir_filespec

  if [ -z "$BUILDROOT" ]; then
    echo "flex_touch: BUILDROOT env var required; aborted."
    # No, we do not check if CHROOT_DIR is used or not here (they're optional)
    exit 3
  fi

  if [ "${1:0:1}" != "/" ]; then
    echo "flex_touch: argument '$1' must be an absolute directory path; aborted."
    exit 9
  fi

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${1}")"

  # now for the actual file-settings performance
  if [ "$FILE_SETTING_PERFORM" == 'true' ]; then
    if [ -n "$DRY_RUN" ]; then
      printf "touch %s\n" "$destdir_filespec"
    else
      # We do no error checking for non-root users, if they errored, they errored.
      touch "$destdir_filespec"
    fi
  fi

  # now for the recording of file-settings performance
  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    if [ -n "$VERBOSE" ]; then
      printf "Recording 'touch %s' to %s\n" \
        "${destdir_filespec}" \
        "$FILE_SETTINGS_FILESPEC"
    fi
    printf "touch %s\n" "$destdir_filespec" \
        >> "$FILE_SETTINGS_FILESPEC"
  fi
  unset destdir_filespec
}

###############################################################
# Flexible flex_chcon()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with
#                            file permission settings
# Arguments:
#   $1 - absolute directory specification
# Outputs:
#   none
################################################################

function flex_chcon() 
{
  local destdir_filespec

  if [ -z "$BUILDROOT" ]; then
    echo "flex_chmod: BUILDROOT env var required; aborted."
    # No, we do not check if CHROOT_DIR is used or not here (they're optional)
    exit 3
  fi

  if [ "${2:0:1}" != "/" ]; then
    echo "flex_chmod: argument '$1' must be an absolute directory path; aborted."
    exit 9
  fi

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${2}")"

  # now for the actual file-settings performance
  if [ "$FILE_SETTING_PERFORM" == 'true' ]; then
    if [ -n "$DRY_RUN" ]; then
      printf "chcon system_u:object_r:%s:s0 to %s ...\n" \
            "${1}" "$destdir_filespec"
    else
      # We do no error checking for non-root users, if they errored, they errored.
      selinuxenabled
      retsts=$?
      if [ "$retsts" -ne 0 ]; then
        chcon "system_u:object_r:${1}:s0" "$destdir_filespec"
      fi
    fi
  fi

  # now for the recording of file-settings performance
  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    if [ -n "$VERBOSE" ]; then
      printf "Recording 'chcon system_u:object_r:%s:s0 %s' to %s ...\n" \
        "${1}" \
        "${destdir_filespec}" \
        "$FILE_SETTINGS_FILESPEC"
    fi
    printf "chcon system_u:object_r:%s:s0 %s\n" \
            "${1}" "$destdir_filespec" \
        >> "$FILE_SETTINGS_FILESPEC"
  fi
  unset destdir_filespec
}

# Wanted:
#   find_first_line
#   find_same_lines
#   append_line    - append line to a file
#   replace_line   - replace a specific line with a line into a file

# function find_first_line()
# {
# }

# function find_same_lines()
# {
# }

# function append_line()
# {
# }

# function replace_line()
# {
# }

