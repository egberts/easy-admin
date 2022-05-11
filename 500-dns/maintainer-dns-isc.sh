#!/bin/bash
# File: maintainer-dns-isc.sh
# Title: Common settings for ISC DNS 
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   INSTANCE
#   VAR_LIB_NAMED_DIRNAME - useful for multi-instances of 'named' daemons

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

extracted_dirspec="$(dirname $(realpath $0))"

source ../easy-admin-installer.sh

SYSD_BIND_TEMPLATE_SVCNAME="named"
SYSD_BIND_SVCNAME="named"
SYSD_BIND_ALT_SVCNAME="bind"

source ../distro-os.sh


function unique_add_line()
{
  include_name="$1"
  filespec="$2"
  flex_touch "$include_name"
  grep -q -c "include \"$include_name\";" "${BUILDROOT}${CHROOT_DIR}$filespec"
  retsts=$?
  if [ $retsts -ge 1 ]; then
    # not found
    echo "; inserted by $(basename "$0")" >> "${BUILDROOT}${CHROOT_DIR}$filespec"
    echo "include \"$include_name\";" >> "${BUILDROOT}${CHROOT_DIR}$filespec"
    echo >> "${BUILDROOT}${CHROOT_DIR}$filespec"
  fi
  unset filespec
  unset include_name
}


NAMED_CONF_FILEPART="named"
NAMED_CONF_FILETYPE=".conf"
NAMED_CONF_FILENAME="${NAMED_CONF_FILEPART}${NAMED_CONF_FILETYPE}"

DHCP_TO_BIND_KEYNAME="local-ddns"
RNDC_KEYNAME="rndc-key"
RNDC_PORT="953"

RNDC_CONF_FILEPART="rndc"
RNDC_CONF_FILETYPE=".conf"
RNDC_CONF_FILENAME="${RNDC_CONF_FILEPART}${RNDC_CONF_FILETYPE}"

RNDC_KEY_FILEPART="rndc"
RNDC_KEY_FILETYPE=".key"
RNDC_KEY_FILENAME="${RNDC_KEY_FILEPART}${RNDC_KEY_FILETYPE}"

# ISC Bind9 configuration filename default
if [ -z "$INSTANCE" ]; then
  INSTANCE_SUBDIRPATH=""
  INSTANCE_NAMED_CONF_FILEPART_SUFFIX=""
else
  INSTANCE_SUBDIRPATH="/$INSTANCE"
  INSTANCE_NAMED_CONF_FILEPART_SUFFIX="-$INSTANCE"
fi
INSTANCE_NAMED_CONF_FILENAME="${NAMED_CONF_FILENAME}"
INSTANCE_RNDC_CONF_FILENAME="${RNDC_CONF_FILENAME}"

case $ID in
  debian|devuan)
    USER_NAME="bind"
    GROUP_NAME="bind"
    ETC_SUB_DIRNAME="bind"
    VAR_SUB_DIRNAME="bind"
    LOG_SUB_DIRNAME="named"
    DISTRO_HOME_DIRSPEC="/var/cache/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-bind}"
    VAR_LIB_NAMED_DIRSPEC="${VAR_DIRSPEC}/lib/${VAR_LIB_NAMED_DIRNAME}"
    if [ "$VERSION_ID" -ge 11 ]; then
      NAMED_CONF_DIRSPEC="${ETC_DIRSPEC}/${ETC_SUB_DIRNAME}"
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-${NAMED_CONF_DIRSPEC}/$NAMED_CONF_FILENAME}"
    else
      DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-/etc/$NAMED_CONF_FILENAME}"
    fi
    package_tarname="bind9"
    #if [ "$VERSION_ID" -ge 11 ]; then
    #  systemd_unitname="bind9"  # leverage Debian's unit alias name
    #else
      systemd_unitname="named"
    #fi
    sysvinit_unitname="named"  # used to be 'bind', quit shifting around
    default_chroot_dirspec="/var/lib/named"
    VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_DIRSPEC}/$VAR_SUB_DIRNAME"
    ;;
  fedora|centos|redhat)
    USER_NAME="named"
    GROUP_NAME="named"
    ETC_SUB_DIRNAME="named"
    VAR_SUB_DIRNAME="named"
    LOG_SUB_DIRNAME="named"
    DISTRO_HOME_DIRSPEC="$localstatedir/$USER_NAME"
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-${ETC_SUB_DIRNAME}}"
    VAR_LIB_NAMED_DIRSPEC="/var/${VAR_LIB_NAMED_DIRNAME}"
    NAMED_CONF_DIRSPEC="${ETC_DIRSPEC}/${ETC_SUB_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-${NAMED_CONF_DIRSPEC}/$NAMED_CONF_FILENAME}"
    package_tarname="bind"
    sysvinit_unitname="named"
    systemd_unitname="named"
    default_chroot_dirspec="/var/named/chroot"
    SYSTEMD_NAMED_UNITNAME="named"
    VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_DIRSPEC}/$VAR_SUB_DIRNAME"
    ;;
  arch)
    USER_NAME="named"
    GROUP_NAME="named"
    ETC_SUB_DIRNAME="named"
    VAR_SUB_DIRNAME="named"
    LOG_SUB_DIRNAME="named"
    DISTRO_HOME_DIRSPEC="$localstatedir/$USER_NAME"
    # ArchLinux uses /var/named, not /var/lib/named !?!?!
    VAR_LIB_NAMED_DIRNAME="${VAR_LIB_NAMED_DIRNAME:-${ETC_SUB_DIRNAME}}"
    # I am putting my foot down here, it is back to /var/lib/named
    VAR_LIB_NAMED_DIRSPEC="${VAR_DIRSPEC}/lib/${VAR_LIB_NAMED_DIRNAME}"
    NAMED_CONF_DIRSPEC="${ETC_DIRSPEC}/${ETC_SUB_DIRNAME}"
    DEFAULT_NAMED_CONF_FILESPEC="${NAMED_CONF:-${NAMED_CONF_DIRSPEC}/$NAMED_CONF_FILENAME}"
    DISTRO_HOME_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/$USER_NAME"
    package_tarname="bind"   # extra/bind
    sysvinit_unitname="named"
    systemd_unitname="named"
    default_chroot_dirspec="/var/named/chroot"
    SYSTEMD_NAMED_UNITNAME="named"
    # ArchLinux does not use /var/cache, so dovetail it into /var/lib
    VAR_CACHE_NAMED_DIRSPEC="${VAR_LIB_DIRSPEC}/$VAR_SUB_DIRNAME"
    ;;
esac

log_dir="/var/log/$LOG_SUB_DIRNAME"


if [ -n "$ETC_SUB_DIRNAME" ]; then
  extended_sysconfdir="${sysconfdir}/${ETC_SUB_DIRNAME}"
else
  extended_sysconfdir="${sysconfdir}"
fi
ETC_NAMED_DIRSPEC="$extended_sysconfdir"
SYSTEMD_NAMED_UNITNAME="$systemd_unitname"


#  ARGH!  Another weird maintainer quirk!
case $ID in
  arch)
    RNDC_CONF_DIRSPEC="${ETC_DIRSPEC}"
    NAMED_CONF_FILESPEC="${ETC_DIRSPEC}/${NAMED_CONF_FILENAME}"
    ;;
  *)
    RNDC_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
    NAMED_CONF_FILESPEC="${NAMED_CONF_DIRSPEC}/${NAMED_CONF_FILENAME}"
    ;;
esac

RNDC_KEY_DIRSPEC="${ETC_NAMED_DIRSPEC}/keys"
RNDC_CONF_FILESPEC="${RNDC_CONF_DIRSPEC}/$RNDC_CONF_FILENAME"
RNDC_KEY_FILESPEC="${RNDC_KEY_DIRSPEC}/$RNDC_KEY_FILENAME"
VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_DIRSPEC}/$VAR_SUB_DIRNAME"

SYSTEMD_NAMED_SERVICE="${SYSTEMD_NAMED_UNITNAME}.$SYSTEMD_SERVICE_FILETYPE"
SYSTEMD_NAMED_INSTANCE_SERVICE="${SYSTEMD_NAMED_UNITNAME}@.$SYSTEMD_SERVICE_FILETYPE"

INSTANCE_ETC_NAMED_DIRSPEC="${extended_sysconfdir}"
INSTANCE_NAMED_CONF_FILESPEC="${NAMED_CONF_DIRSPEC}${INSTANCE_SUBDIRPATH}/${INSTANCE_NAMED_CONF_FILENAME}"

INSTANCE_VAR_LIB_NAMED_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
INSTANCE_VAR_LIB_NAMED_PRIMARIES_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
INSTANCE_VAR_LIB_NAMED_SECONDARIES_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
INSTANCE_VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_NAMED_DIRSPEC}"
INSTANCE_LOG_DIRSPEC="/var/log/${LOG_SUB_DIRNAME}"
INSTANCE_RNDC_CONF_DIRSPEC="$RNDC_CONF_DIRSPEC"
INSTANCE_RNDC_KEY_DIRSPEC="${ETC_NAMED_DIRSPEC}/keys"

INSTANCE_RNDC_CONF_FILESPEC="${RNDC_CONF_DIRSPEC}/$RNDC_CONF_FILENAME"
INSTANCE_RNDC_KEY_FILESPEC="$RNDC_KEY_FILESPEC"
INSTANCE_SYSTEMD_NAMED_SERVICE="${SYSTEMD_NAMED_UNITNAME}.$SYSTEMD_SERVICE_FILETYPE"

if [ -n "$INSTANCE" ]; then
  INSTANCE_ETC_NAMED_DIRSPEC="${extended_sysconfdir}/${INSTANCE}"
  INSTANCE_VAR_LIB_NAMED_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/$INSTANCE"
  INSTANCE_VAR_CACHE_NAMED_DIRSPEC="${VAR_CACHE_NAMED_DIRSPEC}/$INSTANCE"
  INSTANCE_LOG_DIRSPEC="/var/log/$LOG_SUB_DIRNAME/$INSTANCE"
  INSTANCE_RNDC_CONF_DIRSPEC="${RNDC_CONF_DIRSPEC}"
  INSTANCE_RNDC_KEY_DIRSPEC="${INSTANCE_RNDC_CONF_DIRSPEC}/keys"

  INSTANCE_RNDC_CONF_FILESPEC="${INSTANCE_RNDC_CONF_DIRSPEC}/$RNDC_CONF_FILENAME"
  INSTANCE_RNDC_KEY_FILESPEC="${INSTANCE_RNDC_KEY_DIRSPEC}/$RNDC_KEY_FILENAME"

  INSTANCE_SYSTEMD_NAMED_SERVICE="${SYSTEMD_NAMED_UNITNAME}@${INSTANCE}.$SYSTEMD_SERVICE_FILETYPE"
fi



if [ -z "$NAMED_SHELL_FILESPEC" ]; then
  NAMED_SHELL_FILESPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $7}')"
fi

# Data?  It's where statistics, memstatistics, dump, and secdata go into
DEFAULT_DATA_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/data"

# $HOME is always treated separately from Zone DB; Only Fedora merges them
#
# named.conf 'directory' statement is not the same as named $HOME directory.
# daemon's current working directory is not the same as ('directory' statement)
# named $HOME directory is not the same as named daemon current working dir.
# These three above things are ... three ... separate ... groups of files.
#
# Unmerging would make it easier for 'named' group to be doled out to
# administrators' supplemental group ID list (much to Fedora's detriments)
# and enable restricting these administrators to just updates of DNS zones.
#
if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep $USER_NAME /etc/passwd | awk -F: '{print $6}')"
fi

# Furthermore, Zone DB directory is now being split into many subdirectories
#  by their zone type (i.e., primary/secondary/hint/mirror/redirect/stub)
#
# Redhat/Fedora already uses 'slaves' zone type for a subdirectory 
# (but that could change to 'secondaries')
DEFAULT_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}"
# shellcheck disable=SC2054
DEFAULT_ZONE_DB_DIRNAME_A=("primaries", "secondaries", "hints", "mirrors", "redirects", "stubs", "masters", "slaves")
# shellcheck disable=SC2054
DEFAULT_ZONE_DB_DIRNAME_ALT_A=("primary", "secondary", "hint", "mirror", "redirect", "stub")

# DNSSEC-related & managed-keys/trust-anchors
DEFAULT_DYNAMIC_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/dynamic"

# WHY WOULD WE WANT /var[/lib]/named/keys?  We have /etc/named/keys
# Perhaps it refers to a statically-defined rndc, XFER, AXFR, and DDNS keys 
# that go into /etc/named/keys
# whereas the dynamically-created DNSSEC go into /var[/lib]/named/keys.

DEFAULT_CONF_KEYS_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/keys"
DEFAULT_KEYS_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"


# Use the 'which -a' which follows $PATH to pick up all 'named' binaries
# choose the first one or choose the ones in SysV/systemd?
# (or let the end-user choose it?)
# Make the SysV/systemd-selected ones the default, then let user choose it
# if there are more than one
named_bins_a=()
# shellcheck disable=SC2207
named_bins_a=($(which -a named | awk '{print $1}'))

# If there is more than one, use first one as the user-default
if [ ${#named_bins_a[@]} -ge 4 ]; then

  # Quick and see if systemctl cat named.service can clue us to which binary
  systemd_named_bin="$(systemctl cat "${systemd_unitname}.service" | grep "ExecStart="|awk -F= '{print $2}' | awk '{print $1}')"
  retsts=$?
  if [ $retsts -eq 0 ] && [ -n "$systemd_named_bin" ]; then
    default_named_bin="$systemd_named_bin"
    echo "Choosing systemd-default: $systemd_named_bin"
  else
    default_named_bin="${named_bins_a[0]}"
    echo "Choosing first 'which' listing: ${named_bins_a[0]}"
  fi
  while true ; do
    i=1
    echo "Found the following 'named' binaries:"
    for o in "${named_bins_a[@]}"; do
      echo "  $i) $o"
      ((i++))
    done
    read -rp "The index to which 'named' binary to use? [$default_named_bin]: "
    if [ -z "$REPLY" ]; then
      named_bin="${default_named_bin}"
      break;
    fi
    if [[ "$REPLY" =~ ^-?[0-9]+$ ]]; then
      if [ "$REPLY" -le "${#named_bins_a[@]}" ]; then
        ((REPLY--))
        echo "$REPLY= $REPLY"
        named_bin="${named_bins_a[REPLY]}"
        break;
      fi
    else
      named_bin="$REPLY"
      break;
    fi
  done
  # echo "'named' selected: ${named_bin}"
else
  named_bin="${named_bins_a[0]}"
  # echo "Only one 'named' found: $(echo ${named_bins_a[*]} | xargs)"
fi
# echo "Using 'named' binary in: $named_bin"


# Now ensure that we use the same tools as  this daemon
named_sbin_dirspec="$(dirname "$named_bin")"
tool_dirspec="$(dirname "$named_sbin_dirspec")"

NAMED_SBIN_FILESPEC="${named_sbin_dirspec}/named"
NAMED_RNDC_SBIN_FILESPEC="${named_sbin_dirspec}/rndc"
named_checkconf_filespec="${named_sbin_dirspec}/named-checkconf"
named_checkzone_filespec="${named_sbin_dirspec}/named-checkzone"
named_compilezone_filespec="${named_sbin_dirspec}/named-compilezone"
named_journalprint_filespec="${named_sbin_dirspec}/named-journalprint"

named_bin_dirspec="${tool_dirspec}/bin"
named_rrchecker_filespec="${named_bin_dirspec}/named-rrchecker"

# What to do with named.conf?
#   Influencers are:
#    - INSTANCE, takes precedence over all
#    - user CLI argument
#    - named binary compiled-in default

# Check for user-supplied named.conf
# use 'named -V' to get default named.conf to use as a default
# scan /etc/named/*.conf for any
# Prompt for named.conf

if [ -z "$INSTANCE" ] && [ -z "$1" ]; then
  # DEFAULT_NAMED_CONF_FILESPEC="/etc/named.conf"  # TODO: temporary
  SYSTEMD_NAMED_CONF="$(systemctl cat "${systemd_unitname}.service"|grep -E "Environment\s*=\s*NAMEDCONF\s*="|awk -F= '{print $3}')"
  if [ -n "$SYSTEMD_NAMED_CONF" ]; then
    echo "systemd ${systemd_unitname}.service unit uses this config file: $SYSTEMD_NAMED_CONF"
  else
    # echo "No named.conf found in 'systemctl cat ${systemd_unitname}.service'"
    # Execute 'named -V' to get 'named configuration' default setting
    SBIN_NAMED_CONF_FILESPEC="$("$named_bin" -V|grep 'named configuration:'|awk '{print $3}')"
    # Might be an older 'named -V' with no output
    if [ -z "$SBIN_NAMED_CONF_FILESPEC" ]; then
      echo "Older 'named' binary offered no named.conf default dirpath;"
      NAMED_CONF_FILESPEC="$DEFAULT_NAMED_CONF_FILESPEC"
      echo "Using ISC default named.conf: $DEFAULT_NAMED_CONF_FILESPEC"
    else
      # echo "Binary 'named' has a built-in config default: $SBIN_NAMED_CONF_FILESPEC"
      NAMED_CONF_FILESPEC="$SBIN_NAMED_CONF_FILESPEC"
    fi
  fi
else
  if [ -n "$1" ]; then
    echo "User-defined named.conf: $1"
    NAMED_CONF_FILESPEC="$1"
  fi
  if [ -n "$INSTANCE" ]; then
    echo "Instance-defined named.conf: $INSTANCE_NAMED_CONF_FILESPEC"
  fi
fi

unset named_conf

INIT_DEFAULT_DIRSPEC="/etc/default"
BIND_INIT_DEFAULT_FILENAME="${sysvinit_unitname}"
INIT_DEFAULT_FILESPEC="$INIT_DEFAULT_DIRSPEC/$BIND_INIT_DEFAULT_FILENAME"

CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"
DYNAMIC_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/dynamic"
KEYS_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/keys"
DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"
PID_DIRSPEC="${rundir}/${systemd_unitname}"

INSTANCE_PID_DIRSPEC="$PID_DIRSPEC"
INSTANCE_NAMED_HOME_DIRSPEC="$NAMED_HOME_DIRSPEC"
INSTANCE_INIT_DEFAULT_FILENAME="${sysvinit_unitname}"
INSTANCE_CONF_KEYS_DIRSPEC="${extended_sysconfdir}/keys"
INSTANCE_KEYS_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/keys"
INSTANCE_DYNAMIC_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/dynamic"
INSTANCE_DB_PRIMARIES_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/primaries"
INSTANCE_DB_SECONDARIES_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/secondaries"
INSTANCE_DATA_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/data"
INSTANCE_RNDC_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
if [ -n "$INSTANCE" ]; then
  INSTANCE_PID_DIRSPEC="${PID_DIRSPEC}${INSTANCE_SUBDIRPATH}"
  INSTANCE_NAMED_HOME_DIRSPEC="${NAMED_HOME_DIRSPEC}${INSTANCE_SUBDIRPATH}"
  INSTANCE_INIT_DEFAULT_FILENAME="${sysvinit_unitname}-$INSTANCE"
  INSTANCE_RNDC_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}${INSTANCE_SUBDIRPATH}"

  INSTANCE_CONF_KEYS_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/keys"
  INSTANCE_KEYS_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"
  INSTANCE_DYNAMIC_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/dynamic"
  INSTANCE_DB_PRIMARIES_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/primaries"
  INSTANCE_DB_SECONDARIES_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/secondaries"
  INSTANCE_DATA_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/data"
fi
INSTANCE_INIT_DEFAULT_FILESPEC="$INIT_DEFAULT_DIRSPEC/$INSTANCE_INIT_DEFAULT_FILENAME"
INSTANCE_PID_FILESPEC="${INSTANCE_PID_DIRSPEC}/named.pid"

# /var/lib/bind[/instance]/dynamic
# clause: 'options' 
# statement: 'managed-keys-directory' 
MANAGED_KEYS_DIRSPEC="${INSTANCE_DYNAMIC_DIRSPEC}"
# clause: 'zone'
# statement: 'key-directory'
ZONE_KEYS_DIRSPEC="${INSTANCE_KEYS_DB_DIRSPEC}"

# /var/cache/bind[/instance]
# all definable within named.conf
JOURNAL_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
JOURNAL_FILENAME="${JOURNAL_DIRSPEC}/myzone.jnl"  # zone 'journal' directive
# clause: 'options' 
# statement: 'dump-file'
DUMP_CACHE_FILENAME="named_dump.db"  # compiled-in default
DUMP_CACHE_DIRSPEC="$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"  # compiled-in default to $HOME/$CWD
DUMP_CACHE_FILESPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}/$DUMP_CACHE_FILENAME"

# named.conf 'options' 'session-keyfile'
# default 'session-keyfile' directory path is compiled-in to $CWD 
#   default directory path is typically /etc/passwd:$HOME
SESSION_KEYFILE_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
# default 'session-keyfile' filename is compiled-in to 'session.key'
SESSION_KEYFILE_FILENAME="${SESSION_KEYFILE_DIRSPEC}/session.key" #  'session-keyfile'

# include files
ACL_NAMED_CONF_FILENAME="acls-named.conf"
CONTROLS_NAMED_CONF_FILENAME="controls-named.conf"
OPTIONS_NAMED_CONF_FILENAME="options-named.conf"
OPTIONS_EXT_NAMED_CONF_FILENAME="options-extensions-named.conf"
OPTIONS_BASTION_NAMED_CONF_FILENAME="options-bastions-named.conf"
OPTIONS_LISTEN_ON_NAMED_CONF_FILENAME="options-listen-on-named.conf"
KEY_NAMED_CONF_FILENAME="keys-named.conf"
LOGGING_NAMED_CONF_FILENAME="logging-named.conf"
MANAGED_KEYS_NAMED_CONF_FILENAME="managed-keys-named.conf"
PRIMARY_NAMED_CONF_FILENAME="primaries-named.conf"
SERVER_NAMED_CONF_FILENAME="servers-named.conf"
STATS_NAMED_CONF_FILENAME="statistics-named.conf"
TRUST_ANCHORS_NAMED_CONF_FILENAME="trust-anchors-named.conf"
VIEW_NAMED_CONF_FILENAME="views-named.conf"
ZONE_NAMED_CONF_FILENAME="zones-named.conf"


INSTANCE_ACL_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${ACL_NAMED_CONF_FILENAME}"
INSTANCE_CONTROLS_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${CONTROLS_NAMED_CONF_FILENAME}"
INSTANCE_OPTIONS_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${OPTIONS_NAMED_CONF_FILENAME}"
INSTANCE_OPTIONS_EXT_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${OPTIONS_EXT_NAMED_CONF_FILENAME}"
INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${OPTIONS_BASTION_NAMED_CONF_FILENAME}"
INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${OPTIONS_LISTEN_ON_NAMED_CONF_FILENAME}"
INSTANCE_KEY_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${KEY_NAMED_CONF_FILENAME}"
INSTANCE_LOGGING_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${LOGGING_NAMED_CONF_FILENAME}"
INSTANCE_MANAGED_KEYS_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${MANAGED_KEYS_NAMED_CONF_FILENAME}"
INSTANCE_PRIMARY_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${PRIMARY_NAMED_CONF_FILENAME}"
INSTANCE_SERVER_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${SERVER_NAMED_CONF_FILENAME}"
INSTANCE_STATS_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/${STATS_NAMED_CONF_FILENAME}"
INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$TRUST_ANCHORS_NAMED_CONF_FILENAME"
INSTANCE_VIEW_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$VIEW_NAMED_CONF_FILENAME"
INSTANCE_ZONE_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$ZONE_NAMED_CONF_FILENAME"

# ACLs Match List (AML) names defined through 'acl' clauses of named.conf
#
# Legend:
#   PUBLIC/PRIVATE = WAN/LAN, Internet/HomeLAN
#   EXTERNAL/INTERNAL = used only within the same bastion host
#   OUTWARD/INWARD = used to reference OUTWARD the physical wire (or vmnet)
#                    and INWARD via within in-host communication (loopback)
#

# control_rndc_interior used for relocation of RNDC control connections
# typically 127.0.0.130 (or something)
CONTROL_RNDC_INTERIOR_AML="aml_rndc_control_channel"

# AML netdev interfaces 
# ('localhost' is a named builtin AML)
# common external red network IP address(es)
PUBLIC_OUTWARD_AML="aml_public_border_ip_addrs"  # plural only in multi-homed

# PUBLIC bastion (an instance of named) has outward/inward netdevs.

# used only in multi-named bastion setup
PUBLIC_INWARD_AML="aml_bastion_public_interior_ip_addr"

# INWARD netdev (loopback) is used between PUBLIC and PRIVATE bastions
BASTION_PRIVATE_PUBLIC_AML="aml_bastion_public_private_interior_ip_addr"

# used only in multi-named bastion setup
PRIVATE_INWARD_AML="aml_bastion_private_interior_ip_addr"

# PRIVATE bastion (an instance of named) has outward/inward netdevs.

# common private green network IP address(es)
PRIVATE_OUTWARD_AML="aml_private_border_ip_addrs"

# nameservers, various

# public secondary/slave nameserver(s) AML
PUBLIC_PRIMARY_NS_AML="aml_trusted_downstream_secondary_nameservers"

# public primary/master nameserver AML (used only in bastion setup)
PUBLIC_PRIMARY_NS_AML="aml_trusted_downstream_primary_nameserver"

# private primary/master nameserver AML (used only in bastion setup)
PRIVATE_PRIMARY_NS_AML="aml_trusted_homelan_primary_nameserver"


function create_header()
{
  FILESPEC=$1
  owner=$2
  perms=$3
  title=$4
  filename="$(basename "$FILESPEC")"
  filepath="$(dirname "$FILESPEC")"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC ..."
  cat << CH_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: $title
# Generator: $(basename "$0")
# Created on: $(date)

CH_EOF
  flex_chown "$owner" "$FILESPEC"
  flex_chmod "$perms" "$FILESPEC"
}

