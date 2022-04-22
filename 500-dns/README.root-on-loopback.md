
BIND acts both as a recursive resolver and an authoritative server.  Because of this, there is "fate-sharing" between the two servers in the following configuration.  That is, if the root server dies, it is likely that all of BIND is dead.

Using this configuration, queries for information in the root zone are returned with the AA bit not set.

When slaving a zone, BIND will treat zone data differently if the zone is slaved into a separate view (or a separate instance of the software) versus slaved into the same view or instance that is also performing the recursion.

Validation:  When using separate views or separate instances, the DS records in the slaved zone will be validated as the zone data is accessed by the recursive server.  When using the same view, this validation does not occur for the slaved zone.

Caching:  When using separate views or instances, the recursive server will cache all of the queries for the slaved zone, just as it would using the traditional "root hints" method.  Thus, as the zone in the other view or instance is refreshed or updated, changed information will not appear in the recursive server until the TTL of the old record times out.  Currently, the TTL for DS and delegation NS records is two days.  When using the same view, all zone data in the recursive server will be updated as soon as it receives its copy of the zone.





```nginx
   view root {
       match-destinations { 127.12.12.12; };
       zone "." {
           type slave;
           file "rootzone.db";
           notify no;
           masters {
               192.228.79.201; # b.root-servers.net
               192.33.4.12;    # c.root-servers.net
               192.5.5.241;    # f.root-servers.net
               192.112.36.4;   # g.root-servers.net
               193.0.14.129;   # k.root-servers.net
               192.0.47.132;   # xfr.cjr.dns.icann.org
               192.0.32.132;   # xfr.lax.dns.icann.org
               2001:500:84::b; # b.root-servers.net
               2001:500:2f::f; # f.root-servers.net
               2001:7fd::1;    # k.root-servers.net
               2620:0:2830:202::132;  # xfr.cjr.dns.icann.org
               2620:0:2d0:202::132;  # xfr.lax.dns.icann.org
           };
       };
   };

   view recursive {
       dnssec-validation auto;
       allow-recursion { any; };
       recursion yes;
       zone "." {
           type static-stub;
           server-addresses { 127.12.12.12; };
       };
   };
```

Reference:

* https://datatracker.ietf.org/doc/html/rfc7706
