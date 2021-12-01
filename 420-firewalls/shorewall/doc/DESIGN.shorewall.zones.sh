# 'zones' config file for Shorewall
#
# The /etc/shorewall/zones file declares your network zones.
#
# You specify the hosts in each zone through entries
# in /etc/shorewall/interfaces or /etc/shorewall/hosts.
#
# The columns in the file are as follows (where the column name is
# followed by a different name in parentheses, the different name
# is used in the alternate specification syntax).
echo "ipv6/ipv4 comes later."
echo "netdev/interfaces comes later."
echo "Do all zones ... firstly."
echo ""
echo "Got a fancier zone design for Shorewall?"
echo "Or is this going to be a simple one-zone-per-interface firewall?"
user prompt is_a_one_zone_per_interface_firewall (Y/n)

echo "Here are some precanned set of labels to choose from"
echo "- public private dmz iot homelan lab dmz closednet external internal lan"
echo "- red green yellow white blue black orange purple"
user prompt list_of_labels (NAME/color)?

zone_names_A=()
interfaces_by_zone_A=()
# null - error if undefined
# 0 - 'unmanaged' interface option
# 1 - 'required/optional' interface option
is_this_interface_fw_managed_A=()  # tri-state (null/0/1)

# Pre-clear arrays
for this_interface in netdev_interfaces_list; do
  zones_by_interface_A[interface_idx]=""
  # leave is_this_interface_fw_managed_A[interface_idx] untouched (null)
done

reserved_zone_names="all none any SOURCE DEST"
if NOT is_a_one_zone_per_interface_firewall
  # A bit of pre-planning of zone/interface mapping is needed here
  # - A zone can span multiple interfaces (eth1/eth2/eth3 = homelan)
  # - An interface can span multiple zones (dmz/homelan/iot = eth1)
  # We are pre-defining ALL zone names ... firstly
  # prompt user for a zone name
  # assign multiple interfaces to it
  #
  # WHEW, here we go with multiple-zones-per-multiple-interfaces

  zone_idx=0
  while true; do
    user prompt "Enter in a new zone name: "
    zone_name=$REPLY
    zone_names_A+=($zone_name)
    if zone_name is empty
      break
    # ALways reused same full list of netdev interfaces for each zone
    select this_interface in netdev_interfaces_list; do
      if REPLY is '0'; break
      if interface_name is valid
        interface_idx=((REPLY--))
        zones_by_interface_A[interface_idx]+="$this_zone "
        interfaces_by_zone_A[zone_idx]=$REPLY
        # But remember which interfaces have been 'managed'.
        is_this_interface_fw_managed_A[interface_idx]=1
    done
  done
else  # is_a_one_zone_per_interface_firewall
  # Simple zoning laws (er, firewall)
  echo "We show a list of interfaces; you pick which one firstly, then label"
  echo "Enter in '0' to quit input loop"
  interface_idx=0
  netdev_interfaces_list
  select this_interface in netdev_interfaces_list; do
    if REPLY is 0, break
    if REPLY is valid
      list_of_labels="red green yellow white blue black orange purple"
      list_of_labels="public private dmz iot homelan lab dmz closednet external internal"
      echo "Enter in '0' to quit input loop"
      zone_idx=0
      select this_label in list_of_labels; do
        if REPLY is 0, break
        # invalid REPLY is also a valid label, take theirs
        if #REPLY is greater than 5
          echo "Length of zone name cannot be greater than 5"
          loop again
        if REPLY is in reserved_zone_names="all none any SOURCE DEST"
          echo "Cannot use reserved word like $reserved_zone_names"
          loop again
      done
      zone_names_A[zone_idx]=$REPLY
      is_this_interface_fw_managed_A[interface_idx]=1
      ((zone_idx++))
    fi
    ((interface_idx++))
  done
fi  # NOT is_a_one_zone_per_interface_firewall
echo "$zone_names_A[*]"

echo "Show what remaining interfaces will be left"
prompt user unzoned_interfaces_are_unmanaged_and_left_alone
if unzoned_interfaces_are_unmanaged_and_left_alone
  # mark it as unmanaged
  is_this_interface_fw_managed_A[interface_idx]=0
else
  error "MUST either zoneify an interface or mark it unmanaged"
fi


# Output /etc/shorewall/zones config file
OUTPUT_FILE="/etc/shorewall/zones"
printf "%s\t%s\t%s" zone_name, zone_type, zone_option
cat << ZONE_CONFIG_EOF | tee "${BUILDROOT}${CHROOT_DIR}$OUTPUT_FILE" >/dev/null
#
# File: zones
# Path: /etc/shorewall
# Title: Zone config file for Shorewall firewall
#
# Description:
#  ZONE - zone[:parent-zone[,parent-zone]...]
#
#  Name of the zone. Must start with a letter and consist of letters,
#  digits or '_'. The names "all", "none", "any", "SOURCE" and "DEST"
#  are reserved and may not be used as zone names.
#  The maximum length of a zone name is determined by the setting
#  of the LOGFORMAT option in shorewall.conf(5).
#  With the default LOGFORMAT, zone names can be at most 5 characters long.
#
#       The maximum length of an iptables log prefix is 29 bytes.
#       As explained in shorewall.conf (5), the legacy default
#       LOGPREFIX formatting string is “Shorewall:%s:%s:” where the
#       first %s is replaced by the chain name and the second is
#       replaced by the disposition.
#
#           The "Shorewall:%s:%s:" formatting string has 12 fixed
#               characters ("Shorewall" and three colons).
#
#           The longest of the standard dispositions are ACCEPT and
#               REJECT which have 6 characters each.
#
#           The canonical name for the chain containing the rules for
#               traffic going from zone 1 to zone 2 is
#               "<zone 1>2<zone 2>" or "<zone 1>-<zone 2>".
#
#           So if M is the maximum zone name length, such chains can
#               have length 2*M + 1.
#           12 + 6 + 2*M + 1 = 29 which reduces to
#           2*M = 29 - 12 - 6 - 1 = 10 or
#           M = 5
#
#       the LOGFORMAT in the default and sample shorewall.conf files
#       was changed to "%s:%s ".
#
#           That formatting string has 2 fixed characters (":" and a space).
#
#           So the maximum zone name length M is calculated as:
#           2 + 6 + 2*M + 1 = 29
#           2M = 29 - 2 - 6 - 1 = 20
#           M = 10
#
#   The order in which Shorewall matches addresses from packets
#   to zones is determined by the order of zone declarations.
#   Where a zone is nested in one or more other zones, you may
#   either ensure that the nested zone precedes its parents in
#   this file, or you may follow the (sub)zone name by ":" and
#   a comma-separated list of the parent zones. The parent zones
#   must have been declared in earlier records in this file.
#   See shorewall-nesting(5) for additional information.
#
#   Example:
#
#   #ZONE     TYPE     OPTIONS         IN OPTIONS        OUT OPTIONS
#   a         ip
#   b         ip
#   c:a,b     ip
#
#   Currently, Shorewall uses this information to reorder the zone
#   list so that parent zones appear after their subzones in the
#   list. The IMPLICIT_CONTINUE option in shorewall.conf(5) can
#   also create implicit CONTINUE policies to/from the subzone.
#
#   Where an ipsec zone is explicitly included as a child of an
#   ip zone, the ruleset allows CONTINUE policies (explicit or
#   implicit) to work as expected.
#
#   In the future, Shorewall may make additional use of nesting
#   information.
#YPE
#
#   ip
#
#       This is the standard Shorewall zone type and is the default
#   if you leave this column empty or if you enter "-" in the
#   column. Communication with some zone hosts may be encrypted.
#   Encrypted hosts are designated using the 'ipsec' option in
#   shorewall-hosts(5). For clarity, this zone type may be specified
#   as ipv4 in IPv4 configurations and ipv6 in IPv6 configurations.
#   ipsec
#
#       Communication with all zone hosts is encrypted. Your kernel
#       and iptables must include policy match support.
#       For clarity, this zone type may be specified as ipsec4 in
#       IPv4 configurations and ipsec6 in IPv6 configurations.
#   firewall
#
#       Designates the firewall itself. You must have exactly one
#       'firewall' zone. No options are permitted with a 'firewall'
#       zone. The name that you enter in the ZONE column will be
#       stored in the shell variable $FW which you may use in other
#       configuration files to designate the firewall zone.
#   bport
#
#       The zone is associated with one or more ports on a single
#       bridge. For clarity, this zone type may be specified as
#       bport4 in IPv4 configurations and bport6 in IPv6
#       configurations.
#   vserver
#
#       Added in Shorewall 4.4.11 Beta 2 -
#       A zone composed of Linux-vserver guests.
#       The zone contents must be defined in shorewall-hosts (5).
#
#       Vserver zones are implicitly handled as subzones of the
#       firewall zone.
#   loopback
#
#       Added in Shorewall 4.5.17.
#
#       Normally, Shorewall treats the loopback interface (lo) in
#       the following way:
#
#           By default, all traffic through the interface is ACCEPTed.
#
#           If a $FW -> $FW policy is defined or $FW -> $FW rules are
#           defined, they are placed in a chain named ${FW}2${F2} or
#           ${FW}-${FW} (e.g., 'fw2fw' or 'fw-fw' ) depending on
#           the ZONE2ZONE setting in shorewall.conf(5).
#
#           $FW -> $FW traffic is only filtered in the OUTPUT chain.
#
#       By defining a loopback zone and associating it with the
#       loopback interface in shorewall-interfaces(5), you can effect
#       a slightly different model. Suppose that the loopback zone
#       name is 'local'; then:
#
#           Both $FW -> local and local -> $FW chains are created.
#
#           The $FW -> local and local -> $FW policies may be different.
#
#           Both $FW -> local and local -> $FW rules may be specified.
#
#       Rules to/from the loopback zone and any zone other than the
#       firewall zone are ignored with a warning.
#
#       loopback zones may be nested within other loopback zones.
#   local
#
#       Added in Shorewall 4.5.17. local is the same as ipv4 with
#       the exception that the zone is only accessible from the
#       firewall and vserver zones.
#
# OPTIONS, IN OPTIONS and OUT OPTIONS (options, in_options,
# out_options) - [option[,option]...]
#
#   A comma-separated list of options. With the exception of the mss
#   and blacklist options, these only apply to TYPE ipsec zones.
#
#   dynamic_shared
#
#       May only be specified in the OPTIONS column and indicates
#       that only a single ipset should be created for this zone if
#       it has multiple dynamic entries in shorewall-hosts(5).
#       Without this option, a separate ipset is created for each interface.
#
#   reqid=number
#
#       where number is specified using setkey(8) using the
#       'unique:number option for the SPD level.
#
#   spi=<number>
#
#       where number is the SPI of the SA used to encrypt/decrypt packets.
#
#   proto=ah|esp|ipcomp
#
#       IPSEC Encapsulation Protocol
#
#   mss=number
#
#       sets the MSS field in TCP packets. If you supply this
#       option, you should also set FASTACCEPT=No in
#       shorewall.conf(5) to insure that both the SYN and
#       SYN,ACK packets have their MSS field adjusted.
#
#   mode=transport|tunnel
#
#       IPSEC mode
#
#   tunnel-src=address[/mask]
#
#       only available with mode=tunnel
#
#   tunnel-dst=address[/mask]
#
#       only available with mode=tunnel
#
#   strict
#
#       Means that packets must match all rules.
#
#   next
#
#       Separates rules; can only be used with strict
#
#   The options in the OPTIONS column are applied to both incoming
#   and outgoing traffic. The IN OPTIONS are applied to incoming
#   traffic (in addition to OPTIONS) and the OUT OPTIONS are applied
#   to outgoing traffic.
#
#   If you wish to leave a column empty but need to make an entry
#   in a following column, use "-".
ZONE_CONFIG_EOF

# Default entry for required 'firewall' zone
printf "%s\t%s\t%s" 'fw', 'firewall', '-'

# Loop print out all zones and its settings
zone_idx=0
for this_zone in zone_names_A[@]; do
  zone_name=$this_zone
  zone_type=$zone_types_A[zone_idx]
  zone_options=$zone_options_A[zone_idx]
  if [ -z "$zone_options" ]; then
    zone_options="-"
  fi
  printf "%s\t%s\t%s" zone_name, zone_type, zone_options
  ((zone_idx++))
done
