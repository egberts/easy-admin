#!/bin/bash
# File: 123-cis-apparmor.sh
# Title: Ensure that apparmor is running
#

echo "Ensure that apparmor is running ..."

BUILDROOT=${BUILDROOT:-/tmp}

echo "Checking if apparmor packages are installed..."
dpkg --status apparmor >/dev/null
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "apparmor is not installed."
  echo "Attempting installation of apparmor ..."
  sudo apt install apparmor
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "ERROR: unable to install apparmor; errno $RETSTS"
    exit $RETSTS
  fi
else
  echo "apparmor package is installed"
fi

# Check if utilities for apparmor is installed as well
dpkg --status apparmor-utils >/dev/null
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "apparmor-utils is not installed."
  echo "Attempting installation of apparmor-utils ..."
  sudo apt install apparmor-utils
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "ERROR: unable to install apparmor-utils; errno $RETSTS"
    exit $RETSTS
  fi
else
  echo "apparmor-utils package is installed"
fi

echo "Reading /boot/grub/grub.cfg for any missing options..."

# /boot access may be privilege, sudo this

APPARMOR_IN_CMDLINE="$(sudo grep '^\s*linux' /boot/grub/grub.cfg | grep -v 'apparmor=1')"
SECAPPARMOR_IN_CMDLINE="$(sudo grep '^\s*linux' /boot/grub/grub.cfg | grep -v 'security=apparmor')"

if [ -n "$APPARMOR_IN_CMDLINE" ] || \
   [ -n "$SECAPPARMOR_IN_CMDLINE" ]; then
  if [ -n "$APPARMOR_IN_CMDLINE" ]; then
    echo "Missing 'apparmor=1' in /boot/grub/grub.cfg"
  fi
  if [ -n "$SECAPPARMOR_IN_CMDLINE" ]; then
    echo "Missing 'security=apparmor' in /boot/grub/grub.cfg"
  fi
  GRUB_CMDLINE_FILENAME="grub"
  GRUB_CMDLINE_FILEPATH="/etc/default"
  GRUB_CMDLINE_FILESPEC="${BUILDROOT}$GRUB_CMDLINE_FILEPATH/$GRUB_CMDLINE_FILENAME"
  if [ ! -d "$GRUB_CMDLINE_FILEPATH" ]; then
    echo "Making $GRUB_CMDLINE_FILEPATH directory ..."
    sudo mkdir -p "$GRUB_CMDLINE_FILEPATH"
  fi
  echo "Need to insert the following in $GRUB_CMDLINE_FILEPATH/$GRUB_CMDLINE_FILENAME"
  echo "Creating $GRUB_CMDLINE_FILESPEC..."
  cat << GRUB_CMDLINE_EOF | sudo tee "$GRUB_CMDLINE_FILESPEC"
#
# Check that no other GRUB_CMDLINE_LINUX exist
#
# Run 'update-grub' after any changes
#
GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"

GRUB_CMDLINE_EOF
  echo "Aborted."
  exit 11
fi
echo "Done."
