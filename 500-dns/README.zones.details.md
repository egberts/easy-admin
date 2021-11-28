
Fun Zones
=========
This section details everything about a zone using 'portal.example.tld' as an
example.

Zone is a Part-Domain
---------------------
What is a zone?  

A zone provides for a part of a domain name.  

Part of a domain name has no period symbol in it.

`portal.example.tld` has three zones: `portal`, `example`, `tld`.

Zone also details how its own domain (`example.tld`) relates to its parent domain (`.tld`) and toward its own multiple (`portal.example.tld`) sub-zones, if any.

[jtable]
sub-domain domain  parent-domain
. 
tld        .
example    tld     .
portal     example tld 
-          portal  example.tld
[/jtable]

Zone - The Different Perspective
--------------------------------
Let me introduce you to a different perspective on domain names.  

This new perspective makes use of this example:

    `.portal.example.tld.`

Let us treat this period (`.`) symbol as each period equating with a DNS server: one period, one nameserver.

Just to have 'portal.example.tld' and make its availability for the world to do a lookup against this domain name, we would require at least 3 DNS servers (also called nameserver).

[jtable]
nameserver nameserver nameserver nameserver
. 
.tld       .
.example   .tld       .
.portal    .example   .tld         .
[/jtable]

Each period represents a nameserver.

The first (and ending) period (`.`) symbol represents the 13 Root Servers.
These Root Servers that handles the world's Internet need: No Root Server, no Internet.
Root Servers' major responsibility is to provide a lookup for top-level domain (TLD) names like `.com`, `.edu`, `.org`  and some 143 other TLDs.

Second period symbol, the `.tld` is handle by a ICANN-approved registar(s).  Each registar has its own
bank of nameservers across the world just to handle their own multi-millions of second-level domain names.

The third nameserver handles your `.example` zone and all its records pertaining
to `.example.tld`.  Your own nameserver will make your `example.tld` come alive
on the Internet.   No nameserver, no `example.tld`.  Must provide a nameserver
there.

Subsequential zone files (and if your own network traffic mandates this, additional nameservers) can then handle your ambitious expansion plan under `example.tld`.

Zone Overview
-------------
Given `.portal.example.tld.` we have:

Three zones and zone files:

* `tld`
* `example` 
* `portal` 

and four nameservers needed to dish out info about this domain name:

* Root Servers (.)
* TLD Registars (.tld)
* Your own domain (.example)
* Your expansion plan (.portal)

Zone File
---------
Zone file is a keyvalue-store database.  Zone file contains key/value stuff about a zone.  

A zone is that domain name (but without a period symbol in its name).

A zone file is often called the primary zone.  There is only one copy/one file
and one primary DNS server to dish it out.  There might be some secondary
nameservers to help out there.

NOTE: For the old readers, 'primary' used to be called 'master', and 'secondary' a 'slave'.

For the remainder of this article, a 'zone file' is that (lone) primary text-based file for its domain. To make changes to a zone, editing entails changing its primary zone file.

NOTE: In some DNS server software, there can be an accessible text-based zone file may that is used as a secondary zone file.  But most DNS server software have gone indexed binary-blob for secdonary zones.

Zone Schema
-----------
A zone file holds records (lines) of record type (or key) and each record holds one or more answers (or values).

Zone File Format
----------------
Zone file is a UNIX-ASCII-based flat-file format.  

Such a format of a Zone file is like a comma-separated-value format but without the commas.  Also takes ';' symbol as a comment part for the remainder of its line. 

DEEP-INSIGHT: Giant ISPs use full-blown database server instead of a zone text file.  Here, we focus on zone file being text-based instead of delving into database backends; because text-based zone file is more common scenario.

HISTORICAL: As administrators, we say that a zone file is actually the primary zone file.  Reason is that secondary zone file had since been redesigned to be a memory-stored, disk-checkpointed, indexed-binary blob format, which provides for the fastest response time with record answers (values).

Meanwhile, secondary zone file (only found in secondary nameserver) get its blob file automatically updated by its primary DNS server whose primary zone file remains in text-based format.

Henceforth, editing a zone file often means the only the primary aspect of zone file is being edited.

Secondary zone file get directly maintained by secondary nameserver software yet updated by its primary nameserver.  No administrator need be involved in the maintenance of these secondary zone files.  

You can peek at a secondary zone file, but not change it.

First Line - Zone File Format
-----------------------------
First line of a zone file contains enough information to describe this zone (or
domain name part not having a period symbol.)

    example.tld.  86400  SOA  ns1.example.tld. admin.example.tld. 2020103437 1200 180 1209600 10800

Breakdown of this single line in a zone file are:

* Zone name, that is being controlled by this primary zone file.
* SOA - a DNS record type (or key); stands for 'S'tart 'O'f 'A'uthority
* zone's primary nameserver who can be found to be holding this zone file.
* contact email ('@' got replaced with a period).
* A bunch of numbers containing serial number, time, duration.

Often times, the first line spans multiple lines in which to bunch a set of numbers surround by a pair of parenthesis, last line ending with the last line having its ending parenthesis.

    example.tld.  86400  SOA  ns1.example.tld. admin.example.tld. (
                              2020103437 
                              1200 
                              180 
                              1209600 
                              10800 )

More frequently than not, each line with a number has a comment after its number.

    example.tld.  86400  SOA  ns1.example.tld. admin.example.tld. (
                              2020103437  ; Xxxxx Xxx Xxxxx
                              1200        ; XXX Xx XXX
                              180         ; XXX Xx XXX
                              1209600     ; XXX Xx XXX
                              10800 )     ; XXX Xx XXX

Those numbers's comment will be detailed in further sections.

First Value of First Set of Lines - Zone File Format
--------------------------------------------
First value in the zone file begins with what this zone file controls: 

    'example.tld.'

There may be two (or more) domain parts in the first value.  

Notice the period at the end of `example.tld.`  This `example.tld` is an absolute form of fully-qualified domain name (FQDN).  

There are two kinds of zone file as determined by that first-value in its first-line.

* Absolute TLD path
* relative domain name

Absolute TLD path - First Value - First Lines - Zone File
--------------------------------------------------------
`example.tld.` zone file details additional records about its `example` domain part. 

Absolute TLD zone file does not detail anything past the first part of its FQDN
(the `.tld.` part)

Only the first domain part is focused within its zone file.  The rest of the
domain parts are there to assist DNS server software with where along the domain
path it belongs to.

For an absolute TLD path domain name, nothing can be added after the last period.  This domain name cannot be made extensible to any add-on domain names.  

This first value is the most useful and common choice for a top-most part of a domain that you control.

Relative Domain Name - First Value - First Lines - Zone File
-----------------------------------------------------------
Relative domain name is a simplier form of zone first value.  First value only
contains a part of a domain name: 

    example

If you control both zones (domain part) `portal` along with `example` within the same nameserver daemon (DNS server), then you can make the sub-domain `portal` a relative domain part (by omitting the ending period symbol).

If you control two or more back-to-back domain parts of the same FQDN, they too
can be made into a relative domain name in its own zone file.

This usage of relative domain name is most useful for moving entire part of a domain (zone file) around during:

* corporate merger, 
* department organizational lateral move, 
* partner sharing or 
* work from home scenarios 

This is done by doing a simple change to the nameserver configuration which is outside of its zone file(s).  

Zone file does not need to be changed in these situations (unless your network team is also shifting IP subnets around ... again).  

RANT: Shifting subnets around is a sign of bad network engineering practice; if you were to be using RFC1912 private subnets, you would not be using something common like 192.168.1.1/24, you would be using something esoteric like 172.28.251.0/20.


Second Value - First Lines - Zone File
-------------------------------------
TTL is how long should we be telling other people to remember our record type and answer (value/key) settings of a zone before asking us of the same answer again.

Time to Live (TTL) is the second value of the first line.

That's the `86400` part of the first line:

    example.tld.  86400  SOA  ns1.example.tld. admin.example.tld. 2020103437 1200 180 1209600 10800


TTL usefulness is when we might be moving to another nameserver, and to do that we must shorten this TTL firstly.  

CAVEAT: Decreasing TTL would increase DNS network traffic by however divisable we cut this TTL.  Cut TTL in half, we double traffic; third, triple ...

Planning is required about `86400` minutes ahead of time before one should be doing a nameserver or zone change.

Failure to plan `86400` ahead of time would definitely be a spotty outage of our zone for that remaining duration of 'their' remaining TTL when they obtained our original TTL setting.


SOA
---
Start of Authority (SOA) is a DNS record type.

SOA is pretty much always the first line of a zone file.

SOA is that authoritative record that governs how your FQDN (`portal.example.tld`) are to be used as consulted by secondary nameservers willing to help your primary nameserver.  Just DNS-NOTIFY and DNS-UPDATE with secondary nameservers. 

Nothing else for this 'SOA nameserver name' field.  Not the parent domain, nor its sub-domain. Just laterally across other secondary nameserver(s) (and in rare cases, hidden-master server): nothing else.

SOA is not the glue that is used to stitch domain parts together to make a FQDN:
that would be the joint-effort of root-server/registar/your-DNS-server's  job to
stitch the parts together.  Nothing to do with zone file.

SOA merely tells us the age, expiration, and caching duration of your zone.

`portal` SOA zone file also tells secondary nameserver(s) how often they should refresh their copy of your `portal` zone.  Same thing for each of the higher level of domain part in `portal.example.tld` FQDN.  Each level has their own set of primary and multiple secondary nameservers to keep this 'domain' alive.

SOA Primary Nameserver
-------------------------

Primary zone file needs to let others know where its own nameserver is.  SOA
primary nameserver is that place.

Controlling nameserver of the zone must also goes into the SOA record of
this zone file.  

It is very often that the hostname of the host that is running the DNS server is
used as this SOA primary nameserver.

HIDDEN-MASTER: The name of the controlling nameserver doesn't have to be the
same host that your nameserver is running on.  
We call this 'hidden-master' mode.  
This hidden-master is useful when the zone file resides ELSEWHERE other than where the primary (and often public-facing) nameserver is in control of the zone.

To see SOA in action for the 13 Root Servers, we have a special Root Server domain name (a period (`.`) symbol) in which to run this command:

    dig  @8.8.8.8  .  SOA

And showing just the ANSWER section:

    ;; ANSWER SECTION:
    .			xxxxx	xx	SOA	a.root-servers.net. xxxxx.xxxxxxxxxxxx.xxx. xxxxxxxxxx xxxx xxx xxxxxx xxxxx

Even the Root Servers has a name:  `a.root-servers.net.`.

However, the actual authority of the Root Servers is spread out over 13 primary
nameservers:

    ;; AUTHORITY SECTION:
    .			17556	IN	NS	i.root-servers.net.
    .			17556	IN	NS	b.root-servers.net.
    .			17556	IN	NS	e.root-servers.net.
    .			17556	IN	NS	d.root-servers.net.
    .			17556	IN	NS	c.root-servers.net.
    .			17556	IN	NS	j.root-servers.net.
    .			17556	IN	NS	l.root-servers.net.
    .			17556	IN	NS	h.root-servers.net.
    .			17556	IN	NS	a.root-servers.net.
    .			17556	IN	NS	k.root-servers.net.
    .			17556	IN	NS	m.root-servers.net.
    .			17556	IN	NS	g.root-servers.net.
    .			17556	IN	NS	f.root-servers.net.

To see SOA in action for Root Servers, we have a special Root Server domain name (a period (`.`) symbol) in which to run this command:

    dig  @8.8.8.8  .  NS


and it answers back, whose obfuscated output of AUTHORITY SECTION so we can show just the relevant part as:

    ;; ANSWER SECTION:
    .			17644	IN	NS	f.root-servers.net.
    .			17644	IN	NS	i.root-servers.net.
    .			17644	IN	NS	c.root-servers.net.
    .			17644	IN	NS	j.root-servers.net.
    .			17644	IN	NS	k.root-servers.net.
    .			17644	IN	NS	e.root-servers.net.
    .			17644	IN	NS	g.root-servers.net.
    .			17644	IN	NS	a.root-servers.net.
    .			17644	IN	NS	m.root-servers.net.
    .			17644	IN	NS	h.root-servers.net.
    .			17644	IN	NS	b.root-servers.net.
    .			17644	IN	NS	l.root-servers.net.
    .			17644	IN	NS	d.root-servers.net.
    
    ;; ADDITIONAL SECTION:
    a.root-servers.net.	4198	IN	A	198.41.0.4
    a.root-servers.net.	18698	IN	AAAA	2001:503:ba3e::2:30


Responses to a SOA query are always in a same-line format.



XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

You give it a record type (key) and it returns the answer (value).  

For this article, the 'example.tld.' shall be used as a domain name. 

Domain name is a generic label, may be a fully-qualified domain name (FQDN), top-level domain name (TLD), or a subdomain (engineering.example.tld).

Domain name has period(s) in it.  There is a zone file for each part of the
domain name separated by a period. 


* A zone file for '.com', 
* another zone file for 'example'.  
* probably a zone file for 'engineering' as in 'engineering.example.tld'.

There is only ONE primary zone file for each domain name (not having a period
symbol).

Three primary zone files have to exist for the given example above.

The primary zone file for '.com' is with the registars who control it.


These example zone files are not controlled by one nameserver .  Zone files are
literally spread all over the world.  But 'example' zone file must
be in a DNS server that you control.

The 13 root servers have a zone file for '.tld' (such as '.com',
'.edu').  These root servers are the primary of '.tld' zone.  We have registars
that maintain the '.tld' zone file (and its file has millions of entries).

To get 'example' started under '.tld', a registar wants several things from the owner of 'example':

* Name, address, phone, email
* your DNS server (also called nameserver for 'example' zone)
  * by its fully-qualified domain name (ns1.example.tld)
  * IP address of all your nameservers
    * primary nameserver (your IP address)
    * secondary nameserver(s) (may also be under your control or others)

Registar will only expose the following, if you requested privacy:

* name of your newly-created nameserver (ns1.example.tld)
* IP addresses of all your DNS servers (nameservers).

Registar then informs the Root Servers of both your `A` and `NS` information and
the `example.tld` is born.

Magic lookup is the host named `ns1.example.tld`; it is how the rest of the world will find 'example.tld' and all things pertaining under 'example.tld'.  

Upon registration of 'example', the registar will create a `SOA`, an `A` and a `NS` records in its root zone file:

    example.tld.  86400 IN SOA ns1.example.tld. admin.example.tld. 2020103437 1200 180 1209600 10800
    
    ;; AUTHORITY SECTION:
    example.tld.  86400 IN NS ns1.example.tld.
    example.tld.  86400 IN NS ns1.he.net.
    example.tld.  86400 IN NS ns3.he.net.
    example.tld.  86400 IN NS ns4.he.net.
    example.tld.  86400 IN NS ns2.he.net.
    example.tld.  86400 IN NS ns5.he.net.
    
    ;; ADDITIONAL SECTION:
    ns1.example.tld.  86400 IN A 104.218.48.116
    ns1.example.tld.  86400 IN AAAA 2604:a00:5:1156::116


A couple of things must be given to '.tld' registars of these root servers.
If you own the 'example.com' domain name, your registar will ask you where your 'example' zone file is located at.  This is called the nameserver for 'example.tld'.  That's your job to provide a nameserver if you want 'example' to be available under '.tld'.



add your 'example' to the root servers' '.tld' zone file.  Now, 'example' record is in root servers' zone file.

With available 'example.tld' in root zone file, you must take steps to announce
to the world that new zone records are 'query-able' for lookups about
'example.tld'.



Subsequentially, if you created 'engineering.example.com', you must create 

Basically, a zone file holds the record and its corresponding answer(s) for DNS.

Zone file (usually) have exactly one primary that is in charge of controlling the
content of this zone.

Zone file targets a specific domain group, not a specific host.  Domain group
can be:

* example.tld,
* portal.example.tld, if not bunching 'vpn', 'ssh', 'tor', 'wireguard' together
* finance.example.tld
* engineering.example.tld

