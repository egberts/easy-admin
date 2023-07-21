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

if [ "$systemd_unitname" == "bind" ] \
   || [ "$systemd_unitname" == "named" ]; then
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
Conflicts=${systemd_unitname}.service

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
# Path: ${ETC_SYSTEMD_SYSTEM_DIRSPEC}
# Title: ISC Bind9 named daemon systemd unit
# Creator: $(basename "$0")
# Created on: $(date)
# Description:
#
#   An instantiation of bind9.service to support
#   bastion DNS hosting (multiple DNS servers on
#   multi-home gateway)
#
#   Cannot use '-f' nor '-g' option in this Bind9 
#   named setup without additional but intensive 
#   changes.
#
#   NAMED_OPTIONS string must be defined in ${INSTANCE_INIT_DEFAULT_FILESPEC}
#     Useful examples:
#        NAMED_OPTIONS="-p 53 -s"  # open port 53/udp and write stats
#        NAMED_OPTIONS="-d 63"   # turn on various debug bit flags
#
#   RNDC_OPTIONS string must be defined in ${INSTANCE_INIT_DEFAULT_FILESPEC}
#     Default example: RNDC_OPTIONS="-p 953 -s 127.0.0.1"
#
# References:
#   * https://bind9-users.isc.narkive.com/qECPVuuu/enable-systemd-hardening-options-for-named
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

# /var/cache/[named|bind]
ConditionPathExists=${VAR_CACHE_NAMED_DIRSPEC}
ConditionPathIsDirectory=${VAR_CACHE_NAMED_DIRSPEC}

ConditionPathExists=${VAR_CACHE_NAMED_DIRSPEC}/%I
ConditionPathIsDirectory=${VAR_CACHE_NAMED_DIRSPEC}/%I
ConditionPathIsReadWrite=${VAR_CACHE_NAMED_DIRSPEC}/%I

ConditionPathExists=${VAR_LIB_NAMED_DIRSPEC}
ConditionPathIsDirectory=${VAR_LIB_NAMED_DIRSPEC}
ConditionPathIsReadWrite=${VAR_LIB_NAMED_DIRSPEC}

ConditionPathExists=${VAR_LIB_NAMED_DIRSPEC}/%I
ConditionPathIsDirectory=${VAR_LIB_NAMED_DIRSPEC}/%I
ConditionPathIsReadWrite=${VAR_LIB_NAMED_DIRSPEC}/%I

ConditionPathExists=${log_dir}
ConditionPathIsDirectory=${log_dir}

ConditionPathExists=${log_dir}/%I
ConditionPathIsDirectory=${log_dir}/%I
ConditionPathIsReadWrite=${log_dir}/%I

# [/var]/run/[named|bind]
ConditionPathExists=${PID_DIRSPEC}
ConditionPathIsDirectory=${PID_DIRSPEC}

# [/var]/run/[named|bind]
ConditionPathExists=${PID_DIRSPEC}/%I
ConditionPathIsDirectory=${PID_DIRSPEC}/%I
ConditionPathIsReadWrite=${PID_DIRSPEC}/%I


[Service]
Type=simple

# resources
DeviceAllow=/dev/random r
DeviceAllow=/dev/urandom r
InaccessiblePaths=/home
InaccessiblePaths=/opt
InaccessiblePaths=/root

Environment=
EnvironmentFile=

# uncomment line for debug output during named startup
#Environment=SYSTEMD_LOG_LEVEL=debug

#Environment=NAMED_CONF="${INSTANCE_NAMED_CONF_FILESPEC}"
#Environment=NAMED_OPTIONS="-c ${INSTANCE_NAMED_CONF_FILESPEC}"
#Environment=RNDC_OPTIONS="-s %I -c ${INSTANCE_RNDC_CONF_FILESPEC}"

Environment=NAMED_CONF="${NAMED_CONF_DIRSPEC}/%I/${NAMED_CONF_FILENAME}"
Environment=NAMED_OPTIONS="-c "${NAMED_CONF_DIRSPEC}/%I/${NAMED_CONF_FILENAME}"
Environment=RNDC_OPTIONS="-s %I -c "${RNDC_CONF_DIRSPEC}/%I/${RNDC_CONF_FILENAME}"

# /etc/default/[named|bind] is optional
EnvironmentFile=-${INIT_DEFAULT_FILESPEC}
# instantiation-specific Bind environment file is absolutely required
EnvironmentFile=${INSTANCE_INIT_DEFAULT_FILESPEC}

# Far much easier to peel away additional capabilities after
# getting a bare-minimum cap-set working
# h.reindl at thelounge.net:
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_ADMIN CAP_DAC_OVERRIDE CAP_KILL CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_SYS_CHROOT

AmbientCapabilities=CAP_NET_BIND_SERVICE

SystemCallFilter=~@clock

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
ProtectHome=false
ProtectSystem=strict
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectKernelLogs=true
ProtectClock=true
ProtectProc=invisible
ProtectControlGroups=true
ProtectHostname=true
RestrictSUIDSGID=true
MemoryDenyWriteExecute=true
LockPersonality=true
RestrictAddressFamilies=~AF_PACKET
RestrictNamespaces=true
RestrictRealtime=true

# uncomment if using CHROOT
#RootDirectory=/$CHROOT_DIR

# any files generated by 'named' will not be available to 'named' group
UMask=0077

LogsDirectory=${LOG_SUB_DIRNAME}/%I
LogsDirectoryMode=0750

ConfigurationDirectory=+${INSTANCE_ETC_NAMED_DIRSPEC}/%I
ConfigurationDirectoryMode=0750

# **
# Tmpfiles
PrivateTmp=false

RuntimeDirectory=${VAR_SUB_DIRNAME}/%I
RuntimeDirectoryMode=0755

# Home directory (instantiation-excluded)
WorkingDirectory=$NAMED_HOME_DIRSPEC

# systemd v251
CacheDirectory=${VAR_SUB_DIRNAME}/%I
CacheDirectoryMode=0750

# State directory (Bind9 database files, static/dynamic)
StateDirectory=${VAR_SUB_DIRNAME}/%I
StateDirectoryMode=0750

#### PIDFile=$INSTANCE_PID_FILESPEC   # this needs work with 'Type='
ExecStartPre=/usr/sbin/named-checkconf -jz \$NAMED_CONF
ExecStart=/usr/sbin/named -f -u $USER_NAME -c \$NAMED_CONF \$NAMED_OPTIONS

# rndc will dovetail any and all instantiations of
# Bind9 'named' daemons into a single rndc.conf file
# and use its '-s <server>' as a reference from
# this rndc.conf config file.
ExecReload=/usr/sbin/rndc \$RNDC_OPTIONS reload
ExecStop=/usr/sbin/rndc \$RNDC_OPTIONS stop
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
# PermissionsStartOnly=True
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
# Path: $ETC_SYSTEMD_SYSTEM_DIRSPEC
# Title: ISC Bind9 named unit service file
# Creator: $(basename "$0")
# Created on: $(date)
#
# NAMED_OPTIONS string must be defined in /etc/default/bind
#    NAMED_OPTIONS cannot replace '-u' or '-c' option of
#    named(8) for its hard-coded in this file as:
#        '-u bind -c /etc/${ETC_SUB_DIRNAME}/named.conf'
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

# /etc/{named|bind}
ConditionPathExists=$ETC_NAMED_DIRSPEC
ConditionPathIsDirectory=$ETC_NAMED_DIRSPEC
ConditionPathIsReadWrite=$ETC_NAMED_DIRSPEC

# /var/cache/{named|bind}
ConditionPathExists=$VAR_CACHE_NAMED_DIRSPEC
ConditionPathIsDirectory=$VAR_CACHE_NAMED_DIRSPEC
ConditionPathIsReadWrite=$VAR_CACHE_NAMED_DIRSPEC

# /var/lib/{named|bind}
ConditionPathExists=$VAR_LIB_NAMED_DIRSPEC
ConditionPathIsDirectory=$VAR_LIB_NAMED_DIRSPEC
ConditionPathIsReadWrite=$VAR_LIB_NAMED_DIRSPEC

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
Environment=RNDC_OPTIONS=""

# default bind9 (global) is optional
EnvironmentFile=-/etc/default/${sysvinit_unitname}

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

UMask=0007
LogsDirectory=$LOG_SUB_DIRNAME
LogsDirectoryMode=0750

ConfigurationDirectory=+$INSTANCE_ETC_NAMED_DIRSPEC
ConfigurationDirectoryMode=0750

# **
# Tmpfiles
PrivateTmp=false

PermissionsStartOnly=True
RuntimeDirectory=$VAR_SUB_DIRNAME
RuntimeDirectoryMode=0755

# Home directory (derived from pw_dir/getpwd(5); instantiation-excluded)
WorkingDirectory=$NAMED_HOME_DIRSPEC

# systemd v251
CacheDirectory=$VAR_SUB_DIRNAME
CacheDirectoryMode=0750

# State directory (Bind9 database files, static/dynamic)
StateDirectory=$VAR_SUB_DIRNAME
StateDirectoryMode=0750

PIDFile=$INSTANCE_PID_FILESPEC
ExecStartPre=/usr/sbin/named-checkconf -z \$NAMED_CONF
ExecStart=/usr/sbin/named -u $USER_NAME \$NAMED_CONF

# rndc will dovetail any and all instantiations of
# Bind9 'named' daemons into a single rndc.conf file
# and use its '-s <server>' as a reference from
# this rndc.conf config file.
ExecReload=/usr/sbin/rndc \$RNDC_OPTIONS reload
ExecStop=/usr/sbin/rndc \$RNDC_OPTIONS stop
#ExecStop=/bin/sh -c /usr/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID

RestartSec=5s
Restart=on-failure

[Install]
WantedBy=multi-user.target


# Additional settings mentioned but not tested from
#   various Linux distros and ISC bind9-users
# CapabilityBoundingSet=CAP_SYS_RESOURCE
# IgnoreSIGPIPE=false
# LockPersonality=yes
# ProtectControlGroups=true
# ProtectKernelLogs=yes
# ProtectKernelModules=true
# ProtectKernelTunables=true
# RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
# RestrictRealtime=yes
# RestartPreventExitStatus=255
# SystemCallArchitectures=native
# Type=notify

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"
echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"


# Create the /etc/default/[named|bind] file
echo
FILENAME="$BIND_INIT_DEFAULT_FILENAME"
FILEPATH="$INIT_DEFAULT_DIRSPEC"
FILESPEC="$INIT_DEFAULT_FILESPEC"
mkdir -v "${BUILDROOT}${CHROOT}${INIT_DEFAULT_DIRSPEC}"

echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: SysV init.rc startup setting for general (non-instance) usage
# Creator: $(basename "$0")
# Created on: $(date)
#
#   NAMED_CONF - Full filepath specification to 'named.conf'
#
#   NAMED_OPTIONS - passthru CLI options for 'named' daemon
#                    cannot use -c option (use NAMED_PORT)
#
#   RNDC_OPTIONS - passthru CLI options for 'rndc' utility
#                    cannot use -p option (edit rndc.conf instead)
#
#   RESOLVCONF - Do a one-shot resolv.conf setup. 'yes' or 'no'
#           Only used in SysV/s6/OpenRC/ConMan; Ignored by systemd.
#
# default settings for startup options  of '$systemd_unitname'
# is located in ${ETC_SYSTEMD_SYSTEM_DIRSPEC}/${SYSTEMD_NAMED_SERVICE}
# and its defaults are:
#
#   NAMED_CONF="${NAMED_CONF_FILESPEC}"
#   NAMED_OPTIONS="-c ${NAMED_CONF_FILESPEC}"
#   RNDC_OPTIONS="-c ${RNDC_CONF_FILESPEC}"
#


# the "rndc.conf" should have all its server, key, port, and IP address defined
RNDC_OPTIONS="-c ${RNDC_CONF_FILESPEC}"

NAMED_CONF="${NAMED_CONF_FILESPEC}"

# Do not use '-f' or '-g' option in NAMED_OPTIONS
# systemd 'Type=simple' hardcoded this '-f'
### NAMED_OPTIONS="-L/tmp/mydns.out -c ${NAMED_CONF_FILESPEC}"
### NAMED_OPTIONS="-4 -c ${NAMED_CONF_FILESPEC}"
NAMED_OPTIONS="-c ${NAMED_CONF_FILESPEC}"

# There may be other settings in a unit-instance-specific default
# file such as /etc/default/named-public.conf or
# /etc/default/bind9-dmz.conf.

# run resolvconf?  (legacy sysV initrd)
RESOLVCONF=no

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"
echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"


if [ -n "$INSTANCE" ]; then
  # Create the /etc/default/[named|bind]/instance file
  echo
  FILENAME="$INSTANCE_INIT_DEFAULT_FILENAME"
  FILEPATH="$INIT_DEFAULT_DIRSPEC"
  FILESPEC="$INSTANCE_INIT_DEFAULT_FILESPEC"

  echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
  cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: SysV init.rc startup setting for "$INSTANCE"-specific instance
# Creator: $(basename "$0")
# Created on: $(date)
#
#   NAMED_CONF - Full filepath specification to 'named.conf'
#
#   NAMED_OPTIONS - passthru CLI options for 'named' daemon
#                    cannot use -c option (use NAMED_PORT)
#
#   RNDC_OPTIONS - passthru CLI options for 'rndc' utility
#                    cannot use -p option (edit rndc.conf instead)
#
#   RESOLVCONF - Do a one-shot resolv.conf setup. 'yes' or 'no'
#           Only used in SysV/s6/OpenRC/ConMan; Ignored by systemd.
#
# default settings for startup options  of '$systemd_unitname'
# is located in ${ETC_SYSTEMD_SYSTEM_DIRSPEC}/${INSTANCE_SYSTEMD_NAMED_SERVICE}
# and its defaults are:
#
#   NAMED_CONF="${INSTANCE_NAMED_CONF_FILESPEC}"
#   NAMED_OPTIONS="-c ${INSTANCE_NAMED_CONF_FILESPEC}"
#   RNDC_OPTIONS="-c ${INSTANCE_RNDC_CONF_FILESPEC}"
#


# the "rndc.conf" should have all its server, key, port, and IP address defined
RNDC_OPTIONS="-c ${INSTANCE_RNDC_CONF_FILESPEC}"

NAMED_CONF="${INSTANCE_NAMED_CONF_FILESPEC}"

# Do not use '-f' or '-g' option in NAMED_OPTIONS
# systemd 'Type=simple' hardcoded this '-f'
### NAMED_OPTIONS="-L/tmp/mydns.out -c ${INSTANCE_NAMED_CONF_FILESPEC}"
### NAMED_OPTIONS="-4 -c ${INSTANCE_NAMED_CONF_FILESPEC}"
NAMED_OPTIONS="-c ${INSTANCE_NAMED_CONF_FILESPEC}"

# There may be other settings in a unit-instance-specific default
# file such as /etc/default/named-public.conf or
# /etc/default/bind9-dmz.conf.

# run resolvconf?  (legacy sysV initrd)
RESOLVCONF=no

BIND_EOF
  flex_chown "root:root" "$FILESPEC"
  flex_chmod "0644"      "$FILESPEC"
  echo "Created $BUILDROOT$CHROOT_DIR$FILESPEC"
fi


echo
echo "Done."
