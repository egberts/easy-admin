#!/bin/bash
# File: 133-cis-vsftp-server.sh
# Title: Disable FTP server
#

# checking if we need to prompt for 'disabling FTP server'...


echo "Checking if FTP server is running..."
vsfptd_active="$(systemctl is-active vsftpd.service)"
if [ "$vsfptd_active" != 'inactive' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  GLOBAL_IP_INTFS="$(ip -o addr | grep -c 'scope global')"
  DYN_IP_INTFS="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $GLOBAL_IP_INTFS"
  echo "Number of dynamic IP interfaces: $DYN_IP_INTFS"
  if [ "$DYN_IP_INTFS" -lt "$GLOBAL_IP_INTFS" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled vsftpd? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$DYN_IP_INTFS" -eq "$GLOBAL_IP_INTFS" ]; then
    # skip prompt (no way to host a VSFPTD server)
    REPLY='y'
  fi
  if [ "$REPLY" == 'y' ]; then
    echo "Disabling and stopping vsftpd.service"
    echo "You run 'systemctl --now disable vsftpd.service', not me."
  else
    echo "Skipping disabling vsftpd..."
  fi
fi
echo "Done."
