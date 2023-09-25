#!/bin/bash
# File: 131-cis-cups.sh
# Title: Disable CUPS daemon
#
echo "Disabling CUPS printer service ..."
echo
echo -n "Enter in 'continue' then ENTER to continue: "
read -r ANYTHING
if [ "$ANYTHING" != "continue" ]; then
  echo "Aborted."
  exit 1
fi

echo "Checking if cups-daemon is running..."
cups_active="$(systemctl is-active cups.service 2>/dev/null)"
RETSTS=$?
if [ $RETSTS -eq 0 ] && [ "$cups_active" != 'inactive' ]; then
  echo "Disabling and stopping cups.service..."
  systemctl --now stop cups.service
  systemctl --now disable cups.service
  echo ""
else
  echo "No CUPS daemon found"
  echo ""
fi
echo "Done."
