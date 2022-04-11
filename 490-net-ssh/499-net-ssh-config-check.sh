#!/bin/bash
# File: 499-net-ssh-config-check.sh
# Title: Check for secured settings in OpenSSH configs
#
# Description:
#   Basic limitation of this checker script is that
#   binaries are not under relative $BUILDROOT.
#
#   This script is focused on correctness of SSH 
#   settings anywhere (relative or absolute $BUILDROOT)
#
#   Given that, current SSH-related binaries (first
#   found in $PATH) shall be used for syntax-checking of 
#   SSH settings found under relative $BUILDROOT.
#
# Usage:
#   499-net-ssh-config-check.sh
#          [ -t <BUILDROOT> ]
#          [ -t <chroot-dir> ]
#          [ <sshd_conf-filespec> [ <ssh_conf-filespec> ] ]
#
#      -b : optional BUILDROOT path (default is '/'). Overrides
#           BUILDROOT envvar
#      -t : optional top-level directory path to chroot directory.
#           Overrides CHROOT_DIR envvar
#
# TODO:
#
# Environment variables
#   BUILDROOT
#   CHROOT_DIR
#   SSH_HOME_DIRSPEC

echo "Checking security of OpenSSH configs"
echo

default_buildroot='build'
default_chroot_dir=''

function cmd_show_syntax_usage {
    cat << USAGE_EOF
Usage:  $0
    [-v|--verbose]
    [[-b|--build-root=] <BUILDROOT> ]
    [[-t|--chroot-dir=] <chroot-dir> ]
    [ <sshd_conf-filespec> [ <ssh_conf-filespec> ] ]

  -b : optional BUILDROOT path (default is '/'). Overrides
       BUILDROOT envvar
  -t : optional top-level directory path to chroot directory.
       Overrides CHROOT_DIR envvar
USAGE_EOF
}

function sshd_syntax_check()
{
  if [ "$SUDO_REQUIRED_SSHD" -ge 1 ]; then
    SUDO_BIN="/usr/bin/sudo"
    exit
  fi

  # Fake generate throwaway host key for syntax-checking effort
  temp_throwaway_key="fake-ssh-keys-$USER.key"
  ssh-keygen \
    -t ed25519 \
    -f "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}" \
    -q \
    -N ""

  # Check syntax of sshd_config/sshd_config.d/*.conf, et. al.
  echo "Checking sshd_config syntax ..."
  $SUDO_BIN /usr/sbin/sshd -T -t \
    -f "${BUILDROOT}${SSHD_CONFIG_FILESPEC}" \
    -o ChrootDirectory="${BUILDROOT}${CHROOT_DIR}/" \
    -h "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}" \
    >/dev/null 2>&1
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error during ssh config syntax checking."
    echo "Showing sshd_config output"
    $SUDO_BIN /usr/sbin/sshd \
      -T \
      -t \
      -f "${BUILDROOT}${SSHD_CONFIG_FILESPEC}" \
      -o ChrootDirectory="${BUILDROOT}${CHROOT_DIR}/" \
      -h "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}"
    rm "${BUILDROOT}${CHROOT_DIR}/$temp_throwaway_key"
    rm "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}.pub"
    exit "$retsts"
  fi
  echo "${BUILDROOT}$SSHD_CONFIG_FILESPEC passes syntax-checker."
  echo
  rm "${BUILDROOT}${CHROOT_DIR}/$temp_throwaway_key"
  rm "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}.pub"
}


# Call getopt to validate the provided input.
options=$(getopt -o b:ht:vV \
          --long build:,help,chroot-dir:,verbose,version -- "$@" )
RETSTS=$?
[[ ${RETSTS} -eq 0 ]] || {
    echo "Incorrect options provided"
    cmd_show_syntax_usage
    exit ${RETSTS}
}

CHROOT_DIR="${CHROOT_DIR:-}"
VERBOSITY=0

eval set -- "${options}"
while true; do
    case "$1" in
    -b|--buildroot)
        shift;  # The arg is next in position args
	[[ -n "$VERBOSE" ]] && echo "BUILDROOT=$1 (was $BUILDROOT)"
        BUILDROOT=$1  # deferred argument checking
        ;;
    -t|--chroot-dir)
        shift;  # The arg is next in position args
	[[ -n "$VERBOSE" ]] && echo "CHROOT_DIR=$1 (was $CHROOT_DIR)"
        CHROOT_DIR=$1  # deferred argument checking
        sshd_opt="-t $CHROOT_DIR"
        ;;
    -v|--verbose)
        ((VERBOSITY=VERBOSITY+1))
        readonly VERBOSITY
        ;;
    -V|--version)
        echo "$0: version TBA"
        exit 0
        ;;
    -h|--help)
        cmd_show_syntax_usage
        break
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

# Check user options (passive)

if [ -z "$BUILDROOT" ]; then
  BUILDROOT="$default_buildroot"
fi
if [ -z "$default_chroot_dir" ]; then
  CHROOT_DIR="$default_chroot_dir"
fi

if [ -n "$VERBOSE" ]; then
  echo "BUILDROOT: $BUILDROOT"
  echo "CHROOT_DIR: $CHROOT_DIR"
  echo "VERBOSE: $VERBOSE"
fi


# Check end-user's environment for test suitability
#
# Check end-user if non-root, print warning
if [ $EUID -ne 0 ]; then
  echo "WARN: User $UID is not root; "
  echo "Will try and test for OpenSSH securedness as '${USER}'"
  echo "Will never execute any 'sudo'/'su'"
  echo
fi


# There are two orthogonal parts to security checking
#   1. file permission
#   2. end-user allowability of using SSH client
#

echo "Checking against BUILDROOT=$BUILDROOT directory ..."
FILE_SETTING_PERFORM=false   # we are not changing anything
FILE_SETTINGS_FILESPEC=''
# Leaving FILE_SETTINGS_FILESPEC empty will ignore a lot of things
# Leaving FILE_SETTING_PERFORM as false

source ./maintainer-ssh-openssh.sh


# Check user arguments (passive)

if [ -z "${2}" ]; then
  this_ssh_config_filespec="$SSH_CONFIG_FILESPEC"
else
  this_ssh_config_filespec="$2"
fi
if [ -z "${1}" ]; then
  this_sshd_config_filespec="$SSHD_CONFIG_FILESPEC"
else
  this_sshd_config_filespec="$1"
fi

# check that all basic rootfs dirs are there
rootfs_dirs_list="$ETC_DIRSPEC $VAR_DIRSPEC $VAR_LIB_DIRSPEC "
rootfs_dirs_list+="$VAR_LIB_SSH_DIRSPEC "
for this_rootfs_dir in $rootfs_dirs_list; do
  if [ ! -d "${BUILDROOT}${CHROOT_DIR}$this_rootfs_dir" ]; then
    echo "Directory '${BUILDROOT}${CHROOT_DIR}$this_rootfs_dir' does not exist."
    exit 9
  fi
done

#
# Check for package install via package-specific rootfs-related subdirs
#
# Check ssh directory accessibility before anything

if [ ! -d "${BUILDROOT}${CHROOT_DIR}$extended_sysconfdir" ]; then
  echo "OpenSSH config '${BUILDROOT}${CHROOT_DIR}${extended_sysconfdir}' is not a directory; aborted."
  exit 9
fi

if [ ! -r "${BUILDROOT}${CHROOT_DIR}$extended_sysconfdir" ]; then
  echo "OpenSSH config '${BUILDROOT}${CHROOT_DIR}${extended_sysconfdir}' is not accessible; aborted."
  exit 9
fi

# Check ssh config files (passive)

# ssh_config may still be behind group/file-permission 
# but we merely check for a file
if [ ! -f "${BUILDROOT}${CHROOT_DIR}$this_ssh_config_filespec" ]; then
  echo "SSH config '${BUILDROOT}${CHROOT_DIR}${this_ssh_config_filespec}' file does not exist; aborted."
  exit 9
fi

# sshd_config may still be behind group/file-permission 
# but we merely check for a file
if [ ! -f "${BUILDROOT}${CHROOT_DIR}$this_sshd_config_filespec" ]; then
  echo "SSHD config '${BUILDROOT}${CHROOT_DIR}${this_sshd_config_filespec}' does not exist; aborted."
  exit 9
fi

# Probably should have 'source distro-package-specific' scripting go here
# Needs to deal with 'DEFAULT_ETC_CONF_DIRNAME' there.
# libdir and $HOME are three separate grouping (that Fedora, et. al. merged)

[[ -n "$VERBOSE" ]] && echo "VAR_LIB_SSH_DIRSPEC: $sshd_home_dirspec"

EXPECTED_SSH_SHELL_FILESPEC="/usr/sbin/nologin"
if [ -z "$SSH_SHELL_FILESPEC" ]; then
  SSH_SHELL_FILESPEC="$(grep $SSH_USER_NAME /etc/passwd | awk -F: '{print $7}')"
fi

# $HOME is always treated separately from /etc directory; 
#
if [ -z "$SSH_HOME_DIRSPEC" ]; then
  SSH_HOME_DIRSPEC="$(grep $SSH_USER_NAME /etc/passwd | awk -F: '{print $6}')"
fi
SSH_HOME_DIRSPEC="$sshd_home_dirspec"


# SSH_BIN_GROUP
# SSH_BIN_FILESPEC
# SSHD_BIN_GROUP
# SSHD_BIN_FILESPEC

if [ -n "$VERBOSE" ]; then
  echo "Using 'sshd' binary in: $SSHD_BIN_FILESPEC"
  echo "Using 'ssh' binary in: $SSH_BIN_FILESPEC"
fi


# Identify config files

##################################################################

if [ ! -f "$SSH_CONFIG_FILESPEC" ]; then
  # might be hidden or suppressed by file permission, go sudo
  # might be a split horizon, sshd.conf could have gone sshd-*.conf
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "OK, we found the $SSH_CONFIG_FILESPEC file but it requires SUDO operation."
    echo "to read it.  Rest of this script will use SUDO but for read-only operation."
    echo "...Alternatively, you can copy the configs to /tmp or set all"
    echo "...file permission to world-read."
    echo "No changes shall be made."
  else
    read -rp "Enter in SSH config file: " -ei${SSH_CONFIG_FILESPEC}
    if [ ! -f "$REPLY" ]; then
      echo "No such file: $REPLY"
      echo "Aborted."
      exit 111
    fi
    SSH_CONFIG_FILESPEC="$REPLY"
  fi
fi

# Find all config files, by chasing the 'include' clauses
#
# sshd-checkconf -p -x # can do all that collating of include files,
# but it already stripped out the include clauses leaving us with no
# clue as to what its filespec of these include clauses are so that
# approach is useless.
#
# This is CIS; we must validate file permissions on all
# files, and this includes the include clauses and their respective file.

function find_include_clauses
{
  local val
  local filespec="$1"
  [[ -n "$VERBOSE" ]] && echo "Begin scanning for 'include' clauses..."
  val="$($sudo_bin cat "$filespec" | grep -E -- "^\s*[\s\{]*\s*include\s*")"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  val="$(echo "$val" | xargs)"
  CONFIG_VALUE="$val"
  unset val filespec
}

# make a list of all configuration files using 'include' clause as a
# search extender
sshd_config_files_list=
config_file="${BUILDROOT}${CHROOT_DIR}$SSHD_CONFIG_FILESPEC"
find_include_clauses  "${config_file}"
if [ -n "$CONFIG_VALUE" ]; then
  SSHD_CONFIG_FILE_MODE='split-file'
else
  SSHD_CONFIG_FILE_MODE='standalone'
fi
sshd_config_files_list="$config_file $CONFIG_VALUE"

ssh_config_files_list=
config_file="${BUILDROOT}${CHROOT_DIR}$SSH_CONFIG_FILESPEC"
find_include_clauses  "${config_file}"
if [ -n "$CONFIG_VALUE" ]; then
  SSH_CONFIG_FILE_MODE='split-file'
else
  SSH_CONFIG_FILE_MODE='standalone'
fi
ssh_config_files_list="$config_file $CONFIG_VALUE"

# For SSH server, Reconstruct a entire configuration 
# file by including all configuration files mentioned 
# by its 'include' clause using 'ssh -G -F'
echo
echo "SSHD (Server) Config File(s) Layout: $SSHD_CONFIG_FILE_MODE"
echo "Reading in ${BUILDROOT}${CHROOT_DIR}$SSHD_CONFIG_FILESPEC ..."
# Capture non-STDERR output of ssh, if any
# shellcheck disable=SC2086
sshd_conf_all_includes="$($SSHD_BIN_FILESPEC $sshd_opt -t -T -d -f "$SSHD_CONFIG_FILESPEC" 2>/dev/null)$"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "User '${USER}(${UID})' has no read-access to $SSHD_CONFIG_FILESPEC; errno $RETSTS"
  # capture only STDERR output of sshd-checkconf
  # shellcheck disable=SC2086
  errmsg="$($SSHD_BIN_FILESPEC $sshd_opt -t -T -d -f "$SSHD_CONFIG_FILESPEC")"
  echo "Need to fix error in $SSHD_CONFIG_FILESPEC before going further"
  echo "CLI: $SSH_BIN_FILESPEC $sshd_opt -G -F $SSHD_CONFIG_FILESPEC localhost"
  echo "Error code: $RETSTS"
  echo "Error message: $errmsg"
  exit $RETSTS
fi
echo "Content of $SSHD_CONFIG_FILESPEC Syntax OK."
echo

echo "SSH (Client) Config File(s) Layout: $SSH_CONFIG_FILE_MODE"
echo "Reading in ${BUILDROOT}${CHROOT_DIR}$SSH_CONFIG_FILESPEC ..."
# Capture non-STDERR output of ssh, if any
# shellcheck disable=SC2086
ssh_conf_all_includes="$($SSH_BIN_FILESPEC $ssh_opt -G -F "$SSH_CONFIG_FILESPEC" localhost 2>/dev/null)$"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "User '${USER}(${UID})' has no read-access to $SSH_CONFIG_FILESPEC; errno $RETSTS"
  # capture only STDERR output of ssh
  # shellcheck disable=SC2086
  errmsg="$($SSH_BIN_FILESPEC $ssh_opt -G -F "$SSH_CONFIG_FILESPEC" localhost )"
  echo "Need to fix error in $SSH_CONFIG_FILESPEC before going further"
  echo "CLI: $SSH_BIN_FILESPEC $ssh_opt -G -F $SSH_CONFIG_FILESPEC localhost"
  echo "Error code: $RETSTS"
  echo "Error message: $errmsg"
  exit $RETSTS
fi
echo "Content of $SSH_CONFIG_FILESPEC Syntax OK."
echo

# Typically, when sshd shell switches user, current directory switches to new $HOME
cwd_dir="$SSHD_HOME_DIRSPEC"

# Now for the many default settings
DEFAULT_LOCKFILE_DIRNAME="$rundir/sshd"
DEFAULT_LOCKFILE_FILENAME="sshd.lock"
DEFAULT_PIDFILE_DIRNAME="$rundir/sshd"  # sshd/config.c/defaultconf
DEFAULT_PIDFILE_FILENAME="sshd.pid"  # sshd/config.c/defaultconf

# Some settings which might be wiped-out by sshd.conf, selectively.
pidfile_filespec="${DEFAULT_PIDFILE_DIRNAME}/$DEFAULT_PIDFILE_FILENAME"


# start extracting entire directories
function dir_exist
{
  if [ ! -d "$1" ]; then
    echo "Directory does not exist: $1"
    echo "Aborted"
    exit 254
    RETSTS=9
  fi
}

function its_dir_exist
{
  if [ ! -d "$(dirname "$1")" ]; then
    echo "Holding Directory does not exist: $(dirname "$1")"
    echo "Aborted"
    exit 254
  fi
}


# in case of split-horizon bastion
#sshd_home="$cwd_dir"

function search_sshd_keyvalue()
{
  keyword="${1,,}"
  KEYVALUE="$(sudo $SSHD_BIN_FILESPEC -t -T -f "$SSHD_CONFIG_FILESPEC" \
              | grep -E "^${keyword}\s+" \
              | awk -F' ' '{print $2}')"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error in grep; errno $retsts"
    exit $retsts
  fi
}

# Get DenyUsers
search_sshd_keyvalue DenyUsers
deny_users="$KEYVALUE"
search_sshd_keyvalue AllowUsers
allow_users="$KEYVALUE"
search_sshd_keyvalue DenyGroups
deny_groups="$KEYVALUE"
search_sshd_keyvalue AllowGroups
allow_groups="$KEYVALUE"

# Pick up all the host_key files
####hostkeys_list="$(ls -1 ${BUILDROOT}${CHROOT_DIR}${extended_sysconfdir}/ssh_host_* \
hostkeys_list="$(ls -1 ${extended_sysconfdir}/ssh_host_* \
                 | grep -Ev '.pub$' \
                 | xargs )"

# List the host_key files actually used by SSHD
search_sshd_keyvalue HostKey
hostkeys_used_list="$(echo "$KEYVALUE" | xargs)"

printf "Version: %s\n" "$($SSH_BIN_FILESPEC -V 2>&1)"
echo "'sshd' \$HOME:  $SSHD_HOME_DIRSPEC"
echo "Binary Path:"
echo "  Server     : $SSHD_BIN_FILESPEC"
echo "  Client     : $SSH_BIN_FILESPEC"
echo "  Shell      : $SSH_SHELL_FILESPEC"
if [ "$SSH_SHELL_FILESPEC" != "$EXPECTED_SHELL_FILESPEC" ]; then
  echo 'nologin' is BSD, but various Linux distros have broken nologin away 
  echo from the BSD 'shadow' package. 
  echo There are five 'nologin' variants out there...  we probably need the ones
  echo "that properly logs to LOG_CONSOLE|LOG_AUTH|LOG_CRIT (which is BSD shadow)"
  echo to comply with basic auditing/CISecurity and record all SSH activities
  echo It is tough to check the auditing aspect of an unknown 'nologin' w/o source code
  echo and the only other way is by actual demonstration and observation in audit logs.
fi
echo
echo "Group File Permissions Policy"
echo "  SSHD daemon  : $SSHD_GROUP_NAME"
if [ 'root' == "$SSH_GROUP_NAME" ]; then
  echo "WARN: generic SSHD group name;"
  echo "INFO: create a unique group ID/name for SSH daemon"
fi
echo "  Inbound SSH  : $allow_groups"
echo "  Outbound SSH : $SSH_GROUP_NAME"
if [ "$allow_groups" == "$SSH_GROUP_NAME" ]; then
  echo "WARN: No security granularity between inbound and outbound SSH connection."
fi
# InboundSSH != OutboundSSH
echo
echo "Inbound Policy"
echo "  Deny Users   : $deny_users"
echo "  Allow Users  : $allow_users"
echo "  Deny Groups  : $deny_groups"
echo "  Allow Groups : $allow_groups"
echo
echo "Server config files:  $sshd_config_files_list"
echo "Server hostkey files: $hostkeys_used_list"
# hostkeys_used_list is the final absolute filespec inside a config file
# hostkeys_list is the slippery BUILDROOT within this script
# recouncil the two together somehow:  strip BUILDROOT or tack-on BUILDROOT?
# try strip
# instead of doing a combinatorial double-loop through a two-list
# we could reduce a list (without a BUILDROOT) into a new list then
# do a direct two-list compare
if [ "$hostkeys_used_list" != "$hostkeys_list" ]; then
  echo WARN: remove unused hostkey files
  echo INFO: refer to 'HostKey' in sshd_config, et. al.
  echo "INFO: Some files are: $hostkeys_list"
fi
echo "Client config files:  $ssh_config_files_list"
echo
echo "SELinux sshd_var_run_t group:"
echo "PID file:     $pidfile_filespec"
echo
# Testing all directories for its file permission and file ownership settings


total_files=0
total_file_missings=0
total_file_errors=0
total_perm_errors=0

function file_perm_check
{
  ((total_files+=1))
  local filespec expected_fmod expected_groupname expected_username varnam
  varnam=$1
  # shellcheck disable=SC2086
  eval filespec=\$$1
  $sudo_bin ls -1 "$filespec" >/dev/null 2>&1
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "...skipping unused $filespec ($varnam)."
    ((total_file_missings+=1))
  else
    local err_per_file msg_a this_fmod this_username this_groupname
    expected_fmod=$2
    expected_username=$3
    expected_groupname=$4
    err_per_file=0
    msg_a=()
    this_fmod="$($sudo_bin stat -c%a "$filespec")"
    this_username="$($sudo_bin stat -c%U "$filespec")"
    this_groupname="$($sudo_bin stat -c%G "$filespec")"
    if [ "$expected_fmod" != "$this_fmod" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_fmod' file permission"
      ((total_perm_errors+=1))
      ((err_per_file+=1))
    fi
    if [ "$expected_username" != "$this_username" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_username' username"
      ((total_perm_errors+=1))
      ((err_per_file+=1))
    fi
    if [ "$expected_groupname" != "$this_groupname" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_groupname' group name"
      ((total_perm_errors+=1))
      ((err_per_file+=1))
    fi
    echo -n "$this_fmod $this_username:$this_groupname ($varnam) $filespec: "
    if [ "$err_per_file" -eq 0 ]; then
      echo " ok."
    else
      echo " ERROR"  # new line
      idx=0
      while [ "$idx" -lt "$err_per_file" ]; do
        echo "${msg_a[$idx]}"
        ((idx+=1))
      done
      ((total_file_errors+=1))
    fi
    unset err_per_file
  fi
  unset filespec expected_fmod expected_groupname expected_username varnam
}

echo
read -rp "Ubuntu 20+, CISecurity, or Maximum Security settings? (u/c/M): " -eiM
REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"

case $REPLY in
  'm')
    echo "Maximum security settings..."
    if [ $EUID -ne 0 ]; then
      echo "Re-run $0 in 'sudo'; aborted."
      exit 13
    fi

    file_perm_check EXPECTED_SSH_SHELL_FILESPEC "755" "root" "root"

    # SELinux Entrypoint
    # SELinux ssh_exec_t
    file_perm_check SSH_BIN_FILESPEC "750" "root" "$SSH_GROUP_NAME"
    NM_SSH_SERVICE='/usr/libexec/nm-ssh-service'
    file_perm_check NM_SSH_SERVICE "750" "root" "$SSHD_GROUP_NAME"

    # Float the $HOME based on sshd /etc/passwd entry (no expectation)
    file_perm_check SSHD_HOME_DIRSPEC "775" "root" "$SSHD_GROUP_NAME"
    file_perm_check SSHD_BIN_FILESPEC "750" "root" "$SSHD_GROUP_NAME"


    # SELinux Process type

    # SELinux ssh_net_t
    # file_perm_check memstatistics_filespec "640" "root" "$GROUP_NAME"

    # to allow host key based authentication, you 
    # must turn on the 'ssh_keysign' boolean. 
    # Disabled by default
    # SELinux ssh_keysign_t

    for this_config_file in $sshd_config_files_list; do
      file_perm_check this_config_file "640" "root" "$SSHD_GROUP_NAME"
    done
    for this_config_file in $ssh_config_files_list; do
      file_perm_check this_config_file "640" "root" "$SSH_GROUP_NAME"
    done


    # SELinux ssh_keygen_t
    # SELinux sshd_keygen_t
    # file_perm_check BINDKEY "644" "root" "root"

    # SELinux ssh_sandbox_t


    # sshd public-part of key file shall be world-read for general 
    # inspection of file permissions
    file_perm_check VAR_RUN_SSHD_DIRSPEC "755" "root" "$SSHD_GROUP_NAME"
    file_perm_check pidfile_filespec "644" "$SSHD_USER_NAME" "$SSHD_GROUP_NAME"
    if [ ! -f "$pidfile_filespec" ]; then
      echo "WARN: PID file not found; make sure it is in the correct 'sshd' subdir."
    fi
  ;;

  'c')
    echo "Recommended CIS settings..."
    echo "There isn't any; so this one is TBA"
    ;;

  # Fedora
  'u')
    echo "Ubuntu 20 default settings..."
    echo "There isn't any; so this one is TBA"
    ;;

esac

printf "Permission errors: %3d\n" "$total_perm_errors"
printf "Total files      : %3d\n" "$total_files"
printf "File missing     :     %3d\n" "$total_file_missings"
printf "Skipped files    :     %3d\n" "$total_file_errors"

