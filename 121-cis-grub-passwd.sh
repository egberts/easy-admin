#!/bin/bash
# File: 121-cis-grub-passwd.sh
# Title:  Add boot password for enabling changes to GRUB menu
#
# Environment:
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Prerequisites:
#   grub (grub)
#   gawk (awk)
#   sudo (sudo)
#   coreutils (tee, chown, chmod, touch)
#
# References:
#   https://help.ubuntu.com/community/Grub2/Passwords

BUILDROOT=${BUILDROOT:-/tmp}

echo "Reading /boot/grub/grub.cfg..."
GRUB_PASSWORD_CFG_FILESPEC="${BUILDROOT}/etc/grub.d/45-grub-password.cfg"
FOUND_SET_SUPERUSERS="$(sudo grep "^set\ssuperusers" /boot/grub/grub.cfg)"
FOUND_PASSWORD="$(sudo grep "^password\s" /boot/grub/grub.cfg)"

if [ -z "$FOUND_SET_SUPERUSERS" ] || \
   [ -z "$FOUND_PASSWORD" ]; then
  if [ -z "$FOUND_SET_SUPERUSERS" ]; then
    echo "Unable to find 'set superusers' in /boot/grub/grub.cfg"
    echo "Due to tainted kernel (made by end-users), these settings"
    echo "are probably best done in /etc/grub.d/password-boot.cfg"
    echo "  Some settings are:"
    echo "     set superusers=\"$USER\""
  fi
  if [ -z "$FOUND_PASSWORD" ]; then
    echo ""
    echo "Unable to find 'password' in /boot/grub/grub.cfg"
    echo "Due to tainted kernel (made by end-users), these settings"
    echo "are probably best done in $GRUB_PASSWORD_CFG_FILESPEC file"
    echo "  To verify a password:"
    echo "     password_pbkdf2 <$USER> <encrypted_password>"
    echo "  To create a password:"
    echo "     grub-mkpasswd-pbkdf2"
    echo ""
    read -rp "Shall I insert your password into this cfg file? (N/y): " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print $1}')"
    if [ -n "$REPLY" ] && [ "$REPLY" == 'y' ]; then
      if [ ! -d "$(dirname "$GRUB_PASSWORD_CFG_FILESPEC")" ]; then
        echo "Creating $GRUB_PASSWORD_CFG_FILESPEC directory..."
        mkdir -p "$(dirname "$GRUB_PASSWORD_CFG_FILESPEC")"
      fi
      # PASSWD="$(grub-mkpasswd-pbkdf2)"
      sudo touch "$GRUB_PASSWORD_CFG_FILESPEC"
      sudo chown root:root "$GRUB_PASSWORD_CFG_FILESPEC"
      sudo chmod 0640 "$GRUB_PASSWORD_CFG_FILESPEC"
      echo ""
      echo "Creating $GRUB_PASSWORD_CFG_FILESPEC..."
      cat << GRUB_PASSWORD_EOF | sudo tee "$GRUB_PASSWORD_CFG_FILESPEC"
#
# Use 'grub-mkpasswd-pbkdf2' utility to insert encrypted-password
#
# Run 'update-grub' after password is cut-n-pasted.
#
set superusers="$USER"
password_pbkdf2 $USER <encrypted-password>

GRUB_PASSWORD_EOF
      RETSTS=$?
      if [ $RETSTS -ne 0 ]; then
        echo "Error $RETSTS writing $GRUB_PASSWORD_CFG_FILESPEC"
        echo "Aborted."
      fi
    fi
  fi
fi

read -rp "Need to reboot without a password? (Y/n): " -eiY
REPLY="$(echo "${REPLY:0:1}"|awk '{print $1}')"
if [ "$REPLY" == 'y' ]; then
  LINUX_CLASS_FILESPEC="${BUILDROOT}/etc/grub.d/10_linux"
  if [ ! -d "$(dirname "$LINUX_CLASS_FILESPEC")" ]; then
    echo "Creating $LINUX_CLASS_FILESPEC directory..."
    mkdir -p "$(dirname "$LINUX_CLASS_FILESPEC")"
  fi
  cat << LINUX_CLASS_EOF | sudo tee "$LINUX_CLASS_FILESPEC"
#
# To allow the system to boot without entering a password.
# Password will still be required to edit menu items.
# Still useful to prevent disabling apparmor at kernel command line.
#
# To implement this, run 'update-grub'
#
CLASS="--class gnu-linux --class gnu --class os --unrestricted"

LINUX_CLASS_EOF
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "Error $RETSTS writing $LINUX_CLASS_FILESPEC"
    echo "Aborted."
  fi
fi
echo "Done."
exit 0
