#
# File: maintainer-firewall-shorewall.sh
# Title: Common settings for Shorewall firewall
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   SHOREWALL_CONF
#   VAR_LIB_SHOREWALL_DIRNAME - useful for multi-instances of 'shorewall' daemons


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ./easy-admin-installer.sh

DEFAULT_ETC_CONF_DIRNAME="shorewall"

source ./distro-os.sh

# ISC Bind9 configuration filename default
SHOREWALL_CONF_FILENAME="shorewall.conf"
SHOREWALL_CONF_DIRSPEC="$extended_sysconfdir"

case $ID in
  debian|devuan)
    LOG_SUB_DIRNAME=""
    VAR_LIB_SHOREWALL_DIRNAME="${VAR_LIB_SHOREWALL_DIRNAME:-bind}"
    VAR_LIB_SHOREWALL_DIRSPEC="/var/lib/$VAR_LIB_SHOREWALL_DIRNAME"
    if [ "$VERSION_ID" -ge 11 ]; then
      DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/bind/$SHOREWALL_CONF_FILENAME}"
    else
      DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/$SHOREWALL_CONF_FILENAME}"
    fi
    package_tarname="bind9"
    systemd_unitname="bind"
    sysvinit_unitname="bind9"
    default_chroot_dirspec="/var/lib/shorewall"
    ;;
  fedora|redhat|centos)
    LOG_SUB_DIRNAME=""
    VAR_LIB_SHOREWALL_DIRNAME="${VAR_LIB_SHOREWALL_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_SHOREWALL_DIRSPEC="/var/${VAR_LIB_SHOREWALL_DIRNAME}"
    DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/$SHOREWALL_CONF_FILENAME}"
    package_tarname="bind"
    systemd_unitname="shorewall"
    sysvinit_unitname="shorewall"
    default_chroot_dirspec="/var/shorewall/chroot"
    ;;
  arch)
    LOG_SUB_DIRNAME="shorewall"
    VAR_LIB_SHOREWALL_DIRNAME="${VAR_LIB_SHOREWALL_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_SHOREWALL_DIRSPEC="$libdir/${VAR_LIB_SHOREWALL_DIRNAME}"
    DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/$SHOREWALL_CONF_FILENAME}"
    package_tarname="bind"
    systemd_unitname="shorewall"
    sysvinit_unitname="shorewall"
    default_chroot_dirspec="/var/shorewall/chroot"
    ;;
esac

log_dir="/var/log/$LOG_SUB_DIRNAME"

if [  -z "$VAR_LIB_SUB_DIRNAME" ]; then
  libdir="/var/${DEFAULT_LIB_SHOREWALL_DIRNAME}"
else
  libdir="/var/${DEFAULT_LIB_SHOREWALL_DIRNAME}"
fi

# Data?  It's where statistics, memstatistics, dump, and secdata go into
DEFAULT_DATA_DIRSPEC="${VAR_LIB_SHOREWALL_DIRSPEC}/data"



# Use the 'which -a' which follows $PATH to pick up all 'shorewall' binaries
# choose the first one or choose the ones in SysV/systemd?
# (or let the end-user choose it?)
# Make the SysV/systemd-selected ones the default, then let user choose it
# if there are more than one
shorewall_bins_a=()
shorewall_bins_a=($(which -a shorewall | awk '{print $1}'))

# If there is more than one, use first one as the user-default
if [ ${#shorewall_bins_a[@]} -ge 4 ]; then

  # Quick and see if systemctl cat shorewall.service can clue us to which binary
  systemd_shorewall_bin="$(systemctl cat "${systemd_unitname}.service" | grep "ExecStart="|awk -F= '{print $2}' | awk '{print $1}')"
  if [ $? -eq 0 ] && [ -n "$systemd_shorewall_bin" ]; then
    default_shorewall_bin="$systemd_shorewall_bin"
    echo "Choosing systemd-default: $systemd_shorewall_bin"
  else
    default_shorewall_bin="${shorewall_bins_a[0]}"
    echo "Choosing first 'which' listing: ${shorewall_bins_a[0]}"
  fi
  while true ; do
    i=1
    echo "Found the following 'shorewall' binaries:"
    for o in "${shorewall_bins_a[@]}"; do
      echo "  $i) $o"
      ((i++))
    done
    read -rp "The index to which 'shorewall' binary to use? [$default_shorewall_bin]: "
    if [ -z "$REPLY" ]; then
      shorewall_bin="${default_shorewall_bin}"
      break;
    fi
    if [[ "$REPLY" =~ ^-?[0-9]+$ ]]; then
      if [ "$REPLY" -le "${#shorewall_bins_a[@]}" ]; then
        ((REPLY--))
        echo "$REPLY= $REPLY"
        shorewall_bin="${shorewall_bins_a[REPLY]}"
        break;
      fi
    else
      shorewall_bin="$REPLY"
      break;
    fi
  done
  # echo "'shorewall' selected: ${shorewall_bin}"
else
  shorewall_bin="${shorewall_bins_a[0]}"
  echo "Only one 'shorewall' found: $(echo ${shorewall_bins_a[*]} | xargs)"
fi
echo "Using 'shorewall' binary in: $shorewall_bin"


# Now ensure that we use the same tools as  this daemon
shorewall_sbin_dirspec="$(dirname "$shorewall_bin")"
tool_dirspec="$(dirname "$shorewall_sbin_dirspec")"

shorewall_bin_dirspec="${tool_dirspec}/bin"
shorewall_checkconf_filespec="${shorewall_bin_dirspec}/shorewall-checkconf"
shorewall_checkzone_filespec="${shorewall_bin_dirspec}/shorewall-checkzone"
shorewall_compilezone_filespec="${shorewall_bin_dirspec}/shorewall-compilezone"
shorewall_journalprint_filespec="${shorewall_bin_dirspec}/shorewall-journalprint"
shorewall_rrchecker_filespec="${shorewall_bin_dirspec}/shorewall-rrchecker"

# Check for user-supplied shorewall.conf
# use 'shorewall -V' to get default shorewall.conf to use as a default
# scan /etc/shorewall/*.conf for any
# Prompt for shorewall.conf

if [ -z "$SHOREWALL_CONF" ]; then
  # DEFAULT_SHOREWALL_CONF_FILESPEC="/etc/shorewall.conf"  # TODO: temporary
  SYSTEMD_SHOREWALL_CONF="$(systemctl cat "${systemd_unitname}.service"|egrep "Environment\s*=\s*SHOREWALLCONF\s*="|awk -F= '{print $3}')"
  if [ -n "$SYSTEMD_SHOREWALL_CONF" ]; then
    echo "systemd ${systemd_unitname}.service unit uses this config file: $SYSTEMD_SHOREWALL_CONF"
  else
    echo "No shorewall.conf found in 'systemctl cat ${systemd_unitname}.service'"
    # Execute 'shorewall -V' to get 'shorewall configuration' default setting
    SBIN_SHOREWALL_CONF_FILESPEC="$("$shorewall_bin" -V|grep 'shorewall configuration:'|awk '{print $3}')"
    # Might be an older 'shorewall -V' with no output
    if [ -z "$SBIN_SHOREWALL_CONF_FILESPEC" ]; then
      echo "Older 'shorewall' binary offered no shorewall.conf default dirpath;"
      SHOREWALL_CONF_FILESPEC="$DEFAULT_SHOREWALL_CONF_FILESPEC"
      echo "Using ISC default shorewall.conf: $DEFAULT_SHOREWALL_CONF_FILESPEC"
    else
      echo "Binary 'shorewall' built-in config default: $SBIN_SHOREWALL_CONF_FILESPEC"
      SHOREWALL_CONF_FILESPEC="$SBIN_SHOREWALL_CONF_FILESPEC"
    fi
  fi
else
  echo "User-defined shorewall.conf: $SHOREWALL_CONF"
fi

unset SHOREWALL_CONF

