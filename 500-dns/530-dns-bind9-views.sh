#!/bin/bash
# File: 550-dns-bind-views.sh
# Title: Create a view
# Description:
#
# Environment Names
#   VIEW_NAME - The name of the view to create
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

# Ask the user for the view name (in form of a domain name) if not given via
# VIEW_NAME env var.
if [ -z "$VIEW_NAME" ]; then
  if [ -n "$DEFAULT_VIEW_NAME" ]; then
    read_opt="-i${DEFAULT_VIEW_NAME}"
  fi
  read -rp "Enter in name of domain: " -e ${read_opt}
  VIEW_NAME="$REPLY"
fi

# Compile a list of IP-assigned interfaces
SYS_IP4_NETDEVS_A=($(ip -o -4 address show | awk '{print $4}'))
SYS_IP4_NETDEVS_COUNT="${#SYS_IP4_NETDEVS_A[@]}"
echo "This system has     : $SYS_IP4_NETDEVS_COUNT IP-assigned interfaces."
echo "IP addresses are    : ${SYS_IP4_NETDEVS_A[*]}"

# How many IP-assigned interfaces are available for assignment to a view?
AVAIL_IP4_NETDEVS_A=($(echo "${SYS_IP4_NETDEVS_A[*]}" | xargs -n1 | grep -v 127.0.0.1 | xargs) )
AVAIL_IP4_NETDEVS_COUNT="${#AVAIL_IP4_NETDEVS_A[@]}"
echo "View-assignable IPs : ${AVAIL_IP4_NETDEVS_A[*]}"

if [ "$AVAIL_IP4_NETDEVS_COUNT" -eq 0 ]; then  # TBS: -le
  echo "No need to create a view, go straight to defining view."
  echo "  there is only $AVAIL_IP4_NETDEVS_COUNT IP-assigned interface."
  exit 13
fi
echo
echo "Done."

# Determine recursion
NEED_RECURSION=yes

# Determine forwarders
NEED_FORWARDERS=yes
FORWARDERS_A=()

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
#   This file gets included by $INSTANCE_VIEW_CONF_FILESPEC configuration file.
#
# Settings that goes into the extension  view configuration file
#  additional-from-auth (yes | no) ; [ Opt, View ]  # obsoleted by 9.16???
#    additional-from-cache (yes | no) ; [ Opt, View ]
#    allow-new-zones no;   // RNDC ACL
#    allow-notify { address_match_list }; [ Opt, View, Zone ]
#    allow-query { address_match_list }; [ Opt, View, Zone ]
#    allow-query-cache { address_match_list }; [ Opt, View, Zone ]
#    allow-query-cache-on { address_match_list }; [ Opt, View, Zone ]
#    allow-query-on { address_match_list }; [ Opt, View, Zone ]
#    allow-recursion { address_match_list }; [ Opt, View ]
#    allow-recursion-on { address_match_list }; [ Opt, View ]
#    allow-transfer { address_match_list }; [ Opt, View, Zone ]
#    allow-update { address_match_element; ... };
#    allow-update-forwarding { address_match_list }; [ Opt, View, Zone ]
#    also-notify { ip_addr [port ip_port] ; ... ] }; [ Opt, View, Zone ]
#    alt-transfer-source ( ipv4 | * ) [ port ( integer | * )]; [ Opt, View, Zone ]
#    alt-transfer-source-v6 ( ipv6 | * ) [ port ( integer | * ) ]; [ Opt, View, Zone ]
#    attach-cache string
#    auth-nxdomain boolean;
#    cleaning-interval number; [ Opt, View ]
#    catalog-zones
#    deny-answer-addresses { address_match_element; ... } [
#        except-from { string; ... } ];
#    deny-answer-aliases { string; ... } [ except-from { string; ...
        } ];
#    dialup dialup_options; [ Opt, View, Zone ]
#    disable-algorithms
#    disable-ds-digest
#    disable-empty-zones
#    dlz string { }
#    dns64 netprefix { }
#    dns64-contact string { }
#    dns64-server string { }
#    dnskey-sig-validity { }
#    ### dnssec-lookaside domain trust-anchor domain; [ Opt, View ] obsoleted???
#    dnssec-accept-expired
#    dnssec-dnskey-kskonly
#    dnssec-loadkeys-intervale
#    dnssec-must-be-secure
#    dnssec-policy
#    dnssec-secure-to-insecure
#    dnssec-update-mode
#    dnssec-validation
#    dnstap { }
#    dual-stack-servers [ port p_num ] { ( "id" [port p_num] |
#                  ipv4 [port p_num] | ipv6 [port p_num] ); ... }; [ Opt, View ]
#    dyndb string quote { }
#    edns-udp-size size_in_bytes; [ Opt, View ]
#    empty-contact
#    empty-server string
#    empty-zones-enable
#    fetch-quota-params integer fixedpoint fixedpoint fixedpoint;
#    fetches-per-server integer [ ( drop | fail ) ];
#    fetches-per-zone integer [ ( drop | fail ) ];
#    forward ( first | only );
#    forwarders [ port integer ] [ dscp integer ] { ( ipv4_address
#        | ipv6_address ) [ port integer ] [ dscp integer ]; ... };
#    glue-cache boolean;
#    ### heartbeat-interval minutes; [ Opt, View ]  # obsoleted
#    inline-signing boolean;
#    ixfr-from-differences ( primary | master | secondary | slave |
#        boolean );
#    key string {
#        algorithm string;
#        secret string;
#    };
#    lame-ttl duration;
#    lmdb-mapsize sizeval; # ( new since 9.6)
#    masterfile-format
#    masterfile-style
#    match-clients { address_match_list } ; [ View ]
#    match-destinations { address_match_list } ; [ View ]
#    match-recursive-only ( yes | no ) ; [ View ]
#    max-cache-size size_in_bytes ; [ Opt, View ]
#    max-clients-per-queue;  # new since 9.6
#    max-cache-ttl seconds; [ Opt, View ]
#    max-ixfr-ratio ( unlimited | percentage );  # new since 9.6
#    max-journal-size size_in_bytes; [ Opt, View, Zone ]
#    max-ncache-ttl seconds; [ Opt, View ]
#    max-records integer; [ View ]   # new since 9.6
#    max-recursion-depth integer;  [ View ] # new since 9.6
#    max-recursion-queue integer;  [ View ] new since 9.6
#    max-refresh-time seconds ; [ Opt, View, Zone ]
#    max-retry-time seconds ; [ Opt, View, Zone ]
#    max-stale-ttl duration; [ View ]  # new since 9.6
#    max-transfer-idle-in minutes; [ Opt, View, Zone ]
#    max-transfer-idle-out minutes; [ Opt, View, Zone ]
#    max-transfer-time-in minutes; [ Opt, View, Zone ]
#    max-transfer-time-out minutes; [ Opt, View, Zone ]
#    max-udp-size integer; [ View ]  # new since 9.6
#    max-zone-ttl ( unlimited | duration );  [ View ]  # new since 9.6
#    message-compression boolean;  [ View ]  # new since 9.6
#    min-cache-ttl duration;
#    min-ncache-ttl duration;
#    min-refresh-time seconds ; [ Opt, View, Zone ]
#    min-retry-time seconds ; [ Opt, View, Zone ]
#    minimal-any ( yes | no ) ; [ Opt, View ]   # new since 9.6
#    minimal-responses ( yes | no ) ; [ Opt, View ]
#    multi-master ( yes | no ) ; [ Opt, View, Zone ]
#    new-zones-directory quoted_string;  [ View ]  # new since 9.6
#    no-case-compress { address_match_element; ... };  [ View ]  # new since 9.6
#    notify ( yes | no | explicit | master-only ); [ Opt, View, Zone ]
#    notify-delay integer;  [ View ]  # new since 9.6
#    notify-source (ip4_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    notify-source-v6 (ip6_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    notify-to-soa ( yes | no ); [ View ]
#    nta-lifetime duration;  [ View ]  # new since 9.6
#    nta-recheck duration;  [ View ]  # new since 9.6
#    nxdomain-redirect string;  [ View ]  # new since 9.6
#    plugin ( query ) string { };  [ View ]  # new since 9.6
#    preferred-glue ( A | AAAA) ; [ Opt, View ]
#    prefetch integer;  [ View ]  # new since 9.6
#    provide-ixfr ( yes | no) ; [ Opt, View, server ]
#    qname-minimization ( strict | relaxed | disabled | off ); [ View ]  # new #    since 9.6
#  CISecurity says not to use 'query-source[-v6]'
#    query-source [ address ( ip_addr | * ) ] [ port ( ip_port | * ) ]; [ Opt, View ]
#    query-source-v6 [ address ( ip_addr | * ) ] [ port ( ip_port | * ) ]; [ Opt, View ]
#    rate-limit { };  [ View ]  # new since 9.6
#    recursion ( yes | no ); [ Opt, View ]
#    request-expire ( yes | no ); [ Opt, View, server ]  # new since 9.6
#    request-ixfr ( yes | no ); [ Opt, View, server ]
#    request-nsid ( yes | no ); [ Opt, View, server ]  # new since 9.6
#    require-serveri-cookie ( yes | no ); [ Opt, View, server ]  # new since 9.6
#    resolver-nonbackoff-tries integer;  [ View ]  # new since 9.6
#    resolver-query-timeout integer;  [ View ]  # new since 9.6
#    resolver-retry-interval integer;  [ View ]  # new since 9.6
#    response-padding { } block_size integer; [ View]  # new since 9.6
#    response-policy { }; [ View]  # new since 9.6
#    root-delegation-only [ exclude { namelist } ] ; [ Opt, View ]
#    root-key-sentinel boolean; ; [ Opt, View ]
#    rrset-order { order_spec ; [ order_spec ; ... ] ); [ Opt, View ]
#    send-cookie boolean;  [ View ]  # new since 9.6
#    serial-update-method ( date | increment | unixtime );  [ View ]  # new since 9.6
#    server netprefix { };  [ View ]  # new since 9.6
#    sig-validity-interval number ; [ Opt, View, Zone ]
#    servfail-ttl duration;
#    sig-signing-nodes integer ; [ Opt, View, Zone ]  # new since 9.6
#    sig-signing-signatures integer ; [ Opt, View, Zone ]  # new since 9.6
#    sig-signing-type integer ; [ Opt, View, Zone ]  # new since 9.6
#    sig-validity-interval days ; [ Opt, View, Zone ]
#    sortlist { address_match_list }; [ Opt, View ]
#    stale-answer-enable boolean; [ View ]  # new since 9.6
#    stale-answer-ttl duration; [ View ]  # new since 9.6
#    synth-from-dnssec boolean;  [ View ]  # new since 9.6
#    transfer-format ( one-answer | many-answers ); [ Opt, View, server ]
#    transfer-source (ip4_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    transfer-source-v6 (ip6_addr | *) [port ip_port] ; [ Opt, View, Zone ]
#    trust-anchor-telemetry boolean;  [ View ]  # new since 9.6
#    trust-anchors { };  [ View ]  # new since 9.6
#    trusted-keys { };  [ View ]  # new since 9.6
#    try-tcp-refresh boolean;  [ View ]  # new since 9.6
#    use-alt-transfer-source ( yes | no ); [ Opt, View, Zone ]
#    v6-bias integer;  # new since 9.6
#    zero-no-soa-ttl boolean  # new since 9.6
#    zero-no-soa-ttl-cache boolean  # new since 9.6
#    zone-statistics ( full | terse | none | boolean )  [ View ]  # new since 9.6

VIEW_EXTN_CONF_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640               "$filespec"

# Lastly, create THE view configuration file

# Settings that goes into this main part of view configuration file
#    dnssec-enable ( yes | no ); [ Opt, View ]
#    auth-nxdomain (yes | no); [ Opt, View ]
#    disable-algorithms string { string; ... }; [ Opt, View ]
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

    dnssec-enable yes;

    key-directory quoted_string;

    // conform to RFC 1035
    auth-nxdomain no;

    max-rsa-exponent-size 4096;

    // disables the SHA-256 digest for .net TLD only.
    disable-ds-digests "net" { "SHA-256"; };

    disable-algorithms "${FQ_ZONE_NAME}" {
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

    # The timeout is short because they don't need to allow for
    # much slowness on our metropolitan-area fibre network.
    # 5 seconds is based on my rough eyeball assessment when
    # typical DNS-over-TCP (DoT) connections are unlikely to be
    # ...
    tcp-clients 25;
    # following tcp-* is available at 9.15+
    ## tcp-idle-timeout 50;  # 5 seconds
    ## tcp-initial-timeout 25;  # 2.5 seconds minimal permitted
    ## tcp-keepalive-timeout 50;  # 5 seconds
    ## tcp-advertised-timeout 50;  # 5 seconds



VIEW_CONF_EOF

# Write all the settings here for 'view' clause

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
    check-names response fail;
    check-names slave fail;
    check-names master fail;
    check-sibling no;
    check-spf warn;
    check-srv-cname fail;
    check-wildcard no;
    update-check-ksk boolean;  # new since 9.6
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

echo "Done."
