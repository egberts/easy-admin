#!/bin/bash
# File: 133-cis-ldap-server.sh
# Title: Disable LDAP server
#

# checking if we need to prompt for 'disabling LDAP server'...
echo "Remove LDAP daemon service"
echo

SYSTEMCTL_BIN="$(which systemctl)"
if [ -z "$SYSTEMCTL_BIN" ]; then
  echo "No systemd installed; exiting..."
  exit 1
fi


echo "Checking if LDAP server is running..."
slapd_active="$(systemctl is-active slapd.service)"
if [ "$slapd_active" != 'inactive' ]; then

  # So, it is active... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  global_ip_intfs="$(ip -o addr | grep -c 'scope global')"
  dyn_ip_intfs="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $global_ip_intfs"
  echo "Number of dynamic IP interfaces: $dyn_ip_intfs"
  if [ "$dyn_ip_intfs" -lt "$global_ip_intfs" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled slapd? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$dyn_ip_intfs" -eq "$global_ip_intfs" ]; then
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
