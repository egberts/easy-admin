#!/bin/bash -x
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

SUDO_BIN=
ANNOTATION=${ANNOTATION:-y}

# shellcheck disable=SC2034
package_tarname="chrony"

BUILDROOT="/"

ARG1_CHRONY_CONF=${1}

# configure/autogen/autoreconf -------------------------------------
# most configurable variables used here are found in
# configure/autogen/autoconf but are capitalized for readablity here
#
# maintainer default (Chrony)
#   prefix=/usr/local
#   libexecdir=$prefix/libexec
#   datarootdir=$prefix/share
#   sysconfdir=$prefix/etc
#   localstatedir=$prefix/var
#   libdir=$exec_prefix/lib
#   bindir=$exec_prefix/bin
#   sbindir=$exec_prefix/sbin
#   datadir=$datarootdir

# Debian maintainer however applies this:
#   libdir=/usr/lib
#   SYSROOT=/
#   libexecdir=/usr/lib

# All we are really concern about are:
#   prefix/prefix
#   sysconfdir/sysconfdir
#   localstatedir/localstatedir

DISTRO_MANUF="$(lsb_release -i|awk -F: '{print $2}'|xargs)"
if [ "$DISTRO_MANUF" == "Debian" ]; then
  DEFAULT_PREFIX=""  # '/'
  DEFAULT_EXEC_PREFIX="/usr"  # revert  back to default
  DEFAULT_LOCALSTATEDIR=""  # '/'
  EXTENDED_SYSCONFDIR_DIRNAME="chrony"
elif [ "$DISTRO_MANUF" == "Redhat" ]; then
  DEFAULT_PREFIX=""  # '/'
  DEFAULT_EXEC_PREFIX="/usr"  # revert  back to default
  DEFAULT_LOCALSTATEDIR="/var"
  EXTENDED_SYSCONFDIR_DIRNAME="chrony"  # change this often
else
  DEFAULT_PREFIX="/usr"
  DEFAULT_LOCALSTATEDIR="/var"  # or /usr/local/var
  EXTENDED_SYSCONFDIR_DIRNAME="$package_tarname"   # ie., 'bind' vs 'named'
fi
prefix="${prefix:-$DEFAULT_PREFIX}"
sysconfdir="${sysconfdir:-$prefix/etc}"
exec_prefix="${exec_prefix:-${DEFAULT_EXEC_PREFIX:-${prefix}}}"
libdir="${libdir:-$exec_prefix/lib}"
libexecdir=${libexecdir:-$exec_prefix/libexec}
localstatedir="${localstatedir:-"${DEFAULT_LOCALSTATEDIR}"}"
datarootdir=${datarootdir:-$prefix/share}
# sharedstatedir=${prefix:-${prefix}/com}
# bindir="$exec_prefix/bin"
### runstatedir="$(realpath -m "$localstatedir/run")"
runstatedir="$localstatedir/run"
# sbindir="$exec_prefix/sbin"

# bind9 maintainer tweaks
expanded_sysconfdir="${sysconfdir}/${EXTENDED_SYSCONFDIR_DIRNAME}"

# Useful directories that autoconf/configure/autoreconf does not offer.
VARDIR="$prefix/var"
STATEDIR=${STATEDIR:-${VARDIR}/lib/${package_tarname}}
# LOG_DIR="$VARDIR/log"  # /var/log

# application specific
DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
DEFAULT_CHRONY_DRIFT_FILENAME="chrony.drift"
CHRONY_DRIFT_FILENAME="$DEFAULT_CHRONY_DRIFT_FILENAME"

# CHRONY_ETC_DIR="$expanded_sysconfdir/chrony"
# CHRONY_RUN_DIR="$runstatedir/$package_tarname"  # /run/chrony
CHRONY_VAR_LIB_DIR="$VARDIR/lib/$package_tarname"
CHRONY_DUMP_DIRPATH="$CHRONY_VAR_LIB_DIR"

# CHRONY_CONFD_DIR="$expanded_sysconfdir/conf.d"  # /etc/chrony/conf.d
CHRONY_SOURCESD_DIR="$expanded_sysconfdir/sources.d"  # /etc/chrony/sources.d
# CHRONY_LOG_DIR="$LOG_DIR/chrony"  # /var/log/chrony
CHRONY_DRIFT_FILESPEC="$CHRONY_VAR_LIB_DIR/$CHRONY_DRIFT_FILENAME"
CHRONY_KEYS_FILESPEC="$expanded_sysconfdir/chrony.keys"

# User supplied chrony.conf variants (offline testing)
if [ -n "$ARG1_CHRONY_CONF" ]; then
  REAL_CONF="$ARG1_CHRONY_CONF"
  CONF_FILENAME="$(basename "$REAL_CONF")"
  CONF_PATHNAME="$(dirname "$REAL_CONF")"
else
  CONF_FILENAME="$DEFAULT_CHRONY_CONF_FILENAME"
  CONF_PATHNAME="$expanded_sysconfdir"
fi
CONF_FILESPEC="$(realpath -m "${BUILDROOT}$CONF_PATHNAME/$CONF_FILENAME")"

# /run/chrony-dhcp/* is populated by /etc/dhcp/dhclient-exit-hooks.d/chrony
# script and executed by 'dhclient' daemon.
DHCP_CHRONY_PATHNAME="$runstatedir/chrony-dhcp/"

# CHRONY_LOG_DIR="$VAR_LOG_DIR/chrony"
# CHRONY_RUN_DIR="$VAR_RUN_DIR/chrony"

# CHRONY_CONFD_DIR="$CHRONY_ETC_DIR/conf.d"  # deferred to other scripts

# minimum default settings of /etc/chrony/chrony.conf

if [ ! -e "$CONF_FILESPEC" ]; then
  echo "File $CONF_FILESPEC does not exist; Aborted."
  exit 9
elif [ ! -f "$CONF_FILESPEC" ]; then
  echo "File $CONF_FILESPEC is not a file; Aborted."
  exit 9
elif [ ! -r "$CONF_FILESPEC" ]; then
  echo "File $CONF_FILESPEC is not readable; Aborted."
  exit 9
else
  read -rp "File $CONF_FILESPEC exists; over-write it? [N/y]: " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != "y" ]; then
    echo "Aborted."
    exit 1
  fi
fi
if [ ! -w "$CONF_FILESPEC" ]; then
  read -rp "File $CONF_FILESPEC is not writeable; use 'sudo' command? [N/y]: " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != "y" ]; then
    echo "Aborted."
    exit 1
  fi
  echo "Continuing on with over-writing $CONF_FILESPEC..."
  SUDO_BIN=sudo
fi

# Syntax: create_file CONF_FILESPEC [file-permission [owner:group]]
function create_file
{
  $SUDO_BIN touch "$1"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error touching '$1' file; Aborted."
    exit $retsts
  fi
  $SUDO_BIN chmod "$2" "$1"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error changing '$1' file permission to $2; Aborted."
    exit $retsts
  fi
  $SUDO_BIN chown "$3" "$1"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error changing '$1' file ownership to $3; Aborted."
    exit $retsts
  fi
  cat << CREATE_FILE_EOF | $SUDO_BIN tee "$1" >/dev/null
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
  cat << CREATE_FILE_EOF | $SUDO_BIN tee -a "$CONF_FILESPEC" >/dev/null
# Title: $1
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#
CREATE_FILE_EOF
}

function write_conf
{
  $SUDO_BIN echo "$1" >> "$CONF_FILESPEC"
}

function write_note
{
  if [ "$ANNOTATION" = 'y' ]; then
    $SUDO_BIN echo "$1" >> "$CONF_FILESPEC"
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

echo "Writing $CONF_FILESPEC config file..."
create_file "$CONF_FILESPEC" 0640 "${CHRONY_USERNAME}:${CHRONY_GROUPNAME}"
add_file_headers "Configuration file for Chrony NTP daemon"

# DHCP-CHRONY is provided by 'chrony' package
# 'chrony' script is executed by 'dhclient' service as needed
# content of /run/chrony-dhcp subdirectory is written by 'dhclient'
# content of /run/chrony-dhcp subdirectory is read by 'chronyd'
DHCP_CHRONY_SCRIPT="/etc/dhcp/dhclient-exit-hooks.d/chrony"
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

echo ""
echo "Creating empty $CHRONY_DRIFT_FILESPEC drift file..."
$SUDO_BIN touch "$CHRONY_DRIFT_FILESPEC"
# CIS Security recommended file permission setting
$SUDO_BIN chmod 0600 "$CHRONY_DRIFT_FILESPEC"
$SUDO_BIN chown "$USERNAME":"$GROUPNAME" "$CHRONY_DRIFT_FILESPEC"


# CMD_NET_ACL_NEEDED=0

#

# Verify the configuration files to be correct, syntax-wise.
echo ""
echo "Checking syntax of $CONF_FILESPEC config file..."
chronyd -p -f "$CONF_FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  # Re-run but verbosely
  chronyd -p -f "$CONF_FILESPEC"
  echo "ERROR: $CONF_FILESPEC failed syntax check."
  exit 13
fi
echo "$CONF_FILESPEC passes syntax-check"

# Objective is to 'enable' chrony service
# and only restart or try-restart the service
# It is not intended to start anything
# Just reload any active Chrony daemon
# That's the operator's job.
#
# If it was stopped, it stays stopped
# If it was started, it gets restarted/reloaded
systemctl --quiet is-enabled chrony.service
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Enabling Chrony service..."
  systemctl enable chrony.service
fi

echo ""
systemctl --quiet is-active chrony.service
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Trying to reload or restart Chrony service..."
  systemctl try-reload-or-restart chrony.service
  echo "WARNING: You may have to start it yourself."
  echo "Chrony daemon status: $(systemctl is-active chrony.service)"
  exit $?  # pass-along 'is-active' errcode
else
  echo "Restarting Chrony service..."
  systemctl restart chrony.service
fi
echo "Chrony daemon status: $(systemctl is-active chrony.service): Done."
exit $?  # pass-along 'is-active' errcode
