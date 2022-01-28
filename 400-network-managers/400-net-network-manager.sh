#!/bin/bash
#
# File: 400-net-network-manager.sh
# Title: Ensure that NetworkManager is up and running
# Description:
#   Turns off systemd-networkd, SysV, and other weird init stuff.

echo "Check this host to ensure that NetworkManager is up and running"
echo 
if [ "$USER" != 'root' ]; then
  echo "Requires 'sudo' only to read OS stuff"
  echo "Press ENTER to continue (sudo prompt may appear)"
  echo "Press Ctrl-C to exit"
  read REPLY
fi

SYSTEMCTL_BIN="$(which systemctl)"
if [ -z "$SYSTEMCTL_BIN" ]; then
  echo "systemd is not installed; exiting ..."
  exit 1
fi
# ENABLED_WORKING="$(sudo systemctl is-enabled networking)"
ENABLED_SYSNETD="$(sudo systemctl is-enabled systemd-networkd)"
# ACTIVE_WORKING="$(sudo systemctl is-active networking)"
ACTIVE_SYSNETD="$(sudo systemctl is-active systemd-networkd)"

if [ "${ENABLED_SYSNETD}" == "enabled" ]; then
  echo "Need to execute:"
  echo "    systemctl disable systemd-networkd.service systemd-networkd.socket"
  exit 3
fi
if [ "${ACTIVE_SYSNETD}" == "active" ]; then
  echo "Need to execute:"
  echo "    systemctl disable systemd-networkd.service systemd-networkd.socket"
  exit 3
fi

NMCLI_WHEREIS="$(whereis nmcli|awk '{print $2}')"
if [ -z "$NMCLI_WHEREIS" ]; then
  echo "NetworkManager is not installed. Aborted."
  exit 9
fi

#
#  Check if NetworkManager.service is running
#
NM_RUNNING="$(sudo nmcli -t -f RUNNING general)"
if [ "${NM_RUNNING}" != "running" ]; then
  echo "Need to execute 'systemctl enable NetworkManager.service'"
  echo "Need to execute 'systemctl start NetworkManager.service'"
fi

# Check if NetworkManager-wait-online.service is running
ENABLED_NMWO="$(sudo systemctl is-enabled NetworkManager-wait-online)"
if [ "${ENABLED_NMWO}" != "enabled" ]; then
  echo "Need to execute 'systemctl enable NetworkManager-wait-online.service'"
  exit 3
fi
ACTIVE_NMWO="$(sudo systemctl is-active NetworkManager-wait-online)"
if [ "${ACTIVE_NMWO}" != "active" ]; then
  echo "Need to execute 'systemctl start NetworkManager-wait-online.service'"
  exit 3
fi

echo "systemd NetworkManager, et. al. is good"
