RNDC Security Mechanisms


Granularity of RNDC utility security in accessing the ISC Bind9 
named daemon control are:

1.  full-admin, by IP address via 'controls { inet ...'
2.  read-only, by IP address, via 'read-only' option in 'controls { inet ...'

And further access control by IP address.

Read-only is good for QA folks, Common Criteria 
enforcer, and selected end-users.

Security: Also, it is getting increasingly important that "world" file permission of `rndc` binary must be dropped and lowered to at most `0750`.  Some distro will revert this file permission during upgrades.
