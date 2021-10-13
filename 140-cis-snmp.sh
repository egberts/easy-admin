#!/bin/bash
# File: 140-cis-snmp-server.sh
# Title: Disable SNMP server


# checking if we need to prompt for 'disabling SNMP server'...


echo "Checking if SNMP server is running..."
SNMP_ENABLED="$(systemctl is-enabled snmp.service)"
if [ "$SNMP_ENABLED" != 'disabled' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  GLOBAL_IP_INTFS="$(ip -o addr | grep -c 'scope global')"
  DYN_IP_INTFS="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $GLOBAL_IP_INTFS"
  echo "Number of dynamic IP interfaces: $DYN_IP_INTFS"
  if [ "$DYN_IP_INTFS" -lt "$GLOBAL_IP_INTFS" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled SNMP? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$DYN_IP_INTFS" -eq "$GLOBAL_IP_INTFS" ]; then
    # skip prompt (no way to host a SNMP server)
    REPLY='y'
  fi
  if [ "$REPLY" == 'y' ]; then
    echo "Disabling and stopping snmp.service"
    echo "You run 'systemctl --now disable snmp.service', not me."
  else
    echo "Skipping disabling SNMP..."
  fi
fi
echo "Done."
