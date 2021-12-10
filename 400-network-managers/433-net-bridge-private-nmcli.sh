#!/bin/bash
#
# File: 430-net-bridge-nmcli-private.sh
# Title: Create a private LAN bridge
#
# References:
#  man nm-settings(5)
#  man nm-settings-nmcli(5)
#
PRIVATE_LAN_IP="172.28.140.1"
DNS_SERVER_IP="172.28.130.1"
DNS_DOMAIN_NAME_SEARCH="leo"

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
sudo nmcli c delete bridge-slave-enp3s0 >/dev/null 2>&1
sudo nmcli c delete enp3s0 >/dev/null 2>&1

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
sudo nmcli c add type bridge-slave ifname enp3s0 master br0 con-name 'enp3s0'
# nmcli_con_modify enp3s0 ethernet.mac-address-blacklist ""
# nmcli_con_modify enp3s0 connection.lldp 0
# nmcli_con_modify enp3s0 connection.llmnr "no"
# nmcli_con_modify enp3s0 connection.read-only "1" # does not work

# go back to bridge master and connect the slaves
# nmcli_con_modify br0 connection.autoconnect-slaves 1
sleep 0.5

sudo nmcli connection down enp3s0
sudo nmcli connection down br0
sudo nmcli connection up br0   # hopefully that will bring up all slave ports
sudo nmcli connection up enp3s0  # might be redundant

# sudo systemctl try-restart NetworkManager.service
