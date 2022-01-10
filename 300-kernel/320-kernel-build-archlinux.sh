#!/bin/bash
#
# Source: https://wiki.archlinux.org/title/Kernel/Traditional_compilation

if [ 0 -eq 1  ]; then
sudo pacman -Syu
sudo pacman -S --needed git base-devel
fi

echo "Constructing modprobed-db from AUR ..."
MODPROBED_DB_BIN="$(which modprobed-db)"
if [ -z "$MODPROBED_DB_BN" ]; then
  git clone https://aur.archlinux.org/modprobed-db.git
  pushd .
  cd modprobed-db
  makepkg
  pacman -U modprobed-db.tar.xz
  popd
  MODPROBED_DB_BIN="$(which modprobed-db)"
fi

$MODPROBED_DB_BIN store && $MODPROBED_DB_BIN init 
if [ $? -ne 0 ]; then
  echo "Unable to get '$MODPROBED_DB_BIN' info"
  exit 1
fi

echo "Stepping into Linux kernel source directory ..."
cd linux-5.15.12
echo "cleaning off all maintainers' cruft plus 'make clean' ..."
make mrproper    # blows away .config

echo "Take current kernel's .config and use that ..."
zcat /proc/config.gz > .config
echo "Take dynamic module listings and incorporate into kernel's .config ..."
make LSMOD=$HOME/.config/modprobed.db localmodconfig

echo "Update the LOCALVERSION; press ENTER to continue."
read X
vim ~/.config

echo "Perform kernel 'make' (long time)..."
make -j4
echo "Perform kernel 'make modules' (medium time)..."
make modules
echo "Perform kernel 'make modules_install' (quick time)..."
sudo make modules_install

echo "Perform kernel 'make bzImage' (makes vmlinux) ..."
make bzImage

if [ ! -r /etc/mkinitcpio.d/linux515.preset ]; then
  sudo cp /etc/mkinitcpio.d/linux.preset /etc/mkinitcpio.d/linux515.preset
  sudo vi /etc/mkinitcpio.d/linux515.preset
fi
sudo mkinitcpio -p linux515

sudo cp -v arch/x86/boot/bzImage /boot/vmlinuz-linux515
sudo cp System.map /boot/System.map-linux515
sudo ln -sf /boot/System.map-linux515 /boot/System.map

sudo grub-mkconfig -o /boot/grub/grub.cfg
