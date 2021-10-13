#!/bin/bash
#
# File: 431-net-nmcli-public.sh
# Title: Create a public LAN interface
#

echo "Creating an ethernet interface for public LAN (sudo pwd prompt)..."

# Hide any error messages during deletion
sudo nmcli c delete enp5s0 >/dev/null 2>&1

sudo nmcli c add type ethernet ifname enp5s0 con-name "enp5s0"
sudo nmcli c mod enp5s0 ipv4.method auto

sudo nmcli c down enp5s0
sudo nmcli c up enp5s0

sudo systemctl try-restart NetworkManager.service
