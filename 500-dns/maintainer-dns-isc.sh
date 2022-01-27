#
# File: maintainer-dns-isc.sh
# Title: Common settings for ISC DNS 
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   INSTANCE
#   VAR_LIB_NAMED_DIRNAME - useful for multi-instances of 'named' daemons


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

source ../easy-admin-installer.sh

SYSD_BIND_TEMPLATE_SVCNAME="named"
SYSD_BIND_SVCNAME="named"
SYSD_BIND_ALT_SVCNAME="bind"

source ../distro-os.sh

# ISC Bind9 configuration filename default
if [ -z "$INSTANCE" ]; then
  NAMED_CONF_FILEPART="named"
  INSTANCE_DIRPATH=""
  INSTANCE_FILEPART=""
else
  NAMED_CONF_FILEPART="named-$INSTANCE"
  INSTANCE_FILEPART="-$INSTANCE"
fi
NAMED_CONF_FILETYPE=".conf"
NAMED_CONF_FILENAME="${NAMED_CONF_FILEPART}${NAMED_CONF_FILETYPE}"

case $ID in
  debian|devuan)
    USER_NAME="bind"
    GROUP_NAME="bind"
    ETC_SUB_DIRNAME="bind"
    VAR_SUB_DIRNAME="bind"
    LOG_SUB_DIRNAME="named"
    HOME_DIRSPEC="/var/cache/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-bind}"
    VAR_LIB_NAMED_DIRSPEC="${VAR_DIRSPEC}/lib/${VAR_LIB_NAMED_DIRNAME}"
    if [ "$VERSION_ID" -ge 11 ]; then
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/${ETC_SUB_DIRNAME}/$NAMED_CONF_FILENAME}"
    else
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    fi
    package_tarname="bind9"
    if [ "$VERSION_ID" -ge 11 ]; then
      systemd_unitname="named"
    else
      systemd_unitname="bind"
    fi
    sysvinit_unitname="named"  # used to be 'bind', quit shifting around
    default_chroot_dirspec="/var/lib/named"
    ;;
  fedora)
    USER_NAME="named"
    GROUP_NAME="named"
    ETC_SUB_DIRNAME="named"
    VAR_SUB_DIRNAME="named"
    LOG_SUB_DIRNAME="named"
    HOME_DIRSPEC="$localstatedir/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_NAMED_DIRSPEC="/var/${VAR_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
    default_chroot_dirspec="/var/named/chroot"
    ;;
  redhat)
    USER_NAME="named"
    GROUP_NAME="named"
    ETC_SUB_DIRNAME="named"
    LOG_SUB_DIRNAME="named"
    VAR_SUB_DIRNAME="named"
    HOME_DIRSPEC="$localstatedir/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_NAMED_DIRSPEC="/var/${VAR_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
    default_chroot_dirspec="/var/named/chroot"
    ;;
  centos)
    USER_NAME="named"
    GROUP_NAME="named"
    ETC_SUB_DIRNAME="named"
    VAR_SUB_DIRNAME="named"
    LOG_SUB_DIRNAME="named"
    HOME_DIRSPEC="$localstatedir/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_NAMED_DIRSPEC="$libdir/${VAR_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
    default_chroot_dirspec="/var/named/chroot"
    ;;
  arch)
    USER_NAME="named"
    GROUP_NAME="named"
    ETC_SUB_DIRNAME="named"
    VAR_SUB_DIRNAME="named"
    LOG_SUB_DIRNAME="named"
    HOME_DIRSPEC="$localstatedir/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_NAMED_DIRSPEC="$libdir/${VAR_LIB_NAMED_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
    default_chroot_dirspec="/var/named/chroot"
    ;;
esac

log_dir="/var/log/$LOG_SUB_DIRNAME"

if [ -n "$ETC_SUB_DIRNAME" ]; then
  extended_sysconfdir="${sysconfdir}/${ETC_SUB_DIRNAME}"
else
  extended_sysconfdir="${sysconfdir}"
fi
ETC_NAMED_DIRSPEC="$extended_sysconfdir"
VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_DIRSPEC}/$VAR_SUB_DIRNAME"

INSTANCE_NAMED_HOME_DIRSPEC="${NAMED_HOME_DIRSPEC}"
INSTANCE_SYSCONFDIR="${extended_sysconfdir}"
INSTANCE_VAR_LIB_NAMED_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
INSTANCE_LOG_DIR="/var/log/$LOG_SUB_DIRNAME"
INSTANCE_VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_NAMED_DIRSPEC}"
if [ -n "$INSTANCE" ]; then
  INSTANCE_NAMED_HOME_DIRSPEC="${NAMED_HOME_DIRSPEC}/$INSTANCE"
  INSTANCE_SYSCONFDIR="${extended_sysconfdir}/${INSTANCE}"
  INSTANCE_VAR_LIB_NAMED_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/$INSTANCE"
  INSTANCE_VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_NAMED_DIRSPEC}/$INSTANCE"
  INSTANCE_LOG_DIR="/var/log/$LOG_SUB_DIRNAME/$INSTANCE"
fi



if [ -z "$NAMED_SHELL_FILESPEC" ]; then
  NAMED_SHELL_FILESPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $7}')"
fi

# Data?  It's where statistics, memstatistics, dump, and secdata go into
DEFAULT_DATA_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/data"

# $HOME is always treated separately from Zone DB; Only Fedora merges them
#
# named 'directory' statement is not the same as named $HOME directory.
# daemon's current working directory is not the same as ('directory' statement)
# named $HOME directory is not the same as named daemon current working dir.
# These three above things are ... three ... separate ... groups of files.
#
# Unmerging would make it easier for 'named' group to be doled out to
# administrators' supplemental group ID list (much to Fedora's detriments)
# and restrict these administrators to just updates of zones.
#
if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $6}')"
fi

# Furthermore, Zone DB directory is now being split into many subdirectories
#  by their zone type (i.e., primary/secondary/hint/mirror/redirect/stub)
#
# Redhat/Fedora already uses 'slaves' zone type for a subdirectory 
# (but that could change to 'secondaries')
DEFAULT_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}"
DEFAULT_ZONE_DB_DIRNAME_A=("primaries", "secondaries", "hints", "mirrors", "redirects", "stubs", "masters", "slaves")
DEFAULT_ZONE_DB_DIRNAME_ALT_A=("primary", "secondary", "hint", "mirror", "redirect", "stub")

# DNSSEC-related & managed-keys/trust-anchors
DEFAULT_DYNAMIC_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/dynamic"

# WHY WOULD WE WANT /etc/named/keys?  We have /var[/lib]/named/keys
# Perhaps statically-defined rndc, XFER, AXFR, and DDNS keys go into /etc/named/keys
# and dynamically-created DNSSEC go into /var[/lib]/named/keys.

DEFAULT_CONF_KEYS_DIRSPEC="${INSTANCE_SYSCONFDIR}/keys"
DEFAULT_KEYS_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"


# Use the 'which -a' which follows $PATH to pick up all 'named' binaries
# choose the first one or choose the ones in SysV/systemd?
# (or let the end-user choose it?)
# Make the SysV/systemd-selected ones the default, then let user choose it
# if there are more than one
named_bins_a=()
named_bins_a=($(which -a named | awk '{print $1}'))

# If there is more than one, use first one as the user-default
if [ ${#named_bins_a[@]} -ge 4 ]; then

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
named_bin_filespec="${named_bin_dirspec}/named"
named_checkconf_filespec="${named_bin_dirspec}/named-checkconf"
named_checkzone_filespec="${named_bin_dirspec}/named-checkzone"
named_compilezone_filespec="${named_bin_dirspec}/named-compilezone"
named_journalprint_filespec="${named_bin_dirspec}/named-journalprint"
named_rrchecker_filespec="${named_bin_dirspec}/named-rrchecker"

# What to do with named.conf?
#   Influencers are:
#    - INSTANCE, takes precedence over all
#    - user CLI argument
#    - named binary compiled-in default

# Check for user-supplied named.conf
# use 'named -V' to get default named.conf to use as a default
# scan /etc/named/*.conf for any
# Prompt for named.conf

if [ -z "$INSTANCE" -a -z "$1" ]; then
  # DEFAULT_NAMED_CONF_FILESPEC="/etc/named.conf"  # TODO: temporary
  SYSTEMD_NAMED_CONF="$(systemctl cat "${systemd_unitname}.service"|egrep "Environment\s*=\s*NAMEDCONF\s*="|awk -F= '{print $3}')"
  if [ -n "$SYSTEMD_NAMED_CONF" ]; then
    echo "systemd ${systemd_unitname}.service unit uses this config file: $SYSTEMD_NAMED_CONF"
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
  if [ -z "$INSTANCE" ]; then
    NAMED_CONF_FILESPEC="$1"
    echo "User-defined named.conf: $1"
  else
    NAMED_CONF_FILESPEC="$DEFAULT_NAMED_CONF_FILESPEC"
    echo "Instance-defined named.conf: $NAMED_CONF_FILESPEC"
  fi
fi

unset named_conf

INIT_DEFAULT_DIRSPEC="/etc/default"
BIND_INIT_DEFAULT_FILENAME="${sysvinit_unitname}"

CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"
DYNAMIC_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/dynamic"
KEYS_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/keys"
DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"

INSTANCE_CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"
INSTANCE_KEYS_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"
INSTANCE_DYNAMIC_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/dynamic"
INSTANCE_DATA_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/data"
if [ -n "$INSTANCE" ]; then
  BIND_INIT_DEFAULT_FILENAME="${sysvinit_unitname}-$INSTANCE"
  INSTANCE_CONF_KEYS_DIRSPEC="${INSTANCE_SYSCONFDIR}/${INSTANCE}/keys"
  INSTANCE_KEYS_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"
  INSTANCE_DYNAMIC_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/dynamic"
  INSTANCE_DATA_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/data"
fi
INSTANCE_INIT_DEFAULT_FILESPEC="$INIT_DEFAULT_DIRSPEC/$BIND_INIT_DEFAULT_FILENAME"


BIND_SERVICE_FILENAME="${sysvinit_unitname}"

# /var/lib/bind[/instance]/dynamic
# clause: 'options' 
# statement: 'managed-keys-directory' 
MANAGED_KEYS_DIRSPEC="${INSTANCE_DYNAMIC_DIRSPEC}"
# clause: 'zone'
# statement: 'key-directory'
ZONE_KEYS_DIRSPEC="${INSTANCE_KEYS_DB_DIRSPEC}"

# /var/cache/bind[/instance]
# all definable within named.conf
JOURNAL_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
JOURNAL_FILENAME="${JOURNAL_DIRSPEC}/myzone.jnl"  # zone 'journal' directive
# clause: 'options' 
# statement: 'dump-file'
DUMP_CACHE_FILENAME="named_dump.db"  # compiled-in default
DUMP_CACHE_DIRSPEC="$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"  # compiled-in default to $HOME/$CWD
DUMP_CACHE_FILESPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}/$DUMP_CACHE_FILENAME"

# named.conf 'options' 'session-keyfile'
# default 'session-keyfile' directory path is compiled-in to $CWD 
#   default directory path is typically /etc/passwd:$HOME
SESSION_KEYFILE_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
# default 'session-keyfile' filename is compiled-in to 'session.key'
SESSION_KEYFILE_FILENAME="${SESSION_KEYFILE_DIRSPEC}/session.key" #  'session-keyfile'

