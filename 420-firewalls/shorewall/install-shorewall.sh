#!/bin/bash

# Freshly installed shorewall only has 3 files in /etc/shorewall

SMALL_SHOREWALL_ETC=`ls -1 /etc/shorewall | wc -l`

if [ $SMALL_SHOREWALL_ETC -gt 10 ]; then
  echo "Oh, it's fully configured"
  exit 1
else
  echo "It's probably freshly installed"
fi

# Clear the way
sudo mkdir /etc/shorewall/.orig
sudo mv /etc/shorewall/* /etc/shorewall/.orig

# Copy everything
sudo cp -rpf etc/shorewall/* /etc/shorewall/

# DO it again
sudo systemctl disable iptables.service
sudo systemctl disable iptables6.service
