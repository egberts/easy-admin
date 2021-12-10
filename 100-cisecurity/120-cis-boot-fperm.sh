#!/bin/bash
# File: 120-cis-fperm-boot.sh
# Title: Knock off group-other file permissions from GRUB boot menu

echo "Lower file permission of /boot/grub config file"
echo ""

source /etc/os-release

GRUB_FILENAME="grub.cfg"
DEFAULT_GRUB_FILESPEC="/etc/default/grub"
echo "Determine OS distro ..."
case $ID in
  'debian')
    GRUB_DIRSPEC="/boot/grub"
    ;;
  'fedora')
    GRUB_DIRSPEC="/boot/grub2"
    ;;
  'centos')
    GRUB_DIRSPEC="/boot/grub2"
    ;;
  'redhat')
    GRUB_DIRSPEC="/boot/grub2"
    ;;
  *)
    echo "Unknown OS type '$ID'; aborted."
    exit 11
    ;;
esac
echo "Distro $ID detected"
echo ""

GRUB_FILESPEC="${GRUB_DIRSPEC}/$GRUB_FILENAME"
echo "Changing file ownership to root:root on $GRUB_FILESPEC ..."
sudo chown root:root "$GRUB_FILESPEC"
echo "Changing file permission og-rwx to $GRUB_FILESPEC ..."
sudo chmod og-rwx    "$GRUB_FILESPEC"
echo ""

echo "Changing file ownership to root:root on $DEFAULT_GRUB_FILESPEC ..."
sudo chown root:root "$DEFAULT_GRUB_FILESPEC"
echo "Changing file permission og-rwx to $DEFAULT_GRUB_FILESPEC ..."
sudo chmod og-rwx    "$DEFAULT_GRUB_FILESPEC"
echo ""

echo "Done."

