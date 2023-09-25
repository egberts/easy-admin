#!/bin/bash
# File: 150-protocol-sctp.sh
# Title: Remove SCTP protocol kernel module
#

echo "CIS recommendation for removal of SCTP Protocol"
echo ""

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/os-modules-protocol-sctp.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -f "$FILE_SETTINGS_FILESPEC"
fi

source ../easy-admin-installer.sh

sctp_module="sctp"

sctp_filename="protocol-sctp-no.conf"
sctp_filepath="/etc/modprobe.d"
sctp_filespec="$sctp_filepath/$sctp_filename"

if [ ! -d "$sctp_filepath" ]; then
  echo "INFO: No module support found in  $sctp_filepath; aborted"
  exit 1
fi

# build area
# Flex-create that build directory (later via script)
flex_ckdir "/etc"
flex_ckdir "$sctp_filepath"

flex_chmod 0755 "$sctp_filepath"
flex_chown root:root "$sctp_filepath"

echo "Writing ${BUILDROOT}${CHROOT_DIR}$sctp_filespec..."
flex_touch "$sctp_filespec"
flex_chown root:root "$sctp_filespec"
flex_chmod 0644      "$sctp_filespec"
cat << PROTOCOL_SCTP_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}/$sctp_filespec" >/dev/null 2>&1
#
# File: $sctp_filename
# Path: $sctp_filepath
# Title: Ensure that SCTP protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.2
#
install $sctp_module /bin/true
PROTOCOL_SCTP_EOF
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to create $sctp_filespec; errno $RETSTS; aborted."
  exit $RETSTS
fi

echo ""

echo "Done."
