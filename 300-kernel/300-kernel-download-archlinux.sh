#!/bin/bash
# File: 300-kernel-download-archlinux.sh
# Title: Download Linux kernel
#
# To get original non-Debian Linux kernel
#
# References:
# - https://wiki.archlinux.org/title/Kernel/Traditional_compilation
#
#
download_source=${download_source:-0}
download_filetype="xz"
download_pgp="sign"

TARGET_VERSION_H="5"  # LTR
TARGET_VERSION_M="16"  # LTR
TARGET_VERSION_L="20"
KERNEL_SITE="https://cdn.kernel.org"
KERNEL_DIRPATH="/pub/linux/kernel/v5.x"
KERNEL_URL="${KERNEL_SITE}/$KERNEL_DIRPATH"

construct_tarball_filename()
{
  # ie., linux-5.16.20
  KERNEL_DIRNAME="linux-${TARGET_VERSION_H}.${this_ver}.${1}"

  # Use KERNEL_DIRNAME as KERNEL_FILE_PRESUFFIX
  # ie., linux-5.16.20.tar
  KERNEL_FILESUFFIX="${KERNEL_DIRNAME}.tar"

  # ie., linux-5.16.20.tar.xz
  KERNEL_FILENAME="${KERNEL_FILESUFFIX}.${download_filetype}"

  # ie., linux-5.16.20.tar.sign
  KERNEL_FILESIGN="${KERNEL_FILESUFFIX}.${download_pgp}"
}

echo "Building Linux kernel for ArchLinux"
echo
mkdir -p kernelbuild
cd kernelbuild

# pacman -S --needed base-devel
# pacman -S pahole  # used by Linux kernel 'make bzImage'

# pacman -S linux  # this installs the binary, we want kernel source 

# Download IF and ONLY IF requested
if [ $download_source -ge 1 ]; then

  # Locate highest TARGET_VERSION
  this_ver="$TARGET_VERSION_M"
  this_loop=1
  latest_ver=""
  while [ true ]; do
    # construct filename of tarball
    construct_tarball_filename $this_loop
    this_url="${KERNEL_URL}/$KERNEL_FILENAME"
  
    # Test file at given URL (but not download) via HTTP-HEAD (not HTTP-GET)
    wget --spider -q $this_url
    retsts=$?
    if [[ $retsts -ne 0 ]]; then
      # revert back to working lower version
      ((this_loop--))
      break
    fi
    latest_ver="$this_url"
    latest_filename="$KERNEL_FILENAME"
    ((this_loop++))
  done
  # Reconstruct earlier version of filename
  construct_tarball_filename $this_loop
  if [ -z "$latest_ver" ]; then
    echo "Kernel source file not found."
    echo "Aborted."
    exit 9
  fi

  # Check if our local copy already exist
  if [ ! -f "$latest_filename" ]; then
    wget -q "$latest_ver"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "Unable to download $latest_ver"
      echo "Errno $retsts; aborted."
      exit $retsts
    fi
  fi
else
  # check local copy
  this_ver=$TARGET_VERSION_M
  construct_tarball_filename $TARGET_VERSION_L
  if [ ! -f "$KERNEL_FILENAME" ]; then
    echo "Must set 'download_source=1' and re-run this script"
    exit 11
  fi
  latest_ver="$KERNEL_FILENAME"
fi
echo "File $latest_ver on hand."

# Get PGP-signed file
this_sign="${KERNEL_URL}/${KERNEL_FILESIGN}"
echo "wget -N -q \"$this_sign\""
wget -N -q "$this_sign"
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Error retrieving signed PGP file $this_sign; errno $errno; aborted."
  exit $retsts
fi

# Check integrity of ownload
gpg --list-packets ${KERNEL_FILESIGN}
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Integrity of Linux kernel source file FAILED; aborted."
  exit $retsts
fi

# Delete tarball
rm -f ${KERNEL_FILESUFFIX}

# Extract tarball
unxz -k -f ${KERNEL_FILENAME}
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Unable to XZ-uncompress Linux kernel source $KERNEL_FILENAME"
  echo "errno $retsts; aborted."
  exit $retsts
fi

gpg --verify "$KERNEL_FILESIGN" ${KERNEL_FILESUFFIX}
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Unable to verify PGP for Linux kernel source $KERNEL_FILESUFFIX"
  echo "errno $retsts; aborted."
  echo "perhaps execute 'gpg -recv-key 647F28654894E3BD457199BE38DBBDC86092693E'"
  exit $retsts
fi

# If source directory already exist, do NOT OVERWRITE them, ask firstly.
if [ -d "$KERNEL_DIRNAME" ]; then
  echo "WARNING: Cannot uncompress tarball into $KERNEL_DIRNAME"
  echo "WARNING: Subdirectory $KERNEL_DIRNAME already exist"
  read -rp "Do you wish to blow away any and all changes? (N/y): " -ein
  REPLY="${REPLY:0:1}"
  REPLY="${REPLY:,,}"
  if [ "$REPLY" != 'y' ]; then
    echo "Aborted."
    exit 2
  fi
  rm -f "$KERNEL_DIRNAME"
fi

tar xvf "$KERNEL_FILESUFFIX"
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Unable to uncompress tarball; errno $retsts; aborted."
  exit $retsts
fi

chown -R ${USER}:$USER "$KERNEL_DIRNAME"
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Unable to change file ownership to ${USER}:${USER}; aborted."
  exit $retsts
fi


echo "cd $KERNEL_DIRNAME"
cd "$KERNEL_DIRNAME"
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Unable to go into $KERNEL_DIRNAME directory; aborted."
  exit $retsts
fi

echo "make mrproper"
make mrproper
retsts=$?
if [ $retsts -ge 1 ]; then
  echo "Unable to execute 'make mrproper'; aborted."
  exit $retsts
fi

echo
echo "Done."
