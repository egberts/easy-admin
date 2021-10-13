#!/bin/bash
# Title: 402-network-manager-nm-misc.sh
#

echo "Set up NetworkManager configurations"

echo "Disable randomization of MAC address in Wifi"
FILENAME="wifi_rand_mac.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Writing $FILESPEC..."
cat << NM_CONF | sudo tee "$FILESPEC"
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Disable MAC randomization
#
# Creator: $(realpath "$0")
# Date: $(date)
#

[device]
wifi.scan-rand-mac-address=no

NM_CONF

echo "Disable systemd-resolved (resolvconf, et. al.)"
FILENAME="no-systemd-resolved.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Writing $FILESPEC..."
cat << NM_CONF | sudo tee "$FILESPEC"
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Disable systemd resolver
#
# Creator: $(realpath "$0")
# Date: $(date)
#

[main]
systemd-resolved=false

NM_CONF



