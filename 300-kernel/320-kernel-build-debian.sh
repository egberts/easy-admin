#!/bin/bash
# File: 320-kernel-build.sh
# Title: Build customized Linux kernel
#
# To get original non-Debian Linux kernel
#
#    tar xvfJ /usr/src/linux-source*.tgz
#    # writes into ./linux-5.10
#

DEFAULT_KERNEL_LOCALVERSION="custom1"  # the part that goes into `uname -r`

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

echo "Listing available kernel source directories:"
potential_kernels_dirlist="$(find . -maxdepth 1 -type d -name "linux-*" -print | sed -e 's/\.\///' | xargs)"
echo "    $potential_kernels_dirlist"
if [ -z "$potential_kernels_dirlist" ]; then
  echo "No directory found starting with 'linux-'; aborted."
  exit 9
fi

# Loop through candidate Linux directories for any Kconfig file
kernels_dirlist=
for this_dir in $potential_kernels_dirlist; do
  found_Kconfig="$(find $this_dir -maxdepth 1 -type f -name Kconfig -print)"
  if [ -n "$found_Kconfig" ]; then
    if [ -z "$kernels_dirlist" ]; then
      kernels_dirlist="$this_dir"
    else
      kernels_dirlist="$kernels_dirlist $this_dir"
    fi
  fi
done

# prompt user for kernel selection
PS3="Enter in kernel version: "
select kern_version in $kernels_dirlist; do
  if [ -n "$kern_version" ]; then
    break
  fi
done
if [ ! -d "$kern_version" ]; then
  echo "$kern_version is not a valid directory; aborted."
  exit 3
fi

cd $kern_version || exit 9
LINUX_VERSION="${kern_version:6}"


######################################################
# recreating 5.10.46 as-is, no-change, unsigned.
######################################################

# Check if this is signed or not
PEM_FILE=$(awk '{ FS="="; if ( $1 == "CONFIG_SYSTEM_TRUSTED_KEYS" ) print $2; }' .config)
echo "PEM FILE: $PEM_FILE"

if [ -z "$PEM_FILE" ]; then
  echo "WARNING: ***** Missing PEM files from Debian Team ****"
  echo "You can only build unsigned kernels+modules"
fi

echo "Enter in your custom version (without the minus symbol)"
read -rp "This custom kernel local version: " -ei${DEFAULT_KERNEL_LOCALVERSION}
KERNEL_LOCALVERSION="$REPLY"

echo "Create a Debian package or in-kernel bzImage+modules build?"
read -rp "Debian (P)ackage or (K)ernel build? (K/p): " -eiK
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
BUILD_METHOD="$REPLY"


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
      echo "File $versioned_config not found; falling back to generic .config."
      if [ ! -f ".config" ]; then
        echo "File .config not found; aborted."
        exit 9
      fi
    else
      echo "Copying $versioned_config into ./.config ..."
      cp "$versioned_config" .config
      retsts=$?
      if [ $retsts -ne 0 ];then
        echo "Error copying $versioned_config into .config; aborted."
        exit 11
      fi
      # eliminate any unneeded '=n' option and its corresponding CONFIG_(s).
    fi
    make oldconfig
    ;;
  CLONE_OS)
    EXPECT_MODULES=1
    # If .config is missing, create using 'default' via oldconfig
    if [ ! -r .config ]; then
      echo "Missing .config file; default to 'oldconfig'"
      make oldconfig
      retsts=$?
      if [ $retsts -ne 0 ]; then
        echo "Error $retsts recreating .config file; aborted."
        exit $retsts
      fi
    fi
    dotconfig_get_current_kernel
    modules_list_active_mods

    ;;

  # KVM_INITRAMFS settings
  KVM_INITRAMFS)
    EXPECT_MODULES=1
    # If .config is missing, create using 'default' via oldconfig
    if [ ! -r .config ]; then
      echo "Missing .config file; default to 'oldconfig'"
      make oldconfig
      retsts=$?
      if [ $retsts -ne 0 ]; then
        echo "Error $retsts recreating .config file; aborted."
        exit $retsts
      fi
    fi
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
    # If .config is missing, create using 'default' via oldconfig
    if [ ! -r .config ]; then
      echo "Missing .config file; default to 'oldconfig'"
      make oldconfig
      retsts=$?
      if [ $retsts -ne 0 ]; then
        echo "Error $retsts recreating .config file; aborted."
        exit $retsts
      fi
    fi
    dotconfig_get_current_kernel
    modules_list_active_mods

    ;;

  # KVM_INITRAMFS settings
  KVM_INITRAMFS)
    EXPECT_MODULES=1

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
    echo "INFO: modules are being used in this kernel variant."
    # exit 9
  fi

if [ "$BUILD_METHOD" == 'k' ]; then

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


elif [ "$BUILD_METHOD" == 'p' ]; then

  make -j${num_cpus} \
      DPKG_FLAGS="-sA" \
      KDEB_PKGVERSION=$(make kernelversion)-1 \
      deb-pkg
#     LOCALVERSION=-${KERNEL_LOCALVERSION} \  # useful for minor-minor tweaks
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "make deb-pkg failed: Error $retsts; aborted."
    exit $retsts
  fi


  # incorporate the change(s)
  #### dch -im
  # or
  #### dpkg-source -b --commit --skip-debianization

  # use -d to ignore later kernel-wedge
  ###dpkg-buildpackage -i -b --no-sign
  dpkg-buildpackage --build=source,binary -d -i -j${num_cpus} --no-sign
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "make deb-buildpackage --no-sign-key failed: Error $retsts; aborted."
    exit $retsts
  fi

  dpkg-buildpackage --build=source,binary -d -i -j${num_cpus} --sign-key="9C5F1A4625032DD1F2F98A39356E41FC96FD5864"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "make deb-buildpackage --sign-key failed: Error $retsts; aborted."
    exit $retsts
  fi
  echo "You can now install kernel image:"
  echo "sudo dpkg -i linux-images-5.10.46_5.10.46*.deb"
else
  echo "Option is not 'p' or 'k'; aborted."
  exit 1
fi

echo
echo "Done."
