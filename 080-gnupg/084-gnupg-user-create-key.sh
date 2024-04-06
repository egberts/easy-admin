#!/bin/bash
# File: 084-gnupg-user-create-key.sh
# Title: GNU Pretty Good Privacy setup for end-user
# Description:
#   GNU Pretty Good Privacy setup for maintainers of packages.
#   Sets up the user-wide global settings for GNU Pretty Good Privacy
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - none
#  create - ~/.gnupg
#           ~/.gnupg/gpg.conf
#           ~/.gnupg/gpg-agent.conf
#           ~/.bashrc.d/plugins/gpg-agent.bash
#  modify - none
#  delete - none
#
# Environment Variables:
#   none
#
# Package Prerequisites (binaries):
#   awk (mawk)
#   gpg (gpg)
#   grep (grep)
#

#   --quick-generate-key is too simplistic
#   --full-generate-key ignores $HOME/.gnupg/gpg.conf
gpg --generate-key

echo "This is an interactive terminal session"
echo
echo "You will be in 'trust' menu"
echo "Select '5' then ENTER"
echo "Enter in 'quit' then ENTER"
echo
echo "Do this for every public keys made locally."
echo
echo "Press ENTER to continue: "
read -r ANYKEY
if [ -n "$ANYKEY" ]; then
  echo "Aborted."
  exit 255
fi

# Extract the PGP ID
LIST_LOCAL_PUBLIC="$(gpg --list-keys --with-colons | grep pub:u:255:22 | awk -F: '{ print $5 }')"

for KEY in $LIST_LOCAL_PUBLIC; do
  echo "Trusting PGP public key ID: $KEY:"
  gpg --edit-key "$KEY" trust
done

echo "$0: done."
