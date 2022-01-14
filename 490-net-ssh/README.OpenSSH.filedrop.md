
How to Set Up a File-Drop SSH Host
================================

A file-drop SSH host is a server that only allows
SSH connection with following `sshd_config` settings:

Match sftpusers
    Banner /etc/ssh/banner_sftp.txt
    PubkeyAuthentication yes
    PasswordAuthentication no
    PermitEmptyPasswords no
    AllowTcpForwarding no
    ChrootDirectory /data/sftphome/%u
    ForceCommand internal-sftp -l DEBUG1 -f AUTHPRIV -P symlink,hardlink,fsync,rmdir,remove,rename
    PermitOpen <allowed_client_IP>:2222

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

