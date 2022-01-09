#!/bin/bash
# File: 130-cis-dhcp-server.sh
# Title: Disable DHCP server
#

echo "CIS recommendation for removal of DHCP Server daemon service"
echo

SYSTEMCTL_BIN="$(which systemctl)"
if [ -z "$SYSTEMCTL_BIN" ]; then
  echo "No systemd installed; exiting ..."
  exit 1
fi

# checking if we need to prompt for 'disabling DHCP server'...


echo "Checking if DHCP server is running..."
DHCPD_ENABLED="$(systemctl is-enabled isc-dhcp-server.service)"
if [ "$DHCPD_ENABLED" != 'disabled' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  GLOBAL_IP_INTFS="$(ip -o addr | grep -c 'scope global')"
  DYN_IP_INTFS="$(ip -o addr | grep -c ' dynamic ' )"
  echo "Number of global IP interfaces: $GLOBAL_IP_INTFS"
  echo "Number of dynamic IP interfaces: $DYN_IP_INTFS"
  if [ "$DYN_IP_INTFS" -lt "$GLOBAL_IP_INTFS" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled isc-dhcp-server? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$DYN_IP_INTFS" -eq "$GLOBAL_IP_INTFS" ]; then
    # skip prompt (no way to host a DHCP server)
    REPLY='y'
  fi
  if [ "$REPLY" == 'y' ]; then
    echo "Disabling and stopping isc-dhcp-server.service"
    echo "You run 'systemctl --now disable isc-dhcp-server.service', not me."
  else
    echo "Skipping disabling isc-dhcp-server..."
  fi
fi
echo "Done."
