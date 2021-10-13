#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#

sudo apt install openssh-server

echo "We are blowing away the old SSH settings"

# Only the first copy is saved as the backup
if [ ! -f /etc/ssh/sshd_config.backup ]; then
  sudo mv /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi
if [ ! -f /etc/ssh/ssh_config.backup ]; then
  sudo mv /etc/ssh/ssh_config /etc/ssh/ssh_config.backup
fi

# Update the SSH server settings
#


SSH_MODULI_BITS=4096
ssh-keygen -M generate \
    -O bits=${SSH_MODULI_BITS} \
    /tmp/moduli-${SSH_MODULI_BITS}.candidates

ssh-keygen -M screen \
        -f /tmp/moduli-${SSH_MODULI_BITS}.candidates \
        /tmp/moduli.safe

# awk '$5 > 3071' \
    # /tmp/moduli-${SSH_MODULI_BITS}.candidates \
    # | tee /tmp/moduli-${SSH_MODULI_BITS}
sudo cp /tmp/moduli.safe /etc/ssh/moduli

sudo chmod 640 /etc/ssh/moduli
sudo chown root:ssh /etc/ssh/moduli

rm /tmp/moduli-${SSH_MODULI_BITS}.candidates
rm /tmp/moduli-${SSH_MODULI_BITS}
rm /tmp/moduli.safe
#
