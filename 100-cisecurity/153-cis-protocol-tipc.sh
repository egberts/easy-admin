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
flex_mkdir "/etc"
flex_mkdir "$tipc_filepath"
if [ ! -d "$tipc_filepath" ]; then
  flex_chown root:root "$tipc_filepath"
  flex_chmod 0755 "$tipc_filepath"
fi

echo "Writing $tipc_filespec..."
flex_touch "$tipc_filespec"
flex_chown root:root "$tipc_filespec"
flex_chmod 0644      "$tipc_filespec"
cat << PROTOCOL_TIPC_EOF | tee "${BUILDROOT}${CHROOT_DIR}$tipc_filespec" >/dev/null
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
echo ""

echo "Done."

