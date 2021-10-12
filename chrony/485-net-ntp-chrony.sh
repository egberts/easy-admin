#!/bin/bash
# File: 485-net-ntp-chrony.sh
# Title: Setup the Chrony timeserver
# Description:
#   - Chrony config file must exist first
#   - Sets up the time server
#     - Installs Chrony package
#     -
#   - Compiles all 'peer/server/pool' entries in sources.d/
#   - Relocates debian pool from main chrony.conf into sources.d/
#
# Shell UID requirement:  Any username
#
# Reads:
#   /etc/chrony/chrony.conf
#   /etc/chrony/conf.d/*
#   /etc/chrony/sources.d is only consulted by 'chronyc reload sources'
#   /run/chrony-dhcp/*
# Changes:
#   /etc/chrony/chrony.conf
# Adds:
#   /etc/chrony/conf.d
#

SYS_CONF_DIR="/etc"
CHRONY_CONF_DIRNAME="$SYS_CONF_DIR/chrony"

FILENAME="chrony.conf"
FILEPATH="$CHRONY_CONF_DIRNAME"

CHRONY_CONFD_DIRNAME="$CHRONY_CONF_DIRNAME/conf.d"

# A file in $DEBIAN_RUN_CHRONY_DHCP is written by
# the dhclient-exit-hooks.d/chrony script and read by
# the chrony.conf, its 'sourcedir' config item or
# its Debian's dynamic '/run/chrony-dhcp'
DEBIAN_RUN_CHRONY_DHCP="/run/chrony-dhcp"

SRC_DIRPATH="/etc/chrony/sources.d"
SRC_SUFFIX="sources"
CONF_FILE="$FILEPATH/$FILENAME"

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
#
# Find the Chrony config file.
if [ ! -f "$CONF_FILE" ]; then
  echo "Ummm, Chrony is missing the $CONF_FILE file."
  exit 9
fi

# Find the correct location to drop the chrony.source file
# that will contain the 'peer', 'server', and 'pool'.
# We are only interested in the 'peer' part.
SOURCEDIR_A=("$(grep sourcedir "$CONF_FILE" | awk '{print $2}')")
if [ -z "${SOURCEDIR_A[*]}" ]; then
  echo "This is an old Chrony setup."
  echo "The configuration keyword 'sourcedir' is missing in $CONF_DIR."
  echo "Aborted."
  exit 9
fi

# check if /etc/chrony/conf.d exist, if not, create them
if [ ! -d "$CHRONY_CONFD_DIRNAME" ]; then
  echo "Creating $CHRONY_CONFD_DIRNAME..."
  sudo mkdir "$CHRONY_CONFD_DIRNAME"
  sudo chown "$CHRONY_USER:$CHRONY_GROUP" "$CHRONY_CONFD_DIRNAME"
  sudo chmod 0750 "$CHRONY_CONFD_DIRNAME" # drop this to 0750 if ntp group-privilege is given to end-users.
fi

# get all config files, including drop-in config files.
FOUNDED_CHRONY_CONFD_DIRNAME_INCLUDES="$(grep -e '^confdir\s' "$CONF_FILE" | awk '{print $2}')"
FOUNDED_SOURCEDIR_INCLUDES="$(grep -e '^sourcedir\s' "$CONF_FILE" | awk '{print $2}')"
MORE_CONF_FILES="$CONF_FILE"
MORE_CONF_FILES="$MORE_CONF_FILES $FOUNDED_CHRONY_CONFD_DIRNAME_INCLUDES"
MORE_CONF_FILES="$MORE_CONF_FILES $FOUNDED_SOURCEDIR_INCLUDES"

# check that all include directories exist, as well
# as adding its wildcard '/*' suffix
CONF_FILES=
for THIS_DIR in $FOUNDED_CHRONY_CONFD_DIRNAME_INCLUDES $FOUNDED_SOURCEDIR_INCLUDES; do
  if [ ! -d "$THIS_DIR" ]; then
    echo "Include directory '$THIS_DIR' is missing"
    echo "Either create that '$THIS_DIR' directory or remove its corresponding "
    echo "'sourcedir $THIS_DIR'/'confdir $THIS_DIR' "
    echo "from the $CONF_FILE file".
    exit 9
  fi
  CONF_FILES="$CONF_FILES $THIS_DIR/* "
done

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

MORE_CONF_FILES="$CONF_FILES"

# Collect all existing 'server', 'peer', and 'pool' from /etc/chrony/chrony.conf
# Skip the commented-out lines
# shellcheck disable=SC2207
NTP_ADDR_POOL_A=($(grep -E '^(\s*(~#)*\s*pool\s+)' "$MORE_CONF_FILES"| awk '{print $2}'))
# shellcheck disable=SC2207
NTP_ADDR_SERVER_A=($(grep -E '^(\s*(~#)*\s*server\s+)' "$MORE_CONF_FILES"| awk '{print $2}'))
# shellcheck disable=SC2207
NTP_ADDR_PEER_A=($(grep -E '^(\s*(~#)*\s*peer\s+)' "$MORE_CONF_FILES"| awk '{print $2}'))

echo "Pool: ${NTP_ADDR_POOL_A[*]}"
echo "Server: ${NTP_ADDR_SERVER_A[*]}"
echo "Peer: ${NTP_ADDR_PEER_A[*]}"

function relocate_keyword
{
  KEYWORD=$1     # no-space text string
  NTP_ADDR_A=$2  # array
  NEW_FILE="$SRC_DIRPATH/debian-stock-${KEYWORD}.${SRC_SUFFIX}"    # filespec
  if [ -n "${NTP_ADDR_A[*]}" ]; then
    # create a new source file
    cat << NEW_CHRONY_D_FILE | sudo tee "${NEW_FILE}" >/dev/null
#
# File: $(basename "$NEW_FILE")
# Path: $(dirname "$NEW_FILE")
# Title: Chrony $KEYWORD source configuration file
# Creator: $(realpath "$0")
# Date: $(date)
#
NEW_CHRONY_D_FILE

    # Write a keyword entry for each address in the array
    for this_addr in ${NTP_ADDR_A[*]}; do
      echo "${KEYWORD}  ${this_addr}" | sudo tee -a "${NEW_FILE}" >/dev/null
    done
    echo "" | sudo tee -a "${NEW_FILE}" >/dev/null
  else
    if [ -f "$NEW_FILE" ]; then
      echo "This ${NEW_FILE} is lingering around, might have to delete them"
      echo "Could have already been de-Debianized."
    fi
  fi

  # Remove that entry from the main /etc/chrony/chrony.conf config file.
 sudo sed -r -i.backup \
     "s/^(\s*(~#)*\s*${KEYWORD}\s+.*)$/# stock Debian NTP ${KEYWORD} keyword removed/" "${CONF_FILE}"

}

# if Debian, Comment out all pools from stock Debian config
if [ -d "$SRC_DIRPATH" ]; then

  # and relocate those settings into a /etc/chrony/sources.d/ subdir
  relocate_keyword 'pool' "${NTP_ADDR_POOL_A[*]}"
  relocate_keyword 'peer' "${NTP_ADDR_PEER_A[*]}"
  relocate_keyword 'server' "${NTP_ADDR_SERVER_A[*]}"
else
  echo "This is not the latest Debian chrony, for there are no 'chrony.d' subdir."
  echo "Aborted."
fi

# DISABLE crappy systemd-timesyncd
stop_disable_sysd ntp
stop_disable_sysd time-daemon
stop_disable_sysd systemd-timesyncd.service

################################################################
# Drop-in config files
################################################################

# go check that various DHCP clients have been updating /run/chrony-dhcp file.
if [ -d "${DEBIAN_RUN_CHRONY_DHCP}" ]; then
  CHRONY_DHCP_LIST="$(/usr/bin/ls -1 -- $DEBIAN_RUN_CHRONY_DHCP/)"
  CHRONY_DHCP_COUNT="$(echo "$CHRONY_DHCP_LIST" | wc -l)"
  if [ "$CHRONY_DHCP_COUNT" -ge 1 ]; then
    for f in "${DEBIAN_RUN_CHRONY_DHCP}"/*; do
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
  echo "   ${DEBIAN_RUN_CHRONY_DHCP} file from that /etc/dhcp/dhclient-exit.d/chrony "
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

FILENAME="zzz-remote-chronyc-all-denied.conf"
FILEPATH="$CHRONY_CONFD_DIRNAME"
NEW_FILE="$FILEPATH/$FILENAME"
cat << DROPIN_NTP_CLIENT_ALLOWED_CONF | sudo tee "${NEW_FILE}" >/dev/null
#
# File: $(basename "$NEW_FILE")
# Path: $(dirname "$NEW_FILE")
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
