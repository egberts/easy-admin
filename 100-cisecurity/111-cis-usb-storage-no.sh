#!/bin/bash
# File: 111-usb-storage-no.sh
# Title: Remove USB storage kernel module
#
BUILDROOT="${BUILDROOT:-/tmp}"

USBS_FILENAME="usb_storage.conf"
USBS_DIRPATH="/etc/modprobe.d"
USBS_FILESPEC="${BUILDROOT}${USBS_DIRPATH}/$USBS_FILENAME"
echo "CIS recommendation for removal of Debian USB Storage"
echo ""
read -rp "Enter in 'continue' to run: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi
echo "Writing $USBS_FILESPEC..."
sudo touch "$USBS_FILESPEC"
sudo chown root:root "$USBS_FILESPEC"
sudo chmod 0644      "$USBS_FILESPEC"
sudo cat << USB_STORAGE_EOF | sudo tee "$USBS_FILESPEC"
install usb-storage /bin/true
USB_STORAGE_EOF

# Do the removal of usb-storage right now
USB_STORAGE_LOADED="$(lsmod | grep usb-storage)"
if [ -n "$USB_STORAGE_LOADED" ]; then
  sudo rmmod usb-storage
fi

echo "Done."
