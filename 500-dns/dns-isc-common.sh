#
# File: dns-isc-common.sh
# Title: Common settings for DNS DHCP


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source installer.sh
source os-distro.sh

case $ID in
  debian)
    USER_NAME="bind"
    GROUP_NAME="bind"
    package_tarname="bind"
    ;;
  fedora)
    USER_NAME="named"
    GROUP_NAME="named"
    package_tarname="bind"
    ;;
  redhat)
    USER_NAME="named"
    GROUP_NAME="named"
    package_tarname="bind"
    ;;
  centos)
    USER_NAME="named"
    GROUP_NAME="named"
    package_tarname="bind"
    ;;
esac

if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep named /etc/passwd | awk -F: '{print $6}')"
fi

