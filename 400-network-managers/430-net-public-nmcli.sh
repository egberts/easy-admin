#!/bin/bash
#
# File: 431-net-nmcli-public.sh
# Title: Create a public LAN interface
#

echo "Under NetworkManager, create dynamic IPv4 interface for public LAN"
echo "May prompt for sudo password..."
echo ""

nm_filelist="$(find /etc/NetworkManager/ -maxdepth 1 -type f)"

if [ -z "$nm_filelist" ]; then
  echo "/etc/NetworkManager looks largely empty."
  echo "Looks like NetworkManager is not configured at all; Aborted."
  exit 3
fi

# Find the binary
which_nmcli_bin="$(which nmcli)"
if [ -z "$which_nmcli_bin" ]; then
  echo "Unable to find 'nmcli' binary; aborted."
  exit 9
fi

# Make a list of available interfaces
avail_interfaces="$(ip -4 -o addr show | awk '{print $2}' | grep -v 'lo' | xargs)"
echo "Available interfaces: $avail_interfaces"
PS3="Enter in digit: "
select interface_name in $avail_interfaces; do
  break
done
echo "REPLY: $REPLY"
echo "interface_name: $interface_name"

# Check if interface is already up and dynamic, then abort
intf_status="$(ip -4 -o addr show dev "$interface_name" | awk '{print $9}')"
if [ "$intf_status" == "dynamic" ]; then
  echo "Interface $interface_name is already set up; aborted."
  exit 3
fi

read -rp "Type in 'continue' then press ENTER to continue: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 3
fi

# Hide any error messages during deletion
sudo nmcli c delete "$interface_name" >/dev/null 2>&1

sudo nmcli c add type ethernet ifname "$interface_name" con-name "$interface_name"
sudo nmcli c mod "$interface_name" ipv4.method auto

sudo nmcli c down "$interface_name"
sudo nmcli c up "$interface_name"

sudo systemctl try-restart NetworkManager.service
echo ""
echo "Done."
