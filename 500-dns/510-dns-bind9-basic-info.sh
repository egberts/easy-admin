#
# File: 510-dns-bind-basic-info.sh
# Title: Ask what kind of DNS system we are setting up for
#

TEST_DEFAULT_DOMAIN_NAME="egbert.net"

OUTSIDE_RELIABLE_CONTACT="8.8.8.8"  # used to determine Internet access

echo "Basic info for a new nameserver"
echo

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

# if multiple IP netdevs
#   Have an interior network to provide needed DNS recursive resolving?
#     NEED_RECURSIVE_FOR_INTERIOR_NETWORK = 'y'
#   if NEED_NAMED_RECURSIVE_FOR_INTERIOR_NETWORK then
#   else
#   fi
# else
#   Need to replace dnsmasq with Bind9 recursive resolver?
#   NEED_NAMED_RECURSIVE_FOR_STANDALONE_WORKSTATION='y'
# fi
#
# if 
HIDDEN_KEYNAME="offsite-key"
HIDDEN_PRIMARY_PORT=353
PRIMARY_NAME="primary_list_downstream_public_nameserver"

source ./maintainer-dns-isc.sh

# Are we making a build subdir or directly installing?
if [ "${BUILDROOT:0:1}" == '/' ]; then
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-basic-info${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "$BUILDROOT"
  rm -rf "$FILE_SETTINGS_FILESPEC"
  flex_mkdir "$INSTANCE_ETC_NAMED_DIRSPEC"
fi
echo
if [[ -z "$BUILDROOT" ]] || [[ "$BUILDROOT" == '/' ]]; then
  SUDO_BIN=sudo
  echo "Writing files as 'root'..."
else
  echo "Writing ALL files into $BUILDROOT as user '$USER')..."
fi

# Do this host have IPv4 or IPv6 up and running?
HAVE_IPV4=${HAVE_IPV4:-1}
# Verify IPv6 presence
if [ -d /proc/sys/net/ipv6 ]; then
  echo "Auto-detected IPv6 support; enabling IPv6"
  HAVE_IPV6=${HAVE_IPV6:-1}
else
  HAVE_IPV6=0
fi



#
#  User Interface Querying
#

# Have a domain name to manage? (HAVE_DOMAIN_TO_MANAGE='Y/n')
# if HAVE_DOMAIN_TO_MANAGE == 'y'
#   echo Setting up an exterior authoritative nameserver
#   find public IP address of this host (no multi-home support ... yet)
#   find internal IP address(es) of this host
# endif
read -rp "Do you have domain name(s) that you own and need to primary? (Y/n): " -eiY
REPLY="$(echo "$REPLY" | awk '{print tolower($1)}')"
HAVE_DOMAIN_TO_MANAGE="$REPLY"
echo
MY_DOMAINS=()
while true; do
  if [ -n "$TEST_DEFAULT_DOMAIN_NAME" ]; then
    read_opt="-i $TEST_DEFAULT_DOMAIN_NAME"
  else
    read_opt=
  fi
  read -rp "Enter in your domain name: " -e $read_opt
  [ -z "$REPLY" ] && break
  TEST_DEFAULT_DOMAIN_NAME=
  echo "Press ENTER to quit"
  MY_DOMAINS+=("$REPLY")
done
if [ ${#MY_DOMAINS[@]} -eq 0 ]; then
  echo "No domain entered; aborted."
  exit 13
fi
echo "MY_DOMAINS: ${MY_DOMAINS[*]}"

PRIMARY_IPV4_CANDIDATE="$(ip route get "$OUTSIDE_RELIABLE_CONTACT" | awk '{print $7}' | xargs)"
PRIMARY_NETDEV_CANDIDATE="$(ip route get "$OUTSIDE_RELIABLE_CONTACT" | awk '{print $5}' | xargs)"

echo "External-facing public netdev is:       $PRIMARY_NETDEV_CANDIDATE"
echo "External-facing public IPv4 address is: $PRIMARY_IPV4_CANDIDATE"
exit

DOMAIN_SOA="$(dig @${HIDDEN_PRIMARY_NS_IP4_ADDR} +short $DOMAIN_NAME SOA)"
DOMAIN_SOA_MNAME="$(echo "$DOMAIN_SOA" | awk '{print tolower($1)}')"

# Verify that local nameserver zone SOA also points to that remote nameserver

if [ "$SELECTED_NS" == "$DOMAIN_SOA_MNAME" ]; then
  echo "On LOCAL $SELECTED_NS nameserver,"
  echo "SOA MNAME $DOMAIN_SOA_MNAME is good."
else
  echo "ERROR: On the local $HIDDEN_PRIMARY_NS_IP4_ADDR nameserver, "
  echo "update the SOA MNAME in $DOMAIN_NAME zone file to $SELECTED_NS"
  echo "It is possible that this test of the IP has gotten firewall-blocked."
  echo "Or it is not up and running yet."
  echo "Continuing ..."
fi
echo

#

filename="$(basename "$INSTANCE_PRIMARY_NAMED_CONF_FILESPEC")"
filepath="$(dirname "$INSTANCE_PRIMARY_NAMED_CONF_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NAMED_PRIMARY_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: Declare the Hidden Primary (Master) 
# Generator: $(basename $0)
# Created on: $(date)
#
# Description:
#
#    Defines a list of one or more primaries that may be referenced 
#    from a primaries statement in a zone clause of type secondary or 
#    an 'also-notify' statement in a zone clause of type primary. 
#
#    Note: Somewhat confusing because the name, primaries, is used 
#    for both the free-standing clause and a statement within a 
#    zone clause.
#   
#    WARNING: Do not confuse 'primaries' clause here with 'primaries' 
#             statement in the zone clause
#
#    Who he declares a 'primaries' is the primary/master of all nameservers
#    including all secondary and downstream ones.
#   
#    primaries primary-name [port gp-num] 
#                         [dscp gd-num] 
#                         { 
#                           ( 
#                             primaries-list |
#                             IP-Address [port p-num] [key key]
#                           ) ; [...]
#                         }
#
#    primary-name is a unique name that references this primaries 
#    list. It can optionally be enclosed in a quoted string, 
#    but if a space appears in the primaries-name it must be 
#    enclosed in a quoted string, for example "my primary" 
#    (quoted string required) but "my-primary" (quoted string is 
#    optional). 
#
#    Multiple primaries clauses may be defined, each 
#    having a unique primaries-name. 
#
#    gp-num defines a port number that will be applied to 
#    all IP addresses in the defined list unless 
#    explicity overwritten by a port p-num element 
#    which applies only to a specific IP-Address (default in 
#    both cases is port 53). 
#
#    key-name refers to a 'key' clause which may be use to 
#    authenticate the zone transfer or the NOTIFY message. 
#
#    From BIND 9.10 the clause also allows the use of a DiffServ 
#    Differentiated Service Code Point (DSCP) number 
#    (range 0 - 95, where supported by the OS), defined 
#    by gd-num, to be used to identify the traffic 
#    classification for all IP address in the primaries-list or 
#    the explictly defined IP-Address list.
#

primaries $PRIMARY_NAME {
    $PUBLIC_PRIMARY_IP4_ADDR port $HIDDEN_PRIMARY_PORT key $HIDDEN_KEYNAME;
};
NAMED_PRIMARY_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

# need to insert 'primaries_list_downstream_public_nameserver' into
# 'also-notify' statement of 'zone' clause for each appropriate zones
# that are to be hidden from this 'hidden primary' nameserver.
# Also requires 'notify explicit;' when using 'also-notify;'
ZONE_FILENAME="mz.$DOMAIN_NAME"
ADDRLIST_NOTIFY_ZONE_FILESPEC="$INSTANCE_ETC_NAMED_CONF/$ADDRLIST_NOTIFY_ZONE_FILENAME"
NOTIFY_OPTIONS_NAMED_CONF_FILENAME="options-notify-named.conf"
NOTIFY_INTERNALBASTION_OPTIONS_NAMED_CONF_FILENAME="options-internal-bastion-named.conf"
NOTIFY_INTERNALBASTION_OPTIONS_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$NOTIFY_INTERNALBASTION_OPTIONS_NAMED_CONF_FILENAME"
filename="$NOTIFY_OPTIONS_NAMED_CONF_FILENAME"


# Mmmmmmm, we need sub-zone settings
filename="mz.$DOMAIN_NAME.also-notify"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NOTIFY_OPTIONS_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: Notify sub-options within 'options' clause
# Generator: $(basename $0)
# Created on: $(date)
#

	// notify behaviour is applicable to both primary zones 
	// (with 'type master;') and secondary zones (with 'type slave;') 
	// and if set to 'yes' (the default) then, when a zone is 
	// loaded or changed, for example, after a zone transfer, 
	// NOTIFY messages are sent to the name servers defined in 
	// the NS records for the zone (except itself and the 
	// 'Primary Master' name server defined in the SOA record) 
	// and to any IPs listed in any also-notify statement.
	// 
	// * If set to 'no' NOTIFY messages are not sent.
	// * If set to 'explicit' NOTIFY is only sent to those IP(s) 
	//   listed in an also-notify statement.
	// If a global notify statement is 'no' an also-notify 
	// statement may be used to override it for a specific zone, 
	// and conversely if the global options contain an 
	// also-notify list, setting notify 'no' in the zone will 
	// override the global option. 
	//
	// This statement may be specified in zone, view clauses or 
	// in a global options clause.  Global notify is none.
	//
	// In short, push any changes that this server here made to
	// its zone databases toward other nameservers (most commonly
	// slave or downstream ones, rarely toward hidden-primaries)

	notify explicit;

	// who to notify when zones get updated
	// send NOTIFY messages to secondary DNS provider when the zone changes
	also-notify port $HIDDEN_PRIMARY_PORT {
		// cannot use ACL name here, 
		// can use 'primary_name' in 'primaries {}' list OR
		// can use IPv4/IPv6 address (with 'notify explicit')

                // the downstream public primary/master nameserver
		${PRIMARY_NAME};

		// the internal bastion of downstream 
		// internal (non-public) primary/master nameserver
include "$NOTIFY_INTERNALBASTION_OPTIONS_NAMED_CONF_FILESPEC"; // BASTION_INTERNAL_PRIMARY_IPV4_ADDR
		};

	// restrict DNS query to just the downstream primary nameserver
	// and localhost
	allow-query { 
		localhost;
		${PUBLIC_PRIMARY_IP4_ADDR};
		};
NOTIFY_OPTIONS_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

touch "${BUILDROOT}${CHROOT_DIR}$NOTIFY_INTERNALBASTION_OPTIONS_NAMED_CONF_FILESPEC"
filename="$(basename $INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC)"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << OPTIONS_LISTENON_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: 'listen-on' part of 'options' clause for named.conf
# Generator: $(basename $0)
# Created on: $(date)
#
# To be included within $INSTANCE_OPTIONS_NAMED_CONF_FILESPEC
#
# This file gets appended by 560-dns-bind-hidden-primary.sh
#

	listen-on port $HIDDEN_PRIMARY_PORT {
		${HIDDEN_PRIMARY_NS_IP4_ADDR};
		};

	//// notify-to-soa [no|yes]; // default is no.
	//// If yes do not check the nameservers in the NS RRset against
	//// the SOA MNAME.
	//// Normally a NOTIFY message is not sent to the SOA
	//// MNAME (SOA ORIGIN) as it is supposed to contain the
	//// name of the ultimate primary. Sometimes, however, a
	//// slave is listed as the SOA MNAME in hidden primary
	//// configurations and in that case you would want the
	//// ultimate primary to still send NOTIFY messages to all
	//// the nameservers listed in the NS RRset.
	// is this NS a Hidden-primary? Still send to MNAME in SOA
	notify-to-soa yes;

OPTIONS_LISTENON_EOF
flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"
echo

echo "Done."

