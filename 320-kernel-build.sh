#!/bin/bash
# File: 320-kernel-build.sh
# Title: Build customized Linux kernel
#
# To get original non-Debian Linux kernel
#
#    tar xvfJ /usr/src/linux-source*.tgz
#    # writes into ./linux-5.10
#

cd linux-5.10.46-5.10.46 && exit 9
if [ ! -r .config ]; then
  echo "Missing .config file; aborted"
  exit 9
fi

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



# incorporate the change(s)
#### dch -im

# or
#### dpkg-source -b --commit --skip-debianization


make deb-pkg

# use -d to ignore later kernel-wedge
###dpkg-buildpackage -i -b --no-sign
dpkg-buildpackage --build=source,binary -d -i -j5 --no-sign
dpkg-buildpackage --build=source,binary -d -i -j5 --sign-key="9C5F1A4625032DD1F2F98A39356E41FC96FD5864"

echo "You can now install kernel image:"
echo "sudo dpkg -i linux-images-5.10.46_5.10.46*.deb"
