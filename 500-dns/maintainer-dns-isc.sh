#
# File: maintainer-dns-isc.sh
# Title: Common settings for ISC DNS 
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   INSTANCE
#   NAMED_CONF
#   VAR_LIB_NAMED_DIRNAME - useful for multi-instances of 'named' daemons


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ./easy-admin-installer.sh

source ./distro-os.sh

# ISC Bind9 configuration filename default
NAMED_CONF_FILENAME="named.conf"
NAMED_CONF_DIRSPEC="$extended_sysconfdir"

case $ID in
  debian)
    USER_NAME="bind"
    GROUP_NAME="bind"
    WHEEL_GROUP="sudo"
    ETC_SUB_DIRNAME="bind"
    LOG_SUB_DIRNAME="named"
    HOME_DIRSPEC="/var/cache/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-bind}"
    if [ -n "$INSTANCE" ]; then
      VAR_LIB_NAMED_DIRSPEC="/var/lib/${VAR_LIB_NAMED_DIRNAME}/$INSTANCE"
    else
      VAR_LIB_NAMED_DIRSPEC="/var/lib/$VAR_LIB_NAMED_DIRNAME"
    fi
    if [ "$VERSION_ID" -ge 11 ]; then
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/bind/$NAMED_CONF_FILENAME}"
    else
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    fi
    package_tarname="bind9"
    systemd_unitname="bind"
    sysvinit_unitname="bind9"
    default_chroot_dirspec="/var/lib/named"
    ;;
  fedora)
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ETC_SUB_DIRNAME="named"
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
    WHEEL_GROUP="wheel"
    ETC_SUB_DIRNAME="named"
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
  centos)
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ETC_SUB_DIRNAME="named"
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
if [ -n "$INSTANCE" ]; then
  extended_sysconfdir="${extended_sysconfdir}/$INSTANCE"
fi

if [  -z "$VAR_LIB_SUB_DIRNAME" ]; then
  libdir="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
else
  libdir="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
fi

if [ -z "$NAMED_SHELL_FILESPEC" ]; then
  NAMED_SHELL_FILESPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $7}')"
fi

# Data?  It's where statistics, memstatistics, dump, and secdata go into
DEFAULT_DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"

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
named_checkconf_filespec="${named_bin_dirspec}/named-checkconf"
named_checkzone_filespec="${named_bin_dirspec}/named-checkzone"
named_compilezone_filespec="${named_bin_dirspec}/named-compilezone"
named_journalprint_filespec="${named_bin_dirspec}/named-journalprint"
named_rrchecker_filespec="${named_bin_dirspec}/named-rrchecker"

# Check for user-supplied named.conf
# use 'named -V' to get default named.conf to use as a default
# scan /etc/named/*.conf for any
# Prompt for named.conf

if [ -z "$NAMED_CONF" ]; then
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
  echo "User-defined named.conf: $NAMED_CONF"
fi

unset NAMED_CONF

CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"

DYNAMIC_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/dynamic"
KEYS_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/keys"
DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"
