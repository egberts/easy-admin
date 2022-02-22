#!/bin/bash
# File: 592-dns-bind-autodiscover.sh
# Title:  Set up autodiscovering by remote Microsoft-only email client 
#
# Description:
#
#   Uses both SRV and HTTP (noticed it is not HTTPS?)
#
# References:
#  * https://www.icdsoft.com/en/kb/view/1698_automatic_e_mail_configuration_autodiscover_autoconfig


source ./maintainer-dns-isc.sh


if [ "${BUILDROOT:0:1}" == '/' ]; then
  # absolute (rootfs?)
  echo "Absolute build"
else
  mkdir -p build
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind-autodiscovery-smtp-imap${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
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


DOMAIN_NAME="egbert.net"
OC_NAME="Egbert Networks"
OC_SHORTNAME="EgNet"
# THUNDERBIRD_VERSION="$(thunderbird --version)"
THUNDERBIRD_VERSION="78.41.01"

FOUND_IMAP=1
IMAP_DOMAIN_NAME="imap.$DOMAIN_NAME"
FOUND_SMTP=1
SMTP_DOMAIN_NAME="smtp.$DOMAIN_NAME"

ZONE_NAME="egbert.net"
ZONE_FQDN="${ZONE_NAME}."
MX_ZONE_FQDN="mx1.${ZONE_FQDN}"

VAR_LIB_WWW_DIRSPEC="${VAR_LIB_DIRSPEC}/www"
flex_mkdir "$INSTANCE_DB_PRIMARIES_DIRSPEC"
flex_mkdir "$VAR_LIB_WWW_DIRSPEC"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/.well-known"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/.well-known/autoconfig"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/.well-known/autoconfig/mail"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/support"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/support/email"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/support/email/config"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/support/email/config/thunderbird"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/support/email/config/thunderbird/imap-thunderbird"
flex_mkdir "${VAR_LIB_WWW_DIRSPEC}/support/email/config/thunderbird/imap-thunderbird/imap"
exit

filespec="/var/lib/bind/public/master/db.egbert.net_addons"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_DB_MAIN_EOF | tee "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
\$ORIGIN ${ZONE_FQDN}
;
; 
${ZONE_FQDN}		IN    TXT     "mailconf=https://egbert.net/.well-known/autoconfig/mail/config-v1.1.xml"

www			IN	CNAME	${ZONE_FQDN}
autodiscover		IN	CNAME	${ZONE_FQDN}
autoconfig		IN	CNAME	${ZONE_FQDN}
smtp       		IN	CNAME	${ZONE_FQDN}
imap			IN	CNAME	${ZONE_FQDN}
portal			IN	CNAME	${ZONE_FQDN}

; _tcp.egbert.net.
\$ORIGIN _tcp.${ZONE_FQDN}
_autodiscover	SRV	1 1 443 mx1.egbert.net

; _tcp.mx1.egbert.net.
\$ORIGIN _tcp.${MX_ZONE_FQDN}
; RFC 6186 SRV records for e-mail services
_imap		SRV	0 0 0 .
_imaps		SRV	1 1 993 ${MX_ZONE_FQDN}
_pop3		SRV	0 0 0 .
_pop3s		SRV	0 0 0 .
_submission	SRV	1 1 587 ${MX_ZONE_FQDN}
_submissions	SRV	1 1 465 ${MX_ZONE_FQDN}

ZONE_DB_MAIN_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo

# URL:/.well-known/autoconfig/mail
#     /support/email/config/thunderbird/imap-thunderbird/imap



AUTOCONFIG_EMAIL_SUPPORT_FILESPEC="${VAR_LIB_WWW_DIRSPEC}/support/email/config/thunderbird/imap-thunderbird/imap"

AUTOCONFIG_TB_DOC_FILESPEC="${INSTANCE_VAR_LIB_WWW}/support/email/config/index.html"

AUTOCONF_MAIL_FILESPEC=".well-known/autoconfig/mail/config-v1.1.xml"
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

if [ "$HAVE_IMAP" -ge 1 ]; then
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

if [ "$HAVE_SUBMISSION" -ge 1 ]; then
  cat << ZONE_HTML_AC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
    <outgoingServer type="smtp">
      <hostname>${SMTP_DOMAIN_NAME}</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
ZONE_HTML_AC_EOF
fi

if [ "$HAVE_SMTP" -ge 1 ]; then
  cat << ZONE_HTML_AC_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
    <outgoingServer type="smtp">
      <hostname>${SMTP_DOMAIN_NAME}</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
ZONE_HTML_AC_EOF
fi

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

# Add 'autodiscover' subdomain to your domain

AUTODISCOVER_DB_FILESPEC="/var/lib/bind[/instance]/master/db.autodiscover.$DOMAIN_NAME"
filespec="$AUTODISCOVER_DB_FILESPEC"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << AUTODISCOVER_DB_EOF | tee "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
;
;  Autodiscover email support
\$ORIGIN $DOMAIN_NAME
autodiscover	IN	CNAME	$DOMAIN_NAME
AUTODISCOVER_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo

# APPEND the 'autodiscover' subdomain zone database to your domain zone database
DOMAIN_DB_FILESPEC="/var/lib/bind[/instance]/master/db.$DOMAIN_NAME"
filespec="$DOMAIN_DB_FILESPEC"
filename="$(basename $filespec)"
filepath="$(dirname $filespec)"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << AUTODISCOVER_DB_EOF | tee "${BUILDROOT}${CHROOT_DIR}${filespec}" > /dev/null
;
;  Add the Autodiscover email support
\$INCLUDE \"${AUTODISCOVER_DB_FILESPEC}\"
autodiscover	IN	CNAME	$DOMAIN_NAME
AUTODISCOVER_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod "0640"             "$filespec"
echo


echo "Done."

