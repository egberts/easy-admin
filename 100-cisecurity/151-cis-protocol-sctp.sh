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
  rm "$FILE_SETTINGS_FILESPEC"
fi

source installer.sh

sctp_module="sctp"

sctp_filename="protocol-sctp-no.conf"
sctp_filepath="/etc/modprobe.d"
sctp_filespec="$sctp_filepath/$sctp_filename"

# Check if ACTUAL modules.d directory exists
if [ ! -d "$sctp_filepath" ]; then

  # Create that directory later via outputted script
  flex_mkdir "$sctp_filepath"
  flex_chmod 0755 "$sctp_filepath"
  flex_chown root:root "$sctp_filepath"
fi

echo "Writing $sctp_filespec..."
flex_touch "$sctp_filespec"
flex_chown root:root "$sctp_filespec"
flex_chmod 0644      "$sctp_filespec"
cat << PROTOCOL_SCTP_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$sctp_filespec"
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
echo ""

echo "Done."
