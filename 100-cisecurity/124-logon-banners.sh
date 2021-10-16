#!/bin/bash
# File: 124-logon-banners.sh
# Title: Minimize the various banners of logons
#

BUILDROOT=${BUILDROOT:-/tmp}

ISSUE_NET_FILENAME="issue.net"
ISSUE_FILENAME="issue"
ISSUE_FILEPATH="/etc"
ISSUE_FILESPEC="${BUILDROOT}${ISSUE_FILEPATH}/${ISSUE_FILENAME}"
ISSUE_NET_FILESPEC="${BUILDROOT}${ISSUE_FILEPATH}/${ISSUE_NET_FILENAME}"
echo "Creating $ISSUE_FILESPEC..."
touch "$ISSUE_FILESPEC"
chown root:root "$ISSUE_FILESPEC"
chmod 0644      "$ISSUE_FILESPEC"
cat << ISSUE_EOF | sudo tee "$ISSUE_FILESPEC"
Authorized uses only. All activity may be monitored and reported.
ISSUE_EOF

echo "Creating $ISSUE_NET_FILESPEC..."
touch "$ISSUE_NET_FILESPEC"
chown root:root "$ISSUE_NET_FILESPEC"
chmod 0644      "$ISSUE_NET_FILESPEC"
cat << ISSUE_EOF | sudo tee "$ISSUE_NET_FILESPEC"
Authorized uses only. All activity may be monitored and reported.
ISSUE_EOF

if [ "$BUILDROOT" == '/' ]; then
  MOTD_FILENAME="motd"
  MOTD_FILEPATH="/etc"
  MOTD_FILESPEC="${BUILDROOT}${MOTD_FILEPATH}/${MOTD_FILENAME}"
  echo "Removing $MOTD_FILESPEC..."
  sudo rm -i "$MOTD_FILESPEC"
else
  echo "Also run 'rm $MOTD_FILEPATH/$MOTD_FILENAME' command."
fi
