#!/bin/bash
# File: 560-dns-bind-primary-hidden.sh
# Title: Convert this primary into a hidden primary
# Description:
#
#   Formerly called 'hidden master'.

echo "Set up a hidden-primary nameserver"
echo "  (formerly known as 'hidden-master')"
echo "This script requires a properly working primary/secondary nameservers"
echo

HIDDEN_KEYNAME="offsite-key"
HIDDEN_PRIMARY_PORT=353
PRIMARY_NAME="primary_list_downstream_public_nameserver"

source ./maintainer-dns-isc.sh

if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Absolute build"
else
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-primaries-hidden-named.sh"
fi
echo

#
#  User Interface Querying
#
#  What is the domain name (zone) that will need this hidden-primary?
read -rp "TLD domain name that needs a hidden primary/master: "
REPLY="$(echo "$REPLY" | awk '{print tolower($1)}')"
DOMAIN_NAME="$REPLY"
echo

# Make sure that this host is NOT the public primary/master for 
# this domain-name's NS
LOCALHOST_MNAME="$(hostname -f)"
MNAME_LEN="${#LOCALHOST_MNAME}"
((--MNAME_LEN))
if [ "${LOCALHOST_MNAME:${MNAME_LEN}}" != '.' ]; then
  LOCALHOST_MNAME+='.'
fi

#    - Find domain's nameserver hostname via 'NS' resource record.
NS_LIST=()
# shellcheck disable=SC2207
NS_LIST=($(dig +short "$DOMAIN_NAME" NS ))

# run through each primary-secondary nameservers to get its SOA MNAME
# make sure they are all the same
MNAME_LIST=()
for this_ns in "${NS_LIST[@]}"; do
  # shellcheck disable=SC2086
  MNAME_LIST+=("$(dig +short @${this_ns} "$DOMAIN_NAME" SOA | awk '{print $1}')")
done
MNAME_REDUCED_LIST="$(echo "${MNAME_LIST[*]}" | xargs -n1 | sort -u | xargs)"
if [ "$(echo "$MNAME_REDUCED_LIST" | wc -w)" -ge 2 ]; then
  echo "Your public nameservers (both primary and secondaries) "
  echo "do not have consistent SOA MNAME"
  echo "Encountered MNAMEs: ${MNAME_REDUCED_LIST}"
  echo "Aborted."
  exit 13
fi

for this_ns in "${NS_LIST[@]}"; do
  if [ "$LOCALHOST_MNAME" == "$this_ns" ]; then
    echo "this host ($LOCALHOST_MNAME) IS one of the public server."
    echo "You need to move off to another host for a new hidden-primary/master."
    echo "Aborted."
    exit 13
  fi
done
echo "Made absolutely sure that this $LOCALHOST_MNAME host is NOT one of the "
echo "public nameserver for $DOMAIN_NAME TLD."
echo

SELECTED_NS="$MNAME_REDUCED_LIST"
# shellcheck disable=SC2086
PUBLIC_PRIMARY_IP4_ADDR="$(dig +short $SELECTED_NS A)"

#  That this host will be updating (as a hidden-primary/master),
#  is the remote hostname of the publicly-advertised nameserver correct?
#    - Ensure that zone database SOA MNAME has this remote hostname
# On the remote primary, SOA MNAME and its remote NS RR must be identical
# shellcheck disable=SC2086
DOMAIN_SOA="$(dig @${SELECTED_NS} +short $DOMAIN_NAME SOA)"
DOMAIN_SOA_MNAME="$(echo "$DOMAIN_SOA" | awk '{print tolower($1)}')"

if [ "$SELECTED_NS" == "$DOMAIN_SOA_MNAME" ]; then
  echo "On remote $SELECTED_NS nameserver,"
  echo "SOA MNAME $DOMAIN_SOA_MNAME is good."
else
  echo "ERROR: On remote $SELECTED_NS nameserver, update the SOA MNAME "
  echo "       in $DOMAIN_NAME zone file to $SELECTED_NS"
  exit 13
fi

HIDDEN_PRIMARY_NS_IP4_ADDR="$(ip route get "$PUBLIC_PRIMARY_IP4_ADDR" | awk '{print $7}' | xargs)"
# shellcheck disable=SC2086
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
# Generator: $(basename "$0")
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
# shellcheck disable=SC2034
ZONE_FILENAME="mz.$DOMAIN_NAME"
# shellcheck disable=SC2034
ADDRLIST_NOTIFY_ZONE_FILESPEC="${INSTANCE_ETC_NAMED_CONF}/$ADDRLIST_NOTIFY_ZONE_FILENAME"
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
# Generator: $(basename "$0")
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

	// notify-to-soa
	//
	// If yes, do not check the name servers defined in the NS RRset
	// against this zone's SOA MNAME.
	// Normally a NOTIFY message is not sent to the SOA MNAME 
	// (SOA ORIGIN), as it is supposed to contain the name of 
	// the ultimate primary server. Sometimes, however, a 
	// secondary server is listed as the SOA MNAME in hidden 
	// primary configurations; in that case, the ultimate 
	// primary should be set to still send NOTIFY messages 
	// to all the name servers listed in the NS RRset.
	//
	// 'notify-to-soa' can be used in 'options clause if
	// all Zones/Views needs this.
	//
	// The 'notify-to-soa' default is 'no'.

	notify-to-soa yes;

NOTIFY_OPTIONS_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

touch "${BUILDROOT}${CHROOT_DIR}$NOTIFY_INTERNALBASTION_OPTIONS_NAMED_CONF_FILESPEC"
filename="$(basename "$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC")"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << OPTIONS_LISTENON_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: 'listen-on' part of 'options' clause for named.conf
# Generator: $(basename "$0")
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

