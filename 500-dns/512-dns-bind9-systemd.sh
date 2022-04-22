#!/bin/bash
# File: 512-dns-bind9-init-systemd.sh
# Title: Service default startup settings for Bind9
# Description:
#   Drop two new systemd unit files:
#      named/bind9.service
#      named@/bind9@.service
#   Also add a conflict to any existing 'bind.service' to our unit files
#
# Prerequisites:
#
# Env varnames
#   - BUILDROOT - '/' for direct installation, otherwise create 'build' subdir
#   - RNDC_CONF - rndc configuration file
#   - INSTANCE - Bind9 instance name, if any
#

echo "Creating a new bind9@.service systemd unit file..."
echo

source ./maintainer-dns-isc.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind9-systemd-unitfile${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
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
#

[Unit]
Conflicts=bind.service

BIND_EOF
  flex_chown "root:root" "$FILESPEC"
  flex_chmod "0644"      "$FILESPEC"
fi

# bind9@.service or named@.service
FILENAME="${SYSD_BIND_TEMPLATE_SVCNAME}@.service"
FILESPEC=$ETC_SYSTEMD_SYSTEM_DIRSPEC/${FILENAME}

# Tread carefully, don't be overwriting symbolic links within systemd
if [ -L "$FILESPEC" ]; then
  ls -lat "$FILESPEC"
  echo "Symbolic link?!  Remove it"
  rm "$FILESPEC"
fi

# bind9@.service or named@.service
echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: ISC Bind9 named daemon systemd unit
# Creator: $(basename "$0")
# Created on: $(date)
#
#
# An instantiation of bind9.service to support
# bastion DNS hosting (multiple DNS servers on
# multi-home gateway)
#
# PORT number must be defined in /etc/default/bind
#
# This same PORT number must be declared in 'default-port'
#    statement of 'options' section in /etc/rndc.conf
#
# This same PORT number must be declared in 'listen-on'
#    statement of 'options' section.
#
# NAMED_OPTIONS string must be defined in /etc/default/bind
#    NAMED_OPTIONS cannot replace '-u' or '-c' option of
#    named(8) for its hard-coded in this file as:
#        '-u bind -c /etc/bind/named.conf'
#    Useful examples:
#        NAMED_OPTIONS="-p 53 -s"  # open port 53/udp and write stats
#        NAMED_OPTIONS="-d 63"   # turn on various debug bit flags
#
# RNDC_OPTIONS string must be defined in /etc/default/bind
#    Secured Example: RNDC_OPTIONS="-p 953 -s 127.0.0.1"
#
# References:
#   * https://bind9-users.isc.narkive.com/qECPVuuu/enable-systemd-hardening-options-for-named
#
#
#
[Unit]
Description=ISC BIND9 Domain Name Server for %I
Documentation=https://github.com/egberts/systemd-bind9
Documentation=https://bind9.readthedocs.io/
Documentation=man:named(8)
After=network.target
Wants=nss-lookup.target
Before=nss-lookup.target
# AssertFileIsExecutable=/usr/sbin/named
# AssertFileIsExecutable=/usr/sbin/rndc
# AssertPathIsDirectory=${INSTANCE_SYSCONFDIR}/%I
# AssertFileIsExecutable=${named_sbin_filespec}
# AssertFileIsExecutable=/usr/sbin/rndc
# AssertPathExists=${VAR_CACHE_NAMED_DIRSPEC}/%I
# AssertPathIsDirectory=${VAR_CACHE_NAMED_DIRSPEC}/%I
# AssertPathIsReadWrite=${VAR_CACHE_NAMED_DIRSPEC}/%I
# AssertPathExists=${VAR_LIB_NAMED_DIRSPEC}/%I
# AssertPathIsDirectory=${VAR_LIB_NAMED_DIRSPEC}/%I
# AssertPathIsReadWrite=${VAR_LIB_NAMED_DIRSPEC}/%I


# ConditionPathExists=/run/bind
# ConditionPathIsDirectory=/run/bind

# ConditionPathExists=/run/bind/%I
# ConditionPathIsDirectory=/run/bind/%I
# ConditionPathIsReadWrite=/run/bind/%I

# ConditionPathExists=/var/cache/bind
# ConditionPathIsDirectory=/var/cache/bind

# ConditionPathExists=/var/cache/bind/%I
# ConditionPathIsDirectory=/var/cache/bind/%I
# ConditionPathIsReadWrite=/var/cache/bind/%I

ConditionPathExists=/var/lib/bind
ConditionPathIsDirectory=/var/lib/bind

ConditionPathExists=/var/lib/bind/%I
ConditionPathIsDirectory=/var/lib/bind/%I
ConditionPathIsReadWrite=/var/lib/bind/%I
ReadWritePaths=/var/lib/bind/%I

ConditionPathExists=/var/log/named/%I
ConditionPathIsDirectory=/var/log/named/%I
ConditionPathIsReadWrite=/var/log/named/%I
ReadWritePaths=/var/log/named/%I

# ReadOnlyPaths=+${INSTANCE_ETC_NAMED_DIRSPEC}/
# ReadOnlyPaths=+${INSTANCE_ETC_NAMED_DIRSPEC}/*
# ReadOnlyPaths=+${INSTANCE_ETC_NAMED_DIRSPEC}/*/*
# ReadWritePaths=+${INSTANCE_LOG_NAMED_DIRSPEC}/
# ReadWritePaths=+${VAR_CACHE_NAMED_DIRSPEC}/%I
# ReadWritePaths=+${VAR_LIB_NAMED_DIRSPEC}/%I

[Service]
Type=forking

# resources
###LimitNPROC=10
DeviceAllow=/dev/random r
DeviceAllow=/dev/urandom r
InaccessiblePaths=/home
InaccessiblePaths=/opt
InaccessiblePaths=/root

# global bind9 is optional
Environment=NAMED_OPTIONS="-c ${NAMED_CONF_FILESPEC}"
Environment=RNDC_OPTIONS=""

Environment=RNDC_BIN=/usr/sbin/rndc
Environment=NAMED_BIN=/usr/sbin/named
Environment=NAMED_CHECKCONF_BIN=/usr/sbin/named-checkconf

EnvironmentFile=-/etc/default/bind9
# instantiation-specific Bind environment file is absolutely required
EnvironmentFile=/etc/default/bind9-%I

# Far much easier to peel away additional capabilities after
# getting a bare-minimum cap-set working
# h.reindl at thelounge.net:
CapabilityBoundingSet=CAP_CHOWN CAP_SETGID CAP_SETUID CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_KILL CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_IPC_LOCK CAP_SYS_CHROOT
AmbientCapabilities=CAP_NET_BIND_SERVICE

# User/Group
# If you set 'DynamicUser=true', MANY subdirectories will be created
# under /var/cache, /var/log, /var/run; save yourself some pain, don't do that.
# TO undo this accident, rm /var/[(log|run|cache)/(named|bind)
# and restore via 'mv /var/log/private/named /var/log/'
# and restore via 'mv /var/run/private/named /var/run/'
# and restore via 'mv /var/cache/private/named /var/cache/'
DynamicUser=false
User=${USER_NAME}
Group=${GROUP_NAME}

# File Security settings
NoNewPrivileges=true
ProtectHome=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true

RootDirectory=/$CHROOT_DIR
UMask=0007
LogsDirectory=${LOG_SUB_DIRNAME}/%I
LogsDirectoryMode=0750

ConfigurationDirectory=+${INSTANCE_ETC_NAMED_DIRSPEC}/%I
ConfigurationDirectoryMode=0750

# **
# Tmpfiles
PrivateTmp=false

RuntimeDirectory=${VAR_SUB_DIRNAME}/%I
RuntimeDirectoryMode=0750

# Home directory (instantiation-excluded)
WorkingDirectory=$DISTRO_HOME_DIRSPEC

# systemd v251
CacheDirectory=${VAR_SUB_DIRNAME}/%I
CacheDirectoryMode=0750

# State directory (Bind9 database files, static/dynamic)
StateDirectory=${VAR_SUB_DIRNAME}/%I
StateDirectoryMode=0750

PIDFile=$INSTANCE_PID_FILESPEC
ExecStartPre=\$NAMED_CHECKCONF_BIN -z \$NAMED_CONF
ExecStart=\$NAMED_BIN -u $USER_NAME \$NAMED_CONF

# rndc will dovetail any and all instantiations of
# Bind9 'named' daemons into a single rndc.conf file
# and use its '-s <server>' as a reference from
# this rndc.conf config file.
ExecReload=\$RNDC_BIN \$RNDC_OPTIONS reload
ExecStop=\$RNDC_BIN \$RNDC_OPTIONS stop
#ExecStop=/bin/sh -c /usr/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID

# No need for 'KillMode=process' unless cgroups get disabled
RestartSec=5s
Restart=on-failure

[Install]
WantedBy=multi-user.target


# Additional settings mentioned but not tested from
#   various Linux distros and ISC bind9-users
# CapabilityBoundingSet=CAP_SYS_RESOURCE
# IgnoreSIGPIPE=false
# LockPersonality=yes
# PermissionsStartOnly=True
# PrivateDevices=true
# PrivateMounts=yes
# ProtectKernelLogs=yes
# ProtectSystem=strict
# ReadWritePaths=/run/named /var/run/named
# ReadWritePaths=/var/cache/bind
# RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
# RestrictRealtime=yes
# RestartPreventExitStatus=255
# SystemCallArchitectures=native
# Type=notify

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"
echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"

# bind9/named.service
echo
FILENAME="${SYSD_BIND_TEMPLATE_SVCNAME}.service"
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
# NAMED_OPTIONS string must be defined in /etc/default/bind
#    NAMED_OPTIONS cannot replace '-u' or '-c' option of
#    named(8) for its hard-coded in this file as:
#        '-u bind -c /etc/bind/named.conf'
#    Useful examples:
#        NAMED_OPTIONS="-p 53 -s"  # open port 53/udp and write stats
#        NAMED_OPTIONS="-d 63"   # turn on various debug bit flags
#
# RNDC_OPTIONS string must be defined in /etc/default/bind
#    Secured Example: RNDC_OPTIONS="-p 953 -s 127.0.0.1"
#
# References:
#   * https://bind9-users.isc.narkive.com/qECPVuuu/enable-systemd-hardening-options-for-named
#
#
#
[Unit]
Description=ISC BIND9 Domain Name Server
Documentation=https://github.com/egberts/systemd-bind9
Documentation=https://bind9.readthedocs.io/
Documentation=man:named(8)
After=network.target
Wants=nss-lookup.target
Before=nss-lookup.target

# ConditionPathExists=$VAR_NAMED_DIRSPEC
# ConditionPathIsDirectory=$VAR_NAMED_DIRSPEC
# ConditionPathIsReadWrite=$VAR_NAMED_DIRSPEC

# ConditionPathExists=$VAR_CACHE_NAMED_DIRSPEC
# ConditionPathIsDirectory=$VAR_CACHE_NAMED_DIRSPEC
# ConditionPathIsReadWrite=$VAR_CACHE_NAMED_DIRSPEC

# ConditionPathExists=$VAR_LIB_NAMED_DIRSPEC
ConditionPathIsDirectory=$VAR_LIB_NAMED_DIRSPEC
ConditionPathIsReadWrite=$VAR_LIB_NAMED_DIRSPEC
#ReadWritePaths=$VAR_LIB_NAMED_DIRSPEC

[Service]
Type=forking

# resources
###LimitNPROC=10
DeviceAllow=/dev/random r
DeviceAllow=/dev/urandom r
InaccessiblePaths=/home
InaccessiblePaths=/opt
InaccessiblePaths=/root

Environment=NAMED_OPTIONS="-c $NAMED_CONF_FILESPEC"
Environment=RNDC_OPTIONS="-p 953 -s localhost"

Environment=RNDC_BIN="/usr/sbin/rndc"
Environment=NAMED_BIN="/usr/sbin/named"
Environment=NAMED_CHECKCONF_BIN="/usr/sbin/named-checkconf"

# default bind9 (global) is optional
EnvironmentFile=-/etc/default/bind9

# Far much easier to peel away additional capabilities after
# getting a bare-minimum cap-set working
# h.reindl at thelounge.net:
CapabilityBoundingSet=CAP_CHOWN CAP_SETGID CAP_SETUID CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_KILL CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_IPC_LOCK CAP_SYS_CHROOT
AmbientCapabilities=CAP_NET_BIND_SERVICE

# User/Group
# If you set 'DynamicUser=true', MANY subdirectories will be created
# under /var/cache, /var/log, /var/run; save yourself some pain, don't do that.
# TO undo this accident, rm /var/[(log|run|cache)/(named|bind)
# and restore via 'mv /var/log/private/named /var/log/'
# and restore via 'mv /var/run/private/named /var/run/'
# and restore via 'mv /var/cache/private/named /var/cache/'
DynamicUser=false
User=${USER_NAME}
Group=${GROUP_NAME}

# File Security settings
NoNewPrivileges=true
ProtectHome=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true

RootDirectory=/$CHROOT_DIR
UMask=0007
LogsDirectory=$LOG_SUB_DIRNAME
LogsDirectoryMode=0750

ConfigurationDirectory=+$INSTANCE_ETC_NAMED_DIRSPEC
ConfigurationDirectoryMode=0750

# **
# Tmpfiles
PrivateTmp=false

RuntimeDirectory=$VAR_SUB_DIRNAME
RuntimeDirectoryMode=0750

# Home directory
WorkingDirectory=$DISTRO_HOME_DIRSPEC

# systemd v251
CacheDirectory=$VAR_SUB_DIRNAME
CacheDirectoryMode=0750

# State directory (Bind9 database files, static/dynamic)
StateDirectory=$VAR_SUB_DIRNAME
StateDirectoryMode=0750

PIDFile=$INSTANCE_PID_FILESPEC
ExecStartPre=\$NAMED_CHECKCONF_BIN -z \$NAMED_CONF
ExecStart=\$NAMED_BIN -u $USER_NAME \$NAMED_CONF

# rndc will dovetail any and all instantiations of
# Bind9 'named' daemons into a single rndc.conf file
# and use its '-s <server>' as a reference from
# this rndc.conf config file.
ExecReload=\$RNDC_BIN \$RNDC_OPTIONS reload
ExecStop=\$RNDC_BIN \$RNDC_OPTIONS stop
#ExecStop=/bin/sh -c /usr/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID

# No need for 'KillMode=process' unless cgroups get disabled
RestartSec=5s
Restart=on-failure

[Install]
WantedBy=multi-user.target


# Additional settings mentioned but not tested from
#   various Linux distros and ISC bind9-users
# CapabilityBoundingSet=CAP_SYS_RESOURCE
# IgnoreSIGPIPE=false
# LockPersonality=yes
# PermissionsStartOnly=True
# PrivateDevices=true
# PrivateMounts=yes
# ProtectKernelLogs=yes
# ProtectSystem=strict
# ReadWritePaths=/run/named /var/run/named
# ReadWritePaths=/var/cache/bind
# RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
# RestrictRealtime=yes
# RestartPreventExitStatus=255
# SystemCallArchitectures=native
# Type=notify

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"
echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"

echo
echo "Done."
