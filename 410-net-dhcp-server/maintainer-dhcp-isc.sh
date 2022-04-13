#
# File: maintainer-dhcp-isc.sh
# Title: Common settings for ISC DHCP
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
    # No USER_NAME
    # No GROUP_NAME
    package_tarname="isc-dhcp-server"
    ;;
  fedora|centos|redhat)
    ETC_DHCP_SUBDIRNAME="dhcp"
    USER_NAME="dhcpd"
    GROUP_NAME="dhcpd"
    package_tarname="dhcpd"
    ;;
  arch)
    ETC_DHCP_SUBDIRNAME="dhcp"
    USER_NAME="dhcp"
    GROUP_NAME="dhcp"
    package_tarname="dhcpd"
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

# Instantiations
