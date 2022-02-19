Environment variables used in OpenSSH (8.8p1)
as references by static getenv(3) function.

SSH client (shell session)

<jtable>
`AUTHSTATE`, IBM AIX only; used in place of `/etc/environment`, filespec, session.c
`DISPLAY`, the default host, display number, and screen of the current desktop session, string, channels.c, mux.c, readpass.c, readpass.c, ssh.c
`KRB5CCNAME`, the absolute path of the Kerberos5 user credential cache., filepath, session.c, sshd.c
`HOME`, the path of the user home directory as specified by the password database, filepath, sshconnect.c
`LANG`, the locale of the OS system, locale category, misc.c
`PATH`, a set of directories where executable programs are located, list of filepaths, session.c
`SHELL`, The file path to the user's shell executable image, as specified by the password database., filepath, readconf.c, sftp.c, ssh-agent.c, sshconnect.c
`SSH_ASKPASS`, set by user; a filepath to the Ask Password executable program/script, filepath, readpass.c
`SSH_ASKPASS_ENV` - readpass.c
`SSH_ASKPASS_REQUIRE_ENV` - readpass.c
`SSH_PKCS11_HELPER` - ssh-pkcs11-client.c
`SSH_SK_HELPER` - ssh-sk-client.c
`SSH_SOCKS_SERVER`, SOCKS firewall connection info; set by the SSH user before ssh(1) is called, string,
`TERM` - mux.c, ssh.c
`TMPDIR` - misc.c
`TZ` - auth-pam.c, session.c
</jtable>

SSH server (daemon)
<jtable>
Env varname, description, type, source
`KRB5CCNAME`, the absolute path of the Kerberos5 user credential cache., filepath, session.c, sshd.c
`SSH_CONNECTION` - sftp-server.c
`SHELL`, The file path to the user's shell executable image, as specified by the password database., filepath, readconf.c, sftp.c, ssh-agent.c, sshconnect.c
</jtable>

SSH agent (daemon)
<jtable>
Env varname, description, type, source
`SHELL`, The file path to the user's shell executable image, as specified by the password database., filepath, readconf.c, sftp.c, ssh-agent.c, sshconnect.c
`SSH_AGENTPID_ENV_NAME` - ssh-agent.c
`SSH_AUTHSOCKET_ENV_NAME`  - authfd.c
`SSH_AUTH_SOCK`, authentication socket of SSH agent; passed to SSH user, UNIX socket path,
</jtable>

SSH keygen (CLI)
<jtable>
Env varname, description, type, source
`SSH_SK_PROVIDER` - ssh-add.c, ssh-keygen.c
</jtable>

Add SSH ssh-add(1) (CLI)
<jtable>
Env varname, description, type, source
`SSH_SK_PROVIDER` - ssh-add.c, ssh-keygen.c
</jtable>

Created and propagated by SSH session forwarder
<jtable>
Env varname, description, type, source
`DISPLAY`, the default host, display number, and screen of the current desktop session, string, channels.c, mux.c, readpass.c, readpass.c, ssh.c
`HOME`, the path of the user home directory as specified by the password database, filepath, sshconnect.c
`LOGIN`, UNIX user name; used only on IBM AIX, string, session.c
`LOGNAME`, UNIX user name, string, session.c
`KRB5CCNAME`, MIT Kerberos 5 session name; only used in KRB5 environment, string, session.c
`MAIL`, Local inbox for UNIX Maildir system, filepath or directory path, session.c
`PATH`, a set of directories where executable programs are located, list of filepaths, session.c
`SSH_CLIENT`, (deprecated) SSH client connection socket info; set by the sshd(8) daemon, string, session.c
`SSH_CONNECTION`,  SSH client and server socket connection info; set by the sshd(8) daemon, string, session.c
`SSH_ORIGINAL_COMMAND`, the original command used by client to enter into this SSH session; set by the sshd(8) daemon, string, session.c
`SSH_TUNNEL`,  SSH tunnel connection, string, session.c
`SSH_TTY`, Name of the TTY device allocated by sshd(8) daemon for client to use, string, session.c
`SSH_USER_AUTH`, SSH authentication selected, string, session.c
`SUPATH`, a set of directories where executable programs are located from a superuser shell, list of filepaths, session.c
`TERM`, UNIX terminal device name, string, session.c
`TZ`, UNIX timezone, string, session.c
`UMASK`, UNIX file permission mask, 4-digit octal, session.c
`USER`, UNIX user name, string, session.c
</jtable>
