#!/bin/bash
# File: 513-dns-bind9-systemd-start-later.sh
# Title: Start 'named' after DHCP client is UP
# Description:
#   Drop two new systemd unit files:
#      named/bind9.service
#      named@/bind9@.service
#   Also add an override of 'After=network-online.target'
#
# Prerequisites:
#
# Env varnames
#   - BUILDROOT - '/' for direct installation, otherwise create 'build' subdir
#   - INSTANCE - Bind9 instance name, if any
#

echo "Revising 'After' to 'network-online.target'"
echo

source ./maintainer-dns-isc.sh


# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" == '/' ]; then
  FILE_SETTING_PERFORM=true
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old bind/named settings"
  # Only the first copy is saved as the backup
  if [ ! -f "${NAMED_CONF_FILESPEC}.backup" ]; then
    BACKUP_FILENAME=".backup-$(date +'%Y%M%d%H%M')"
    echo "Moving /etc/${ETC_SUB_DIRNAME}/* to /etc/${ETC_SUB_DIRNAME}/${BACKUP_FILENAME}/ ..."
    mv "$NAMED_CONF_FILESPEC" "${NAMED_CONF_FILESPEC}.backup"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "ERROR: Failed to create a backup of /etc/${ETC_SUB_DIRNAME}/*"
      exit 3
    fi
  fi
else
  FILE_SETTING_PERFORM=false
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind9-systemd-after-online${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"

  # relative BUILDROOT directory path
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"
  echo "Creating subdirectories to $BUILDROOT$CHROOT_DIR$sysconfdir ..."
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$sysconfdir"

  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
  # shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for ISC Bind9 client"; \
  } >> "$FILE_SETTINGS_FILESPEC"
fi



if [ ! -d "$ETC_SYSTEMD_SYSTEM_DIRSPEC" ]; then
  echo "Systemd is not installed. Aborted."
  exit 1
fi
flex_ckdir "$ETC_SYSTEMD_DIRSPEC"
flex_ckdir "$ETC_SYSTEMD_SYSTEM_DIRSPEC"

#
# BIND_SYSD_UNIT="${BIND_PKG_NAME}.$SERVICE_FILETYPE"
# TEMPLATE_BIND_SYSD_UNIT="${BIND_PKG_NAME}@.$SERVICE_FILETYPE"


# Now tweak the original base unit service file.
# named.service or bind.service
TEMPLATE_SYSD_UNIT_DROPIN="${SYSD_BIND_TEMPLATE_SVCNAME}.service.d"
TEMPLATE_SYSD_DROPIN_DIRSPEC="${ETC_SYSTEMD_SYSTEM_DIRSPEC}/$TEMPLATE_SYSD_UNIT_DROPIN"
flex_ckdir "$TEMPLATE_SYSD_DROPIN_DIRSPEC"
if [ ! -d "$BUILDROOT$TEMPLATE_SYSD_DROPIN_DIRSPEC" ]; then
  echo "Unable to create ${TEMPLATE_SYSD_DROPIN_DIRSPEC} directory."
  exit 9
fi

flex_chmod 0755 "$TEMPLATE_SYSD_DROPIN_DIRSPEC"
flex_chown "root:root" "$TEMPLATE_SYSD_DROPIN_DIRSPEC"

#if [ "$systemd_unitname" == "bind" ]; then
  # Dont edit the bind.service directly, modify it
  # Stick in 'conflicts' with our new named@.service dropin subdir

  FILENAME="start-after-dhclient-is-up.conf"
  FILESPEC=$TEMPLATE_SYSD_DROPIN_DIRSPEC/${FILENAME}
  echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
  cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${TEMPLATE_SYSD_DROPIN_DIRSPEC}
# Title: Start named after DHCP client is up
# Creator: $(basename "$0")
# Created on: $(date)
#
# Description:
#   Defer the startup of 'named' daemon until
#   DHCP client is up and its IP address
#   fully resolved.
#
#   This is rather important if the
#   'interfaces-interval' option gets used 
#   in 'options' clause of named.conf.
#

[Unit]
After=network-online.target

BIND_EOF
  flex_chmod "0644"      "$FILESPEC"
  flex_chown "root:root" "$FILESPEC"
#fi

echo
echo "Done."
