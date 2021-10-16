#!/bin/bash
# File: 133-cis-ldap-server.sh
# Title: Disable LDAP server
#

# checking if we need to prompt for 'disabling LDAP server'...


echo "Checking if LDAP server is running..."
SLAPD_ENABLED="$(systemctl is-enabled slapd.service)"
if [ "$SLAPD_ENABLED" != 'disabled' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  GLOBAL_IP_INTFS="$(ip -o addr | grep -c 'scope global')"
  DYN_IP_INTFS="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $GLOBAL_IP_INTFS"
  echo "Number of dynamic IP interfaces: $DYN_IP_INTFS"
  if [ "$DYN_IP_INTFS" -lt "$GLOBAL_IP_INTFS" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled slapd? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$DYN_IP_INTFS" -eq "$GLOBAL_IP_INTFS" ]; then
    # skip prompt (no way to host a SLAPD server)
    REPLY='y'
  fi
  if [ "$REPLY" == 'y' ]; then
    echo "Disabling and stopping slapd.service"
    echo "You run 'systemctl --now disable slapd.service', not me."
  else
    echo "Skipping disabling slapd..."
  fi
fi
echo "Done."
