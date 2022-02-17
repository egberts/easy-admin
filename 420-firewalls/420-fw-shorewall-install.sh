#!/bin/bash -x


source ./maintainer-firewall-shorewall.sh

if [ 0 -ne 0 ]; then
case $ID in
  debian|devuan)
    apt install shorewall shorewall-doc ipsetS
    ;;
  arch)
    pacman -S  shorewall shorewall-doc ipsetS
    pacman -S --needed base-devel
    pacman -S pahole  # used by Linux kernel 'make bzImage'

    pacman -S nftables
    pacman -S libnftnl
    pacman -S libnfnetlink
    pacman -S libnetfilter_conntrack
    pacman -S iptables-nft
    ;;
esac
fi


# Disable a bunch of things
#
FIREWALL_PACKAGES_LIST="ufw iptables iptables6 firehol ferm firewalld nftables"
for this_pkg in $FIREWALL_PACKAGES_LIST; do
  systemctl stop "$this_pkg"
  systemctl disable "$this_pkg"
done

CHOICES_LIST_A=()
echo "1) If you have a desktop-type system with a single network interface"
echo "2) If you have a desktop-type system with a single network "
echo "       interface, pkg shorewall6"
echo "3) If you have a router with two network interfaces"
echo "4) If you have a router with three network interfaces"
read -rp "Enter in network configuration ID: " -ei1

case $REPLY in
  # If you have a desktop-type system with a single network interface
  1)
    cp /usr/share/doc/shorewall/Samples/one-interface/* /etc/shorewall/
    ;;
  # If you have a desktop-type system with a single network
  #    interface, pkg shorewall6
  2)
    cp /usr/share/doc/shorewall6/Samples6/one-interface/* /etc/shorewall6/
    ;;
  # If you have a router with two network interfaces
  3)
    cp /usr/share/doc/shorewall/Samples/two-interfaces/* /etc/shorewall/
    ;;
  # If you have a router with three network interfaces
  4)
    cp /usr/share/doc/shorewall/Samples/three-interfaces/* /etc/shorewall/
    ;;
esac

shorewall check
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Shorewall syntax check failed."
  exit $retsts
fi

# Install basic gateway setup
# cd shorewall || exit $?
# ./install-shorewall.sh

echo "Now you can edit the firewall rules in /etc/shorewall/rules file."
echo "Then do:"
echo "  shorewall check"
echo "  shorewall start"
echo "  shorewall stop"
echo "or execute:"
echo "  shorewall clear"
echo "to go back to non-firewall state".
