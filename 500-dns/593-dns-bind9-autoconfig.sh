#!/bin/bash
# File: 593-dns-bind-autoconfig.sh
# Title:  Set up autoconfig for remote Mozilla-only email client (thunderbird)
#
# Description:
#
#   Assist remote mail clients (Apple Mail, Thunderbird, Outlook) in
#   finding your SMTP/IMAP/POP3 servers.
#
# MOZILLA THUNDERBIRD:
# MICROSOFT OUTLOOK:
#   The Outlook mail client performs the following AutoDiscover phases
#   to detect the server endpoint URLs:
#
#    Phase 1 – The client performs a Secure Copy Protocol
#    (SCP) lookup against the local Active Directory.
#    If your client isn’t domain-joined, AutoDiscover skips this step.
#    NOTE: This Phase 1 is totally ignored here in this script.
#
#    Phase 2 – The client sends a request to the following
#    URLs and validates the results. These endpoints are only
#    available using HTTPS.
#
#     * https://company.tld/autodiscover/autodiscover.xml
#     * https://autodiscover.company.tld/autodiscover/autodiscover.xml
#
#    Phase 3 – The client performs a DNS lookup to
#    autodiscover.company.tld and sends an unauthenticated GET
#    request to the derived endpoint from the user’s email
#    address. If the server returns a 302 redirect, the client
#    resends the AutoDiscover request against the returned HTTPS endpoint.
#
#   Can use 'autoconfig.DOMAIN_NAME IN A 127.0.0.1' to disable
#   Can use 'autodiscover.DOMAIN_NAME IN A 127.0.0.1' to disable
#
# APPLE MAIL:
#
# Environment variables, overridable
#   HTDOCS_DIR - HTTP document root directory (default /var/lib/www)
#
# Dependencies:
#    dig (bind9-dnsutils)
#    nslookup (bind9-dnsutils)
#    awk (gawk)
#    coreutils
#
# References:
#  * https://www.icdsoft.com/en/kb/view/1698_automatic_e_mail_configuration_autodiscover_autoconfig
#  * https://netwinsite.com/surgemail/help/autodiscover.htm
#  * https://docs.aws.amazon.com/workmail/latest/adminguide/autodiscover.html

echo "Set up autoconfig for remote Mozilla-only email client (thunderbird)"
echo

source ./maintainer-dns-isc.sh

HTDOCS_DIR="${HTDOCS_DIR:-${VAR_LIB_DIRSPEC}/www}"
HTDOCS_DIRSPEC="$HTDOCS_DIR"

if [ "${BUILDROOT:0:1}" == '/' ]; then
  # absolute (rootfs?)
  echo "Absolute build"
else
  mkdir -p build
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind-smtp-autoconfig${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  mkdir -p build/etc
  mkdir -p build/var
  mkdir -p build/var/lib
  flex_mkdir "${ETC_NAMED_DIRSPEC}"
  flex_mkdir "${VAR_LIB_NAMED_DIRSPEC}"
  if [ -n "$INSTANCE" ]; then
    flex_mkdir "${INSTANCE_ETC_NAMED_DIRSPEC}"
    flex_mkdir "${INSTANCE_VAR_LIB_NAMED_DIRSPEC}"
  fi
fi

DEFAULT_DOMAIN_NAME="egbert.net"
OC_NAME="ACME Networks"
OC_SHORTNAME="ACME"
# THUNDERBIRD_VERSION="$(thunderbird --version)"
THUNDERBIRD_VERSION="78.41.01"

echo "Email address syntax:  localpart@address_part"
echo "To provide autoconfig support to 'address_part' for remote email clients,"
read -rp "Enter in address part of email: " -ei${DEFAULT_DOMAIN_NAME}
DOMAIN_NAME="$REPLY"

# Check if website and DNS NS is up firstly before using this tool

# Check if domain name MX is up firstly
echo -n "Checking for MX record in $DOMAIN_NAME DNS..."
SMTP_DOMAINNAME="$(dig +short "$DOMAIN_NAME" MX | awk '{print $2}')"
if [ -z "$SMTP_DOMAINNAME" ]; then
  echo
  echo "SMTP MX Address_part of $DOMAIN_NAME not found; aborted."
  echo
  echo "Probably need to add a $SMTP_DOMAINNAME 'MX' resource record into your"
  echo "'${DOMAIN_NAME}' zone file."
  exit 9
fi
THIS_MX_HOSTNAME="$SMTP_DOMAINNAME"
echo " $THIS_MX_HOSTNAME found."

# Check if MX's A resource record is queriable
echo -n "Checking for MX record in $THIS_MX_HOSTNAME DNS..."
THIS_A="$(dig +short "$THIS_MX_HOSTNAME" A)"
if [ -z "$THIS_A" ]; then
  echo
  echo "MX '$THIS_MX_HOSTNAME' does not have an IP address (missing 'A' record)."
  echo
  echo "Probably need to add a working 'A' resource record into your"
  echo "'${DOMAIN_NAME}' zone file."
  exit 9
fi
echo " $THIS_A found."

# Now we check the well-known port numbers for available services
# then ask for ones that we did not find

# Port 80, HTTP
echo -n "Checking for website accessibility at http://$DOMAIN_NAME ..."
HTTP_PORT_OPEN="$(wget --no-hsts http://${DOMAIN_NAME} > /dev/null 2>&1)"
retsts=$?
if [ $retsts -ne 0 ] && [ $retsts -ne 8 ]; then
  echo
  echo "Web server is not up and accessible at http://${DOMAIN_NAME}"
  echo "Aborted."
  exit $retsts
fi
echo " OK, accessible."


# go find services like IMAP, SMTP, and/or submission
IMAP_SUBDOMAINNAMES="imap4 imap"
SMTPS_SUBDOMAINNAMES="smtps smtp"
POP3_SUBDOMAINNAMES="pop3 pop"
SUBM_SUBDOMAINNAMES="submissions mail submission"

# Scan for available names
# scan_subdomain_names "$IMAP_SUBDOMAINNAMES"
IMAP_SUBDOMAINNAME="${RESULT:-imap}"
# scan_subdomain_names "$SMTPS_SUBDOMAINNAMES"
SMTPS_SUBDOMAINNAME="${RESULT:-smtps}"
# scan_subdomain_names "$POP3_SUBDOMAINNAMES"
POP3_SUBDOMAINNAME="${RESULT:-pop3}"
# scan_subdomain_names "$SUBM_SUBDOMAINNAMES"
SUBM_SUBDOMAINNAME="${RESULT:-submissions}"
IMAP_DOMAIN_NAME="${IMAP_SUBDOMAINNAME}.$DOMAIN_NAME"
SMTPS_DOMAIN_NAME="${SMTPS_SUBDOMAINNAME}.$DOMAIN_NAME"
POP3_DOMAIN_NAME="${SMTPS_SUBDOMAINNAME}.$DOMAIN_NAME"
SUBM_DOMAIN_NAME="${SUBM_SUBDOMAINNAME}.$DOMAIN_NAME"

# Check if IMAP DNS is set up correctly
echo -n "Checking for DNS 'imap' A record in $DOMAIN_NAME zone ..."
THIS_IMAP4="$(dig +short "$IMAP_DOMAIN_NAME" A | grep -E "^[0-9]")"
if [ -z "$THIS_IMAP4" ]; then
  echo
  echo "IMAP A Address_part of $IMAP_DOMAIN_NAME not found; aborted."
  echo
  echo "Probably need to add a $IMAP_DOMAIN_NAME 'A' resource record into your"
  echo "'${DOMAIN_NAME}' zone file."
  FOUND_IMAP=0
else
  FOUND_IMAP=1
fi
echo " $THIS_IMAP4 found."

# Check if SMTP DNS is set up correctly
echo -n "Checking for DNS 'smtp' A record in $SMTP_DOMAINNAME zone ..."
THIS_SMTP="$(dig +short "$SMTP_DOMAINNAME" A | grep -E "^[0-9]")"
if [ -z "$THIS_SMTP" ]; then
  echo
  echo "SMTP A Address_part of $SMTP_DOMAINNAME not found; aborted."
  echo
  echo "Probably need to add a '${SMTP_DOMAINNAME}' 'A' resource record into your"
  echo "'${DOMAIN_NAME}' zone file."
  FOUND_SMTP=0
else
  FOUND_SMTP=1
  echo " $THIS_SMTP found."
fi

FOUND_SUBMISSION=1  # port 465
FOUND_SUBM=1   # port 587
echo

ZONE_NAME="$DOMAIN_NAME"
ZONE_FQDN="${ZONE_NAME}."
MX_ZONE_FQDN="$SMTP_DOMAINNAME"

flex_mkdir "$INSTANCE_DB_PRIMARIES_DIRSPEC"
flex_mkdir "$HTDOCS_DIRSPEC"
flex_mkdir "${HTDOCS_DIRSPEC}/.well-known"
flex_mkdir "${HTDOCS_DIRSPEC}/.well-known/autoconfig"
flex_mkdir "${HTDOCS_DIRSPEC}/.well-known/autoconfig/mail"
flex_mkdir "${HTDOCS_DIRSPEC}/support"
flex_mkdir "${HTDOCS_DIRSPEC}/support/email"
flex_mkdir "${HTDOCS_DIRSPEC}/support/email/config"
flex_mkdir "${HTDOCS_DIRSPEC}/support/email/config/thunderbird"
flex_mkdir "${HTDOCS_DIRSPEC}/support/email/config/thunderbird/imap-thunderbird"
flex_mkdir "${HTDOCS_DIRSPEC}/support/email/config/thunderbird/imap-thunderbird/imap"

PRIMARY_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"

DOMAIN_DB_FILENAME="db.$DOMAIN_NAME"
DOMAIN_DB_FILESPEC="${INSTANCE_DB_PRIMARIES_DIRSPEC}/$DOMAIN_DB_FILENAME"

AUTOCONF_MAIL_FILENAME="config-v1.1.xml"
AUTOCONF_MAIL_WEBPATH="/.well-known/autoconfig/mail"

# /.well-known/autoconfig/mail/config-v1.1.xml
AUTOCONF_MAIL_WEBPAGE="${AUTOCONF_MAIL_WEBPATH}/$AUTOCONF_MAIL_FILENAME"
# /var/lib/www/.well-known/autoconfig/mail
AUTOCONF_MAIL_DIRSPEC="${HTDOCS_DIRSPEC}/${AUTOCONF_MAIL_WEBPATH}"
# /var/lib/www/.well-known/autoconfig/mail/config-v1.1.xml
AUTOCONF_MAIL_FILESPEC="${AUTOCONF_MAIL_DIRSPEC}/$AUTOCONF_MAIL_FILENAME"

# /var/lib/bind[/instance]/masters/db.autoconfig.$DOMAIN_NAME
AUTOCONF_DB_FILENAME="db.autoconfig.${DOMAIN_NAME}"
AUTOCONF_DB_FILESPEC="${INSTANCE_DB_PRIMARIES_DIRSPEC}/$AUTOCONF_DB_FILENAME"

AUTOCONFIG_EMAIL_PAGENAME="index.html"
AUTOCONFIG_EMAIL_PAGEPATH="/support/email/config"

AUTOCONFIG_EMAIL_TB_DOC_PAGENAME="index.html"
AUTOCONFIG_EMAIL_TB_DIRPATH="${AUTOCONFIG_EMAIL_DIRPATH}/thunderbird/imap-thunderbird/imap"
AUTOCONFIG_EMAIL_SUPPORT_FILESPEC="${HTDOCS_DIRSPEC}${AUTOCONFIG_EMAIL_TB_DIRPATH}/index.html"


# /support/email/config/index.html"
AUTOCONFIG_EMAIL_DOC_FILESPEC="${INSTANCE_VAR_LIB_WWW}/${AUTOCONFIG_EMAIL_PAGEPATH}/$AUTOCONFIG_EMAIL_PAGENAME"

#"https://egbert.net/.well-known/autoconfig/mail/config-v1.1.xml"
url_autoconfig_xml_filename="https://$DOMAIN_NAME/${AUTOCONF_MAIL_WEBPAGE}"


# URL:/.well-known/autoconfig/mail

# /var/lib/www/.well-known/autoconfig/mail
flex_mkdir "$AUTOCONF_MAIL_DIRSPEC"

# /var/lib/www/.well-known/autoconfig/mail/config-v1.1.xml
filespec="$AUTOCONF_MAIL_FILESPEC"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_HTML_AC_EOF | tee "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>

<clientConfig version="1.1">
  <emailProvider id="${DOMAIN_NAME}">
    <domain>${DOMAIN_NAME}</domain>
    <displayName>${OC_NAME} Mail</displayName>
    <displayShortName>${OC_SHORT_NAME}</displayShortName>
ZONE_HTML_AC_EOF

if [ "$FOUND_IMAP" -ge 1 ]; then
  echo "Adding IMAP to ${BUILDROOT}${CHROOT_DIR}$filespec ..."
  cat << ZONE_HTML_AC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
    <incomingServer type="imap">
      <hostname>${IMAP_DOMAIN_NAME}</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <!-- authentication>password-encrypted</authentication -->
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <incomingServer type="imap">
      <hostname>${IMAP_DOMAIN_NAME}</hostname>
      <port>143</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
ZONE_HTML_AC_EOF
fi

if [ "$FOUND_SUBMISSION" -ge 1 ]; then
  echo "Adding SUBMISSION(465) to ${BUILDROOT}${CHROOT_DIR}$filespec ..."
  cat << ZONE_HTML_AC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
    <outgoingServer type="smtp">
      <hostname>${SMTP_DOMAINNAME}</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
ZONE_HTML_AC_EOF
fi

if [ "$FOUND_SUBM" -ge 1 ]; then
  echo "Adding SUBMISSION(587) to ${BUILDROOT}${CHROOT_DIR}$filespec ..."
  cat << ZONE_HTML_AC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
    <outgoingServer type="smtp">
      <hostname>${SUBM_DOMAINNAME}</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
ZONE_HTML_AC_EOF
fi

echo "Adding Documentation to ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_HTML_AC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
    <documentation url="http://egbert.net/support/email/config/index.html">
      <descr lang="de">Allgemeine Beschreibung der Einstellungen</descr>
      <descr lang="en">Generic settings page</descr>
    </documentation>
    <documentation url="http://egbert.net/support/email/config/thunderbird/imap-thunderbird/imap/index.html">
support/email/config/thunderbird/imap-thunderbird/imap/index.html

      <descr lang="de">${THUNDERBIRD_VERSION} IMAP-Einstellungen</descr>
      <descr lang="en">${THUNDERBIRD_VERSION} IMAP settings</descr>
    </documentation>
  </emailProvider>
</clientConfig>
ZONE_HTML_AC_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo




# APPEND the $INCLUDE 'autodiscover' subdomain zone database to
# your domain zone database

filespec="$DOMAIN_DB_FILESPEC"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Appending $INCLUDE $AUTODISCOVER_DB_FILESPE ..."
echo "  into ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << DOMAIN_DB_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
;
;  Add the Autodiscover email support
\$INCLUDE "${AUTOCONF_DB_FILESPEC}"
DOMAIN_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo

# Create the zone database to be included by requested domain/zone file

flex_mkdir "$AUTOCONF_MAIL_DIRSPEC"
filespec="${INSTANCE_DB_PRIMARIES_DIRSPEC}/db.autoconfig.${DOMAIN_NAME}"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_DB_MAIN_EOF | tee "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
\$ORIGIN ${ZONE_FQDN}
;
; File: $filename
; Path: $filepath
; Title:  Auto set-up of various remote mail clients
;
;
${ZONE_FQDN}        IN  TXT "mailconf=${url_autoconfig_xml_filename}"
;
; Must use HTTPS (443) by remote mail client during SMTP autodiscovery
_autodiscover._tcp  IN  SRV 0 0 443 ${ZONE_FQDN}

;
;  Mozilla Thunderbird mail client
autoconfig      IN  CNAME   ${ZONE_FQDN}

;
;  Microsoft Outlook mail client
autodiscover        IN  CNAME   ${ZONE_FQDN}

;  Apple Mail client uses 'mail.DOMAIN.COM'
;  Microsoft Outlook mail client uses 'mail.DOMAIN.COM' as fall-back
mail            IN  CNAME   ${ZONE_FQDN}


ZONE_DB_MAIN_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo

# Mozilla Thunderbird mail client autoconfig settings

# URL:/support/email/config/thunderbird/imap-thunderbird/imap

# /var/lib/www/support/email/config/thunderbird/imap-thunderbird/imap
flex_mkdir "$AUTOCONF_MAIL_DIRSPEC"

# /var/lib/www/support/email/config/thunderbird/imap-thunderbird/imap/index.html


echo "Done."
exit

# the rest is for Microsoft Outlook 'autodiscover'
# the rest is for Microsoft Outlook 'autodiscover'
# the rest is for Microsoft Outlook 'autodiscover'
# the rest is for Microsoft Outlook 'autodiscover'
# the rest is for Microsoft Outlook 'autodiscover'

# Add 'autodiscover' subdomain to your domain

#AUTODISCOVER_DB_FILESPEC="${INSTANCE_DB_PRIMARIES_DIRSPEC}/db.autodiscover.$DOMAIN_NAME"
filespec="$AUTODISCOVER_DB_FILESPEC"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << AUTODISCOVER_DB_EOF | tee "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
;
;  Autodiscover email support
\$ORIGIN $DOMAIN_NAME
autodiscover    IN  CNAME   $DOMAIN_NAME
AUTODISCOVER_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo
# APPEND the 'autodiscover' subdomain zone database to your domain zone database
filespec="$DOMAIN_DB_FILESPEC"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << AUTODISCOVER_DB_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
;
;  Add the Autodiscover email support
\$INCLUDE \"${AUTODISCOVER_DB_FILESPEC}\"
AUTODISCOVER_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo


echo "Done."

