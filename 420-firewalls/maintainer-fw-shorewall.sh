#!/bin/bash
# File: maintainer-fw-shorewall.sh
# Title: Common settings for Shorewall firewall
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   INSTANCE
#   VAR_LIB_SHOREWALL_DIRNAME - useful for multi-instances of daemons

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

source ../easy-admin-installer.sh

SYSD_SHOREWALL_TEMPLATE_SVCNAME="shorewall"
SYSD_SHOREWALL_SVCNAME="shorewall"

source ../distro-os.sh

SHOREWALL_CONF_FILEPART="shorewall"
SHOREWALL_CONF_FILETYPE=".conf"
SHOREWALL_CONF_FILENAME="${SHOREWALL_CONF_FILEPART}${SHOREWALL_CONF_FILETYPE}"

if [ -z "$INSTANCE" ]; then
  INSTANCE_SUBDIRPATH=""
  INSTANCE_SHOREWALL_CONF_FILEPART_SUFFIX=""
else
  INSTANCE_SUBDIRPATH="/$INSTANCE"
  INSTANCE_SHOREWALL_CONF_FILEPART_SUFFIX="-$INSTANCE"
fi
INSTANCE_SHOREWALL_CONF_FILENAME="${SHOREWALL_CONF_FILENAME}"

case $ID in
  debian|devuan)
    USER_NAME="root"
    GROUP_NAME="root"
    ETC_SUB_DIRNAME="shorewall"
    VAR_SUB_DIRNAME="shorewall"
    VAR_LIB_SHOREWALL_DIRNAME="${VAR_LIB_SHOREWALL_DIRNAME:-shorewall}"
    VAR_LIB_SHOREWALL_DIRSPEC="${VAR_DIRSPEC}/lib/${VAR_LIB_SHOREWALL_DIRNAME}"
    if [ "$VERSION_ID" -ge 11 ]; then
      DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/${ETC_SUB_DIRNAME}/$SHOREWALL_CONF_FILENAME}"
    else
      DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/$SHOREWALL_CONF_FILENAME}"
    fi
    package_tarname="shorewall"
    systemd_unitname="shorewall"
    sysvinit_unitname="shorewall"  # used to be 'shorewall', quit shifting around
    default_chroot_dirspec="/var/lib/shorewall"
    ;;
  fedora|centos|redhat)
    USER_NAME="root"
    GROUP_NAME="root"
    ETC_SUB_DIRNAME="shorewall"
    VAR_SUB_DIRNAME="shorewall"
    VAR_LIB_SHOREWALL_DIRNAME="${VAR_LIB_SHOREWALL_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_SHOREWALL_DIRSPEC="/var/${VAR_LIB_SHOREWALL_DIRNAME}"
    DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/$SHOREWALL_CONF_FILENAME}"
    package_tarname="shorewall"
    sysvinit_unitname="shorewall"
    default_chroot_dirspec="/var/shorewall/chroot"
    SYSTEMD_SHOREWALL_UNITNAME="shorewall"
    ;;
  arch)
    USER_NAME="root"
    GROUP_NAME="root"
    ETC_SUB_DIRNAME="shorewall"
    VAR_SUB_DIRNAME="shorewall"
    VAR_LIB_SHOREWALL_DIRNAME="${VAR_LIB_SHOREWALL_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_SHOREWALL_DIRSPEC="$libdir/${VAR_LIB_SHOREWALL_DIRNAME}"
    DEFAULT_SHOREWALL_CONF_FILESPEC="${SHOREWALL_CONF:-/etc/$SHOREWALL_CONF_FILENAME}"
    package_tarname="shorewall"
    sysvinit_unitname="shorewall"
    default_chroot_dirspec="/var/shorewall/chroot"
    SYSTEMD_SHOREWALL_UNITNAME="shorewall"
    ;;
esac

log_dir="/var/log"


if [ -n "$ETC_SUB_DIRNAME" ]; then
  extended_sysconfdir="${sysconfdir}/${ETC_SUB_DIRNAME}"
else
  extended_sysconfdir="${sysconfdir}"
fi
ETC_SHOREWALL_DIRSPEC="$extended_sysconfdir"
SHOREWALL_CONF_FILESPEC="${ETC_SHOREWALL_DIRSPEC}/${SHOREWALL_CONF_FILENAME}"
SYSTEMD_SHOREWALL_UNITNAME="$systemd_unitname"

VAR_CACHE_SHOREWALL_DIRSPEC="${VAR_CACHE_DIRSPEC}/$VAR_SUB_DIRNAME"

SYSTEMD_SHOREWALL_SERVICE="${SYSTEMD_SHOREWALL_UNITNAME}.$SYSTEMD_SERVICE_FILETYPE"
SYSTEMD_SHOREWALL_INSTANCE_SERVICE="${SYSTEMD_SHOREWALL_UNITNAME}@.$SYSTEMD_SERVICE_FILETYPE"

INSTANCE_ETC_SHOREWALL_DIRSPEC="${extended_sysconfdir}"
INSTANCE_SHOREWALL_CONF_FILESPEC="${ETC_SHOREWALL_DIRSPEC}${INSTANCE_SUBDIRPATH}/${INSTANCE_SHOREWALL_CONF_FILENAME}"

INSTANCE_VAR_LIB_SHOREWALL_DIRSPEC="${VAR_LIB_SHOREWALL_DIRSPEC}"
INSTANCE_VAR_LIB_SHOREWALL_PRIMARIES_DIRSPEC="${VAR_LIB_SHOREWALL_DIRSPEC}"
INSTANCE_VAR_LIB_SHOREWALL_SECONDARIES_DIRSPEC="${VAR_LIB_SHOREWALL_DIRSPEC}"
INSTANCE_VAR_CACHE_SHOREWALL_DIRSPEC="${VAR_CACHE_SHOREWALL_DIRSPEC}"
INSTANCE_LOG_DIRSPEC="${log_dir}/${LOG_SUB_DIRNAME}"

INSTANCE_SYSTEMD_SHOREWALL_SERVICE="${SYSTEMD_SHOREWALL_UNITNAME}.$SYSTEMD_SERVICE_FILETYPE"

if [ -n "$INSTANCE" ]; then
  INSTANCE_ETC_SHOREWALL_DIRSPEC="${extended_sysconfdir}/${INSTANCE}"
  INSTANCE_VAR_LIB_SHOREWALL_DIRSPEC="${VAR_LIB_SHOREWALL_DIRSPEC}/$INSTANCE"
  INSTANCE_VAR_CACHE_SHOREWALL_DIRSPEC="${VAR_CACHE_SHOREWALL_DIRSPEC}/$INSTANCE"
  INSTANCE_LOG_DIRSPEC="${log_dir}$LOG_SUB_DIRNAME/$INSTANCE"

  INSTANCE_SYSTEMD_SHOREWALL_SERVICE="${SYSTEMD_SHOREWALL_UNITNAME}@${INSTANCE}.$SYSTEMD_SERVICE_FILETYPE"
fi



if [ -z "$SHOREWALL_SHELL_FILESPEC" ]; then
  SHOREWALL_SHELL_FILESPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $7}')"
fi

if [ -z "$SHOREWALL_HOME_DIRSPEC" ]; then
  SHOREWALL_HOME_DIRSPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $6}')"
fi

# Use the 'which -a' which follows $PATH to pick up all 'shorewall' binaries
# choose the first one or choose the ones in SysV/systemd?
# (or let the end-user choose it?)
# Make the SysV/systemd-selected ones the default, then let user choose it
# if there are more than one
shorewall_bins_a=()
# shellcheck disable=SC2207
shorewall_bins_a=($(which -a shorewall | awk '{print $1}'))

# If there is more than one, use first one as the user-default
if [ ${#shorewall_bins_a[@]} -ge 4 ]; then

  # Quick and see if systemctl cat shorewall.service can clue us to which binary
  systemd_shorewall_bin="$(systemctl cat "${systemd_unitname}.service" | grep "ExecStart="|awk -F= '{print $2}' | awk '{print $1}')"
  retsts=$?
  if [ $retsts -eq 0 ] && [ -n "$systemd_shorewall_bin" ]; then
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
  # echo "Only one 'shorewall' found: $(echo ${shorewall_bins_a[*]} | xargs)"
fi
# echo "Using 'shorewall' binary in: $shorewall_bin"


# Now ensure that we use the same tools as  this daemon
shorewall_sbin_dirspec="$(dirname "$shorewall_bin")"
tool_dirspec="$(dirname "$shorewall_sbin_dirspec")"

shorewall_sbin_filespec="${shorewall_sbin_dirspec}/shorewall"

# What to do with shorewall.conf?
#   Influencers are:
#    - INSTANCE, takes precedence over all
#    - user CLI argument
#    - shorewall binary compiled-in default

INIT_DEFAULT_DIRSPEC="/etc/default"
SHOREWALL_INIT_DEFAULT_FILENAME="${sysvinit_unitname}"

INSTANCE_SHOREWALL_HOME_DIRSPEC="${SHOREWALL_HOME_DIRSPEC}"
INSTANCE_INIT_DEFAULT_FILENAME="${sysvinit_unitname}"
if [ -n "$INSTANCE" ]; then
  INSTANCE_SHOREWALL_HOME_DIRSPEC="${SHOREWALL_HOME_DIRSPEC}${INSTANCE_SUBDIRPATH}"
  INSTANCE_INIT_DEFAULT_FILENAME="${sysvinit_unitname}-$INSTANCE"

fi
INSTANCE_INIT_DEFAULT_FILESPEC="$INIT_DEFAULT_DIRSPEC/$INSTANCE_INIT_DEFAULT_FILENAME"
