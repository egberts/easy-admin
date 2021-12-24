#!/bin/bash
# File: 510-cis-dns-bind-dirs.sh
# Title: Check file permissions of various files
#
# Description:
# Usage:
#   500-cis-dns-bind-dirs.sh
#          [ -i <bind9-instance-name> ]
#          [ -t <chroot-dir> ] 
#          <named.conf-filespec>
#
#      -t : optional top-level directory path to chroot directory
#      -i : optional Bind9 instance name, typically one for each named daemon
#
# - split-horizon have two instance names.
#
# TODO:
#   named v9.16 opens /usr/lib/ssl/openssl.cnf  (check that?)
#   named v9.16 opens $CWD/_default.tsigkeys
#   named v9.16 opens $CWD/_bind.tsigkeys
#   named v9.16 opens $CWD/_default.nta
#   named v9.16 opens $CWD/_bind.nta
#   named v9.16 opens $CWD/managed-keys.bind  (only if single view-less zone)
#   named v9.16 opens $CWD/managed-keys.bind.jnl

function cmd_show_syntax_usage {
    cat << USAGE_EOF
Usage:  $0
	[-t|--chroot-dir <chroot-dir>] \
        [-i|--instance <bind9-instance-name>] \
        [ --help|-h ] [ --verbosity|-v ]
        < named.conf-filespec >
USAGE_EOF
  exit 1
}

# Call getopt to validate the provided input.
options=$(getopt -o hit:vV \
          --long help,instance:,chroot-dir:,verbose,version -- "$@" )
RETSTS=$?
[[ ${RETSTS} -eq 0 ]] || {
    echo "Incorrect options provided"
    cmd_show_syntax_usage
    exit ${RETSTS}
}

CHROOT=
ncc_opt=
VERBOSITY=0

eval set -- "${options}"
while true; do
    case "$1" in
    -i|--instance)
        shift;  # The arg is next in position args
        INSTANCE=$1  # deferred argument checking
        ;;
    -t|--tempdir)
        shift;  # The arg is next in position args
        CHROOT=$1  # deferred argument checking
        ncc_opt="-t $CHROOT"
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
  echo "Will user-prompt before any writing operation is needed."
  sudo_bin=sudo
fi

# Use the 'which -a' which follows $PATH to pick up all 'named' binaries
# choose the first one or choose the ones in SysV/systemd?
# (or let the end-user choose it?)
# Make the SysV/systemd-selected ones the default, then let user choose it
# if there are more than one
named_bins_a=()
named_bins_a=($(which -a named | awk '{print $1}'))
echo "Found 'named' in: $(echo ${named_bins_a[*]} | xargs)"

# If there is more than one, use first one as the user-default
if [ ${#named_bins_a[@]} -ge 2 ]; then
  default_named_bin="${named_bins_a[0]}"
  while true ; do
    i=1
    echo "Enter in 'named' index [default: $default_named_bin]: "
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
  echo "'named' selected: ${named_bin}"
else
  named_bin="${named_bins_a[0]}"
  echo "Only one 'named' found: $(echo ${named_bins_a[*]} | xargs)"
fi
echo "Using 'named' binary in: $named_bin"

#  TODO

# TODO: What to do with two binaries? (/usr/sbin and /usr/local/sbin)
#
named_checkconf_bin="$(whereis -b named-checkconf | awk '{print $2}')"
if [ -z "$named_checkconf_bin" ]; then
  echo "named-checkconf is not found; Aborted."
  exit 1
fi

source /etc/os-release

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

# libdir and $HOME are two separate grouping (that Fedora, et. al. merged)
case $ID in
  debian)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR=""
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-bind}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-bind}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/lib/${DEFAULT_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="/etc/bind/named.conf"
    USER_NAME="bind"
    GROUP_NAME="bind"
    WHEEL_GROUP="sudo"
    ;;
  centos)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-named}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-named}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="/etc/named.conf"
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ;;
  redhat)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-named}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-named}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="/etc/named.conf"
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ;;
  fedora)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-named}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-named}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="/etc/named.conf"
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ;;
  *)
    echo "Unknown Linux distro"
    exit 3
    ;;
esac
bind_username="$USER_NAME"
bind_groupname="$GROUP_NAME"

# Vendor-specific autotool/autoconf
prefix="${prefix:-${DEFAULT_PREFIX}}"
sysconfdir="${sysconfdir:-${DEFAULT_SYSCONFDIR}}"
exec_prefix="${exec_prefix:-${DEFAULT_EXEC_PREFIX}}"
libdir="${libdir:-"${DEFAULT_LIB_NAMED_DIRSPEC}"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DEFAULT_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific
named_conf_filespec="${NAMED_CONF:-${DEFAULT_NAMED_CONF_FILESPEC}"

##########################################################################

case $ID in
  debian)
    USER_NAME="bind"
    GROUP_NAME="bind"
    package_tarname="bind"
    ;;
  fedora)
    USER_NAME="named"
    GROUP_NAME="named"
    package_tarname="bind"
    ;;
  redhat)
    USER_NAME="named"
    GROUP_NAME="named"
    package_tarname="bind"
    ;;
  centos)
    USER_NAME="named"
    GROUP_NAME="named"
    package_tarname="bind"
    ;;
esac

if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep named /etc/passwd | awk -F: '{print $6}')"
fi

##########################################################################

# Either we let distro pick the name or we try and pick up the user/group names
known_bind_usernames="bind named"
for bind_username in $known_bind_usernames; do
  found_bindname_A=("$(grep -E -- "^$bind_username" /etc/passwd)")
  if [ ${#found_bindname_A[@]} -gt 1 ]; then
    echo "Too many $bind_username accounts."
    echo "Aborted"
    exit 9
  elif [ -n "${found_bindname_A[0]}" ]; then
    bind_username="${bind_username}"
    bind_home_dir="$(echo "${found_bindname_A[0]}" | awk -F: '{print $6}')"
  fi
done
echo "Bind9 user account name is automatically determined as: '$bind_username'"
if [ -z "$bind_home_dir" ]; then
  echo "User '$bind_username' $HOME directory is undefined"
  echo "Aborted."
  exit 123
fi
echo "User $bind_username \$HOME=$bind_home_dir"

# Now extract that Bind9 user $HOME directory (also varied across distros)
# named needs a $HOME for statistics, dump-files, cache dumps.
# named puts other files elsewhere depending on static/dynamic/write/read needs
# Keyword: 'directory'
find_bind_home="$(grep "$bind_username" /etc/passwd | awk -F: '{print $6}')"
if [ -z "$find_bind_home" ]; then
  echo "Unable to determine \$HOME for '$bind_username' user."
  echo "Aborted"
  exit 123
else
  DEFAULT_USER_HOME_DIRNAME="$find_bind_home"
fi
bind_shell="$(grep -e "^$bind_username" /etc/passwd|awk -F: '{print $7}')"


# Later, we can override much of $HOME with named.conf's 'directory' keyword,
# if any.
# This override of USER_HOME shall occur before first usage of $USER_HOME

# Find the Bind9 configuration directory, if any
# Start with subdirectory, work your way up to just plain ol' /etc
sysconfdir="/etc/bind"
echo "...$sysconfdir for Bind configuration directory..."
if [ ! -d $sysconfdir ]; then
  sysconfdir="/etc/named"
  echo "...$sysconfdir for Bind configuration directory..."
  if [ ! -d $sysconfdir ]; then
    sysconfdir="/etc"
    echo "...$sysconfdir for Bind configuration directory..."
    if [ ! -d $sysconfdir ]; then
      echo "WARN: Looks like Bind configuration directory is $sysconfdir..."
    fi
  fi
fi
echo "sysconfdir: $sysconfdir"

# TODO: Do we want to lift the default named.conf using
#   'named -V | grep 'named configuration:' | awk '{print $2}' ???
# Compiled-in default for named configuration filespec
NAMED_FILENAME="named.conf"  # almost never changeable
NAMED_FILEPATH="$sysconfdir"  # ./configure during autogen/build/autoreconf


# Find the Bind9 configuration file (most commonly, called 'named.conf'
DESIRED_NAMED_CONF="${1:-$NAMED_FILEPATH/$NAMED_FILENAME}"
DESIRED_NAMED_CONF_DIR="$(dirname "$DESIRED_NAMED_CONF")"
DESIRED_NAMED_CONF_FILENAME="$(basename "$DESIRED_NAMED_CONF")"

# how to recouncil with compiled-in default
NAMED_FILENAME="$DESIRED_NAMED_CONF_FILENAME"
NAMED_FILEPATH="$(realpath "$DESIRED_NAMED_CONF_DIR")"

echo ""
# Final filespec (after CWD-factoring)
NAMED_FILESPEC="$NAMED_FILEPATH/$NAMED_FILENAME"
if [ ! -f "$NAMED_FILESPEC" ]; then
  # might be hidden or suppressed by file permission, go sudo
  # might be a split horizon, named.conf could have gone named-*.conf
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "OK, we found the $NAMED_FILESPEC file but it requires SUDO operation."
    echo "to read it.  Rest of this script will use SUDO but for read-only operation."
    echo "...Alternatively, you can copy the configs to /tmp or set all"
    echo "...file permission to world-read."
    echo "No changes shall be made."
  else
    read -rp "Enter in Bind9 config file: " -ei${NAMED_FILESPEC}
    if [ ! -f "$REPLY" ]; then
      echo "No such file: $REPLY"
      echo "Aborted."
      exit 111
    fi
    NAMED_FILESPEC="$REPLY"
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
  echo "Scanning for 'include' clauses..."
  val="$($sudo_bin cat "$NAMED_FILESPEC" | grep -E -- "^\s*[\s\{]*\s*include\s*")"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  val="$(echo "$val" | xargs)"
  CONFIG_VALUE="$val"
  unset val
}

# List of primary configuration file and all included configuration files.
config_files_list="$NAMED_FILESPEC"
find_include_clauses
config_files_list="$NAMED_FILESPEC $CONFIG_VALUE"


# Read the entire config file
echo ""
echo "Reading in $NAMED_FILESPEC..."
echo "May need access via sudo..."
# Capture non-STDERR output of named-checkconf, if any
# shellcheck disable=SC2086
named_conf_all_includes="$($sudo_bin $named_checkconf_bin $ncc_opt -p -x "$NAMED_FILESPEC" 2>/dev/null)$"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  # capture only STDERR output of named-checkconf
  # shellcheck disable=SC2086
  errmsg="$($sudo_bin $named_checkconf_bin $ncc_opt -p -x "$NAMED_FILESPEC" 1>/dev/null)"
  echo "Need to fix error in $NAMED_FILESPEC before going further"
  echo "CLI: $sudo_bin $named_checkconf_bin $ncc_opt -p -x $NAMED_FILESPEC"
  echo "Error code: $RETSTS"
  echo "Error message: $errmsg"
  exit $RETSTS
fi
echo "Content of $NAMED_FILESPEC Syntax OK."

# This function is useful in extracting B from string "A B", "A B;" or "{ A B;".
function find_config_value
{
  local val
  echo "Scanning for '$1' ..."
  # named_conf_all_includes="$($sudo_bin named-checkconf -p -x $NAMED_FILESPEC 2>/dev/null)$"
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
  if [[ $t =~ $regex_file_statements ]]; then
    add_file="${BASH_REMATCH[1]}"
    t=${t#*"${BASH_REMATCH[1]}"}
    t=${t#*"${BASH_REMATCH[2]}"}
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      return
    fi
    zone_files_list="$zone_files_list $add_file"
    ((tmp_fidx+=1))
fi
  zone_file_statements_A[$zone_idx_tmp]="$zone_files_list"
  unset regex_file_statements t tmp_fidx zone_files_list zone_idx_tmp
}

find_zone_clauses()
{
  ZONE_IDX=0
  zone_clauses_A=()
  local s=$1 named_conf_by_zone_a=()
  # If you added any more pairs of (), you must add BASH_REMATCH[n+1] below
  regex_zone_clauses='[^zone]*zone[\n[:space:]]*(\S{1,64})[\n[:space:]]*\S{0,6}[\n[:space:]]*(\{[\n[:space:]]*)[^zone]*'
  #echo "find_zone_clauses: called"
  while [[ $s =~ $regex_zone_clauses ]]; do
    zone_clauses_A[$ZONE_IDX]="$(echo "${BASH_REMATCH[1]}" | xargs)"
    s=${s#*"${BASH_REMATCH[1]}"}
    s=${s#*"${BASH_REMATCH[2]}"}
    named_conf_by_zone_a[$ZONE_IDX]="$s" # echo "$s" | xargs )"
    ((ZONE_IDX+=1))
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      break
    fi
    # if zone clause but no file statement; DNS server is a forwarder
  done
  idx=0
  while [ "$idx" -lt "$ZONE_IDX" ]; do
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

# did we find any overriding 'directory' keyword?
# Directory under which BIND runs, typically '/var/named' or chrooted equivalent

# Get that 'directory', if any
find_config_value "directory"
CV_BIND_DIRSPEC="$CONFIG_VALUE"
if [ -n "$CV_BIND_DIRSPEC" ]; then
  HOME_DIR="$CV_BIND_DIRSPEC"
  echo "Redefining 'directory' to $HOME_DIR"
else
  HOME_DIR="$DEFAULT_USER_HOME_DIRNAME"
  echo "Keeping 'directory' at $HOME_DIR"
fi

# configure/autogen/autoreconf -----------------------------------
# maintainer default (ISC Bind9)
prefix=/usr
sysconfdir=$prefix/etc
localstatedir=$prefix/var
# exec_prefix=$prefix
DATAROOTDIR=$prefix/share
datadir=$DATAROOTDIR

# TODO Need additional clarity with CHROOT
# SYSROOT=/   # used with chroot?
# CHROOT_DIR="/var/named"  # Bind9 ARM handbook
# CHROOT_DIR="/var/named/chroot"  # Fedora 35

# CIS-specific default???
dynamic_dir="/var/lib/bind/dynamic"  # Debian 9,10,11

# distro-specific default
case $ID in
  'debian')
    prefix="/usr"
    sysconfdir="/etc/bind"
    localstatedir=""
    # CHROOT_DIR="/var/lib/named"
    dynamic_dir="/var/lib/bind/dynamic"  # Debian 9,10,11
    ;;

  'redhat'|'fedora'|'centos')
    prefix="/usr"
    sysconfdir="/etc/named"
    localstatedir="/var"
    CHROOT_DIR="/var/lib/named"

    dynamic_dir="/var/named/dynamic"  # TBD/TODO
    ;;
esac

echo "final configure/autogen/autoreconf settings:"
echo "  prefix:        $prefix"
echo "  sysconfdir:    $sysconfdir"
echo "  localstatedir: $localstatedir"

# Typically, when shell switches user, current directory switches to new $HOME
cwd_dir="$bind_home_dir"

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
echo "zone_clauses_A[*]: ${zone_clauses_A[*]}"
echo "zone_file_statements_A[*]: ${zone_file_statements_A[*]}"
zone_clauses_count=${#zone_clauses_A[*]}

# Some settings which might be wiped-out by named.conf, selectively.

# Keyword: 'dump-file'
find_config_value "dump-file"
CV_dump_filespec
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
  echo "Redefining 'statistics-file' to $STATISTICS_DIR/$STATISTICS_FILENAME"
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
  echo "Redefining 'memstatistics-file' to $MEMSTATISTICS_DIR/$MEMSTATISTICS_FILENAME"
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
  echo "Redefining 'lock-file' to $LOCK_DIR/$LOCK_FILENAME"
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
  echo "Redefining 'managed-keys-directory' to $MANAGEDKEYS_DIR"
else
  MANAGEDKEYS_DIR="$DEFAULT_MANAGED_KEYS_DIRNAME"
fi

# TODO:  Is that by total views or by total zones?
# UPDATE: Doesn't look like total zones is working
if [ "$zone_clauses_count" -ge 10 ]; then
# Break out filename by numbers of zones greater than 1
  MANAGEDKEYS_FILENAME="<not-a-file>"
  echo "Redefining default 'managed-keys-file' to $MANAGEDKEYS_FILENAME"
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
  echo "Redefining 'random-device' to $RANDOM_DIR/$RANDOM_FILENAME"
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
  echo "Redefining 'pid-file' to $PID_DIR/$PID_FILENAME"
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
  echo "Redefining 'recursing-file' to $RECURSING_DIR/$RECURSING_FILENAME"
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
  echo "Redefining 'secroots-file' to $SECROOTS_DIR/$SECROOTS_FILENAME"
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
  echo "Redefining 'bindkeys-file' to $BINDKEY_DIR/$BINDKEY_FILENAME"
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
  echo "Redefining 'session-file' to $SESSION_KEY_DIR/$SESSION_KEY_FILENAME"
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
  echo "Redefining 'tkey-gssapi-keytab' to $KEYTAB_DIR/$KEYTAB_FILENAME"
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
  echo "Redefining 'key-directory' to $KEYDIR"
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




bind_home="$cwd_dir"
# Directory for managed keys which are dynamically updated
dynamic_dir="/var/bind/dynamic"  # explicit by Bind9 ARM handbook
# Directory for dynamically updated slave zone files.
slave_dir="/var/bind/slave"
# Directory for statistics collecte at runtime.
datadir="/var/log/named"
# Directory for log files
log_dir="/var/log/named"

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


echo "Based on $NAMED_FILESPEC settings..."
echo ""
echo "TMPDIR:		$TMPDIR"
echo "datadir:		$datadir"
echo "Bind username:		$bind_username"
echo "Bind groupname:	$bind_groupname"
echo "Bind shell:		$bind_shell"
echo
echo "SELinux name_zone_t group:"
echo "Bind \$HOME:		$bind_home"
echo "Zone files list:	$zone_files_list"
echo "Zone clauses_A:	${zone_clauses_A[*]}"
echo "Zone file statements_A:	${zone_file_statements_A[*]}"
echo
echo "SELinux name_cache_t group:"
echo "DNSSEC Dynamic Dir:	$dynamic_dir"
echo "Zone Slave Dir:		$slave_dir"
echo "key_dir_list		$key_dir_list"
echo "ManagedKeys filespec:	$MANAGEDKEYS_FILESPEC"
echo "dump filespec:		$dump_filespec"
echo "secroots filespec:	$secroots_filespec"
echo "statistics filespec:	$statistics_filespec"
echo "memstatistics filespec:	$memstatistics_filespec"
echo "KRB5 keytab filespec:	$keytab_filespec"
echo "Session Key:	$SESSION_KEY_FILESPEC"
echo "Journal dir:		$JOURNAL_DIR"
echo "Lock filespec:		$lock_filespec"
echo "ManagedKeys Dir:	$MANAGEDKEYS_DIR"
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
echo 
echo "SELinux misc. group:"
echo "random filespec:	$random_filespec"

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
    echo "$filespec ($varnam): is missing."
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

echo ""
read -rp "CISecurity settings or Debian settings? (C/d): " -eiC
REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"

case $REPLY in
  'd')
  echo "Debian default settings..."
  file_perm_check bind_shell "755" "root" "root"
  file_perm_check bind_home "775" "root" "$bind_username"
  for config_file in $config_files_list; do
    file_perm_check config_file "644" "root" "$bind_username"
  done
  for zone_file in $zone_files_list; do
    file_perm_check zone_file "644" "root" "root"
  done
  file_perm_check CIS_RUNDIR "755" "root" "$bind_username"
  file_perm_check dynamic_dir "2750" "root" "$bind_username"
  file_perm_check slave_dir "770" "root" "$bind_username"
  file_perm_check datadir "770" "root" "$bind_username"
  file_perm_check log_dir "770" "root" "$bind_username"
  for key_dir in $key_dir_list; do
    file_perm_check key_dir "775" "root" "$bind_username"
  done
  file_perm_check TMPDIR "1777" "root" "root"
  # Bind key file shall be world-read for general inspection of file permissions
  file_perm_check BINDKEY "644" "root" "root"
  file_perm_check pid_filespec "644" "$bind_username" "$bind_username"
  # session-key only occurs when DHCP server is coordinating with this DNS
  file_perm_check SESSION_KEY_FILESPEC "600" "$bind_username" "$bind_username"
  file_perm_check JOURNAL_DIR "775" "root" "$bind_username"
  file_perm_check lock_filespec "640" "root" "$bind_username"
  file_perm_check MANAGEDKEYS_DIR "775" "root" "$bind_username"
  if [ -z "$?" ]; then
    file_perm_check MANAGEDKEYS_DIR "775" "root" "$bind_username"
  else
    file_perm_check  "640" "root" "$bind_username"
  fi
  file_perm_check random_filespec "666" "root" "root"
  file_perm_check secroots_filespec "640" "root" "$bind_username"
  file_perm_check dump_filespec "640" "root" "$bind_username"
  file_perm_check statistics_filespec "640" "root" "$bind_username"
  file_perm_check memstatistics_filespec "640" "root" "$bind_username"
  file_perm_check keytab_filespec "640" "root" "$bind_username"
  file_perm_check recursing_filespec  "640" "root" "$bind_username"
  ;;

  'c')
  echo ""
  echo "Recommended CIS settings..."

  file_perm_check bind_home "770" "$bind_username" "$bind_username"
  # shellcheck disable=SC2034
  for config_file in $config_files_list; do
    file_perm_check config_file "640" "root" "$bind_username"
  done
  # shellcheck disable=SC2034
  for zone_file in $zone_files_list; do
    file_perm_check zone_file "640" "root" "$bind_username"
  done
  file_perm_check CIS_RUNDIR "2775" "root" "$bind_username"
  # Key directory shall be world-read for general inspection of file permissions
  # shellcheck disable=SC2034
  for key_dir in $key_dir_list; do
    file_perm_check key_dir "770" "root" "$bind_username"
  done
  file_perm_check pid_filespec "640" "root" "$bind_username"
  file_perm_check SESSION_KEY_FILESPEC "600" "$bind_username" "root"
  file_perm_check JOURNAL_DIR "2750" "$bind_username" "root"
  if [ -z "$?" ]; then
    file_perm_check MANAGEDKEYS_DIR "2750" "$bind_username" "root"
  else
    file_perm_check  "640" "$bind_username" "root"
  fi

#########################
  file_perm_check TMPDIR "1777" "root" "root"
  # Bind key file shall be world-read for general inspection of file permissions
  file_perm_check BINDKEY "644" "root" "root"
  file_perm_check lock_filespec "640" "root" "$bind_username"
  file_perm_check random_filespec "666" "root" "root"
  file_perm_check secroots_filespec "640" "root" "$bind_username"
  file_perm_check dump_filespec "640" "root" "$bind_username"
  file_perm_check statistics_filespec "640" "root" "$bind_username"
  file_perm_check memstatistics_filespec "640" "root" "$bind_username"
  file_perm_check keytab_filespec "640" "root" "$bind_username"
  file_perm_check recursing_filespec  "640" "root" "$bind_username"
  ;;

  'f')
    echo "Fedora default settings..."
    file_perm_check bind_shell "755" "root" "root"

    # Reason for o-rx in named $HOME:
    #   dhcp-client needs access to named session-key
    file_perm_check bind_home "1770" "root" "$bind_groupname"
    for config_file in $config_files_list; do
      file_perm_check config_file "640" "root" "$bind_groupname"
    done
    for zone_file in $zone_files_list; do
      file_perm_check zone_file "640" "$bind_username" "$bind_groupname"
    done
    file_perm_check CIS_RUNDIR "775" "$bind_username" "$bind_groupname"
    file_perm_check dynamic_dir "750" "$bind_username" "$bind_groupname"
    file_perm_check slave_dir "750" "$bind_username" "$bind_groupname"
    file_perm_check datadir "750" "$bind_username" "$bind_groupname"
    file_perm_check log_dir "750" "$bind_username" "$bind_groupname"
    for key_dir in $key_dir_list; do
      file_perm_check key_dir "750" "$bind_username" "$bind_groupname"
    done
    file_perm_check TMPDIR "1777" "root" "root"
    file_perm_check BINDKEY "644" "$bind_username" "$bind_groupname"
    file_perm_check pid_filespec "644" "$bind_username" "$bind_groupname"
    # session-key only occurs when DHCP server is coordinating with this DNS
    file_perm_check SESSION_KEY_FILESPEC "600" "$bind_username" "$bind_groupname"
    file_perm_check JOURNAL_DIR "750" "$bind_username" "$bind_groupname"
    file_perm_check lock_filespec "640" "$bind_username" "$bind_groupname"
    file_perm_check MANAGEDKEYS_DIR "750" "$bind_username" "$bind_groupname"
    if [ -z "$?" ]; then
      file_perm_check MANAGEDKEYS_DIR "750" "$bind_username" "$bind_groupname"
    #else
    #  file_perm_check  "640" "root" "$bind_groupname"
    fi
    file_perm_check random_filespec "666" "root" "root"
    file_perm_check secroots_filespec "640" "$bind_username" "$bind_groupname"
    file_perm_check dump_filespec "640" "$bind_username" "$bind_groupname"
    file_perm_check statistics_filespec "640" "$bind_username" "$bind_groupname"
    file_perm_check memstatistics_filespec "640" "$bind_username" "$bind_groupname"
    file_perm_check keytab_filespec "640" "$bind_username" "$bind_groupname"
    file_perm_check recursing_filespec  "640" "$bind_username" "$bind_groupname"
    ;;

esac

echo "Total files:       $total_files"
echo "File missing:          $total_file_missings"
echo "File errors:           $total_file_errors"
echo "Permission errors:         $total_perm_errors"

