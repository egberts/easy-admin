#!/bin/bash
# File: 111-usb-storage-no.sh
# Title: Remove USB storage kernel module
#

chroot_dir="${chroot_dir:-}"
buildroot_param="${BUILDROOT:-build}"
BUILDROOT="${buildroot_param}${chroot_dir}"

echo "To disable USB storage access support; enter in 'continue' and press ENTER: "
read -r CONTINUE
if [ "$CONTINUE" != "continue" ]; then
  echo "Aborted."
  exit 255
fi

usbs_filename="usb_storage.conf"
usbs_dirpath="/etc/modprobe.d"
usbs_filespec="${BUILDROOT}${usbs_dirpath}/$usbs_filename"
echo "CIS recommendation for removal of Debian USB Storage"
echo ""
read -rp "Enter in 'continue' to run: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi

if [ ! -d "$BUILDROOT" ]; then
  mkdir -p "$BUILDROOT"
fi
if [ ! -d "${BUILDROOT}/$usbs_dirpath" ]; then
  mkdir -p "${BUILDROOT}/$usbs_dirpath"
fi

echo "Writing $usbs_filespec..."
sudo touch "$usbs_filespec"
sudo chown root:root "$usbs_filespec"
sudo chmod 0644      "$usbs_filespec"
sudo cat << USB_STORAGE_EOF | sudo tee "$usbs_filespec"
install usb-storage /bin/true
USB_STORAGE_EOF

# Do the removal of usb-storage right now
USB_STORAGE_LOADED="$(lsmod | grep usb-storage)"
if [ -n "$USB_STORAGE_LOADED" ]; then
  sudo rmmod usb-storage
fi

echo "Done."
