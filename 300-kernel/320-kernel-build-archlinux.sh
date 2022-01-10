#!/bin/bash
#
# Source: https://wiki.archlinux.org/title/Kernel/Traditional_compilation

KERNEL_VERSION="helium6"  # the part that goes into `uname -r`
LINUX_VERSION=5.15.12

# SUDO_BIN=echo  # testing
SUDO_BIN=/usr/bin/sudo


# Unchangable things below

LINUX_VERSION_1="$(echo "$LINUX_VERSION" | awk -F. '{print $1}')"
LINUX_VERSION_2="$(echo "$LINUX_VERSION" | awk -F. '{print $2}')"
MKINIT_VERSION="linux${LINUX_VERSION_1}${LINUX_VERSION_2}"

# if [ 0 -eq 1  ]; then
# sudo pacman -Syu
# sudo pacman -S --needed git base-devel
# fi

echo "Constructing modprobed-db from AUR ..."
MODPROBED_DB_BIN="$(which modprobed-db)"
if [ -z "$MODPROBED_DB_BIN" ]; then
  git clone https://aur.archlinux.org/modprobed-db.git
  pushd . || exit 9
  cd modprobed-db || exit 10
  makepkg
  pacman -U modprobed-db.tar.xz
  popd || exit 11
  MODPROBED_DB_BIN="$(which modprobed-db)"
fi

$MODPROBED_DB_BIN store && $MODPROBED_DB_BIN init 
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to get '$MODPROBED_DB_BIN' info: Error $retsts"
  exit 1
fi

echo "Stepping into Linux kernel source directory ..."
cd "linux-${LINUX_VERSION}" || exit 1
echo "cleaning off all maintainers' cruft plus 'make clean' ..."
make mrproper    # blows away .config

echo "Take current kernel's .config and use that ..."
zcat /proc/config.gz > .config

echo "Take dynamic module listings and incorporate into kernel's .config ..."
make LSMOD="$HOME/.config/modprobed.db" localmodconfig

# Update LOCALVERSION
sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"-${KERNEL_VERSION}\"/" .config
vim .config

echo "Perform kernel 'make' (long time)..."
make -j4
echo "Perform kernel 'make modules' (medium time)..."
make modules

echo "Perform kernel 'make bzImage' (makes vmlinux) ..."
make bzImage
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "make bzImage failed: error $retsts"
  exit $retsts
fi

echo "Perform kernel 'make modules_install' (quick time)..."
sudo make modules_install
if [ "$retsts" -ne 0 ]; then
  echo "make bzImage failed: error $retsts"
  exit $retsts
fi


MKINITCPIO_CONF_DIRSPEC="/etc"
MKINITCPIO_CONF_FILENAME="mkinitcpio-${KERNEL_VERSION}.conf"
MKINITCPIO_CONF_FILESPEC="${MKINITCPIO_CONF_DIRSPEC}/$MKINITCPIO_CONF_FILENAME"

MKINITCPIO_D_DIRSPEC="/etc/mkinitcpio.d"
MKINITCPIO_D_FILENAME="${MKINIT_VERSION}.preset"
MKINITCPIO_D_FILESPEC="${MKINITCPIO_D_DIRSPEC}/$MKINITCPIO_D_FILENAME"

VMLINUZ_DIRSPEC="/boot"
VMLINUZ_FILENAME="vmlinuz-${MKINIT_VERSION}"
VMLINUZ_FILESPEC="${VMLINUZ_DIRSPEC}/$VMLINUZ_FILENAME"

INITRAMFS_DIRSPEC="/boot"
INITRAMFS_FILENAME="initramfs-${MKINIT_VERSION}.img"
INITRAMFS_FILESPEC="${INITRAMFS_DIRSPEC}/$INITRAMFS_FILENAME"

INITRAMFS_FB_DIRSPEC="/boot"
INITRAMFS_FB_FILENAME="initramfs-${MKINIT_VERSION}-fallback.img"
INITRAMFS_FB_FILESPEC="${INITRAMFS_FB_DIRSPEC}/$INITRAMFS_FB_FILENAME"

SYSTEM_MAP_DIRSPEC="/boot"
SYSTEM_MAP_FILENAME="System.map-${MKINIT_VERSION}"
SYSTEM_MAP_FILESPEC="${SYSTEM_MAP_DIRSPEC}/$SYSTEM_MAP_FILENAME"

if [ ! "$MKINITCPIO_D_FILESPEC" ]; then
  $SUDO_BIN cat << PRESET_EOF | tee "$MKINITCPIO_D_FILESPEC"
#
# File: $MKINITCPIO_D_FILENAME
# Path: $MKINITCPIO_D_DIRSPEC
# mkinitcpio preset file for the '$MKINIT_VERSION' package

# ALL_config="/etc/mkinitcpio.conf"
# ALL_kver="/boot/vmlinuz"

PRESETS=('default' 'fallback')

default_config="$MKINITCPIO_CONF_FILESPEC"
default_image="$INITRAMFS_FILESPEC"
#default_options=""

fallback_config="$MKINITCPIO_CONF_FILESPEC"
fallback_image="$INITRAMFS_FB_FILESPEC"
fallback_options="-S autodetect"

PRESET_EOF
fi

$SUDO_BIN cp -v arch/x86/boot/bzImage "$VMLINUZ_FILESPEC"
if [ ! -f System.map ]; then
  $SUDO_BIN cp /proc/kallsyms "$SYSTEM_MAP_FILESPEC"
fi
$SUDO_BIN cp System.map "$SYSTEM_MAP_FILESPEC"

if [ ! -h /boot/System.map ]; then
  $SUDO_BIN ln -sf "$SYSTEM_MAP_FILESPEC" /boot/System.map
fi

$SUDO_BIN mkinitcpio -p ${MKINIT_VERSION}


$SUDO_BIN grub-mkconfig -o /boot/grub/grub.cfg
