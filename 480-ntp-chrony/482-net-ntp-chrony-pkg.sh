#!/bin/bash
# File: 485-net-ntp-chrony.sh
# Title: Basic Setup of the Chrony timeserver
# Description:
#   - Chrony config file must exist first
#   - Sets up the time server
#     - Installs Chrony package
#
# Shell UID requirement:  Any username
#
# Reads:
#   /etc/chrony/chrony.conf
#   /etc/chrony/conf.d/*
#   /etc/chrony/sources.d/* is only consulted by 'chronyc reload sources'
#   /run/chrony-dhcp/*
# Changes:
#   /etc/chrony/conf.d
#   /etc/chrony/chrony.conf
#   /etc/chrony/sources.d
# Adds:
#   /etc/chrony/conf.d/*
#

BUILDROOT="${BUILDROOT:-build}"
source ./maintainer-ntp-chrony.sh

if [ "${BUILDROOT:0:1}" != '/' ]; then
  mkdir -p "$BUILDROOT"
else
  FILE_SETTING_PERFORM='true'
fi

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-setting-chrony-debian-pkg.sh"

DEFAULT_DROPIN_CONF_FILENAME="zzz-remote-chronyc-all-denied.conf"
DROPIN_CONF_FILESPEC="$CHRONY_CONFD_DIRSPEC/$DEFAULT_DROPIN_CONF_FILENAME"


CHRONY_CONF_DIRPATH="$sysconfdir/chrony"
CHRONY_CONFD_DIRPATH="$CHRONY_CONF_DIRPATH/conf.d"
CHRONY_SOURCESD_DIRPATH="$CHRONY_CONF_DIRPATH/sources.d"
CHRONY_RUN_DIRPATH="$localstatedir/run/chrony"

CHRONY_CONF_FILESPEC="$CHRONY_CONF_DIRPATH/$DEFAULT_CHRONY_CONF_FILENAME"
DROPIN_CONF_FILESPEC="$CHRONY_CONFD_DIRPATH/$DEFAULT_DROPIN_CONF_FILENAME"

# A file in $CHRONY_DHCP_DIRPATH is written by
# the dhclient-exit-hooks.d/chrony script and read by
# the chrony.conf, its 'sourcedir' config item or
# its Debian's dynamic '/run/chrony-dhcp'
CHRONY_DHCP_DIRPATH="$(realpath -m "$localstatedir/run/chrony-dhcp")"

####################################################################
# Defensive coding between NTP clients
####################################################################

# USERNAMES_LIST="_named bind9 bind named"  # new ISC Bind9
# USERNAMES_LIST="_ntp ntp chrony"  # new NTP
USERNAMES_LIST="_chrony chrony ntp"  # new Chrony

for this_username in $USERNAMES_LIST; do
  found_in_passwd="$(grep -e ^"${this_username}": /etc/passwd )"
  if [ -n "$found_in_passwd" ]; then
    CHRONY_USER="$(echo "$found_in_passwd" | awk -F: '{print $1}')"
    CHRONY_GROUP="$(id -G -n "$CHRONY_USER")"
    break;
  fi
done

if [ -z "$CHRONY_USER" ]; then
  echo "List of usernames not found: $USERNAMES_LIST"
  exit 9
fi
echo "Username '$CHRONY_USER' found."


##############################################################
# Chrony infrastructure
##############################################################
#
# Find the Chrony config directory.
if [ ! -d "$extended_sysconfdir" ]; then
  echo "Ummm, Chrony is missing the $extended_sysconfdir directory."
  exit 9
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$extended_sysconfdir"
sudo chmod 0750 "$extended_sysconfdir"

# Find the Chrony config file.
if [ ! -f "$CHRONY_CONF_FILESPEC" ]; then
  echo "Ummm, Chrony is missing the $CHRONY_CONF_FILESPEC file."
  exit 9
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_CONF_FILESPEC"
sudo chmod 0640 "$CHRONY_CONF_FILESPEC"

# check if /etc/chrony/conf.d exist, if not, create them
if [ ! -d "$CHRONY_CONFD_DIRSPEC" ]; then
  echo "Creating $CHRONY_CONFD_DIRSPEC..."
  echo sudo mkdir "$CHRONY_CONFD_DIRSPEC"
  sudo mkdir "$CHRONY_CONFD_DIRSPEC"
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_CONFD_DIRSPEC"
sudo chmod 0750 "$CHRONY_CONFD_DIRSPEC" # drop this to 0750 if ntp group-privilege is given to end-users.

if [ ! -d "$CHRONY_SOURCESD_DIRSPEC" ]; then
  echo "Creating $CHRONY_SOURCESD_DIRSPEC..."
  sudo mkdir "$CHRONY_SOURCESD_DIRSPEC"
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_SOURCESD_DIRSPEC"
sudo chmod 0750 "$CHRONY_SOURCESD_DIRSPEC"

if [ ! -d "$CHRONY_RUN_DIRSPEC" ]; then
  echo "Package install should have created this $CHRONY_RUN_DIRSPEC; aborted."
  edit 9
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_RUN_DIRSPEC"
sudo chmod 0750 "$CHRONY_RUN_DIRSPEC"

function stop_disable_sysd()
{
  ACTIVE="$(systemctl is-active "${1}" >/dev/null 2>&1)"
  if [ "${ACTIVE}" == "active" ]; then
    sudo systemctl stop "${1}"
  fi
  ENABLED="$(systemctl is-enabled "${1}" >/dev/null 2>&1)"
  if [ "${ENABLED}" == "enabled" ]; then
    sudo systemctl disable "$1"
  fi
}

# DISABLE crappy systemd-timesyncd
stop_disable_sysd ntp
stop_disable_sysd time-daemon
stop_disable_sysd systemd-timesyncd.service

################################################################
# Drop-in config files
################################################################

# go check that various DHCP clients have been updating /run/chrony-dhcp file.
if [ -d "${CHRONY_DHCP_DIRSPEC}" ]; then
  CHRONY_DHCP_LIST="$(/usr/bin/ls -A -- "$CHRONY_DHCP_DIRSPEC/" |xargs -n1 | sort -u | xargs)"
  CHRONY_DHCP_COUNT="$(echo "$CHRONY_DHCP_LIST" | wc -l)"
  if [ "$CHRONY_DHCP_COUNT" -ge 1 ]; then
    for f in "${CHRONY_DHCP_DIRSPEC}"/*; do
      # shellcheck disable=SC2002
      IP_ADDR=$(cat "$f" | awk '{print $2}')
      NTP_SERVERS+="$NTP_SERVERS $IP_ADDR"
      if [ -n "${IP_ADDR}" ]; then
        echo "DHCP client is actively updating Chrony NTP with:"
        echo "  ${NTP_SERVERS[*]}"
      fi
    done
  fi
else
  echo "WARNING: DHCP 'dhclient' client is not updating the "
  echo "   ${CHRONY_DHCP_DIRSPEC} file from that /etc/dhcp/dhclient-exit.d/chrony "
  echo "   DHCP client dispatcher-script file."
fi
echo "Configured NTP addr peer:   ${NTP_ADDR_PEER_A[*]}"
echo "Configured NTP addr pool:   ${NTP_ADDR_POOL_A[*]}"
echo "Configured NTP addr server: ${NTP_ADDR_SERVER_A[*]}"
echo "DHCP-supplied NTP address:  : $NTP_SERVERS"


# sudo systemctl restart chrony.service
sudo chronyc reload sources
sleep 5
sudo chronyc sources
RETSTS=$?
if [ "$RETSTS" -ne 0 ]; then
  echo "Command 'chronyc source' has error code $RETSTS"
  echo "Executing 'systemctl status chrony.service'..."
  systemctl status chrony.service
  exit $RETSTS
fi

if [ "$CHRONY_DHCP_COUNT" -ge 1 ]; then
  echo "Cool. We detected your DHCP server is obtaining NTP address(es)."
fi


# Permission zone

# Always set 'deny all' and 'cmddeny all'

# Do a 'cmddeny all' to restrict 'chronyc' to just
# the UNIX socket (and not its localhost nor anyone else outside the host)

# Because it is a lexiographical-order drop-in config subdir,
# we seek the last file entry there (using 'zzz')

sudo touch "${DROPIN_CONF_FILESPEC}"
sudo chmod 0640 "${DROPIN_CONF_FILESPEC}"
sudo chown "${CHRONY_USER}:${CHRONY_GROUP}" "${DROPIN_CONF_FILESPEC}"
cat << DROPIN_NTP_CLIENT_ALLOWED_CONF | sudo tee "${DROPIN_CONF_FILESPEC}" >/dev/null
#
# File: $(basename "$DROPIN_CONF_FILESPEC")
# Path: $(dirname "$DROPIN_CONF_FILESPEC")
# Title: Deny all remote 'chronyc' access to this host
# Description:
#   Restrict the access to Chrony CLI to 'cmddeny all' (or nobody).
#
#   NOTE: time-serving are controlled by 'deny'/'allow' directives.
#   NOTE: command-CLI are controlled by 'cmddeny'/'cmdallow' directives.
#
# Creator: $(realpath "$0")
# Date: $(date)
#
cmddeny all

DROPIN_NTP_CLIENT_ALLOWED_CONF

