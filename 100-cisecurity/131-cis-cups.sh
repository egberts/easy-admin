#!/bin/bash
# File: 130-cis-avahi.sh
# Title: Disable AVAHI daemon
#

echo "Checking if cups-daemon is running..."
AVAHI_ENABLED="$(systemctl is-enabled cups.service)"
if [ "$AVAHI_ENABLED" != 'disabled' ]; then
  echo "Disabling and stopping cups.service..."
  systemctl --now disable cups.service
fi
echo "Done."
