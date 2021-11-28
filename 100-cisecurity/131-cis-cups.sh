#!/bin/bash
# File: 130-cis-avahi.sh
# Title: Disable AVAHI daemon
#

echo "Checking if cups-daemon is running..."
cups_active="$(systemctl is-active cups.service 2>/dev/null)"
if [ $? -eq 0 ] && [ "$cups_active" != 'inactive' ]; then
  echo "Disabling and stopping cups.service..."
  systemctl --now stop cups.service
  systemctl --now disable cups.service
  echo ""
else
  echo "No CUPS daemon found"
  echo ""
fi
echo "Done."
