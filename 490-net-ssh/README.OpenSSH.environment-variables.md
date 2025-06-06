Environment variables used in OpenSSH (8.8p1)
as references by static getenv(3) function.

SSH client (shell session)

<jtable>
`AUTHSTATE`, IBM AIX only; used in place of `/etc/environment`, filepath, session.c
`DISPLAY`, the default host/ display number/ and screen of the current desktop session; The DISPLAY variable indicates the location of the X11 server.  It is automatically set by ssh to point to a value of the form “hostname:n” where “hostname” indicates the host where the shell runs and ‘n’ is an integer ≥ 1.  ssh uses this special value to forward X11 connections over the secure channel.  The user should normally not set DISPLAY explicitly as that will render the X11 connection insecure (and will require the user to manually copy any required authorization cookies)., <host>:<display-id>.<screen-id>, channels.c mux.c readpass.c readpass.c ssh.c
`WAYLAND_DISPLAY`, the default host/ display number/ and screen of the current desktop session; The DISPLAY variable indicates the location of the Wayland X server.  It is automatically set by ssh to point to a value of the form “hostname:n” where “hostname” indicates the host where the shell runs and ‘n’ is an integer ≥ 1.  ssh uses this special value to forward X11 connections over the secure channel.  The user should normally not set DISPLAY explicitly as that will render the X11 connection insecure (and will require the user to manually copy any required authorization cookies)., <host>:<display-id>.<screen-id>, channels.c mux.c readpass.c readpass.c ssh.c
`KRB5CCNAME`, the absolute path of the Kerberos5 user credential cache., filespec, session.c, sshd.c
`HOME`, the path of the user home directory as specified by the password database, filepath, sshconnect.c
`LANG`, the locale of the OS system, locale category, misc.c
`PATH`, a set of directories where executable programs are located, list of colon-separated filepath(s), session.c
`SHELL`, The file path to the user's shell executable image as specified by the password database., full-filespec, readconf.c sftp.c ssh-agent.c sshconnect.c
`SSH_ASKPASS`, If ssh needs a passphrase then it will read the passphrase from the current terminal if it was run from a terminal.  If ssh does not have a terminal associated with it but `DISPLAY` and `SSH_ASKPASS` are set then it will execute the program specified by `SSH_ASKPASS` and open an X11 window to read the passphrase.  This is particularly useful when calling ssh from a .xsession or related script.  (Note that on some machines it may be necessary to redirect the input from /dev/null to make this work.) set by user; a filepath to the Ask Password executable program/script, filepath, readpass.c
`SSH_ASKPASS_ENV` - readpass.c
`SSH_ASKPASS_REQUIRE`, Allows further control over the use of an askpass program.  If this variable is set to “never” then ssh will never attempt to use one.  If it is set to "prefer" then ssh will prefer to use the askpass program instead of the TTY when requesting passwords.  Finally if the variable is set to "force" then the askpass program will be used for all passphrase input regardless of whether `DISPLAY` is set., 'never' or 'prefer', readpass.c
`SSH_ASKPASS_REQUIRE_ENV`,  readpass.c
`SSH_AUTH_SOCK`, Identifies the path of a UNIX-domain socket used to communicate with the agent. Passed to SSH user, UNIX socket filepath, authfd.c
`SSH_PKCS11_HELPER`,  ssh-pkcs11-client.c
`SSH_SK_HELPER`,  ssh-sk-client.c
`SSH_SOCKS_SERVER`, SOCKS firewall connection info; set by the SSH user before ssh(1) is called, string,
`TERM`, terminal name,  mux.c ssh.c
`TMPDIR`, dirspec,  misc.c
`TZ`, timezone, auth-pam.c session.c
</jtable>

SSH server (daemon)
<jtable>
Env varname, description, type, source
`KRB5CCNAME`, the absolute path of the Kerberos5 user credential cache., filepath, session.c, sshd.c
`SSH_AUTH_SOCK`, Identifies the path of a UNIX-domain socket used to communicate with the agent. Passed to SSH user, UNIX socket path,
`SSH_CONNECTION`, Identifies the client and server ends of the connection.  The variable contains four space-separated values: client IP address and client port number and server IP address and server port number. SSH client and server socket connection info; set by the sshd(8) daemon, string, sftp-server.c
`SHELL`, The file path to the user's shell executable image as specified by the password database., filepath, readconf.c sftp.c ssh-agent.c sshconnect.c
</jtable>

SSH agent (daemon)
<jtable>
Env varname, description, type, source
`SHELL`, The file path to the user's shell executable image as specified by the password database., filepath, readconf.c sftp.c ssh-agent.c sshconnect.c
`SSH_AGENTPID_ENV_NAME` - ssh-agent.c
`SSH_AUTHSOCKET_ENV_NAME`  - authfd.c
`SSH_AUTH_SOCK`, Identifies the path of a UNIX-domain socket used to communicate with the agent. Passed to SSH user, UNIX socket path,
</jtable>

SSH keygen (CLI)
<jtable>
Env varname, description, type, source
`SSH_SK_PROVIDER` - ssh-add.c ssh-keygen.c
</jtable>

Add SSH ssh-add(1) (CLI)
<jtable>
Env varname, description, type, source
`SSH_SK_PROVIDER` - ssh-add.c ssh-keygen.c
</jtable>

Created and propagated by SSH session forwarder
<jtable>
Env varname, description, type, source
`DISPLAY`, the default host/ display number/ and screen of the current desktop session, string, channels.c mux.c readpass.c readpass.c ssh.c
`HOME`, the path of the user home directory as specified by the password database, filepath, sshconnect.c
`LOGIN`, UNIX user name; used only on IBM AIX, string, session.c
`LOGNAME`, Synonym for USER; set for compatibility with systems that use this variable., string, session.c
`KRB5CCNAME`, MIT Kerberos 5 session name; only used in KRB5 environment, string, session.c
`MAIL`, Set to the filepath of a user local inbox for UNIX Maildir system, filepath or directory path, session.c
`PATH`, a set of directories where executable programs are located, list of filepaths, session.c
`SSH_CLIENT`, (deprecated) SSH client connection socket info; set by the sshd(8) daemon, string, session.c
`SSH_CONNECTION`, Identifies the client and server ends of the connection.  The variable contains four space-separated values: client IP address and client port number and server IP address and server port number. SSH client and server socket connection info; set by the sshd(8) daemon, string, session.c 
`SSH_ORIGINAL_COMMAND`, This variable contains the original command line if a forced command is executed.  It can be used to extract the original arguments.; set by the sshd(8) daemon, string, session.c
`SSH_TTY`, This is set to the name of the tty (path to the device) associated with the current shell or command.  If the current session has no tty, this variable is not set.  Set by the sshd(8)., string, session.c
`SSH_TUNNEL`,  Optionally set by sshd(8) to contain the interface names assigned if tunnel forwarding was requested by the client., string, session.c
`SSH_USER_AUTH`, Optionally set by sshd(8) this variable may contain a pathname to a file that lists the authentication methods successfully used when the session was es‐ tablished including any public keys that were used., string, session.c
`SUPATH`, a set of directories where executable programs are located from a superuser shell, list of filepaths, session.c
`TERM`, UNIX terminal device name, string, session.c
`TZ`, UNIX timezone, string, session.c
`UMASK`, UNIX file permission mask, 4-digit octal, session.c
`USER`, Set to the name of the user logging in., string, session.c
</jtable>


Test environment variables:
<jtable>
`TEST_SSH_ELAPSED_TIMES`, enable printing of the elapsed time in seconds of each test.
</jtable>
