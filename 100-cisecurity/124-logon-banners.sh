#!/bin/bash
# File: 124-logon-banners.sh
# Title: Minimize the various banners of logons
#

echo "Enforcing coherent login banners":
echo ""
CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/os-file-settings-banners.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -f "$FILE_SETTINGS_FILESPEC"
fi

source installer.sh

issue_filename="issue"
issue_filepath="/etc"
issue_filespec="${issue_filepath}/${issue_filename}"

echo "Creating ${BUILDROOT}${CHROOT_DIR}$issue_filespec..."
flex_mkdir "$(dirname "$issue_filespec")"
flex_touch "$issue_filespec"
flex_chown root:root "$issue_filespec"
flex_chmod 0644      "$issue_filespec"
cat << ISSUE_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$issue_filespec" >/dev/null
Authorized uses only. All activity may be monitored and reported.
ISSUE_EOF
echo ""

issue_net_filename="issue.net"
issue_net_filespec="${issue_filepath}/${issue_net_filename}"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$issue_net_filespec..."
flex_touch "$issue_net_filespec"
flex_chown root:root "$issue_net_filespec"
flex_chmod 0644      "$issue_net_filespec"
cat << ISSUE_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$issue_net_filespec">/dev/null
Authorized uses only. All activity may be monitored and reported.
ISSUE_EOF
echo ""

# Remove /etc/motd.d
MOTD_DIRNAME="motd.d"
MOTD_DIRPATH="/etc"
MOTD_DIRSPEC="${MOTD_DIRPATH}/${MOTD_DIRNAME}"
if [ -d "$MOTD_DIRSPEC" ]; then
  echo "You should also be removing $MOTD_FILESPEC..."
  echo ""
fi

echo "Done."
