#!/bin/bash
# File: 515-dns-bind9-interkeys.sh
# Title: Create HMAC keys for inter-communication of multiple name servers.
# Description:
#   Provides a HMAC key for symetric secured communication between
#   different instances of named servers within the same host
#   using tsig-keygen.
#
# Environment Variables:
#   - KEY_ALGORITHM - hmac-sha512, hmac-sha384, hmac-sha256,
#                     hmac-sha224, hmac-sha1, hmac-md5
#
echo "Create a key for both DHCP and DNS to securely communicate
echo

source ./maintainer-dns-isc.sh

HMAC_KEY_KEYNAME="bastion-inter-instance-$KEY_ALGORITHM"
HMAC_KEY_FILENAME="${HMAC_KEY_KEYNAME}.key"
HMAC_KEY_DIRSPEC="/var/lib/bind/keys"
HMAC_KEY_FILESPEC="${HMAC_KEY_DIRSPEC}/$HMAC_KEY_FILENAME"

function create_hmac_key_header() {
    echo "Creating ${CHROOT_DIR}$HMAC_KEY_FILESPEC ..."
    flex_touch "$HMAC_KEY_FILESPEC"
    cat << EOF | tee "${BUILDROOT}${CHROOT_DIR}$HMAC_KEY_FILESPEC" >/dev/null
#
# File: ${HMAC_KEY_FILENAME}
# Path: ${HMAC_KEY_DIRSPEC}
# Title: Create HMAC keys for inter-communication of multiple name servers.
# Description:
#   Provides a HMAC key for symetric secured communication between
#   different instances of named servers within the same host
#   using tsig-keygen.
#
#   To recreate HMAC key, run:
#     $ tsig-keygen \\
#           -a $KEY_ALGORITHM \\
#           $HMAC_KEY_KEYNAME \\
#           > $HMAC_KEY_FILESPEC
#
#   Or you could run
#     $ $0
#
#   Then reload ALL instances of named daemon within this host.
#
# Creator: $(basename "$0")
# Date: $(date)
#

EOF
}


flex_mkdir "$HMAC_KEY_DIRSPEC"
flex_chown root:bind "$HMAC_KEY_FILESPEC"
flex_chmod 0640      "$HMAC_KEY_FILESPEC"
create_hmac_key_header

# Write to the partial-config build area for inclusion into named.conf
PARTCFG_KEY_FILENAME="key-inter-instance.conf"
PARTCFG_KEY_DIRSPEC="${BUILDBIND}$INSTANCE_DIRSPEC"
PARTCFG_KEY_FILESPEC="${PARTCFG_KEY_DIRSPEC}/$PARTCFG_KEY_FILENAME"

# mkdir $PARTCFG_KEY_DIRSPEC
cat << EOF | tee "$PARTCFG_KEY_FILESPEC" >/dev/null
# Key used for inter-communication of named servers within same host
include "${CHROOT_DIR}$HMAC_KEY_FILESPEC";
EOF

echo ""
echo "Done."
exit 0

