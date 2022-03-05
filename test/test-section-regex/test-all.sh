#!/bin/sh
echo "Unit-test section-regex.sh bash module"

. ./test-ini-file-read.sh
. ./test-ini-section-list.sh
. ./test-ini-section-test.sh
. ./test-ini-section-extract.sh
. ./test-ini-kw-normalize.sh
. ./test-ini-kw-valid.sh
. ./test-ini-kw-get.sh

echo ""

echo "${BASH_SOURCE[0]}: Done."
