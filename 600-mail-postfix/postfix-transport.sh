#!/bin/bash
# File: postfix-transport.sh
# Title: Create transport config settings for Postfix

BUILDROOT="build"

source maintainer-mail-postfix.sh

mkdir -p "$BUILDROOT"
mkdir -p "${BUILDROOT}$POSTFIX_DIRSPEC"

touch ${BUILDROOT}${TRANSPORT_FILESPEC}

echo "transport_maps = hash:${TRANSPORT_FILESPEC}" >> ${BUILDROOT}$MAIN_CF_FILESPEC
