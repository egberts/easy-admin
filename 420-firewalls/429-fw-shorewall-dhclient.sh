#!/bin/bash
# File: 429-fw-shorewall-dhclient.sh
# Title: Configure files between Shorewall and ISC dhclient
#
# Description:
#   DHCP client enter hook for `shorewall reload`
#
#   This event will occur only if its interface subnet has changed
#   as noticed ONLY by this dhclient daemon, such as
#   receiving DHCP-RELEASE, DHCP-BIND (IP subnet change), or
#   DHCP-RENEW message.
#
#   Does not cover scenarios where Ethernet cabling got disconnected
#   from its RG-45 connector or remote side goes down.
#

DHCLIENT_ENTER_HOOK_SHOREWALL=/etc/dhcp/dhclient-exit-hooks.d/shorewall

echo "Installing Shorewall-dhclient settings (may ask for sudo password)..."
echo

BUILDROOT="${BUILDROOT:-build}"

source ./maintainer-fw-shorewall.sh
if [ "${BUILDROOT:0:1}" == '/' ]; then
  FILE_SETTING_PERFORM='true'
fi

flex_ckdir /etc
flex_ckdir /etc/dhcp
flex_ckdir /etc/dhcp/dhclient-exit-hooks.d

# check for existing dynamic IP interface (as a DHCP client)
# if no dynamic IP interface, error and exit
ANY_DYN_IP="$(ip -o addr show | grep dynamic | awk '{print $9}')"
if [ "$ANY_DYN_IP" != "dynamic" ]; then
  echo "No dynamic IP netdev found.  Aborted."
  exit 3
fi
DYN_NETDEV="$(ip -o addr show | grep dynamic | awk '{print $2}')"
if [ "$(echo "$DYN_NETDEV" | wc -w)" -gt 1 ]; then
  echo "This script does not work on multiple dynamic netdev interfaces."
  exit 3
fi

# Checking if Shorewall is installed
# 'which' is too-Debian-specific
# 'command -v' doesn't work if binary has restricted file permissions
# 'whereis -b' is our cup-of-tea.
SHOREWALL_EXIST="$(whereis -b shorewall 2>/dev/null | awk '{ print $2 }')"
if [ -z "${SHOREWALL_EXIST}" ]; then
  echo "Shorewall does not exist"
  exit 9
fi

# check if dhclient is installed
DHCLIENT_EXIST="$(whereis -b dhclient | awk '{ print $2 }')"
if [ -z "${DHCLIENT_EXIST}" ]; then
  echo "dhclient does not exist"
  exit 9
fi

DATE="$(date)"
echo "Creating ${BUILDROOT}${DHCLIENT_ENTER_HOOK_SHOREWALL} file ..."
cat << SH_EOF > "${BUILDROOT}$DHCLIENT_ENTER_HOOK_SHOREWALL"
#
# File: ${DHCLIENT_ENTER_HOOK_SHOREWALL}
# Title: DHCP client enter hook for 'shorewall reload'
# Created: ${DATE}
# Created by: $0
# Description:
#   This event will occur only if its interface subnet has changed
#   as noticed ONLY by this dhclient daemon, such as
#   receiving DHCP-RELEASE, DHCP-BIND (IP subnet change), or
#   DHCP-RENEW message.
#
#   Does not cover scenarios where Ethernet cabling got disconnected
#   from its RG-45 connector or remote side goes down.

DHCLIENT_PHY_INTF=$DYN_NETDEV

# Dynamic settings that ISC DHCP server will pass on to this
# script via shell environment variables
#
reason=\$reason
interface=\$interface
medium=\$medium
alias_ip_address=\$alias_ip_address
new_ip_address=\$new_ip_address
new_routers=\$new_routers
new_static_routes=\$new_static_routes
new_subnet_mask=\$new_subnet_mask
new_domain_name=\$new_domain_name
new_domain_name_servers=\$new_domain_name_servers
routers=\$routers

logger "dhclient-enter-hooks.d/shorewall: started: reason: \$reason"

firewall_setup() {

  case \$reason in

   BOUND|REBIND|REBOOT|FAIL|RELEASE|STOP)

     if [ "\${interface}" != "\${DHCLIENT_PHY_INTF}" ]; then
       return
     fi

     # dhclient environment variables defined in dhclient-script(8) man page
     logger "shorewall refresh at \$interface due to DHCP \$reason"
     logger "shorewall ... medium: \$medium alias_ip: \$alias_ip_address routers: \$routers"
     logger "shorewall ... new_ip: \$new_ip_address new_subnet_mask: \$new_subnet_mask"
     logger "shorewall ... new_domain: \$new_domain_name new_dns_servers: \$new_domain_name_servers"
     logger "shorewall ... new_routers: \$new_routers new_static_routes: \$new_static_routes"
    ;;
   *)
     return
    ;;
  esac

  umask 022

  # reload the shorewall server
  [ -x /sbin/shorewall ] && /sbin/shorewall reload

}

firewall_setup
RETSTS=\$?
logger "dhclient-enter-hooks.d/shorewall: exiting RETSTS \${RETSTS}"
exit \$RETSTS

SH_EOF

flex_chown root:root $DHCLIENT_ENTER_HOOK_SHOREWALL
flex_chmod 0640 $DHCLIENT_ENTER_HOOK_SHOREWALL

echo ""
echo "Done."
