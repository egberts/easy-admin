#!/bin/bash
# File: 405-network-manager-wifi-privacy.sh
# Title: Disable Wifi Privacy by preventing randomizing MAC address
#
# Description:
#   Newer WiFi access points now offer to randomize the 802.11 clients' MAC address as a privacy feature.
#   For some WiFi installation who use direct mapping of MAC address to DHCP client IP address, this is
#   not a viable feature to have this WiFi Privacy enabled and randomly changing MAC address.
#
#   This script will instruct NetworkManager to turn off this random selection of MAC address of all SSIDs
#   for clients trying to join this SSID.

echo "Set up NetworkManager to turn off WiFi Privacy feature"
echo

source ./maintainer-NetworkManager.sh

FILE_SETTINGS_FILESPEC="file-NetworkManager-conf.d-wifi-privacy-off.sh"

echo "Disable randomization of MAC address in Wifi"
FILENAME="wifi_rand_mac.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Disable randomization of clients' MAC address during joining a WiFi SSID
#
# Description:
#   Newer WiFi access points now offer to randomize the 802.11 clients' MAC address as a privacy feature.
#   For some WiFi installation who use direct mapping of MAC address to DHCP client IP address, this is
#   not a viable feature to have this WiFi Privacy enabled and randomly changing MAC address.
#
#   This script will instruct NetworkManager to turn off this random selection of MAC address of all SSIDs
#   for clients trying to join this SSID.
#
# Creator: $(realpath "$0")
# Date: $(date)
#

[device]
wifi.scan-rand-mac-address=no

NM_CONF
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to create $FILESPEC; error $retsts"
  exit $retsts
fi
flex_chown root:root "$FILESPEC"
flex_chmod 0640 "$FILESPEC"

echo
echo "Done."