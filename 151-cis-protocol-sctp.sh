#!/bin/bash
# File: 150-protocol-sctp.sh
# Title: Remove SCTP protocol kernel module
#
BUILDROOT="${BUILDROOT:-/tmp}"

SCTP_MODULE="sctp"

SCTP_FILENAME="protocol-sctp-no.conf"
SCTP_FILEPATH="/etc/modprobe.d"
SCTP_FILESPEC="${BUILDROOT}/$SCTP_FILEPATH/$SCTP_FILENAME"
echo "CIS recommendation for removal of SCTP Protocol"
echo ""
read -rp "Enter in 'continue' to run: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi
DIRNAME="$(dirname "$SCTP_FILESPEC")"
if [ ! -d "$DIRNAME" ]; then
  echo "Making $DIRNAME directory..."
  sudo mkdir -p "$DIRNAME"
fi
echo "Writing $SCTP_FILESPEC..."
sudo touch "$SCTP_FILESPEC"
sudo chown root:root "$SCTP_FILESPEC"
sudo chmod 0644      "$SCTP_FILESPEC"
sudo cat << PROTOCOL_SCTP_EOF | sudo tee "$SCTP_FILESPEC"
#
# File: $SCTP_FILENAME
# Path: $SCTP_FILEPATH
# Title: Ensure that SCTP protocol is disabled
# Creator: $(basename "$0")
# Date: $(date)
#
# References:
#   CIS Benchmark - Debian 10 - section 3.4.2
#
install $SCTP_MODULE /bin/true
PROTOCOL_SCTP_EOF

# Do the removal of sctp kernel module right now
PROTOCOL_SCTP_LOADED="$(lsmod | grep $SCTP_MODULE)"
if [ -n "$PROTOCOL_SCTP_LOADED" ]; then
  sudo rmmod $SCTP_MODULE
fi

echo "Done."
