#!/bin/bash
# File: 120-cis-boot-fperm.sh
# Title: Knock off group-other file permissions from GRUB boot menu
# Description:
#
# Coding Design
#
# Reads:  /boot/grub2
#         /etc/default/grub
# Modifies: ${BUILDROOT}/boot/grub[2]
# Adds: nothing
#
# ENVIRONMENT variables:
#   BUILDROOT
#

echo "Lower file permission of /boot/grub config file"
echo ""

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"
source ../easy-admin-installer.sh

DEFAULT_ETC_CONF_DIRNAME="chrony"  # feeds into DEFAULT_EXTENDED_SYSCONFDIR in distro-os.sh
source ../distro-os.sh

GRUB_FILENAME="grub.cfg"
DEFAULT_GRUB_FILESPEC="/etc/default/grub"
echo "Determine OS distro ..."
case $ID in
  debian|devuan)
    GRUB_DIRSPEC="/boot/grub"
    ;;
  fedora|centos|redhat)
    GRUB_DIRSPEC="/boot/grub2"
    ;;
  *)
    echo "Unknown OS type '$ID'; aborted."
    exit 11
    ;;
esac
echo "Distro detected: $ID"
echo ""

if [ "${BUILDROOT:0:1}" != '/' ]; then
  mkdir -p "$BUILDROOT"
else
  FILE_SETTING_PERFORM='true'
fi

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-boot-grub.sh"

GRUB_FILESPEC="${GRUB_DIRSPEC}/$GRUB_FILENAME"
echo "Changing file ownership to root:root on $GRUB_FILESPEC ..."
flex_chown root:root "$GRUB_FILESPEC"

echo "Changing file permission og-rwx to $GRUB_FILESPEC ..."
flex_chmod 0600  "$GRUB_FILESPEC"
echo ""

echo "Changing file ownership to root:root on $DEFAULT_GRUB_FILESPEC ..."
flex_chown root:root "$DEFAULT_GRUB_FILESPEC"

echo "Changing file permission og-rwx to $DEFAULT_GRUB_FILESPEC ..."
flex_chmod 0600  "$DEFAULT_GRUB_FILESPEC"
echo ""

echo "Done."

