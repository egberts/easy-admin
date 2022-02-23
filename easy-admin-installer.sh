
# File: easy-admin-installer.sh
# Title: Create an installer script that handles file permissions
# Description:
#
# Envvars:
#
#    BUILDROOT - scratch build area; if empty, it is an actual install
#    CHROOT_DIR - directory specification to a chroot area
#    FILE_SETTINGS_FILESPEC - output file containing bash file settings script
#
# shellcheck disable=SC2148


###############################################################
# Flexible mkdir()
# Description:
#   Make a directory
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
function flex_mkdir() {

  if [ "${1:0:1}" != "/" ]; then
    echo "flex_mkdir: argument '$1' must be an absolute directory path"
    exit 9
  fi
  # precheck if parent directory exist ... firstly otherwise error-out
  parent_dir="$(dirname "${BUILDROOT}${CHROOT_DIR}${1}")"
  if [ ! -d "$parent_dir" ]; then
    echo "ERROR: Parent directory $parent_dir does not exist."
    echo "ERROR: Unable to create ${BUILDROOT}${CHROOT_DIR}${1} subdirectory."
    exit 9
  fi
  destdir_dirspec="${CHROOT_DIR}${1}"

  # mkdir is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -n "${BUILDROOT}${CHROOT_DIR}" ] ||
     [ $UID -eq 0 ]; then

    if [ ! -d "${BUILDROOT}${CHROOT_DIR}$destdir_dirspec" ]; then
      echo "Creating ${BUILDROOT}${CHROOT_DIR}$destdir_dirspec directory ..."
      mkdir "${BUILDROOT}${CHROOT_DIR}$destdir_dirspec"
    fi
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "mkdir -p $destdir_dirspec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run: mkdir $destdir_dirspec"
  fi
  unset destdir_dirspec
}

###############################################################
# Flexible ckdir()
# Description:
#   Checks if a directory already exist, other create them if in BUILDROOT mode
#   Errors out if directory does NOT exist while in BUILDROOT mode
#
#   No-Op if not in BUILDROOT (root-direct-install) mode as
#   we do not want to tamper with existing OS filesystem directory.
#
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with
#                            file permission settings
#
# Arguments:
#   $1 - absolute directory specification
# Outputs:
#   none
################################################################
function flex_ckdir()
{
  echo "Checking for $1 directory ..."
  if [ -z "$1" ]; then
    echo "Must supply argument; aborted."
    exit 13
  fi
  # If not in BUILDROOT (but are in direct root update) mode
  if [ -z "$BUILDROOT" -o "${BUILDROOT:0:1}" == '/' ]; then
    # Return as No-Op
    return
  fi

  if [ "${1:0:1}" != "/" ]; then
    echo "flex_ckdir: argument '$1' must always be an absolute directory path"
    exit 9
  fi
  # precheck if parent directory exist ... firstly otherwise error-out
  parent_dir="$(dirname "${BUILDROOT}${CHROOT_DIR}${1}")"
  if [ ! -d "$parent_dir" ]; then
    echo "ERROR: Parent directory $parent_dir does not exist."
    echo "ERROR: Unable to create ${BUILDROOT}${CHROOT_DIR}${1} subdirectory."
  fi

  # Check if directory does not exist
  if [ ! -d "${BUILDROOT}${CHROOT_DIR}${1}" ]; then
    # create the subdirectory
    mkdir "${BUILDROOT}${CHROOT_DIR}${1}"
  fi
}

###############################################################
# Flexible chown()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with
#                            file permission settings
# Arguments:
#   $1 - chown file ownership options
#   $2 - absolute directory specification
# Outputs:
#   none
################################################################
function flex_chown() {

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${2}")"

  # chown is driven by no $BUILDROOT and 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
     [ "$UID" -eq 0 ]; then
    chown "$1" "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "chown $1 $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run: chown $1 $destdir_filespec"
  fi
  unset destdir_dirspec
}

###############################################################
# Flexible chmod()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with
#                            file permission settings
# Arguments:
#   $1 - chmod file permission options
#   $2 - absolute directory specification
# Outputs:
#   none
################################################################
function flex_chmod() {

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${2}")"

  # chmod is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
     [ "$UID" -eq 0 ]; then

    echo "chmod $1 to ${BUILDROOT}${CHROOT_DIR}$destdir_filespec ..."
    chmod "$1" "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "chmod $1 $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run chmod $1 $destdir_filespec"
  fi
  unset destdir_dirspec
}

###############################################################
# Flexible touch()
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

function flex_touch() {

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${1}")"

  # touch is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
     [ "$UID" -eq 0 ]; then

    echo "touching ${BUILDROOT}${CHROOT_DIR}$destdir_filespec file ..."
    touch "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "touch $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run touch $destdir_filespec"
  fi
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

function flex_chcon() {

  destdir_filespec="$(realpath -m "${CHROOT_DIR}${2}")"

  # chcon is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
    [ "$UID" -eq 0 ]; then

    selinuxenabled
    retsts=$?
    if [ "$retsts" -eq 0 ]; then

      echo "chmcon system_u:object_r:$1:s0 to ${BUILDROOT}${CHROOT_DIR}$destdir_filespec ..."
      chmod "$1" "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
      chcon "system_u:object_r:${1}:s0" "$destdir_filespec"
    fi
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "chcon $1 $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run chcon $1 $destdir_filespec"
  fi
  unset destdir_dirspec
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
