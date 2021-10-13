#!/bin/bash
# File: 130-cis-avahi.sh
# Title: Disable AVAHI daemon
#

echo "Checking if avahi-daemon is running..."
AVAHI_ENABLED="$(systemctl is-enabled avahi-daemon)"
if [ "$AVAHI_ENABLED" != 'disabled' ]; then
  echo "Disabling and stopping avahi-daemon..."
  systemctl --now disable avahi-daemon.service avahi-daemon.socket
fi
echo "Done."
