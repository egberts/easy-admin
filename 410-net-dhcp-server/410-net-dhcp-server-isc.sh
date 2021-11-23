#!/bin/bash
# File: 410-net-dhcp-server-isc.sh
# Title: Configure ISC DHCP Server
#
# DESIGN:
#   Determine nameservers by resolve.conf* (if gateway-firewalled, used this DNS
#   Determine log server(s) by port-probe
#   Determine NTP server(s) by port-probe (if gateway-firewalled, use this NTP)
#   Determine WWW server(s) on this server (prompt if not found)
#   Prompts list of subnets for DHCP to serve
#     obtain  list of interfaces from subnets
#     - any duplicate interfaces mandates 'shared-network' group
#   For each subnet
#     Prompts for IP adddress range, start/end
#     Determine gateway IP
#     Prompt for log server IP (show nested-default)
#     Prompt for DNS nameservers (show nested-default)
#
#   Detect for esoteric settings
#     1. Nintendo 3DS?
#     2. Bad ActionTEC hostnames
#     3. local-pac-server (used by WPAD)
#     4. Detects for ISC Bind9 update policy for zone updates
#     5. Somehow figure out who ise the zone master; DNS or DHCP
#     6. Somehow decided who sets the hostname; end-user or sysadmin
#
# Envvars
#   BUILDROOT - where to output the files into (default $PWD/build)
#   CHROOT_DIR - where to output files get installed into (default /)
#
# System Files impacted:
#   Modified: none
#   Created: none

echo "ISC DHCP Server configuration"
echo ""
source dhcp-isc-common.sh

DHCPD_DIRSPEC="$sysconfdir"

echo "CHROOT_DIR: $CHROOT_DIR"
echo "BUILDROOT: $BUILDROOT"
flex_mkdir "$DHCPD_DIRSPEC"
mkdir "$BUILD_TMP"

DHCPD_CONF_FILENAME="dhcpd.conf"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: DhCP IPv4 configuration file

include "${DHCPD_DIRSPEC}/dhcpd.conf.options";
include "${DHCPD_DIRSPEC}/dhcpd.conf.pools";
include "${DHCPD_DIRSPEC}/dhcpd.conf.zones";
include "${DHCPD_DIRSPEC}/dhcpd.conf.reserved";

DHCPD_CONF_EOF

# TODO: Prompt for server-identifier?
# TODO: Prompt for server-name?
DHCPD_CONF_FILENAME="dhcpd.conf.options"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server Options configuration file

authoritative;
local-port 67;
### server-identifier my_gateway;
### server-name my_gateway;

# ################
# Client Control
# ################

# Host  declarations  can  match client messages based on the DHCP Client
#    Identifier option or based on the client's network  hardware  type  and
#    MAC  address.   If  the  MAC address is used, the host declaration will
#    match any client with that MAC address - even  clients  with  different
#    client identifiers.  This doesn't normally happen, but is possible when
#    one computer has more than one operating system installed on it  -  for
#    example, Microsoft Windows and NetBSD or Linux.
#
# The duplicates flag tells the DHCP server that if a request is received
#    from a client that matches the MAC address of a host  declaration,  any
#    other  leases  matching  that  MAC  address  should be discarded by the
#    server, even if the UID is not the same.  This is a  violation  of  the
#    DHCP  protocol, but can prevent clients whose client identifiers change
#    regularly from holding many leases at the same time.  By  default,  du‐
#    plicates are allowed.
# deny duplicates;

# The  DHCPDECLINE  message  is used by DHCP clients to indicate that the
#    lease the server has offered is not valid.  When the server receives  a
#    DHCPDECLINE  for  a  particular  address, it normally abandons that ad‐
#    dress, assuming that some unauthorized system is  using  it.   Unfortu‐
#    nately,  a  malicious  or buggy client can, using DHCPDECLINE messages,
#    completely exhaust the DHCP server's allocation pool.  The server  will
#    eventually  reclaim  these  leases, but not while the client is running
#    through the pool. This may cause serious thrashing in the DNS,  and  it
#    will also cause the DHCP server to forget old DHCP client address allo‐
#    cations.
#
#    The declines flag tells the DHCP server whether or not to honor DHCPDE‐
#    CLINE  messages.  If it is set to deny or ignore in a particular scope,
#    the DHCP server will not respond to DHCPDECLINE messages.
#
# The declines flag is only supported by DHCPv4 servers.  Given the large
#    IPv6  address space and the internal limits imposed by the server's ad‐
#    dress generation mechanism we don't think it is  necessary  for  DHCPv6
#    servers at this time.
#
# Currently, abandoned IPv6 addresses are reclaimed in one of two ways:
#    a) Client renews a specific address:
#       If a client using a given DUID submits a DHCP REQUEST containing
#       the last address abandoned by that DUID, the address will be
#       reassigned to that client.
#
#    b) Upon the second restart following an address abandonment.  When
#       an address is abandoned it is both recorded as such in the lease
#       file and retained as abandoned in server memory until the server
#       is restarted. Upon restart, the server will process the lease file
#       and all addresses whose last known state is abandoned will be
#       retained as such in memory but not rewritten to the lease file.
#       This means that a subsequent restart of the server will not see the
#       abandoned addresses in the lease file and therefore have no record
#       of them as abandoned in memory and as such perceive them as free
#       for assignment.
#
#    The total number addresses in a pool, available for a given DUID value,
#    is internally limited by the server's address generation mechanism.  If
#    through  mistaken  configuration,  multiple  clients are using the same
#    DUID they will competing for the same addresses causing the  server  to
#    reach  this internal limit rather quickly.  The internal limit isolates
#    this type of activity such that address  range  is  not  exhausted  for
#    other  DUID  values.  The appearance of the following error log, can be
#    an indication of this condition:
#
#        "Best match for DUID <XX> is an abandoned address, This may be a
#        result of multiple clients attempting to use this DUID"
#
#        where <XX> is an actual DUID value depicted as colon separated
#        string of bytes in hexadecimal values.
#
# TODO: Decline any client-suggested RR record values.  We decide everything
deny declines;

# really, one-lease-per-client is from old days of having expensive lone eth0
###########one-lease-per-client on;

# The  do-forward-updates  statement instructs the DHCP server as to
#    whether it should attempt to update a DHCP client´s A record  when
#    the  client acquires or renews a lease.  This statement has no ef‐
#    fect unless DNS updates are enabled.  Forward updates are  enabled
#    by default.  If this statement is used to disable forward updates,
#    the DHCP server will  never  attempt  to  update  the  client´s  A
#    record,  and  will  only  ever  attempt to update the client´s PTR
#    record if the client supplies an FQDN that should be placed in the
#    PTR record using the fqdn option.  If forward updates are enabled,
#    the DHCP server will still honor the setting of the client-updates
#    flag.
# do-forward-updates on;
# SLE: Our DNS is the master, DHCP server/client must obey.
do-forward-updates false;

# If the update-conflict-detection parameter is true, the server
#   will perform standard DHCID multiple-client, one-name conflict
#   detection.  If the parameter has been set false, the server
#   will skip this check and instead simply tear down any previous
#   bindings to install the new binding without question.  The
#   default is true.
# If update-conflict-detection is true, the dhcp-server
#    updates the dns-server with the A, PTR and TXT record.
# If update-conflict-detection is false, the dhcp-server
#    updates the dns-server with only the A and PTR record.
update-conflict-detection true;

# The  update-static-leases  flag,  if  enabled,  causes  the DHCP
#    server to do DNS updates for clients even if those  clients  are
#    being  assigned their IP address using a fixed-address or fixed-
#    address6 statement - that is, the client is being given a static
#    assignment.   It  is not recommended because the DHCP server has
#    no way to tell that the update has been done, and therefore will
#    not  delete  the record when it is not in use.  Also, the server
#    must attempt the update each time the client renews  its  lease,
#    which  could  have  a significant performance impact in environ‐
#    ments that place heavy demands on the DHCP server.  This feature
#    is  supported for both DHCPv4 and DHCPv6, and update modes stan‐
#    dard or interim. It is disabled by default.
#
# Tells the DHCP server to do DNS updates even for clients with
# "static leases"; that is, clients who receive a DHCP address
# that you specifically assign them based on MAC address.
# update-static-leases   off;
update-static-leases   false;

# The client-updates flag tells the DHCP server whether or not  to  honor
#    the  client's  intention to do its own update of its A record.  See the
#    documentation under the heading THE DNS UPDATE SCHEME for details.
#
# Default to ignore any updates by DHCP clients
# Permission are relaxed within each subnet/pool
ignore client-updates;

always-broadcast false;

#  if flag = true this parameter directs the DHCP server to lookup the hostname corresponding to the assigned IP address and set the resolved hostname in the DHCP hostname option (12). In this scenario the DNS reverse zone would have been pre-populated with hostnames corresponding to IP addresses corresponding to the scope on which this parameter is set (e.g. subnet). If flag = false no lookup is performed (default).
get-lease-hostnames true;


# 'use-host-decl-names on' - Tells the DHCP server to tell
# static-mapped clients what their hostname is via the
# "hostname" option inside the DHCP response.

use-host-decl-names on;

ddns-update-style interim;

ping-check on;
ping-timeout 3;

##########################
# Lease Authority
##########################
# default-lease-time - Set how log the DHCP leases are good for. This
# is the maximum time a client will go before it asks for a new
# address. This option can be set longer or shorter to taste;
# for a small home LAN, it doesn't make much difference what it's set to.
# default-lease-time 1814400; #21 days
# max-lease-time 1814400; #21 days
default-lease-time 14400; # 4 hours
max-lease-time 28800; # 8 hours

# If the  update-optimization  parameter  is  false  for  a  given
#    client,  the  server  will  attempt a DNS update for that client
#    each time the client renews its lease, rather than only attempt‐
#    ing  an update when it appears to be necessary.  This will allow
#    the DNS to heal from database inconsistencies more  easily,  but
#    the  cost is that the DHCP server must do many more DNS updates.
#    We recommend leaving this option enabled, which is the  default.
#    If  this parameter is not specified, or is true, the DHCP server
#    will only update when the client information changes, the client
#    gets a different lease, or the client's lease expires.
update-optimization true;


option local-pac-server code 252 = text;
log-facility local7;

# Key for updating the internal DNS zone
key DDNS_UPDATER {
    secret aaaaaaaaaaaaaaaaaaaaaa==;
    algorithm hmac-md5;
    }

#
# This will help with Nintendo 3DS attach to network
# due to faulty firmware of having its hostname with a space betwen
# two words ("Nintendo 3DS").
if (option host-name ~= "Nintendo 3DS") {
   ddns-hostname = concat ("Nintendo3DS",
                           binary-to-ascii (16, 8, "x",
                                            substring (hardware, 1, 6)));
   log(concat("Changing hostname1: ",
              option host-name, " into ", ddns-hostname));
}

if (option host-name ~= "(Nintendo 3DS)") {
   ddns-hostname = concat("Nintendo3DS",
                          binary-to-ascii(16, 8, "x",
                                          substring (hardware, 1, 6)));
   log(concat("Changing hostname2: ",
               option host-name, " into ", ddns-hostname));
}

# Workaround to Juniper Gateway's custom DHCP server used by "Big ISPs"

#if (not (option host-name ~= "Wireless_Broadband_Router")) {
#    if (not (option host-name ~= "[A-Za-z0-9][A-Za-z0-9\-_]+[A-Za-z0-9]")) {
#        set newName = concat("host-", binary-to-ascii(16, 8, "", substring(hardware, 1, 6)));
#        log(concat("Changing invalid hostname: ", option host-name, " into ", newName));
#   ddns-hostname = newName;
#    }
#}


class "dmz2" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}
class "3DS" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}
class "iPod" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}
class "kids" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}
class "DMZ" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}
class "green" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}
class "white" {
    # match hardware;
    match pick-first-value (option dhcp-client-identifier, hardware);
}

DHCPD_CONF_EOF


DHCPD_CONF_FILENAME="dhcpd.conf.pool.10.22.0-vir"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server Pool configuration file for Virtual-Net

# vir
subnet 10.22.0.0 netmask 255.255.255.0
{
    authoritative;

    server-identifier 10.22.1.1;
    server-name dhcp-server-10;

    allow unknown-clients;
    allow client-updates;

    option log-servers 10.22.0.1;
    option domain-name-servers 10.22.0.1;
    option local-pac-server "http://10.22.0.1:80/wpad-90.dat";

    # log-facility local7;
}
DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.pool.172.17-docker"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server Pool configuration file for Docker-Net
#

# entire Ethernet interface
subnet 172.17.0.0  netmask 255.255.0.0
{
    # authoritative - Tells the DHCP server that it is to act as the one
    # true DHCP server for the scopes it's configured to understand, by
    # sending out DHCPNAK (DHCP-no-acknowledge) packets to
    # misconfigured DHCP clients.

    server-identifier 172.17.0.1;
    server-name dhcp-server-172-17;


    # 'allow unknown-clients' - Tells the DHCP server to assign
    # addresses to clients without static host declarations,
    # which is almost certainly something you want to do.
    # Otherwise, only clients you've manually given addresses to
    # later in the file will get DHCP assignments.
    deny unknown-clients;

    ignore client-updates;
    option log-servers 172.17.0.1;
    # do not use option domain-search in DMZ
    # do not use option domain-name in DMZ
    option subnet-mask 255.255.0.0;
    option routers 172.17.0.1;
    option ntp-servers 172.17.0.1;

    option domain-name "homenet";
    option domain-search "homenet";
    option domain-name-servers 172.17.0.1;
# log-facility local7;


    # ddns-updates - This line enables global dynamic updating. You can
    # also set this per-scope, in case you wanted some scopes to
    # be able to do updating and not others
    ddns-updates off;

    pool
    {
        allow unknown-clients;
        range 172.17.0.2 172.17.0.20;
        ignore client-updates;
        option domain-name "homenet";
        option broadcast-address 172.17.255.255;
        option subnet-mask 255.255.0.0;
        ddns-updates off;
    }

}
DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.pool.192.168.12-resinet"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server Pool configuration file for Residential-Net
#
#

shared-network "resinet" {

  # SERVER CONTROL
  # authoritative - Tells the DHCP server that it is to act as the one
  # true DHCP server for the scopes it's configured to understand, by
  # sending out DHCPNAK (DHCP-no-acknowledge) packets to
  # misconfigured DHCP clients.
  authoritative;

  server-identifier 192.168.12.1;
  server-name dhcp-server-172;

  # deny bootp;
  # deny duplicates;   # static and dynamic?
  # deny booting;

  option log-servers 192.168.12.1;
  option subnet-mask 255.255.252.0;
  option routers 192.168.12.1;
  option ntp-servers 192.168.12.1;
  option www-server 192.168.12.1;
  option local-pac-server "http://wpad.homenet:80/wpad-90.dat";
  # option wpad "\n";

  option domain-name "homenet";
  option domain-name-servers 192.168.12.1;
# log-facility local7;
  option broadcast-address 192.168.12.0;

    # CLIENT CONTROL

    # 'allow unknown-clients' - Tells the DHCP server to assign
    # addresses to clients without static host declarations,
    # which is almost certainly something you want to do.
    # Otherwise, only clients you've manually given addresses to
    # later in the file will get DHCP assignments.
    # NOTE: If mixing static/dynamic within same pool, cannot use 'deny unknown'
    deny unknown-clients;

    # ignore client-updates;


    # do not use option domain-search in DMZ
    #    (use domain-search within each pool)
    # do not use option domain-name in DMZ

    # NETWORK COMPONENTS

    # ddns-updates - This line enables global dynamic updating. You can
    # also set this per-scope, in case you wanted some scopes to
    # be able to do updating and not others
    ddns-updates on;
    ddns-domainname "homenet.";
    ddns-rev-domainname "in-addr.arpa.";


    # on release { }
    # on expiry { }
    on commit {
            set clip = binary-to-ascii(10, 8, ".", leased-address);
            set clhw = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
            execute("/usr/local/sbin/dhcpevent", "commit", clip, clhw, host-decl-name);
        }

  subnet 192.168.12.0 netmask 255.255.255.0
  {
    pool {
      range 192.168.12.100 192.168.12.249;
      # This pool has static & dynamic IP, cannot use 'deny unknown-clients'
      # deny all clients;

      # No dynamic IP here, only static IP, cannot use 'deny all clients;'
      deny unknown-clients;
    }
  }

  subnet 192.168.13.0 netmask 255.255.255.0
  {
    pool {
      range 192.168.13.200 192.168.13.249;
      # This pool has static & dynamic IP, cannot use 'deny unknown-clients'
      # deny all clients;

      # No dynamic IP here, only static IP, cannot use 'deny all clients;'
      deny unknown-clients;
    }
  }

  subnet 192.168.14.0 netmask 255.255.255.0
  {
    pool {
      range 192.168.14.200 192.168.14.249;
      # This pool has static & dynamic IP, cannot use 'deny unknown-clients'
      # deny all clients;

      # No dynamic IP here, only static IP, cannot use 'deny all clients;'
      deny unknown-clients;
    }
  }

  subnet 192.168.15.0 netmask 255.255.255.0
  {
    pool {
      range 192.168.15.200 192.168.15.249;
      # We do static lease via MAC-reservation (see dhcpd.conf.reserved)
      # This pool has static & dynamic IP, cannot use 'deny unknown-clients'
      # deny all clients;

      # No dynamic IP here, only static IP, cannot use 'deny all clients;'
      deny unknown-clients;
    }
  }

#     # ddns-hostname = concat(binary-to-ascii(10, 8, "-", leased-address), "unknown");

}
DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.pool.172.32-dmz2"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server Pool configuration file for DMZ-Net
#
#

shared-network "dmz2" {

  # deny bootp;
  deny duplicates;
  # deny booting;

  subnet 172.32.1.0 netmask 255.255.255.0
  {
    # SERVER CONTROL

    # authoritative - Tells the DHCP server that it is to act as the one
    # true DHCP server for the scopes it's configured to understand, by
    # sending out DHCPNAK (DHCP-no-acknowledge) packets to
    # misconfigured DHCP clients.

    server-identifier 172.32.1.1;
    server-name dhcp-server-172-32;

    # CLIENT CONTROL

    # 'allow unknown-clients' - Tells the DHCP server to assign
    # addresses to clients without static host declarations,
    # which is almost certainly something you want to do.
    # Otherwise, only clients you've manually given addresses to
    # later in the file will get DHCP assignments.
    deny unknown-clients;
    ignore client-updates;
    # do not use option domain-search in DMZ
    # do not use option domain-name in DMZ

    # NETWORK COMPONENTS

    option log-servers 172.32.1.1;
    option subnet-mask 255.255.255.0;
    option routers 172.32.1.1;
    option ntp-servers 172.32.1.1;
    option www-server 172.32.1.1;

    option domain-name "verizon.net";
    option domain-name-servers 71.242.0.12, 71.252.0.12;

# log-facility local7;
    option broadcast-address 172.32.1.255;

    # on release { }

    # on expiry { }
    on commit {
            set clip = binary-to-ascii(10, 8, ".", leased-address);
            set clhw = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
            execute("/usr/local/sbin/dhcpevent", "commit", clip, clhw, host-decl-name);
        }

  }
}
DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.pool.192.168.15-wlan"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server Pool configuration file for Wireless-Net
#

subnet 192.168.15.0 netmask 255.255.255.0
{
    authoritative;
    server-identifier 192.168.15.1;
    server-name dhcp-server-192-168-15;

    allow unknown-clients;
    allow client-updates;

    option log-servers 192.168.15.1;
    option domain-name-servers 192.168.15.1;
    option local-pac-server "http://192.168.15.1:80/wpad-90.dat";

    # log-facility local7;
}
DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.pools"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server configuration for all DHCP pools
#

include "/etc/dhcp/dhcpd.conf.pool.192.168.12-resinet";
include "/etc/dhcp/dhcpd.conf.pool.192.168.15-wlan";
include "/etc/dhcp/dhcpd.conf.pool.172.32-dmz2";
include "/etc/dhcp/dhcpd.conf.pool.10.22.0-vir";

DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.reserved"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: ISC DHCP Server configuration for reserved IP addresses
#
#
# in dhcp-eval(8), MAC address prefixed with "1:" represents Ethernet
# other prefix value are: 6 for token-ring, 8 is FDDI

# DMZ (cable) Zone (192.168.12.0/22)
# Used only for Verizon-related backend IoTs
# sorted by MAC address (without 1: prefix)
# subclass "dmz2"   f8:e4:fb:12:34:56;  # ActionTec router
# subclass "dmz2"   f8:e4:fb:78:9a:bc;  # ActionTec router
# subclass "dmz2"   f8:e4:23:45:67:89;  # Fake ActionTec router
subclass "dmz2"   00:2c:57:8b:2f:dd;  # New Fake ActionTec router
# subclass "dmz2"   fa:bf:ff:01:23:33;  # Verizon (Motorola) Cable Set-top Box

# DMZ (non-cable) Zone (192.168.12.0/22)
# sorted by MAC address (without 1: prefix)
subclass "DMZ"   00:14:d1:31:23:11;  # TrendNet 1 PowerLAN
subclass "DMZ"   00:71:47:00:01:23;  # Amazon Alexa Echo 2
subclass "DMZ"   2c:10:c1:32:12:13;  # Wii
subclass "DMZ"   58:fd:b1:32:12:31;  # LG TV
subclass "DMZ"   7c:ed:8d:32:12:31;  # XBox360
subclass "DMZ"   ac:89:95:21:12:23;  # PS4

# special zone (IP class-less)
# Used to auto-correct faulty DNS name
# sorted by MAC address (without 1: prefix)
subclass "3DS"   34:af:2c:12:12:12;  # 3ds.homenet.
subclass "3DS"   40:d2:8a:12:12:12;  # 3dsxl-gold.homenet.
subclass "3DS"   cc:fb:65:12:12:12;  # 3dsxl.homenet.
subclass "iPod"  00:23:df:12:12:12;  # iPod

# Blue Zone (192.168.13.0/22)
# sorted by MAC address (without 1: prefix)
subclass "kids"   00:22:5f:12:23:34;  # laptop Dell Inspiron (WiFi)
subclass "kids"   00:23:ae:12:23:34;  # laptop Dell Inspiron (eth0)
subclass "kids"   08:74:02:12:23:34;  # iPhone
subclass "kids"   8c:99:e6:12:23:34;  # Android
subclass "kids"   98:5f:d3:12:23:34;  # Surface tablet
subclass "kids"   a4:67:06:12:23:34;  # iPad
subclass "kids"   e0:cb:1d:12:23:34;  # Kimble

# Green Zone (192.168.14.0/22)
# sorted by MAC address (without 1: prefix)
subclass "green" 1:0c:3e:9f:12:23:34;  # iPhone
subclass "green"   14:56:8e:12:23:34;  # Samsung mobile
subclass "green" 1:24:1b:7a:12:23:34;  # iPad
subclass "green"   58:67:1a:12:23:34;  # Nook
subclass "green"   b8:8a:ec:12:23:34;  # Nintendo Switch
subclass "green"   c8:21:58:12:23:34;  # Chromebook
subclass "green"   dc:56:e7:12:23:34;  # MacBook

# White Zone (192.168.14.0/22)
# sorted by MAC address (without 1: prefix)
subclass "white"   00:1a:a0:12:23:34;  # Desktop
subclass "white"   24:1b:7a:12:23:34;  # iPad
subclass "white" 1:24:f6:77:12:23:34;  # iPhone
subclass "white"   50:9A:4C:12:23:34;  # Pi
subclass "white"   b4:ce:f6:12:23:34;  # WinPhone

group dmz2 {
    option domain-name "home";
    ddns-domainname "home";
    use-host-decl-names on;

    # Actiontec router (needs static IP)
    #  And preferably some non-192.168.1 subnet
    # This only happens if ActionTec router is behind gateway.homenet eth0
#    host Wireless_Broadband_Router  {
#   hardware ethernet f8:e4:fb:12:23:34;
#        fixed-address 192.168.1.2;
#    }
#    host Wireless_Broadband_Router  {
#   hardware ethernet f8:e4:fb:12:23:34;
#        fixed-address 192.168.1.3;
#    }
#    host stb.home. {
#   hardware ethernet ba:dc:af:12:23:34;
#        fixed-address 192.168.1.4;
#    }
}


group dmz {
    option domain-name "homenet";
    ddns-domainname "homenet";
    use-host-decl-names on;

    # TrendNet 1 PowerLAN
    host trendnet1.homenet. {
    hardware ethernet 00:14:d1:12:23:34;
        fixed-address 192.168.12.10;
    }
    # NetFlix 1
    host lg-1.homenet. {
    hardware ethernet 3c:bd:d8:12:23:34;    # wired
    fixed-address 192.168.12.32;
        option host-name "lg-1";
        ddns-hostname "lg-1";
    }
    # NetFlix 2
    host lg-2.homenet. {
    hardware ethernet 88:03:55:12:23:34;
    fixed-address 192.168.12.33;
        option host-name "lg-2";
        ddns-hostname "lg-2";
    }
    # NetFlix 1
    host lg-1wifi.homenet. {
    hardware ethernet 88:03:55:12:23:34;  # wireless
    fixed-address 192.168.12.35;
    }
    # Amazon Alexa Echo 2 (codeword: biscuit)
    host biscuit.homenet. {
    hardware ethernet 00:71:47:12:23:34;  # wireless
    fixed-address 192.168.12.36;
    }
    # LG TV
    host tv-lg.homenet. {
    hardware ethernet 58:fd:b1:12:23:34;
        fixed-address 192.168.12.40;
    }
}

group blue {
    ddns-updates on;
    ddns-domainname "homenet";
    ddns-rev-domainname "in-addr.arpa.";

    # iPod
    host ipod.homenet. {
    hardware ethernet 00:23:df:12:23:34;
        fixed-address 192.168.13.51;
    }

    # 3DS
    host 3ds.homenet. {
    hardware ethernet 9c:e6:35:12:23:34;
        fixed-address 192.168.13.54;
    }
    # gold 3DS-xl
    host 3dsxl-gold.homenet. {
    hardware ethernet 40:d2:8a:12:23:34;
        fixed-address 192.168.13.55;
    }
    # 3DS-xl
    host 3dsx.homenet. {
    hardware ethernet 9c:e6:35:12:23:34;
        fixed-address 192.168.13.56;
    }
    # XBox360
    host xbox360.homenet. {
    hardware ethernet 7c:ed:8d:12:23:34;
    fixed-address 192.168.13.57;
    }
    # Wii
    host wii.homenet. {
    hardware ethernet 2c:10:c1:12:23:34;
    fixed-address 192.168.13.58;
    }
    # Nook Book
    host nook.homenet. {
    hardware ethernet 58:67:1a:12:23:34;
    fixed-address 192.168.13.74;
    }
}

group green {
    # iPad
    host ipad.homenet. {
        hardware ethernet f4:5c:89:12:23:34;
        fixed-address 192.168.14.97;
    }
    # Kindle
    host kindle.homenet. {
        hardware ethernet e0:cb:1d:12:23:34;
        fixed-address 192.168.14.105;
    }
}

group white {
    # If you turn off use-host-decl-names, you
    #    can use 'option host-name "<name>"' selectively for each static IP
    use-host-decl-names off;

    ddns-updates on;
    ddns-domainname "homenet";
    ddns-rev-domainname "in-addr.arpa.";

    host laptop.homenet. {
        hardware ethernet 70:56:81:12:23:34;
        fixed-address 192.168.14.129;
    }
}

DHCPD_CONF_EOF

DHCPD_CONF_FILENAME="dhcpd.conf.zones"
DHCPD_CONF_FILESPEC="${DHCPD_DIRSPEC}/$DHCPD_CONF_FILENAME"
echo "Creating ${BUILDROOT}$DHCPD_CONF_FILESPEC ..."
cat << DHCPD_CONF_EOF | tee "${BUILDROOT}$DHCPD_CONF_FILESPEC" >/dev/null
#
# File: ${DHCPD_CONF_FILENAME}
# Path: ${DHCPD_DIRSPEC}
# Title: DHCP Server to ISC Bind path for Zone file updates
#

# resinet
zone homenet. {
    primary 192.168.12.1;
        key DDNS_UPDATER;
    }

# 192.168.12.0/22
zone 130.28.172.in-addr.arpa. {
    primary 192.168.12.1;
        key DDNS_UPDATER;
    }

DHCPD_CONF_EOF

echo ""
echo "Done."
