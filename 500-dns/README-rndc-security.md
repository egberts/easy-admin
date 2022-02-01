RNDC Security Mechanisms


Granularity of RNDC utility security in accessing the ISC Bind9 
named daemon control are:

1.  full-admin, by IP address via 'controls { inet ...'
2.  read-only, by IP address, via 'read-only' option in 'controls { inet ...'

And further access control by IP address.

Read-only is good for QA folks, Common Criteria 
enforcer, and selected end-users.
