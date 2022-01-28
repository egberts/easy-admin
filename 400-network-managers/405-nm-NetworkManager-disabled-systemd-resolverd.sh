#!/bin/bash
# File: 405-nm-NetworkManager-disabled-systemd-resolvered.sh
# Title: Prevent systemd-resolvered from engaging in tampering with /etc/resolv.conf
#
# Description:

echo "Disable systemd-resolverd from telling NetworkManager what to do"
echo

source ./maintainer-NetworkManager.sh

FILE_SETTINGS_FILESPEC="file-NetworkManager-conf.d-sysd-resolvered-disable.sh"


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

echo
echo "Done."