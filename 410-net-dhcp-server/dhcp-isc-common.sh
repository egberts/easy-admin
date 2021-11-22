#
# File: dhcp-isc-common.sh
# Title: Common settings for ISC DHCP

package_tarname="isc-dhcp-server"

DEFAULT_ETC_CONF_DIRNAME="dhcp"

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build/}"
BUILD_ISC="${BUILDROOT}/partial-dhcp"

source installer.sh
source os-distro.sh
