#!/bin/bash
#
#  We split this up into other bash files
#    - chrony.conf
#    - pool/server/peer
#    - admin
#    - MitM protection
#
#   Goal is to make this chrony.conf alone
#   All other works goes into drop-in '/etc/chrony/conf.d'
#     - Moved 'pool' into a drop-in config file
#     - Moved hwclk settings into a drop-inconfig file
#
# Reads: nothing
# Changes: nothing
# Adds:
#    /etc/chrony/chrony.conf
#    /var/lib/chrony/chrony.drift
#
#
# Numerous Debian bugs against chrony 4.0 (all filed by me).
# File: 481-net-ntp-choices.sh
# Title: Help decide which NTP client/server to use
#
#  #995201 - chrony: No clue as to why CLI cannot find UNIX socket
#  #995207 - chrony: Using 'bindacqdevice' directive causes SYSSIG signal
#  #995190 - chrony -p (print config) doesn't show 'sourcedir'
#  #995196 - chrony: 'apt purge chrony' blew away customized configuration
#  #995213 - chrony: Unable to mix chrony and ntp together
#
# Usage:
#    481-net-ntp-choices.sh
#    ANNOTATION=1 481-net-ntp-choices.sh

ANNOTATION=${ANNOTATION:-y}

ARG1_CHRONY_CONF=${1}

BUILDROOT="${BUILDROOT:-build}"
source ./maintainer-ntp-chrony.sh

if [ "${BUILDROOT:0:1}" != '/' ]; then
  mkdir -p "$BUILDROOT"
else
  FILE_SETTING_PERFORM='true'
fi

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-setting-chrony-conf-main.sh"

flex_ckdir "$ETC_DIRSPEC"
flex_ckdir "$extended_sysconfdir"
flex_ckdir "$CHRONY_CONFD_DIRSPEC"
flex_ckdir "$CHRONY_SOURCESD_DIRSPEC"

flex_ckdir "$VAR_DIRSPEC"
flex_ckdir "$VAR_LIB_DIRSPEC"
flex_ckdir "$CHRONY_VAR_LIB_DIRSPEC"

CHRONYD_BIN="$(whereis -b chronyd | awk -F: '{print $2}')"


# Useful directories that autoconf/configure/autoreconf does not offer.

# User supplied chrony.conf variants (offline testing)
if [ -n "$ARG1_CHRONY_CONF" ]; then
  REAL_CONF="$ARG1_CHRONY_CONF"
  CONF_FILENAME="$(basename "$REAL_CONF")"
  CONF_PATHNAME="$(dirname "$REAL_CONF")"
else
  CONF_FILENAME="$DEFAULT_CHRONY_CONF_FILENAME"
  CONF_PATHNAME="$extended_sysconfdir"
fi
CONF_FILESPEC="$CONF_PATHNAME/$CONF_FILENAME"


# USERNAMES_LIST="_ntp ntp chrony"  # new NTP
USERNAMES_LIST="_chrony chrony ntp"  # new Chrony

for this_username in $USERNAMES_LIST; do
  found_in_passwd="$(grep -e ^"${this_username}": /etc/passwd )"
  if [ -n "$found_in_passwd" ]; then
    USERNAME="$(echo "$found_in_passwd" | awk -F: '{print $1}')"
    break;
  fi
done

if [ -z "$USERNAME" ]; then
  echo "List of usernames not found: $USERNAMES_LIST"
  exit 9
fi
echo "Username '$USERNAME' found."
GROUPNAME="$(id -G -n "$USERNAME")"


# Syntax: create_file CONF_FILESPEC [file-permission [owner:group]]
function create_file
{
  flex_touch "$1"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error touching '$1' file; Aborted."
    exit $retsts
  fi
  flex_chmod "$2" "$1"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error changing '$1' file permission to $2; Aborted."
    exit $retsts
  fi
  flex_chown "$3" "$1"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error changing '$1' file ownership to $3; Aborted."
    exit $retsts
  fi
  cat << CREATE_FILE_EOF | tee "${BUILDROOT}$1" >/dev/null
#
# File: $(basename "$1")
# Path: $(dirname "$1")
CREATE_FILE_EOF
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error writing to '$1'; Aborted."
    exit $retsts
  fi
}

function add_file_headers
{
  cat << CREATE_FILE_EOF | tee -a "${BUILDROOT}$CONF_FILESPEC" >/dev/null
# Title: $1
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#
CREATE_FILE_EOF
}

function write_conf
{
  echo "$1" >> "${BUILDROOT}$CONF_FILESPEC"
}

function write_note
{
  if [ "$ANNOTATION" = 'y' ]; then
    echo "$1" >> "${BUILDROOT}$CONF_FILESPEC"
  fi
}

function dump_chrony_conf_current_settings
{
  echo "HAVE_RTC_DEVICE: $HAVE_RTC_DEVICE"
  # echo "CMD_ACL_NEEDED: $CMD_ACL_NEEDED"
  idx=0
  while [ $idx -lt ${#CHRONY_CONF_A[@]} ]; do
    echo "CHRONY_CONF_A[$idx]: ${CHRONY_CONF_A[$idx]}"
    ((idx+=1))
  done
}
function dump_chrony_conf_mitm
{
  idx=0
  while [ $idx -lt ${#CC_MITM_A[@]} ]; do
    echo "CC_MITM_A[$idx]: ${CC_MITM_A[$idx]}"
    ((idx=idx+1))
  done
}
function dump_chrony_conf_hwclk
{
  idx=0
  while [ $idx -lt ${#CC_HWCLK_A[@]} ]; do
    echo "CC_HWCLK_A[$idx]: ${CC_HWCLK_A[$idx]}"
    ((idx=idx+1))
  done
}
function dump_chrony_conf_default_admin
{
  idx=0
  while [ $idx -lt ${#CHRONY_CONF_A[@]} ]; do
    echo "CHRONY_CONF_A[$idx]: ${CHRONY_CONF_A[$idx]}"
    ((idx=idx+1))
  done
}

function dump_settings
{
  dump_chrony_conf_current_settings
  dump_chrony_conf_mitm
  dump_chrony_conf_hwclk
  dump_chrony_conf_default_admin
}

function annotate
{
  if [ "$ANNOTATION" -ne 0 ]; then
    CHRONY_CONF_A+=("")
    CHRONY_CONF_A+=("# $1")
  fi
}


echo "Writing ${BUILDROOT}$CONF_FILESPEC config file..."
create_file "$CONF_FILESPEC" 0640 "${USERNAME}:${GROUPNAME}"
add_file_headers "Configuration file for Chrony NTP daemon"

# DHCP-CHRONY is provided by 'chrony' package
# 'chrony' script is executed by 'dhclient' service as needed
# content of /run/chrony-dhcp subdirectory is written by 'dhclient'
# content of /run/chrony-dhcp subdirectory is read by 'chronyd'
DHCP_EXITHOOKSD_DIRNAME="dhclient-exit-hooks.d"
DHCP_EXITHOOKSD_DIRSPEC="${extended_sysconfdir}/$DHCP_EXITHOOKSD_DIRNAME"
DHCP_CHRONY_SCRIPT="${DHCP_EXITHOOKSD_DIRSPEC}/chrony"
if [ -f "$DHCP_CHRONY_SCRIPT" ]; then
  write_note ""
  write_note "# pool pool.ntp.org goes into a separate sourcedir directory."
  write_note "# Use the time source(s) from DHCP"
  write_conf "sourcedir ${DHCP_CHRONY_PATHNAME}"
fi

write_note ""
write_note "# Use NTP sources found in the /etc/chrony/sources.d subdirectory."
write_conf "sourcedir ${CHRONY_SOURCESD_DIR}"

write_note ""
write_note "# This driftfile directive specify the location of the file that "
write_note "# contains ID/key-pair used for NTP authentication."
write_conf "keyfile ${CHRONY_KEYS_FILESPEC}"

write_note ""
write_note "# This driftfile directive specify the file into which chronyd"
write_note "# will store the rate information"
write_conf "driftfile ${CHRONY_DRIFT_FILESPEC}"

write_note ""
write_note "# Save NTS keys and cookies."
write_conf "ntsdumpdir ${CHRONY_DUMP_DIRPATH}"

write_note ""
write_note "# Log files location."
write_conf "# logdir /var/log/chrony"

write_note ""
write_note "# Stop bad estimates that are upsetting machine clock"
write_conf "maxupdateskew 100.0"

write_note ""
write_note "# This directive enables kernel synchronization (every 11 minutes)"
write_note "# of the real-time clock.  NOTE: This keyword cannot used  along"
write_note "# with the 'rtcfile' directive: choose one."
write_conf "rtcsync"

write_note ""
write_note "# Steps the system clock instead of slewing it if the adjustment is "
write_note "# larger than one second, but only in the first three clock updates"
write_conf "makestep 1 3"

write_note "# Get TAI-UTC offset and leap second from the system TZ database"
write_note "# This directive must be commented out when using time source serving"
write_note "# leap-smeared time."
write_conf "leapsectz 0"

# We can open them ACLs up by subnet/address for the NTP commands as needed.
# This complies with IETF BCP 8? and BCP 63?
write_note "# Set the default access for all NTP commands to 'nobody'"
write_conf "cmddeny all"  # This is the DEFAULT-DENY approach
write_conf ""

echo
echo "Creating empty ${BUILDROOT}$CHRONY_DRIFT_FILESPEC drift file..."
flex_touch "$CHRONY_DRIFT_FILESPEC"
# CIS Security recommended file permission setting
flex_chmod 0600 "$CHRONY_DRIFT_FILESPEC"
flex_chown "$USERNAME":"$GROUPNAME" "$CHRONY_DRIFT_FILESPEC"


# CMD_NET_ACL_NEEDED=0

#

# Verify the configuration files to be correct, syntax-wise.
echo
echo "Checking syntax of ${BUILDROOT}$CONF_FILESPEC config file..."
$CHRONYD_BIN -p -f "${BUILDROOT}$CONF_FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  if [ "$retsts" -eq 1 ]; then
    echo "AppArmor/SELinux is blocking reading of ${BUILDROOT}$CONF_FILESPEC"
    echo "Install the config file into /etc/chrony/ and rerun $0"
    exit 1
  fi
  # Re-run but verbosely
  $CHRONYD_BIN -p -f "${BUILDROOT}$CONF_FILESPEC"
  echo "ERROR: ${BUILDROOT}$CONF_FILESPEC failed syntax check."
  exit 13
fi
echo "${BUILDROOT}$CONF_FILESPEC passes syntax-check"
echo
echo "Done."
exit

# Objective is to 'enable' chrony service
# and only restart or try-restart the service
# It is not intended to start anything
# Just reload any active Chrony daemon
# That's the operator's job.
#
# If it was stopped, it stays stopped
# If it was started, it gets restarted/reloaded
systemctl --quiet is-enabled "$chrony_systemd_unit_name"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Enabling Chrony service..."
  systemctl enable "$chrony_systemd_unit_name"
fi

echo
systemctl --quiet is-active "$chrony_systemd_unit_name"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Trying to reload or restart Chrony service..."
  systemctl try-reload-or-restart "$chrony_systemd_unit_name"
  echo "WARNING: You may have to start it yourself."
  echo "Chrony daemon status: $(systemctl is-active "$chrony_systemd_unit_name")"
  exit $?  # pass-along 'is-active' errcode
else
  echo "Restarting Chrony service..."
  systemctl restart "$chrony_systemd_unit_name"
fi
echo "Chrony daemon status: $(systemctl is-active "$chrony_systemd_unit_name"): Done."
exit $?  # pass-along 'is-active' errcode
