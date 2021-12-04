#!/bin/bash -x


sudo apt install shorewall shorewall-doc ipset

# Disable a bunch of things
#
FIREWALL_PACKAGES_LIST="ufw iptables iptables6 firehol ferm firewalld nftables"
for this_pkg in $FIREWALL_PACKAGES_LIST; do
  systemctl stop "$this_pkg"
  systemctl disable "$this_pkg"
done

# Install basic gateway setup
cd shorewall || exit $?
./install-shorewall.sh

echo "Now you can edit the firewall rules in /etc/shorewall/rules file."
echo "Then do:"
echo "  shorewall check"
echo "  shorewall start"
echo "  shorewall stop"
echo "or execute:"
echo "  shorewall clear"
echo "to go back to non-firewall state".
