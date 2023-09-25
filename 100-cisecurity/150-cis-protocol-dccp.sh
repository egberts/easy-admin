#!/bin/bash
# File: 150-protocol-dccp.sh
# Title: Remove DCCP protocol kernel module
#

echo "CIS recommendation for removal of DCCP Protocol"
echo ""

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/os-modules-protocol-dccp.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -f "$FILE_SETTINGS_FILESPEC"
fi

source ../easy-admin-installer.sh

dccp_module="dccp"

dccp_filename="protocol-dccp-no.conf"
dccp_filepath="/etc/modprobe.d"
dccp_filespec="$dccp_filepath/$dccp_filename"

if [ ! -d "$dccp_filepath" ]; then
  echo "INFO: No module support found in  $dccp_filepath; aborted"
  exit 1
fi

# build area
# Flex-create that build directory (later via script)
flex_ckdir "/etc"
flex_ckdir "$dccp_filepath"

flex_chown root:root "$dccp_filepath"
flex_chmod 0755 "$dccp_filepath"

echo "Writing ${BUILDROOT}${CHROOT_DIR}$dccp_filespec..."
flex_touch "$dccp_filespec"
flex_chown root:root "$dccp_filespec"
flex_chmod 0644      "$dccp_filespec"
cat << PROTOCOL_DCCP_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$dccp_filespec" >/dev/null 2>&1
#
# File: $dccp_filename
# Path: $dccp_filepath
# Title: Ensure that DCCP protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.1
#
install $dccp_module /bin/true
PROTOCOL_DCCP_EOF
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to create $dccp_filespec; errno $RETSTS; aborted."
  exit $RETSTS
fi
echo ""

echo "Done."

