#!/bin/bash
# File: 405-nm-NetworkManager-own-dhcp-client-resolver-disable.sh
# Title: Prevent NetworkManager's own DHCP client from updating /etc/resolv.conf
#
# NOTE: This does nothing toward other DHCP clients (outside of Network Manager'lsb_release
#       own builtin DHCP client).  This script is often useful for use with
#       ISC DHCP (dhclient) client package.

echo "Disable NetworkManager built-in DHCP client from updating /etc/resolv.conf"
echo

source ./maintainer-NetworkManager.sh

FILE_SETTINGS_FILESPEC="file-NetworkManager-conf.d-dhcp-client-resolver.sh"

echo "Disabled DHCP-driven DNS update"
FILENAME="no-dhcp-dns-update-to-resolver.conf"
FILEPATH="/etc/NetworkManager/conf.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Prevent NetworkManager's own DHCP client from updating /etc/resolv.conf
#
# NOTE: This does nothing toward other DHCP clients (outside of Network Manager'lsb_release
#       own builtin DHCP client).  This script is often useful for use with
#       ISC DHCP (dhclient) client package.
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

echo
echo "Done."
