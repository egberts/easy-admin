#!/bin/bash
# File: postfix-passwd-setup.sh
# Title: Sets up the authentication methods for Postfix

BUILDROOT="build"

source maintainer-mail-postfix.sh

mkdir -p "$BUILDROOT"
mkdir -p "${BUILDROOT}${CHROOT_DIR}$POSTFIX_DIRSPEC"
mkdir -p "${BUILDROOT}${CHROOT_DIR}$SASL_DIRSPEC"

touch ${BUILDROOT}${CHROOT_DIR}${SASL_SMTPD_CONF_FILESPEC}

cat << SASL_SMTPD_EOF | tee ${BUILDROOT}${CHROOT_DIR}${SASL_SMTPD_CONF_FILESPEC}
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN
SASL_SMTPD_EOF
