#!/bin/bash
# File:
# Title: Build Linux kernel and install into boot
# Description:
#    Compile, link, install the Linux kernel using various customizations
#
#
# Envvars:
#   LINUX_VERSION: The Linux kernel version (format is something like 5.15.12)
#              also the name of a subdirectory below to this script
#              containing this version of Linux kernel sources.
#              Subdirectory must start with 'linux-' as in 'linux-5.15.12'
#   KERNEL_LOCALVERSION:  your custom subversion to tack on to the Linux version
#   KERN_TYPE: defaults to KVM_INITRAMFS
#              choices are:
#                FULL - All Linux modules built
#                CLONE_OS - All modules loaded in this OS are being used here
#                KVM_INITRAMFS - Minimal KVM needed
#
# Source: https://wiki.archlinux.org/title/Kernel/Traditional_compilation

DEFAULT_KERNEL_LOCALVERSION="custom1"  # the part that goes into `uname -r`
LINUX_VERSION=5.15.12

KERN_TYPES='FULL CLONE_OS INITRAMFS KVM_INITRAMFS'
kern_type="${KERN_TYPE:-KVM_INITRAMFS}"

# Unchangable things below

sudo_bin=
if [ "root" != "$USER" ]; then
  # sudo_bin=echo  # testing
  sudo_bin=/usr/bin/sudo
fi

NUM_CPUS="$(grep -E '^processor\s*:' /proc/cpuinfo | tail -n1 | awk -F: '{print $2}')"
((NUM_CPUS++))
echo "NUM_CPUS: $NUM_CPUS"

PS3="Enter in kernel type: "
select kern_type in $KERN_TYPES; do
  if [ -n "$kern_type" ]; then
    break
  fi
done
if [ -z "$kern_type" ]; then
  echo "Not a valid value; aborted."
  exit 3
fi

LINUX_VERSION_1="$(echo "$LINUX_VERSION" | awk -F. '{print $1}')"
LINUX_VERSION_2="$(echo "$LINUX_VERSION" | awk -F. '{print $2}')"
mkinitcpio_prefix="linux${LINUX_VERSION_1}${LINUX_VERSION_2}"

# if [ 0 -eq 1  ]; then
# $sudo_bin pacman -Syu
# $sudo_bin pacman -S --needed git base-devel
# fi

echo "Listing available kernel source directories:"
KERNELS_LIST="$(find . -maxdepth 1 -type d -name "linux-*" -print | sed -e 's/\.\///' | xargs)"
echo "    $KERNELS_LIST"
if [ -z "$KERNELS_LIST" ]; then
  echo "No directory found starting with 'linux-'; aborted."
  exit 9
fi

# Select first one as a default
default_kernel_version="$(echo "$KERNELS_LIST" | awk '{print $1}')"
echo 
echo "Stepping into Linux kernel source directory ..."
PROMPT_DIRTRIM=2
read -rp "Enter desired linux-* subdirectory name: " -ei"$default_kernel_version"

if [ -d "$REPLY" ]; then
  readlink_linux_version="$(readlink -f "$REPLY")"
  basename_linux_version="$(basename "$readlink_linux_version")"
  LINUX_VERSION="${basename_linux_version:6}"
else
  echo "No such directory: '$REPLY'; aborted."
  exit 9
fi
cd "linux-${LINUX_VERSION}" || exit 1

read -rp "Your custom kernel local version: " -ei"${DEFAULT_KERNEL_LOCALVERSION}"
KERNEL_LOCALVERSION="$REPLY"

echo "cleaning off all maintainers' cruft plus 'make clean' ..."
make mrproper    # blows away .config


function dotconfig_get_current_kernel()
{
  # Reset .config to current kernel's /proc/config.gz
  echo "Take current kernel's .config and use that ..."
  zcat /proc/config.gz > .config
}


function modules_list_active_mods()
{
  echo "Constructing modprobed-db from AUR ..."
  MODPROBED_DB_BIN="$(which modprobed-db)"
  if [ -z "$MODPROBED_DB_BIN" ]; then
    git clone https://aur.archlinux.org/modprobed-db.git
    pushd . || exit 9
    cd modprobed-db || exit 10
    makepkg
    $sudo_bin -U modprobed-db.tar.xz
    popd || exit 11
    MODPROBED_DB_BIN="$(which modprobed-db)"
  fi
  # Why are we using modprobed-db?  Because we can do things
  # between boots which auto-loaded modules of which this
  # modprobed-db can then extract from /proc/modules for
  # this kernel build to use.
  #
  # Read /proc/modules and update $HOME/.config/modprobed-db
  # Alternatively, we could do:
  #    lsmod > /tmp/my-lsmod.txt
  #    make LSMOD=/tmp/my-lsmod.txt localmodconfig
  $MODPROBED_DB_BIN store && $MODPROBED_DB_BIN init 
} 


function dotconfig_tweak_settings()
{
  CONFIGS_LIST="$1"
  THE_SETTING="$2"
  for this_config in $CONFIGS_LIST; do
    sed -i "s/^CONFIG_${this_config}=.*/CONFIG_${this_config}=${THE_SETTING}/" .config
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "CONFIG_${this_config}=${THE_SETTING}" >> .config
    fi
  done
}


USE_MODULES=0
case $kern_type in
  CLONE_OS)
    USE_MODULES=1
    dotconfig_get_current_kernel
    modules_list_active_mods

    ;;

  # KVM_INITRAMFS settings
  KVM_INITRAMFS)
    USE_MODULES=1

    dotconfig_get_current_kernel
    modules_list_active_mods

    # Remove lots of kernel config settings based on inactive kernel modules
    # using 'make localmodconfig'
    # and 'LSMOD='
    echo "Take dynamic module listings and incorporate into kernel's .config ..."
    make LSMOD="$HOME/.config/modprobed.db localmodconfig"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "Unable to get '$MODPROBED_DB_BIN' info: Error $retsts"
      exit 1
    fi

    YES_CONFIGS=""
    M_CONFIGS="DM_SNAPSHOT DM_MIRROR DM_CACHE DM_CACHE_SMQ DM_THIN_PROVISIONING USB_HID NETFILTER_NETLINK NF_TABLES"
    # Set some config settings to "YES"
    # Do this anyway regardless of USE_MODULES
    dotconfig_tweak_settings "$YES_CONFIGS" y
    dotconfig_tweak_settings "$M_CONFIGS" m

    # eliminate any 'n' and its corresponding CONFIG_(s).
    make oldconfig
    ;;
  FULL)
    make defaultconfig
    ;;
esac
# At this point, .config is ready


# Update LOCALVERSION
sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"-${KERNEL_LOCALVERSION}\"/" .config

# Review .config settings in $EDITOR
vim .config

# Test .config if modules were used and not requested
if [ "$USE_MODULES" -eq 0 ]; then
  MODULES_USED="$(grep -c "=m" .config)"
  if [ "$MODULES_USED" -ge 1 ]; then
    echo "WARNING: modules used in this kernel"
    # exit 9
  fi
fi

echo "Perform kernel 'make' (long time)..."
make -j"${NUM_CPUS}"

echo "Perform kernel 'make bzImage' (makes vmlinux) ..."
make -j"${NUM_CPUS}" bzImage
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "make bzImage failed: error $retsts"
  exit $retsts
fi

echo "Perform kernel 'make modules' (medium time)..."
make -j"${NUM_CPUS}" modules

if [ -n "$sudo_bin" ]; then
  echo "This shell session is under $USER user, not 'root'."
  echo "because series of sudo prompts are next on the way."
  echo "Finally, it builds.  Press ENTER to continue."
  read -rp _
fi

echo "Perform kernel 'make modules_install' (quick time)..."
#####$sudo_bin make -j"${NUM_CPUS}" LSMOD="$HOME/.config/modprobed.db" modules_install
$sudo_bin make -j"${NUM_CPUS}" modules_install
if [ "$retsts" -ne 0 ]; then
  echo "make bzImage failed: error $retsts"
  exit $retsts
fi

MKINITCPIO_CONF_DIRSPEC="/etc"
MKINITCPIO_CONF_FILENAME="mkinitcpio-${KERNEL_LOCALVERSION}.conf"
MKINITCPIO_CONF_FILESPEC="${MKINITCPIO_CONF_DIRSPEC}/$MKINITCPIO_CONF_FILENAME"

MKINITCPIO_D_DIRSPEC="/etc/mkinitcpio.d"
MKINITCPIO_D_FILENAME="${mkinitcpio_prefix}.preset"
MKINITCPIO_D_FILESPEC="${MKINITCPIO_D_DIRSPEC}/$MKINITCPIO_D_FILENAME"

VMLINUZ_DIRSPEC="/boot"
VMLINUZ_FILENAME="vmlinuz-${mkinitcpio_prefix}"
VMLINUZ_FILESPEC="${VMLINUZ_DIRSPEC}/$VMLINUZ_FILENAME"

INITRAMFS_DIRSPEC="/boot"
INITRAMFS_FILENAME="initramfs-${mkinitcpio_prefix}.img"
INITRAMFS_FILESPEC="${INITRAMFS_DIRSPEC}/$INITRAMFS_FILENAME"

INITRAMFS_FB_DIRSPEC="/boot"
INITRAMFS_FB_FILENAME="initramfs-${mkinitcpio_prefix}-fallback.img"
INITRAMFS_FB_FILESPEC="${INITRAMFS_FB_DIRSPEC}/$INITRAMFS_FB_FILENAME"

SYSTEM_MAP_DIRSPEC="/boot"
SYSTEM_MAP_FILENAME="System.map-${mkinitcpio_prefix}"
SYSTEM_MAP_FILESPEC="${SYSTEM_MAP_DIRSPEC}/$SYSTEM_MAP_FILENAME"

if [ ! "$MKINITCPIO_D_FILESPEC" ]; then
  $sudo_bin cat << PRESET_EOF | tee "$MKINITCPIO_D_FILESPEC"
#
# File: $MKINITCPIO_D_FILENAME
# Path: $MKINITCPIO_D_DIRSPEC
# mkinitcpio preset file for the '$mkinitcpio_prefix' package

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

$sudo_bin cp -v arch/x86/boot/bzImage "$VMLINUZ_FILESPEC"
if [ ! -f System.map ]; then
  $sudo_bin cp /proc/kallsyms "$SYSTEM_MAP_FILESPEC"
fi
$sudo_bin cp System.map "$SYSTEM_MAP_FILESPEC"

if [ ! -h /boot/System.map ]; then
  $sudo_bin ln -sf "$SYSTEM_MAP_FILESPEC" /boot/System.map
fi

$sudo_bin mkinitcpio -p "${mkinitcpio_prefix}"


$sudo_bin grub-mkconfig -o /boot/grub/grub.cfg
