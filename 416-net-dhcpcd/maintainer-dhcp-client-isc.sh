#
# File: maintainer-dhcp-client-isc.sh
# Title: Common settings for ISC DHCP client
# Description:
#
# importable environment name
#   INSTANCE - a specific instance out of multiple instances of DHCP server daemons
#
#   Debian 12
#   SYSCONFDIR =         /etc
#   SBINDIR =            /sbin
#   LIBDIR =             /lib
#   LIBEXECDIR =         /libexec
#   DBDIR =              /var/db/dhcpcd
#   RUNDIR =             /var/run/dhcpcd
#   MANDIR =             /usr/share/man
#   DATADIR =            /usr/share
#   HOOKSCRIPTS =        50-ntp.conf
#   EGHOOKSCRIPTS =      50-yp.conf
#   STATUSARG =
#   PRIVSEPUSER =        dhcpcd




CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ../easy-admin-installer.sh

source ../distro-os.sh

case $ID in
  debian|devuan)
    ETC_DHCPCD_SUBDIRNAME=""
    LIBEXEC_DHCPCD_DIRPATH="/libexec"
    VAR_RUN_DHCPCD_SUBDIRPATH="$rundir/dhcp"
    VAR_DB_DHCPCD_SUBDIRPATH="/var/db/dhcp"
    USER_NAME="dhcpcd"
    GROUP_NAME="root"
    package_tarname="dhcp-client"
    ;;
#  fedora|centos|redhat)
#    ETC_DHCPCD_SUBDIRNAME="dhcpcd"
#    VAR_DHCPCD_SUBDIRNAME="dhcpcd"
#    USER_NAME="dhcpd"
#    GROUP_NAME="dhcpd"
#    package_tarname="dhcpcd"
#    ;;
  arch)
    ETC_DHCPCD_SUBDIRNAME="dhcpcd"
    VAR_DHCPCD_SUBDIRNAME="dhcpcd"
    USER_NAME="dhcpcd"
    GROUP_NAME="root"
    package_tarname="dhcp-client"
    ;;
  *)
    echo "Unknown Linux OS distro: '$ID'; aborted."
    exit 3
esac

if [ -n "$ETC_DHCPCD_SUBDIRNAME" ]; then
  extended_sysconfdir="${ETC_DIRSPEC}/$ETC_DHCPCD_SUBDIRNAME"
else
  extended_sysconfdir="$sysconfdir"
fi

ETC_DHCPCD_DIRSPEC="$extended_sysconfdir"
VAR_LIB_DHCPCD_DIRSPEC="${VAR_LIB_DIRSPEC}/$VAR_DHCP_SUBDIRNAME"
LEASE_DIRSPEC="${VAR_LIB_DHCP_DIRSPEC}"
DHCPCD_EXIT_HOOKS_DIRNAME="dhclient-exit-hooks.d"
DHCPCD_ENTER_HOOKS_DIRNAME="dhclient-enter-hooks.d"
EXIT_HOOKS_DIRSPEC="${extended_sysconfdir}/$DHCPCD_EXIT_HOOKS_DIRNAME"
ENTER_HOOKS_DIRSPEC="${extended_sysconfdir}/$DHCPCD_ENTER_HOOKS_DIRNAME"

# Instantiations

