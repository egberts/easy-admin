This page details the interim construction of `named.conf` file for ISC
Bind9.:wq

BUILD directory
===============
A temporary '$CWD/build' directory is created to store all the user settings
of the upcoming Bind9 named.conf configurations.  BUILDROOT envar is defined
as './build'.

Also BUILDROOT is suffix with a `CHROOT_DIR` envar value in event of 
desired `chroot named`.  Example: `./build/var/chroot/named`.

Subdirectories are:

   ./build/partial-configs
   ./build/etc/bind
   ./build/usr/bin
   ./build/var
   ./build/var/bind
   ./build/var/bind/cache
   ./build/var/bind/lib   (zone files)
   ./build/var/bind/lib   (zone files)

Partial Configuration
---------------------

Subdirectory `partial-configs` under `BUILDROOT` holds the many `named`
configuration settings collected for creation of final `named.conf`.

Partial-Configs Organization
----------------------------

Configuration of `named.conf` are nested by:

* IP interface
* Instances of `named` daemons (how many)
* `view`(s) of each `named` daemon 
* `zone`(s) of each `view` 

A simple `named-checkconf` ensures a correct syntax at anytime.

IP Interfaces
=============
When on a host being configured for, it may select-prompt a list of available
IP links.

Available IP link is determined by an IP address assigned to an OS netdev.

`view` and `zone` can then use these selectable IP interface(s).

* Auto-determination of IP links for:
  * Local Dynamic IP Address
    * restricts a lot of available config setttings depending on either hot/cold side.
  * Gateway
    * simple, single IP gateway
    * multi-homed (the challenge of a roving laptop)
    * dual-stack IPv4/IPv6 gateway (getting more common).
  * Virtualized IP subnet
    * netdev that is used in bridging, VPS, LXC, VLAN, MACVLAN, 802.1x
    * Pay attention to overlapping and hairpin subnets

These IP interfaces directly set the `listen-on` and `listen-on-v6` statements.


Local Dynamic IP Addressing
---------------------------
Nearly all DNS servers require that all IP addresses being *known* and *defined* upfront before starting.

Dynamic IP address may be at the public-side (impacting master zones) or
may be at the private-side (impacting view `match-client` filtering).

IP Link are stored in partial-configs, its details are:

* IP address
* static/dynamic (presence of DHCP client)
* gateway or not (where the hot/public/red/Internet is)


Instances
=========
Instances are multiples of `named` daemons used to ensure separation of
UNIX process (and its threads) from other interfaces and `view`s.  

This enhanced security of using separate instance of UNIX daemon ensures 
safer data separation in event of non-filesystem-related data
compromises (such as memory leakage or network abuse/misuse).

Instance holds the following information:

* Name of instance; to aid with end-user visualization: eg.:
 * public/private,
 * internet/dmz/homelan, 
 * hot/cold, 
 * red/black

NOTE: In some rare cases, such hot-side may refer to a white-lab (closed network).

Instance is a security feature.

View
====

View makes it possible to provide a different answer of a DNS record toward 
different remote clients that is doing the querying.

View is an abstract construct devised by ISC Bind9.

Examples of `view` usage would be for:

* external network
  * 'vpn.portal.example.tld', provide VPN service to work-from-home employees.
  * 'ssh.portal.example.tld', provide SSH tunneling service to work-from-home employees.
  * 'wireguard.portal.example.tld', provide Wireguard feature for Example employees.
  * 'tor.portal.example.tld', provide TOR node
  * it is common to bunch all of above into a single 'portal.example.tld' address, and something that you do not want internally-placed Example employees to use.
* internal or local network
  * 'internal.example.tld' only to those on internal network.
  * 'www.finance.example.tld', webserver only to those on financial network.
  * 'mx1.finance.example.tld', mailserver only to those on financial network.
  * 'git.engr.example.tld', private Git repo only to Example engineers
  * None of above should be obtained by anyone outside of internal network.
* de-militarized zone (DMZ)
  * 'dmz.example.tld' only to Internet of Things (IoT) used within 'example.tld'.
* geographical; 
  * 'us.ntp.org' provides answers only to remote IP residing in the United States. 
  * 'eu.ntp.org' for European Union.  
  * 'ca.ntp.org' for Canada.

`view` in `partial-configs` build directory holds the following information:

* View name
* Interfaces used, may be 'any;'

Zones
=====
Basically, a zone denotes all things that are below a 'period' in a domain name.

