RNDC Security Mechanisms


Granularity of RNDC utility security in accessing the ISC Bind9 
named daemon control are:

1.  full-admin, by IP address via 'controls { inet ...'
1.  full-admin, by UNIX socket via 'controls { unix ...'
2.  read-only, by IP address, via 'read-only' option in 'controls { inet ...'
2.  read-only, by UNIX socket, via 'read-only' option in 'controls { unix ...'
3.  read-only, by world file permission
4.  read-only, by 'bind'/'named' group file permission

Read-only is good for QA folks, Common Criteria 
enforcer, and selected end-users.
