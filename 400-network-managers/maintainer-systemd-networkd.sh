#
# File: maintainer-systemd-networkd.sh
# Title: Package Maintainer-specific settings for systemd-networkd

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"


source ../easy-admin-installer.sh
source ../distro-os.sh
FILE_SETTING_PERFORM='yes'

NETWORKMANAGER_CONF_FILENAME="NetworkManager"
NETWORKMANAGER_DIRNAME="NetworkManager"
DEFAULT_NETWORKMANAGER_CONF_FILENAME="$NETWORKMANAGER_CONF_FILENAME.conf"
DEFAULT_NETWORKMANAGER_CONFD_DIRNAME="conf.d"

NETWORKMANAGER_ETC_DIRNAME="$NETWORKMANAGER_DIRNAME"
DEFAULT_EXTENDED_SYSCONFDIR="${ETC_DIRSPEC}/$NETWORKMANAGER_ETC_DIRNAME"
extended_sysconfdir="${extended_sysconfdir:-${DEFAULT_EXTENDED_SYSCONFDIR}}"

if [ "${BUILDROOT:0:1}" != '/' ]; then
  # relative build, create subdirectories
  # absolute build, do not create build directory
  if [ ! -d "$BUILDROOT" ]; then
    mkdir -p "$BUILDROOT"
  fi
  mkdir -p "${BUILDROOT}$extended_sysconfdir"
  BUILD_ABSOLUTE=0
else
  BUILD_ABSOLUTE=1
fi


# Package maintainer-specific

case $ID in
  debian|devuan)
    package_tarname="network-manager"
    nm_systemd_unitname="NetworkManager.service"
    nmwo_systemd_unitname="NetworkManager-wait-online.service"
    USER_NAME="root"
    GROUP_NAME="root"
    ;;
  fedora|centos|redhat)
    package_tarname="network-manager"
    nm_systemd_unitname="NetworkManager.service"
    nmwo_systemd_unitname="NetworkManager-wait-online.service"
    USER_NAME="root"
    GROUP_NAME="root"
    ;;
  arch)
    package_tarname="network-manager"
    nm_systemd_unitname="NetworkManager.service"
    nmwo_systemd_unitname="NetworkManager-wait-online.service"
    USER_NAME="root"
    GROUP_NAME="root"
    ;;
  *)
    echo "Unknown Linux OS '$ID' distro; aborting..."
    exit 1
    ;;
esac

unset varlibdir

ETC_NETWORKMANAGER_DIRSPEC="$DEFAULT_EXTENDED_SYSCONFDIR"


#####################


# /etc/NetworkManager/NetworkManager.conf
NETWORKMANAGER_CONF_FILESPEC="${extended_sysconfdir}/$DEFAULT_NETWORKMANAGER_CONF_FILENAME"

# /var/lib/NetworkManager
varlibdir="${VAR_DIRSPEC}/lib"
NETWORKMANAGER_VAR_LIB_DIRNAME="$NETWORKMANAGER_DIRNAME"
NETWORKMANAGER_VAR_LIB_DIRSPEC="${varlibdir}/$NETWORKMANAGER_VAR_LIB_DIRNAME"

# /etc/NetworkManager/conf.d
NETWORKMANAGER_CONFD_DIRSPEC="${extended_sysconfdir}/$DEFAULT_NETWORKMANAGER_CONFD_DIRNAME"

# Useful directories that autoconf/configure/autoreconf does not offer.
NETWORKMANAGER_RUN_DIRNAME="$NETWORKMANAGER_DIRNAME"
NETWORKMANAGER_RUN_DIRSPEC="${rundir}/$NETWORKMANAGER_RUN_DIRNAME"

NETWORKMANAGER_LOG_DIRNAME="$NETWORKMANAGER_DIRNAME"
NETWORKMANAGER_LOG_DIRSPEC="$LOG_DIRSPEC/$NETWORKMANAGER_LOG_DIRNAME"

unset varlibdir

