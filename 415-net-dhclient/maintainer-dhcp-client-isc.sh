#
# File: maintainer-dhcp-client-isc.sh
# Title: Common settings for ISC DHCP client
# Description:
#
# importable environment name
#   INSTANCE - a specific instance out of multiple instances of DHCP server daemons



CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ../easy-admin-installer.sh

source ../distro-os.sh

case $ID in
  debian|devuan)
    ETC_DHCP_SUBDIRNAME="dhcp"
    VAR_DHCP_SUBDIRNAME="dhcp"
    USER_NAME="root"
    GROUP_NAME="root"
    package_tarname="isc-dhcp-client"
    ;;
  fedora|centos|redhat)
    ETC_DHCP_SUBDIRNAME="dhcp"
    VAR_DHCP_SUBDIRNAME="dhcp"
    USER_NAME="dhcpd"
    GROUP_NAME="dhcpd"
    package_tarname="dhclient"
    ;;
  arch)
    ETC_DHCP_SUBDIRNAME="dhcp"
    VAR_DHCP_SUBDIRNAME="dhcp"
    USER_NAME="dhcp"
    GROUP_NAME="dhcp"
    package_tarname="dhclient"
    ;;
  *)
    echo "Unknown Linux OS distro: '$ID'; aborted."
    exit 3
esac

if [ -n "$ETC_DHCP_SUBDIRNAME" ]; then
  extended_sysconfdir="${ETC_DIRSPEC}/$ETC_DHCP_SUBDIRNAME"
else
  extended_sysconfdir="$sysconfdir"
fi

ETC_DHCP_DIRSPEC="$extended_sysconfdir"
VAR_LIB_DHCP_DIRSPEC="${VAR_LIB_DIRSPEC}/$VAR_DHCP_SUBDIRNAME"
LEASE_DIRSPEC="${VAR_LIB_DHCP_DIRSPEC}"
DHCLIENT_EXIT_HOOKS_DIRNAME="dhclient-exit-hooks.d"
DHCLIENT_ENTER_HOOKS_DIRNAME="dhclient-enter-hooks.d"
EXIT_HOOKS_DIRSPEC="${extended_sysconfdir}/$DHCLIENT_EXIT_HOOKS_DIRNAME"
ENTER_HOOKS_DIRSPEC="${extended_sysconfdir}/$DHCLIENT_ENTER_HOOKS_DIRNAME"

# Instantiations

