#!/bin/bash
# File: 310-kernel-config.sh
# Title: Configure the Linux kernel
#
# To get original non-Debian Linux kernel
#    apt download linux-source-5.10
#    dpkg -i linux-source-5.10*.deb
#
#    # stored  into /usr/src/linux-source-5.10*.tgz
#
#    tar xvfJ /usr/src/linux-source*.tgz
#    # writes into ./linux-5.10
#

# Always download Debian PKS PEM file, whether its signed or not
DEBIAN_UEFI_CERT=debian-uefi-certs.pem

##########################


# locally-clone the original linux-5.10.46
# use X.YY.ZZ-X.YY.ZZ versioning scheme
# so that `make deb-pkg` works???
cp -rpf linux-5.10.46 linux-5.10.46-5.10-46

cd linux-5.10.46-5.10-46 || exit $?

pushd .
if [ ! -d debian ]; then
  mkdir debian
fi
cd debian || exit $?
if [ ! -d certs ]; then
  mkdir certs
fi
cd certs || exit $?

# Should now be at linux-5.10.46-5.10.46/debian/certs subdirectory
if [ ! -r $DEBIAN_UEFI_CERT ]; then
  # Get raw PEM file
  wget https://salsa.debian.org/kernel-team/linux/-/raw/master/debian/certs/$DEBIAN_UEFI_CERT
  if [ ! -r $DEBIAN_UEFI_CERT ]; then
    echo "WARNING: *** You can only make unsigned images+modules ***"
  fi
fi
popd || exit $?


echo "Copying /boot/config into linux-5.10.46/.config"
echo "It is the only time we produce this .config"
echo "Afterward, you can change it in later scripts"
make oldconfig

