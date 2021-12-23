#!/bin/bash
# File: 510-dns-bind9-reset-config.sh
# Title:  Restart Bind9 configuration from scratch

BUILDROOT="${BUILDROOT:-build/}"
source dns-isc-common.sh

echo "Clearing out prior settings in $BUILDROOT"

# Defensive mechanism from unexpected disk wipe
if [ -n "$BUILDROOT" ]; then
  if [ "${BUILDROOT:0:1}" == "/" ]; then
    echo "BUILDROOT should be empty or a relative directory; not absolute path"
    echo "Aborted."
    exit 9
  fi
fi
if [ -d "$BUILDROOT" ]; then
  rm -rf "$BUILDROOT"
fi

# Create skeleton subdirectory
flex_mkdir "$sysconfdir"
flex_chown root:bind "$sysconfdir"
flex_chmod 0750      "$sysconfdir"

echo "Creating a new $BUILDBIND directory..."
mkdir "$BUILDBIND"  # no flex_mkdir, this is an intermediate-build tmp directory

flex_mkdir "$SYSTEMD_SYSTEM_DIRSPEC"
flex_chown root:bind "$SYSTEMD_SYSTEM_DIRSPEC"
flex_chmod 0750      "$SYSTEMD_SYSTEM_DIRSPEC"

flex_mkdir "$ETC_LOGROTATED_DIRSPEC"
flex_chown root:root "$ETC_LOGROTATED_DIRSPEC"
flex_chmod 0750      "$ETC_LOGROTATED_DIRSPEC"

flex_mkdir "$ETC_APPARMORD_DIRSPEC"
flex_chown root:root "$ETC_APPARMORD_DIRSPEC"
flex_chmod 0750      "$ETC_APPARMORD_DIRSPEC"

flex_mkdir "$ETC_APPARMORD_LOCAL_DIRSPEC"
flex_chown root:root "$ETC_APPARMORD_LOCAL_DIRSPEC"
flex_chmod 0750      "$ETC_APPARMORD_LOCAL_DIRSPEC"

echo ""
echo "Done."
exit 0

