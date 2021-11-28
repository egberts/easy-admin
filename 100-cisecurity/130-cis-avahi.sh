#!/bin/bash
# File: 130-cis-avahi.sh
# Title: Disable AVAHI daemon
#

echo "Checking if avahi-daemon is running..."
avahi_active="$(systemctl is-active avahi-daemon 2>/dev/null )"
if [ $? -eq 0 ] && [ "$avahi_active" != 'inactive' ]; then
  echo "Disabling and stopping avahi-daemon..."
  systemctl stop avahi-daemon.service avahi-daemon.socket
  systemctl --now disable avahi-daemon.service avahi-daemon.socket
else
  echo "No avahi found"
fi
echo ""
echo "Done."
