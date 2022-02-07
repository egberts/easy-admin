General Setup Workflow 
======================

DNS Setup Questionnaire
-----------------------

Definitions
-----------
The terms of Top-level domain (TLD), domain name, 
second-level domain (2LD), and subdomain and its 
definition would not work very well here; we use 
“zone” as a concept therewithin. 

Zone Concept
------------

Zone concept has two basic abstractions: 

* zone name
* zone server

Zone Server
-----------

Zone server is more concisely called an authoritative DNS server 
out there but “zone server” is the shorter moniker here. 

CLUTTER-ALERT: here are many kinds of DNS servers: 

* authoritative, 
* recursive/caching, 
* filtering, 
* forwarding, 
* redirect, 
* mirror, 
* hint; 

but none of these essential functions will be mentioned within 
this article). 

It is all about the beginning of DNS: and that is the 
authoritative DNS server.  

Zone server is represented by the period symbol found in 
a typical long version of hostnames/domain names.   

          zone servers
              |
       +------+---+
       |      |   |
       V      V   V
    www.amazon.com.

Zone server is also a node of our tree of zone names.  
Each node offers a subdomain name (oops, that’s the 
next zone downward).

A zone server receives a zone name (of a given 
domain name) then decides which line to follow down to 
another node (zone server)  

Zone Name
---------

Zone name is a part of the label of the long-version 
hostname/domain name that does not have a period symbol 
in it.  

          zone servers
              |
       +------+---+
       |      |   |
       V      V   V
    www.amazon.com.
     ^    ^     ^
     |    |     |
    www amazon com
     ^    ^     ^
     |    |     |
     +------+---+
              |
          zone names

The term “zone” is understood and used by all DNS 
server software and their configuration.  Thankfully, 
the text-based zone database file format is also the 
same and interchangeable between different DNS software.

An example of “www.amazon.com.” is a fully-qualified 
domain name (FQDN) that has three zones: “www”, “amazon”, 
and “com”.  

It’s a neat trick to note in that each period in all 
domain (and long-versioned host-)names has at least 
one authoritative DNS server representing each of the 
period symbols.  

ANOTHER MIND-BENDER ALERT: often that last (rightmost) 
period symbol gets omitted in most data entry of 
hostnames; it is that extraneous keystroke there 
because DNS root servers are always mandatory … 
just to use the DNS lookup so why bother with the 
last period/keystroke).

UNSIMPLIFICATION ALERT:  DNS network engineers uses 
the rightmost period symbol to denote that name is a 
fully-qualified domain name (FQDN) and an absolute 
pathway toward the root server; absent that last 
period, it becomes a relative and these relative 
domain names can then be restackable and easily 
relocatable toward others zones/domain names.  
But you already would know that UNIX and DOS users 
have their “/“ at the beginning of a directory file 
specification as an absolute file pathway to the top 
of its filesystem and missing that beginning “/“ is a 
relative directory file specification from the point 
of its current working director.  Likewise, DNS 
network engineers used rightmost ending period to 
denote this same absolute and a missing period for a 
relative).  Don’t worry if you accidentally entered 
in that last character of a hostname/domain name with 
a period, most software will ignore it except DNS software.  

Root Zone
---------
Root zone is that top most part and starting point of 
an acyclic tree of all domain names (and long-version 
hostnames) used in today’s Internet. Root zone is 
represented by a lone period (“.”) symbol used at the 
rightmost part of all hostnames and domain names.  

          root zone server
                  |
                  |
                  |
                  V
    www.amazon.com.

There is no zone name for the root zone.

MIND-BENDER ALERT: however you will find a different 
hostname serving each and all root servers).  
Root zone is managed by 13 “Root Servers” throughout 
the world by ICANN. Lastly, all root servers are 
simply an authoritative DNS server (and are using no 
other features of most DNS servers we used today).

Zones are pointed to each other by SOA and NS resource 
records. And always in a graph tree fashion with no 
loop (hence acyclic graph).  

General Questionnaire Workflow
==============================
During any user-prompting of domain/zone names or IP 
address, any found interfaces should display 
the following info:

* interface name
* IP address
* IP subnet/netmask
* dynamic/static
* forwarding enabled
* default route

when stepping through the following suggested workflow:

* initialization
* View(s)
 * no view, single zone
  * Root Server
 * one view, single zone
 * departmental compartmentalization; N-views, same interface
 * split-horizon; N-views, different interfaces
 * bastion; one-view, different daemon instances
* Zone
 * Zone clause, user-defined
 * Zone database, user-defined
 * Zones, standard
* Interaction with other DNS servers
 * secondary(s) (formerly known as slave)
 * hidden-primary (formerly known as hidden-master)
 * split-NOTIFY/AXFR traffic
 * localhost /etc/resolv.conf
* Protocol Security
 * Recursion allowed
 * Querying rights
 * Transfer rights
 * Forwarding rights
* Customized Resource Records (RR)
 * Mail (SMTP/IMAP4/POP3/SUBMISSION/SMTPS/IMAP4S/POP3S/SUBMISSIONS)
 * Autodiscover/Autoconfig for remote email clients to find your email server
 * SSHFP
 * BIMI
 * OpenPGPKey


View
====
POV. How many different point of views? 
Mostly security POV or simply View(s) are used.

* Large enterprise may have many POVs such as finance, 
engineering, sales, marketing, HR, CxO suite)
* small-medium business would use two: public and internal
* standalone blog cloud server have none
* Homelab have three (or back to 2 if have multiple DNS servers)

User selects a list of IP address and/or interface/netdev name to 
assign toward a a view clause

* If view is on the public-side, flip ‘recursion’ to disable.

 * If this view is not a hidden-master, set ‘allow-query’ 
to its interface IP address in view clause, otherwise use ‘none;’

* If this view is on the private-side, prompt user for 
‘recursion’ (default is no). Set ‘allow-query’ to its 
interface IP address in the view clause.

For the remainder, do the following steps for each for each (or no) view:

zone clauses(s), user-defined
zone name & basic settings
database file and its basic resource records (SOA, NS, A or PTR
zone clause add-ons template file for different things based on its zone DB file and its IPs
by name
by IP address
repeat above for each subdomain as needed
zone clauses, standard
 loopback, 
in-addr.arpa., 
CHaos ‘version.bind’
unused RFC1918 (private address)
further customization
autoconfig/autodiscover; What mail client uses what?
autoconfig
Thunderbird, Mozilla
KMail (KDE)
Kontact (KDE)
Evolution (Gnome)
autodiscover
Outlook (Microsoft)
SSHFP
OPENPGPKEY
Hidden-Master
update ‘allow-notify’ on remote public master
‘direct-to-soa’ on hidden-master
DKIM
SPF
DMARC
locator(LOC)
HINFO (CPU/Model)
DNS Certification Authority Authorization (CAA) Resource Record (RFC 8659)
prompt for IP address of any secondary server
select the given zone names that this secondary server will offer to cover (not all secondary covers all zones equally, but often they do).
ask user if their chosen provider of secondary DNS offering are doing the split-NOTIFY/AXFR or not.  (Hurricane Electric.net does this).
update ‘also-notify’ within its zone clause
update the ‘allow-transfer’ within its zone clause

Master/Primary DNS Nameserver

ANY_IP_FORWARDING=$(any IP interface with forwarding IP option?)
while true
what are the primary zone names?
what configured (offline/online) IP interface does this primary zone listens on, answers for and toward clients about its own DNS zone file containing resource (RR) records of A/NS/MX/SRV/SOA related to ‘$this_zone’zone?
if zone name is a TLD (auto-determined)
if any interfaces on this primary zone is a default route, 
ERROR “cannot be a root server alongside the 13 existing Root Servers of the world due to ‘$this_interface’ selection and using a TLD of ‘$this_zone’; abort.
else if any one of IP interfaces assigned to this primary zone is an IP forwarding
warn “could not be a closednet”, needs TLD Exception option (TBA), hard whitelab problem
else if TLD, do you want a private Root Server?
create root server RRset (A/NS) in root zone in https://egbert.net/blog/articles/bind9-dnssec-root-server.html
`dnssec-keygen -a ECDSAP256SHA256 -n ZONE .`
inserted public key DS RR into the zone file by including the .key files using zone file$INCLUDE statements.
self-sign `dnssec-signzone -o . zone.root`
include `zone.root.signed` in named.conf
does primary zone have more than one interface? (auto-determined)
if one of zone’s interface has a default gateway, 
then a definite choice of this split-horizon, multi-instance submode (auto-determination)
(optional split horizon candidate)
else primary zone has one interface with default gateway out of any interfaces assigned to its zone (auto-determined, irregardless of IP forwarding)
if interface has dynamic IP (auto-determined)
do you want hidden master feature? default yes
if no, abort with a CAVEAT
if yes, select hidden-master feature 
if interface has static IP (auto-determined)
do you want hidden master feature? default no
if no, ignore.
if yes, select hidden-master for this zone

loop for each zone
if hidden-master selected then
add `notify-to-soa`
dnssec-keygen TSIG hmac-sha512
get IP info on former-master-soon-to-be-secondary for
`allow-transfer`
inform new secondary on new settings 
zone `type` to secondary
`allow-update`
new TSIG key

if no closednet, NOTE no IP interface found with IP forwarding enabled. 

Secondary DNS Nameserver

on this host, can this host also be a slave/secondary for other remotely-controlled DNS zones,

if so, what are the zone names?  

what are the other FQDN domain name(s) that this host can receive new and updated DNS records from other primary/master name-serving host(s) and can share those DNS records from this host.  

This counts as a secondary zone.
none;
egbert.net (hidden-master scenario on a public secondary)
ask for its remote nameserver’s full hostname. use as SOA MNAME.



1.  system settings
1.  Initialization
2.  RNDC control
3.  logging
5.  zones
  1.  localhost
  2.  pz.1.0.0.172.in-addr.arpa.
6.  



# TODO: Need to introduce more auto-determination based on current settings and
# setups.
#
# Line of User Questioning that failed:
#   How many interfaces (no, too specific)
#   Is this a workstation or a server? (resolver or authoritative/recursion)
#   Want caching or not?
#   Want forwarding or not?
#   Do you want resolver? (workstation)
#   Do you want recursion? (server)
#   What do you gonna do with your life?
#
#
# Auto-determination
#   NETDEV_LIST="eth0 eth1 eth2 br0 vmbr1 lo"
#   NETDEV_COUNT=5
#   PUBLICLAN_INTFS_A=("eth0")
#   PUBLICLAN_COUNT=1
#   PUBLICLAN_IP4=12.12.12.12
#   PRIVATELAN_NETDEV_LIST="eth1 eth2 br0 vmbr1 wifi0"  # minus lo and eth0
#   PHYSICAL_NETDEV_LIST="eth0 eth1 eth2 wifi0"  # 802.3/802.11
#   ROUTABLE_NETDEV_LIST="eth0 eth2 br0 "  # eth1/wifi0 is slave to br0
#                                          # vmbr1 is a closed-net
#
# 3-part questioning (recursive/authoritative/resolver)
#
#   recursive DNS server (server, private-facing-only)
#     which netdev to provide DNS records (loopback (lo) already selected)?
#     check that selected netdev is public-facing
#     if NETDEV_IS_PUBLIC_FACING then
#       echo "ERROR: MUST NOT do recursion on public-facing netdevs"; exit
#     else
#       needs more speedup of your DNS query responses? (workstation, server)
#         Risk: caching of bad query will take a while for this error to go away
#         You offering a DNS resolver on your local host (workstation, server)
#       Need to use forwarder(s)?
#       if multiple-netdev then
#         On your gateway, is that firewall blocking the forwarding of this DNS 
#         port 53/udp/tcp? (Say no, if YDK)
#         If forwarding of DNS port 53/udp/tcp open?
#           - Router with default-deny firewall AND
#           - Router with split-horizon/bastion DNS nameservers running
#           - CAN_DO_DNS_PASSTHROUGH_FORWARDING=0
#           - MUST_HAVE_FORWARDING=1
#           - MUST_HAVE_FORWARDERS=1
#           - MAY_DO_FORWARDING=x
#           - MAY_DO_FORWARDERS=x
#         else if there is no firewall blocking of DNS querying at the gateway, do you want this DNS server to forward DNS queries to selected upstream nameservers (of your choice)
#           - CAN_DO_DNS_PASSTHROUGH_FORWARDING=1
#           - MUST_HAVE_FORWARDING=0
#           - MUST_HAVE_FORWARDERS=0
#           - MAY_DO_FORWARDING=1
#           - MAY_DO_FORWARDERS=1
#           read "Do you want forwarding of DNS queries to a specific DNS server(s)?
#           if WANT_FORWARDING=1
#             forwarders 9.9.9.9;
#
#         Risk: if xxxx_FORWARDING='y', then upstream (ISP, Google, 
#             CloudFlare) DNS nameservers may be server-tracking you.  
#             Would be just fine if you OWN and OPERATE that upstream 
#             nameserver.
#         This forwarder is for this host? (or for a specific zones)
#           # determination of forwarders/forwarding 
#           if HOST_DEFAULT_DENY_FIREWALL == 'no'  &&
#              GATEWAY_DEFAULT_DENY_FIREWALL == 'no' then
#             prompt for external DNS nameservers (default listings 8.8.8.8;1.1.1.1?)
#           else
#             use gateway as its only nameserver
#           fi
#     fi
#
#   authoritative DNS server (server, public-facing/private-facing):
#     You hosting a domain name of yours? (Y/N) (server)
#     How many domain name do you own and want to served out to somewhere?
#     Check this domain name's TLD (gTLD or not)?
#     if domain name's TLD is publically resolvable (or gTLD-owned)?
#       Domain XXXX needs to be served to public?
#       Domain XXXX needs to be served to private?
#       BOTH_SIDES_SERVED=PUBLIC & PRIVATE
#     else
#       Domain XXXX DOES needs to be served to private (don't ask)
#     fi
#     IF For this domain, on this host, is this DNS server going to be 
#         the primary/master nameserver?
#       MUST_NO_RECURSION='$domain_name'
#       MUST_NO_ALLOW_RECURSION=1
#       ZONE_TYPE='primary'
#     ELSEIF for this domain, on this host, is this DNS server going 
#         to be the secondary/slave nameserver?
#       MUST_NO_RECURSION='$domain_name'
#       MUST_NO_ALLOW_RECURSION=1
#       ZONE_TYPE='secondary'
#     else
#       HAVE_RECURSION='$domain_name'
#       MAY_HAVE_ALLOW_RECURSION=1
#       echo "What exactly am I doing here?; aborted"
#       exit

#
#   WARNING: we do not touch resolver (/etc/resolv.conf) here.
#     to add/replace with this new nameserver,
#       edit 'nameserver 127.0.0.130' on /etc/resolv.conf
#       if /etc/resolv.conf is a symlink then
#         echo consult manual for systemd-resolverd/resolvconf if
#         echo /etc/resolv.conf is managed (symlinked)
#




if SPLIT_HORIZON_BASTION == 'yes' then
  # check for two on-line IP interfaces
  # check for upstream gateway
  # check for firewall blockages

