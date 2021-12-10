#
# File: 022-fonts-ibm-plex.sh
#

pushd .
cd /tmp
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

echo "Done."

