#!/bin/bash
# File: 405-nm-NetworkManager-own-dhcp-client-resolver-disable.sh
# Title: Prevent NetworkManager's own DHCP client from updating /etc/resolv.conf
#
# NOTE: This does nothing toward other DHCP clients (outside of Network Manager
#       own builtin DHCP client).  This script is often useful for use with
#       ISC DHCP (dhclient) client package.

echo "Disable NetworkManager built-in DHCP client from updating /etc/resolv.conf"
echo

source ./maintainer-NetworkManager.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-NetworkManager-conf.d-dhcp-client-resolver.sh"

flex_mkdir "$NETWORKMANAGER_CONFD_DIRSPEC"

echo "Disabled DHCP-driven DNS update"
FILENAME="no-dhcp-dns-update-to-resolver.conf"
FILEPATH="$NETWORKMANAGER_CONFD_DIRSPEC"
FILESPEC="$FILEPATH/$FILENAME"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$FILESPEC..."
cat << NM_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$FILESPEC" > /dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Prevent NetworkManager's own DHCP client from updating /etc/resolv.conf
#
# NOTE: This does nothing toward other DHCP clients (outside of Network Manager'
#       own builtin DHCP client).  This script is often useful for use with
#       ISC DHCP (dhclient) client package.
#
# Creator: $(basename "$0")
# Date: $(date)
#

[main]

# 'dns='
# Set the DNS processing mode.
#
# If the key is unspecified, default is used, unless
# /etc/resolv.conf is a symlink to
# /run/systemd/resolve/stub-resolv.conf,
# /run/systemd/resolve/resolv.conf,
# /lib/systemd/resolv.conf or
# /usr/lib/systemd/resolv.conf.
# In that case, systemd-resolved is chosen automatically.
#
# 'default': NetworkManager will update /etc/resolv.conf
# to reflect the nameservers provided by currently
# active connections. The rc-manager setting (below)
# controls how this is done.
#
# 'dnsmasq': NetworkManager will run dnsmasq as a local
# caching nameserver, using "Conditional Forwarding" if
# you are connected to a VPN, and then update resolv.conf
# to point to the local nameserver. It is possible to
# pass custom options to the dnsmasq instance by adding
# them to files in the "/etc/NetworkManager/dnsmasq.d/"
# directory. Note that when multiple upstream servers
# are available, dnsmasq will initially contact them in
# parallel and then use the fastest to respond, probing
# again other servers after some time. This behavior
# can be modified passing the 'all-servers' or
# 'strict-order' options to dnsmasq (see the
# 'NetworkManager.conf(5)' manual page for more details).
#
# 'systemd-resolved': NetworkManager will push the DNS
# configuration to systemd-resolved
#
# 'unbound': NetworkManager will talk to unbound and
# dnssec-triggerd, using "Conditional Forwarding" with
# DNSSEC support. /etc/resolv.conf will be managed by
# dnssec-trigger daemon.
#
# 'none': NetworkManager will not modify resolv.conf.
# This implies rc-manager unmanaged
#
# Note that the plugins dnsmasq, systemd-resolved and
# unbound are caching local nameservers. Hence, when
# NetworkManager writes
# /run/NetworkManager/resolv.conf and /etc/resolv.conf
# (according to rc-manager setting below), the name
# server there will be localhost only. NetworkManager
# also writes a file
# /run/NetworkManager/no-stub-resolv.conf that
# contains the original name servers pushed to the
# DNS plugin.
#
# When using dnsmasq and systemd-resolved
# per-connection added dns servers will always be
# queried using the device the connection has been
# activated on.

dns=none

NM_CONF
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to create ${BUILDROOT}${CHROOT_DIR}/$FILESPEC; error $retsts"
  exit $retsts
fi
flex_chown root:root "$FILESPEC"
flex_chmod 0640 "$FILESPEC"

echo
echo "Done."
