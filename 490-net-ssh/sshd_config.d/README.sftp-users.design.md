
Match Group sftponly

  # %h is a variable for $USER home
  ChrootDirectory %h

  # Use internal-sftp as a SSH SHELL session
  # Changes directory after login
  ForceCommand internal-sftp -d uploads

  AllowTcpForwarding no
  X11Forwarding no

  # PasswordAuthentication must be 'no' for sftp subsystem.
  # Otherwise, malicious actor can run SaSSHimi to reverse
  # tunnel back in.
  PasswordAuthentication no

Match User sftpusers
  PubkeyAuthentication  yes
  PasswordAuthentication no
  AuthenticationMethods publickey



