#!/bin/bash -x
#
# File: 421-fw-shorewall-init.sh
# Description:
#   Install firewall to start during bootup
#   right after the first network interface
#   comes up but before the desktop appears
#
#   Part of the hardened security stance

echo "Set up hardened Shorewall (shorewall-init) during boot-up"
echo ""

if [ ! -f /etc/shorewall/shorewall.conf ]; then
  echo "Must install shorewall firstly."
  echo "Execute:"
  echo "  sudo apt install shorewall-init"
  echo "and rerun '$0' command"
  exit 1
fi

# Edit any PRODUCTS= in /etc/default/shorewall-init
# Change to PRODUCTS="shorewall"
shorewall_init_conf="/etc/default/shorewall-init"
sudo sed -i.backup \
    's/^PRODUCTS.*=.*$/PRODUCTS="shorewall"/' \
    "$shorewall_init_conf"
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to modify $shorewall_init_conf file; aborted."
  exit 3
fi

systemctl enable shorewall-init.service
systemctl start shorewall-init.service
systemctl try-restart shorewall.service
echo ""

echo "Done."
