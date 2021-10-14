#!/bin/bash
# File:/489-net-ntp-chrony-file-perms.sh
# Title: Check file ownership and file permissions for Chrony package
# Description:
#   - Checks for file permissions
#
# Usage Syntax:
#   ./489-net-ntp-chrony-file-perms.sh   <config-filespec>
#     whereas
#       - config-filespec is the Chrony config file. Default is
#       /etc/chrony/chrony.conf (for Debain), or
#       /etc/chrony.conf (other distro)
#
# Use Cases:
#  - QA and Hardening Specialists needs to review these settings
#    without using 'root' privilege.
#
# Prerequisites:
#   findutils (xargs)
#   lsb-release (lsb_release)
#   gawk (awk)
#   sudo (sudo)
#   coreutils (ls, realpath, stat)

# shellcheck disable=SC2034
package_tarname="chrony"

BUILDROOT="/"
SUDO_BIN=

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

# Across multiple distros, all we mostly are really concern about are:
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
sharedstatedir=${prefix:-${prefix}/com}
bindir="$exec_prefix/bin"
### runstatedir="$(realpath -m "$localstatedir/run")"
runstatedir="$localstatedir/run"
sbindir="$exec_prefix/sbin"

# bind9 maintainer tweaks
expanded_sysconfdir="${sysconfdir}/${EXTENDED_SYSCONFDIR_DIRNAME}"
CHRONY_CONF_DIR="$expanded_sysconfdir"

# Useful directories that autoconf/configure/autoreconf does not offer.
VARDIR="$prefix/var"
STATEDIR=${STATEDIR:-${VARDIR}/lib/${package_tarname}}
LOG_DIR="$VARDIR/log"  # /var/log

DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
DEFAULT_CHRONY_DRIFT_FILENAME="chrony.drift"

CHRONY_RUN_DIR="$runstatedir/$package_tarname"  # /run/chrony
CHRONY_VAR_LIB_DIR="$VARDIR/lib/$package_tarname"

CHRONY_CONFD_DIR="$expanded_sysconfdir/conf.d"  # /etc/chrony/conf.d
CHRONY_SOURCESD_DIR="$expanded_sysconfdir/sources.d"  # /etc/chrony/sources.d
CHRONY_LOG_DIR="$LOG_DIR/chrony"  # /var/log/chrony
CHRONY_DRIFT_FILESPEC="$CHRONY_VAR_LIB_DIR/$DEFAULT_CHRONY_DRIFT_FILENAME"
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


TOTAL_FILES=0
TOTAL_PERM_ERRORS=0
TOTAL_FILE_ERRORS=0
TOTAL_FILE_MISSINGS=0

function file_perm_check
{
  local filespec expected_fmod expected_groupname expected_username varnam
  varnam=$1
  # shellcheck disable=SC2086
  eval filespec=\$$1
  $SUDO_BIN ls -1 "$filespec" >/dev/null 2>&1
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "$filespec ($varnam): is missing."
    ((TOTAL_FILE_MISSINGS+=1))
  else
    local err_per_file msg_a this_fmod this_username this_groupname
    expected_fmod=$2
    expected_username=$3
    expected_groupname=$4
    err_per_file=0
    msg_a=()
    this_fmod="$($SUDO_BIN stat -c%a "$filespec")"
    this_username="$($SUDO_BIN stat -c%U "$filespec")"
    this_groupname="$($SUDO_BIN stat -c%G "$filespec")"
    if [ "$expected_fmod" != "$this_fmod" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_fmod' file permission"
      ((TOTAL_PERM_ERRORS+=1))
      ((err_per_file+=1))
    fi
    if [ "$expected_username" != "$this_username" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_username' username"
      ((TOTAL_PERM_ERRORS+=1))
      ((err_per_file+=1))
    fi
    if [ "$expected_groupname" != "$this_groupname" ]; then
      msg_a[$err_per_file]="...Expecting '$expected_groupname' group name"
      ((TOTAL_PERM_ERRORS+=1))
      ((err_per_file+=1))
    fi
    echo -n "$this_fmod $this_username:$this_groupname ($varnam) $filespec: "
    if [ "$err_per_file" -eq 0 ]; then
      echo " ok."
    else
      echo " ERROR"  # new line
      idx=0
      while [ "$idx" -lt "$err_per_file" ]; do
        echo "${msg_a[$idx]}"
        ((idx+=1))
      done
      ((TOTAL_FILE_ERRORS+=1))
    fi
    unset err_per_file
  fi
  unset filespec expected_fmod expected_groupname expected_username varnam
  ((TOTAL_FILES+=1))
}

echo "Checking file permissions..."
read -rp "CIS Security setup or Debian defaults? (C/d): " -eiC
REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
echo ""

# check for DHCP-CHRONY co-relationship for activeness.
#  'nmcli devices',
#     scan for 'connected'
#        'nmcli connection show <device-name>
#          scan for any 'DHCP.*' settings

# For now, we ALWAYS check this but put out a warning otherwise

if [ "$REPLY" != "c" ]; then
  echo "Debian default settings..."
  file_perm_check CONF_FILESPEC "644" "_chrony" "_chrony"
  file_perm_check CHRONY_CONF_DIR "755" "root" "root"
  file_perm_check CHRONY_CONFD_DIR "755" "root" "root"
  file_perm_check CHRONY_SOURCESD_DIR "755" "root" "root"
  file_perm_check CHRONY_RUN_DIR "750" "_chrony" "_chrony"
  file_perm_check CHRONY_KEYS_FILESPEC "640" "root" "root"
  file_perm_check CHRONY_DRIFT_FILESPEC "644" "_chrony" "_chrony"

else
  echo "CIS Security settings..."
  file_perm_check CONF_FILESPEC "640" "_chrony" "_chrony"
  file_perm_check CHRONY_CONF_DIR "750" "_chrony" "_chrony"
  file_perm_check CHRONY_CONFD_DIR "750" "_chrony" "_chrony"
  file_perm_check CHRONY_SOURCESD_DIR "750" "_chrony" "_chrony"

  # /var/run/chrony (or /var/chrony) can adjusted for chrony tool restriction
  #   0755 @ /var/run/chrony for anyone can use these chrony tools
  #   0750 @ /var/run/chrony for chrony user/group can use these chrony tools
  file_perm_check CHRONY_RUN_DIR "750" "_chrony" "_chrony"
  file_perm_check CHRONY_KEYS_FILESPEC "600" "_chrony" "_chrony"
  file_perm_check CHRONY_DRIFT_FILESPEC "600" "_chrony" "_chrony"

fi
CONFIG_FILES="$(find "$CHRONY_CONFD_DIR" -name "*.conf" -print)"
SOURCES_FILES="$(find "$CHRONY_SOURCESD_DIR" -name "*.sources" -print)"

# What both Debian and CIS Security did together correctly
# A slow progress toward security
for config_file in $CONFIG_FILES; do
  file_perm_check config_file "640" "_chrony" "_chrony"
done
for source_file in $SOURCES_FILES; do
  file_perm_check source_file "640" "_chrony" "_chrony"
done
file_perm_check CHRONY_VAR_LIB_DIR "750" "_chrony" "_chrony"
file_perm_check CHRONY_LOG_DIR "750" "_chrony" "_chrony"

# The following files do not need to be check as its file permissions
# are determined by what the umask of the parent daemon process was set to.
# Even such file is set to file 0777 permission, the [/var]/run/chrony
# directory file will restrict it to 0750 permission with group-write priv

# [/var]/run/chrony/chrony.sock - No need to check
# [/var]/run/chrony/chrony.pid - No need to check.

TOTAL_ERRORS=TOTAL_FILE_ERRORS
((TOTAL_ERRORS+=TOTAL_FILE_MISSINGS))
echo  ""
echo "Uncounted (controlled by 'dhclient' (isc-dhcp-client.service)"
file_perm_check DHCP_CHRONY_PATHNAME "755" "root" "root"
echo  ""
echo "Total files:             $TOTAL_FILES"
echo "Total errors:            $TOTAL_ERRORS"
echo "    missing files:           $TOTAL_FILE_MISSINGS"
echo "    files with errors:       $TOTAL_FILE_ERRORS"
echo "        permission bit errors:   $TOTAL_PERM_ERRORS"

if [ "$TOTAL_ERRORS" -gt 0 ]; then
  exit 1
fi
exit 0
