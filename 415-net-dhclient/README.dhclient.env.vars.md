

For scripts under various DHCP client hook mechanism, the available
environment variables depends on the state of DHCLIENT negotiation.


MEDIUM
  - `$interface` - netdev interface name
  - `$medium` - media type of the netdev interface

PREINIT
  - `$interface` - netdev interface name
  - `$medium` - media type of the netdev interface
  - `$alias_ip_address` - If an IP alias has been declared in dhclient.conf, its address will be passed in $alias_ip_address, and that ip alias should be deleted from the interface, along with any routes to it.

BOUND (same as REBOOT)
  - `$interface` - netdev interface name
  - `$medium` - media type of the netdev interface
  - `$alias_ip_address` - Create the new alias IP address
  - `requested_ip_address` - negotiated IP address
  - `requested_ntp_server` - if DHCP server sends `ntp_server`
  - `requested_subnet_mask` - if DHCP server sends `subnet_mask`
  - `requested_dhcp6_server_id` - the `dhcp_server_id`, if DHCP server replies with it
  - `requested_domain_name` - the `domain_name`, if DHCP server replies with it
  - `requested_domain_name_servers` - the `domain_name_servers`, if DHCP server replies with it
  - `requested_routers` - the `routers`, if DHCP server replies with it
  - `requested_static_routes` - the `static_routes`, if DHCP server replies with it

  - `new_ip_address` - negotiated IP address
  - `new_ntp_server` - if DHCP server sends `ntp_server`
  - `new_subnet_mask` - if DHCP server sends `subnet_mask`
  - `new_dhcp6_server_id` - the `dhcp_server_id`, if DHCP server replies with it
  - `new_domain_name` - the `domain_name`, if DHCP server replies with it
  - `new_domain_name_servers` - the `domain_name_servers`, if DHCP server replies with it
  - `new_routers` - the `routers`, if DHCP server replies with it
  - `new_static_routes` - the `static_routes`, if DHCP server replies with it

RENEW (same as REBIND)
Rebind has a new IP address of which the ARP cache table MUST be cleared/purged.
  - `$interface` - netdev interface name
  - `$medium` - media type of the netdev interface
  - `$alias_ip_address` - Create the new alias IP address
  - `requested_ip_address` - negotiated IP address
  - `requested_ntp_server` - if DHCP server sends `ntp_server`
  - `requested_subnet_mask` - if DHCP server sends `subnet_mask`
  - `requested_dhcp6_server_id` - the `dhcp_server_id`, if DHCP server replies with it
  - `requested_domain_name` - the `domain_name`, if DHCP server replies with it
  - `requested_domain_name_servers` - the `domain_name_servers`, if DHCP server replies with it
  - `requested_routers` - the `routers`, if DHCP server replies with it
  - `requested_static_routes` - the `static_routes`, if DHCP server replies with it

  - `new_ip_address` - negotiated IP address
  - `new_ntp_server` - if DHCP server sends `ntp_server`
  - `new_subnet_mask` - if DHCP server sends `subnet_mask`
  - `new_dhcp6_server_id` - the `dhcp_server_id`, if DHCP server replies with it
  - `new_domain_name` - the `domain_name`, if DHCP server replies with it
  - `new_domain_name_servers` - the `domain_name_servers`, if DHCP server replies with it
  - `new_routers` - the `routers`, if DHCP server replies with it
  - `new_static_routes` - the `static_routes`, if DHCP server replies with it

EXPIRE
EXPIRE is the same as RENEW and REBIND except that its DHCP client lease period has expired.

FAIL
Should purge the lease config file from the lease directory such as /var/cache/dhcp or /run/dhcp or /var/lib/dhcp.  Then this state can be treated just like
EXPIRE state.

TIMEOUT
- The DHCP client has been unable to contact any DHCP servers. However, an old lease has been identified, and its parameters have been passed in as with BOUND. The client configuration script should test these parameters and, if it has reason to believe they are valid, should exit with a value of zero. If not, it should exit with a nonzero value.
- The usual way to test a lease is to set up the network as with REBIND (since this may be called to test more than one lease) and then ping the first router defined in $routers. If a response is received, the lease must be valid for the network to which the interface is currently connected. It would be more complete to try to ping all of the routers listed in $new_routers, as well as those listed in $new_static_routes, but current scripts do not do this.


References:

- https://codingrelic.geekhold.com/2012/02/isc-dhcp-vivo-config.html
