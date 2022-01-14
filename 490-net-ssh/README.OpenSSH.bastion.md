How to Set Up a Bastion SSH Host
================================

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

Above supports following command:

  ssh -J finaluser@finalhost@bastion.domain.tld

Also its OS must have the following attributes:

- Shell(s) compiled without any built-ins
- No SUDO 
- Root account disabled
- Read-only Root filesystem
- No user home directory
- No coreutils 
- OSSEC/Tripwire/audit/SELinux
- Email outlet for alerts
- Templates are destroyed and rebuilt every 8 hours

