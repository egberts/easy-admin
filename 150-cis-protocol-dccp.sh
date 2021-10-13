#!/bin/bash
# File: 150-protocol-dccp.sh
# Title: Remove DCCP protocol kernel module
#
BUILDROOT="${BUILDROOT:-/tmp}"

DCCP_MODULE="dccp"

DCCP_FILENAME="protocol-dccp-no.conf"
DCCP_FILEPATH="/etc/modprobe.d"
DCCP_FILESPEC="${BUILDROOT}/$DCCP_FILEPATH/$DCCP_FILENAME"
echo "CIS recommendation for removal of DCCP Protocol"
echo ""
read -rp "Enter in 'continue' to run: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi
DIRNAME="$(dirname "$DCCP_FILESPEC")"
if [ ! -d "$DIRNAME" ]; then
  echo "Making $DIRNAME directory..."
  sudo mkdir -p "$DIRNAME"
fi
echo "Writing $DCCP_FILESPEC..."
sudo touch "$DCCP_FILESPEC"
sudo chown root:root "$DCCP_FILESPEC"
sudo chmod 0644      "$DCCP_FILESPEC"
sudo cat << PROTOCOL_DCCP_EOF | sudo tee "$DCCP_FILESPEC"
#
# File: $DCCP_FILENAME
# Path: $DCCP_FILEPATH
# Title: Ensure that DCCP protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.1
#
install $DCCP_MODULE /bin/true
PROTOCOL_DCCP_EOF

# Do the removal of dccp kernel module right now
PROTOCOL_DCCP_LOADED="$(lsmod | grep $DCCP_MODULE)"
if [ -n "$PROTOCOL_DCCP_LOADED" ]; then
  sudo rmmod $DCCP_MODULE
fi

echo "Done."
