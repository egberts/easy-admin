#
# File: maintainer-dhcp-isc.sh
# Title: Common settings for ISC DHCP

package_tarname="isc-dhcp-server"


CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ./easy-admin-installer.sh

DEFAULT_ETC_CONF_DIRNAME="dhcp"

source ./distro-os.sh

extended_sysconfdir="${sysconfdir}/${DEFAULT_ETC_CONF_DIRNAME}"
