#!/bin/bash
# File: 150-protocol-tipc.sh
# Title: Remove TIPC protocol kernel module
#
echo "CIS recommendation for removal of TIPC Protocol"
echo ""
CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/os-modules-protocol-tipc.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -f "$FILE_SETTINGS_FILESPEC"
fi

source ../easy-admin-installer.sh

tipc_module="tipc"

tipc_filename="protocol-tipc-no.conf"
tipc_filepath="/etc/modprobe.d"
tipc_filespec="$tipc_filepath/$tipc_filename"

if [ ! -d "$tipc_filepath" ]; then
  echo "INFO: No module support found in  $tipc_filepath; aborted"
  exit 1
fi

# build area
# Flex-create that build directory (later via script)
  
flex_ckdir "/etc"
flex_ckdir "$tipc_filepath"

flex_chown root:root "$tipc_filepath"
flex_chmod 0755 "$tipc_filepath"

echo "Writing ${BUILDROOT}${CHROOT_DIR}$tipc_filespec..."
flex_touch "$tipc_filespec"
flex_chown root:root "$tipc_filespec"
flex_chmod 0644      "$tipc_filespec"
cat << PROTOCOL_TIPC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$tipc_filespec" >/dev/null 2>&1
#
# File: $tipc_filename
# Path: $tipc_filepath
# Title: Ensure that TIPC protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.3
#
install $tipc_module /bin/true
PROTOCOL_TIPC_EOF
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to create $tipc_filespec; errno $RETSTS; aborted."
  exit $RETSTS
fi

echo ""

echo "Done."

