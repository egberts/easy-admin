#
# File: maintainer-NetworkManager.sh
# Title: Package Maintainer-specific settings for NetworkManager

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ../easy-admin-installer.sh

source ../distro-os.sh

DEFAULT_ETC_CONF_DIRNAME="${ETC_DIRSPEC}/NetworkManager"
DEFAULT_EXTENDED_SYSCONFDIR="${ETC_DIRSPEC}/NetworkManager"
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

