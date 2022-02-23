#!/bin/bash
# File: 512-dns-bind9-init-systemd.sh
# Title: Service default startup settings for Bind9
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

echo "Creating a new bind9@.service systemd unit file..."
echo ""

source ./maintainer-dns-isc.sh

FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind9-systemd-unitfile${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
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



CREATOR="$(basename "$0")"

if [ ! -d "$ETC_SYSTEMD_SYSTEM_DIRSPEC" ]; then
  echo "Systemd is not installed. Aborted."
  exit 1
fi
flex_mkdir "$ETC_SYSTEMD_DIRSPEC"
flex_mkdir "$ETC_SYSTEMD_SYSTEM_DIRSPEC"

#
# BIND_SYSD_UNIT="${BIND_PKG_NAME}.$SERVICE_FILETYPE"
# TEMPLATE_BIND_SYSD_UNIT="${BIND_PKG_NAME}@.$SERVICE_FILETYPE"


# Now tweak the original base unit service file.
# named.service or bind.service
TEMPLATE_SYSD_UNIT_DROPIN="${SYSD_BIND_TEMPLATE_SVCNAME}.d"
TEMPLATE_SYSD_DROPIN_DIRSPEC="${ETC_SYSTEMD_SYSTEM_DIRSPEC}/$TEMPLATE_SYSD_UNIT_DROPIN"
flex_mkdir "$TEMPLATE_SYSD_DROPIN_DIRSPEC"
if [ ! -d "$BUILDROOT$TEMPLATE_SYSD_DROPIN_DIRSPEC" ]; then
  echo "Unable to create ${TEMPLATE_SYSD_DROPIN_DIRSPEC} directory."
  exit 9
fi

DATE="$(date)"

flex_chmod 0644 "$TEMPLATE_SYSD_DROPIN_DIRSPEC"
flex_chown "root:root" "$TEMPLATE_SYSD_DROPIN_DIRSPEC"

if [ "$systemd_unitname" == "bind" ]; then
  # Dont edit the bind.service directly, modify it
  # Stick in 'conflicts' with our new named@.service dropin subdir

  FILENAME="unit-conflicts.conf"
  FILESPEC=$TEMPLATE_SYSD_DROPIN_DIRSPEC/${FILENAME}
  echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
  cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${TEMPLATE_SYSD_DROPIN_DIRSPEC}
# Title: systemd unit conflict detection
# Creator: $(basename "$0")
# Created on: $(date)
#
# Description:
#   If a unit has a 'Conflict=' setting on another unit
#   starting the former unit will stop the latter unit
#   and vice versa.
# Creator: ${CREATOR}
# Date: ${DATE}
#

[Unit]
Conflicts=bind.service

BIND_EOF
  flex_chown "root:root" "$FILESPEC"
  flex_chmod "0644"      "$FILESPEC"
fi

# Stick in 'default Debian settings' with our new bind@.service
FILENAME="bind9-instance.conf"
FILESPEC=$TEMPLATE_SYSD_DROPIN_DIRSPEC/${FILENAME}

# Tread carefully, don't be overwriting symbolic links within systemd
if [ -L "$FILESPEC" ]; then
  ls -lat "$FILESPEC"
  echo "Symbolic link?!  Remove it"
  rm "$FILESPEC"
fi
echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: ISC Bind9 named daemon systemd unit
# Creator: $(basename "$0")
# Created on: $(date)
#
# Description:
#
# An instantiation of bind9.service to support
# bastion DNS hosting (multiple DNS servers on
# multi-home gateway).
#
# Also supports 'multi-daemon split-horizon' as well
# as 'multi-view split-horizon'
#
# OPTIONS string must be defined in /etc/default/bind-%I
#    OPTIONS cannot replace '-u' or '-c' option of
#    named(8) for its hard-coded in this file as:
#        '-u ${USER_NAME} -c /etc/bind/named-%I.conf'
#    Useful Example:
#        OPTIONS="-u ${USER_NAME} -d 63"   # turn on various debug bit flags
#
# RNDC_OPTIONS string must be defined in /etc/default/bind-%I
#    RNDC_OPTIONS cannot replace '-p' or '-c' option of
#    rndc(8) for its hard-coded in this file as:
#        '-c /etc/bind/rndc-%I.conf'
#    Secured Example: RNDC_OPTIONS="-s 127.0.0.1"
#
# RESOLVCONF string is used only by initd (non-systemd). 'yes' or 'no'
#
# Creator: ${CREATOR}
# Date: ${DATE}
#

[Unit]
# Conflicts=bind9.service
# Conflicts=bind9@.service
# Conflicts=named.service
AssertFileIsExecutable=
AssertPathExists=
AssertPathIsDirectory=
AssertPathIsReadWrite=

AssertPathIsDirectory=${INSTANCE_SYSCONFDIR}/%I
AssertFileIsExecutable=${named_sbin_filespec}
AssertFileIsExecutable=/usr/sbin/rndc

## AssertPathExists=${rundir}/bind/%I
## AssertPathIsDirectory=${rundir}/bind/%I
## AssertPathIsReadWrite=${rundir}/bind/%I

AssertPathExists=${VAR_CACHE_NAMED_DIRSPEC}/%I
AssertPathIsDirectory=${VAR_CACHE_NAMED_DIRSPEC}/%I
AssertPathIsReadWrite=${VAR_CACHE_NAMED_DIRSPEC}/%I
AssertPathExists=${VAR_LIB_NAMED_DIRSPEC}/%I
AssertPathIsDirectory=${VAR_LIB_NAMED_DIRSPEC}/%I
AssertPathIsReadWrite=${VAR_LIB_NAMED_DIRSPEC}/%I


[Service]
WorkingDirectory=${VAR_CACHE_NAMED_DIRSPEC}/%I
RootDirectory=/
RuntimeDirectory=+${rundir}/bind
StateDirectory=+${VAR_LIB_NAMED_DIRSPEC}
CacheDirectory=+${VAR_CACHE_NAMED_DIRSPEC}
LogsDirectory=${INSTANCE_LOG_DIRSPEC}/%I
ConfigurationDirectory=+${INSTANCE_ETC_NAMED_DIRSPEC}/%I

User=$USER_NAME
Group=$GROUP_NAME


# resources
###LimitNPROC=10
UMask=0007
DeviceAllow=/dev/random r
DeviceAllow=/dev/urandom r
DeviceAllow=/dev/poll rw

# Erase any prior settings of EnvironmentFile=
EnvironmentFile=

# Pick up global-wide Bind9 settings (for all instances)
EnvironmentFile=-/etc/default/named

# Instance-specific Bind environment file required
EnvironmentFile=/etc/default/named-%I

CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_SETGID CAP_SETUID CAP_SYS_CHROOT CAP_DAC_OVERRIDE

# File Security settings
# must use 'ReadWritePaths=' to circumvent 'ProtectSystem=strict'
ProtectSystem=strict
ProtectHome=true

NoNewPrivileges=true
MemoryDenyWriteExecute=true
ProtectClock=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectKernelModules=true
ProtectKernelTunables=true
# RestrictAddressFamilies=true
# RestrictNamespaces=true
# RestrictRealtime=true
RestrictSUIDSGID=true

ProtectControlGroups=true

# File Security settings
# bind:bind
LogsDirectoryMode=0027
# root:bind
ReadWritePaths=+/var/log/named/%I

# **
# Tmpfiles
PrivateTmp=no

# /etc/bind
ConfigurationDirectoryMode=2022
ReadOnlyPaths=+${INSTANCE_ETC_NAMED_DIRSPEC}/
ReadOnlyPaths=+${INSTANCE_ETC_NAMED_DIRSPEC}/*
ReadOnlyPaths=+${INSTANCE_ETC_NAMED_DIRSPEC}/*/*


# root:bind
# RuntimeDirectory=+${rundir}/bind/%I
RuntimeDirectory=bind/%I
RuntimeDirectoryMode=0007
# Save the /run/bind/%I directory after 'systemctl bind9 stop/restart'
RuntimeDirectoryPreserve=yes
ReadWritePaths=+${rundir}/bind/%I


# Home directory
# bind:bind
CacheDirectory=+${VAR_CACHE_NAMED_DIRSPEC}/%I
CacheDirectoryMode=0022
ReadWritePaths=+${VAR_CACHE_NAMED_DIRSPEC}/%I

# State directory (Bind9 database files, static/dynamic)
# bind:bind
StateDirectoryMode=0027
StateDirectory=+/var/lib/bind/%I
ReadWritePaths=+/var/lib/bind/%I

Type=forking
PIDFile=${rundir}/named/%I/named.pid
# Delete old ExecXXXX settings
ExecStart=
ExecReload=
ExecStop=
# Redefine ExecXXXX settings
ExecStart=/usr/sbin/named -f -c ${INSTANCE_ETC_NAMED_DIRSPEC}/%I/named.conf \$OPTIONS
ExecReload=/usr/sbin/rndc -c ${INSTANCE_ETC_NAMED_DIRSPEC}/rndc-%I.conf \$RNDC_OPTIONS reload
ExecStop=/usr/sbin/rndc -c ${INSTANCE_ETC_NAMED_DIRSPEC}/rndc-%I.conf \$RNDC_OPTIONS stop

KillMode=process
RestartSec=5s

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"
echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"


echo ""
# Copy Debian 'named.service' default as 'bind9@.service'
FILENAME="$SYSD_BIND_TEMPLATE_SVCNAME"
FILEPATH="$ETC_SYSTEMD_SYSTEM_DIRSPEC"
FILESPEC="${FILEPATH}/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: ISC Bind9 named unit service file
# Creator: $(basename "$0")
# Created on: $(date)
#

[Unit]
Description=BIND Domain Name Server
Documentation=man:named(8)
After=network.target
Wants=nss-lookup.target
Before=nss-lookup.target

[Service]
EnvironmentFile=-/etc/default/named
ExecStart=/usr/sbin/named -f \$OPTIONS
ExecReload=/usr/sbin/rndc reload
ExecStop=/usr/sbin/rndc stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
# Do this right, no alias here
# Alias=
DefaultInstance=default

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"


echo ""
echo "Done."
exit 0
