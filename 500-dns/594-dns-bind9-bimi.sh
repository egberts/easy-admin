#!/bin/bash
# File: 592-dns-bimi.sh
# Title:  Set up BIMI so that your icon can appears in GMail and Fastmail
#
# Description:
#
#   Pay $1,000 USD per year to display your verified trademark icon
#   on GMail and Fastmail that these remote mail clients will see
#   next to each of your sent email.  Yes, $1,000/year.  O_o
#
#   You could still use it in an unsigned-form of SVG but GMail/Fastmail
#   may NOT accept it.
#
#     Check for default._bimi.example.invalid TXT
#     look for a 'v=BIMI1' tag
#     extract value to 'l=' containing URL to SVG image
#     wget $extracted_bimi_image
#     check DMARC record using 'dig +short _dmarc.egbert.net TXT'
#     check DMARC tags: v=DMARC1; p=none; rua=mailto:dmarc@egbert.net; fo=1
#     check DMARC 'p' tag: for 'quarantine' or 'reject'; 'none' is NOT OK.
#     check MX record
#     check for reverse DNS (PTR) records to each MX IP address
#     check for valid SPF records
#     Use https://bimigroup.org/bimi-generator/ to check for SVG flaws
#
#
# Needs a pretty simple SVG file (no radialGradient, no
#    style, no IRI, and version="1.2").
#
# Environment variables, overridable
#   WWW_ROOT_DIR - HTTP document root directory (default /var/lib/www)
#
# Dependencies:
#    dig (bind9-dnsutils)
#    nslookup (bind9-dnsutils)
#    awk (gawk)
#    coreutils
#
# References:
#  * https://bimigroup.org/how-bimi-avoids-unauthorized-or-fraudulent-use-of-logos/
#  * https://bimigroup.org/bimi-generator/
#  * https://mxtoolbox.com/SuperTool.aspx?action=a%3aegbert.net&run=toolpage
#  * https://bimigroup.org/vmcs-arent-a-golden-ticket-for-bimi-logo-display/
#  *

DEFAULT_DOMAIN_NAME="$(hostname -d)"

echo "Set up BIMI icon for other people's remote webmail client to extract"
echo "and denoate each of your e-mail to them."
echo

source ./maintainer-dns-isc.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-dns-bimi${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
if [ "${BUILDROOT:0:1}" != '/' ]; then
  FILE_SETTING_METHOD=false
  mkdir -p build
  flex_ckdir "$VAR_DIRSPEC"
  flex_ckdir "$VAR_LIB_DIRSPEC"
else
  FILE_SETTING_METHOD=false
fi
flex_ckdir "$VAR_LIB_NAMED_DIRSPEC"

if [ -n "$DEFAULT_DOMAIN_NAME" ]; then
  read_opts="-ei${DEFAULT_DOMAIN_NAME}"
fi
echo "Part of email address to create a BIMI TXT"
read -rp "Enter in domain name part of email address: " $read_opts

# Add 'root' server to the domain name
DOMAIN_NAME="$REPLY"
if [ "${REPLY: -1:1}" != '.' ]; then
  FQ_DOMAIN_NAME="${REPLY}."
else
  FQ_DOMAIN_NAME="${REPLY}"
fi

WWW_ROOT_DIR="${HTDOCS_DIR:-${VAR_LIB_DIRSPEC}/www}}"

#  Obtain TXT RR via default_.bimi.$FQ_DOMAIN_NAME
BIMI_DEFAULT_DOMAINNAME="default._bimi.$DOMAIN_NAME"

CREATE_BIMI_RR=0
BIMI_TXT=$(delv +short -i $BIMI_DEFAULT_DOMAINNAME TXT)
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Unable to query '${BIMI_DEFAULT_DOMAINNAME}' TXT in"
  echo "the '${FQ_DOMAIN_NAME}' zone."
  CREATE_BIMI_RR=1
fi
if [ -z "$BIMI_TXT" ]; then
  echo "No '${BIMI_DEFAULT_DOMAINNAME}' resource record found in"
  echo "the '${DOMAIN_NAME}' zone database."
  CREATE_BIMI_RR=1
fi
CREATE_BIMI_RR=1

if [ "$CREATE_BIMI_RR" -eq 1 ]; then

  read -rp "Enter in URL of BIMI SVG image file: " -e
  BIMI_IMAGE_URL="$REPLY"
  pushd .
  cd /tmp
  # file:/// does not work for 'wget'
  # consider using 'curl'
  wget --no-cache \
          --no-cookie \
          --no-check-certificate \
          $BIMI_IMAGE_URL
  retsts=$?
  popd
  if [ $retsts -ne 0 ]; then
    echo "URL: $BIMI_IMAGE_URL not found"
    echo "Probably should make this URL work first before finishing this script"
    echo "Aborted."
    exit $retsts
  fi


  ZONE_DB_FILENAME="db.${DOMAIN_NAME}"

  ZONE_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
  flex_ckdir "$ZONE_DB_DIRSPEC"
  ZONE_DB_FILESPEC="${ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

  INSTANCE_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
  flex_ckdir "$INSTANCE_ZONE_DB_DIRSPEC"
  INSTANCE_ZONE_DB_FILESPEC="${INSTANCE_ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

  ZONE_DB_BIMI_FILENAME="db.bimi.${DOMAIN_NAME}"

  ZONE_DB_BIMI_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
  ZONE_DB_BIMI_FILESPEC="${ZONE_DB_BIMI_DIRSPEC}/${ZONE_DB_BIMI_FILENAME}"

  INSTANCE_ZONE_DB_BIMI_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/$ZONE_TYPE_NAME"
  INSTANCE_ZONE_DB_BIMI_FILESPEC="${INSTANCE_ZONE_DB_BIMI_DIRSPEC}/$ZONE_DB_BIMI_FILENAME"


  # Create BIMI zone file add-on
  echo "Creating $filespec ..."
  cat << BIMI_EOF | tee "${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_BIMI_FILESPEC" > /dev/null
\$ORIGIN $FQ_DOMAIN_NAME
;
; File: $filename
; Path: $filepath
; Title: BIMI resource records for $FQ_DOMAIN_NAME
;

default._bimi       IN  TXT "v=BIMI1;l=${BIMI_IMAGE_URL};a="

BIMI_EOF
  flex_chmod 0640 "${INSTANCE_ZONE_DB_BIMI_FILESPEC}"
  flex_chown "root:$GROUP_NAME" "${INSTANCE_ZONE_DB_BIMI_FILESPEC}"

  # Append '$INCLUDE bimi-zone-addon' to domain zone file
  echo "\$ORIGIN ${FQ_DOMAIN_NAME}" >> ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_FILESPEC
  echo "\$INCLUDE \"${INSTANCE_ZONE_DB_BIMI_FILESPEC}\"" >> ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_FILESPEC

else
  echo "Query to $BIMI_DEFAULT_DOMAINNAME} TXT RR successful."
  echo "Result: $BIMI_TXT"
  exit
  #
  # look for a 'v=BIMI1' tag
  # in v=BIMI1;l=https://example.invalid/images/bimi1_image.svg;a=
  #
  if ! [[ "$BIMI_TXT" =~ .*"v=BIMI1"*. ]]; then
    echo "BIMI TXT RR does not have 'v=BIMI1', aborted."
    exit 11
  fi

  # remove surrounding double-quote from TXT record before parsing
  if [ "${BIMI_TXT:0:1}" == '"' ]; then
    BIMI_TXT="${BIMI_TXT:1}"
  fi
  if [ "${BIMI_TXT: -1}" == '"' ]; then
    BIMI_TXT="${BIMI_TXT:0: -1}"
  fi

  # separate all arguments by semicolon symbol into a bash array
  IFS='; ' read -r -a BIMI_A <<< "$BIMI_TXT"

  # Read each key/value
  # to extract value to 'l=' containing URL to SVG image
  for this_keyvalue in ${BIMI_A[*]}; do
    key="$(echo "$this_keyvalue" | awk -F= '{print $1}')"
    value="$(echo "$this_keyvalue" | awk -F= '{print $2}')"
    echo "this_keyvalue: $this_keyvalue"
    echo "key: $key"
    echo "value: $value"
    case $key in
      l)
        echo "Extracted '$value' from option '$key'"
        BIMI_IMAGE_URL="$value"
        ;;
      a)
        echo "Extracted '$value' from option '$key'"
        BIMI_ACTION="$value"
        ;;
      v)
        echo "Extracted '$value' from option '$key'"
        BIMI_VERSION="$value"
        ;;
      *)
        echo "Strange '$key' option found in BIMI TXT RR; aborted."
        exit 13
        ;;
    esac
    echo
  done

  #
  # wget $extracted_bimi_image
  pushd .
  cd /tmp
  wget --no-cache \
          --no-cookie \
          --no-check-certificate \
          $BIMI_IMAGE_URL
  popd
fi
exit
#
# check DMARC record using 'dig +short _dmarc.egbert.net TXT'
#
# check DMARC tags: v=DMARC1; p=none; rua=mailto:dmarc@egbert.net; fo=1
# check DMARC 'p' tag: for 'quarantine' or 'reject'; 'none' is NOT OK.
#
#  check MX record
#
# check for reverse DNS (PTR) records to each MX IP address
#
# check for valid SPF records
#

echo "Use https://bimigroup.org/bimi-generator/ to check for flaws in SVG image "
#
exit 0
