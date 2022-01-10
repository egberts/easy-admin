#
# File: dhcp-isc-common.sh
# Title: Common settings for ISC DHCP

package_tarname="isc-dhcp-server"


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ./installer.sh

DEFAULT_ETC_CONF_DIRNAME="dhcp"

source ./os-distro.sh

extended_sysconfdir="${sysconfdir}"

