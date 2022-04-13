#!/bin/bash
# File: 423-fw-shorewall-params.sh
# Title: Configure params and interfaces config files of Shorewall firewall

echo "Configure params and interfaces config files of Shorewall firewall"
echo

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

if [ "${BUILDROOT:0:1}" != "/" ]; then
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-perms-fw-shorewall-params.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -f "$FILE_SETTINGS_FILESPEC"
else
  FILE_SETTING_PERFORM='true'
fi

DEFAULT_ETC_CONF_DIRNAME="shorewall"

source ./maintainer-fw-shorewall.sh

shorewall_dirspec="$extended_sysconfdir"
flex_ckdir "$shorewall_dirspec"

shorewall_conf_filename="shorewall.conf"
shorewall_conf_filespec="${shorewall_dirspec}/$shorewall_conf_filename"

# Sequece of user-prompting
# /etc/shorewall/params
# /etc/shorewall/interfaces
# /etc/shorewall/policy
# /etc/shorewall/rules
# /etc/shorewall/zones
#
# Function name: add_macaddr_to_maclist_config_file
# Arguments:
#    interface label
#    MAC address, in 'XX:XX:XX:XX:XX:XX' string format
config_maclist_created=0
function add_macaddr_to_maclist_config_file() {
  intf_label="$1"
  macaddr="$2"
  if [ -z "$macaddr" ]; then
    echo "Empty argument; aborted"
    exit 3
  fi
  maclist_filename="maclist"
  maclist_dirspec="$extended_sysconfdir"
  maclist_filespec="${maclist_dirspec}/$maclist_filename"
  maclist_output_file="${BUILDROOT}${CHROOT_DIR}$maclist_filespec"
  # create maclist config file, if not done before
  if [ "$config_maclist_created" -eq 0 ]; then
    echo "Creating $BUILDROOT$CHROOT_DIR$maclist_filespec ..."
    cat << MACLIST_CONF_EOF | tee "$maclist_output_file" >/dev/null
#
# File: $maclist_filename
# Path: $maclist_dirspec
#
# For information about entries in this file, type "man shorewall-maclist"
#
# For additional information, see http://shorewall.net/MAC_Validation.html
#
###############################################################################
#
# This file is used to define the MAC addresses and optionally their associated
# IP addresses to be allowed to use the specified interface. The feature is
# enabled by using the maclist option in the shorewall-interfaces(5) or
# shorewall-hosts(5) configuration file.
#
# The columns in the file are as follows (where the column name is followed by a
# different name in parentheses, the different name is used in the alternate
# specification syntax).
#
# DISPOSITION - {ACCEPT|DROP|REJECT}[:log-level]
#
#     ACCEPT or DROP (if MACLIST_TABLE=filter in shorewall.conf(5), then REJECT
#     is also allowed). If specified, the log-level causes packets matching the
#     rule to be logged at that level.
#
# INTERFACE - interface
#
#     Network interface to a host.
#
# MAC - address
#
#     MAC address of the host -- you do not need to use the Shorewall format for
#     MAC addresses here. If IP ADDRESSES is supplied then MAC can be supplied as
#     a dash (-)
#
# IP ADDRESSES (addresses) - [address[,address]...]
#
#     Optional - if specified, both the MAC and IP address must match. This
#     column can contain a comma-separated list of host and/or subnet addresses.
#     If your kernel and iptables have iprange match support then IP address
#     ranges are also allowed. Similarly, if your kernel and iptables include
#     ipset support than set names (prefixed by "+") are also allowed.
#
###############################################################################
#DISPOSITION    INTERFACE       MAC         IP ADDRESSES (Optional)

MACLIST_CONF_EOF
    config_maclist_created=1
  fi
  echo "Adding $macaddr to $maclist_output_file ..."
  cat << MACLIST_CONF_EOF | tee -a "$maclist_output_file" >/dev/null
ACCEPT      \$$intf_label         $macaddr
MACLIST_CONF_EOF
  echo
  unset intf_label
  unset macaddr
  unset maclist_output_file
}

# Get a list of all IP-configured netdevs
netdevs_list="$(ip -br -4 -o addr show scope global|awk '{print $1}'|xargs)"
echo "netdevs_list: $netdevs_list"
for this_intf in $netdevs_list; do
  short_intf_details="$(ip -br -4 -o addr show dev $this_intf)"
  echo "$short_intf_details"
done
echo

# Select netdevs and label them
# man shorewall-params(5)
netdev_labels_A=()
netdev_zone_A=()
echo "Labeling the netdevs:"
echo "    Some examples are: RED/GREEN/YELLOW, PUBLIC/PRIVATE/DMZ ..."
echo "Enter in empty input to skip that netdev."
if [ 0 -ne 0 ]; then  # TODO
for this_netdev in $netdevs_list; do
  read -rp "Label for ${this_netdev}?: "
  REPLY="$(echo "$REPLY"|awk '{print toupper($1)}')"
  netdev_zone_A+=(${REPLY})
  netdev_labels_A+=(${REPLY}_IP)
done
else
  netdev_zone_A+=("red")
  netdev_zone_A+=("green")
  netdev_zone_A+=("white")
  netdev_zone_A+=("orange")
  netdev_labels_A+=("RED_IF")
  netdev_labels_A+=("GREEN_IF")
  netdev_labels_A+=("WHITE_IF")
  netdev_labels_A+=("ORANGE_IF")
fi
echo

shorewall_params_filename="params"
shorewall_params_filespec="${shorewall_dirspec}/$shorewall_params_filename"
echo "Labels in $shorewall_params_filename file are:"
echo "netdev_labels_A[*]: ${netdev_labels_A[@]}"
echo
OUTPUT_FILE="${BUILDROOT}$shorewall_params_filespec"
echo "Creating ${OUTPUT_FILE} file ..."
cat << SHOREWALL_CONF_EOF | tee "${OUTPUT_FILE}" >/dev/null
#
# File: $shorewall_params_filespec
# Title: Shorewall Parameters configuration file
#
# Assign any variables that you need here.
#
# It is suggested that variable names begin with an upper case letter
# to distinguish them from variables used internally within the
# Shorewall programs
#
# Example:
#
#   NET_IF=eth0
#   NET_BCAST=130.252.100.255
#   NET_OPTIONS=routefilter,norfc1918
#
# Example (/etc/shorewall/interfaces record):
#
#   net $NET_IF     $NET_BCAST  $NET_OPTIONS
#
# The result will be the same as if the record had been written
#
#   net eth0        130.252.100.255 routefilter,norfc1918
#
###############################################################################

SHOREWALL_CONF_EOF

# Write in the netdev label assignments into 'params' file
idx=0
for this_intf in $netdevs_list; do
  short_intf_details="$(ip -br -4 -o addr show dev $this_intf)"
  echo "    ${netdev_labels_A[$idx]}=$this_intf"
  echo "${netdev_labels_A[$idx]}=$this_intf" >> "${OUTPUT_FILE}"
  ((idx++))
done

# Close out the 'params' config file in a Shorewall manner.
cat << SHOREWALL_CONF_EOF | tee -a "${OUTPUT_FILE}" >/dev/null

#LAST LINE -- DO NOT REMOVE
SHOREWALL_CONF_EOF
echo

flex_chmod 0640 "$shorewall_params_filespec"
flex_chown root:root "$shorewall_params_filespec"

####################################################################
#  Creating 'interfaces' config file
####################################################################

# identify the netdev(s) to upstream Internet
default_gw_netdevs_A=()
default_gw_netdevs_A+=("$(ip -4 -o route show|grep "^default"|awk '{print $5}')")
default_gw_ip4_A=()
default_gw_ip4_A+=("$(ip -4 -o route show|grep "^default"|awk '{print $3}')")
# Bug: it is possible to have a double  entry of gateway for same interface
# workable, valid, but not kosher.  Sort unique them out of these arrays
#    ip -4 -o route show
#    default via 192.168.1.1 dev enp4s0
#    default via 192.168.1.1 dev enp4s0 proto dhcp metric 100
default_gw_netdevs_A=($(echo ${default_gw_netdevs_A[*]} | xargs -n1 | sort -u | xargs ))
default_gw_ip4_A=($(echo ${default_gw_ip4_A[*]} | xargs -n1 | sort -u | xargs ))

echo "Netdev(s) to gateway: $(echo ${default_gw_netdevs_A[*]}|xargs)"
default_gateways=""
if [ "${#default_gw_netdevs_A[@]}" -eq 1 ]; then
  default_gateways="${default_gw_netdevs_A[0]}"
fi
echo "default_gw_ip4_A: ${default_gw_ip4_A[*]}"
echo "default_gateways: $default_gateways"

# Select Public IP using default gateway as a default prompt
single_gateway=
read -rp "Enter in netdev(s) for Public-side network: " -ei"${default_gateways}"
public_netdevs="$REPLY"

# if multi-home (multiple default gateway), then no 'routeback' option
interfaces_multi_homed=0
if [ "$(echo $public_netdevs|wc -w)" -gt 1 ]; then
  # If multi-homed, turn off 'routeback'
  interfaces_multi_homed=1
fi

shorewall_interfaces_filename="interfaces"
shorewall_interfaces_filespec="${shorewall_dirspec}/$shorewall_interfaces_filename"
interfaces_output="${BUILDROOT}${CHROOT_DIR}$shorewall_interfaces_filespec"
echo "Creating ${interfaces_output} file ..."
cat << SHOREWALL_CONF_EOF | tee "${interfaces_output}" >/dev/null
#
# File: $shorewall_interfaces_filespec
# Path: $shorewall_dirspec
# Title: interfaces config file for Shorewall firewall
#
# Description:
#
# The interfaces file serves to define the firewall's network
# interfaces to Shorewall. The order of entries in this file
# is not significant in determining zone composition.
#
# The columns in the file are as follows.
#
# ZONE - zone-name
#
#  Zone for this interface. Must match the name of a
#  zone declared in /etc/shorewall/zones. You may not
#  list the firewall ('FW') zone in this column.
#
#  If the interface serves multiple zones that will be
#  defined in the shorewall-hosts(5) file, you should
#  place "-" in this column.
#
#  If there are multiple interfaces to the same zone, you
#  must list them in separate entries.
#
#     Example:
#
#         #ZONE   INTERFACE
#         loc     eth1
#         loc     eth2
#
# INTERFACE - interface[:port]
#
#  Logical name of interface. Each interface may be listed
#  only once in this file. You may NOT specify the name
#  of a "virtual" interface (e.g., eth0:0) here; see
#  https://shorewall.org/FAQ.htm#faq18. If the physical
#  option is not specified, then the logical name is
#  also the name of the actual interface.
#
#  You may use wildcards here by specifying a prefix followed
#  by the plus sign ("+"). For example, if you want to make
#  an entry that applies to all PPP interfaces, use 'ppp+';
#  that would match ppp0, ppp1, ppp2, ...
#
#  Shorewall allows to specify 'physical=+' in the OPTIONS
#  column (see below).
#
#  There is no need to define the loopback interface (lo) in this file.
#
#  If a port is given, then the interface must have been defined
#  previously with the bridge option. The OPTIONS column
#  may not contain the following options when a port is given.
#     arp_filter
#     arp_ignore
#     bridge
#     log_martians
#     mss
#     optional
#     proxyarp
#     required
#     routefilter
#     sourceroute
#     upnp
#     wait
#
#  If you specify a zone for the 'lo' interface, then that
#  zone must be defined as type local in shorewall6-zones(5).
#
#  If you don't want to give a value for this column but you
#  want to enter a value in the OPTIONS column, enter - in
#  this column.
#
# OPTIONS (Optional) - [option[,option]...]
#
#  A comma-separated list of options from the following
#  list. The order in which you list the options is not
#  significant but the list should have no embedded white-space.
#
#   accept_ra[={0|1|2}]
#     IPv6 only; added in Shorewall 4.5.16. Values are:
#
#     0 - Do not accept Router Advertisements.
#     1 - Accept Route Advertisements if forwarding is disabled.
#     2 - Overrule forwarding behavior. Accept Route Advertisements
#         even if forwarding is enabled.
#
#     If the option is specified without a value, then the value 1 is assumed.
#     Note
#
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified, a warning is
#       issued and the option is ignored.
#
#   arp_filter[={0|1}]
#     IPv4 only. If specified, this interface will only
#     respond to ARP who-has requests for IP addresses
#     configured on the interface. If not specified, the
#     interface can respond to ARP who-has requests for
#     IP addresses on any of the firewall's interface.
#     The interface must be up when Shorewall is started.
#
#     Only those interfaces with the arp_filter option
#     will have their setting changed; the value assigned
#     to the setting will be the value specified (if any)
#     or 1 if no value is given.
#     Note
#
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). , If this option is specified,
#       a warning is issued and the option is ignored.
#
#   arp_ignore[=number]
#     IPv4 only. If specified, this interface will respond
#     to arp requests based on the value of number (defaults to 1).
#
#     1 - reply only if the target IP address is local address
#     configured on the incoming interface
#
#     2 - reply only if the target IP address is local address
#     configured on the incoming interface and the sender's IP
#     address is part from same subnet on this interface's address
#
#     3 - do not reply for local addresses configured with scope
#     host, only resolutions for global and link
#
#     4-7 - reserved
#
#     8 - do not reply for all local addresses
#     Note
#
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified, a
#       warning is issued and the option is ignored.
#       Warning
#
#       Do not specify arp_ignore for any interface involved
#       in Proxy ARP.
#
#   blacklist
#     Checks packets arriving on this interface against the
#     shorewall-blacklist(5) file.
#
#     If a zone is given in the ZONES column, then the
#     behavior is as if blacklist had been specified in the
#     IN_OPTIONS column of shorewall-zones(5).
#
#     Otherwise, the option is ignored with a warning:
#
#       WARNING: The 'blacklist' option is ignored on multi-zone interfaces
#
#   bridge
#     Designates the interface as a bridge. Setting this option
#     also sets routeback.
#     Note
#
#       If you have a bridge that you don't intend to define
#       bport zones on, then it is best to omit this option and
#       simply specify routeback.
#
#   dbl={none|src|dst|src-dst}
#     This option defined whether or not dynamic blacklisting
#     is applied to packets entering the firewall through
#     this interface and whether the source address and/or
#     destination address is to be compared against the
#     ipset-based dynamic blacklist (DYNAMIC_BLACKLIST=ipset...
#     in shorewall.conf(5)). The default is determine by the
#     setting of DYNAMIC_BLACKLIST:
#
#     DYNAMIC_BLACKLIST=No
#       Default is none (e.g., no dynamic blacklist checking).
#
#     DYNAMIC_BLACKLIST=Yes
#       Default is src (e.g., the source IP address is checked).
#
#     DYNAMIC_BLACKLIST=ipset[-only]
#       Default is src.
#
#     DYNAMIC_BLACKLIST=ipset[-only],src-dst...
#
#       Default is src-dst (e.g., the source IP addresses in
#       checked against the ipset on input and the
#       destination IP address is checked against the ipset
#       on packets originating from the firewall and leaving
#       through this interface).
#
#     The normal setting for this option will be dst or none
#     for internal interfaces and src or src-dst for
#     Internet-facing interfaces.
#
#   destonly
#     Causes the compiler to omit rules to handle traffic from this interface.
#
#   dhcp
#     Specify this option when any of the following are true:
#
#       - the interface gets its IP address via DHCP
#       - the interface is used by a DHCP server running on the firewall
#       - the interface has a static IP but is on a LAN segment
#         with lots of DHCP clients.
#
#     the interface is a simple bridge with a DHCP server on one
#     port and DHCP clients on another port.

#     Note
#       If you use Shorewall-perl for firewall/bridging, then you
#       need to include DHCP-specific rules in shorewall-rules(5).
#       DHCP uses UDP ports 67 and 68.
#
#       This option allows DHCP datagrams to enter and leave the interface.
#
#   forward[={0|1}]
#
#     IPv6 only Sets the /proc/sys/net/ipv6/conf/interface/
#     forwarding option to the specified value. If no value
#     is supplied, then 1 is assumed.
#
#     Note
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified,
#       a warning is issued and the option is ignored.
#
#   ignore[=1]
#     When specified, causes the generated script to ignore
#     up/down events from Shorewall-init for this device.
#     Additionally, the option exempts the interface from
#     hairpin filtering. When '=1' is omitted, the ZONE
#     column must contain '-' and ignore must be the only OPTION.
#
#     May be specified as 'ignore=1' which only causes the
#     generated script to ignore up/down events from
#     Shorewall-init; hairpin filtering is still applied.
#     In this case, the above restrictions on the ZONE and
#     OPTIONS columns are lifted.
#
#   loopback
#     Designates the interface as the loopback interface.
#     This option is assumed if the interface's physical
#     name is 'lo'. Only one interface man have the
#     loopback option specified.
#
#   logmartians[={0|1}]
#     IPv4 only. Turn on kernel martian logging (logging of
#     packets with impossible source addresses. It is strongly
#     suggested that if you set routefilter on an interface
#     that you also set logmartians. Even if you do not specify
#     the routefilter option, it is a good idea to specify
#     logmartians because your distribution may have enabled
#     route filtering without you knowing it.
#
#     Only those interfaces with the logmartians option will have
#     their setting changed; the value assigned to the setting will
#     be the value specified (if any) or 1 if no value is given.
#
#     To find out if route filtering is set on a given interface,
#     check the contents of /proc/sys/net/ipv4/conf/interface/rp_filter
#     - a non-zero value indicates that route filtering is enabled.
#
#     Example:
#       teastep@lists:~$ cat /proc/sys/net/ipv4/conf/eth0/rp_filter
#       1
#       teastep@lists:~$
#
#     Note
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified, a
#       warning is issued and the option is ignored.
#
#       This option may also be enabled globally in the
#       shorewall.conf(5) file.
#
#   maclist
#     Connection requests from this interface are compared
#     against the contents of shorewall-maclist(5). If this
#     option is specified, the interface must be an Ethernet
#     NIC and must be up before Shorewall is started.
#
#   mss=number
#     Causes forwarded TCP SYN packets entering or leaving on
#     this interface to have their MSS field set to the
#     specified number.
#
#   nets=(net[,...])
#     Limit the zone named in the ZONE column to only the
#     listed networks. The parentheses may be omitted if only
#     a single net is given (e.g., nets=192.168.1.0/24).
#     Limited broadcast to the zone is supported.
#     Multicast traffic to the zone is also supported.
#
#   nets=dynamic
#     Defines the zone as dynamic. Requires ipset match support
#     in your iptables and kernel. See
#     https://shorewall.org/Dynamic.html for further information.
#
#   nodbl
#     When specified, dynamic blacklisting is disabled on
#     the interface. nodbl is equivalent to dbl=none.
#
#   nosmurfs
#     IPv4 only. Filter packets for smurfs (packets with
#     a broadcast address as the source).
#
#     'nosmurfs' is typically used on bridge-only interface.
#
#     Smurfs will be optionally logged based on the setting
#     of SMURF_LOG_LEVEL in shorewall.conf(5). After logging,
#     the packets are dropped.
#
#   omitanycast
#     IPv6 only.  Shorewall6 has traditionally generated rules
#     for IPv6 anycast addresses. These rules include:
#
#     - Packets with these destination IP addresses are dropped by REJECT rules.
#
#     - Packets with these source IP addresses are dropped by
#       the 'nosmurfs' interface option and by the 'dropSmurfs' action.
#
#     - Packets with these destination IP addresses are not
#       logged during policy enforcement.
#
#     - Packets with these destination IP addresses are processes
#       by the 'Broadcast' action.
#
#     This can be inhibited for individual interfaces by
#     specifying noanycast for those interfaces.
#     Note
#
#    RFC 2526 describes IPv6 subnet anycast addresses.
#    The RFC makes a distinction between subnets with
#    "IPv6 address types required to have 64-bit interface
#    identifiers in EUI-64 format" and all other subnets.
#    When generating these anycast addresses, the Shorewall
#    compiler does not make this distinction and unconditionally
#    assumes that the last 128 addresses in the subnet
#    are reserved as anycast addresses.
#
#   optional
#
#     This option indicates that the firewall should be able
#     to start, even if the interface is not usable for
#     handling traffic. It allows use of the enable and
#     disable commands on the interface.
#
#     When optional is specified for an interface, Shorewall
#     will be silent when:
#
#       - a /proc/sys/net/ipv[46]/conf/ entry for the interface cannot be modified (including for proxy ARP or proxy NDP).
#
#       - The first address of the interface cannot be obtained.
#
#       - The gateway of the interface can not be obtained (provider interface).
#
#       - The interface has been disabled using the disable command.
#
#     May not be specified with required.
#
#   physical=name
#     When specified, the interface or port name in the INTERFACE
#     column is a logical name that refers to the name given in
#     this option. It is useful when you want to specify the
#     same wildcard port name on two or more bridges.
#     See https://shorewall.org/bridge-Shorewall-perl.html#Multiple.
#
#     If the interface name is a wildcard name (ends with
#     '+'), then the physical name must also end in '+'. The
#     physical name may end in '+' (or be exactly '+') when the
#     interface name is not a wildcard name.
#
#     If physical is not specified, then it's value defaults
#     to the interface name.
#
#   proxyarp[={0|1}]
#     IPv4 only. Sets /proc/sys/net/ipv4/conf/interface/proxy_arp.
#     Do NOT use this option if you are employing Proxy ARP through
#     entries in shorewall-proxyarp(5). This option is intended
#     solely for use with Proxy ARP sub-networking as described
#     at: http://tldp.org/HOWTO/Proxy-ARP-Subnet/index.html.
#
#     Note
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified, a
#       warning is issued and the option is ignored.
#
#     Only those interfaces with the proxyarp option will
#     have their setting changed; the value assigned to the
#     setting will be the value specified (if any) or 1 if
#     no value is given.
#
#   proxyndp[={0|1}]
#     IPv6 only. Sets /proc/sys/net/ipv6/conf/interface/proxy_ndp.
#
#     Note
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified, a
#       warning is issued and the option is ignored.
#
#     Only those interfaces with the proxyndp option will
#     have their setting changed; the value assigned to the
#     setting will be the value specified (if any) or 1 if
#     no value is given.
#
#   required
#     If this option is set, the firewall will fail to start
#     if the interface is not usable. May not be specified
#     together with optional.
#
#   routeback[={0|1}]
#     If specified, indicates that Shorewall should include
#     rules that allow traffic arriving on this interface to
#     be routed back out that same interface. This option is
#     also required when you have used a wildcard in the
#     INTERFACE column if you want to allow traffic between
#     the interfaces that match the wildcard.
#
#     If you specify this option, then you should also specify
#     either sfilter (see below) or routefilter on all
#     interfaces (see below).
#
#     You may specify this option to explicitly reset
#     (e.g., routeback=0). This can be used to override
#     Shorewall's default setting for bridge devices which is routeback=1.
#
#   routefilter[={0|1|2}]
#
#     IPv4 only. Turn on kernel route filtering for this
#     interface (anti-spoofing measure).
#
#     Only those interfaces with the routefilter option will
#     have their setting changes; the value assigned to the
#     setting will be the value specified (if any) or 1 if
#     no value is given.
#
#     The value 2 is only available with Shorewall 4.4.5.1 and
#     later when the kernel version is 2.6.31 or later.
#     It specifies a loose form of reverse path filtering.
#
#     Note
#       This option does not work with a wild-card physical
#       name (e.g., eth0.+). If this option is specified, a
#       warning is issued and the option is ignored.
#
#     This option can also be enabled globally via the ROUTE_FILTER
#     option in the shorewall.conf(5) file.
#
#     Important
#
#     If ROUTE_FILTER=Yes in shorewall.conf(5), or if your
#     distribution sets net.ipv4.conf.all.rp_filter=1 in
#     /etc/sysctl.conf, then setting routefilter=0 in an
#     interface entry will not disable route filtering on
#     that interface! The effective setting for an
#     interface is the maximum of the contents of
#     /proc/sys/net/ipv4/conf/all/rp_filter and the
#     routefilter setting specified in this file
#     (/proc/sys/net/ipv4/conf/interface/rp_filter).
#
#     Note
#       There are certain cases where routefilter cannot be
#       used on an interface:
#
#       - If USE_DEFAULT_RT=Yes in shorewall.conf(5) and the
#         interface is listed in shorewall-providers(5).
#
#       - If there is an entry for the interface in
#         shorewall-providers(5) that doesn't specify the
#         balance option.
#
#       - If IPSEC is used to allow a road-warrior to have a
#         local address, then any interface through which the
#         road-warrior might connect cannot specify routefilter.
#
#     When routefilter is set to a non-zero value, the logmartians
#     option is also implicitly set. If you actually want route
#     filtering without logging, then you must also specify
#     logmartians=0 after routefilter.
#
#   rpfilter
#
#     This is an anti-spoofing measure that requires the
#     'RPFilter Match' capability in your iptables and
#     kernel. It provides a more efficient alternative
#     to the sfilter option below. It performs a function
#     similar to routefilter (see above) but works with
#     Multi-ISP configurations that do not use balanced
#     routes.
#
#   sfilter=(net[,...])
#     This option provides an anti-spoofing alternative
#     to routefilter on interfaces where that option cannot
#     be used, but where the routeback option is required
#     (on a bridge, for example). On these interfaces,
#     sfilter should list those local networks that are
#     connected to the firewall through other interfaces.
#
#   sourceroute[={0|1}]
#     If this option is not specified for an interface, then
#     source-routed packets will not be accepted from that
#     interface unless it has been explicitly enabled
#     via sysconf. Only set this option to 1 (enable source
#     routing) if you know what you are doing. This might
#     represent a security risk and is usually unneeded.
#
#     Only those interfaces with the sourceroute option will
#     have their setting changed; the value assigned to the
#     setting will be the value specified (if any) or 1 if
#     no value is given.
#        Note
#
#     This option does not work with a wild-card physical
#     name (e.g., eth0.+). If this option is specified, a
#     warning is issued and the option is ignored.
#
#   tcpflags[={0|1}]
#     Packets arriving on this interface are checked for
#     certain illegal combinations of TCP flags. Packets
#     found to have such a combination of flags are
#     handled according to the setting of TCP_FLAGS_DISPOSITION
#     after having been logged according to the setting
#     of TCP_FLAGS_LOG_LEVEL.
#
#     tcpflags=1 is the default. To disable this option,
#     specify tcpflags=0.
#
#   unmanaged
#     Causes all traffic between the firewall and hosts on
#     the interface to be accepted. When this option is given:
#
#     - The ZONE column must contain '-'.
#
#     - Only the following other options are allowed with unmanaged:
#            arp_filter
#            arp_ignore
#            ignore
#            routefilter
#            optional
#            physical
#            routefilter
#            proxyarp
#            proxyudp
#            sourceroute
#
#   upnp
#     Incoming requests from this interface may be remapped
#     via UPNP (upnpd). See https://shorewall.org/UPnP.html.
#     Supported in IPv4 and in IPv6.
#
#   upnpclient
#     This option is intended for laptop users who always
#     run Shorewall on their system yet need to run
#     UPnP-enabled client apps such as Transmission
#     (BitTorrent client). The option causes Shorewall to
#     detect the default gateway through the interface and
#     to accept UDP packets from that gateway. Note that,
#     like all aspects of UPnP, this is a security hole
#     so use this option at your own risk. Supported in
#     IPv4 and in IPv6.
#
#   wait=seconds
#     Causes the generated script to wait up to seconds
#     seconds for the interface to become usable before applying
#     the required or optional options.
#
## internet has the following:
##    dhcp - the interface gets its IP address via DHCP LAN segment
##    logmartians - Turn on kernel martian logging (logging of
##                      packets with impossible source addresses.
#    routeback - indicates that Shorewall should include rules that
#                    allow traffic arriving on this interface to
#                    be routed back out that same interface.
#    routefilter - Turn on kernel route filtering for this
#                      interface (anti-spoofing measure).
#    nosmurfs - Filter packets for smurfs (packets with a
#                   broadcast address as the source).
#               'nosmurfs' is typically used on bridge-only interface.
#    tcpflags - Packets arriving on this interface are checked
#                   for certain illegal combinations of TCP flags.
#    upnp - Incoming requests from this interface may be remapped
#                   via UPNP (upnpd).
#    upnpclient - Only allow UPnP packets from detected gateway
#    bridge - Designates the interface as a bridge.
#                 Setting this option also sets routeback.
#------------------------------------------------------------------------------
# For information about entries in this file, type "man shorewall-interfaces"
###############################################################################
###############################################################################
#ZONE   INTERFACE   OPTIONS
?FORMAT 2

-       lo      -
SHOREWALL_CONF_EOF
echo

echo "Processing public-side interfaces ..."
echo "public_netdevs: $public_netdevs"
for this_public_netdev in $public_netdevs; do

  echo "  Processing $this_public_netdev public-side interface ..."

  # Stick in the defaults
  # (must assumes at least ONE interface option, due to CSV pre-construct)
  INTF_OPTS="logmartians,tcpflags,routefilter"

  # If a bridge-only, then MUST append a 'nosmurfs' option

  # 'routeback' option, only if not a multi-home (multiple default route)
  if [ "$interfaces_multi_homed" -eq 0 ]; then
    echo "Singular-homed interfaces"
    INTF_OPTS+=",routeback"
    is_a_bridge="$(ip -o -4 link show dev $this_public_netdev type bridge)"
    if [ -n "$is_a_bridge" ]; then
      INTF_OPTS+=",nosmurfs"
    fi
  else
    echo "Multi-home interface"
    echo "    Multi-homed $this_public_netdev is a bridge type, must do a 'routeback'"
    INTF_OPTS+=",nosmurfs"
    # Check if netdev is a 'type bridge'
    is_a_bridge="$(ip -o -4 link show dev $this_public_netdev type bridge)"
    if [ -n "$is_a_bridge" ]; then
      echo "    Multi-homed $this_public_netdev is a bridge type, must do a 'nosmurfs'"
      INTF_OPTS+=",routeback"
    fi
  fi

  # autodetect 'dhcp' option for any kind of netdev
  netdev_isdynamic="$(ip -4 -o addr show dev $this_public_netdev | awk '{print $9}')"
  if [ "$netdev_isdynamic" == "dynamic" ]; then
    INTF_OPTS+=",dhcp"
  fi

  # Absolutely no UPnP interface option for public-facing netdevs

  # 'maclist' interface option (used only on public-facing netdevs
  # This is the public netdev for-loop, so we know it is a default gateway
  echo "Shorewall can restrict traffic to just with the gateway routers."
  echo "Locating gateway routers' IP address ..."
  idx=0
  intfname_netdev="UNKNOWN_IP"
  default_gw_ip="255.255.255.255"
  for this_gw_device in ${default_gw_netdevs_A[@]}; do
    echo "idx: $idx"
    if [ "$this_public_netdev" == "${this_gw_device}" ]; then
      default_gw_ip="${default_gw_ip4_A[$idx]}"
      echo "    Gateway IP: ${default_gw_ip}"
      intfname_netdev="${netdev_labels_A[$idx]}"
      zone_netdev="${netdev_zone_A[$idx]}"
    fi
    ((idx++))
  done
  echo "Locating MAC address of gateway router on $this_public_netdev ..."
  echo "default_gw_ip: $default_gw_ip"
  echo "default_gw_ip: $default_gw_ip"
  gw_macaddr="$(ip -o -4 neigh show|grep -E "^${default_gw_ip} "|awk '{print $5}')"
  echo "count(gw_macaddr): $(echo ${gw_macaddr} | wc -w)"
  echo "    Found MAC address of gateway router: $gw_macaddr"
  echo "Leave blank AND press ENTER if you:"
  echo "  1. wish to listen to other traffic next to this gateway router."
  if [ -z "$gw_macaddr" ]; then
    echo "  2. do not know the MAC address of this gateway router."
  fi
  read -rp "MAC address of upstream gateway router: " -ei$gw_macaddr
  gw_macaddr="$REPLY"
  if [ -n "$gw_macaddr" ]; then
    INTF_OPTS+=",maclist"
    add_macaddr_to_maclist_config_file "$intfname_netdev" "$gw_macaddr"
  fi

  echo "$zone_netdev \$$intfname_netdev $INTF_OPTS" >> "$interfaces_output"

done
echo

# identify the netdev(s) to downstream Internet
# Compute remaining list of netdev(s) to assign
for this_gw in ${default_gw_netdevs_A[*]}; do
  downstream_netdevs="$(echo "$netdevs_list"| sed -e "s/$this_gw//")"
done
echo "Remaining netdevs: $downstream_netdevs"
echo "Processing non-public-side interfaces ..."

echo "Type in '0' and press ENTER to exit."
private_netdevs_A=()
selected_private_netdevs_list=""
echo "Press ENTER to skip a netdev."
PS3="Enter in netdev to firewall for non-Public-side network: "
select this_private_netdev in $downstream_netdevs; do
  echo "REPLY: $REPLY"
  if [ -z "$this_private_netdev" ]; then
    break
  fi
  selected_private_netdevs_list+="$this_private_netdev "
  echo "Selected non-public-side netdevs: $selected_private_netdevs_list"
done
echo "List of remaining private netdev(s): $selected_private_netdevs_list"
echo


###############################################################
for this_private_netdev in $selected_private_netdevs_list; do

  echo "  Processing $this_private_netdev non-public-side interface ..."

  # Seed interface options with the defaults
  # (must assumes at least 1 interface option, due to varibale CSV comma appends)
  INTF_OPTS="logmartians,tcpflags,routefilter"

  # if non-public interface is a bridge
  is_a_bridge="$(ip -o -4 link show dev $this_private_netdev type bridge)"
  if [ -n "$is_a_bridge" ]; then
    INTF_OPTS+=",routeback"
    INTF_OPTS+=",nosmurf"
  fi

  # autodetect 'dhcp' option for any kind of netdev
  # this is usually rare for non-upstream but supported here anyway
  netdev_isdynamic="$(ip -4 -o addr show dev $this_private_netdev | awk '{print $9}')"
  if [ "$netdev_isdynamic" == "dynamic" ]; then
    INTF_OPTS+=",dhcp"
  fi

  # Absolutely no UPnP interface option for public-facing netdevs
  read -rp "Do you want UPnP support on $this_private_netdev? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  if [ -n "$REPLY" ] && [ "$REPLY" == "y" ]; then
    INTF_OPTS+=",upnp"
  fi

  idx=0
  intfname_netdev="UNKNOWN_IP"
  for this_netdev in $netdevs_list; do
    if [ "$this_private_netdev" == "$this_netdev" ]; then
      zone_netdev="${netdev_zone_A[$idx]}"
      intfname_netdev="${netdev_labels_A[$idx]}"
    fi
    ((idx++))
  done
  echo "$zone_netdev    \$$intfname_netdev  $INTF_OPTS" >> "$interfaces_output"
  echo
done

echo "Done."
exit
