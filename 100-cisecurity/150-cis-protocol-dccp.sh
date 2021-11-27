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

source installer.sh

dccp_module="dccp"

dccp_filename="protocol-dccp-no.conf"
dccp_filepath="/etc/modprobe.d"
dccp_filespec="$dccp_filepath/$dccp_filename"

# check ACTUAL modules.d directory
if [ ! -d "$dccp_filepath" ]; then
  # Flex create that directory (later via script)
  flex_mkdir "$dccp_filepath"
  flex_chown root:root "$dccp_filepath"
  flex_chmod 0755 "$dccp_filepath"
fi

echo "Writing $dccp_filespec..."
flex_touch "$dccp_filespec"
flex_chown root:root "$dccp_filespec"
flex_chmod 0644      "$dccp_filespec"
cat << PROTOCOL_DCCP_EOF | tee "${BUILDROOT}${CHROOT_DIR}$dccp_filespec"
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
echo ""

echo "Done."

