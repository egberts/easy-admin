How to configure a bastion OpenSSH server so that
a simple command of:

   ssh -J finaluser@finalhost bastionuser@bastionhost

is the ONLY thing that is supported.

* Shell is compiled in without "build-in" compile options
* No coreutils
* No sudo
* Root account disabled
* Read-only Root Filesystem
* No user home directories

Also configures OpenSSH for:

   AllowAgentForwarding no
   AllowTcpForwarding yes
   X11Forwarding no
   PermitTunnel no
   PermitTTY no
   GatewayPorts no
   # do not allow log-in from interior
   PermitOpen BastionHostname:22
   ForceCommand echo 'Nope'
   # Disables session multiplexing
   # MaxSessions=1 means:
   #  - All logins get logged  (>1 would miss-out on some audit)
   MaxSessions 1

