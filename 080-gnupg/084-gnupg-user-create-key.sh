#!/bin/bash
# File: 081-gnupg-setup-user.sh
# Title: GNU Pretty Good Privacy setup for end-user
#
# --quick-generate-key is too simplistic
# --full-generate-key ignores $HOME/.gnupg/gpg.conf
gpg --generate-key 

echo "This is an interactive terminal session"
echo
echo "Enter in 'trust' then ENTER"
echo "Select '5' then ENTER"
echo "Enter in 'quit' then ENTER"
echo
echo "Do this for every public keys made locally."
echo
echo "Press ENTER to continue: "
read -r ANYKEY
if [ ! -z "$ANYKEY" ]; then
  echo "Aborted."
  exit 255
fi

# Extract the PGP ID
LIST_LOCAL_PUBLIC="`gpg --list-keys --with-colons | grep pub:u:255:22 | awk -F: '{ print $5 }'`"

for KEY in $LIST_LOCAL_PUBLIC; do
  echo "Trusting PGP public key ID: $KEY:"
  gpg --edit-key $KEY
done

echo "$0: done."
