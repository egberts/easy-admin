title: What checks against RCPT TO: in Exim4 mail server?
date: 2022-03-24 05:59
status: published
tags: Exim4
category: HOWTO
summary: Your Exim4 mail server is rejecting the "RCPT TO:".  This article shows how to debug the Exim4 for this type of rejection.
slug: exim4-debug-rcpt-to
lang: en
private: False

Your Exim4 mail server is rejecting the "RCPT TO:".  This article shows how to debug the Exim4 for this type of rejection.

The various filter files used by Exim4 daemon to deny/accept the inbound 'RCPT TO:' are listed in chronological checking order:

* !ACL `acl_local_deny_exceptions`
 * `/etc/exim4/host_local_deny_exceptions`
 * `/etc/exim4/sender_local_deny_exceptions`
 * `/etc/exim4/local_host_whitelist`
 * `/etc/exim4/local_sender_whitelist`

* RECIPIENTS `/etc/exim4/local_rcpt_callout`

* !ACL `acl_local_deny_exceptions`
 * `/etc/exim4/host_local_deny_exceptions`
 * `/etc/exim4/sender_local_deny_exceptions`
 * `/etc/exim4/local_host_whitelist`
 * `/etc/exim4/local_sender_whitelist`

* SENDERS `/etc/exim4/local_sender_blacklist`

* !ACL `acl_local_deny_exceptions`
 * `/etc/exim4/host_local_deny_exceptions`
 * `/etc/exim4/sender_local_deny_exceptions`
 * `/etc/exim4/local_host_whitelist`
 * `/etc/exim4/local_sender_whitelist`

* HOSTS `/etc/exim4/local_host_blacklist`


How To Get The List Again
=========================
Sometimes the configuration files get muddled, like in changing your (email) router settings.

You can recreate your own list of `RCPT TO:` accept/deny list and compare it against this Exim4 default settings.

Stop the `exim4` daemon and run this:

```bash
#!/bin/bash
# File: exim4-daemon-debug.sh
# Title: Run exim4 in debug for troubleshooting
echo "Running exim4 daemon in debug mode ..."
echo

if [ "$USER" != 'root' ]; then
  echo "Must be in 'root' to debug exim4 daemon. Aborting ..."
  exit 255
fi

/usr/sbin/exim4 -bd -q30m -oX 587:465:25 -oP /run/exim4/exim.pid -d
echo $?

echo
echo "Done debugging exim4 daemon: exit code $retsts"
```
Capture the output into a temporary file (e.g, `output.script`).

Send a test email against the Exim4 server.  I use the awesome `swaks` tool:

```console
swaks --to test@egbert.net --from somename@yahoo.com --server egbert.net --quit-after RCPT --hide-all
```

NOTE: Oh drat, after writing this article, I found my problem: I have inadvertly included the unwanted `--quit-after RCPT`.  So, I have fixed it for me.  Might get you further.


Then scan the intensive output for the output marker:

```console
<pid> ----------- end verify ------------
```

Look for the all of the lines with the starting word `check `:

First level check:
```console
grep -E "^[0-9]{1,6} check" /tmp/output.script
<pid> check !acl = acl_local_deny_exceptions
<pid> check recipients = ${if exists{/etc/exim4/local_rcpt_callout}{/etc/exim4/local_rcpt_callout}{}}
<pid> check !acl = acl_local_deny_exceptions
<pid> check senders = ${if exists{/etc/exim4/local_sender_blacklist}{/etc/exim4/local_sender_blacklist}{}}
<pid> check !acl = acl_local_deny_exceptions
<pid> check hosts = ${if exists{/etc/exim4/local_host_blacklist}{/etc/exim4/local_host_blacklist}{}}
```

All-level checks:
```console
grep -E "^[0-9]{1,6}\s+check" /tmp/output.script
15445 check !acl = acl_local_deny_exceptions
15445  check hosts = ${if exists{/etc/exim4/host_local_deny_exceptions}{/etc/exim4/hos
t_local_deny_exceptions}{}}
15445  check senders = ${if exists{/etc/exim4/sender_local_deny_exceptions}{/etc/exim4
/sender_local_deny_exceptions}{}}
15445  check hosts = ${if exists{/etc/exim4/local_host_whitelist}{/etc/exim4/local_hos
t_whitelist}{}}
15445  check senders = ${if exists{/etc/exim4/local_sender_whitelist}{/etc/exim4/local
_sender_whitelist}{}}
15445 check recipients = ${if exists{/etc/exim4/local_rcpt_callout}{/etc/exim4/local_r
cpt_callout}{}}
15445 check !acl = acl_local_deny_exceptions
15445  check hosts = ${if exists{/etc/exim4/host_local_deny_exceptions}{/etc/exim4/hos
t_local_deny_exceptions}{}}
15445  check senders = ${if exists{/etc/exim4/sender_local_deny_exceptions}{/etc/exim4
/sender_local_deny_exceptions}{}}
15445  check hosts = ${if exists{/etc/exim4/local_host_whitelist}{/etc/exim4/local_hos
t_whitelist}{}}
15445  check senders = ${if exists{/etc/exim4/local_sender_whitelist}{/etc/exim4/local
_sender_whitelist}{}}
15445 check senders = ${if exists{/etc/exim4/local_sender_blacklist}{/etc/exim4/local_
sender_blacklist}{}}
15445 check !acl = acl_local_deny_exceptions
15445  check hosts = ${if exists{/etc/exim4/host_local_deny_exceptions}{/etc/exim4/hos
t_local_deny_exceptions}{}}
15445  check senders = ${if exists{/etc/exim4/sender_local_deny_exceptions}{/etc/exim4
/sender_local_deny_exceptions}{}}
15445  check hosts = ${if exists{/etc/exim4/local_host_whitelist}{/etc/exim4/local_hos
t_whitelist}{}}
15445  check senders = ${if exists{/etc/exim4/local_sender_whitelist}{/etc/exim4/local
_sender_whitelist}{}}
15445 check hosts = ${if exists{/etc/exim4/local_host_blacklist}{/etc/exim4/local_host
_blacklist}{}}

```
