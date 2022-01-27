#!/bin/bash
# Title: 402-network-manager-nm-misc.sh
#

echo "Set up NetworkManager configurations"

source ./maintainer-NetworkManager.sh

FILE_SETTINGS_FILESPEC="file-NetworkManager-conf.d.sh"

echo "Disable randomization of MAC address in Wifi"
FILENAME="wifi_rand_mac.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
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
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to create $FILESPEC; error $retsts"
  exit $retsts
fi
flex_chown root:root "$FILESPEC"
flex_chmod 0640 "$FILESPEC"

echo "Disable systemd-resolved (resolvconf, et. al.)"
FILENAME="no-systemd-resolved.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
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
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to create $FILESPEC; error $retsts"
  exit $retsts
fi
flex_chown root:root "$FILESPEC"
flex_chmod 0640 "$FILESPEC"

echo "Disabled DHCP-driven DNS update"
FILENAME="no-dhcp-dns-update-to-resolver.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Disable NetworkManager DHCP from updating resolver
#
# Creator: $(realpath "$0")
# Date: $(date)
#

[main]
dns=none

NM_CONF
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to create $FILESPEC; error $retsts"
  exit $retsts
fi
flex_chown root:root "$FILESPEC"
flex_chmod 0640 "$FILESPEC"


