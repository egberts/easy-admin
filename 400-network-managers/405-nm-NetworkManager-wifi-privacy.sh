#!/bin/bash
# File: 405-nm-NetworkManager-wifi-privacy.sh
# Title: Disable Wifi Privacy by preventing randomizing MAC address
#
# Description:
#   Newer WiFi access points now offer to randomize the
#   802.11 clients' MAC address as a privacy feature.
#   For some WiFi installation who use direct mapping of
#   MAC address to DHCP client IP address, this is
#   not a viable feature to have this WiFi Privacy
#   enabled and randomly changing MAC address.
#
#   This script will instruct NetworkManager to turn
#   off this random selection of MAC address of all SSIDs
#   for clients trying to join this SSID.

echo "Set up NetworkManager to turn off WiFi Privacy feature"
echo

source ./maintainer-NetworkManager.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-NetworkManager-conf.d-wifi-privacy-off.sh"

flex_mkdir "$NETWORKMANAGER_CONFD_DIRSPEC"

echo "Disable randomization of MAC address in Wifi"
FILENAME="wifi_rand_mac.conf"
FILEPATH="$NETWORKMANAGER_CONFD_DIRSPEC"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Disable randomization of clients' MAC address during joining a WiFi SSID
#
# Description:
#   Newer WiFi access points now offer to randomize the
#   802.11 clients' MAC address as a privacy feature.
#   For some WiFi installation who use direct mapping of
#   MAC address to DHCP client IP address, this is
#   not a viable feature to have this WiFi Privacy enabled
#   and randomly changing MAC address.
#
#   This script will instruct NetworkManager to turn off
#   this random selection of MAC address of all SSIDs
#   for clients trying to join this SSID.
#
# Creator: $(basename "$0")
# Date: $(date)
#

[device]

# 'wifi.scan-rand-mac-address'
#
#
# Configures MAC address randomization of a Wi-Fi
# device during scanning. This defaults to yes in
# which case a random, locally-administered MAC
# address will be used. The setting
# 'wifi.scan-generate-mac-address-mask' allows to
# influence the generated MAC address to use certain
# vendor OUIs. If disabled, the MAC address during
# scanning is left unchanged to whatever is configured.
# For the configured MAC address while the device is
# associated, see instead the per-connection setting
# 'wifi.cloned-mac-address'.

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
