#!/bin/bash
# File: 600-net-web-well-known.sh
# Title: Create well-known files


DOMAIN_NAME="example.invalid"
# SMARTHOST_DOMAIN_NAME="mail.example.invalid"
SMART_HOST_DOMAIN_NAME="${DOMAIN_NAME}"
GNUPG_KEY_ID="5f2de5521c63a801ab59ccb603d49de44b29100f"
TELEPHONE=

HTML_DIR="/var/www/html"


#
WELLKNOWN_DIRSPEC="${HTML_DIR}/.well-known"
if [ ! -d "$WELLKNOWN_DIRSPEC" ]; then
  echo "Creating $WELLKNOWN_DIRSPEC subdirectory ..."
  mkdir "$WELLKNOWN_DIRSPEC"
fi

#
# Create PKI Validation (required by CAB Forum)
PKI_VAL_DIRSPEC="${WELLKNOWN_DIRSPEC}/pki-validation"

echo "Creating ${PKI_VAL_DIRSPEC} ..."
cat << PKI_VAL_EOF | tee "$PKI_VAL_DIRSPEC" >/dev/null
#
# File: ${PKI_VAL_DIRSPEC}
# Title: Well-Known PKI Validation file
# Description:
#   Detailed in CAB Forum 3.2.2.4.6
PKI_VAL_EOF

#
# Create security.txt (IETF draft-foudil-securitytxt)
SEC_TXT_DIRSPEC="${WELLKNOWN_DIRSPEC}/security.txt"

echo "Creating ${SEC_TXT_DIRSPEC} ..."
cat << SEC_TXT_EOF | tee "$SEC_TXT_DIRSPEC" >/dev/null
#
# File: ${SEC_TXT_DIRSPEC}
# Title: Well-Known security.txt
# Description:
#   IETF draft-foundil-securitytxt
# Reference:
#   - https://datatracker.ietf.org/doc/draft-foudil-securitytxt/12/

# Disclosure Policy
Policy: https://${DOMAIN_NAME}/disclosure-policy.html

# Our security address
Contact: mailto:security@${DOMAIN_NAME}
Contact: https://${DOMAIN_NAME}/security-contact.html
SEC_TXT_EOF
if [ -n "$TELEPHONE" ]; then
  cat << SEC_TXT_EOF | tee -a "$SEC_TXT_DIRSPEC" >/dev/null
Contact: tel:${TELEPHONE}

SEC_TXT_EOF
fi
if [ "$GNUPG_KEY_ID" ]; then
  GNUPG_KEY_ID_16="${GNUPG_KEY_ID:0:16}"
# Our OpenPGP encryption keys
  cat << SEC_TXT_EOF | tee -a "$SEC_TXT_DIRSPEC" >/dev/null
Encryption: dns:${GNUPG_KEY_ID_16}._openpgpkey.${DOMAIN_NAME}?type=OPENPGPKEY
Encryption: https://${DOMAIN_NAME}/pgp-key.txt
Encryption: openpgp4fpr:${GNUPG_KEY_ID}

SEC_TXT_EOF
fi

cat << SEC_TXT_EOF | tee -a "$SEC_TXT_DIRSPEC" >/dev/null
# Opportunities for IT security folks
Hiring: https://${DOMAIN_NAME}/jobs.html

Preferred-Languages: en, ru, ch

# Our security acknowledgments page
Acknowledgments: https://${DOMAIN_NAME}/hall-of-fame.html

Expires: 2023-12-31T18:37:07z
SEC_TXT_EOF

#
# Create _mta_sts.txt (IETF RFC 8461 MTA-STS)
MTA_STS_DIRSPEC="${WELLKNOWN_DIRSPEC}/mta_sts.txt"
echo "Creating ${MTA_STS_DIRSPEC} ..."
cat << MTA_STS_EOF | tee "$MTA_STS_DIRSPEC" >/dev/null
#
# File: ${MTA_STS_DIRSPEC}
# Title: Well-Known _mta_sts.txt
# Description:
#   IETF RFC 8461 MTA-STS
#   Two DNS records required:
#
#    -  mta_sts.${DOMAIN_NAME} that only provides one HTTP page and
#                               must be defined in the zone file.
#
#    -  _mta_sts.${DOMAIN_NAME} that only provides one DNS
#                               RRCODE TXT record and must contain
#                               "v=STSv1,id=20160831085700Z"
#
#   One HTTPS web page required:
#    -  The _mta_sts.txt file shall be served only by HTTPS protocol
#       with certain HTTP response headers
#       and only at mta_sts.${SMARTHOST_DOMAIN_NAME} domain name.
#         - HTTP Request Header: Content-Type: plain/text
#         - HTTP Request Header: Cache-Control: 60
#    - One symbolic link of mta_sts.txt pointing to _mta_sts.txt
#
# The policy itself is a set of key/value pairs (similar to header
#  fields in [RFC5322]) served via the HTTPS GET method from the fixed
#  "well-known" [RFC5785] path of ".well-known/mta-sts.txt" served by
#  the Policy Host.  The Policy Host DNS name is constructed by
#  prepending "mta-sts" to the Policy Domain.
#
#  Thus, for a Policy Domain of "example.com", the full URL is
#  "https://mta-sts.example.com/.well-known/mta-sts.txt".
#
#  When fetching a policy, senders SHOULD validate that the media type
#  is "text/plain" to guard against cases where web servers allow
#  untrusted users to host non-text content (typically, HTML or images)
#  at a user-defined path.  All parameters other than charset=utf-8 or
#  charset=us-ascii are ignored.  Additional "Content-Type" parameters
#  are also ignored.
#
# Reference:
#   - https://www.rfc-editor.org/rfc/rfc8461.html

version: STSv1

# other modes are 'testing', 'enforce', 'none'
# - "enforce": In this mode, Sending MTAs MUST NOT deliver the
#       message to hosts that fail MX matching or certificate validation
#       or that do not support STARTTLS.
#
# - "testing": In this mode, Sending MTAs that also implement the
#       TLSRPT (TLS Reporting) specification [RFC8460] send a report
#       indicating policy application failures (as long as TLSRPT is also
#       implemented by the recipient domain); in any case, messages may
#       be delivered as though there were no MTA-STS validation failure.
# - "none": In this mode, Sending MTAs should treat the Policy Domain
#       as though it does not have any active policy
mode: enforce


max-age: 604800

# MX Host Validation
mx: ${SMARTHOST_DOMAIN_NAME}
mx: mx1.${SMARTHOST_DOMAIN_NAME}
mx: mx2.${SMARTHOST_DOMAIN_NAME}

MTA_STS_EOF

#
#
