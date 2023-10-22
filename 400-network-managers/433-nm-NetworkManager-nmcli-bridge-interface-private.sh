#!/bin/bash
#
# File: 433-nm-NetworkManager-nmcli-bridge-interface-private.sh
# Title: Create a private LAN bridge
#
# References:
#  man nm-settings(5)
#  man nm-settings-nmcli(5)
#
echo "Under NetworkManager, create private LAN bridge interface"
echo

if [ "$USER" != 'root' ]; then
  echo "May prompt for sudo password..."
  echo
fi
echo "May mess with your network settings; do not do this remotely"
read -rp "Enter in 'continue' to ... continue: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 3
fi

# get gateway netdev
GW_NETDEV="$(ip -o route show  | grep default | awk '{print $5}')"
BRIDGE_NETDEV="$(ip -o -d link show | grep " bridge " | awk '{print $2}')"
# get list of all netdevs
if [ -n "$BRIDGE_NETDEV" ]; then
  BRIDGE_NETDEV="${BRIDGE_NETDEV:0:-1}"
  ALL_NETDEVS="$(ip -o -4 addr show | grep -v "host lo" | grep -v "$GW_NETDEV" | grep -v "$BRIDGE_NETDEV" | awk '{print $2}' | xargs)"
fi

if [ -z "$ALL_NETDEVS" ]; then
  echo "No non-public netdev available left; aborted."
  exit 1
fi

read -rp "Enter in private LAN IP address: "
PRIVATE_LAN_IP="$REPLY"
read -rp "Enter in private DNS nameserver address: " -ei"$PRIVATE_LAN_IP"
DNS_SERVER_IP="$REPLY"
read -rp "Enter in domain name search suffix: "
DNS_DOMAIN_NAME_SEARCH="$REPLY"
echo
echo "List of netdev: $ALL_NETDEVS"
read -rp "Enter in private LAN netdev device: " -ei"$ALL_NETDEVS"
PRIVATE_LAN_NETDEV="$REPLY"

function nmcli_con_modify
{
  sudo nmcli c modify "$1" "$2" "$3"
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "Error modifying connection: Error $RETSTS"
    echo "command used: sudo nmcli c modify $1 $2 $3"
    exit $RETSTS
  fi
}

# Assumes that public IP interface is configured, up and running.

echo "Creating a bridge for private LAN (sudo pwd prompt)..."

# Hide any error message during deletion
sudo nmcli c delete bridge-br0 >/dev/null 2>&1
sudo nmcli c delete br0 >/dev/null 2>&1
sudo nmcli c delete "bridge-slave-${PRIVATE_LAN_NETDEV}" >/dev/null 2>&1
sudo nmcli c delete "${PRIVATE_LAN_NETDEV}" >/dev/null 2>&1

# We want a connection named 'br0' (id=br0)
sudo nmcli c add ifname br0 type bridge con-name br0

nmcli_con_modify br0 connection.autoconnect "true"
nmcli_con_modify br0 connection.autoconnect-retries "0"  # try indefinitely
nmcli_con_modify br0 bridge.stp false
nmcli_con_modify br0 ipv4.addresses "${PRIVATE_LAN_IP}/22"
#nmcli_con_modify br0 ipv4.gateway ""   # cannot provide empty string
nmcli_con_modify br0 ipv4.dns "$DNS_SERVER_IP"
nmcli_con_modify br0 ipv4.dns-search "$DNS_DOMAIN_NAME_SEARCH"
# Never make this interface a default route
nmcli_con_modify br0 ipv4.never-default "true"
# nmcli_con_modify br0 ipv4.ignore-auto-dns "false"
# nmcli_con_modify br0 ipv4.ignore-auto-routes "false"
nmcli_con_modify br0 ipv4.method manual

nmcli_con_modify br0 ipv6.addr-gen-mode "stable-privacy"
nmcli_con_modify br0 ipv6.never-default "true"
# ipv4.method must be the last setting
nmcli_con_modify br0 ipv6.method disabled


# Set up all bridge slaves
sudo nmcli c add type bridge-slave ifname "${PRIVATE_LAN_NETDEV}" master br0 con-name "${PRIVATE_LAN_NETDEV}"
nmcli_con_modify "${PRIVATE_LAN_NETDEV}" ethernet.mac-address-blacklist ""
nmcli_con_modify "${PRIVATE_LAN_NETDEV}" connection.lldp 0
nmcli_con_modify "${PRIVATE_LAN_NETDEV}" connection.llmnr "no"
nmcli_con_modify "${PRIVATE_LAN_NETDEV}" connection.read-only "1" # does not work

# go back to bridge master and connect the slaves
nmcli_con_modify br0 connection.autoconnect-slaves 1
sleep 0.5

sudo nmcli connection down "${PRIVATE_LAN_NETDEV}"
sudo nmcli connection down br0
sudo nmcli connection up br0   # hopefully that will bring up all slave ports
sudo nmcli connection up "${PRIVATE_LAN_NETDEV}"  # might be redundant"

# sudo systemctl try-restart NetworkManager.service
