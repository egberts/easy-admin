#
# File: dns-isc-common.sh
# Title: Common settings for DNS DHCP
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   NAMED_CONF
#   VAR_LIB_NAMED_DIRNAME


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source installer.sh
source os-distro.sh


case $ID in
  debian)
    USER_NAME="bind"
    GROUP_NAME="bind"
    WHEEL_GROUP="sudo"
    ETC_SUB_DIRNAME="bind"
    LOG_SUB_DIRNAME="named"
    HOME_DIRSPEC="/var/cache/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-bind}"
    VAR_LIB_NAMED_DIRSPEC="/var/lib/${VAR_LIB_NAMED_DIRNAME}"
    if [ "$VERSION_ID" -ge 11 ]; then
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/bind/named.conf}"
    else
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/named.conf}"
    fi
    package_tarname="bind9"
    systemd_unitname="bind"
    sysvinit_unitname="bind9"
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
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/named.conf}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
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
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/named.conf}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
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
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/named.conf}"
    package_tarname="bind"
    systemd_unitname="named"
    sysvinit_unitname="named"
    ;;
esac

log_dir="/var/log/$LOG_SUB_DIRNAME"

if [ -n "$ETC_SUB_DIRNAME" ]; then
  extended_sysconfdir="${sysconfdir}/${ETC_SUB_DIRNAME}"
else
  extended_sysconfdir="${sysconfdir}"
fi

if [  -z "$VAR_LIB_SUB_DIRNAME" ]; then
  libdir="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
else
  libdir="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
fi

if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep named /etc/passwd | awk -F: '{print $6}')"
fi
if [ -z "$NAMED_SHELL_DIRSPEC" ]; then
  NAMED_SHELL_DIRSPEC="$(grep named /etc/passwd | awk -F: '{print $7}')"
fi

# Data?  It's where statistics, memstatistics, dump, and secdata go into
DEFAULT_DATA_DIRSPEC="${NAMED_HOME_DIRSPEC}/data"

# $HOME is always treated separately from Zone DB; Only Fedora merges them
#
# named 'directory' statement is not the same as named $HOME directory.
# daemon's current working directory is not the same as ('directory' statement)
# named $HOME directory is not the same as named daemon current working dir.
# These three above things are ... three ... separate ... groups of files.
#
# Unmerging would make it easier for 'named' group to be doled out to
# administrators' supplemental group IDlist (much to Fedora's detriments)
DEFAULT_ZONE_DB_DIRSPEC="${DEFAULT_DATA_DIRSPEC}"
DEFAULT_KEYS_DB_DIRSPEC="/var/named/keys"

# DNSSEC-related & managed-keys/trust-anchors
DEFAULT_DYNAMIC_DIRSPEC="/var/named/dynamic"


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
  systemd_named_bin="$(systemctl cat named.service | grep "ExecStart="|awk -F= '{print $2}' | awk '{print $1}')"
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
named_checkconf="${named_sbin_dirspec}/named-checkconf"
named_checkzone="${named_sbin_dirspec}/named-checkzone"
named_compilezone="${named_sbin_dirspec}/named-compilezone"
named_journalprint="${named_sbin_dirspec}/named-journalprint"
named_rrchecker="${named_bin_dirspec}/named-rrchecker"

# Check for named.conf
# if try in 'systemctl cat named.service'
# else if try in SysV initrc '/etc/init.d/named'
# scan /etc/named/*.conf for any
# Prompt for named.conf
