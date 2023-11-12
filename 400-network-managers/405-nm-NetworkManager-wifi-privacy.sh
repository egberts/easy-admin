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
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - none
#  create - /etc/NetworkManager/conf.d/wifi_mac_random_no.conf
#         - ./file-NetworkManager-conf.d-wifi-privacy-off.sh
#  modify - none
#  delete - none
#
# Environment Variables:
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Prerequisites (package name):
#   maintainer-NetworkManager.sh
#   basename (coreutils)
#   cat (coreutils)
#   chown (coreutils)
#   chmod (coreutils)
#   date (coreutils)
#   tee (coreutils)
#
# References:
#   https://unix.stackexchange.com/questions/395059/how-to-stop-mac-address-from-changing-after-disconnecting
#

echo "Set up NetworkManager to turn off WiFi Privacy feature"
echo

source ./maintainer-NetworkManager.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-NetworkManager-conf.d-wifi-privacy-off.sh"

flex_ckdir "/etc"
flex_ckdir "/etc/systemd"
flex_ckdir "$DEFAULT_EXTENDED_SYSCONFDIR"
flex_ckdir "$NETWORKMANAGER_CONFD_DIRSPEC"


echo "Disable randomization of MAC address in Wifi"
FILENAME="wifi_mac_random_no.conf"
FILEPATH="$NETWORKMANAGER_CONFD_DIRSPEC"
FILESPEC="$FILEPATH/$FILENAME"
BIN_BASENAME="$(basename $0)"
DATE_TXT="$(date)"
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
# Creator: ${BIN_BASENAME}
# Date: ${DATE_TXT}
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
