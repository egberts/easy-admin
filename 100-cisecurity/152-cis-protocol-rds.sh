#!/bin/bash
# File: 150-protocol-rds.sh
# Title: Remove RDS protocol kernel module
#
echo "CIS recommendation for removal of RDS Protocol"
echo ""
CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/os-modules-protocol-rds.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm "$FILE_SETTINGS_FILESPEC"
fi

source installer.sh

rds_module="rds"

rds_filename="protocol-rds-no.conf"
rds_filepath="/etc/modprobe.d"
rds_filespec="$rds_filepath/$rds_filename"

# check if ACTUAL modules.d directory exists
if [ ! -d "$rds_filepath" ]; then
  # create that directory later on
  flex_mkdir "$rds_filepath"
  flex_chown root:root "$rds_filepath"
  flex_chmod 0755      "$rds_filepath"
fi

echo "Writing $rds_filespec..."
flex_touch "$rds_filespec"
flex_chown root:root "$rds_filespec"
flex_chmod 0644      "$rds_filespec"
cat << PROTOCOL_RDS_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$rds_filespec"
#
# File: $rds_filename
# Path: $rds_filepath
# Title: Ensure that RDS protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.3
#
install $rds_module /bin/true
PROTOCOL_RDS_EOF
echo ""

echo "Done."
