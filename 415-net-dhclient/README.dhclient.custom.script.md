ISC dhclient(1) can accept custom DHCP codes
and custom scripting in response to the custom DHCP server codes.

Methods
====

Code 43, the original mess
Code 124 - VIVO
Code 125 - VIVO

Code 43
-------
That Code 43, a custom DHCP server code, did not have a unique manufacturing ID
so everybody dove into this and there was chaotic overlapping: now useless.

VIVO Approach
=============
IETF RFC 3925 defined a new DHCP server code.  It was made more distinctive
by shifting the burden of packet layout toward each enterprise.

An vendor would register with IANA for their own unique enterprise ID
then proceed to defining custom DHCP server content of their own design.

Code 124 - VIVO
---------------
Sent by a DHCP client to elicit response(s) of vendor-specific information
from its DHCP server.

Code 125 - VIVO
---------------
Received by a DHCP client containing vendor-specific information 
in response to its vendor-specific request with its DHCP server.


Reference:

* https://codingrelic.geekhold.com/2012/02/isc-dhcp-vivo-config.html
