#!/usr/bin/env bash
# File: 435-nm-NetworkManager-nmcli-wireguard-interface.sh
# Title: wireguard configurator
# Description:
#   A bash-based Wireguard configurator that
#   can set up any type of network layouts in
#   [TODO: beginner or] expert configuration mode.
#   [TODO: 'wireguard.mtu' goes under 'connection' section, useful?
#
#   NOTE: This script will not insert '0.0.0.0/0' into the
#         [Peer] 'AllowedIPs' as a security measure.
#         But instead will review your current route table
#         for suitable candidates as well as entering your
#         own route (may it be that you enter 0.0.0.0/0
#         in yourself).
#
# This tool supports both peer and server endpoints of the
# following network-layouts:
#   - Peer-to-server
#   - Server-to-server
#   - Peer-to-server-to-Internet  (VPN hoster or VPN user)
#   - Peer-to-server-to-LAN  (VPN hoster or VPN user)
#   - Multiple-peers-to-server-LAN
#   - peer-to-server-to-LAN-and-Internet
#
# If this host is auto-detected as behind a NAT/firewall,
# then only the following network-layout are supported.
#   - Peer-to-server-*
#   - LAN-to-peer-to-server-*
#   - Internet-Peer-to-server
#   - Internet-Peer-to-server-LAN
#
# If using LAN option, you are responsible for routing
# table update.  Perhaps, set up a RIP/EGP/OSPF daemon?
# Nevertheless, we will output an update route table script
# for this side for your convenience.
#
# WHAT IT CANNOT DO:
#    - Bounce server; peer behind a NAT to peer behind a NAT.
#      You'll need a STUN/TUNS server for that.
#
# Prerequisite packages:
#   wireguard-tools
#   ipcalc-ng
#   iproute2 (/sbin/ip)
#   bind9-dnsutils (/usr/bin/dig)
#   gawk (/usr/bin/awk)
#   grep
#   util-linux (/usr/bin/whereis)
#   coreutils (cat, date, tee, mkdir, chown, chmod)
#
WG_DIRNAME="wireguard"
WG_DIRPATH="/etc/$WG_DIRNAME"

echo "Set up Wireguard under NetworkManager"
echo

if [ "$USER" != 'root' ]; then
  echo "May prompt for sudo password..."
  echo
fi
echo "May mess with your network settings; do not do this remotely"
read -rp "Enter in 'continue' to ... continue: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 3
fi

PRG_NAME="$(basename "$0")"

VERSION=$(wg --version)
echo "Wireguard ver; $VERSION"
if [ "$USER" == "root" ] || [ "$GROUP" == "root" ]; then
  echo "This $PRG_NAME shall not be run in 'root' mode."
  exit 254
fi

DEFAULT_PRIVATE_IP4=192.168.2.0/24

#  LOCAL_IP4_ADDR_PREFIX can be undefined (to mean ANY interface)
LOCAL_PORT=51820
LOCAL_IP4_ADDR=
LOCAL_IP4_PREFIX=
LOCAL_IP4_ADDR_PREFIX=
LOCAL_ALL_FWRDING=n
LOCAL_IP4_ROUTES_A=()
LOCAL_IP4_NATTED=y
LOCAL_IP6_ADDR=
LOCAL_IP6_PREFIX=
LOCAL_IP6_ADDR_PREFIX=
LOCAL_IP6_ROUTES_A=()

TUNNEL_INTF_NAME=wg0
TUNNEL_IP4_ADDR_PREFIX=
TUNNEL_IP4_PREFIX=24
TUNNEL_IP4_ADDR_LOCAL=192.168.2.2/24
TUNNEL_IP4_ADDR_REMOTE=192.168.2.1/24

REMOTE_HOSTNAME=
REMOTE_IP4_ADDR=
REMOTE_IP4_PREFIX=
REMOTE_IP6_ADDR=
REMOTE_IP6_PREFIX=
REMOTE_IP6_ADDR_PREFIX=
REMOTE_PORT=51820

WG_BIN="$(whereis -b wg | awk '{ print $2}')"
if [ -z "$WG_BIN" ]; then
  echo "/etc/wireguard is missing; missing package installation?"
  exit 11
fi

source ./maintainer-NetworkManager.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-NetworkManager-conf.d-wireguard-enable.sh"

BR_WG_DIRSPEC="${BUILDROOT}${CHROOT_DIR}/$WG_DIRPATH"

# Recover old settings
PARAMS_FILENAME="${PRG_NAME}-old-settings.conf"
PARAMS_FILESPEC="${WG_DIRSPEC}/$PARAMS_FILENAME"
BR_PARAMS_FILESPEC="${BUILDROOT}${CHROOT_DIR}/$PARAMS_FILESPEC"
if [ -r "$BR_PARAMS_FILENAME" ]; then
  read -rp "Re-use old settings as current defaults? (N/y): " -i "N" -e REUSE
  REUSE="$(echo "${REUSE:0:1}" | awk '{print tolower($REUSE)}')"
  if [ "${REUSE:0:1}" == 'Y' ]; then
    echo "Reading in old settings ($PARAMS_FILENAME)..."
    # shellcheck disable=SC1090
    source "${BR_PARAMS_FILESPEC}"
  else
    echo "Deleting off the old settings ($PARAMS_FILENAME)..."
    rm "${BR_PARAMS_FILENAME}"
  fi
fi

WG_BIN="$(whereis -b wg | awk '{ print $2}')"
if [ -z "$WG_BIN" ]; then
  echo "/usr/bin/wireguard is missing; missing package installation?"
  exit 11
fi

SHOREWALL_BIN="$(which -a shorewall)"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  SHOREWALL_BIN=""
  echo "Shorewall not found; skipping shorewall support"
fi

DATETS_NOW="$(date)"

function save_params() {
  echo "Saving old settings to $PARAMS..."
  cat << PARAMS_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$GLOBAL_CONFIG_FILESPEC" > /dev/null
#
# Filespec: $GLOBAL_CONFIG_FILESPEC
# Title: Configuration file used by $PRG_NAME
# Creator: $PRG_NAME
# Created: $DATETS_NOW
#
LOCAL_PORT=$LOCAL_PORT
LOCAL_ALL_FWRDING=$LOCAL_ALL_FWRDING
LOCAL_IP4_ADDR=$LOCAL_IP4_ADDR
LOCAL_IP4_ADDR_PREFIX=$LOCAL_IP4_ADDR_PREFIX
LOCAL_IP4_PREFIX=$LOCAL_IP4_PREFIX
LOCAL_IP4_NATTED=$LOCAL_IP4_NATTED
LOCAL_IP4_ROUTES_A=${LOCAL_IP4_ROUTES_A[*]}
LOCAL_IP6_ADDR=$LOCAL_IP6_ADDR
LOCAL_IP6_ADDR_PREFIX=$LOCAL_IP6_ADDR_PREFIX
LOCAL_IP6_PREFIX=$LOCAL_IP6_PREFIX
LOCAL_IP6_ROUTES_A=${LOCAL_IP6_ROUTES_A[*]}

REMOTE_HOSTNAME=$REMOTE_HOSTNAME
REMOTE_IP4_ADDR=$REMOTE_IP4_ADDR
REMOTE_IP4_PREFIX=$REMOTE_IP4_PREFIX
REMOTE_IP6_ADDR=$REMOTE_IP6_ADDR
REMOTE_IP6_ADDR_PREFIX=$REMOTE_IP6_ADDR_PREFIX
REMOTE_IP6_PREFIX=$REMOTE_IP6_PREFIX
REMOTE_PORT=$REMOTE_PORT

TUNNEL_INTF_NAME=$TUNNEL_INTF_NAME
TUNNEL_IP4_ADDR_PREFIX=${TUNNEL_IP4_ADDR_PREFIX}
TUNNEL_IP4_PREFIX=${TUNNEL_IP4_PREFIX}
TUNNEL_IP4_ADDR_LOCAL=${TUNNEL_IP4_ADDR_LOCAL}
TUNNEL_IP4_ADDR_REMOTE=${TUNNEL_IP4_ADDR_REMOTE}
PARAMS_EOF
}



# Get all details of local network on this host.

# First, get an array of non-localhost IPv4 network devices
# Only 'scope link' and 'scope global' (no 'scope host')
# shellcheck disable=SC2207
NETDEV_NAME_A=($(ip -o addr | grep -v 'scope host' | grep -v inet6 | awk '{print $2}' | xargs))
# shellcheck disable=SC2207
# NETDEV_NAME_MAPFILE="$(echo "$(ip -o addr|grep -v 'scope host'|grep -v inet6 | awk '{print $2}' | xargs)" | mapfile)"

# get an array of non-localhost IPv4 addresses
# shellcheck disable=SC2207
IP4_ADDR_LIST=($(ip -o addr | grep -v 'scope host' | grep -v inet6 | awk '{print $4}' | awk -F'/' '{print $1}'))
# shellcheck disable=SC2207
IP4_ADDR_PREFIX_LIST=($(ip -o addr | grep -v 'scope host' | grep -v inet6 | awk '{print $4}'))

# get an array of non-localhost IPv4 mode
# shellcheck disable=SC2207
IP4_DYN_LIST=($(ip -o addr | grep -v 'scope host' | grep -v inet6 | awk '{print $9}'))

# if there is a dynamic, we probably should lean toward that local IP address
# go loop and extract that dynamic IP network interface
for idx in ${#IP4_IP_LIST[*]}; do
  if [ "${IP4_DYN_LIST[$idx]}" == 'dynamic' ]; then
    LOCAL_IP4_ADDR="$(echo "${IP4_ADDR_LIST[$idx]}" | awk -F'/' '{print $1}')"
    LOCAL_IP4_ADDR_PREFIX=${IP4_ADDR_LIST[$idx]}
    # Save the network device name of this dynamic IP address
    LOCAL_NETDEV=${NETDEV_NAME_A[$idx]}
    break
  fi
done

# Using the network device name, find the actual routing subnet
# Ignore any 'default' entry.
if [ -n "$LOCAL_NETDEV" ]; then

  # iterate over an array of IP addresses
  for idx in ${#IP4_IP_LIST[*]}; do

    if [ "${LOCAL_NETDEV}" == "${NETDEV_NAME_A[$idx]}" ]; then
      # echo "Matching device name ${LOCAL_NETDEV}"
      LOCAL_IP4_ADDR=$(echo "${IP4_ADDR_LIST[$idx]}" | awk -F'/' '{print $1}')
      LOCAL_IP4_ADDR_PREFIX="${IP4_ADDR_LIST[$idx]}"
    fi
  done
fi

# Get all the non-default IP routing entries
###IP4_ROUTE_A=($(ip route | grep -v '^default' | awk '{print $1}'))

# Get that default gateway (first default ones should suffice)
###DEFAULT_GW=$(ip route | grep '^default' | awk '{print $3}' | sort -u)

echo "OUTER TUNNEL"
echo "============"
echo
echo "LOCAL HOST - OUTER TUNNEL"
echo "-------------------------"

# Make up an interface name (might be 'wg0')?
PREEXISTING_WG_NETDEV_A="$(ip -o link show type wireguard | awk '{print $2}' | sed -e 's/://g')"

echo
echo "Choose a new or reuse one from a list of current Wireguard interfaces."
echo "Existing wireguard interfaces currently are:"
echo "    ${PREEXISTING_WG_NETDEV_A[*]}"
read -rp "Enter in Wireguard interface name: " -e -i "${TUNNEL_INTF_NAME}" TUNNEL_INTF_NAME

echo
read -rp "What the UDP port number for this local host to listen here?: " \
  -i $LOCAL_PORT -e LOCAL_PORT

# Onward with the remote host
echo
echo "REMOTE HOST - OUTER TUNNEL"
echo "-----------------------------------------"
while true; do
  read -rp "Hostname/IP address of remote host: " REMOTE_HOSTNAME
  [[ -z "$REMOTE_HOSTNAME" ]] && continue
  REMOTE_IP4_ADDR="$(ipcalc-ng --no-decorate -o "$REMOTE_HOSTNAME")"
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "Cannot find $REMOTE_HOSTNAME on the Internet: try again."
    continue
  else
    break
  fi
done
echo "Remote host $REMOTE_HOSTNAME is found resolvable as $REMOTE_IP4_ADDR"
echo
echo "And what is its port number on the remote host side?"
read -rp "Remote UDP port number: " -e -i "$REMOTE_PORT" REMOTE_PORT

if [ "$LOCAL_PORT" -ne "$REMOTE_PORT" ]; then
  echo
  echo "WARNING:"
  echo "  Local port $LOCAL_PORT and remote port $REMOTE_PORT are not the same."
  echo "  Some firewall only do UDP connection tracking if the ports are the same."
  echo "  NAT/firewall used by most carrier-grade (cellphone service "
  echo "  provider) NAT/firewall cannot track UDP connection across "
  echo "  disparate ports and may block this different port setup."
fi

echo
echo "INNER TUNNEL"
echo "============"
echo "Choose a network subnet for use by the Wireguard inner tunnel."
echo "enter in 'random' for a truly random but valid subnet selection."
count=0
PROMPT=
# Updating TUNNEL_IP4_ADDR_PREFIX
# Updating TUNNEL_IP4_PREFIX
# Updating TUNNEL_IP4_ADDR_LOCAL
# Updating TUNNEL_IP4_ADDR_REMOTE
while true; do
  read -rp "Enter private/inside/internal IPv4 address/prefix: " -e -i "${PROMPT}" REPLY
  count=$((count + 1))
  if [ "$count" -gt 0 ]; then
    # Give them a clue
    PROMPT="$DEFAULT_PRIVATE_IP4"
  fi
  [[ -z "$REPLY" ]] && continue
  if [ "$REPLY" == 'random' ]; then
    RANDOM_IP4_SUBNET="$(ipcalc-ng --no-decorate -a -r31)"
    TUNNEL_IP4_ADDR_PREFIX="$RANDOM_IP4_SUBNET/31"
    break
  fi
  ADDRSPACE="$(ipcalc-ng --no-decorate --addrspace "$REPLY")"
  ADDRSPACE="${ADDRSPACE//\"//}"
  IP_ADDR_COUNT="$(ipcalc-ng --addresses --no-decorate "$REPLY")"
  if [ "$ADDRSPACE" != "Private Use" ]; then
    echo
    echo "Ummm, your $REPLY is in the '${ADDRSPACE}' class."
    if [ "$count" -lt 1 ]; then
      echo "Need to pick a subnet/prefix from the 'Private Use' class."
      echo "Like or within these 10.0.0.0/8, 172.28.0.0/12, or 192.168.0.0/16."
    fi
    PROMPT="$DEFAULT_PRIVATE_IP4"
  elif [ "$IP_ADDR_COUNT" -lt 2 ]; then
    echo "The minimum starting IP address: $(ipcalc-ng --minaddr --no-decorate "$REPLY")"
    echo "The maximum starting IP address: $(
      ipcalc-ng --maxaddr --no-decorate
      "$REPLY"
    )"
    echo "Total available IP addresses   : $(
      ipcalc-ng --addresses --no-decorate
      "$REPLY"
    )"
    echo "Need a minimum of 2 available IP addresses, pick a bigger prefix."
  else
    TUNNEL_IP4_ADDR_PREFIX=$REPLY
    break
  fi
done
TUNNEL_IP4_ADDR_LOCAL="$(ipcalc-ng --minaddr --no-decorate "$TUNNEL_IP4_ADDR_PREFIX")"
TUNNEL_IP4_ADDR_REMOTE="$(ipcalc-ng --maxaddr --no-decorate "$TUNNEL_IP4_ADDR_PREFIX")"

echo
echo "This Host - INNER TUNNEL"
echo "------------------------"
echo "Inner Tunnel subnet/prefix:       $TUNNEL_IP4_ADDR_PREFIX"
echo "Inner Tunnel local side IP addr:  $TUNNEL_IP4_ADDR_LOCAL"
echo "Inner Tunnel remote side IP addr: $TUNNEL_IP4_ADDR_REMOTE"

# About supporting routed interfaces, we breakdown asking for separate asking
# of route table entries in form of local LANs, public Internet, and tunneled.

# By selecting an address or address/prefix, we can flip on
# /sys/net/ipv4/<netdev-name>/ip_forward on.
# There is no reason to ask for blanket 'ip_forward' ON.
# This is as about surgical as we can do without touching 'ip_forward'
#
# /proc/sys/net/ipv4/all/forwarding -
#    Forces ALL currently active interfaces to start forwarding
#
# /proc/sys/net/ipv4/conf/default/forwarding -
#    Does nothing.  Only impacts newly created interfaces.
#
# /proc/sys/net/ipv4/conf/wg0/forwarding -
#    Network device-specific actually allows it to its
#    own forward packets but ONLY toward other
#    interfaces who ALSO have turned on their own
#    device-specific 'forwarding' on.
#    That logic gets ignored by global '/proc/sys/net/ipv4/forwarding=1'

echo
echo "ROUTING"
echo "======="
# Scan all network interfaces for 'forwarding'
echo "Available but forwardable IPv4 addresses that this local host "
echo "can connect directly to ${TUNNEL_INTF_NAME} with:"

# Print out available Wireguard-able IPv4 interfaces
# do not check /proc/sys/net/ipv4/ip_forwarding
# we use /proc/sys/net/ipv4/conf/$NETDEV/forwarding instead
idx=0
LOCAL_IP4_ADDR_IDX_LIST=
# cycle through each valid non-loopback netdev network devices
while [ $idx -lt ${#NETDEV_NAME_A[*]} ]; do
  echo -n "  netdev ${NETDEV_NAME_A[idx]} interface: "

  # Save /proc/sys/net/ipv4/conf/<netdev-name>/forwarding state
  NETDEV_FORWARDING_A[idx]="$(cat "/proc/sys/net/ipv4/conf/${NETDEV_NAME_A[idx]}/forwarding")"
  if [ "${NETDEV_FORWARDING_A[idx]}" -eq 1 ]; then
    echo "Forwarding ENABLED."

    # Ignore Wireguard "wg0" interface for now
    if [ "${NETDEV_NAME_A[idx]}" != "$TUNNEL_INTF_NAME" ]; then

      # Print out Index/netdev name/subnet
      echo "    Netdev: ${IP4_ADDR_LIST[idx]} ${NETDEV_NAME_A[idx]} is available for Wireguard usage"
      LOCAL_IP4_ADDR_IDX_LIST+="$idx "
    fi
  else
    echo "  Forwarding DISABLED."
  fi
  idx=$((idx + 1))
done

echo "NETDEV_FORWARDING_A: ${NETDEV_FORWARDING_A[*]}"
if [ -z "${NETDEV_FORWARDING_A[*]}" ]; then
  echo "ERROR: $TUNNEL_INTF_NAME"
  exit 16
fi
echo "LOCAL_IP4_ADDR_IDX_LIST: $LOCAL_IP4_ADDR_IDX_LIST"
if [ -z "$LOCAL_IP4_ADDR_IDX_LIST" ]; then
  echo "ERROR: No forwarding IPv4 subnet found; aborted"
  exit 15
fi

# echo "If you don't see the device you want, then turn on 'forwarding'"
# echo "for that device."
# echo "   'echo \"1\" > /proc/sys/net/ipv4/<your-netdev>/forwarding'"

# idx value is continued from previous loop
count=0

# Construct an array of route table
echo "Available outside routes (and their hosts) that can connect directly "
echo "to inside $TUNNEL_INTF_NAME interface:"
ROUTE_TABLE_A=()
# shellcheck disable=SC2207
ROUTE_TABLE_A=($(ip -o route list | awk '{print $1}' | sort -u | sed -e '/default/d' | xargs))
# shellcheck disable=SC2048
for THIS_ROUTE in ${ROUTE_TABLE_A[*]}; do
  echo "  Found subnet route: $THIS_ROUTE"
done

echo
echo "Network interface - ROUTING"
echo "---------------------------"
echo "Going through each network device on this box, we will prompt"
echo "you for each outside route and network interface that the"
echo "inside $TUNNEL_INTF_NAME tunnel device can connect with."
lir_idx=0
for this_idx in $LOCAL_IP4_ADDR_IDX_LIST; do
  echo " Checking netdev: ${NETDEV_NAME_A[this_idx]} (subnet ${IP4_ADDR_PREFIX_LIST[this_idx]})"

  read -rp "  ALL hosts (+ this host) on ${IP4_ADDR_PREFIX_LIST[this_idx]} can connect to $TUNNEL_INTF_NAME (N/y): " REPLY
  [[ -z "$REPLY" ]] && REPLY='n'
  REPLY="$(echo "${REPLY:0:1}" | awk '{ print tolower($1) }')"
  if [ "${REPLY}" == 'y' ]; then
    LOCAL_IP4_ROUTES_A[lir_idx]="${IP4_ADDR_PREFIX_LIST[this_idx]}"
    lir_idx=$((lir_idx + 1))
  else
    read -rp "  ONLY this host ${IP4_ADDR_LIST[this_idx]} can connect to $TUNNEL_INTF_NAME (N/y): " REPLY
    [[ -z "$REPLY" ]] && REPLY='n'
    REPLY="$(echo "${REPLY:0:1}" | awk '{ print tolower($1) }')"
    if [ "${REPLY}" == 'y' ]; then
      LOCAL_IP4_ROUTES_A[lir_idx]="${IP4_ADDR_LIST[this_idx]}/32"
      lir_idx=$((lir_idx + 1))
    else
      read -rp "  What IP address can connect to this host's $TUNNEL_INTF_NAME?: " REPLY
      LOCAL_IP4_ROUTES_A[lir_idx]="$REPLY"
      lir_idx=$((lir_idx + 1))
    fi
  fi
done
# Create a CSV-list of 'ip route' for [Peer]AllowedIPs setting.
X="${LOCAL_IP4_ROUTES_A[*]}"
LOCAL_IP4_ROUTES_LIST="$(echo "${LOCAL_IP4_ROUTES_A[*]}" | xargs | sed -e 's/ /,/g')"
echo
echo "Allowed IPs are: $LOCAL_IP4_ROUTES_LIST"

if [ -z "$LOCAL_IP4_ROUTES_LIST" ]; then
  echo "This is not going to work; there is no routing, "
  echo "no selected routing ... at all!"
  echo "Do it all over again, but this time, do select some "
  echo "connecting subnets to the $TUNNEL_INTF_NAME network device."
  exit 2
fi

function pre_touch() {
  (
    umask 0077
    touch "$1"
  )
}

#   mkdir $OUT_DIR
#  mkdir -p $OUT_DIR/etc/wireguard
#  mkdir -p $OUT_DIR/etc/sysctl
#  mkdir -p $OUT_DIR/etc/shorewall/rules.d

SYSCTL_D_DIRPATH="/etc/sysctl.d"
flex_ckdir "/etc"
flex_ckdir "$SYSCTL_D_DIRPATH"
flex_ckdir "/etc/NetworkManager"

flex_ckdir "$DEFAULT_EXTENDED_SYSCONFDIR"
flex_ckdir "$NETWORKMANAGER_CONFD_DIRSPEC"

flex_ckdir "$WG_DIRPATH"
flex_mkdir "${WG_DIRPATH}/scripts"

if [ -n "$SHOREWALL_BIN" ]; then
  flex_ckdir "/etc/shorewall"
  flex_mkdir "/etc/shorewall/rules.d"
fi

# Create key-pair
WG_KEY_PUB_FILESPEC=/etc/wireguard/${HOSTNAME}-vpn-server-public.key
WG_KEY_PRIV_FILESPEC=/etc/wireguard/${HOSTNAME}-vpn-server-private.key
WG_KEY_PRESHARED_FILESPEC=/etc/wireguard/${HOSTNAME}-vpn-server-preshared.key
BR_WG_KEY_PUB_FILESPEC="${BUILDROOT}${CHROOT_DIR}/$WG_KEY_PUB_FILESPEC"
BR_WG_KEY_PRIV_FILESPEC="${BUILDROOT}${CHROOT_DIR}/$WG_KEY_PRIV_FILESPEC"
BR_WG_KEY_PRESHARED_FILESPEC="${BUILDROOT}${CHROOT_DIR}/$WG_KEY_PRESHARED_FILESPEC"

# Protect the keys
# prepare file then lock down file-permission-wise before writing
pre_touch "$BR_WG_KEY_PUB_FILESPEC"
flex_chown root:root "$WG_KEY_PUB_FILESPEC"
flex_chmod 0755 "$WG_KEY_PUB_FILESPEC"

# prepare file then lock down file-permission-wise before writing
pre_touch "$BR_WG_KEY_PRIV_FILESPEC"
flex_chown root:root "$WG_KEY_PRIV_FILESPEC"
flex_chmod 0700 "$WG_KEY_PRIV_FILESPEC"

# Private key never leaves the local host that it gets generated on
wg genkey | tee "$BR_WG_KEY_PRIV_FILESPEC" | wg pubkey | tee "$BR_WG_KEY_PUB_FILESPEC" >/dev/null

# prepare file then lock down file-permission-wise before writing
pre_touch "$BR_WG_KEY_PRESHARED_FILESPEC"
flex_chown root:root "$WG_KEY_PRESHARED_FILESPEC"
flex_chmod 0700 "$WG_KEY_PRESHARED_FILESPEC"

# Preshared key are meant to be copied to remote (peer) host(s)
wg genpsk | tee "$BR_WG_KEY_PRESHARED_FILESPEC" >/dev/null

# Create GLOBAL settings for Wireguard
# We COULD put this hosts private key globally here, but we would not.
GLOBAL_CONFIG_FILENAME="wireguard.conf"
GLOBAL_CONFIG_DIRPATH="$WG_DIRPATH"
GLOBAL_CONFIG_FILESPEC="${GLOBAL_CONFIG_DIRPATH}/${GLOBAL_CONFIG_FILENAME}"

pre_touch "${BUILDROOT}${CHROOT_DIR}/$GLOBAL_CONFIG_FILESPEC"
flex_chown root:root "$GLOBAL_CONFIG_FILESPEC"
flex_chmod 0700 "$GLOBAL_CONFIG_FILESPEC"

echo "Creating ${GLOBAL_CONFIG_FILESPEC} ..."
cat << GLOBAL_WG_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$GLOBAL_CONFIG_FILESPEC" > /dev/null
#
# File: ${GLOBAL_CONFIG_FILENAME}
# Path: ${GLOBAL_CONFIG_DIRPATH}
# OS type: ${OSTYPE}
# Title: WireGuard GLOBAL configuration
# Creator: ${PRG_NAME}
# Date: ${DATETS_NOW}

[Interface]

# 'Address' is the only setting that 'wg' CLI cannot set.
# Linux use 'ip link add ${TUNNEL_INTF_NAME} type wireshark ip <address>' to set that
Address = ${TUNNEL_IP4_ADDR_LOCAL}

# In this $GLOBAL_CONFIG_FILENAME file, the following private key
# is used for all WireGuard interfaces/subnets.
# Use of this global option is not common.
# Use of this global option is not recommended.
#
# CLI: 'wg set ${TUNNEL_INTF_NAME} private-key <filespec>'
# CLI: 'wg set ${TUNNEL_INTF_NAME} private-key < ${WG_KEY_PRIV_FILESPEC}'
###PrivateKey=

# And this global ListenPort setting here is also used for
# all connections unless overridden by 'ListenPort' in
# its interface-specific config files.
# CLI: 'wg set ${TUNNEL_INTF_NAME} listen-port <port>'
ListenPort = ${LOCAL_PORT}

# Add firewall mark for iptables/nftable usage
# CLI: 'wg set ${TUNNEL_INTF_NAME} fwmark <32bit-integer|32bit-hex-number>'
#FwMark=off
#FwMark=0
#FwMark=MAX_INT32
#FwMark=0xffff

GLOBAL_WG_EOF

# might put a loop in for more [Peer], but not this time
# take the technical debt (TD) in for now
cat << GLOBAL_WG_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}/$GLOBAL_CONFIG_FILESPEC" > /dev/null
[Peer]
# Most global [Peer] setting are done by their respective interface-specific
# ${TUNNEL_INTF_NAME}.conf configuration file.
#
# Endpoint= must always have a colon port notation after hostname or IP address
# DNS resolution of hostname is done through /etc/resolv.conf
#
# CLI: wg set ${TUNNEL_INTF_NAME} endpoint <ip>:<port>
#Endpoint=fqdn.tld:51820
#Endpoint=private-vpn.example.invalid:51820
#Endpoint=123.123.123.123:51820
#Endpoint=123.123.123.123:51820
#Endpoint=[fda2:1:1::1]:51820

# CLI: 'wg set ${TUNNEL_INTF_NAME} peer <base64-key>'
#PublicKey=<base64-key>

# 0.0.0.0/0 means everything in the 'ip route show' is reachable
# from the inner tunnel $TUNNEL_INTF_NAME network interface.
# CLI: 'wg set ${TUNNEL_INTF_NAME} allowed-ips <ip1>/<cidr1> [, <ip2>/<cidr2> ... ]'
#AllowedIPs=123.123.123.123/32

# CLI: 'wg set ${TUNNEL_INTF_NAME} persistent-keepalive <seconds>'
#PersistentKeepalive=3600

# PresharedKey can be left blank here as 'wg-quick' can evoke
# the 'PreUp' to execute 'wg set preshared-key' to read its key
# from a file then directly load into the network device.
# CLI: 'wg set ${TUNNEL_INTF_NAME} preshared-key <filespec>'
# CLI: 'wg set ${TUNNEL_INTF_NAME} preshared-key < ${WG_KEY_PRESHARED_FILESPEC}'
#PresharedKey=<key>
GLOBAL_WG_EOF

# Create the interface-specific (non-Global) WireGuard configuration file
CONFIG_FILENAME="${TUNNEL_INTF_NAME}.conf"
CONFIG_FILEPATH="$WG_DIRPATH"
CONFIG_FILESPEC="${CONFIG_FILEPATH}/${CONFIG_FILENAME}"
BR_CONFIG_FILESPEC="${BUILDROOT}${CHROOT_DIR}${CONFIG_FILEPATH}/${CONFIG_FILENAME}"

# prepare file then lock down file-permission-wise before writing
pre_touch "${BR_CONFIG_FILESPEC}"
flex_chown root:root "$CONFIG_FILESPEC"
flex_chmod 0700 "$CONFIG_FILESPEC"

echo "Creating ${CONFIG_FILESPEC} ..."
cat << WG_EOF | tee "${BR_CONFIG_FILESPEC}" > /dev/null
#
# File: ${CONFIG_FILENAME}
# Path: ${CONFIG_FILEPATH}
# OS type: ${OSTYPE}
# Title: Interface-specific aspect of WireGuard configuration
# Interface: $TUNNEL_INTF_NAME
# Creator: ${PRG_NAME}
# Date: ${DATETS_NOW}

# [Interface] that supports 'wg', 'wg-quick', and NetworkManager 'nmcli' utilities
[Interface]

# 'Address' is the only setting that 'wg' CLI cannot set.
# The following can be equivalence:
#   'ip link add $TUNNEL_INTF_NAME type wireguard'
#   'ip address 10.1.1.1/31 dev $TUNNEL_INTF_NAME'
Address = ${TUNNEL_IP4_ADDR_PREFIX}

# CLI: 'wg set ${TUNNEL_INTF_NAME} listen-port <port>'
ListenPort = ${LOCAL_PORT}

# In this $CONFIG_FILENAME, the following private key
# is used for this specific WireGuard interface/subnet.
# PrivateKey can be commented out as 'wg-quick' can updates that:
# CLI: 'wg set ${TUNNEL_INTF_NAME} private-key < ${WG_KEY_PRIV_FILESPEC}'
# CLI: 'wg set ${TUNNEL_INTF_NAME} private-key <filespec>'
# PrivateKey = \$(cat "/${WG_KEY_PRIV_FILESPEC}")

WG_EOF

# append the OS-specific configuration
if [[ "$OSTYPE" == *"linux"* ]] ||
  [[ "$OSTYPE" == *"darwin"* ]] ||
  [[ "$OSTYPE" == *"freebsd"* ]] ||
  [[ "$OSTYPE" == *"openbsd"* ]] ||
  [[ "$OSTYPE" == *"darwin"* ]] ||
  [[ "$OSTYPE" == *"cygwin"* ]]; then
  # Cannot do BSD-check due to lack of 'ip' (and other) utility
  cat << WG0_EOF | tee -a "${BR_CONFIG_FILESPEC}" > /dev/null
#[Interface]  # wg-quick OS-specific subsection

# Following OS-specific '$OSTYPE' settings are maintained
# by 'wg-quick', not 'wg'.
#
# OS-specific are preserved and maintained across changes
# by wg-quick/linux.bash tool.

# CLI: 'ip link $TUNNEL_INTF_NAME mtu <mtu-size>'
#MTU=2200

# DNS is useful to assist with resolution of hostname found in [Peer]Endpoint
#DNS=8.8.8.8,9.9.9.9

#Table=

# Execute scripts before the wg interface goes up
#PreUp=/etc/wireguard/scripts/xxxx.sh

# Execute scripts before the wg interface goes down
PreDown= wg set %i private-key 0
PreDown= wg set %i preshared-key 0

# Execute scripts AFTER the wg interface goes up
#PostUp=/etc/wireguard/scripts/xxxx.sh
PostUp = wg set %i private-key ${WG_KEY_PRIV_FILESPEC}
PostUp = wg set %i preshared-key ${WG_KEY_PRIV_FILESPEC}

# Execute scripts AFTER the wg interface goes down
#PostDown=/etc/wireguard/scripts/xxxx.sh

# Saves not only the 'wg showconf' portion but additionally the
# OS-specific settings in wg0.conf used and mainted
# by the 'wg-quick' utility.
#SaveConfig=true
#SaveConfig=true

WG0_EOF
fi

# append the [Peer] section
cat << WG_EOF | tee -a "${BR_CONFIG_FILESPEC}" > /dev/null
[Peer]

# CLI: wg set wg0 endpoint <ip>:<port>
Endpoint = ${REMOTE_HOSTNAME}:${REMOTE_PORT}

# CLI: 'wg set wg0 peer <base64-key>'
PublicKey = ${BR_WG_KEY_PUB_FILESPEC}

# PresharedKey can be left blank here as 'wg-quick' can evoke
# the 'PreUp' to execute 'wg set preshared-key' to read its key
# from a file then directly load into the network device.
# CLI: 'wg set wg0 preshared-key <filespec>'
# CLI: 'wg set wg0 preshared-key < ${WG_KEY_PRESHARED_FILESPEC}'
PresharedKey =

# CLI: 'wg set wg0 persistent-keepalive <seconds>'
PersistentKeepalive = 3600

# CLI: 'wg set wg0 allowed-ips <ip1>/<cidr1> [, <ip2>/<cidr2> ... ]'
AllowedIPs=${LOCAL_IP4_ROUTES_LIST}

WG_EOF


# create /etc/sysctl.d/10-ip_router_forwarding_state_{TUNNEL_INTF_NAME}.conf
SYSCTL_IPFWD_NETDEV_FILENAME="11-ip_router_forwarding_state_${TUNNEL_INTF_NAME}.conf"
SYSCTL_D_DIRPATH="/etc/sysctl.d"
SYSCTL_IPFWD_NETDEV_FILESPEC="${SYSCTL_D_DIRPATH}/$SYSCTL_IPFWD_NETDEV_FILENAME"
BR_SYSCTL_IPFWD_NETDEV_FILESPEC="${BUILDROOT}${CHROOT_DIR}${SYSCTL_IPFWD_NETDEV_FILESPEC}"
cat << SYSCTL_D_EOF | tee -a "${BR_SYSCTL_IPFWD_NETDEV_FILESPEC}" > /dev/null
#
# File: ${SYSCTL_IPFWD_NETDEV_FILENAME}
# Path: ${SYSCTL_D_DIRPATH}
# Creation: $DATETS_NOW
# Creator : $PRG_NAME
# Title: controls IP router forwarding for netdev $TUNNEL_INTF_NAME interface
# Description:
# Reference:
#  - KVM Network Performance - Best Practices and Tuning Recommendations
#      https://www.ibm.com/downloads/cas/ZVJGQX8E
#  - https://www.uperf.org
#
# conf/${TUNNEL_INTF_NAME}/forwarding - BOOLEAN
#    Enable IP forwarding to netdev interfaces.
#
#    IPv4 and IPv6 work differently here; e.g. netfilter must be used
#    to control which interfaces may forward packets and which not.
#
#    See below for details.
#

# conf/${TUNNEL_INTF_NAME}/*:
#  Change the netdev ${TUNNEL_INTF_NAME} interface-specific default settings.

net.ipv4.conf.${TUNNEL_INTF_NAME}.forwarding=1
net.ipv6.conf.${TUNNEL_INTF_NAME}.forwarding=1

SYSCTL_D_EOF
flex_chown root:root "$SYSCTL_IPFWD_NETDEV_FILESPEC"
flex_chmod 0750 "$SYSCTL_IPFWD_NETDEV_FILESPEC"

save_params

echo "All done."
echo "Check out all the newly created configuration files"
echo "in $BR_WG_DIRSPEC"
