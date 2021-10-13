#!/bin/bash
# File: 150-protocol-tipc.sh
# Title: Remove TIPC protocol kernel module
#
BUILDROOT="${BUILDROOT:-/tmp}"

TIPC_MODULE="tipc"

TIPC_FILENAME="protocol-tipc-no.conf"
TIPC_FILEPATH="/etc/modprobe.d"
TIPC_FILESPEC="${BUILDROOT}/$TIPC_FILEPATH/$TIPC_FILENAME"
echo "CIS recommendation for removal of TIPC Protocol"
echo ""
read -rp "Enter in 'continue' to run: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi
DIRNAME="$(dirname "$TIPC_FILESPEC")"
if [ ! -d "$DIRNAME" ]; then
  echo "Making $DIRNAME directory..."
  sudo mkdir -p "$DIRNAME"
fi
echo "Writing $TIPC_FILESPEC..."
sudo touch "$TIPC_FILESPEC"
sudo chown root:root "$TIPC_FILESPEC"
sudo chmod 0644      "$TIPC_FILESPEC"
sudo cat << PROTOCOL_TIPC_EOF | sudo tee "$TIPC_FILESPEC"
#
# File: $TIPC_FILENAME
# Path: $TIPC_FILEPATH
# Title: Ensure that TIPC protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.3
#
install $TIPC_MODULE /bin/true
PROTOCOL_TIPC_EOF

# Do the removal of tipc kernel module right now
PROTOCOL_TIPC_LOADED="$(lsmod | grep $TIPC_MODULE)"
if [ -n "$PROTOCOL_TIPC_LOADED" ]; then
  sudo rmmod $TIPC_MODULE
fi

echo "Done."
