#!/bin/bash
# File: 025-repo-debian-experimental.sh
# Title: How to install "SOME" experimental package while staying @ stable
# OS: Debian 11
# Description:
#

echo "Configuring APT to allow some experimental package while staying @ stable"
echo


apt_conf_filename="99default-release"
apt_conf_dirspec="/etc/apt/apt.conf.d"
apt_conf_filespec="${apt_conf_dirspec}/$apt_conf_filename"

echo "Creating ${apt_conf_filespec} ..."
cat << APT_CONF_EOF | tee "$apt_conf_filespec" > /dev/null
#
# File: ${apt_conf_filename}
# Path: ${apt_conf_dirspec}
# Title: How to install "SOME" experimental package while staying @ stable
# Description:
#
#   How to install just a certain 'experimental' package 
#   while staying at 'stable' release.
#
# Reference:
# * https://serverfault.com/questions/22414/how-can-i-run-debian-stable-but-install-some-packages-from-testing
#
APT::Default-Release "stable";
APT_CONF_EOF
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to write ${apt_conf_filespec} file: Error $retsts"
  echo "Aborted."
  exit $retsts
fi
chmod 0644 ${apt_conf_filespec}
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to chmod ${apt_conf_filespec} file: Error $retsts"
  echo "Aborted."
  exit $retsts
fi
chown root:root ${apt_conf_filespec}
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to chown ${apt_conf_filespec} file: Error $retsts"
  echo "Aborted."
  exit $retsts
fi
echo
apt update
echo
echo "now you can execute:"
echo
echo "   apt install -t=experimental <some-better-fixed-package-name>"
echo
echo "And then be able to do an system-wide update only at 'stable'"
echo
echo "   apt upgrade  # only stable package gets upgrade"
echo
echo "Done."
