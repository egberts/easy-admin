
How to Configure Port SSH Namespace for IPTABLES?

Identify user name in which to limit the 
port to: 'sshd' (or 'ssh' for Debian).

Create a group name (eg. 'devops'):
    groupadd -r  devops

Add this new group name to each authorized 
inbound SSH client user: add 'devops'
supplemental group to each allowed SSH user:

    useradd -a -G devops johnd

Then limit all SSH network traffic connections 
to 'devops' group.

    iptables -I OUTPUT \
        -m sshd \
        --gid-owner devops \
        -p tcp \
        --dport 22 \
        -d 192.168.0.0/16 \
        -j ACCEPT


Alternatively, using nftables, to limit all SSH network traffic connections 
to 'devops' group:

```
#!/usr/bin/nft -f

# Assumes a Default-Deny firewall
#
create table inet PUBLIC_SIDE;

table inet PUBLIC_SIDE chain MyInputChain;

add rule inet PUBLIC_SIDE MyInputChain \
    prerouting meta oif eth0 port 2224 --skgid devops -skuid root;
    filter meta oif eth0 port 2224 --gid devops -uid root;
```
