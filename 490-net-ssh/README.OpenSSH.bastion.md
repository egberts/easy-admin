How to Set Up a Bastion SSH Host
================================
A bastion SSH host allows user to login onto the
host and then can do one of the following:

* perform some local work within that bastion host OR
* perform an outbound SSH session using ssh(1) to elsewhere.

This is a marked difference from a SSH Jump host
where a user can login onto the host and then
forward on to another (but internal) SSH server:
a bastion host makes use of two separate SSH
processes (as a security feature) whereas a SSH 
Jump host leverages a single SSH process to receive 
then forward a SSH connection without making a 
use of any local TTY device:  Of course, all 
that does not include the main SSH daemon whose 
job is to do an extra process-forking of a new 
SSH user session with each inbound SSH connection.

A bastion SSH host is a server that only allows
SSH connection with following `sshd_config` settings:
- AllowTcpForwarding yes
- PermitOpen <allowed_client_IP>:2222
- ForceCommand echo 'Nope'
- PermitTunnel no
- PTY none
- Shell none
- Forwarding no
- X11Forwarding no
- No GatewayPorts
- AllowAgentForwarding no

And SSH clients be forced to use:

- AuthorizedKeysFile /etc/ssh/keys/%u

Above setup supports following command:

  ssh -J finaluser@finalhost@bastion.domain.tld

Also its OS should also the following attributes:

- Shell(s) compiled without any built-ins
- No SUDO 
- Root account disabled
- Read-only Root filesystem
- No user home directory
- No coreutils 
- OSSEC/Tripwire/audit/SELinux
- Email outlet for alerts
- Templates are destroyed and rebuilt every 8 hours

