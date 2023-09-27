#!/bin/bash
# File: 022-fonts-ibm-plex.sh
# Title:  Install IBM Plex font
# Description:
#   TBD
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - none
#  create - /etc/X11/xorg.conf.d/80-font-local.conf
#           /usr/local/share/fonts/truetype/ibm-plex
#           /usr/local/share/fonts/truetype/ibm-plex/*
#           /etc/fonts/local.conf
#  modify - none
#  delete - none
#
# Environment Variables:
#   None
#
# Prerequisites (package name):
#   cat (coreutils)
#   cp (coreutils)
#   fc-cache (fontconfig)
#   find (findutils)
#   mkdir (coreutils)
#   rm (coreutils)
#   tee (coreutils)
#   unzip (unzip)
#   wget (wget)
#
echo "Installing IBM Plex fonts ..."
echo
MY_TMPDIR="/var/tmp"
IBM_PLEX_DIRNAME="fonts-ibm-plex"
IBM_PLEX_DIRSPEC="$MY_TMPDIR/$IBM_PLEX_DIRNAME"
IBM_PLEX_FILENAME="master.zip"
IBM_PLEX_FILESPEC="$MY_TMPDIR/$IBM_PLEX_FILENAME"
IBM_PLEX_URL="https://github.com/IBM/type/archive/$IBM_PLEX_FILENAME"
FONT_DIRSPEC="/usr/local/share/fonts/truetype/ibm-plex"
X11_FONT_IBM_PLEX_FILENAME="80-fonts-local.conf"
X11_FONT_IBM_PLEX_PATHSPEC="/etc/X11/xorg.conf.d"
X11_FONT_IBM_PLEX_FILESPEC="${X11_FONT_IBM_PLEX_PATHSPEC}/${X11_FONT_IBM_PLEX_FILENAME}"

pushd .
cd /${MY_TMPDIR} || {
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "ERROR: unable to cd into $MY_TMPDIR: errno $RETSTS"
    exit $RETSTS
  fi
  }
echo "Creating /var/tmp/fonts-ibm-plex directory"
mkdir /${IBM_PLEX_DIRSPEC}
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: unable to create temp holding $IBM_PLEX_DIRSPEC: errno $RETSTS"
  exit $RETSTS
fi
cd /${IBM_PLEX_DIRSPEC} || {
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "ERROR: unable to cd into $IBM_PLEX_DIRSPEC: errno $RETSTS"
    exit $RETSTS
  fi
  }

echo "Downloading 600MB IBM Plex fonts ..."
echo "from $IBM_PLEX_URL"
wget "$IBM_PLEX_URL" -O ${IBM_PLEX_FILESPEC}
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: unable to retrieve IBM Plex zip file: errno $RETSTS"
  exit $RETSTS
fi

echo "Unzipping IBM Plex fonts in /tmp/fonts-ibm-plex subdirectory ..."
unzip  /${IBM_PLEX_FILESPEC}
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: unable to unzip $IBM_PLEX_FILESPEC: errno: $RETSTS"
  exit $RETSTS
fi
echo

echo "Creating $FONT_DIRSPEC directory ..."
sudo mkdir -p /${FONT_DIRSPEC} || {
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "ERROR: unable to mkdir ${FONT_DIRSPEC}: errno: $RETSTS"
    exit $RETSTS
  fi
}
echo "Copying TrueType fonts into /usr/local/share/fonts/truetype/ibm-plex ..."
find . -name "*.ttf" \
    -exec sudo cp {} /${FONT_DIRSPEC}/ \; -print
echo "Copying OpenType fonts into /usr/local/share/fonts/truetype/ibm-plex ..."
find . -name "*.otf" \
    -exec sudo cp {} ${FONT_DIRSPEC}/  \; -print
echo

echo "Cleaning up temporary files ..."
popd

rm -rf /${IBM_PLEX_DIRSPEC}
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: unable to remove $IBM_PLEX_DIRSPEC errno: $RETSTS"
  exit $RETSTS
fi

rm -f /${IBM_PLEX_FILESPEC}
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: unable to remove $IBM_PLEX_FILESPEC errno: $RETSTS"
  exit $RETSTS
fi

echo "Creating /etc/X11/xorg.conf.d/80-fonts-local.conf ..."
cat << LOCAL_FONT_CACHE_EOF | sudo tee /${X11_FONT_IBM_PLEX_FILESPEC} >/dev/null
#
# File: ${X11_FONT_IBM_PLEX_FILENAME}
# Path: ${X11_FONT_IBM_PLEX_PATHSPEC}
# Title: IBM Plex font files for X11

Section "files"
    FontPath "/usr/share/fonts/local"
    FontPath "/usr/local/share/fonts"
    FontPath "/usr/local/share/fonts/truetype"
    FontPath "/usr/local/share/fonts/truetype/ibm-plex"
EndSection
LOCAL_FONT_CACHE_EOF
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to create $X11_FONT_IBM_PLEX_FILESPEC file: errno $RETSTS"
  exit $RETSTS
fi

echo "Creating /etc/fonts/local.conf ..."
cat << ETC_FONT_CONF_EOF | sudo tee /etc/fonts/local.conf >/dev/null
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

<dir>/usr/local/share/fonts/</dir>

</fontconfig>

ETC_FONT_CONF_EOF
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to create /etc/fonts/local.conf file: errno $RETSTS"
  exit $RETSTS
fi
echo

echo "Update font cache ..."
sudo fc-cache -f -v
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to perform fc-cache -f -v: errno $RETSTS"
  exit $RETSTS
fi

sudo fc-cache
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "ERROR: Unable to perform fc-cache: errno $RETSTS"
  exit $RETSTS
fi
echo

echo "$0: done."
