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

if [ "${BUILDROOT:0:1}" != '/' ]; then
  # relative build, create directories
  # absolute build, do not create build directory
  if [ ! -d "$BUILDROOT" ]; then
    mkdir -p "$BUILDROOT"
  fi
  mkdir -p "${BUILDROOT}$sysconfdir"
fi

