#!/bin/bash
# File: 140-cis-snmp-server.sh
# Title: Disable SNMP server


# checking if we need to prompt for 'disabling SNMP server'...


echo "Checking if SNMP server is running..."
snmp_active="$(systemctl is-active snmp.service)"
if [ "$snmp_active" != 'inactive' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  global_ip_intfs="$(ip -o addr | grep -c 'scope global')"
  dyn_ip_intfs="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $global_ip_intfs"
  echo "Number of dynamic IP interfaces: $dyn_ip_intfs"
  if [ "$dyn_ip_intfs" -lt "$global_ip_intfs" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled SNMP? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$dyn_ip_intfs" -eq "$global_ip_intfs" ]; then
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
