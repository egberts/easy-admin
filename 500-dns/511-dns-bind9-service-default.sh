#!/bin/bash
# File: 511-dns-bind9-service-default.sh
# Title: Service default startup setting for Bind9
# Description:
#
# Prerequisites:
#
# Env varnames
#   - BUILDROOT - '/' for direct installation, otherwise create 'build' subdir
#   - RNDC_PORT - Port number for Remote Name Daemon Control (rndc)
#   - RNDC_CONF - rndc configuration file
#   - INSTANCE - Bind9 instance name, if any
#

echo "Create SysV and Systemd default file for ISC Bind9 named daemon"
echo

source ./maintainer-dns-isc.sh

FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind9-service-defaults${INSTANCE_FILEPART}.sh"

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old bind/named settings"
  # Only the first copy is saved as the backup
  if [ ! -f "${NAMED_CONF_FILESPEC}.backup" ]; then
    BACKUP_FILENAME=".backup-$(date +'%Y%M%d%H%M')"
    echo "Moving /etc/bind/* to /etc/bind/${BACKUP_FILENAME}/ ..."
    mv "$NAMED_CONF_FILESPEC" "${NAMED_CONF_FILESPEC}.backup"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "ERROR: Failed to create a backup of /etc/${ETC_SUB_DIRNAME}/*"
      exit 3
    fi
  fi
else
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"
  # mkdir -p "${BUILDROOT}${CHROOT_DIR}$sysconfdir"
  # flex_mkdir "$sysconfdir"
  # flex_mkdir "$extended_sysconfdir"
  # flex_mkdir "$INIT_DEFAULT_DIRSPEC"

  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
  # shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for ISC Bind9 named daemon"; \
  } >> "$FILE_SETTINGS_FILESPEC"
fi



function create_sysv_default() {

  # Make it work for both 'rndc.conf' and 'rndc-public.conf', et. al.
  # /etc/default/bind9
  # /etc/default/bind9-default
  # /etc/default/bind9-public

  # build/etc/default
  flex_mkdir "$ETC_DIRSPEC"
  flex_mkdir "$INIT_DEFAULT_DIRSPEC"

  echo "Creating ${BUILDROOT}${CHROOT_DIR}$BIND_INIT_DEFAULT_FILENAME"
  cat << EOF | tee "${BUILDROOT}${CHROOT_DIR}$INSTANCE_INIT_DEFAULT_FILESPEC" >/dev/null

#
# File: ${BIND_INIT_DEFAULT_FILENAME}
# Path: ${INIT_DEFAULT_DIRSPEC}
# Title: Bind9 configuration for SysV/systemd service startup
# Description:
#   Service startup init settings
#     OPTIONS -      passthru CLI options for 'named' daemon
#     RNDC_OPTIONS - passthru CLI options for 'rndc' utility
#                    cannot use -p option (use RNDC_PORT)
#                    cannot use -c option (uses /etc/${ETC_SUB_DIRNAME}/named-%I.conf)
#     RNDC_PORT - Port number
#
#     RESOLVCONF - Do a one-shot resolv.conf setup. 'yes' or 'no'
#           Only used in SysV/s6/OpenRC/ConMan; Ignored by systemd.

RESOLVCONF=no

# Fork all subsequential daemons as '$USER_NAME' user.
OPTIONS="-u $USER_NAME"

# the "rndc.conf" should have all its server, key, port, and IP address defined
RNDC_OPTIONS="-c $RNDC_CONF"

# There may be other settings in a unit-instance-specific default
# file such as /etc/default/${sysvinit_unitname}-public.conf or
# /etc/default/bind9-dmz.conf.
EOF
}


create_sysv_default

echo ""
echo "Done."
exit 0

