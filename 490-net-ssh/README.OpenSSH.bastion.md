How to Set Up a Bastion SSH Host
================================
A bastion SSH host allows user to login onto the
host and then can do one of the following:

* perform some local work within that bastion host OR
* perform an outbound SSH session using ssh(1) to elsewhere.

This is a marked difference from a SSH Jump host
where a user can login onto the host and then
forward on to another (but internal) SSH server:

- a bastion host makes use of two separate SSH processes (as a security feature)
- whereas a SSH Jump host leverages a single SSH process to receive then forward a SSH connection without making a use of any local TTY device.  

Of course, all 
that does not include the main SSH daemon whose 
job is to do an extra process-forking of a new 
SSH user session with each inbound SSH connection.

A bastion SSH host is a server that only allows
SSH connection with following `sshd_config` settings:

- `PermitOpen <allowed_public_IP>:2222`
- `PermitTunnel no`
- `AllowTcpForwarding yes`
- `X11Forwarding no`
- `AllowAgentForwarding no`
- `PermitTTY no`
- `ForceCommand echo 'Nope'`
- `GatewayPorts none`

And that server should open no other network ports.

For SMB (small and medium businesses), SSH clients can be forced to use their read-only keys OUTSIDE of their \$HOME directory:

- AuthorizedKeysFile /etc/ssh/keys/%u

This eases the system administrator's duty to the quickest lockout by a simple removal of the targeted user's key file.

With the above setup then allows for an easy log-through from outside world to one of your internal host with the following command:

  ssh -J finaluser@finalhost bastionuser@bastion.domain.tld

Also it is prudent that this dedicated bastion host's OS should also 
have the following attributes:

- Shell(s) re-compiled without any built-ins
- No `sudo` binary
- Root account disabled
- Read-only Root filesystem
- No user home directory
- No coreutils 
- Separate disk partition for /var/log (Common Criteria)
- OSSEC/Tripwire/audit/SELinux
- Email outlet for alerts
- Templates are destroyed and rebuilt every 8 hours
- Disable `ptrace()` in OS
- Compile and link `sshd` binary file as a static executable (no `*.so` nor `dlopen()` capability)

Enjoy.

# References

* [Introduction to Injection into sshd for Fun](https://papers.vx-underground.org/papers/VXUG/Mirrors/Injection/linux/blog.xpnsec.com-Linux%20ptrace%20introduction%20AKA%20injecting%20into%20sshd%20for%20fun.pdf)

