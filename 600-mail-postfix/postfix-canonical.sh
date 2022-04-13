#!/bin/bash

BUILDROOT="build"

source maintainer-mail-postfix.sh

mkdir -p "$BUILDROOT"
mkdir -p "${BUILDROOT}$POSTFIX_DIRSPEC"

touch ${BUILDROOT}${CANONICAL_FILESPEC}

echo "canonical_maps = hash:/etc/postfix/canonical" >> ${BUILDROOT}$MAIN_CF_FILESPEC
