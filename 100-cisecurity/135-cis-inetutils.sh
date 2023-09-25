#!/bin/bash
# File: 135-cis-inetutils.sh
# Title: Disable FTP/RSH/RLOGIN server
#
echo "Remove FTP/RSH/RLOGIN server daemon service"
echo

SYSTEMCTL_DIR="$(which systemctl)"
if [ -z "$SYSTEMCTL_DIR" ]; then
  echo "systemd is not installed; exiting ..."
  exit 1
fi

# checking if we need to prompt for 'disabling FTP server'...

echo "Checking if FTP server is running..."
fptd_active="$(systemctl is-active ftpd.service)"
if [ "$fptd_active" != 'inactive' ]; then

  # So, it is enabled... probably should prompt if we need it
  # But if it is a lone but dynamic interface, kill it
  GLOBAL_IP_INTFS="$(ip -o addr | grep -c 'scope global')"
  DYN_IP_INTFS="$(ip -o addr | grep -c ' dynamic ')"
  echo "Number of global IP interfaces: $GLOBAL_IP_INTFS"
  echo "Number of dynamic IP interfaces: $DYN_IP_INTFS"
  if [ "$DYN_IP_INTFS" -lt "$GLOBAL_IP_INTFS" ]; then
    # must prompt
    ip -o -brief addr
    read -rp "Many static interfaces, sure you want to disabled ftpd? N/y: " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  elif [ "$DYN_IP_INTFS" -eq "$GLOBAL_IP_INTFS" ]; then
    # skip prompt (no way to host a VSFPTD server)
    REPLY='y'
  fi
  if [ "$REPLY" == 'y' ]; then
    echo "Disabling and stopping ftpd.service"
    echo "You run 'systemctl --now disable ftpd.service', not me."
  else
    echo "Skipping disabling ftpd..."
  fi
fi

echo "WARNING: You should remove 'inetutils' package yourself."
# pacman -R inetutils
echo "Done."
