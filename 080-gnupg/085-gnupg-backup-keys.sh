#!/bin/bash
# File: 081-gnupg-backup-keys.sh
# Title: Backup on paper, all your GPG  keys
#


TMPDIR="/tmp/gnupg"

echo ""
echo "Prints out all GnuPG/PGP secret keys on paper:"
echo "    for insertion into your physical safe."
echo ""
read -rp "Press any key to continue: " -n1

#PREREQUISITE_PKGS="gpg paperkey grep coreutils util-linux cups-bsd"
# get fingerprint of all keys
#
KEY_FINGERPRINTS="$(gpg --list-secret-keys | grep '^\s\s\s\s\s\s\S*')"
KEY_FINGERPRINTS="${KEY_FINGERPRINTS// /}"
# extract fingerprints from output (somehow)
PGP_KEYS_COUNT="$(echo "$KEY_FINGERPRINTS"|wc -w)"
if [ "$PGP_KEYS_COUNT" -eq 0 ]; then
  echo "No GnuPG/PGP keys found"
  echo "Aborted."
  exit 9
fi

echo
echo "There are $PGP_KEYS_COUNT keys found:"
for this_key in $KEY_FINGERPRINTS; do
  gpg --list-key "$this_key"
done
echo

echo "Passphrase is prompted TWICE for each key found in your GPG trustdb:"
echo "   1. To print the key's secret on paper"
echo "   2. To print the key's revocation on paper."

LPQ_BIN="$(whereis -b lpq|awk -F: '{print $2}')"
if [ -z "$LPQ_BIN" ]; then
  echo ""
  echo "There is no line printer available: missing 'lpq' command."
  read -rp "Save the files? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  if [ -z "$REPLY" ] || [ "$REPLY" == "n" ]; then
    echo "Aborted."
    exit 9
  fi
  echo "ALL FILES will be in $TMPDIR directory; go after them when done."
fi

mkdir $TMPDIR
chmod 0700 $TMPDIR

# Obviously there are more than one parent key.
for this_key in $KEY_FINGERPRINTS; do

  PASSPHRASE_KEY_FILESPEC="$TMPDIR/passphrase-$this_key.txt"
  REVOCATION_KEY_FILESPEC="$TMPDIR/revocation-$this_key.asc"
  echo ""
  echo ""
  echo ""
  echo "Unlocking above key..."
  read -rp "Press any key to prompt for GPG main passphrase" -n1
  # Make a paper-based GPG primary key for insertion into a physical safe
  gpg --export-secret-key "$this_key" | paperkey -o "$PASSPHRASE_KEY_FILESPEC"
  echo "Paper key file for $this_key: $PASSPHRASE_KEY_FILESPEC"


  if [ -n "$LPQ_BIN" ]; then
    echo ""
    echo "Submitting lpr print job for paper key."
    lpr "$PASSPHRASE_KEY_FILESPEC"

    echo "Deleting paper key file for $this_key"
    rm "$PASSPHRASE_KEY_FILESPEC"
  fi

  # Get revocation certificate on paper for insertion into a physical safe.
  # Good for when you lose your password
  # Make a paper-based GPG revocation key for insertion into a physical safe
  echo
  echo "Creating a paper key for revocation (in case you lost your passphrase)"
  gpg --output "$REVOCATION_KEY_FILESPEC" --gen-revoke "$this_key"

  if [ -n "$LPQ_BIN" ]; then
    lpr "$REVOCATION_KEY_FILESPEC"
    echo "Deleting revocation key file for $this_key"
    rm "$REVOCATION_KEY_FILESPEC"
  fi

done

echo "All done with $PGP_KEYS_COUNT keys."
if [ -n "$LPQ_BIN" ]; then
  echo "Current print jobs:"
  $LPQ_BIN
else
  echo "All files created inside $TMPDIR directory."
fi
echo

echo "Done."
exit 0
