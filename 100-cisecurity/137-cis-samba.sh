#!/bin/bash
# File: 133-cis-samba-server.sh
# Title: Disable SAMBA server
#

# checking if we need to prompt for 'disabling SAMBA server'...


echo "Checking if SAMBA server is running..."
SAMBA_ENABLED="$(systemctl is-enabled smbd.service)"
if [ "$SAMBA_ENABLED" != 'disabled' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  GLOBAL_IP_INTFS="$(ip -o addr | grep -c 'scope global')"
  DYN_IP_INTFS="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $GLOBAL_IP_INTFS"
  echo "Number of dynamic IP interfaces: $DYN_IP_INTFS"
  if [ "$DYN_IP_INTFS" -lt "$GLOBAL_IP_INTFS" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled samba? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$DYN_IP_INTFS" -eq "$GLOBAL_IP_INTFS" ]; then
    # skip prompt (no way to host a SAMBA server)
    REPLY='y'
  fi
  if [ "$REPLY" == 'y' ]; then
    echo "Disabling and stopping smbd.service"
    echo "You run 'systemctl --now disable smbd.service', not me."
  else
    echo "Skipping disabling samba..."
  fi
fi
echo "Done."
