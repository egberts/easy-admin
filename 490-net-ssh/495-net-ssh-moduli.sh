#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#
echo "OpenSSH Moduli File Creator"
echo ""

source ssh-openssh-common.sh

SSH_MODULI_BITS=4096

SSH_MODULI_FILENAME="moduli"
SSH_MODULI_FILESPEC="${sysconfdir}/$SSH_MODULI_FILENAME"

TEMP_MODULI_FILESPEC="/tmp/${SSH_MODULI_FILENAME}-${SSH_MODULI_BITS}"
TEMP_MODULI_CANDIDATES_FILESPEC="${TEMP_MODULI_FILESPEC}.candidates"
TEMP_MODULI_SAFE_FILESPEC="${TEMP_MODULI_FILESPEC}.safe"

echo "Generating ${SSH_MODULI_BITS}-bit moduli candidates ..."
echo "... in ${TEMP_MODULI_CANDIDATES_FILESPEC} ..."
ssh-keygen -M generate \
    -O bits=${SSH_MODULI_BITS} \
    "${TEMP_MODULI_CANDIDATES_FILESPEC}"

echo "Screening moduli of ${SSH_MODULI_BITS} bits..."
ssh-keygen -M screen \
        -f "${TEMP_MODULI_CANDIDATES_FILESPEC}" \
        "${TEMP_MODULI_SAFE_FILESPEC}"

if [ false ]; then
  awk '$5 > 3071' \
    ${TEMP_MODULI_CANDIDATES_FILESPEC} \
    | tee ${TEMP_MODULI_FILESPEC}
else
  cp "${TEMP_MODULI_SAFE_FILESPEC}" "${BUILDROOT}$SSH_MODULI_FILESPEC"
fi
echo "Completed the Moduli Generation."

flex_chmod 640 "$SSH_MODULI_FILESPEC"
flex_chown root:ssh "$SSH_MODULI_FILESPEC"

rm "$TEMP_MODULI_CANDIDATES_FILESPEC"
rm "$TEMP_MODULI_SAFE_FILESPEC"
rm "$TEMP_MODULI_FILESPEC"

echo "Done."

