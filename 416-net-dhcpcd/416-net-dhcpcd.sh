#!/bin/bash
# File: 416-net-dhcpcd.sh
# Title: Configures and activates DHCP client using dhcpcd
# Description:
#
# Prerequisites:
#   nmcli (nmcli)
#   xargs (xargs)
#   ip (ip)
#   realpath (realpath)
#   sed (sed)
#   gawk (awk)
#   iproute2 (ip)
#   util-linux (whereis)
#   systemctl (systemctl)
#   sudo (sudo)
#   coreutils (dirname, realpath, tr, wc, xargs)
#

SYSTEMD_UNIT_NAME="dhcpcd"
SYSTEMD_SERVICE_NAME="$SYSTEMD_UNIT_NAME@.service"
DPKG_NAME="dhcp-client"


echo "Installing ISC DHCP client ..."

NETDEV_LIST="$(ip -brief -o link list | awk '{print $1}' | xargs)"
NETDEV_IGNORE_WG="$(ip -brief -o link list type wireguard | awk '{print $1}' | xargs)"
echo "Wireguard netdev(s) to ignore: $NETDEV_IGNORE_WG"
NETDEV_IGNORE_BRIDGE="$(ip -brief -o link list type bridge | awk '{print $1}' | xargs)"
echo "Bridge netdev(s) to ignore: $NETDEV_IGNORE_BRIDGE"
NETDEV_IGNORE_BRIDGE_SLAVE="$(ip -brief -o link list type bridge_slave | awk '{print $1}' | xargs)"
echo "Bridge-slave netdev(s) to ignore: $NETDEV_IGNORE_BRIDGE_SLAVE"

for this_netdev in $NETDEV_LIST; do
  if [[ "lo" = *"$this_netdev"* ]]; then
    continue
  fi

  if [[ "$NETDEV_IGNORE_WG" == *"$this_netdev"* ]]; then
    continue
  fi
  if [[ "$NETDEV_IGNORE_BRIDGE" == *"$this_netdev"* ]]; then
    continue
  fi
  if [[ "$NETDEV_IGNORE_BRIDGE_SLAVE" == *"$this_netdev"* ]]; then
    continue
  fi
  NETDEV_DHCPCD_CANDIDATE+="$this_netdev "
done
echo "Netdev(s) discovered: $NETDEV_LIST"
echo "Netdev(s) usable for DHCP client: $NETDEV_DHCPCD_CANDIDATE"

NETDEV_COUNT="$(echo "$NETDEV_DHCPCD_CANDIDATE" | wc -w)"
echo "Count of netdev(s): $NETDEV_COUNT"
if [ "$NETDEV_COUNT" -eq 0 ]; then
  echo "This is odd.  There aren't any viable netdev for networking."
  exit 5
fi
if [ "$NETDEV_COUNT" -eq 1 ]; then
  echo "No need to prompt for each netdev: rush-job..."
  # DHCPCD_MODE="single-netdev"
  NETDEV_NAME="$NETDEV_DHCPCD_CANDIDATE"
else
  # DHCPCD_MODE="multiple-netdevs"
  while true; do
    read -rp "What network interface device do we get an IP from?: " REPLY
    ip link list "$REPLY" >/dev/null 2>&1
    RETSTS=$?
    if [[ "$RETSTS" -eq 0 ]]; then
      NETDEV_NAME="$REPLY"
      break
    fi
    echo "'$REPLY' is an invalid netdev. Try again."
    echo "Netdev(s) usable for DHCP client: $NETDEV_DHCPCD_CANDIDATE"
  done
fi
NETDEV_NAME="${NETDEV_NAME// /}"
echo "Selected DHCPCD network interface device: $NETDEV_NAME"
SYSTEMD_SERVICE_NAME_BY_INTF="${SYSTEMD_UNIT_NAME}@${NETDEV_NAME}.service"

# Check for dhcpcd binary
WHEREIS_DHCPCD="$(whereis -b dhcpcd | head -n1 | awk '{print $2}')"
if [ -z "${WHEREIS_DHCPCD}" ]; then
    echo "Install $DPKG_NAME package and re-run this command again."
    exit 9
fi

DATE="$(date)"

# Write the /etc/default/dhcpcd (and dhcpcd.<netdev>
sudo touch /etc/default/dhcpcd

# Auto-detect either NetworkManager or systemd-networkd
NM_MODE='no-network-manager-found-so-far'
NMCLI_WHEREIS="$(whereis nmcli|awk '{print $2}')"
if [ -n "$NMCLI_WHEREIS" ]; then
  NMCLI_STATUS="$(nmcli -t -f RUNNING general)"
  if [ "$NMCLI_STATUS" != "running" ]; then
    NM_MODE="try-systemd-networkd"
  else
    NM_MODE="NetworkManager"
  fi
fi
# If not found having a working NetworkManager, try systemd-networkd
if [ "$NM_MODE" != "NetworkManager" ]; then
  # 'networkctl' is worthless for CLI usage, no error code
  # Use 'systemctl is-enabled systemd-networkd' instead
  SYSTEMCTL_WHEREIS="$(whereis systemctl|awk '{print $2}')"
  if [ -n "${SYSTEMCTL_WHEREIS}" ]; then
    echo "Checking on $SYSTEMD_SERVICE_NAME_BY_INTF..."
    UNIT_ENABLED="$(systemctl is-enabled systemd-networkd)"
    echo "systemd-networkd.service: enabled?: $UNIT_ENABLED"
    if [ "$UNIT_ENABLED" != "enabled" ]; then
      # neither works
      echo "Neither NetworkManager nor systemd-networkd is enabled; aborted."
      NM_MODE="no-network-manager-found"
    else
      UNIT_ACTIVE="$(systemctl is-active systemd-networkd)"
      echo "systemd-networkd: active?: $UNIT_ACTIVE"
      if [ "$UNIT_ACTIVE" != "active" ]; then
        echo "Neither NetworkManager nor systemd-networkd is active; aborted."
        NM_MODE="no-network-manager-found"
      else
        NM_MODE="systemd-networkd"
      fi
    fi
  fi
fi

function etc_default_dhcpcd
{
  echo ""
  FILENAME_GLOBAL="dhcpcd"
  FILENAME="dhcpcd-${NETDEV_NAME}"
  FILEPATH="/etc/default"
  DHCPCD_DEFAULT_FILESPEC="$FILEPATH/$FILENAME"
  echo "Writing $DHCPCD_DEFAULT_FILESPEC ..."

  cat << DHCPCD_DEFAULT | sudo tee "$DHCPCD_DEFAULT_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: DHCP client default configuration setting
# Creator: $(realpath "$0")
# Date: ${DATE}
# Description:
#   Used by SysV or systemd initd.
#
# Currently has no default settings
#
#
DHCPCD_DEFAULT
sudo chown root:root "$DHCPCD_DEFAULT_FILESPEC"
sudo chmod 0640      "$DHCPCD_DEFAULT_FILESPEC"

}
function etc_dhcp_dhcpcd_conf
{
  echo ""
  FILEPATH="/etc/dhcp"
  FILENAME_GLOBAL="dhcpcd.conf"
  DHCPCD_FILEPATH_GLOBAL="$FILEPATH/$FILENAME_GLOBAL"
  FILENAME="dhcpcd-${NETDEV_NAME}.conf"
  DHCPCD_FILEPATH="$FILEPATH/$FILENAME"

  if [ -f "$FILEPATH/$FILENAME_GLOBAL" ]; then
    OLD_DHCPCD_FILEPATH="${DHCPCD_FILEPATH_GLOBAL}.original-one"
    echo "Moving this old $FILENAME_GLOBAL out of the way..."
    echo "We are using the new $FILENAME instead"
    echo "Saving old copy as $OLD_DHCPCD_FILEPATH."
    echo sudo mv "${DHCPCD_FILEPATH_GLOBAL}  ${OLD_DHCPCD_FILEPATH}"
    sudo mv "${DHCPCD_FILEPATH_GLOBAL}"  "${OLD_DHCPCD_FILEPATH}"
  fi
  echo "Writing $DHCPCD_FILEPATH ..."
  cat << DHCPCD_CONF | sudo tee "$DHCPCD_FILEPATH" >/dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: ISC DHCP client configuration file for $NETDEV_NAME network device
# Creator: $(realpath "$0")
# Date: ${DATE}
# Description:
#   Configuration file for ISC DHCP ('dhcpcd') client
#   customized for a particular network (netdev) interface.
#
#   If you are using NetworkManager, you will NOT be able to use
#   the 'lease' block or 'alias' block in this file; as for NM
#   who will actually read this file at this $FILEPATH
#   file path.
#
#   Then NM proceeds to murder this configuration file with
#   some extra GUI-based settings, removes some 'unneeded' ones,
#   and replaces a few.  Afterward, the NM stores these new DHCP
#   client configuration file into a new file in a new directory
#   /var/lib/NetworkManager/dhcpcd-<netdev>.conf before
#   starting up the 'dhcpcd' daemon.
#

# send host-name = "Wireless_Broadband_Router";
send domain-name "home";

option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
option ms-classless-static-routes code 249 = array of unsigned integer 8;
option wpad code 252 = string;

request; # override dhcpcd defaults
also request subnet-mask;
also request broadcast-address;
also request time-offset;
also request routers;
also request domain-name;
also request domain-name-servers;
also request time-servers;
also request log-servers;
also request default-ip-ttl;
also request dhcp-requested-address;
also request dhcp-lease-time;
also request dhcp-server-identifier;
also request dhcp-parameter-request-list;
also request vendor-class-identifier;
also request dhcp-client-identifier;
also request interface-mtu;
also request ntp-servers;
also request rfc3442-classless-static-routes;
also request static-routes;
also request wpad;
also request root-path;

DHCPCD_CONF
  sudo chown root:root "$DHCPCD_FILEPATH"
  sudo chmod 0640      "$DHCPCD_FILEPATH"
}


function dhcpcd_NetworkManager
{
  echo ""
  echo "empty dhcpcd_NetworkManager function()"
}

function dhcpcd_systemd_networkd
{
  echo ""
  # Check if our very own systemd unit service file is there
  systemctl cat "$SYSTEMD_SERVICE_NAME" >/dev/null 2>&1
  RETSTS=$?
  if [ "$RETSTS" -eq 0 ]; then
    # This systemd unit service file does exist.
    echo "This utility is the first to have used the word $SYSTEMD_UNIT_NAME"
    echo "That systemd unit service file is ours to maintain with."
    read -rp "$SYSTEMD_UNIT_NAME exists; keep it or update it? (K/u):" -eiK REPLY
    REPLY="$(echo "${REPLY:0:1}" | awk '{print $1}')"
    if [[ "$REPLY" = '' ]] || [[ "$REPLY" = 'K' ]]; then
      REPLACE_UNIT='n'
    else
      REPLACE_UNIT='y'
    fi
  else
    # This systemd unit service file does NOT exist.
    REPLACE_UNIT='y'
  fi

  if [ "$REPLACE_UNIT" == 'y' ]; then
    FILENAME="$SYSTEMD_SERVICE_NAME"
    FILEPATH="/etc/systemd/system"
    DHC_SVC="$FILEPATH/$FILENAME"
    echo "Writing $DHC_SVC ..."

    cat << DHCPCD_EOF | sudo tee ${DHC_SVC} >/dev/null
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: Multi-interface (ISC) DHCP client

# Creator: $(realpath "$0")
# Date: ${DATE}

[Unit]
Description=dhcpcd on %I
Documentation=man:dhcpcd(8)

# dhcpcd wants network.target afterward
# dhcpcd will stay up regardlessof network.target failure
Wants=network.target

#
Before=network.target

# Binds to a specific device based on %i
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device

[Service]
# Reads /etc/dhcp/dhcpcd.conf, by default
# Invokes /sbin/dhcpcd-script, by default, upon receiving a lease IP
# Force dhcpcd to run in foreground and let systemd handle all Unix FDs (0,1, and 2)
ExecStart=/sbin/dhcpcd -4 -d -v -cf /etc/dhcp/dhcpcd-%I.conf -pf /run/dhcpcd-%I.pid -lf /var/lib/dhcp/dhcpcd-%I.leases %I
Type=simple
PIDFile=/run/dhcpcd.%I.pid

# DHCPCD should never exit, ever.
# DHCPCD should not use '-1' option nor handle exit code 2 in a special way
Restart=always
##### TBD ExecStop=/sbin/dhcpcd -x
##### TBD ExecReload=/sbin/dhcpcd -r
#StandardInput=null
#StandardOutput=journal
#StandardError=journal

# Environment variables used by dhcpcd
#  Could define those envname in /etc/default/dhcpcd-%I
# PATH_DHCPCD_CONF The dhcpcd.conf configuration file.
# PATH_DHCPCD_DB The dhcpcd.leases database.
# PATH_DHCPCD_PID The dhcpcd PID file.
# PATH_DHCPCD_SCRIPT The dhcpcd-script file.
# environment filespec is prefaced with '-' as to ignore if unreadable or nonexisting
EnvironmentFile=/etc/default/dhcpcd
EnvironmentFile=-/etc/default/dhcpcd-%I


# Systemd Security settings
# PrivateNetwork=false
# RestrictNamespaces=true
# CapabilityBoundingSet=CAP_SETUID
# CapabilityBoundingSet=CAP_SETGID
# CapabilityBoundingSet=CAP_SETPCAP
# CapabilityBoundingSet=~CAP_SYS_ADMIN
# CapabilityBoundingSet=CAP_SYS_PTRACE
# RestrictAddressFamilies=AF_INET6
# RestrictAddressFamilies=AF_INET
# RestrictNamespaces=~CLONE_NEWUSER
# CapabilityBoundingSet=~CAP_CHOWN
# CapabilityBoundingSet=~CAP_FSETID
# CapabilityBoundingSet=~CAP_SETFCAP
# CapabilityBoundingSet=CAP_FOWNER
# CapabilityBoundingSet=CAP_IPC_OWNER
# CapabilityBoundingSet=CAP_NET_ADMIN
# CapabilityBoundingSet=CAP_SYS_MODULE
# CapabilityBoundingSet=CAP_SYS_RAWIO
# CapabilityBoundingSet=CAP_SYS_TIME
# DeviceAllow=NETDEV_NAME
# IPAddressDeny=
# KeyringMode=
# NoNewPrivileges=true
# NotifyAccess=
# PrivateDevices=true
# PrivateMounts=true
# PrivateTmp=true
# PrivateUsers=true   # breaks DHCP client!!!
# ProtectClock=true
# ProtectControlGroups=true
# ProtectHome=true
# ProtectKernelLogs=true
# ProtectKernelModules=true
# ProtectKernelTunables=true
# ProtectProc=
# ProtectSystem=true
# RestrictAddressFamilies=AF_PACKET
# RestrictSUIDSGID=true

# CapabilityBoundingSet=CAP_AUDIT_*
# CapabilityBoundingSet=CAP_KILL
# CapabilityBoundingSet=CAP_MKNOD
# CapabilityBoundingSet=CAP_NET_BIND_SERVICE
# CapabilityBoundingSet=CAP_NET_BIND_BROADCAST
# CapabilityBoundingSet=CAP_NET_BIND_RAW
# CapabilityBoundingSet=CAP_SYSLOG
# CapabilityBoundingSet=CAP_SYS_NICE
# CapabilityBoundingSet=CAP_SYS_RESOURCE
# RestrictNamespaces=~CLONE_NEWCGROUP
# RestrictNamespaces=~CLONE_NEWIPC
# RestrictNamespaces=~CLONE_NEWNET
# RestrictNamespaces=~CLONE_NEWNS
# RestrictNamespaces=~CLONE_NEWPID
# RestrictRealtime=true

# RestrictAddressFamilies=AF_NETLINK

# SupplementaryGroups=
# CapabilityBoundingSet=~CAP_MAC_*
# CapabilityBoundingSet=~CAP_SYS_BOOT   # breaks DHCP client !!!!

# LockPersonality=true

MemoryDenyWriteExecute=true

# UMask=0067
# CapabilityBoundingSet=CAP_LINUX_IMMUTABLE
# CapabilityBoundingSet=CAP_IPC_LOCK
# CapabilityBoundingSet=CAP_SYS_CHROOT
# ProtectHostname=true
# CapabilityBoundingSet=CAP_BLOCK_SUSPEND
# CapabilityBoundingSet=CAP_LEASE
# CapabilityBoundingSet=CAP_SYS_PACCT
# CapabilityBoundingSet=CAP_SYS_TTY_CONFIG
# CapabilityBoundingSet=CAP_WAKE_ALARM
# RestrictAddressFamilies=~AF_UNIX
# ProcSubset=


[Install]
WantedBy=multi-user.target

DHCPCD_EOF
  else
    echo "Reusing the $SYSTEMD_UNIT_NAME"
  fi
  # Clean off old ones
  echo "Checking on $SYSTEMD_SERVICE_NAME_BY_INTF..."
  UNIT_ENABLED="$(systemctl is-enabled "$SYSTEMD_SERVICE_NAME_BY_INTF")"
  echo "$SYSTEMD_SERVICE_NAME_BY_INTF: enabled?: $UNIT_ENABLED"
  if [ "$UNIT_ENABLED" != "enabled" ]; then
    sudo systemctl enable "$SYSTEMD_SERVICE_NAME_BY_INTF"
  fi
  UNIT_ACTIVE="$(systemctl is-active "$SYSTEMD_SERVICE_NAME_BY_INTF")"
  echo "$SYSTEMD_SERVICE_NAME_BY_INTF: active?: $UNIT_ACTIVE"
  if [ "$UNIT_ACTIVE" != "active" ]; then
    sudo systemctl stop "$SYSTEMD_SERVICE_NAME_BY_INTF"
    sudo systemctl start "$SYSTEMD_SERVICE_NAME_BY_INTF"
  fi
}


etc_default_dhcpcd
etc_dhcp_dhcpcd_conf

case $NM_MODE in
  'NetworkManager')
    dhcpcd_NetworkManager
    ;;
  'systemd-networkd')
    dhcpcd_systemd_networkd
    ;;
esac

echo "$0: All done."
exit 0

