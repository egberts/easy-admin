Design of an SSH/SSHD security checker


# Gather data
#   About the desire target area
#     BUILDROOT
#     CHROOT_DIR
#     openssh package

#   About the current setup
#     what rootfs is out there???  (might be under 'build/')
#     what syntax checkers are available (binaries)
#     what current group/SELinux-context names are being used
#     split-file or standalone config
#     
# Disseminate data
#
# Report
#   warning of SUID on SSHD binaries
#   warning of SUID on SSHD binaries
#   warning of footgun (no root login)
# 

Report

Version: 2.0.1p1
Binaries: /usr/sbin/sshd
          /usr/bin/ssh

File Permissions Policy
  SSHD daemon - `sshd`
  Inbound SSH - `ssh-user`
  Outbound SSH - `ssh`

Inbound Policy  
  Deny Users  :  -
  Allow Users :  -
  Deny Groups :  -
  Allow Groups: ssh-user

Error  chmod  chown:chgrp  Binaries       chcon  
WARN    0755   root:nogroup  /usr/bin/ssh
WARN 'nogroup' group name should not be a generic
INFO group name should be 'sshd' or equivalent
WARN    0755   root:ssh      /usr/bin/ssh
WARN '0755' should not have other execute/read bits enabled
 ok     0750   root:sshd     /usr/sbin/sshd
 ok     0640   root:sshd     /etc/default/ssh

 ok     0755   root:root     /etc/ssh
 ok     0640   root:ssh      /etc/ssh/ssh_config
 ok     0750   root:ssh      /etc/ssh/ssh_config.d
 ok     0640   root:ssh      `/etc/ssh/ssh_config.d/*`

 ok     0640   root:sshd     /etc/ssh/sshd_config
 ok     0750   root:sshd     /etc/ssh/sshd_config.d
 ok     0640   root:sshd     `/etc/ssh/sshd_config.d/*`

 ok     0600   root:root     /etc/ssh/ssh_host_XXXX_key
 ok     0600   root:root     /etc/ssh/ssh_host_XXXX_key
 ok     0600   root:root     /etc/ssh/ssh_host_XXXX_key
WARN    0640   root:sshd     /etc/ssh/ssh_host_XXXX_key
WARN '0640' should not have group-read
WARN 'sshd' group name must be 'root'
