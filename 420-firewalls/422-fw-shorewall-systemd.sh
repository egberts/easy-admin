#!/bin/bash
# File: 422-fw-shorewall-systemd.sh
# Title: Configure Shorewall systemd to 'stop' and not 'clear'

echo "Configure systemd override for Shorewall firewall"
echo ""

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/firewall-shorewall.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -f "$FILE_SETTINGS_FILESPEC"
fi

source ./easy-admin-installer.sh

DEFAULT_ETC_CONF_DIRNAME="shorewall"

source ./distro-os.sh

shorewall_dirspec="$extended_sysconfdir"
if [ "${BUILDROOT:0:1}" != "/" ]; then
  mkdir -p "${BUILDROOT}/$shorewall_dirspec"
fi

systemd_dirspec="$sysconfdir/systemd"
flex_mkdir "$systemd_dirspec"
system_dirspec="$sysconfdir/systemd/system"
flex_mkdir "$system_dirspec"
shorewall_sys_unitname="shorewall.service"
shorewall_sys_override_dirname="${shorewall_sys_unitname}.d"
shorewall_sys_override_dirspec="${system_dirspec}/${shorewall_sys_override_dirname}"
flex_mkdir "$shorewall_sys_override_dirspec"
override_conf_filename="override.conf"
shorewall_override_filespec="${shorewall_sys_override_dirspec}/$override_conf_filename"
echo "Creating '$BUILDROOT$CHROOT_DIR$shorewall_override_filespec' file ..."
cat << OVERRIDE_EOF \
    | tee "${BUILDROOT}${CHROOT_DIR}$shorewall_override_filespec" >/dev/null
#
# File: $override_conf_filename
# Path: $shorewall_sys_override_dirspec
# Title: Systemd override for Shorewall firewall service

[Service]

# Reset ExecStop to nothing
ExecStop=

# Set ExecStop to 'stop' instead of 'clear'
ExecStop=/usr/sbin/shorewall \$OPTIONS stop

OVERRIDE_EOF
echo ""

echo "Done."
