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

sysconfdir="/etc"
localstatedir="/"

DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
DEFAULT_DROPIN_CONF_FILENAME="zzz-remote-chronyc-all-denied.conf"


CHRONY_CONF_DIRPATH="$sysconfdir/chrony"
CHRONY_CONFD_DIRPATH="$CHRONY_CONF_DIRPATH/conf.d"
CHRONY_SOURCESD_DIRPATH="$CHRONY_CONF_DIRPATH/sources.d"

CHRONY_CONF_FILESPEC="$CHRONY_CONF_DIRPATH/$DEFAULT_CHRONY_CONF_FILENAME"
DROPIN_CONF_FILESPEC="$CHRONY_CONFD_DIRPATH/$DEFAULT_DROPIN_CONF_FILENAME"

# A file in $CHRONY_DHCP_DIRPATH is written by
# the dhclient-exit-hooks.d/chrony script and read by
# the chrony.conf, its 'sourcedir' config item or
# its Debian's dynamic '/run/chrony-dhcp'
CHRONY_DHCP_DIRPATH="$(realpath -m "$localstatedir/run/chrony-dhcp")"

SRC_SUFFIX="sources"

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
    CHRONY_GROUP="$(id -g -n "$CHRONY_USER")"
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
# Find the Chrony config file.
if [ ! -f "$CHRONY_CONF_FILESPEC" ]; then
  echo "Ummm, Chrony is missing the $CHRONY_CONF_FILESPEC file."
  exit 9
fi

# check if /etc/chrony/conf.d exist, if not, create them
if [ ! -d "$CHRONY_CONFD_DIRPATH" ]; then
  echo "Creating $CHRONY_CONFD_DIRPATH..."
  echo sudo mkdir "$CHRONY_CONFD_DIRPATH"
  sudo mkdir "$CHRONY_CONFD_DIRPATH"
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_CONFD_DIRPATH"
sudo chmod 0750 "$CHRONY_CONFD_DIRPATH" # drop this to 0750 if ntp group-privilege is given to end-users.

if [ ! -d "$CHRONY_SOURCESD_DIRPATH" ]; then
  echo "Creating $CHRONY_SOURCESD_DIRPATH..."
  sudo mkdir "$CHRONY_SOURCESD_DIRPATH"
fi
sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_SOURCESD_DIRPATH"
sudo chmod 0750 "$CHRONY_SOURCESD_DIRPATH"

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
if [ -d "${CHRONY_DHCP_DIRPATH}" ]; then
  CHRONY_DHCP_LIST="$(/usr/bin/ls -A -- "$CHRONY_DHCP_DIRPATH/" |xargs -n1 | sort -u | xargs)"
  CHRONY_DHCP_COUNT="$(echo "$CHRONY_DHCP_LIST" | wc -l)"
  if [ "$CHRONY_DHCP_COUNT" -ge 1 ]; then
    for f in "${CHRONY_DHCP_DIRPATH}"/*; do
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
  echo "   ${CHRONY_DHCP_DIRPATH} file from that /etc/dhcp/dhclient-exit.d/chrony "
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

touch "${DROPIN_CONF_FILESPEC}"
chmod 0640 "${DROPIN_CONF_FILESPEC}"
chown "${CHRONY_USER}:root" "${DROPIN_CONF_FILESPEC}"
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
