#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#
# Examples:
#   ./495-net-ssh-moduli.sh
#   SSH_MODULI_BITS=512 ./495-net-ssh-moduli.sh  # one hour'ish
#   SSH_MODULI_BITS=8192 ./495-net-ssh-moduli.sh  # takes about 2 days
#
# Environment settings:
#   SSH_MODULI_BITS - 512 to 8192
#
echo "OpenSSH Moduli File Creator"
echo ""

# getrandom(3) SSH_USE_STRONG_RNG
GRND_RANDOM=1
# SSH_USE_STRONG_RNG - 14 to infinity, default 14
SSH_USE_STRONG_RNG=1
GRND_NONBLOCK=1
GRND_RANDOM=1

source ./maintainer-ssh-openssh.sh

case $ID in
  debian)
    if [ "$VERSION_ID" -lt 8 ]; then
      SSH_KEYGEN_VERSION=0
    else
      SSH_KEYGEN_VERSION=1
    fi
    ;;
  redhat)
    if [ "$VERSION_ID" -le 8 ]; then
      SSH_KEYGEN_VERSION=0
    else
      SSH_KEYGEN_VERSION=1
    fi
    ;;
  fedora)
    if [ "$VERSION_ID" -le 29 ]; then
      SSH_KEYGEN_VERSION=0
    else
      SSH_KEYGEN_VERSION=1
    fi
    ;;
  centos)
    if [ "$VERSION_ID" -le 8 ]; then
      SSH_KEYGEN_VERSION=0
    else
      SSH_KEYGEN_VERSION=1
    fi
    ;;
  arch)
    SSH_KEYGEN_VERSION=1
    ;;
esac

SSH_MODULI_BITS="${SSH_MODULI_BITS:-4096}"

SSH_MODULI_FILENAME="moduli"
SSH_MODULI_FILESPEC="${openssh_config_dirspec}/$SSH_MODULI_FILENAME"

TEMP_MODULI_FILESPEC="/tmp/${SSH_MODULI_FILENAME}-${SSH_MODULI_BITS}"
TEMP_MODULI_CANDIDATES_FILESPEC="${TEMP_MODULI_FILESPEC}.candidates"
TEMP_MODULI_SAFE_FILESPEC="${TEMP_MODULI_FILESPEC}.safe"

echo "Generating ${SSH_MODULI_BITS}-bit moduli candidates ..."
echo "... in ${TEMP_MODULI_CANDIDATES_FILESPEC} ..."
if [ "$SSH_KEYGEN_VERSION" -eq 0 ]; then
  ssh-keygen -G "$TEMP_MODULI_CANDIDATES_FILESPEC" \
      -b "$SSH_MODULI_BITS"
  ssh-keygen -T "$TEMP_MODULI_SAFE_FILESPEC" \
      -f "$TEMP_MODULI_CANDIDATES_FILESPEC" 
else
  ssh-keygen -M generate \
      -O bits=${SSH_MODULI_BITS} \
      "${TEMP_MODULI_SAFE_FILESPEC}"

  echo "Screening moduli of ${SSH_MODULI_BITS} bits..."
  ssh-keygen -M screen \
          -f "${TEMP_MODULI_SAFE_FILESPEC}" \
          "${TEMP_MODULI_SAFE_FILESPEC}"
fi

if [ false ]; then
  awk '$5 > 3071' \
    ${TEMP_MODULI_SAFE_FILESPEC} \
    | tee ${TEMP_MODULI_FILESPEC}
else
  cp "${TEMP_MODULI_SAFE_FILESPEC}" "${BUILDROOT}$SSH_MODULI_FILESPEC"
fi
echo "Completed the Moduli Generation."

flex_chmod 640 "$SSH_MODULI_FILESPEC"
flex_chown root:ssh "$SSH_MODULI_FILESPEC"

echo "Removing temporary files ..."
rm "$TEMP_MODULI_CANDIDATES_FILESPEC"
rm "$TEMP_MODULI_SAFE_FILESPEC"
rm "$TEMP_MODULI_FILESPEC"
echo ""

echo "Done."

