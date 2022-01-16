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
#                USE_CONFIG_VERSION -
#                    uses ./config-<version>-<localversion> file (as-is)
#                FULL - All Linux modules built
#                CLONE_OS - All modules loaded in this OS are being used here
#                KVM_INITRAMFS - Minimal KVM needed
#
# Source: https://wiki.archlinux.org/title/Kernel/Traditional_compilation

DEFAULT_KERNEL_LOCALVERSION="custom1"  # the part that goes into `uname -r`
LINUX_VERSION=5.15.12

kern_type_list='USE_CONFIG_VERSION FULL CLONE_OS INITRAMFS KVM_INITRAMFS'
kern_type="${KERN_TYPE:-KVM_INITRAMFS}"

# Unchangable things below

# Do we want to leverage KCONFIG_CONFIG=.config-<version> in 'make bzImage'?

sudo_bin=
if [ "root" != "$USER" ]; then
  # sudo_bin=echo  # testing
  sudo_bin=/usr/bin/sudo
fi

num_cpus="$(grep -E '^processor\s*:' /proc/cpuinfo | tail -n1 | awk -F: '{print $2}')"
((num_cpus++))
echo "num_cpus: $num_cpus"

PS3="Enter in kernel type: "
select kern_type in $kern_type_list; do
  if [ -n "$kern_type" ]; then
    break
  fi
done
if [ -z "$kern_type" ]; then
  echo "Not a valid value; aborted."
  exit 3
fi

linux_version_1="$(echo "$LINUX_VERSION" | awk -F. '{print $1}')"
linux_version_2="$(echo "$LINUX_VERSION" | awk -F. '{print $2}')"
mkinitcpio_prefix="linux${linux_version_1}${linux_version_2}"

# if [ 0 -eq 1  ]; then
# $sudo_bin pacman -Syu
# $sudo_bin pacman -S --needed git base-devel
# fi

echo "Listing available kernel source directories:"
kernels_dirlist="$(find . -maxdepth 1 -type d -name "linux-*" -print | sed -e 's/\.\///' | xargs)"
echo "    $kernels_dirlist"
if [ -z "$kernels_dirlist" ]; then
  echo "No directory found starting with 'linux-'; aborted."
  exit 9
fi

# Select first one as a default
default_kernel_version="$(echo "$kernels_dirlist" | awk '{print $1}')"
echo
echo "Stepping into Linux kernel source directory ..."
# bash internal PROMPT_DIRTRIM for read/select function
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
  modprobed_db_bin="$(which modprobed-db)"
  if [ -z "$modprobed_db_bin" ]; then
    git clone https://aur.archlinux.org/modprobed-db.git
    pushd . || exit 9
    cd modprobed-db || exit 10
    makepkg
    $sudo_bin -U modprobed-db.tar.xz
    popd || exit 11
    modprobed_db_bin="$(which modprobed-db)"
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
  $modprobed_db_bin store && $modprobed_db_bin init
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


EXPECT_MODULES=0
case $kern_type in
  USE_CONFIG_VERSION)
    EXPECT_MODULES=1
    versioned_config="./.config-${LINUX_VERSION}-${KERNEL_LOCALVERSION}"
    if [ ! -f "$versioned_config" ]; then
      echo "File $versioned_config not found; aborted."
      exit 9
    fi
    echo "Copying $versioned_config into ./.config ..."
    cp "$versioned_config" .config
    retsts=$?
    if [ $retsts -ne 0 ];then
      echo "Error copying $versioned_config into .config; aborted."
      exit 11
    fi
    # eliminate any unneeded '=n' option and its corresponding CONFIG_(s).
    make oldconfig
    ;;
  CLONE_OS)
    EXPECT_MODULES=1
    dotconfig_get_current_kernel
    modules_list_active_mods

    ;;

  # KVM_INITRAMFS settings
  KVM_INITRAMFS)
    EXPECT_MODULES=1

    dotconfig_get_current_kernel
    modules_list_active_mods

    # Remove lots of kernel config settings based on inactive kernel modules
    # using 'make localmodconfig'
    # and 'LSMOD='
    echo "Take dynamic module listings and incorporate into kernel's .config ..."
    make LSMOD="$HOME/.config/modprobed.db localmodconfig"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "Unable to get '$modprobed_db_bin' info: Error $retsts"
      exit 1
    fi

    YES_CONFIGS=""
    M_CONFIGS="DM_SNAPSHOT DM_MIRROR DM_CACHE DM_CACHE_SMQ DM_THIN_PROVISIONING USB_HID NETFILTER_NETLINK NF_TABLES"
    # Set some config settings to "YES"
    # Do this anyway regardless of EXPECT_MODULES
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
# 'make -j4' will execute oldconfig to flesh out any errant settings

# Test .config if modules were used and not requested
# if [ "$EXPECT_MODULES" -eq 0 ]; then
  MODULES_USED="$(grep -c "=m" .config)"
  if [ "$MODULES_USED" -ge 1 ]; then
    find . -name "*.ko.*" -print
    echo "WARNING: modules used in this kernel"
    # exit 9
  fi
# fi
mkdir /lib/modules/${LINUX_VERSION}-${KERNEL_LOCALVERSION}

echo "Perform kernel 'make -j${num_cpus}' (long time) ..."
make -j"${num_cpus}"

echo "Perform kernel 'make -j${num_cpus} bzImage' (makes vmlinux) ..."
make -j"${num_cpus}" bzImage
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "make bzImage failed: error $retsts"
  exit $retsts
fi

if [ "$MODULES_USED" -ge 1 ]; then
  echo "Perform kernel 'make -j${num_cpus} modules' (medium time) ..."
  make -j"${num_cpus}" modules
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "make modules failed: error $retsts"
    exit $retsts
  fi
fi

if [ -n "$sudo_bin" ]; then
  echo "This shell session is under '$USER' user session, not 'root'."
  echo "because series of sudo prompts are next on the way."
  echo "Finally, it builds.  Press ENTER to continue."
  read -rp _
fi

if [ "$MODULES_USED" -ge 1 ]; then
  echo "Perform kernel 'make -j${num_cpus} modules_install' (quick time) ..."
  #####$sudo_bin make -j"${num_cpus}" LSMOD="$HOME/.config/modprobed.db" modules_install
  $sudo_bin make -j"${num_cpus}" modules_install
  if [ "$retsts" -ne 0 ]; then
    echo "make bzImage failed: error $retsts"
    exit $retsts
  fi
fi

mkinitcpio_conf_dirspec="/etc"
mkinitcpio_conf_filename="mkinitcpio-${KERNEL_LOCALVERSION}.conf"
mkinitcpio_conf_filespec="${mkinitcpio_conf_dirspec}/$mkinitcpio_conf_filename"

mkinitcpio_d_dirspec="/etc/mkinitcpio.d"
mkinitcpio_d_filename="${mkinitcpio_prefix}.preset"
mkinitcpio_d_filespec="${mkinitcpio_d_dirspec}/$mkinitcpio_d_filename"

vmlinuz_dirspec="/boot"
vmlinuz_filename="vmlinuz-${mkinitcpio_prefix}"
vmlinuz_filespec="${vmlinuz_dirspec}/$vmlinuz_filename"

initramfs_dirspec="/boot"
initramfs_filename="initramfs-${mkinitcpio_prefix}.img"
initramfs_filespec="${initramfs_dirspec}/$initramfs_filename"

initramfs_fb_dirspec="/boot"
initramfs_fb_filename="initramfs-${mkinitcpio_prefix}-fallback.img"
initramfs_fb_filespec="${initramfs_fb_dirspec}/$initramfs_fb_filename"

system_map_dirspec="/boot"
system_map_filename="System.map-${mkinitcpio_prefix}"
system_map_filespec="${system_map_dirspec}/$system_map_filename"

if [ "$MODULES_USED" -ge 1 ]; then
  if [ ! "$mkinitcpio_d_filespec" ]; then
    $sudo_bin cat << PRESET_EOF | tee "$mkinitcpio_d_filespec"
#
# File: $mkinitcpio_d_filename
# Path: $mkinitcpio_d_dirspec
# mkinitcpio preset file for the '$mkinitcpio_prefix' package

# ALL_config="/etc/mkinitcpio.conf"
# ALL_kver="/boot/vmlinuz"

presets_A=('default' 'fallback')

default_config="$mkinitcpio_conf_filespec"
default_image="$initramfs_filespec"
#default_options=""

fallback_config="$mkinitcpio_conf_filespec"
fallback_image="$initramfs_fb_filespec"
fallback_options="-S autodetect"

PRESET_EOF
  fi
fi

$sudo_bin cp -v arch/x86/boot/bzImage "$vmlinuz_filespec"
if [ ! -f System.map ]; then
  $sudo_bin cp /proc/kallsyms "$system_map_filespec"
fi
$sudo_bin cp System.map "$system_map_filespec"

if [ ! -h /boot/System.map ]; then
  $sudo_bin ln -sf "$system_map_filespec" /boot/System.map
fi

if [ "$MODULES_USED" -ge 1 ]; then
  $sudo_bin mkinitcpio -p "${mkinitcpio_prefix}"
fi


$sudo_bin grub-mkconfig -o /boot/grub/grub.cfg

echo "Linux kernel build completed."
echo "  Version:         $LINUX_VERSION"
echo "  Local version:   $KERNEL_LOCALVERSION"
echo "  bzImage/vmlinuz: $vmlinuz_filespec"
echo "  System.map:      $system_map_filespec"
echo "  initramfs:            $initramfs_filespec"
echo "  initramfs (fallback): $initramfs_fb_filespec"
echo "  config:               $versioned_config"
echo "  kernel type:     $kern_type"
if [ "$MODULES_USED" -ge 1 ]; then
echo "  modules used:    TRUE"
else
echo "  modules used:    false"
fi
echo
echo "Done."
