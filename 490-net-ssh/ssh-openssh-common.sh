#
# File: dhcp-isc-common.sh
# Title: Common settings for ISC DHCP

# Debian specific
# package_tarname= got broken apart by Debian into
# "openssh-server"/openssh-client

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build/}"
BUILD_SSH="${BUILDROOT}/partial-ssh"

source installer.sh


DEFAULT_ETC_CONF_DIRNAME="ssh"
source os-distro.sh

