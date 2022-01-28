#!/bin/bash
#
# File: 438-nm-NetworkManager-nmcli-bridge-closenet.sh
# Title: Create a virtual machine LAN bridge
#
PRIVATE_LAN_IP="172.28.200.1"
DNS_SERVER_IP="172.28.140.1"
DNS_DOMAIN_NAME_SEARCH="leo"

echo "Creating a subnet for virtual machine LAN (sudo pwd prompt)..."

# Hide any error message during connection deletion
sudo nmcli c delete bridge-vmbr0 >/dev/null 2>&1
sudo nmcli c delete vmbr0 >/dev/null 2>&1


# Dont use 'con-name', let NM auto-format the name
sudo nmcli c add type bridge ifname vmbr0
sudo nmcli c mod bridge-vmbr0 bridge.stp no
sudo nmcli c mod bridge-vmbr0 ipv4.addresses "${PRIVATE_LAN_IP}/22"
sudo nmcli c mod bridge-vmbr0 ipv4.gateway ""
sudo nmcli c mod bridge-vmbr0 ipv4.dns $DNS_SERVER_IP
sudo nmcli c mod bridge-vmbr0 ipv4.dns-search $DNS_DOMAIN_NAME_SEARCH
# ipv4.method must be the last setting
sudo nmcli c mod bridge-vmbr0 ipv4.method manual

sudo nmcli c down bridge-vmbr0
sleep 0.5
sudo nmcli c up bridge-vmbr0
