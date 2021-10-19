#!/bin/bash
# File: 510-cis-dns-bind-dirs.sh
# Title: Check file permissions of various files
#
# Description:
#   Usage:  500-cis-dns-bind-dirs.sh [ -t <chroot-dir> ] <named.conf-filespec>
#
# as guided by a parent named.conf configuration file.
# So split-horizon have two separate parent named.conf (and their own
# set of included configuration files).
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
        [-t|--tempdir <chroot-dir>] \
        [ --help|-h ] [ --verbosity|-v ]
        < named.conf-filespec >
USAGE_EOF
  exit 1
}

# Call getopt to validate the provided input.
options=$(getopt -o ht:vV \
          --long help,tempdir:,verbose,version -- "$@" )
RETSTS=$?
[[ ${RETSTS} -eq 0 ]] || {
    echo "Incorrect options provided"
    cmd_show_syntax_usage
    exit ${RETSTS}
}

CHROOT=
NCC_OPT=
VERBOSITY=0

eval set -- "${options}"
while true; do
    case "$1" in
    -t|--tempdir)
        shift;  # The arg is next in position args
        CHROOT=$1  # deferred argument checking
        NCC_OPT="-t $CHROOT"
        ;;
    -v|--verbose)
        ((VERBOSITY=VERBOSITY+1))
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

SUDO_BIN=
if [ $EUID -ne 0 ]; then
  echo "WARN: User $UID is not root; may need 'sudo' evocation"
  echo "Will user-prompt before any writing operation is needed."
  SUDO_BIN=sudo
fi

NAMED_CHECKCONF_BIN="$(whereis -b named-checkconf | awk '{print $2}')"
if [ -z "$NAMED_CHECKCONF_BIN" ]; then
  echo "named-checkconf is not found; Aborted."
  exit 1
fi

# Auto determine Distro of Linux
LSB_RELEASE="$(whereis -b lsb_release | awk '{print $2}')"
if [ -n "$LSB_RELEASE" ]; then
  DISTRO=$($LSB_RELEASE -s -i)
  # if [ "$DISTRO" = "Debian" ]; then
  #   GROUPNAME='bind'
  # else
  #   GROUPNAME='named'
  # fi
else
  DISTRO='Unknown'
  # GROUPNAME='named'
fi

BIND_USERNAME='bind'
# Pick up the user/group names
TRY_USERNAMES="bind named"
for bind_username in $TRY_USERNAMES; do
  FOUND_BINDNAME_A=("$(grep -E -- "^$bind_username" /etc/passwd)")
  if [ ${#FOUND_BINDNAME_A[@]} -gt 1 ]; then
    echo "Too many $bind_username accounts."
    echo "Aborted"
    exit 9
  elif [ -n "${FOUND_BINDNAME_A[0]}" ]; then
    BIND_USERNAME="${bind_username}"
    BIND_HOMEDIR="$(echo "${FOUND_BINDNAME_A[0]}" | awk -F: '{print $6}')"
  fi
done
echo "Bind9 user account name is automatically determined as: '$BIND_USERNAME'"
if [ -z "$BIND_HOMEDIR" ]; then
  echo "User '$BIND_USERNAME' $HOME directory is undefined"
  echo "Aborted."
  exit 123
fi
echo "User $BIND_USERNAME \$HOME=$BIND_HOMEDIR"

# Now extract that Bind9 user $HOME directory (also varied across distros)
# named needs a $HOME for statistics, dump-files, cache dumps.
# named puts other files elsewhere depending on static/dynamic/write/read needs
# Keyword: 'directory'
find_bind_home="$(grep "$BIND_USERNAME" /etc/passwd | awk -F: '{print $6}')"
if [ -z "$find_bind_home" ]; then
  echo "Unable to determine $HOME for '$BIND_USERNAME' user."
  echo "Aborted"
  exit 123
else
  DEFAULT_USER_HOME_DIRNAME="$find_bind_home"
fi
BIND_SHELL="$(grep -e "^$BIND_USERNAME" /etc/passwd|awk -F: '{print $7}')"
# Later, we can override USER_HOME with named.conf's 'directory' keyword,
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
  if [ $RETSTS -eq 0 ]; then
    echo "OK, we found the $NAMED_FILESPEC file but it requires SUDO operation."
    echo "to read it.  Rest of this script will use SUDO but for read-only operation."
    echo "...Alternatively, you can copy the configs to /tmp or set all"
    echo "...file permission to world-read."
    echo "No changes shall be made."
  else
    read -rp "Enter in Bind9 config file: " -ei/etc/bind/named.conf
    if [ ! -f "REPLY" ]; then
      echo "No such file: $REPLY"
      echo "Aborted."
      exit 111
    fi
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
  val="$($SUDO_BIN cat "$NAMED_FILESPEC" | grep -E -- "^\s*[\s\{]*\s*include\s*")"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  val="$(echo "$val" | xargs)"
  CONFIG_VALUE="$val"
  unset val
}

# List of primary configuration file and all included configuration files.
CONFIG_FILES="$NAMED_FILESPEC"
find_include_clauses
CONFIG_FILES="$NAMED_FILESPEC $CONFIG_VALUE"


# Read the entire config file
echo ""
echo "Reading in $NAMED_FILESPEC..."
echo "May need access via sudo..."
# Capture non-STDERR output of named-checkconf, if any
# shellcheck disable=SC2086
named_conf_all_includes="$("$SUDO_BIN" "$NAMED_CHECKCONF_BIN" $NCC_OPT -p -x "$NAMED_FILESPEC" 2>/dev/null)$"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  # capture only STDERR output of named-checkconf
  # shellcheck disable=SC2086
  errmsg="$("$SUDO_BIN" "$NAMED_CHECKCONF_BIN" $NCC_OPT -p -x "$NAMED_FILESPEC" 1>/dev/null)"
  echo "Need to fix error in $NAMED_FILESPEC before going further"
  echo "CLI: $SUDO_BIN $NAMED_CHECKCONF_BIN $NCC_OPT -p -x $NAMED_FILESPEC"
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
  # named_conf_all_includes="$($SUDO_BIN named-checkconf -p -x $NAMED_FILESPEC 2>/dev/null)$"
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
  ZONE_FILE_STATEMENTS_A[$zone_idx_tmp]="$zone_files_list"
  unset regex_file_statements t tmp_fidx zone_files_list zone_idx_tmp
}

find_zone_clauses()
{
  ZONE_IDX=0
  ZONE_CLAUSES_A=()
  local s=$1 named_conf_by_zone_a=()
  # If you added any more pairs of (), you must add BASH_REMATCH[n+1] below
  regex_zone_clauses='[^zone]*zone[\n[:space:]]*(\S{1,64})[\n[:space:]]*\S{0,6}[\n[:space:]]*(\{[\n[:space:]]*)[^zone]*'
  #echo "find_zone_clauses: called"
  while [[ $s =~ $regex_zone_clauses ]]; do
    ZONE_CLAUSES_A[$ZONE_IDX]="$(echo "${BASH_REMATCH[1]}" | xargs)"
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
DATADIR=$DATAROOTDIR

# TODO Need additional clarity with CHROOT
# SYSROOT=/   # used with chroot?
# CHROOT_DIR="/var/named"  # Bind9 ARM handbook

# CIS-specific default???
DYNDIR="/var/lib/bind/dynamic"  # Debian 9,10,11

# distro-specific default
DISTRO='Debian'
if [ "$DISTRO" = 'Debian' ]; then
  prefix="/usr"
  sysconfdir="/etc/bind"
  localstatedir=""
  # CHROOT_DIR="/var/lib/named"

  DYNDIR="/var/lib/bind/dynamic"  # Debian 9,10,11

elif [ "$DISTRO" = 'Redhat' ]; then
  prefix="/usr"
  sysconfdir="/etc/bind"
  localstatedir="/var"
  # CHROOT_DIR="/var/lib/named"

  DYNDIR="/var/lib/bind/dynamic"  # TBD/TODO
fi

echo "final configure/autogen/autoreconf settings:"
echo "  prefix:        $prefix"
echo "  sysconfdir:    $sysconfdir"
echo "  localstatedir: $localstatedir"

# Typically, when shell switches user, current directory switches to new $HOME
CWD_DIR="$BIND_HOMEDIR"

# Now for CIS defaults
# Directory for temporary runtime files, typically '/var/run/named'
# This CIS_RUNDIR setting cannot be changed by config file????
CIS_RUNDIR="$localstatedir/run/named"


# Now for the many default settings
# DEFAULT_RNDC_CONF_DIRNAME="$sysconfdir"
# DEFAULT_RNDC_CONF_FILENAME="rndc.conf"
DEFAULT_DUMP_DIRNAME="$CWD_DIR"
DEFAULT_DUMP_FILENAME="named_dump.db"  # named/config.c/defaultconf
DEFAULT_STATISTICS_DIRNAME="$CWD_DIR"
DEFAULT_STATISTICS_FILENAME="named.stats"   # named/config.c/defaultconf
DEFAULT_MEMSTATISTICS_DIRNAME="$CWD_DIR"  # TODO: needs verification
DEFAULT_MEMSTATISTICS_FILENAME="named.memstats"  # named/config.c/defaultconf
# named-checkconf seems to pick up autoreconf/autogen/configure settings
# by doing 'named-checkconf -V'
DEFAULT_LOCKFILE_DIRNAME="$localstatedir/run/named"  # TODO sure its localstatedir?
DEFAULT_LOCKFILE_FILENAME="named.lock"
DEFAULT_MANAGED_KEYS_DIRNAME="$CWD_DIR"  # named/server.c
DEFAULT_MANAGED_KEYS_FILENAME="managed-keys.bind"  # only if 'view-less'
DEFAULT_RANDOM_DIRNAME="/dev"
DEFAULT_RANDOM_FILENAME="random"  # bind9/config.h #define PATH_RANDOMDEV
DEFAULT_PIDFILE_DIRNAME="$localstatedir/run/named"  # named/config.c/defaultconf
DEFAULT_PIDFILE_FILENAME="named.pid"  # named/config.c/defaultconf
DEFAULT_SECROOTS_DIRNAME="$CWD_DIR"
DEFAULT_SECROOTS_FILENAME="named.secroots"  # named/config.c/defaultconf
DEFAULT_BINDKEY_DIRNAME="$sysconfdir"
DEFAULT_BINDKEY_FILENAME="bind.keys"
DEFAULT_SESSION_KEYFILE_DIRNAME="$localstatedir/run/named"  # named/config.c/defaultconf
DEFAULT_SESSION_KEYFILE_FILENAME="session.key"  # named/config.c/defaultconf
DEFAULT_GSSAPI_KEYTAB_DIRNAME="/etc"
DEFAULT_GSSAPI_KEYTAB_FILENAME="krb5.key"
# no default for Zone files, must be explicit, must be a minimum of one
# for authoritative level 1/2 server.  Might have zone(s) in caching mode.
DEFAULT_KEY_DIRNAME="/var/cache/bind"  # Do not put CWD_DIR/BIND_HOME in here
DEFAULT_RECURSING_DIRNAME="$CWD_DIR"
DEFAULT_RECURSING_FILENAME="named.recursing"

DEFAULT_JOURNAL_DIRNAME="$CWD_DIR"
#DEFAULT_JOURNAL_FILENAME="$DEFAULT_MANAGED_KEYS_FILENAME.jnl"

# Scan entire configuration for 'zone's and 'logging, channel's

# Find all 'zone' clauses in config file
find_zone_clauses "$named_conf_all_includes"
echo "ZONE_CLAUSES_A[*]: ${ZONE_CLAUSES_A[*]}"
echo "ZONE_FILE_STATEMENTS_A[*]: ${ZONE_FILE_STATEMENTS_A[*]}"
ZONES_COUNT=${#ZONE_CLAUSES_A[*]}

# Some settings which might be wiped-out by named.conf, selectively.

# Keyword: 'dump-file'
find_config_value "dump-file"
CV_DUMP_FILESPEC
if [ -n "$CV_DUMP_FILESPEC" ]; then
  DUMP_DIR="$(dirname "$CV_DUMP_FILESPEC")"
  DUMP_FILENAME="$(basename "$CV_DUMP_FILESPEC")"
else
  DUMP_DIR="$DEFAULT_DUMP_DIRNAME"
  DUMP_FILENAME="$DEFAULT_DUMP_FILENAME"
fi
DUMP_FILESPEC="$DUMP_DIR/$DUMP_FILENAME"

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
STATISTICS_FILESPEC="$STATISTICS_DIR/$STATISTICS_FILENAME"

# Keyword: 'memstatistics_file'
# TODO: We think memstats goes into $CWD_DIR directory also
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
MEMSTATISTICS_FILESPEC="$MEMSTATISTICS_DIR/$MEMSTATISTICS_FILENAME"

# Keyword: 'geoip-directory'  # going obsolete due its geoip-directory
#   being incorporated into libmaxmindb library.

# Keyword: 'lock-file'
find_config_value "lock-file"
CV_LOCK_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_LOCK_FILESPEC" ]; then
  LOCK_DIR="$(dirname "$CV_LOCK_FILESPEC")"
  LOCK_FILENAME="$(basename "$CV_LOCK_FILESPEC")"
  echo "Redefining 'lock-file' to $LOCK_DIR/$LOCK_FILENAME"
else
  LOCK_DIR="$DEFAULT_LOCKFILE_DIRNAME"
  LOCK_FILENAME="$DEFAULT_LOCKFILE_FILENAME"
fi
LOCK_FILESPEC="$LOCK_DIR/$LOCK_FILENAME"

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
if [ "$ZONES_COUNT" -ge 10 ]; then
# Break out filename by numbers of zones greater than 1
  MANAGEDKEYS_FILENAME="<not-a-file>"
  echo "Redefining default 'managed-keys-file' to $MANAGEDKEYS_FILENAME"
else
  MANAGEDKEYS_FILENAME="$DEFAULT_MANAGED_KEYS_FILENAME"
fi
MANAGEDKEYS_FILESPEC="$MANAGEDKEYS_DIR/$MANAGEDKEYS_FILENAME"

# Keyword: 'random-device'
find_config_value "random-device"
CV_RANDOM_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_RANDOM_FILESPEC" ]; then
  RANDOM_DIR="$(dirname "$CV_RANDOM_FILESPEC")"
  RANDOM_FILENAME="$(basename "$CV_RANDOM_FILESPEC")"
  echo "Redefining 'random-device' to $RANDOM_DIR/$RANDOM_FILENAME"
else
  RANDOM_DIR="$DEFAULT_RANDOM_DIRNAME"
  RANDOM_FILENAME="$DEFAULT_RANDOM_FILENAME"
fi
RANDOM_FILESPEC="$RANDOM_DIR/$RANDOM_FILENAME"

# Keyword: 'pid-file'
find_config_value "pid-file"
CV_PID_FILESPEC="$CONFIG_VALUE"
if [ -n "$CV_PID_FILESPEC" ]; then
  PID_DIR="$(dirname "$CV_PID_FILESPEC")"
  PID_FILENAME="$(basename "$CV_PID_FILESPEC")"
  echo "Redefining 'pid-file' to $PID_DIR/$PID_FILENAME"
else
  PID_DIR="$DEFAULT_PIDFILE_DIRNAME"
  PID_FILENAME="$DEFAULT_PIDFILE_FILENAME"
fi
PID_FILESPEC="$PID_DIR/$PID_FILENAME"

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
RECURSING_FILESPEC="$RECURSING_DIR/$RECURSING_FILENAME"

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
SECROOTS_FILESPEC="$SECROOTS_DIR/$SECROOTS_FILENAME"

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
KEYTAB_FILESPEC="$KEYTAB_DIR/$KEYTAB_FILENAME"

# Keyword: 'file'  by zones
# All zone files referenced in the configuration files regardless of DNS server
# type
ZONE_FILES="$(echo "${ZONE_FILE_STATEMENTS_A[*]}" | xargs)"
if [ ${#ZONE_CLAUSES_A[*]} -gt 1 ]; then
  MANAGED_KEYS_FILENAME=""
else
  MANAGED_KEYS_FILENAME="managed-keys"
fi

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
KEYDIR_LIST="$KEYDIR"   # decommission KEYDIR due to multiple directories
# Do not put $BIND_HOME in 'key-directory' ENV_VAR
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


bind_cfg_files="/etc/bind/*.conf"
its_dir_exist "$bind_cfg_files"

# in case of split-horizon




BIND_HOME="$CWD_DIR"
# Directory for managed keys which are dynamically updated
DYNDIR="/var/bind/dynamic"  # explicit by Bind9 ARM handbook
# Directory for dynamically updated slave zone files.
SLAVEDIR="/var/bind/slave"
# Directory for statistics collecte at runtime.
DATADIR="/var/log/named"
# Directory for log files
LOGDIR="/var/log/named"

# Directory for temporary files - Typically, '/tmp',
# some methods for named to define temporary files are:
# systemd service TmpDir
# TMPDIR environment variable
TMPDIR="/tmp"  # system-default, man tmpfile(3)

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
echo "BIND_USERNAME: $BIND_USERNAME"
echo "BIND_SHELL:   $BIND_SHELL"
echo "CONFIG_FILES: $CONFIG_FILES"
echo "ZONE_FILES:   $ZONE_FILES"
echo "BIND_HOME:    $BIND_HOME"
echo "CIS_RUNDIR:   $CIS_RUNDIR"
echo "DYNDIR:       $DYNDIR"
echo "SLAVEDIR:     $SLAVEDIR"
echo "DATADIR:      $DATADIR"
echo "LOGDIR:       $LOGDIR"
echo "TMPDIR:       $TMPDIR"
echo "KEYDIR_LIST   $KEYDIR_LIST"
echo "BINDKEY:      $BINDKEY"
echo "ZONE_CLAUSES_A: ${ZONE_CLAUSES_A[*]}"
echo "ZONE_FILE_STATEMENTS_A: ${ZONE_FILE_STATEMENTS_A[*]}"
echo "PID_FILESPEC: $PID_FILESPEC"
echo "SESSION_KEY_FILESPEC: $SESSION_KEY_FILESPEC"
echo "JOURNAL_DIR:          $JOURNAL_DIR"
echo "LOCK_FILESPEC:        $LOCK_FILESPEC"
echo "MANAGEDKEYS_DIR:      $MANAGEDKEYS_DIR"
echo "MANAGEDKEYS_FILESPEC: $MANAGEDKEYS_FILESPEC"
echo "RANDOM_FILESPEC:      $RANDOM_FILESPEC"
echo "SECROOTS_FILESPEC:    $SECROOTS_FILESPEC"
echo "DUMP_FILESPEC:        $DUMP_FILESPEC"
echo "STATISTICS_FILESPEC:  $STATISTICS_FILESPEC"
echo "MEMSTATISTICS_FILESPEC: $MEMSTATISTICS_FILESPEC"
echo "KEYTAB_FILESPEC:      $KEYTAB_FILESPEC"

# Testing all directories for its file permission and file ownership settings


TOTAL_FILES=0
TOTAL_FILE_MISSINGS=0
TOTAL_FILE_ERRORS=0
TOTAL_PERM_ERRORS=0

function file_perm_check
{
  ((TOTAL_FILES+=1))
  local filespec expected_fmod expected_groupname expected_username varnam
  varnam=$1
  # shellcheck disable=SC2086
  eval filespec=\$$1
  $SUDO_BIN ls -1 "$filespec" >/dev/null 2>&1
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "$filespec ($varnam): is missing."
    ((TOTAL_FILE_MISSINGS+=1))
  else
    local err_per_file msg_a this_fmod this_username this_groupname
    expected_fmod=$2
    expected_username=$3
    expected_groupname=$4
    err_per_file=0
    msg_a=()
    this_fmod="$($SUDO_BIN stat -c%a "$filespec")"
    this_username="$($SUDO_BIN stat -c%U "$filespec")"
    this_groupname="$($SUDO_BIN stat -c%G "$filespec")"
    if [ "$expected_fmod" != "$this_fmod" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_fmod' file permission"
      ((TOTAL_PERM_ERRORS+=1))
      ((err_per_file+=1))
    fi
    if [ "$expected_username" != "$this_username" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_username' username"
      ((TOTAL_PERM_ERRORS+=1))
      ((err_per_file+=1))
    fi
    if [ "$expected_groupname" != "$this_groupname" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_groupname' group name"
      ((TOTAL_PERM_ERRORS+=1))
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
      ((TOTAL_FILE_ERRORS+=1))
    fi
    unset err_per_file
  fi
  unset filespec expected_fmod expected_groupname expected_username varnam
}
echo "BIND_USERNAME: $BIND_USERNAME"

echo ""
read -rp "CISecurity settings or Debian settings? (C/d): " -eiC
REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"

if [ "$REPLY" != "c" ]; then
  echo "Debian default settings..."
  file_perm_check BIND_SHELL "755" "root" "root"
  file_perm_check BIND_HOME "775" "root" "$BIND_USERNAME"
  for config_file in $CONFIG_FILES; do
    file_perm_check config_file "644" "root" "$BIND_USERNAME"
  done
  for zone_file in $ZONE_FILES; do
    file_perm_check zone_file "644" "root" "root"
  done
  file_perm_check CIS_RUNDIR "775" "root" "$BIND_USERNAME"
  file_perm_check DYNDIR "2750" "root" "$BIND_USERNAME"
  file_perm_check SLAVEDIR "770" "root" "$BIND_USERNAME"
  file_perm_check DATADIR "770" "root" "$BIND_USERNAME"
  file_perm_check LOGDIR "770" "root" "$BIND_USERNAME"
  for key_dir in $KEYDIR_LIST; do
    file_perm_check key_dir "775" "root" "$BIND_USERNAME"
  done
  file_perm_check TMPDIR "1777" "root" "root"
  # Bind key file shall be world-read for general inspection of file permissions
  file_perm_check BINDKEY "644" "root" "root"
  file_perm_check PID_FILESPEC "644" "$BIND_USERNAME" "$BIND_USERNAME"
  # session-key only occurs when DHCP server is coordinating with this DNS
  file_perm_check SESSION_KEY_FILESPEC "600" "$BIND_USERNAME" "$BIND_USERNAME"
  file_perm_check JOURNAL_DIR "775" "root" "$BIND_USERNAME"
  file_perm_check LOCK_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check MANAGEDKEYS_DIR "775" "root" "$BIND_USERNAME"
  if [ -z "$MANAGED_KEYS_FILENAME" ]; then
    file_perm_check MANAGEDKEYS_DIR "775" "root" "$BIND_USERNAME"
  else
    file_perm_check MANAGED_KEYS_FILENAME "640" "root" "$BIND_USERNAME"
  fi
  file_perm_check RANDOM_FILESPEC "666" "root" "root"
  file_perm_check SECROOTS_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check DUMP_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check STATISTICS_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check MEMSTATISTICS_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check KEYTAB_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check RECURSING_FILESPEC  "640" "root" "$BIND_USERNAME"

else
  echo ""
  echo "Recommended CIS settings..."

  file_perm_check BIND_HOME "770" "$BIND_USERNAME" "$BIND_USERNAME"
  # shellcheck disable=SC2034
  for config_file in $CONFIG_FILES; do
    file_perm_check config_file "640" "root" "$BIND_USERNAME"
  done
  # shellcheck disable=SC2034
  for zone_file in $ZONE_FILES; do
    file_perm_check zone_file "640" "root" "$BIND_USERNAME"
  done
  file_perm_check CIS_RUNDIR "2775" "root" "$BIND_USERNAME"
  # Key directory shall be world-read for general inspection of file permissions
  # shellcheck disable=SC2034
  for key_dir in $KEYDIR_LIST; do
    file_perm_check key_dir "770" "root" "$BIND_USERNAME"
  done
  file_perm_check PID_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check SESSION_KEY_FILESPEC "600" "$BIND_USERNAME" "root"
  file_perm_check JOURNAL_DIR "2750" "$BIND_USERNAME" "root"
  if [ -z "$MANAGED_KEYS_FILENAME" ]; then
    file_perm_check MANAGEDKEYS_DIR "2750" "$BIND_USERNAME" "root"
  else
    file_perm_check MANAGED_KEYS_FILENAME "640" "$BIND_USERNAME" "root"
  fi

#########################
  file_perm_check TMPDIR "1777" "root" "root"
  # Bind key file shall be world-read for general inspection of file permissions
  file_perm_check BINDKEY "644" "root" "root"
  file_perm_check LOCK_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check RANDOM_FILESPEC "666" "root" "root"
  file_perm_check SECROOTS_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check DUMP_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check STATISTICS_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check MEMSTATISTICS_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check KEYTAB_FILESPEC "640" "root" "$BIND_USERNAME"
  file_perm_check RECURSING_FILESPEC  "640" "root" "$BIND_USERNAME"

fi

echo "Total files:       $TOTAL_FILES"
echo "File missing:          $TOTAL_FILE_MISSINGS"
echo "File errors:           $TOTAL_FILE_ERRORS"
echo "Permission errors:         $TOTAL_PERM_ERRORS"

