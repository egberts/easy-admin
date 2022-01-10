#!/bin/bash
# File: 514-dns-bind9-rndc-cli.sh
# Title: Create easy-to-remember scripts for many-instance rndc operations
# Description:
#   Creates a rndc script for each instance of Bind9
#
#
# Create:
#    /usr/local/bin/rndc-<instance>
#
# Prerequisites:
#   - INSTANCE_NAME - Bind9 instance name, if any
#

echo "Creating instance-specific 'rndc' script files for $mytool_bindir..."
echo

source ./maintainer-dns-isc.sh

if [ -z "$INSTANCE_NAME" ]; then
  echo "Must define INSTANCE_NAME envar."
  echo "This script only works with instances of Bind9, not default"
  echo "Aborted."
  exit 9
fi

if [ ! -d "$mytool_bindir" ]; then
  echo "Mmmmm, $mytool_bindir directory does not exist."
  echo "Aborted."
  exit 9
fi

# extend the 'rndc' bin filename part
INST_RNDC_BIN_FILENAME="${ISC_RNDC_BIN_FILENAME}${INSTANCE_SUFFIX}"
INST_RNDC_BIN_DIRSPEC="$mytool_bindir"
INST_RNDC_BIN_FILESPEC="${INST_RNDC_BIN_DIRSPEC}/$INST_RNDC_BIN_FILENAME"

flex_mkdir "$mytool_bindir"

echo "Creating ${CHROOT_DIR}$INST_RNDC_BIN_FILESPEC..."
flex_touch root:root "$INST_RNDC_BIN_FILESPEC"
flex_chown root:root "$INST_RNDC_BIN_FILESPEC"
flex_chmod 0750      "$INST_RNDC_BIN_FILESPEC"
cat << EOF | tee "${BUILDROOT}${CHROOT_DIR}$INST_RNDC_BIN_FILESPEC" >/dev/null
#
# File: $INST_RNDC_BIN_FILENAME
# Path: $INST_RNDC_BIN_DIRSPEC
# Title: Remote named Daemon Control (rndc) for '$INSTANCE_NAME' instance
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#   A simplified 'rndc' instantiated by '$INSTANCE_NAME' instance.
#
# Note:
#   To recreate the key for this '$INSTANCE_NAME' instance of rndc, run:
#
#     /usr/sbin/rndc-confgen -a \\
#       -A $KEY_ALGORITHM \\
#       -k "$KEY_NAME" \\
#       -c "$RNDC_KEY_FILESPEC"
#

rndc -s $INSTANCE_NAME \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8 \$9
exit \$?

EOF
echo ""
echo "Done."
exit 0

