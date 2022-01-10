#!/bin/bash
# File: 503-dns-no-dnsmasq.sh
# Title: Ensure that DNSMASQ is NOT running

source ./maintainer-dns-isc.sh

echo "Checking for existance of /etc/dnsmasq.conf file..."
if [ -f /etc/dnsmasq.conf ]; then
  echo "Disable the dnsmasq; those are used by tiny embedded systems"
  echo "Execute:"
  case $ID in
    debian)
      echo "  apt purge dnsmasq-base"
      ;;
    fedora)
      echo "  rpm -q --configfiles dnsmasq"
      echo "  dnf remove dnsmasq"
      ;;
  esac
  echo "  userdel dnsmasq"
  echo "  groupdel dnsmasq"
  echo "Re-run '$0' when done."
  exit 1
fi
echo "Examining dnsmasq.service file..."
systemctl cat dnsmasq.service >/dev/null 2>&1
RETSTS=$?
if [ $RETSTS -gt 0 ]; then
  echo "dnsmasq is not installed on this system."
else
  echo "Stopping dnsmasq.service..."
  sudo systemctl stop dnsmasq.service
  echo "Disabling dnsmasq.service..."
  sudo systemctl disable dnsmasq.service
fi
echo "Done."
exit 0
