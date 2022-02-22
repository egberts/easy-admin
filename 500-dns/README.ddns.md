What keywords are involved with Dynamic DNS (named + dhcpd)?

options {

// 'session-keyfile'
// TSIG gets written into this session-keyfile by named,
// read by ISC DHCP (dhcpd) server
// read by nsupdate CLI tool
//
	session-keyfile "/run/bind[/$INSTANCE]/session.key";


// 'session-keyalg'
// TSIG gets written into this session-keyfile by named
// this must match ISC DHCP (dhcpd) server's selection of TSIG algo

	session-keyalgo "hmac-sha512";


// 'session-keyname'
// Key name used to label this TSIG.
// The onvention between ISC named and dhcpd is to use 'local-ddns' keyname
// 

	session-keyname "local-ddns";


// 'allow-update-forwarding' can be used in
//  mirror zones, secondary zones, or 'options' (all-zones)
//  Most likely restricted to 'zone' clause due to specificity of a zone
allow-update-forwarding {
    acl_master_authoritative_server_ip;
    };
