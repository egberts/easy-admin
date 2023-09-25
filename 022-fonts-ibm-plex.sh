#
# File: 022-fonts-ibm-plex.sh
#

pushd .
cd /var/tmp
mkdir fonts-ibm-plex

echo "Downloading 600MB IBM Plex fonts ..."
wget "https://github.com/IBM/type/archive/master.zip"
echo ""

echo "Unzipping IBM Plex fonts in /tmp/fonts-ibm-plex subdirectory ..."
unzip master.zip
echo ""

echo "Creating /usr/local/share/fonts/truetype/ibm-plex ..."
mkdir -p /usr/local/share/fonts/truetype/ibm-plex
echo "Copying TrueType fonts into /usr/local/share/fonts/truetype/ibm-plex ..."
find . -name "*.ttf" \
    -exec cp {} /usr/local/share/fonts/truetype/ibm-plex/ \; -print
echo "Copying OpenType fonts into /usr/local/share/fonts/truetype/ibm-plex ..."
find . -name "*.otf" \
    -exec cp {} /usr/local/share/fonts/truetype/ibm-plex/ \; -print
echo ""

echo "Cleaning up temporary files ..."
popd 
rm -rf /tmp/fonts-ibm-plex
rm -f /tmp/master.zip

echo "Creating /etc/X11/xorg.conf.d/80-fonts-local.conf ..."
cat << LOCAL_FONT_CACHE_EOF | sudo tee /etc/X11/xorg.conf.d/80-fonts-local.conf

# File: 80-fonts-local.conf
# Path: /etc/X11/xorg.conf.d
# Title: IBM Plex font files for X11

Section "files"
    FontPath "/usr/share/fonts/local"
    FontPath "/usr/local/share/fonts"
    FontPath "/usr/local/share/fonts/truetype"
    FontPath "/usr/local/share/fonts/truetype/ibm-plex"
EndSection
LOCAL_FONT_CACHE_EOF

echo "Creating /etc/fonts/local.conf ..."
cat << ETC_FONT_CONF_EOF | sudo tee -a /etc/fonts/local.conf
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

<dir>/usr/local/share/fonts/</dir>

</fontconfig>
ETC_FONT_CONF_EOF
echo

echo "Update font cache ..."
sudo fc-cache -f -v
sudo fc-cache
echo

echo "Done."

