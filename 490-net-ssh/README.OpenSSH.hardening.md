You are locking down SSH and its sshd daemon?  

Hardened OpenSSH
================
For OpenSSH authorization and authentication, there are multiple ways 
to set up further Bell-LaPalda Modeling (separation of permissions) 
toward ssh and sshd.

Authorization Types 
-------------------
Authorization is a simply permission method of
under what condition should arise before a new SSH session get started
before we get to the user-specific part of the SSH protocol.

* Outbound SSH authorization
* Inbound SSH authorization


Authentication Types
--------------------
As opposed to authorization, we have the 
authentication.

Authentication types are: 

1. Password-based
2. One-Time Pad
3. Certificate


Outbound SSH Session - Authorization
====================
The first line of OpenSSH defense is outbound of SSH connection.
It may not be the weakest link but it is surely the easiest to prevent
a hacker's movement and the hardest to trackdown to.

Most default installations left these features wide-open.  And most of you will
continue to do so.

Several file permission methods for restricting SSH usages within the
outbound SSH session are:

1. Binary restriction (against outbound ssh client)
2. Public Key restriction (against outbound ssh client)


For file-permission restriction against binary file, we can run:

    chmod 0700 /usr/bin/ssh
    chgrp root /usr/bin/ssh

And naively let only root use 'ssh client', which is rare; 
End-user may have no business using this host as a SSH jump-point.


Or we can run:

    chmod 0750 /usr/bin/ssh
    chgrp ssh /usr/bin/ssh

And basically let only users who have 'ssh' supplementary group use 'ssh
client'.  One can add user(s) to the 'ssh' group as needed.

    usermod -a -G ssh <username>

Useful for multi-user environment.

In summary, outbound SSH authorization comprises of:
1.  No group name for SSH, all root-owned
2.  Single 'ssh' group
3.  Both 'ssh' and 'sshkey' groups


Inbound SSH Session - Authorization
===================

Different methods of authorizing inbound SSH session are:

* `AllowGroups`/`AllowUsers`
* `sshkey` UNIX group name by accessibility to `/etc/ssh/ssh\_host_*_keys` file
* `ssh` UNIX group name by accessibility to `/etc/ssh/ssh_config` file

AllowGroup/AllowUsers
---------------------
For inbound SSH session, `sshd_config` has a `AllowGroups` and `AllowUsers`
options.  They're nice to have but impractical.

Good for a small-time admin; large user pool, not so much.  Downside of this
SSH-specific setting is that there is no ease of data-entry for new users.  One
would have to go delve into the `sshd_config`, wade through the many options, and
carefully insert in a new user name. Then run a syntax checker:

   ssh -T -t -f /etc/ssh/sshd\_config
   echo $?

to make sure that its configuration file did not break: shell exit code for 
success is zero(0).

PubkeyAuthentication Only
-------------------------
Did you know that inbound part of public-key-only SSH sessions can be restricted 
as well but by GID/file permission?   Uses the same set 
of `useradd`/`usermod`/`userdel` tools that many sysadmins have come to enjoy.

If your SSH server declines the `PasswordAuthentication` option and uses
`PubkeyAuthentication` instead, then this file-permission approach against 
public key usages is for you; we can run:

    chmod 0640 /etc/ssh/ssh_host_*_keys.pub   # note '.pub' file suffix?
    chgrp sshkey /etc/ssh/ssh_host_*_keys.pub

This prevents SSH session from using any SSH publickey, unless that user 
is also in the supplemental 'sshkey' group as well.

TIP: It is the norm to create another SSH Unix group name/ID like 'sshkey' 
to help restrict reading these public key files.  We keep the existing
'ssh' group for:

* inbound SSH session (by PAM/shadow) and 
* outbound (by binary exec perm) SSH client access.



Authentication
===================
Inbound SSH session are supposed to be the most heavily fortified leg of 
the SSH protocol; but sadly no.

Evolutionarily, OpenSSH configures out the weakness of SSH protocol.  Most
options are now gone such as:

*  GSSAPICleanupCredentials
*  KeepAlive
*  KerberosGetAFSToken
*  KerberosOrLocalPasswd
*  KerberosTicketCleanup
*  KeyRegenerationInterval
* `Protocols 1,2`
*  RSAAuthentication
*  RhostsRSAAuthentication
*  ServerKeyBits
* `UseLogin`
*  UsePrivilegeSeparation

Often times, other daemons such as log alerter, filesystem change detector, and
other defense tools for SSH watches the network port for any SSH abuse.


Password-based Authentication
============================
While discouraged, password-based authentication is best done at the level of PAM 
(Pluggable Authentication Model) for Linux.


One-Time Pad (OTP and variants) Authorization
================================================

1. Password-based
2. One-Time Pad
3. Certificate

Certificate Authorization
============================

Read up on [If you're not using SSH certificates you're doing SSH wrong](https://smallstep.com/blog/use-ssh-certificates/).

In short, to generate a SSH-specific X.509 certificate, run:

    sshh-keygen -L -f id_ed25519-cert.pub  # to view the certificate

Add to `/etc/ssh/sshd_config` config file:

    # Path to the CA public key for verifying user certificates
    TrustedUserCAKeys /etc/ssh/ssh_user_key.pub

    # Path to this host's private key and certificates
    HostKey /etc/ssh/ssh_host_ed25519_key
    HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub

On each remote client (wanting to get access to this server), add a line to
`~/.ssh/known_hosts`.

    @cert-authority *.example.com ed25519-sha512 AAAAEE ...


References
==========

* https://github.com/smallstep/certificates (cli-ca)
* https://github.com/smallstep/cli