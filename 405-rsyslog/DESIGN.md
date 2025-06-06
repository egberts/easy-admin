Configuration
=============

Disable systemd
---------------
Keeping ForwardToSyslog=no in /etc/systemd/journald.conf


Inputs
======

1. Local
  a. logger/syslog()
    1) executable process
    2) CLI tools
    3) CRON jobs
  b. UNIX socket
    1) RabbitMQ
    1) ZeroMQ

2. Remotely
  a. IP socket
    1) TCP
    2) UDP

3. Default
  a.  Debian Version 7
  a.  Debian Version 8
    


File Output
======

1. Local
  a. UNIX socket


References
==========

    /usr/lib/x86_64-linux-gnu/rsyslog   Modules used by rsyslog (`rsyslogd`) daemon
