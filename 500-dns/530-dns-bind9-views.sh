#!/bin/bash
# File: 550-dns-bind-views.sh
# Title: Create a view
# Description:
#   Creates a view clause configuration file for inclusion
#   by ISC Bind9 named daemon configuration (`named.conf`)
#   file.
#
#   Also creates an accompany extension config file
#   (included by its view config file) for accomodating
#   additional settings by other scripts.
#
#   Then tacks on an 'include' clause of this 'view' into the
#   `views-named.conf` for final reading by `named.conf`
#
#
#   DESIGN RATIONALE
#
#   Views are commonly netdev-centric but some views
#   can be departmental-centric (within the same IP interface
#   but having different subnets (or even single IP in case of NAT'd router),
#   regardless of whether its IP interface has one or more
#   assigned IP addresses.)
#
#   This script only offers (for the moment) the netdev-centric
#   approach of creating views.
#     * one view per one netdev (a netdev may have one or more IP interface),
#     * * netdev can only be used by at most one view (script limitation)
#     * * a view can span more than one non-public netdev
#     * * a view can span more than 1 public netdev w/ 'ip route' entries (rare)
#     * A view must not have both public/non-public netdev (OpSec)
#     *
#
#   Ability to do departmental-centric (one view per multiple
#   subnet within same IP interface/subnet) is harder on the bash
#   programming with regard to required IP subnet masking,
#   calculation and validation.  If you need this, you have
#   elevated beyond the need of this and related script files.
#
# User Questionnarie Workflow
#  if only one available IP-assigned netdev interface
#    echo "No view needed; go straight to creating zone(s); aborted"
#    exit
#  fi
#  # Work on one new view at a time (re-run script for another new view)
#  while 1; do
#    read -rp "Enter in view name: "
#    PS3="Enter in a netdev to assign to 'view' view: "
#    select this_netdev in list_available_IP_assigned_netdevs; do
#      if REPLY matches public_ip; then
#        auto_add_all_IP_subnets_on_this_netdev_to_this_view
#        echo "This is a public 'view', no more interfaces"
#        echo "Done with '$view' view."
#        echo
#        remove this_netdev from list_available_IP_assigned_netdevs
#      fi
#    done
#  done
#
# Environment Names
#   VIEW_NAME - The name of the view to create
#   VERBOSE - see more things less tersely
#
DEFAULT_VIEW_NAME="${VIEW_NAME:-public}"

echo "Create a view in ISC Bind9"
echo

source ./maintainer-dns-isc.sh


if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Absolute build"
else
  FILE_SETTINGS_FILESPEC="${BUILDROOT}${CHROOT_DIR}/file-settings-named-views.sh"
  mkdir -p "$BUILDROOT"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$ETC_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_DIRSPEC"
  flex_mkdir "$ETC_NAMED_DIRSPEC"
  flex_mkdir "$VAR_LIB_NAMED_DIRSPEC"
  flex_mkdir "$VAR_CACHE_DIRSPEC"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ETC_NAMED_DIRSPEC ..."
  flex_mkdir "$INSTANCE_ETC_NAMED_DIRSPEC"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VAR_LIB_NAMED_DIRSPEC ..."
  flex_mkdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VAR_CACHE_NAMED_DIRSPEC ..."
  flex_mkdir "$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"
fi
echo

# Compile a list of IP-assigned interfaces
SYS_IP4_NETDEVS_A=($(ip -o -4 address show | awk '{print $4}'))
SYS_IP4_NETDEVS_COUNT="${#SYS_IP4_NETDEVS_A[@]}"
# echo "IP addresses are    : ${SYS_IP4_NETDEVS_A[*]}"

# How many IP-assigned interfaces are available for assignment to a view?
AVAIL_IP4_NETDEVS_A=($(echo "${SYS_IP4_NETDEVS_A[*]}" | xargs -n1 | grep -v 127.0.0.1 | xargs) )
AVAIL_IP4_NETDEVS_COUNT="${#AVAIL_IP4_NETDEVS_A[@]}"
echo "This system has     : $AVAIL_IP4_NETDEVS_COUNT available IP interfaces for view-assignments."
echo "View-assignable IPs : ${AVAIL_IP4_NETDEVS_A[*]}"
echo

if [ "$AVAIL_IP4_NETDEVS_COUNT" -le 1 ]; then  # TBS: -le
  echo "Not enough IP interfaces to justify needed a view."
  echo "No need to create a view, go straight to defining zone(s)."
  exit 13
fi
echo

# Ask the user for the view name (in form of a domain name) if not given via
# VIEW_NAME env var.
if [ -z "$VIEW_NAME" ]; then
  if [ -n "$DEFAULT_VIEW_NAME" ]; then
    read_opt="-i${DEFAULT_VIEW_NAME}"
  fi
  read -rp "Enter in name of a new view: " -e ${read_opt}
  VIEW_NAME="$REPLY"
fi

echo "Done."

# Determine recursion
NEED_RECURSION=yes
# if public interface then
#   query end-user if recursion should be turned off
# fi

# Determine forwarders
CAN_HAVE_FORWARDERS=yes
FORWARDERS_A=()
# if # of IP-interfaces is greater than 1 then
#   while this_interfaces in list_ip4_addresses; do
#     if this_interface is NOT a public-facing IPv4 interface then
#       if this_interface has IPv4 forwarding enabled then
#         for this_zone in zone_list; do
#           if this_zone_ipv4 == this_interface then
#             if this_zone clause has no file statement then
#               MUST_FORWARDERS=yes
#               FORWARDERS_TYPE=only
#             fi
#           fi
#         fi
#       fi
#     fi
#   done
# fi

# Prevention of forwarders
#
# # regardless of public-facing, IPv4 forwarding or zone settings
# # if 'hidden-master'/'hidden-primary' then VIEW_MUST_NOT_HAVE_FORWARDER='yes'

#
if [ "$MUST_HAVE_FORWARDERS" == 'yes' ]; then
  FORWARDERS=1
fi

# Determine DNS Security ('dnssec-enable yes;')
NEED_DNSSEC=yes


VIEW_CONF_FILEPART="view.${VIEW_NAME}"
VIEW_CONF_FILESUFFIX="named.conf"
VIEW_CONF_FILENAME="${VIEW_CONF_FILEPART}-$VIEW_CONF_FILESUFFIX"

# Vim syntax https://github.com/egberts/vim-syntax-bind-named now supports 'pz.*'
VIEW_CONF_EXTN_FILENAME="${VIEW_CONF_FILEPART}-extension-$VIEW_CONF_FILESUFFIX"

VIEW_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
VIEW_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${VIEW_CONF_FILENAME}"
INSTANCE_VIEW_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
INSTANCE_VIEW_CONF_FILESPEC="${INSTANCE_VIEW_CONF_DIRSPEC}/${VIEW_CONF_FILENAME}"
INSTANCE_VIEW_CONF_EXTN_FILESPEC="${INSTANCE_VIEW_CONF_DIRSPEC}/${VIEW_CONF_EXTN_FILENAME}"

INSTANCE_VIEW_KEYS_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"

#    key-directory "${INSTANCE_VIEW_KEYS_DIRSPEC}";
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VIEW_KEYS_DIRSPEC ..."
flex_mkdir "${INSTANCE_VIEW_KEYS_DIRSPEC}"
flex_chown "root:$GROUP_NAME" "$INSTANCE_VIEW_KEYS_DIRSPEC"
flex_chmod 0750               "$INSTANCE_VIEW_KEYS_DIRSPEC"



# EXTENSION TO THE VIEW CLAUSE
# EXTENSION TO THE VIEW CLAUSE
# EXTENSION TO THE VIEW CLAUSE

# include "${INSTANCE_VIEW_CONF_EXTN_FILESPEC}";
filespec="$INSTANCE_VIEW_CONF_EXTN_FILESPEC"
filename="$VIEW_CONF_EXTN_FILENAME"
filepath="$INSTANCE_VIEW_CONF_DIRSPEC"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VIEW_CONF_EXTN_FILESPEC ..."
cat << VIEW_EXTN_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VIEW_CONF_EXTN_FILESPEC" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: View '${VIEW_NAME}' extension configuration file
# Generator: $(basename "$0")
# Date: $(date)
# Description:
#   To validate the syntax of all named configuration files, execute:
#
#     named-checkconf $INSTANCE_NAMED_CONF_FILESPEC
#
#   This file gets included by $INSTANCE_VIEW_CONF_FILESPEC configuration file.
#
# Settings that goes into the extension part of its view configuration file
#  RNDC-related
#    allow-new-zones no;   // RNDC ACL
#  Cache-related
#    additional-from-cache (yes | no) ; [ Opt, View ]
#    attach-cache string
#    glue-cache boolean;
#    max-cache-size size_in_bytes ; [ Opt, View ]
#    max-cache-ttl seconds; [ Opt, View ]
#    max-ncache-ttl seconds; [ Opt, View ]
#    min-cache-ttl duration;
#    min-ncache-ttl duration;
#    prefetch integer;  [ View ]  # new since 9.6
#  Notify-related
#    allow-notify { address_match_list }; [ Opt, View, Zone ]
#    also-notify { ip_addr [port ip_port] ; ... ] }; [ Opt, View, Zone ]
#    notify ( yes | no | explicit | master-only ); [ Opt, View, Zone ]
#    notify-delay integer;  [ View ]  # new since 9.6
#    notify-source (ip4_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    notify-source-v6 (ip6_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    notify-to-soa ( yes | no ); [ View ]
#  Query-related
#    allow-query { address_match_list }; [ Opt, View, Zone ]
#    allow-query-cache { address_match_list }; [ Opt, View, Zone ]
#    allow-query-cache-on { address_match_list }; [ Opt, View, Zone ]
#    allow-query-on { address_match_list }; [ Opt, View, Zone ]
#    deny-answer-addresses { address_match_element; ... } [
#        except-from { string; ... } ];
#    deny-answer-aliases { string; ... } [ except-from { string; ...  } ];
#  CISecurity says not to use 'query-source[-v6]'
#    query-source [ address ( ip_addr | * ) ] [ port ( ip_port | * ) ]; [ Opt, View ]
#    query-source-v6 [ address ( ip_addr | * ) ] [ port ( ip_port | * ) ]; [ Opt, View ]
#  Recursion-related
#    allow-recursion { address_match_list }; [ Opt, View ]
#    allow-recursion-on { address_match_list }; [ Opt, View ]
#    match-recursive-only ( yes | no ) ; [ View ]
#    max-recursion-depth integer;  [ View ] # new since 9.6
#    max-recursion-queue integer;  [ View ] new since 9.6
#    recursion ( yes | no ); [ Opt, View ]
#  Transfer-related
#    allow-transfer { address_match_list }; [ Opt, View, Zone ]
#    alt-transfer-source ( ipv4 | * ) [ port ( integer | * )]; [ Opt, View, Zone ]
#    alt-transfer-source-v6 ( ipv6 | * ) [ port ( integer | * ) ]; [ Opt, View, Zone ]
#    ixfr-from-differences ( primary | master | secondary | slave |
#        boolean );
#    masterfile-format
#    masterfile-style
#    max-ixfr-ratio ( unlimited | percentage );  # new since 9.6
#    max-transfer-idle-in minutes; [ Opt, View, Zone ]
#    max-transfer-idle-out minutes; [ Opt, View, Zone ]
#    max-transfer-time-in minutes; [ Opt, View, Zone ]
#    max-transfer-time-out minutes; [ Opt, View, Zone ]
#    provide-ixfr ( yes | no) ; [ Opt, View, server ]
#    request-ixfr ( yes | no ); [ Opt, View, server ]
#    transfer-format ( one-answer | many-answers ); [ Opt, View, server ]
#    transfer-source (ip4_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    transfer-source-v6 (ip6_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    use-alt-transfer-source ( yes | no ); [ Opt, View, Zone ]
#  Update-relatd
#    allow-update { address_match_element; ... };
#    allow-update-forwarding { address_match_list }; [ Opt, View, Zone ]
#    serial-update-method ( date | increment | unixtime );  [ View ]  # new since 9.6
#
#  DNSSEC-related
#    dnssec-accept-expired
#    dnssec-dnskey-kskonly
#    dnssec-loadkeys-intervale
#    dnssec-must-be-secure
#    dnssec-policy
#    dnssec-secure-to-insecure
#    dnssec-update-mode
#    dnssec-validation
#    dnskey-sig-validity { }
#    inline-signing boolean;
#    nta-lifetime duration;  [ View ]  # new since 9.6
#    nta-recheck duration;  [ View ]  # new since 9.6
#    sig-signing-nodes integer ; [ Opt, View, Zone ]  # new since 9.6
#    sig-signing-signatures integer ; [ Opt, View, Zone ]  # new since 9.6
#    sig-signing-type integer ; [ Opt, View, Zone ]  # new since 9.6
#    sig-validity-interval days ; [ Opt, View, Zone ]
#    sig-validity-interval number ; [ Opt, View, Zone ]
#    trust-anchor-telemetry boolean;  [ View ]  # new since 9.6
#    trust-anchors { };  [ View ]  # new since 9.6
#    trusted-keys { };  [ View ]  # new since 9.6
#
#  Daemon-related
#    catalog-zones
#    cleaning-interval number; [ Opt, View ]
#    disable-empty-zones
#    empty-contact
#    empty-server string
#    dialup dialup_options; [ Opt, View, Zone ]
#    dual-stack-servers [ port p_num ] { ( "id" [port p_num] |
#                  ipv4 [port p_num] | ipv6 [port p_num] ); ... }; [ Opt, View ]
#    key string {
#        algorithm string;
#        secret string;
#    };
#    plugin ( query ) string { };  [ View ]  # new since 9.6
#    server netprefix { };  [ View ]  # new since 9.6
#    v6-bias integer;  # new since 9.6
#
#  Dynamic zone-related
#    empty-zones-enable
#    dlz string { }
#    dyndb string quote { }
#    max-zone-ttl ( unlimited | duration );  [ View ]  # new since 9.6
#    zone-statistics ( full | terse | none | boolean )  [ View ]  # new since 9.6
#
#  DNS protocol-related
#    auth-nxdomain boolean;
#    dns64 netprefix { }
#    dns64-contact string { }
#    dns64-server string { }
#    dnstap { }
#    edns-udp-size size_in_bytes; [ Opt, View ]
#    forward ( first | only );
#    forwarders [ port integer ] [ dscp integer ] { ( ipv4_address
#        | ipv6_address ) [ port integer ] [ dscp integer ]; ... };
#    max-clients-per-queue;  # new since 9.6
#    max-journal-size size_in_bytes; [ Opt, View, Zone ]
#    max-records integer; [ View ]   # new since 9.6
#    max-refresh-time seconds ; [ Opt, View, Zone ]
#    max-retry-time seconds ; [ Opt, View, Zone ]
#    max-stale-ttl duration; [ View ]  # new since 9.6
#    max-udp-size integer; [ View ]  # new since 9.6
#    message-compression boolean;  [ View ]  # new since 9.6
#    minimal-responses ( yes | no ) ; [ Opt, View ]
#    multi-master ( yes | no ) ; [ Opt, View, Zone ]
#    no-case-compress { address_match_element; ... };  [ View ]  # new since 9.6
#    nxdomain-redirect string;  [ View ]  # new since 9.6
#    preferred-glue ( A | AAAA) ; [ Opt, View ]
#    request-expire ( yes | no ); [ Opt, View, server ]  # new since 9.6
#    request-nsid ( yes | no ); [ Opt, View, server ]  # new since 9.6
#    require-serveri-cookie ( yes | no ); [ Opt, View, server ]  # new since 9.6
#    resolver-nonbackoff-tries integer;  [ View ]  # new since 9.6
#    resolver-query-timeout integer;  [ View ]  # new since 9.6
#    resolver-retry-interval integer;  [ View ]  # new since 9.6
#    root-delegation-only [ exclude { namelist } ] ; [ Opt, View ]
#    root-key-sentinel boolean; ; [ Opt, View ]
#    rrset-order { order_spec ; [ order_spec ; ... ] ); [ Opt, View ]
#    send-cookie boolean;  [ View ]  # new since 9.6
#    servfail-ttl duration;
#    stale-answer-enable boolean; [ View ]  # new since 9.6
#    stale-answer-ttl duration; [ View ]  # new since 9.6
#    synth-from-dnssec boolean;  [ View ]  # new since 9.6
#    zero-no-soa-ttl boolean  # new since 9.6
#    zero-no-soa-ttl-cache boolean  # new since 9.6
#
#  Filtering/QoS/RateLimiting
#    fetch-quota-params integer fixedpoint fixedpoint fixedpoint;
#    fetches-per-server integer [ ( drop | fail ) ];
#    fetches-per-zone integer [ ( drop | fail ) ];
#    lame-ttl duration;
#    lmdb-mapsize sizeval; # ( new since 9.6)
#    match-clients { address_match_list } ; [ View ]
#    match-destinations { address_match_list } ; [ View ]
#    rate-limit { };  [ View ]  # new since 9.6
#    sortlist { address_match_list }; [ Opt, View ]

##############################################################
#    minimal-any ( yes | no ) ; [ Opt, View ]   # new since 9.6
#    qname-minimization ( strict | relaxed | disabled | off ); [ View ]  # new #    since 9.6

VIEW_EXTN_CONF_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640               "$filespec"

# THE VIEW CLAUSE
# THE VIEW CLAUSE
# THE VIEW CLAUSE
# Lastly, create THE view configuration file

# Settings that goes into this main part of view configuration file
#    auth-nxdomain (yes | no); [ Opt, View ]
#    disable-algorithms string { string; ... }; [ Opt, View ]
#    disable-ds-digest
#    dnssec-must-be-secure domain ( yes | no); [ Opt, View ]
#    hostname hostname_string; ; [ Opt, View ]
#    key-directory path_name; [ Opt, View, Zone ]
#    zone-statistics ( yes | no ) ; [ Opt, View, Zone ]


filename="$VIEW_CONF_FILENAME"
filepath="$INSTANCE_VIEW_CONF_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << VIEW_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: View Configuration file for the '${VIEW_NAME}' view.
# Generator: $(basename "$0")
# Created on: $(date)
#
# Description:
#   To validate the syntax of all named configuration files, execute:
#
#     named-checkconf $INSTANCE_NAMED_CONF_FILESPEC
#
#   This file gets included by named.conf.
#   This file includes the '${INSTANCE_VIEW_CONF_EXTN_FILESPEC}' extension
#   configuration file.

//// The view statement is a powerful feature of BIND 9 that
//// lets a name server answer a DNS query differently depending
//// on who is asking. It is particularly useful for
//// implementing split DNS setups without having to run
//// multiple servers.

//// Views are class specific. If no class is given, class IN is
//// assumed. Note that all non-IN views must contain a hint
//// zone, since only the IN class has compiled-in default hints.

//// Zones defined within a view statement will only be
//// accessible to clients that match the view. By defining
//// a zone of the same name in multiple views, different
//// zone data can be given to different clients, for
//// example, "internal" and "external" clients in a split
//// DNS setup.

//// view is class dependent but the default class is IN
//// (or 'in' - not case dependent) and has been omitted.

//// Each view statement defines a view of the DNS namespace
//// that will be seen by a subset of clients. A client matches
//// a view if its source IP address matches the
//// address_match_list of the view's match-clients clause and
//// its destination IP address matches the address_match_list of
//// the view's match-destinations clause. If not specified, both
//// match-clients and match-destinations default to matching all
//// addresses. In addition to checking IP addresses
//// match-clients and match-destinations can also take keys
//// which provide an mechanism for the client to select the view.
//// A view can also be specified as match-recursive-only, which
//// means that only recursive requests from matching clients
//// will match that view. The order of the view statements is
//// significant a client request will be resolved in the context
//// of the first view that it matches.

view "$VIEW_NAME" IN
{
    // Should view have their own key directory (or leave that to the zones?)

    // conform to RFC 1035
    auth-nxdomain no;

    check-names response fail;
    check-names slave fail;
    check-names master fail;

    disable-algorithms "*" {
        RSAMD5;  // 1
        DH;      // DH;      // 2 - current standard
        DSA;     // DSA/SHA1;
        4;
        RSASHA1;             // RSA/SHA-1
        6;      // DSA-NSEC3-SHA1
        7;  // RSASHA1-NSEC3-SHA1
        //                   // RSASHA256;  // 8 - current standard
        9;                   // reserved
        //                   // RSASHA512;  // 10 - ideal standard
        11;                  // reserved
        12;                  // ECC-GOST; // GOST-R-34.10-2001
        //                   // ECDSAP256SHA256; // 13 - best standard
        //                   // ECDSAP384SHA384; // 14 - bestest standard
        //                   // ED25519; // 15
        //                   // ED448; // 16
        INDIRECT;
        PRIVATEDNS;
        PRIVATEOID;
        255;
        };

    // disables the SHA-256 digest for .net TLD only.
    disable-ds-digests "net" { "SHA-256"; };

    # following tcp-* is available at 9.15+
    ## tcp-idle-timeout 50;  # 5 seconds
    ## tcp-initial-timeout 25;  # 2.5 seconds minimal permitted
    ## tcp-keepalive-timeout 50;  # 5 seconds
    ## tcp-advertised-timeout 50;  # 5 seconds

#    new-zones-directory quoted_string;  [ View ]  # new since 9.6


VIEW_CONF_EOF

# THE VIEW CLAUSE, THE ENDING
# THE VIEW CLAUSE, THE ENDING
# THE VIEW CLAUSE, THE ENDING

# Finish 'view' clause configuration here
filename="$VIEW_CONF_FILENAME"
filepath="$INSTANCE_VIEW_CONF_DIRSPEC"
filespec="${filepath}/$filename"
echo "Finishing ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << VIEW_CONF_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null

    check-dup-records fail;
    check-integrity no;
    check-mx fail;
    check-mx-cname  fail;
    check-sibling no;
    check-spf warn;
    check-srv-cname fail;
    check-wildcard no;
    update-check-ksk yes;  # new since 9.6
    // multiple-cnames no;  // obsoleted in ISC Bind named v9.14


# Settings that goes into this extension part of the view configuration file
#    dnssec-enable ( yes | no ); [ Opt, View ]
#    auth-nxdomain (yes | no); [ Opt, View ]
#    disable-algorithms string { string; ... }; [ Opt, View ]
#    dnssec-must-be-secure domain ( yes | no); [ Opt, View ]
#    hostname hostname_string; ; [ Opt, View ]
#    key-directory path_name; [ Opt, View, Zone ]
#    zone-statistics ( yes | no ) ; [ Opt, View, Zone ]

# Add some flexible settings for this view via an extension file
include "${INSTANCE_VIEW_CONF_EXTN_FILESPEC}";

};

VIEW_CONF_EOF

flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"
echo

# THE GROUP OF VIEWS
# THE GROUP OF VIEWS
# THE GROUP OF VIEWS
# Finally insert the view into the main named.conf file via
# its extensible `views-named.conf` file.

# filespec="$INSTANCE_VIEW_NAMED_CONF_FILESPEC"
# filename="$(basename $INSTANCE_VIEW_NAMED_CONF_FILESPEC)"
# filepath="$(dirname $INSTANCE_VIEW_NAMED_CONF_FILESPEC)"
echo "Appending 'include "${BUILDROOT}${CHROOT_DIR}/$filespec"; to ${BUILDROOT}${CHROOT_DIR}$INSTANCE_VIEW_NAMED_CONF_FILESPEC ..."
echo "include \"$filespec\";" >> "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VIEW_NAMED_CONF_FILESPEC"
echo

# SYNTAX CHECKING OF named.conf
# SYNTAX CHECKING OF named.conf
# SYNTAX CHECKING OF named.conf
if [ $UID -ne 0 ]; then
  echo "NOTE: Unable to perform syntax-checking this in here."
  echo "      named-checkconf needs CAP_SYS_CHROOT capability in non-root $USER"
  echo "      ISC Bind9 Issue #3119"
  echo "You can execute:"
  echo "  $named_checkconf_filespec -i -p -c -x $named_chroot_opt $INSTANCE_NAMED_CONF_FILESPEC"
  read -rp "Do you want to sudo the previous command? (Y/n): " -eiY
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
fi
if [ "$REPLY" != 'n' ]; then
  pushd . > /dev/null

  if [ -n "$BUILDROOT" ]; then
    # Check syntax of named.conf file
    named_chroot_opt="-t ${BUILDROOT}${CHROOT_DIR}"
    # cd "${BUILDROOT}${CHROOT_DIR}" || exit 16
  fi

  # Check syntax of named.conf file
  named_chroot_opt="-t ${BUILDROOT}${CHROOT_DIR}"
  # cd "${BUILDROOT}${CHROOT_DIR}" || exit 16

# shellcheck disable=SC2086
# sudo /usr/sbin/named-checkconf -c -i -p -x -t build /etc/bind/named.conf

  sudo $named_checkconf_filespec -c \
    -i \
    -p \
    -x \
    $named_chroot_opt \
    "$INSTANCE_NAMED_CONF_FILESPEC"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
# shellcheck disable=SC2086
    sudo $named_checkconf_filespec \
      -i \
      -p \
      -x \
      "$named_chroot_opt" \
      "$INSTANCE_NAMED_CONF_FILESPEC"
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
    # popd || exit 15
    retsts=$?
  fi
  # popd || exit 15
  if [ $retsts -ne 0 ]; then
    exit $retsts
  else
    echo "Syntax-check passed for ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_NAMED_CONF_FILESPEC"
  fi
fi
echo


echo "Done."
