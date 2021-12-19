
Dynamic IP Address
------------------
Methods of DHCP client sending new IP address to a DNS server varied, greatly.

DHCP client is used to obtain a local dynamic IP address.  

For ISC bind/dhcpd, the local DHCP client must start before any kind of remote DNS server runs.  DNS server must also be reloaded/restarted after DHCP client later changes its IP address.

To hand a new IP address to the DNS server, most DHCP clients have hooks (helper-script) support.  Helper-script is often written in bash (via hash shebang line).

In this scenario, the DHCP client helper-script just updates the DNS configuration file and instructs the active DNS server to reload its config file(s).

WARNING: systemd DHCP does not have a "dispatching" hook support, as its made for desktops using DBus, and not made for servers.  Find another DHCP client. ISC DHCP (`dhclient`) client is a good choice.  NetworkManager is second best.

