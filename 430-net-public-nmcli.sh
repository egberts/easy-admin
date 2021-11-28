#!/bin/bash
#
# File: 431-net-nmcli-public.sh
# Title: Create a public LAN interface
#

echo "Under NetworkManager, create ethernet interface for public LAN"
echo "May prompt for sudo password..."
echo ""

nm_filelist="$(find /etc/NetworkManager/ -maxdepth 0 -type f)"

if [ -z "$nm_filelist" ]; then
  echo "/etc/NetworkManager looks largely empty."
  echo "Looks like NetworkManager is not configured at all; Aborted."
  exit 3
fi
exit 0
read -rp "Type in 'continue' then press ENTER to continue: " 
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 3
fi

# Find the binary
which_nmcli_bin="$(which nmcli)"
if [ -z "$which_nmcli_bin" ]; then
  echo "Unable to find 'nmcli' binary; aborted."
  exit 9
fi

interface_name="enp5s0"
avail_interfaces="$(ip -4 -o addr | awk '{print $2}' | xargs)"
echo "Available interfaces: $avail_interfaces"
exit 0

# Hide any error messages during deletion
sudo nmcli c delete $interface_name >/dev/null 2>&1

sudo nmcli c add type ethernet ifname $interface_name con-name "$interface_name"
sudo nmcli c mod $interface_name ipv4.method auto

sudo nmcli c down $interface_name
sudo nmcli c up $interface_name

sudo systemctl try-restart NetworkManager.service
echo ""
echo "Done."
