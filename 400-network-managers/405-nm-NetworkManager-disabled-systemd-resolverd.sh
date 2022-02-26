#!/bin/bash
# File: 405-nm-NetworkManager-disabled-systemd-resolvered.sh
# Title: Prevent systemd-resolvered from engaging in tampering with /etc/resolv.conf
#
# Description:

echo "Disable systemd-resolverd from telling NetworkManager what to do"
echo
echo "Send the connection DNS configuration to"
echo "systemd-resolved."
echo
echo "Defaults to \"true\"."
echo
echo "Note that this setting is complementary to the 'dns' setting."
echo "You can keep this enabled while using 'dns set to"
echo "another DNS plugin alongside systemd-resolved, or"
echo "'dns' set to 'systemd-resolved' to configure the system"
echo "resolver to use systemd-resolved."
echo
echo "If systemd-resolved is enabled, the connectivity"
echo "check resolves the hostname per-device."
echo
echo "systemd-resolved=false"

source ./maintainer-NetworkManager.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-NetworkManager-conf.d-sysd-resolvered-disable.sh"

flex_mkdir "$NETWORKMANAGER_CONFD_DIRSPEC"

FILENAME="no-systemd-resolved.conf"
FILEPATH="$NETWORKMANAGER_CONFD_DIRSPEC"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Disable systemd resolver
#
# Creator: $(basename "$0")
# Date: $(date)
#

[main]

# 'systemd-resolved'
#
#
# Send the connection DNS configuration to
# systemd-resolved.
#
# Defaults to "true".
#
# Note that this setting is complementary to the 'dns' setting.
# You can keep this enabled while using 'dns set to
# another DNS plugin alongside systemd-resolved, or
# 'dns' set to 'systemd-resolved' to configure the system
# resolver to use systemd-resolved.
#
# If systemd-resolved is enabled, the connectivity
# check resolves the hostname per-device.

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
