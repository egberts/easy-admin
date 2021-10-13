#!/bin/bash -x
#
# File: 421-fw-shorewall-init.sh
# Description:
#   Install firewall to start during bootup
#   right after the first network interface
#   comes up but before the desktop appears
#
#   Part of the hardened security stance

if [ ! -f /etc/shorewall/shorewall.conf ]; then
  echo "Must install shorewall firstly."
  echo "Execute:"
  echo "  sudo apt install shorewall-init"
  echo "and rerun '$0' command"
  exit 1
fi

# sudo apt install shorewall-init ipset

# Edit any PRODUCTS= in /etc/default/shorewall-init
# Change to PRODUCTS="shorewall"
sudo sed -i.backup \
    's/^PRODUCTS.*=.*$/PRODUCTS="shorewall"/' \
    /etc/default/shorewall-init

RETSTS=$?

systemctl enable shorewall-init.service
systemctl start shorewall-init.service
systemctl try-restart shorewall.service

echo "Error: $RETSTS"
