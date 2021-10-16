#!/bin/bash
# File: 150-protocol-rds.sh
# Title: Remove RDS protocol kernel module
#
BUILDROOT="${BUILDROOT:-/tmp}"

RDS_MODULE="rds"

RDS_FILENAME="protocol-rds-no.conf"
RDS_FILEPATH="/etc/modprobe.d"
RDS_FILESPEC="${BUILDROOT}/$RDS_FILEPATH/$RDS_FILENAME"
echo "CIS recommendation for removal of RDS Protocol"
echo ""
read -rp "Enter in 'continue' to run: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi
DIRNAME="$(dirname "$RDS_FILESPEC")"
if [ ! -d "$DIRNAME" ]; then
  echo "Making $DIRNAME directory..."
  sudo mkdir -p "$DIRNAME"
fi
echo "Writing $RDS_FILESPEC..."
sudo touch "$RDS_FILESPEC"
sudo chown root:root "$RDS_FILESPEC"
sudo chmod 0644      "$RDS_FILESPEC"
sudo cat << PROTOCOL_RDS_EOF | sudo tee "$RDS_FILESPEC"
#
# File: $RDS_FILENAME
# Path: $RDS_FILEPATH
# Title: Ensure that RDS protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.3
#
install $RDS_MODULE /bin/true
PROTOCOL_RDS_EOF

# Do the removal of rds kernel module right now
PROTOCOL_RDS_LOADED="$(lsmod | grep $RDS_MODULE)"
if [ -n "$PROTOCOL_RDS_LOADED" ]; then
  sudo rmmod $RDS_MODULE
fi

echo "Done."
