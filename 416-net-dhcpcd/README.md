dhcpcd, a replacement to ISC dhclient

TL;DR: Only dhcpcd and udhcpc are viable replacement to ISC's EOL'd dhclient

Requirements
============

There are following requirements for the replacement DHCP client:

1. The DHCP client must support DHCPv6.
2. The DHCP client in the initramfs should be small enough to not increase the size noticeable.
3. The DHCP client needs to be callable from the shell (for initramfs and cloud-init)

Analysis
========

The Ubuntu desktop uses network-manager and the server/cloud images uses systemd-networkd. So there is no need for changing the DHCP client on booted systems, but the initramfs uses dhclient from isc-dhcp-client.

ipconfig (from klibc-utils) does not support DHCPv6 (but there is work in progress in https://git.kernel.org/pub/scm/linux/kernel/git/bwh/klibc.git/?h=ipv6). systemd-networkd, network-manager, and dhcpcanon pull in too many packages/libraries for the initramfs use case (unless using a systemd-based boot). For example, /lib/systemd/systemd-networkd is 1.6 MB big and directly depends on 24 libraries.

systemd-networkd is designed to run as a service. It takes no arguments when called. So it must run as daemon.

Conclusion
==========

Therefore only dhcpcd and udhcpc remain as replacement (for the initramfs). From those two, I propose to use dhcpcd as replacement, because:

* It has many features (like classless static routes or DHCP over InfiniBand)
* It is actively developed (normally a few release per year)


References
==========

* https://bugs.launchpad.net/ubuntu/+source/initramfs-tools/+bug/2024164
