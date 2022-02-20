#!/bin/bash
# File: 411-net-dhclient.sh
# Title: Configures and activates DHCP client
# Description:
#
# Prerequisites:
#   nmcli (nmcli)
#   sed (sed)
#   gawk (awk)
#   iproute2 (ip)
#   util-linux (whereis)
#   coreutils (dirname, realpath, tr, wc, xargs)
#

SYSTEMD_UNIT_NAME="dhclient"
SYSTEMD_SERVICE_NAME="$SYSTEMD_UNIT_NAME@.service"
DPKG_NAME="isc-dhcp-client"


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
  NETDEV_DHCLIENT_CANDIDATE+="$this_netdev "
done
echo "Netdev(s) discovered: $NETDEV_LIST"
echo "Netdev(s) usable for DHCP client: $NETDEV_DHCLIENT_CANDIDATE"

NETDEV_COUNT="$(echo "$NETDEV_DHCLIENT_CANDIDATE" | wc -w)"
echo "Count of netdev(s): $NETDEV_COUNT"
if [ "$NETDEV_COUNT" -eq 0 ]; then
  echo "This is odd.  There aren't any viable netdev for networking."
  exit 5
fi
if [ "$NETDEV_COUNT" -eq 1 ]; then
  echo "No need to prompt for each netdev: rush-job..."
  # DHCLIENT_MODE="single-netdev"
  NETDEV_NAME="$NETDEV_DHCLIENT_CANDIDATE"
else
  # DHCLIENT_MODE="multiple-netdevs"
  while true; do
    read -rp "What network interface device do we get an IP from?: " REPLY
    ip link list "$REPLY" >/dev/null 2>&1
    RETSTS=$?
    if [[ "$RETSTS" -eq 0 ]]; then
      NETDEV_NAME="$REPLY"
      break
    fi
    echo "'$REPLY' is an invalid netdev. Try again."
    echo "Netdev(s) usable for DHCP client: $NETDEV_DHCLIENT_CANDIDATE"
  done
fi
NETDEV_NAME="${NETDEV_NAME// //}"
echo "Selected DHCLIENT network interface device: $NETDEV_NAME"
SYSTEMD_SERVICE_NAME_BY_INTF="${SYSTEMD_UNIT_NAME}@${NETDEV_NAME}.service"

# Check for dhclient binary
WHEREIS_DHCLIENT="$(whereis -b dhclient | head -n1 | awk '{print $2}')"
if [ -z "${WHEREIS_DHCLIENT}" ]; then
  sudo apt install "$DPKG_NAME"
fi

DATE="$(date)"

# Write the /etc/default/dhclient (and dhclient.<netdev>
sudo touch /etc/default/dhclient

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

function etc_default_dhclient
{
  echo ""
  FILENAME_GLOBAL="dhclient"
  FILENAME="dhclient-${NETDEV_NAME}"
  FILEPATH="/etc/default"
  DHCLIENT_DEFAULT_FILESPEC="$FILEPATH/$FILENAME"
  echo "Writing $DHCLIENT_DEFAULT_FILESPEC ..."

  cat << DHCLIENT_DEFAULT | sudo tee "$DHCLIENT_DEFAULT_FILESPEC" >/dev/null
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
DHCLIENT_DEFAULT
sudo chown root:root "$DHCLIENT_DEFAULT_FILESPEC"
sudo chmod 0640      "$DHCLIENT_DEFAULT_FILESPEC"

}
function etc_dhcp_dhclient_conf
{
  echo ""
  FILEPATH="/etc/dhcp"
  FILENAME_GLOBAL="dhclient.conf"
  DHCLIENT_FILEPATH_GLOBAL="$FILEPATH/$FILENAME_GLOBAL"
  FILENAME="dhclient-${NETDEV_NAME}.conf"
  DHCLIENT_FILEPATH="$FILEPATH/$FILENAME"

  if [ -f "$FILEPATH/$FILENAME_GLOBAL" ]; then
    OLD_DHCLIENT_FILEPATH="${DHCLIENT_FILEPATH_GLOBAL}.original-one"
    echo "Moving this old $FILENAME_GLOBAL out of the way..."
    echo "We are using the new $FILENAME instead"
    echo "Saving old copy as $OLD_DHCLIENT_FILEPATH."
    echo sudo mv "${DHCLIENT_FILEPATH_GLOBAL}  ${OLD_DHCLIENT_FILEPATH}"
    sudo mv "${DHCLIENT_FILEPATH_GLOBAL}"  "${OLD_DHCLIENT_FILEPATH}"
  fi
  echo "Writing $DHCLIENT_FILEPATH ..."
  cat << DHCLIENT_CONF | sudo tee "$DHCLIENT_FILEPATH" >/dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: ISC DHCP client configuration file for $NETDEV_NAME network device
# Creator: $(realpath "$0")
# Date: ${DATE}
# Description:
#   Configuration file for ISC DHCP ('dhclient') client
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
#   /var/lib/NetworkManager/dhclient-<netdev>.conf before
#   starting up the 'dhclient' daemon.
#

# send host-name = "Wireless_Broadband_Router";
send domain-name "home";

option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
option ms-classless-static-routes code 249 = array of unsigned integer 8;
option wpad code 252 = string;

request; # override dhclient defaults
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

DHCLIENT_CONF
  sudo chown root:root "$DHCLIENT_FILEPATH"
  sudo chmod 0640      "$DHCLIENT_FILEPATH"
}


function dhclient_NetworkManager
{
  echo ""
  echo "empty dhclient_NetworkManager function()"
}

function dhclient_systemd_networkd
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

    cat << DHCLIENT_EOF | sudo tee ${DHC_SVC} >/dev/null
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: Multi-interface (ISC) DHCP client

# Creator: $(realpath "$0")
# Date: ${DATE}

[Unit]
Description=dhclient on %I
Documentation=man:dhclient(8)

# dhclient wants network.target afterward
# dhclient will stay up regardlessof network.target failure
Wants=network.target

#
Before=network.target

# Binds to a specific device based on %i
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-devices-%i.device

[Service]
# Reads /etc/dhcp/dhclient.conf, by default
# Invokes /sbin/dhclient-script, by default, upon receiving a lease IP
# Force dhclient to run in foreground and let systemd handle all Unix FDs (0,1, and 2)
ExecStart=/sbin/dhclient -4 -d -v -cf /etc/dhcp/dhclient-%I.conf -pf /run/dhclient-%I.pid -lf /var/lib/dhcp/dhclient-%I.leases %I
Type=simple
PIDFile=/run/dhclient.%I.pid

# DHCLIENT should never exit, ever.
# DHCLIENT should not use '-1' option nor handle exit code 2 in a special way
Restart=always
##### TBD ExecStop=/sbin/dhclient -x
##### TBD ExecReload=/sbin/dhclient -r
#StandardInput=null
#StandardOutput=journal
#StandardError=journal

# Environment variables used by dhclient
#  Could define those envname in /etc/default/dhclient-%I
# PATH_DHCLIENT_CONF The dhclient.conf configuration file.
# PATH_DHCLIENT_DB The dhclient.leases database.
# PATH_DHCLIENT_PID The dhclient PID file.
# PATH_DHCLIENT_SCRIPT The dhclient-script file.
# environment filespec is prefaced with '-' as to ignore if unreadable or nonexisting
EnvironmentFile=/etc/default/dhclient
EnvironmentFile=-/etc/default/dhclient-%I


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

DHCLIENT_EOF
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


etc_default_dhclient
etc_dhcp_dhclient_conf

case $NM_MODE in
  'NetworkManager')
    dhclient_NetworkManager
    ;;
  'systemd-networkd')
    dhclient_systemd_networkd
    ;;
esac

echo "$0: All done."
exit 0

