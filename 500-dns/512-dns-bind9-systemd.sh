#!/bin/bash
# File: 512-dns-bind9-init-systemd.sh
# Title: Service default startup settings for Bind9
# Description:
#
# Prerequisites:
#

source  ./maintainer-dns-isc.sh

echo "Creating a new bind9@.service systemd unit file..."
echo ""
CREATOR="$(basename "$0")"

if [ ! -d "$SYSTEMD_SYSTEM_DIRSPEC" ]; then
  echo "Systemd is not installed. Aborted."
  exit 1
fi

#
function stop_disable_unit ()
{
  ACTIVE="$(systemctl is-active "${1}" 2>/dev/null )"
  if [ x"$ACTIVE" == x"active" ]; then
    echo "Stopping systemd $1 service."
    systemctl stop "$1"
    echo "Stopped systemd $1 service."
  fi
  EXISTS="$(systemctl is-enabled "${1}" 2>/dev/null )"
  if [ x"$EXISTS" == x"enabled" ]; then
    echo "Disabling systemd $1 service."
    systemctl disable "$1"
    echo "Disabled systemd $1 service."
  fi
}

# Both ISC DNS services are alias to each other,  Read-only
# BIND_SYSD_UNIT="${BIND_PKG_NAME}.$SERVICE_FILETYPE"
# TEMPLATE_BIND_SYSD_UNIT="${BIND_PKG_NAME}@.$SERVICE_FILETYPE"

echo "Stopping pre-existing Bind9 named service ..."
stop_disable_unit "$SYSD_BIND_SVCNAME"
stop_disable_unit "$SYSD_BIND_ALT_SVCNAME"


# Now tweak the original base unit service file.
# named.service or bind.service
TEMPLATE_SYSD_UNIT_DROPIN="${SYSD_BIND_TEMPLATE_SVCNAME}.d"
TEMPLATE_SYSD_DROPIN_DIRSPEC="${SYSTEMD_SYSTEM_DIRSPEC}/$TEMPLATE_SYSD_UNIT_DROPIN"
flex_mkdir "$TEMPLATE_SYSD_DROPIN_DIRSPEC"
if [ ! -d "$BUILDROOT$TEMPLATE_SYSD_DROPIN_DIRSPEC" ]; then
  echo "Unable to create ${TEMPLATE_SYSD_DROPIN_DIRSPEC} directory."
  exit 9
fi

DATE="$(date)"

flex_chmod 0644 "$TEMPLATE_SYSD_DROPIN_DIRSPEC"
flex_chown "root:root" "$TEMPLATE_SYSD_DROPIN_DIRSPEC"

# Dont edit the bind.service directly, modify it
# Stick in 'conflicts' with our new named@.service dropin subdir

FILENAME="unit-conflicts.conf"
FILESPEC=$TEMPLATE_SYSD_DROPIN_DIRSPEC/${FILENAME}
echo "Creating $FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${TEMPLATE_SYSD_DROPIN_DIRSPEC}
# Title: systemd unit conflict detection
# Description:
#   If a unit has a 'Conflict=' setting on another unit
#   starting the former unit will stop the latter unit
#   and vice versa.
# Creator: ${CREATOR}
# Date: ${DATE}
#

[Unit]
Conflicts=named.service

BIND_EOF
flex_chown "root:root" "${CHROOT_DIR}$FILESPEC"
flex_chmod "0644"      "${CHROOT_DIR}$FILESPEC"

# Stick in 'default Debian settings' with our new bind@.service
FILENAME="egbert-modifications.conf"
FILESPEC=$TEMPLATE_SYSD_DROPIN_DIRSPEC/${FILENAME}

# Tread carefully, don't be overwriting symbolic links within systemd
if [ -L "$FILESPEC" ]; then
  ls -lat "$FILESPEC"
  echo "Symbolic link?!  Remove it"
  rm "$FILESPEC"
fi
echo "Creating $FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: ISC Bind9 named daemon systemd unit
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
#        '-u bind -c /etc/bind/named-%I.conf'
#    Useful Example:
#        OPTIONS="-u bind -d 63"   # turn on various debug bit flags
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
Conflicts=bind9.service
Conflicts=named@.service
Conflicts=named.service
AssertFileIsExecutable=
AssertPathExists=
AssertPathIsDirectory=
AssertPathIsReadWrite=
AssertFileIsExecutable=/usr/sbin/named
AssertFileIsExecutable=/usr/sbin/rndc
## AssertPathExists=/run/bind/%I
## AssertPathIsDirectory=/run/bind/%I
## AssertPathIsReadWrite=/run/bind/%I
AssertPathExists=/var/cache/bind/%I
AssertPathIsDirectory=/var/cache/bind/%I
AssertPathIsReadWrite=/var/cache/bind/%I
AssertPathExists=/var/lib/bind/%I
AssertPathIsDirectory=/var/lib/bind/%I
AssertPathIsReadWrite=/var/lib/bind/%I


[Service]
WorkingDirectory=/var/cache/bind/%I
RootDirectory=/
RuntimeDirectory=+/run/bind
StateDirectory=+/var/lib/bind
CacheDirectory=+/var/cache/bind
LogsDirectory=named/%I
ConfigurationDirectory=+/etc/bind/%I

User=bind
Group=bind


# resources
###LimitNPROC=10
UMask=0007
DeviceAllow=/dev/random r
DeviceAllow=/dev/urandom r
DeviceAllow=/dev/poll rw

# Erase any prior settings of EnvironmentFile=
EnvironmentFile=

# Pick up global-wide Bind9 settings (for all instances)
EnvironmentFile=-/etc/default/bind9

# Instance-specific Bind environment file required
EnvironmentFile=/etc/default/bind9-%I

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
ReadOnlyPaths=+/etc/bind
ReadOnlyPaths=+/etc/bind/*
ReadOnlyPaths=+/etc/bind/*/*


# root:bind
# RuntimeDirectory=+/run/bind/%I
RuntimeDirectory=bind/%I
RuntimeDirectoryMode=0007
# Save the /run/bind/%I directory after 'systemctl bind9 stop/restart'
RuntimeDirectoryPreserve=yes
ReadWritePaths=+/run/bind/%I


# Home directory
# bind:bind
CacheDirectory=+/var/cache/bind/%I
CacheDirectoryMode=0022
ReadWritePaths=+/var/cache/bind/%I

# State directory (Bind9 database files, static/dynamic)
# bind:bind
StateDirectoryMode=0027
StateDirectory=+/var/lib/bind/%I
ReadWritePaths=+/var/lib/bind/%I

Type=forking
PIDFile=/run/named/%I/named.pid
# Delete old ExecXXXX settings
ExecStart=
ExecReload=
ExecStop=
# Redefine ExecXXXX settings
ExecStart=/usr/sbin/named -f -c /etc/bind/%I/named.conf \$OPTIONS
ExecReload=/usr/sbin/rndc -c /etc/bind/rndc-%I.conf \$RNDC_OPTIONS reload
ExecStop=/usr/sbin/rndc -c /etc/bind/rndc-%I.conf \$RNDC_OPTIONS stop

KillMode=process
RestartSec=5s

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"
echo "Created $FILESPEC"


echo ""
# Copy Debian 'named.service' default as 'bind9@.service'
FILENAME="$SYSD_BIND_TEMPLATE_SVCNAME"
FILEPATH="$SYSTEMD_SYSTEM_DIRSPEC"
FILESPEC="${FILEPATH}/$FILENAME"
echo "Creating $FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
# now /etc/systemd/system/bind9.service
# was /lib/systemd/system/named.service
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
