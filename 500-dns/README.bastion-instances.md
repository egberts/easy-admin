Bastion DNS server - by instance
=================================

Normally, nameserver (named) daemon is a single process on a host/server.

```
#     single-named (any view, any zones)
#     +------------------------------------------
#     | public |
#     |  WAN <--->
#     |Internet|
#     +--------|   named daemon
#     | private|
#     | LAN  <--->
#     | HomeNet| 
#     +------------------------------------------
#
```

A single `named` daemon can do pretty much everything: 

* authoritative, 
* recursive, 
* resolver, 
* forwarding, 
* stub, 
* zone mirroring, and even 
* root server.

Some further DNS nameserver conceptualizations (some of which 
are covered within this document) are: 

* split-horizon
* bastion nameservers
* hidden-master
* DNS filtering
* Secured DNS
* DNS over TCP
* DNS over HTTP

Split Horizon
-------------

Split-horizon entails defining multiple views to provide different
DNS record sets to different client hosts.

One downside, the split-horizon does cache DNS records between multiple views:
so if one common cached entry got poisoned, all 'views' suffers. 

The general idea of a bastion is to keep the inside stuff private and
away from lookie-loo outsiders, including cached DNS records.

Even when using bastion, views will still remains an important part 
of securing nameserver(s).

When it comes to bastion DNS server(s), the conceptual idea is
to provide separate querying port of DNS records for each network 
group without having to experience any potential cross-view cache 
poisoning: to do avoidance of cache poisoning, we
turn to separate daemons (and thusly separate configuration files).

```
#     Bastion (two-named)  [optional]
#     +------------------------------------------
#     | public |
#   <--> WAN <--->
#     |Internet|      named (public instance)
#     +--------|
#     |      <--->
#     |loopback+---------------------------------
#     |      <--->
#     +--------|
#     | private|      named (private instance)
#   <--> LAN <--->
#     | HomeNet| 
#     +------------------------------------------
#
```

Unlike the split-horizon (single named daemon) DNS that handles 
everything from all netdev interfaces, to handling all DNS queryings, 
to ALL caching, security of nameserving is further increased
by using two or more daemons/processes: hence the "bastion" concept.
Now we can prevent:

*  revealing details of inside network infrastructure
*  poisoning of DNS cached records
*  DDoS against the interior network

Also we can further enhance DNS daemons through one or 
more additional restrictions:

* file permission
* chroot separation
* additional process space per netdev interface
* network authorization/authentication 

File permissions will keep riff-raff out by other non-bind user ID process/user.

chroot separation ensures that a potentially defective/misconfigured named 
daemon will not be allow to look outside of its 'mini-ecofilesystem'.
This chroot protects the netdev/port from looking past the named-specific
mini-filesystem.

Additional process per interface ensures that DNS packets do not bleed into
the other network.

Network message digest authorization (using shared secret) can be 
added to ensure further restrictions to administration.

A simple bastion DNS server comprises of two named daemons/processes.

Several methods of bastion DNS server are:

1.  chroot per daemon per netdev interface

Hence, following security dictates:
- each RNDC key shall be unique and made readable-only to different group ID
- default 'rndc' shall not use /etc/bind/rndc.key (delete them)

So, what method is the most secured way for 'rndc' to handle both daemons?
```
Method 1 - For bastion setups
  generate two different rndc.key
    cd /etc/bind
    rm /etc/bind/rndc.conf
    rm /etc/bind/rndc.key
    rndc-confgen -a \
        -c /etc/bind/keys/rndc-public.key \
        -k rndc-public-key \
        -A hmac-sha512
    rndc-confgen -a \
        -c /etc/bind/keys/rndc-private.key \
        -k rndc-private-key \
        -A hmac-sha512
    # TBD: at what user-context does named daemon read the RNDC key files at?

    cat << RNDC_MASTER_CONF | tee /etc/bind/rndc.conf
    options {
	default-key "rndc-private-key";
	default-server 127.0.0.1;
	default-port 953;
    };
    server private {
	key "rndc-private-key";
        addresses { 127.0.0.1  port 953; };
    };
    server public {
	key "rndc-public-key";
        addresses { 127.0.0.1  port 954; };
    };
    # Always hide keys from main config file
    include "/etc/bind/keys/rndc-public.key";
    include "/etc/bind/keys/rndc-private.key";
    RNDC_MASTER_CONF

    cat << NAMED_CONTROLS_CONF | tee /etc/bind/public/controls-named.conf
    controls {
        inet 127.0.0.1 port 954
       	allow { 127.0.0.1; } keys { "rndc-public-key"; };
    };
    NAMED_CONTROLS_CONF
    echo "include "/etc/bind/public/controls-named.conf" >> /etc/bind/named-public.conf

    cat << NAMED_CONTROLS_CONF | tee /etc/bind/private/controls-named.conf
    controls {
        inet 127.0.0.1 port 953
       	allow { 127.0.0.1; } keys { "rndc-private-key"; };
   
    NAMED_CONTROLS_CONF
    echo "include "/etc/bind/private/controls-named.conf" >> /etc/bind/named-private.conf

    systemctl restart named@public.service
    systemctl restart named@private.service
    rndc -s public status
    rndc -s private status

    # end-user has copy of RNDC key
    rndc -c ./rndc-end-user.conf status
```

```
Method 2 - For multiple end-users or system admins
  generate two different rndc.conf, each into two different files:
    cd /etc/bind
    rm /etc/bind/rndc.conf
    rndc-confgen -a \
        -c /etc/bind/keys/rndc-public.conf \
        -k public-rndc-key \
        -A hmac-sha512 \
        -p 953 \
        -u bind
    rndc-confgen -a \
        -c /etc/bind/keys/rndc-private.conf \
        -k private-rndc-key \
        -A hmac-sha512 \
        -p 954 \
        -u bind
    # cut last-half of rndc-public.conf, paste to /etc/bind/named-controls.conf
    # cut last-half of rndc-private.conf, append to /etc/bind/named-controls.conf
```

By extension, we can also run multiple bastions to provide 
further separation of network overlays.

```
#     Bastion (multiple-named)  [supported]
#     +--------+------------------+--------+
#     | public |                  |loopback|
#     |  WAN <---> named        <--->      |
#     |Internet|   (public)       |        |
#     +--------+------------------|        |
#     |  .     |     .            |        |
#     |  .     |     .            |        |
#     |  .     |     .            |        |
#     +--------+------------------|        |
#     | private|                  |        |
#     | LAN  <---> named        <--->      |
#     | HomeNet|   (private)      |        |
#     +--------+------------------|        |
#     |offsite |                  |        |
#     |vmnet <---> named        <--->      |
#     |WhiteLab|   (whitelab)     |        |
#     +--------+---------------------------+
#     |newroot |                  |        |
#     |vmnet <---> named        <--->      |
#     |ns2     | (new DNS world)  |        |
#     +--------+---------------------------+
#
```
