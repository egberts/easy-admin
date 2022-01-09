#!/bin/bash
# File: 499-cis-net-ssh-openssh.sh
# Title: Check file permissions of various files in OpenSSH
#
# Description:
# Usage:
#   499-cis-net-ssh-openssh.sh
#          [ -t <chroot-dir> ] 
#          <sshd_conf-filespec> <ssh_conf-filespec>
#
#      -t : optional top-level directory path to chroot directory
#
# TODO:
#
# Environment variables
#   NAMED_HOME_DIRSPEC

echo "Checking file permissions/ownership/security-context for "
echo "OpenSSH server/client/key/agent"
echo

function cmd_show_syntax_usage {
    cat << USAGE_EOF
Usage:  $0
	[-t|--chroot-dir <chroot-dir>] \
        [ --help|-h ] [ --verbosity|-v ]
        < named.conf-filespec >
USAGE_EOF
  exit 1
}

# Call getopt to validate the provided input.
options=$(getopt -o ht:vV \
          --long help,chroot-dir:,verbose,version -- "$@" )
RETSTS=$?
[[ ${RETSTS} -eq 0 ]] || {
    echo "Incorrect options provided"
    cmd_show_syntax_usage
    exit ${RETSTS}
}

CHROOT_DIR="${CHROOT_DIR:-}"
ncc_opt=
VERBOSITY=0

eval set -- "${options}"
while true; do
    case "$1" in
    -t|--tempdir)
        shift;  # The arg is next in position args
        CHROOT_DIR=$1  # deferred argument checking
        ncc_opt="-t $CHROOT_DIR"
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


# ARG1_MODE="${1:-${DEFAULT_CMD_MODE}}"
# ARG2_NAME="${2}"

sudo_bin=
if [ $EUID -ne 0 ]; then
  echo "WARN: User $UID is not root; may need 'sudo' evocation"
  echo "May user-prompt before any read-protected operation gets performed."
  sudo_bin=sudo
fi

# Begin of dns-isc-common.sh
BUILDROOT="${BUILDROOT:-build}"

source ssh-openssh-common.sh

# Probably should have 'source distro-package-specific' scripting go here
# Needs to deal with 'DEFAULT_ETC_CONF_DIRNAME' there.

# libdir and $HOME are three separate grouping (that Fedora, et. al. merged)

log_dir="/var/log/$LOG_SUB_DIRNAME"
echo "VAR_LIB_NAMED_DIRSPEC: $sshd_home_dirspec"
exit

if [ -z "$NAMED_SHELL_FILESPEC" ]; then
  NAMED_SHELL_FILESPEC="$(grep $SSH_USER_NAME /etc/passwd | awk -F: '{print $7}')"
fi

# Data?  It's where statistics, memstatistics, dump, and secdata go into
DEFAULT_DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"

# $HOME is always treated separately from Key directory; Only Fedora merges them
#
# OpenSSH 'directory' statement is not the same as named $HOME directory.
# daemon's current working directory is not the same as ('directory' statement)
# named $HOME directory is not the same as named daemon current working dir.
# These three above things are ... three ... separate ... groups of files.
#
# Unmerging would make it easier for 'named' group to be doled out to
# administrators' supplemental group ID list (much to Fedora's detriments)
# and restrict these administrators to just updates of zones.
#
if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep $SSH_USER_NAME /etc/passwd | awk -F: '{print $6}')"
fi
NAMED_HOME_DIRSPEC="$sshd_home_dirspec"

# Furthermore, Zone DB directory is now being split into many subdirectories
#  by their zone type (i.e., primary/secondary/hint/mirror/redirect/stub)
#
# Redhat/Fedora already uses 'slaves' zone type for a subdirectory 
# (but that could change to 'secondaries')
DEFAULT_ZONE_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
DEFAULT_ZONE_DB_DIRNAME_A=("primaries", "secondaries", "hints", "mirrors", "redirects", "stubs", "masters", "slaves")
DEFAULT_ZONE_DB_DIRNAME_ALT_A=("primary", "secondary", "hint", "mirror", "redirect", "stub")

# DNSSEC-related & managed-keys/trust-anchors
DEFAULT_DYNAMIC_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/dynamic"

# WHY WOULD WE WANT /etc/named/keys?  We have /var[/lib]/named/keys
# I suspect that rndc, XFER, AXFR, and DDNS keys go into /etc/named/keys
# and DNSSEC go into /var[/lib]/named/keys.

DEFAULT_CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"
DEFAULT_KEYS_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/keys"


# Use the 'which -a' which follows $PATH to pick up all 'named' binaries
# choose the first one or choose the ones in SysV/systemd?
# (or let the end-user choose it?)
# Make the SysV/systemd-selected ones the default, then let user choose it
# if there are more than one
named_bins_a=()
named_bins_a=($(which -a named | awk '{print $1}'))

# If there is more than one, use first one as the user-default
if [ ${#named_bins_a[@]} -ge 2 ]; then

  # Quick and see if systemctl cat named.service can clue us to which binary
  systemd_named_bin="$(systemctl cat "${systemd_unitname}.service" | grep "ExecStart="|awk -F= '{print $2}' | awk '{print $1}')"
  if [ $? -eq 0 ] && [ -n "$systemd_named_bin" ]; then
    default_named_bin="$systemd_named_bin"
    echo "Choosing systemd-default: $systemd_named_bin"
  else
    default_named_bin="${named_bins_a[0]}"
    echo "Choosing first 'which' listing: ${named_bins_a[0]}"
  fi
  while true ; do
    i=1
    echo "Found the following 'named' binaries:"
    for o in "${named_bins_a[@]}"; do
      echo "  $i) $o"
      ((i++))
    done
    read -rp "The index to which 'named' binary to use? [$default_named_bin]: "
    if [ -z "$REPLY" ]; then
      named_bin="${default_named_bin}"
      break;
    fi
    if [[ "$REPLY" =~ ^-?[0-9]+$ ]]; then
      if [ "$REPLY" -le "${#named_bins_a[@]}" ]; then
        ((REPLY--))
        echo "$REPLY= $REPLY"
        named_bin="${named_bins_a[REPLY]}"
        break;
      fi
    else
      named_bin="$REPLY"
      break;
    fi
  done
  # echo "'named' selected: ${named_bin}"
else
  named_bin="${named_bins_a[0]}"
  echo "Only one 'named' found: $(echo ${named_bins_a[*]} | xargs)"
fi
echo "Using 'named' binary in: $named_bin"


# Now ensure that we use the same tools as  this daemon
named_sbin_dirspec="$(dirname "$named_bin")"
tool_dirspec="$(dirname "$named_sbin_dirspec")"

named_bin_dirspec="${tool_dirspec}/bin"

# Why did ISC move the offline tools to */sbin subdirectory?!
named_checkconf_filespec="${named_sbin_dirspec}/named-checkconf"
named_checkzone_filespec="${named_sbin_dirspec}/named-checkzone"
named_compilezone_filespec="${named_sbin_dirspec}/named-compilezone"
named_journalprint_filespec="${named_sbin_dirspec}/named-journalprint"
named_rrchecker_filespec="${named_sbin_dirspec}/named-rrchecker"

# Check for user-supplied named.conf
# use 'named -V' to get default named.conf to use as a default
# scan /etc/named/*.conf for any
# Prompt for named.conf

if [ -z "$NAMED_CONF" ]; then
  # DEFAULT_NAMED_CONF_FILESPEC="/etc/named.conf"  # TODO: temporary
  SYSTEMD_NAMED_CONF="$(systemctl cat "${systemd_unitname}.service"|egrep "Environment\s*=\s*NAMEDCONF\s*="|awk -F= '{print $3}')"
  if [ -n "$SYSTEMD_NAMED_CONF" ]; then
    echo "systemd ${systemd_unitname}.service unit uses this config file: $SYSTEMD_NAMED_CONF"
    NAMED_CONF_FILESPEC="$SYSTEMD_NAMED_CONF"
  else
    echo "No named.conf found in 'systemctl cat ${systemd_unitname}.service'"
    # Execute 'named -V' to get 'named configuration' default setting
    SBIN_NAMED_CONF_FILESPEC="$("$named_bin" -V|grep 'named configuration:'|awk '{print $3}')"
    # Might be an older 'named -V' with no output
    if [ -z "$SBIN_NAMED_CONF_FILESPEC" ]; then
      echo "Older 'named' binary offered no named.conf default dirpath;"
      NAMED_CONF_FILESPEC="$DEFAULT_NAMED_CONF_FILESPEC"
      echo "Using ISC default named.conf: $DEFAULT_NAMED_CONF_FILESPEC"
    else
      echo "Binary 'named' built-in config default: $SBIN_NAMED_CONF_FILESPEC"
      NAMED_CONF_FILESPEC="$SBIN_NAMED_CONF_FILESPEC"
    fi
  fi
else
  echo "User-defined named.conf: $NAMED_CONF"
  NAMED_CONF_FILESPEC="$NAMED_CONF"
fi
echo

CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"

DYNAMIC_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/dynamic"
KEYS_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/keys"
DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"

# End of dns-isc-common.sh

##################################################################

echo

if [ ! -f "$NAMED_CONF_FILESPEC" ]; then
  # might be hidden or suppressed by file permission, go sudo
  # might be a split horizon, named.conf could have gone named-*.conf
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "OK, we found the $NAMED_CONF_FILESPEC file but it requires SUDO operation."
    echo "to read it.  Rest of this script will use SUDO but for read-only operation."
    echo "...Alternatively, you can copy the configs to /tmp or set all"
    echo "...file permission to world-read."
    echo "No changes shall be made."
  else
    read -rp "Enter in Bind9 config file: " -ei${NAMED_CONF_FILESPEC}
    if [ ! -f "$REPLY" ]; then
      echo "No such file: $REPLY"
      echo "Aborted."
      exit 111
    fi
    NAMED_CONF_FILESPEC="$REPLY"
  fi
fi

# Find all config files, by chasing the 'include' clauses
#
# named-checkconf -p -x # can do all that collating of include files,
# but it already stripped out the include clauses leaving us with no
# clue as to what its filespec of these include clauses are so that
# approach is useless.
#
# This is CIS; we must validate file permissions on all
# files, and this includes the include clauses and their respective file.

function find_include_clauses
{
  local val
  echo "INFO: May prompt for sudo to perform protected read-only activities"
  echo "Begin scanning for 'include' clauses..."
  val="$($sudo_bin cat "$NAMED_CONF_FILESPEC" | grep -E -- "^\s*[\s\{]*\s*include\s*")"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  val="$(echo "$val" | xargs)"
  CONFIG_VALUE="$val"
  unset val
}

# make a list of all configuration files using 'include' clause as a
# search extender
config_files_list="$NAMED_CONF_FILESPEC"
find_include_clauses
config_files_list="$config_files_list $CONFIG_VALUE"


# Reconstruct a entire configuration file by including all configuration 
# files mentioned by its 'include' clause using 'named-checkconf -p -x'
echo
echo "Reading in $NAMED_CONF_FILESPEC..."
# Capture non-STDERR output of named-checkconf, if any
# shellcheck disable=SC2086
named_conf_all_includes="$($sudo_bin $named_checkconf_filespec $ncc_opt -p -x "$NAMED_CONF_FILESPEC" 2>/dev/null)$"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "User $UID has no read-access to $NAMED_CONF_FILESPEC;"
  echo "May prompt for root access via sudo to just read the $NAMED_CONF_FILESPEC..."
  # capture only STDERR output of named-checkconf
  # shellcheck disable=SC2086
  errmsg="$($sudo_bin $named_checkconf_filespec $ncc_opt -p -x "$NAMED_CONF_FILESPEC" )"
  echo "Need to fix error in $NAMED_CONF_FILESPEC before going further"
  echo "CLI: $sudo_bin $named_checkconf_filespec $ncc_opt -p -x $NAMED_CONF_FILESPEC"
  echo "Error code: $RETSTS"
  echo "Error message: $errmsg"
  exit $RETSTS
fi
echo "Content of $NAMED_CONF_FILESPEC Syntax OK."

# This function is useful in extracting B from string "A B", "A B;" or "{ A B;".
function find_config_value
{
  local val
  # echo "Scanning for '$1' ..."
  # named_conf_all_includes="$($sudo_bin named-checkconf -p -x $NAMED_CONF_FILESPEC 2>/dev/null)$"
  val="$(echo "$named_conf_all_includes" | grep -E -- "^\s*[\s\{]*\s*${1}\s*")"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  CONFIG_VALUE="$val"
  unset val
}


# Searchs multi-line for 'file' statement within its clause block of statements
# of all requested zone/channel clause
function find_file_statement()
{
  local regex_file_statements zone_idx_tmp=$1 t=$2 tmp_fidx=0 zone_files_list=""
  regex_file_statements='[^file]file[\n[:space:]]*"([a-zA-Z0-9\_\-\/\.]{1,64})"[\n[:space:]]*;[\n[:space:]]'
  # Don't while loop this one, we are grabbing first 'file' in 'zone'
  # named-checkconf will error out if multiple 'file' statements are found
  # echo "regex_file_statements: '$regex_file_statements'"
  if [[ $t =~ $regex_file_statements ]]; then

    # BASH_REMATCH is a bash internal variable to [[ regex ]]
    add_file="${BASH_REMATCH[1]}"
    t=${t#*"${BASH_REMATCH[0]}"}
    t=${t#*"${BASH_REMATCH[1]}"}
    t=${t#*"${BASH_REMATCH[2]}"}
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      return
    fi
    # echo "BASH_REMATCH: ${BASH_REMATCH[@]}"
    # echo "Zone file: ${BASH_REMATCH[1]}"
    zone_files_list="$zone_files_list $add_file"
    ((tmp_fidx+=1))
  fi
  # echo "zone_idx_tmp: ${zone_idx_tmp}"
  zone_file_statements_A[$zone_idx_tmp]="$zone_files_list"
  unset regex_file_statements t tmp_fidx zone_files_list zone_idx_tmp
}

find_zone_clauses()
{
  ZONE_IDX=0
  zone_clauses_A=()
  local s=$1 named_conf_by_zone_a=()
  # If you added any more pairs of (), you must add BASH_REMATCH[n+1] below
  regex_zone_clauses='[^zone]*zone[\n[:space:]]*"(\S{1,80})"[\n[:space:]]*\S{0,6}[\n[:space:]]*(\{[\n[:space:]]*)[^zone]*'
  # echo "find_zone_clauses: called"
  while [[ $s =~ $regex_zone_clauses ]]; do
    # echo "RegedRegexRegexRegexRegexRegexRegexRegex"
    # echo "'$regex_zone_clauses'"
    # echo "+++++++++++++++++++++++++++++++++++++++"
    # echo "s: '$s'"
    # echo "---------------------------------------"
    # echo "ZONE_IDX: '$ZONE_IDX'"
    # echo "BASH_REMATCH[0]: ${BASH_REMATCH[0]} "
    # echo "Found Zone name: ${BASH_REMATCH[1]} idx: $ZONE_IDX"
    # echo "BASH_REMATCH[2]: ${BASH_REMATCH[2]} "
    zone_clauses_A[$ZONE_IDX]="$(echo "${BASH_REMATCH[1]}" | xargs)"
    # BASH_REMATCH is a bash internal variable to [[ regex ]]
    s=${s#*"${BASH_REMATCH[0]}"}
    named_conf_by_zone_a[$ZONE_IDX]="$s" # echo "$s" | xargs )"
    s=${s#*"${BASH_REMATCH[1]}"}
    # echo "s(1): $s"
    #s=${s#*"${BASH_REMATCH[2]}"}
    ## echo "s(2): $s"
    ((ZONE_IDX+=1))
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      break
    fi
    # if zone clause but no file statement; DNS server is a forwarder
  done
  idx=0
  while [ "$idx" -lt "$ZONE_IDX" ]; do
    # echo "find_file_statement $idx '${named_conf_by_zone_a[$idx]}'"
    find_file_statement $idx "${named_conf_by_zone_a[$idx]}"
    ((idx+=1))
  done
  unset named_conf_by_zone_a s
  unset regex_file_statements regex_zone_clauses
}


# Obtain log files
find_logging_channel_files() {

  # Pick up 'files "<filespec>"' only within 'channel <name> { ... }' grouping
  regex_logging_channel_files='[\n[:space:]]{0,30}channel[\n[:space:]]+[a-zA-Z0-9\_\-\."]{1,64}[\n[:space:]]\{[\n[:space:]]{0,30}file[[:space:]]*"([\/a-zA-Z0-9\_\-\.]{1,256})"[\n[:space:]]{0,30}((version|size)[\n[:space:]]{0,30}\S{1,64}[\n[:space:]]*;){0,2}'

  rematch_count=0
  sx="$named_conf_all_includes"
  while [[ $sx =~ $regex_logging_channel_files ]]; do
    CONFIG_VALUES_A+=("${BASH_REMATCH[1]}")
    ((rematch_count+=1))
    sx=${sx#*"${BASH_REMATCH[1]}"}
    # echo "remaining sx: $sx"
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      break
    fi
  done
}


# Obtain value (2nd argument) then remove semicolon
# Remove double-quotes

# Get that 'directory', if any
find_config_value "directory"
CV_BIND_DIRSPEC="$CONFIG_VALUE"
if [ -n "$CV_BIND_DIRSPEC" ]; then
  HOME_DIR="$CV_BIND_DIRSPEC"
  echo "Extract 'directory' value as $HOME_DIR"
else
  HOME_DIR="$DEFAULT_USER_HOME_DIRNAME"
  echo "Keeping 'directory' value at $HOME_DIR"
fi
echo 

echo "final configure/autogen/autoreconf settings:"
echo "  prefix:        $prefix"
echo "  sysconfdir:    $sysconfdir"
echo "  localstatedir: $localstatedir"

# Typically, when shell switches user, current directory switches to new $HOME
cwd_dir="$NAMED_HOME_DIRSPEC"

# Now for CIS defaults
# Directory for temporary runtime files, typically '/var/run/named'
# This CIS_RUNDIR setting cannot be changed by config file????
CIS_RUNDIR="$localstatedir/run/named"


# Now for the many default settings
# DEFAULT_RNDC_CONF_DIRNAME="$sysconfdir"
# DEFAULT_RNDC_CONF_FILENAME="rndc.conf"
DEFAULT_DUMP_DIRNAME="$cwd_dir"
DEFAULT_DUMP_FILENAME="named_dump.db"  # named/config.c/defaultconf
DEFAULT_STATISTICS_DIRNAME="$cwd_dir"
DEFAULT_STATISTICS_FILENAME="named.stats"   # named/config.c/defaultconf
DEFAULT_MEMSTATISTICS_DIRNAME="$cwd_dir"  # TODO: needs verification
DEFAULT_MEMSTATISTICS_FILENAME="named.memstats"  # named/config.c/defaultconf
# named-checkconf seems to pick up autoreconf/autogen/configure settings
# by doing 'named-checkconf -V'
DEFAULT_LOCKFILE_DIRNAME="$localstatedir/run/named"  # TODO sure its localstatedir?
DEFAULT_LOCKFILE_FILENAME="named.lock"
DEFAULT_MANAGED_KEYS_DIRNAME="$cwd_dir"  # named/server.c
DEFAULT_MANAGED_KEYS_FILENAME="managed-keys.bind"  # only if 'view-less'
DEFAULT_RANDOM_DIRNAME="/dev"
DEFAULT_RANDOM_FILENAME="random"  # bind9/config.h #define PATH_RANDOMDEV
DEFAULT_PIDFILE_DIRNAME="$localstatedir/run/named"  # named/config.c/defaultconf
DEFAULT_PIDFILE_FILENAME="named.pid"  # named/config.c/defaultconf
DEFAULT_SECROOTS_DIRNAME="$cwd_dir"
DEFAULT_SECROOTS_FILENAME="named.secroots"  # named/config.c/defaultconf
DEFAULT_BINDKEY_DIRNAME="$sysconfdir"
DEFAULT_BINDKEY_FILENAME="bind.keys"
DEFAULT_SESSION_KEYFILE_DIRNAME="$localstatedir/run/named"  # named/config.c/defaultconf
DEFAULT_SESSION_KEYFILE_FILENAME="session.key"  # named/config.c/defaultconf
DEFAULT_GSSAPI_KEYTAB_DIRNAME="/etc"
DEFAULT_GSSAPI_KEYTAB_FILENAME="krb5.key"
# no default for Zone files, must be explicit, must be a minimum of one
# for authoritative level 1/2 server.  Might have zone(s) in caching mode.
DEFAULT_KEY_DIRNAME="/var/cache/bind"  # Do not put cwd_dir/bind_home in here
DEFAULT_RECURSING_DIRNAME="$cwd_dir"
DEFAULT_RECURSING_FILENAME="named.recursing"

DEFAULT_JOURNAL_DIRNAME="$cwd_dir"
#DEFAULT_JOURNAL_FILENAME="$DEFAULT_.jnl"

# Scan entire configuration for 'zone's and 'logging, channel's

# Find all 'zone' clauses in config file
find_zone_clauses "$named_conf_all_includes"
# echo "zone_clauses_A[*]: ${zone_clauses_A[*]}"
# echo "zone_file_statements_A[*]: ${zone_file_statements_A[*]}"
zone_clauses_count=${#zone_clauses_A[*]}

# Some settings which might be wiped-out by named.conf, selectively.

# Keyword: 'dump-file'
find_config_value "dump-file"
CV_dump_filespec="$CONFIG_VALUE"
if [ -n "$CV_dump_filespec" ]; then
  DUMP_DIR="$(dirname "$CV_dump_filespec")"
  DUMP_FILENAME="$(basename "$CV_dump_filespec")"
else
  DUMP_DIR="$DEFAULT_DUMP_DIRNAME"
  DUMP_FILENAME="$DEFAULT_DUMP_FILENAME"
fi
dump_filespec="$DUMP_DIR/$DUMP_FILENAME"

# Keyword: 'statistics-file'
find_config_value "statistics-file"
CV_STATS_FILE="$CONFIG_VALUE"
if [ -n "$CV_STATS_FILE" ]; then
  STATISTICS_DIR="$(dirname "$CV_STATS_FILE")"
  STATISTICS_FILENAME="$(basename "$CV_STATS_FILE")"
  echo "Extracting 'statistics-file' as $STATISTICS_DIR/$STATISTICS_FILENAME"
else
  STATISTICS_DIR="$DEFAULT_STATISTICS_DIRNAME"
  STATISTICS_FILENAME="$DEFAULT_STATISTICS_FILENAME"
fi
statistics_filespec="$STATISTICS_DIR/$STATISTICS_FILENAME"

# Keyword: 'memstatistics_file'
# TODO: We think memstats goes into $cwd_dir directory also
find_config_value "memstatistics-file"
CV_MEMSTATS_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_MEMSTATS_FILESPEC" ]; then
  MEMSTATISTICS_DIR="$(dirname "$CV_MEMSTATS_FILESPEC")"
  MEMSTATISTICS_FILENAME="$(basename "$CV_MEMSTATS_FILESPEC")"
  echo "Extracting 'memstatistics-file' as $MEMSTATISTICS_DIR/$MEMSTATISTICS_FILENAME"
else
  MEMSTATISTICS_DIR="$DEFAULT_MEMSTATISTICS_DIRNAME"
  MEMSTATISTICS_FILENAME="$DEFAULT_MEMSTATISTICS_FILENAME"
fi
memstatistics_filespec="$MEMSTATISTICS_DIR/$MEMSTATISTICS_FILENAME"

# Keyword: 'geoip-directory'  # going obsolete due its geoip-directory
#   being incorporated into libmaxmindb library.

# Keyword: 'lock-file'
find_config_value "lock-file"
CV_lock_filespec="$CONFIG_VALUE"
if [ -n "$CV_lock_filespec" ]; then
  LOCK_DIR="$(dirname "$CV_lock_filespec")"
  LOCK_FILENAME="$(basename "$CV_lock_filespec")"
  echo "Extracting 'lock-file' as $LOCK_DIR/$LOCK_FILENAME"
else
  LOCK_DIR="$DEFAULT_LOCKFILE_DIRNAME"
  LOCK_FILENAME="$DEFAULT_LOCKFILE_FILENAME"
fi
lock_filespec="$LOCK_DIR/$LOCK_FILENAME"

# If view are used, managed keys no longer has default file/dir names
# and managed keys will be tracked in separate files, one file per view;
# each file name will  be the SHA256 hash of the view name,  followed by
# the extension .mkey
find_config_value "managed-keys-directory"
CV_MKEYS_DIRSPEC="$CONFIG_VALUE"
if [ -n "$CV_MKEYS_DIRSPEC" ]; then
  # This becomes a directory, from a filespec
  MANAGEDKEYS_DIR="$CV_MKEYS_DIRSPEC"
  echo "Extracting 'managed-keys-directory' as $MANAGEDKEYS_DIR"
else
  MANAGEDKEYS_DIR="$DEFAULT_MANAGED_KEYS_DIRNAME"
fi

# TODO:  Is that by total views or by total zones?
# UPDATE: Doesn't look like total zones is working
if [ "$zone_clauses_count" -ge 10 ]; then
# Break out filename by numbers of zones greater than 1
  MANAGEDKEYS_FILENAME="<not-a-file>"
  echo "Extracting default 'managed-keys-file' as $MANAGEDKEYS_FILENAME"
else
  MANAGEDKEYS_FILENAME="$DEFAULT_MANAGED_KEYS_FILENAME"
fi
MANAGEDKEYS_FILESPEC="$MANAGEDKEYS_DIR/$MANAGEDKEYS_FILENAME"

# Keyword: 'random-device'
find_config_value "random-device"
CV_random_filespec="$CONFIG_VALUE"
if [ -n "$CV_random_filespec" ]; then
  RANDOM_DIR="$(dirname "$CV_random_filespec")"
  RANDOM_FILENAME="$(basename "$CV_random_filespec")"
  echo "Extracting 'random-device' as $RANDOM_DIR/$RANDOM_FILENAME"
else
  RANDOM_DIR="$DEFAULT_RANDOM_DIRNAME"
  RANDOM_FILENAME="$DEFAULT_RANDOM_FILENAME"
fi
random_filespec="$RANDOM_DIR/$RANDOM_FILENAME"

# Keyword: 'pid-file'
find_config_value "pid-file"
CV_pid_filespec="$CONFIG_VALUE"
if [ -n "$CV_pid_filespec" ]; then
  PID_DIR="$(dirname "$CV_pid_filespec")"
  PID_FILENAME="$(basename "$CV_pid_filespec")"
  echo "Extracting 'pid-file' as $PID_DIR/$PID_FILENAME"
else
  PID_DIR="$DEFAULT_PIDFILE_DIRNAME"
  PID_FILENAME="$DEFAULT_PIDFILE_FILENAME"
fi
pid_filespec="$PID_DIR/$PID_FILENAME"

# Keyword: 'recursing-file'
find_config_value "recursing-file"
CV_RECURSE_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_RECURSE_FILESPEC" ]; then
  RECURSING_DIR="$(dirname "$CV_RECURSE_FILESPEC")"
  RECURSING_FILENAME="$(basename "$CV_RECURSE_FILESPEC")"
  echo "Extracting 'recursing-file' as $RECURSING_DIR/$RECURSING_FILENAME"
else
  RECURSING_DIR="$DEFAULT_RECURSING_DIRNAME"
  RECURSING_FILENAME="$DEFAULT_RECURSING_FILENAME"
fi
# shellcheck disable=SC2034
recursing_filespec="$RECURSING_DIR/$RECURSING_FILENAME"

# Keyword: 'secroots-file'
find_config_value "secroots-file"
CV_SECROOT_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_SECROOT_FILESPEC" ]; then
  SECROOTS_DIR="$(dirname "$CV_SECROOT_FILESPEC")"
  SECROOTS_FILENAME="$(basename "$CV_SECROOT_FILESPEC")"
  echo "Extracting 'secroots-file' as $SECROOTS_DIR/$SECROOTS_FILENAME"
else
  SECROOTS_DIR="$DEFAULT_SECROOTS_DIRNAME"
  SECROOTS_FILENAME="$DEFAULT_SECROOTS_FILENAME"
fi
secroots_filespec="$SECROOTS_DIR/$SECROOTS_FILENAME"

# Keyword: 'bindkeys-file'
find_config_value "bindkeys-file"
CV_BINDKEYS_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_BINDKEYS_FILESPEC" ]; then
  BINDKEY_DIR="$(dirname "$CV_BINDKEYS_FILESPEC")"
  BINDKEY_FILENAME="$(basename "$CV_BINDKEYS_FILESPEC")"
  echo "Extracting 'bindkeys-file' as $BINDKEY_DIR/$BINDKEY_FILENAME"
else
  BINDKEY_DIR="$DEFAULT_BINDKEY_DIRNAME"
  BINDKEY_FILENAME="$DEFAULT_BINDKEY_FILENAME"
fi
BINDKEY="$BINDKEY_DIR/$BINDKEY_FILENAME"

# Keyword: 'session-keyfile'
find_config_value "session-keyfile"
CV_SESSKEY_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_SESSKEY_FILESPEC" ]; then
  SESSION_KEY_DIR="$(dirname "$CV_SESSKEY_FILESPEC")"
  SESSION_KEY_FILENAME="$(basename "$CV_SESSKEY_FILESPEC")"
  echo "Extracting 'session-file' as $SESSION_KEY_DIR/$SESSION_KEY_FILENAME"
else
  SESSION_KEY_DIR="$DEFAULT_SESSION_KEYFILE_DIRNAME"
  SESSION_KEY_FILENAME="$DEFAULT_SESSION_KEYFILE_FILENAME"
fi
SESSION_KEY_FILESPEC="$SESSION_KEY_DIR/$SESSION_KEY_FILENAME"

# Keyword: 'tkey-gssapi-keytab'
find_config_value "tkey-gssapi-keytab"
CV_GSSAPI_KEYTAB="$CONFIG_VALUE"
if [ -n "$CV_GSSAPI_KEYTAB" ]; then
  KEYTAB_DIR="$(dirname "$CV_GSSAPI_KEYTAB")"
  KEYTAB_FILENAME="$(basename "$CV_GSSAPI_KEYTAB")"
  echo "Extracting 'tkey-gssapi-keytab' as $KEYTAB_DIR/$KEYTAB_FILENAME"
else
  KEYTAB_DIR="$DEFAULT_GSSAPI_KEYTAB_DIRNAME"
  KEYTAB_FILENAME="$DEFAULT_GSSAPI_KEYTAB_FILENAME"
fi
keytab_filespec="$KEYTAB_DIR/$KEYTAB_FILENAME"

# Keyword: 'file'  by zones
# All zone files referenced in the configuration files regardless of DNS server
# type
zone_files_list="$(echo "${zone_file_statements_A[*]}" | xargs)"
#if [ ${#zone_clauses_A[*]} -gt 1 ]; then
#  =""
#else
#  ="trust-anchors"
#fi

# Keyword: 'key-directory'
# This action picks up both the 'options, key-directory' and
# all 'zone, key-directory' entries.
# Despite CIS 9.11, KEYDIR is actual multiple directories.
find_config_value "key-directory"
CV_KEY_DIRPATH="$CONFIG_VALUE"
if [ -n "$CV_KEY_DIRPATH" ]; then
  KEYDIR="$CV_KEY_DIRPATH"
  echo "Extracting 'key-directory' as $KEYDIR"
else
  # defaults to one directory
  KEYDIR="$DEFAULT_KEY_DIRNAME"
fi
key_dir_list="$KEYDIR"   # decommission KEYDIR due to multiple directories
# Do not put $bind_home in 'key-directory' ENV_VAR
# named has 'key-directory' compiled-in default set to '/var/cache/bind'
# It was 'bind' user account who 'moved' into the same directory.
# Arguably, user $HOME should be in its own directory '/var/bind'.

# Keyword: 'journal'
find_config_value "journal"
CV_JOURNAL_FILESPEC="$CONFIG_VALUE"
if [ -n "$CONFIG_VALUE" ]; then
  JOURNAL_DIR="$(dirname "$CV_JOURNAL_FILESPEC")"
  # JOURNAL_FILENAME="$(basename "$CV_JOURNAL_FILESPEC")"
else
  JOURNAL_DIR="$DEFAULT_JOURNAL_DIRNAME"
  # JOURNAL_FILENAME="$DEFAULT_JOURNAL_FILENAME"
fi
# TODO: Confirm that named-binary is actually doing this
# JOURNAL_FILESPEC="$JOURNAL_DIR/$JOURNAL_FILENAME"  # TODO

# OK, we got the config file all of their settings,
#
# It is now file permissions time (and ownerships as well)


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


bind_cfg_files="$sysconfdir/*.conf"
its_dir_exist "$bind_cfg_files"

# in case of split-horizon
#bind_home="$cwd_dir"




# Directory for managed keys which are dynamically updated
# Directory for dynamically updated slave zone files.
slave_dir="/var/bind/slave"

# Directory for temporary files - Typically, '/tmp',
# some methods for named to define temporary files are:
# systemd service TmpDir
# TMPDIR environment variable
TMPDIR="/tmp"  # system-default, man tmpfile(3)
#TMPDIR="/var/tmp"  # system-default, man tmpfile(3), Fedora 35

#  echo "Must have a key directory somewhere."
#  echo "Keys are dynamically defined after daemon runs"
#  echo "These keys could not go into /etc/bind/..."
#  echo "These dyanamic keys should go somewhere under /var"
#  echo "These dynamic keys probably are to be upgrade-proof and boot-proof"
#  echo " so that means /var/lib, or more specifically /var/lib/bind/keys"
# Directory for signing key files.
# KEYDIR


echo "Based on $NAMED_CONF_FILESPEC settings..."
echo
echo "TMPDIR:			$TMPDIR"
echo "Bind username:		$SSH_USER_NAME"
echo "Bind groupname:		$GROUP_NAME"
echo "Bind shell:		$NAMED_SHELL_FILESPEC"
echo "random filespec:	$random_filespec"
echo "KRB5 keytab filespec:	$keytab_filespec"
echo
echo "SELinux name_zone_t group:"
echo "Bind \$HOME:		$NAMED_HOME_DIRSPEC"
echo "Zone files list:	$zone_files_list"
echo "Zone clauses_A:	${zone_clauses_A[@]}"
echo "Zone file statements_A:	${zone_file_statements_A[*]}"
echo
echo "SELinux name_cache_t group:"
echo "DNSSEC Dynamic Dir:	$DYNAMIC_DIRSPEC"
echo "Zone Slave Dir:		$slave_dir"
echo "key_dir_list		$key_dir_list"
echo "ManagedKeys Dir:	$MANAGEDKEYS_DIR"
echo "ManagedKeys filespec:	$MANAGEDKEYS_FILESPEC"
echo "Bind data dir:		$DATA_DIRSPEC"
echo "dump filespec:		$dump_filespec"
echo "secroots filespec:	$secroots_filespec"
echo "statistics filespec:	$statistics_filespec"
echo "memstatistics filespec:	$memstatistics_filespec"
echo "Journal dir:		$JOURNAL_DIR"
echo
echo "SELinux name_conf_t group:"
echo "Config files list:	$config_files_list"
echo "BINDKEY:		$BINDKEY"
echo 
echo "SELinux name_log_t group:"
echo "Log directory:		$log_dir"
echo
echo "SELinux name_var_run_t group:"
echo "CIS_RUNDIR:		$CIS_RUNDIR"
echo "PID file:		$pid_filespec"
echo "Session Key:		$SESSION_KEY_FILESPEC"
echo "Lock filespec:		$lock_filespec"
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
read -rp "CISecurity, Fedora, or Debian settings? (C/f/d): " -eiC
REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"

case $REPLY in
  'd')
    echo "Debian default settings..."
    file_perm_check TMPDIR "1777" "root" "root"
    file_perm_check NAMED_SHELL_FILESPEC "755" "root" "root"
    file_perm_check random_filespec "666" "root" "root"
    file_perm_check keytab_filespec "640" "root" "$GROUP_NAME"

    # SELinux named_zone_t
    file_perm_check NAMED_HOME_DIRSPEC "775" "root" "$GROUP_NAME"
    for zone_file in $zone_files_list; do
      file_perm_check zone_file "644" "root" "root"
    done

    # SELinux named_cache_t
    file_perm_check DYNAMIC_DIRSPEC "2750" "root" "$GROUP_NAME"
    file_perm_check slave_dir "770" "root" "$GROUP_NAME"
    for key_dir in $key_dir_list; do
      file_perm_check key_dir "775" "root" "$GROUP_NAME"
    done
    file_perm_check MANAGEDKEYS_DIR "775" "root" "$GROUP_NAME"
    if [ -z "$?" ]; then
      file_perm_check MANAGEDKEYS_DIR "775" "root" "$GROUP_NAME"
    else
      file_perm_check MANAGEDKEYS_FILE "640" "root" "$GROUP_NAME"
    fi
    file_perm_check DATA_DIRSPEC "770" "root" "$GROUP_NAME"
    file_perm_check dump_filespec "640" "root" "$GROUP_NAME"
    file_perm_check secroots_filespec "640" "root" "$GROUP_NAME"
    file_perm_check statistics_filespec "640" "root" "$GROUP_NAME"
    file_perm_check memstatistics_filespec "640" "root" "$GROUP_NAME"
    file_perm_check JOURNAL_DIR "775" "root" "$GROUP_NAME"

    # SELinux named_conf_t
    for config_file in $config_files_list; do
      file_perm_check config_file "644" "root" "$GROUP_NAME"
    done
    file_perm_check BINDKEY "644" "root" "root"

    # SELinux named_var_run_t
    file_perm_check CIS_RUNDIR "755" "root" "$GROUP_NAME"
    # Bind key file shall be world-read for general inspection of file permissions
    file_perm_check pid_filespec "644" "$SSH_USER_NAME" "$GROUP_NAME"
    file_perm_check SESSION_KEY_FILESPEC "600" "$SSH_USER_NAME" "$GROUP_NAME"
    file_perm_check lock_filespec "640" "root" "$GROUP_NAME"

    file_perm_check recursing_filespec  "640" "root" "$GROUP_NAME"

    # SELinux named_var_t
    file_perm_check log_dir "770" "root" "$GROUP_NAME"
  ;;

  'c')
    echo "Recommended CIS settings..."
    file_perm_check TMPDIR "1777" "root" "root"
    #file_perm_check NAMED_SHELL_FILESPEC "755" "root" "root"
    file_perm_check random_filespec "666" "root" "root"
    file_perm_check keytab_filespec "640" "root" "$GROUP_NAME"

    # SELinux named_zone_t
    file_perm_check NAMED_HOME_DIRSPEC "770" "$SSH_USER_NAME" "$GROUP_NAME"
    # shellcheck disable=SC2034
    for zone_file in $zone_files_list; do
      file_perm_check zone_file "640" "root" "$GROUP_NAME"
    done

    # SELinux named_cache_t
    file_perm_check DYNAMIC_DIRSPEC "750" "$SSH_USER_NAME" "$GROUP_NAME"
    file_perm_check slave_dir "750" "$SSH_USER_NAME" "$GROUP_NAME"
    # shellcheck disable=SC2034
    for key_dir in $key_dir_list; do
      file_perm_check key_dir "770" "root" "$GROUP_NAME"
    done
    file_perm_check MANAGEDKEYS_FILESPEC "2750" "root" "$GROUP_NAME"
    if [ -z "$?" ]; then
      file_perm_check MANAGEDKEYS_DIR "2750" "$SSH_USER_NAME" "root"
    else
      file_perm_check mANAGEDKEYS_DIR "640" "$SSH_USER_NAME" "root"
    fi
    file_perm_check DATA_DIRSPEC "750" "$USER_NAME" "$GROUP_NAME"
    file_perm_check dump_filespec "640" "root" "$GROUP_NAME"
    file_perm_check secroots_filespec "640" "root" "$GROUP_NAME"
    file_perm_check statistics_filespec "640" "root" "$GROUP_NAME"
    file_perm_check memstatistics_filespec "640" "root" "$GROUP_NAME"
    file_perm_check JOURNAL_DIR "2750" "$USER_NAME" "root"

    # SELinux named_conf_t
    # shellcheck disable=SC2034
    for config_file in $config_files_list; do
      file_perm_check config_file "640" "root" "$GROUP_NAME"
    done
    file_perm_check BINDKEY "644" "root" "root"

    # SELinux named_var_run_t
    file_perm_check CIS_RUNDIR "2775" "root" "$GROUP_NAME"
    file_perm_check pid_filespec "640" "root" "$GROUP_NAME"
    file_perm_check SESSION_KEY_FILESPEC "600" "$USER_NAME" "root"
    file_perm_check lock_filespec "640" "root" "$GROUP_NAME"

    file_perm_check recursing_filespec  "640" "root" "$GROUP_NAME"

    # SELinux named_log_t
    file_perm_check log_dir "750" "$USER_NAME" "$GROUP_NAME"
    ;;

  # Fedora
  'f')
    echo "Fedora default settings..."
    file_perm_check TMPDIR "1777" "root" "root"
    file_perm_check NAMED_SHELL_FILESPEC "755" "root" "root"
    file_perm_check random_filespec "666" "root" "root"
    file_perm_check keytab_filespec "640" "$USER_NAME" "$GROUP_NAME"

    # unwanted reason for o-rx in named $HOME:
    #   dhcp-client needs access to named session-key
    #   Another good reason for relocating session-key to /var/run/named

    # SELinux named_zone_t
    file_perm_check NAMED_HOME_DIRSPEC "2750" "$USER_NAME" "$GROUP_NAME"
    for zone_file in $zone_files_list; do
      file_perm_check zone_file "640" "$USER_NAME" "$GROUP_NAME"
    done

    # SELinux named_cache_t
    file_perm_check DYNAMIC_DIRSPEC "750" "$USER_NAME" "$GROUP_NAME"
    file_perm_check slave_dir "750" "$USER_NAME" "$GROUP_NAME"
    for key_dir in $key_dir_list; do
      file_perm_check key_dir "750" "$USER_NAME" "$GROUP_NAME"
    done
    file_perm_check MANAGEDKEYS_FILESPEC "2750" "root" "$GROUP_NAME"
    if [ -z "$?" ]; then
      file_perm_check MANAGEDKEYS_DIR "750" "$USER_NAME" "$GROUP_NAME"
    else
      file_perm_check MANAGEDKEYS_DIR  "640" "root" "$GROUP_NAME"
    fi
    file_perm_check DATA_DIRSPEC "750" "$USER_NAME" "$GROUP_NAME"
    file_perm_check dump_filespec "640" "$USER_NAME" "$GROUP_NAME"
    file_perm_check secroots_filespec "640" "$USER_NAME" "$GROUP_NAME"
    file_perm_check statistics_filespec "640" "$USER_NAME" "$GROUP_NAME"
    file_perm_check memstatistics_filespec "640" "$USER_NAME" "$GROUP_NAME"
    file_perm_check JOURNAL_DIR "750" "$USER_NAME" "$GROUP_NAME"
    file_perm_check recursing_filespec  "640" "$USER_NAME" "$GROUP_NAME"

    # SELinux named_conf_t
    for config_file in $config_files_list; do
      file_perm_check config_file "640" "root" "$GROUP_NAME"
    done
    file_perm_check BINDKEY "644" "$USER_NAME" "$GROUP_NAME"

    # named_var_run_t
    file_perm_check CIS_RUNDIR "755" "$USER_NAME" "$GROUP_NAME"
    file_perm_check pid_filespec "644" "$USER_NAME" "$GROUP_NAME"
    # session-key only occurs when DHCP server is coordinating with this DNS
    file_perm_check SESSION_KEY_FILESPEC "600" "$USER_NAME" "$GROUP_NAME"
    file_perm_check lock_filespec "640" "$USER_NAME" "$GROUP_NAME"

    # named_log_t
    file_perm_check log_dir "750" "$USER_NAME" "$GROUP_NAME"
    ;;

esac

echo "Total files:       $total_files"
echo "File missing:          $total_file_missings"
echo "Skipped files:        $total_file_errors"
echo "Permission errors:         $total_perm_errors"

