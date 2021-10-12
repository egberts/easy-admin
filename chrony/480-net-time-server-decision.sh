#!/bin/bash
# File: 480-net-time-server-selecting.sh
# Title: Selecting the right time server
# Description:
#   Help end-user decide what to use for time-syncing effort.
#
# Reads:
#   /dev/ptp[0-9]
# Changes: nothing
# Writes: nothing
#
# Prerequisites:
#   gawk (awk)
#   coreutils (ls)
#
# Notes:
# NTP timeline history
#
# Year  Cite.     Description
# 2021            NTPSec
# 2021  20210625  MS-SNTP https://winprotocoldoc.blob.core.windows.net/productionwindowsarchives/MS-SNTP/[MS-SNTP].pdf
# 2020  RFC 8573  NTPv4.3
# 2017  802.1as   PTP via NICs,  aka gPTP
# 2017  RFC 5905  NTPv4.2, Autokey v2, public key x509v3 PEM/PKCS#8
# 2015  RFC 5905  NTPv4.1
# 2010  RFC 5905  NTPv4
# 1996  RFC 2030  SNTPv4  (also RFC 1769)
# 1995  internal  MS-SNTP (incorp. Kerberos ticket into NTP-RefID field)
# 1993  RFC 1361  SNTP
# 1992  RFC 1305  NTPv3  autokey v1
# 1989  RFC 1119  NTPv2
# 1988  RFC 1059  NTPv1
# 1985  RFC 958   NTP (aka NTPv0)
# 1983  RFC 868   IP Time Protocol
# 1981  RFC 792   ICMP Timestamping
#
#
# Available Time-Syncing Protocols by popular OSes are (newest-to-oldest):
#               |Transport|---Server Support---  ---Client Support---
#  NTP version  | Payload  UNIX  macOS  Windows  UNIX  macOS  Windows
#  --------------\ ------  ----  -----  -------  ----  -----  -------
#  NTPv4.3 NTS?     udp      *     *       *        *     *       *
#  MS-SNTP 20210201 udp      -     -      all       -     -      all
#  NTPv4.2 NTPSec?  udp     all   all      *       all   all      *
#  NTPv4.1 NTPSec?  udp     all   all      -       all   all      *
#  NTPv4            udp     all   all      -       all   all      -
#  SNTPv4           udp     all   all     all      all   all     all
#  MS-SNTP          udp      -     -      all      all   all     all
#  PTP              802.3   some   *       -       most   -      -
#                   or udp
#    NetSync        802.3   some   *       -       some   -      -
#                   or udp
# Legend: (*) - installable as a non-distro package; (-) - not available
#
# HMAC symmetric-key evolution in NTP
#   Protocols are:
#
# Evolution of HMAC/Password Cipher/NTP Extension/PKCS8 certificate signing
# =================================
#            Online  Offline
#   NTP       HMAC   Password/NTP-extension/
# version    digest  PKCS8 certificate signing
# --------   ------  ------------------
# NTPv4.3       MD5  DES3/ (Autokey v2 gone)/ PKCS8+SHA512
# MS-SNTP-2021  MD5  DES3/ MS-ADC/MS-KRB5 ticket RefID scheme/ PKCS8+SHA512
# NTPv4.2       MD5  DES3/ Autokey v2/ PKCS8 certificates (SHA512)
# NTPv4.1       MD5  DES3/ Autokey v2/ PKCS8 certificates
# SNTPv4        MD5  DES3/ Autokey v2
# NTPv4         MD5  DES3/ Autokey v2
# MS-SNTP       MD5  DES/ Microsoft-ADC, MS-KRB5 ticket RefID scheme
# SNTP          MD5  DES/ password/ Autokey v1 (Public Key)
# NTP v3        MD5  DES/ password/ symmetric key
# * all DES3 are DES3-EDE3-CBC.
#
# Now you know the intricacity of NTP 'encryption' network operation:
# It is really about the message digest, hashed variety called HMAC.
#
# Certificate signing digest (ntp-keygen-4.2 -c <opt>):
#   MD4 RSA-MD4 md4WithRSAEncryption
#   MD5 RSA-MD5 md5WithRSAEncryption ssl3-md5
#   ripemd RIPEMD160 ripemd160WithRSA rmd160 RSA-RIPEMD160
#   SHA1 RSA-SHA1 RSA-SHA1-2
#   SHA224 RSA-SSHA224 sha224WithRSAEncryption sha1WithRSAEncryption
#     SHA3-224 ssl3-sha1
#   RSA-SHA3-224 id-rsassa-pkcs1-v1_5-with-sha3-224
#   SHA256 sha256WithRSAEncryption RSA-SHA256
#   SHA3-256 RSA-SHA3-256 id-rsassa-pkcs1-v1_5-with-sha3-256
#
# Certificate signature digest Key (ntp-keygen-4.2 -S <digest>):
#     RSA, DSA
#   No -S<digest> parameter conflict with  any -C<cipher>
#
# Cipher option are only used in password-protecting the certificate
# signing PEM files.  Cipher name choices are partially validated
# by EVP_cipher_getnames() so you won't know if it works unless you
# actually check the *sign_<hostname> file for its incomplete headers and data.
#
# At compiled-in OpenSSL v1.1.1c, ntp-keygen can use the following options,
# cipher options (ntp-keygen-4.2 -C <cipher>):
# Only used to encrypt and protect passwords applied by ntp-keygen:
#   decrypt password after reading from its file (ntp-keygen -C<cipher> -p)
#   encrypt password before write to its file (ntp-keygen -C<cipher> -q)
#
#   AES-128-CBC AES-128-CFB AES-128-ECB AES-128-OFB
#   AES-192-CBC AES-192-CFB AES-192-ECB AES-192-OFB
#   AES-256-CBC AES-256-CFB AES-256-ECB AES-256-OFB
#   aes128 aes192 aes256
#   ARIA-128-CBC ARIA-128-CFB ARIA-128-ECB ARIA-128-OFB
#   ARIA-192-CBC ARIA-192-CFB ARIA-192-ECB ARIA-192-OFB
#   ARIA-256-CBC ARIA-256-CFB ARIA-256-ECB ARIA-256-OFB
#   aria128 aria192 aria256
#   bf BF-CBC blowfish
#   CAMELLIA-128-CBC CAMELLIA-128-CFB CAMELLIA-128-ECB CAMELLIA-128-OFB
#   CAMELLIA-192-CBC CAMELLIA-192-CFB CAMELLIA-192-ECB CAMELLIA-192-OFB
#   CAMELLIA-256-CBC CAMELLIA-256-CFB CAMELLIA-256-ECB CAMELLIA-256-OFB
#   camellia128 camellia192 camellia256
#   cast cast-cbc CAST5-CBC
#   des DES-CBC DES-CFB DES-CFB1 DES-CFB8 DES-ECB DES-EDE des-ede-ecb
#   DES-EDE3-CBC DES-EDE3-CFB DES-EDE3-CFB1 DES-EDE3-CFB8 DES-OFB des3
#   rc2 rc2-128 rc2-40 RC2-40-CBC rc2-64 RC2-64-CBC RC2-CBC
#   seed SEED-CBC SEED-CFB SEED-ECB SEED-OFB
#   sm4 SM4-CBC SM4-CFB SM4-ECB SM4-OFB
#
# A lot of valid OpenSSL ciphers (as determined by EVP_ciphers_getnames()
# but may not allow ntp-keygen to produce a useable encrypted password
# file (bug) but leave you with just the top of the header line
# (no data, no trailer).  Bad list is kept to a single-line
#   Bad list:  id-aes128-CCM AES-128-CFB1 AES-128-CFB8 AES-128-CTR id-aes128-GCM AES-128-OCB AES-128-XTS id-aes192-CCM AES-192-CFB1 AES-192-CFB8 AES-192-CTR id-aes192-GCM AES-192-OCB id-aes256-CCM AES-256-CFB1 AES-256-CFB8 AES-256-CTR id-aes256-GCM AES-256-OCB AES-256-XTS aes128-wrap aes192-wrap aes256-wrap ARIA-128-CCM ARIA-128-CFB1 ARIA-128-CFB8 ARIA-128-CTR ARIA-128-GCM ARIA-192-CCM ARIA-192-CFB1 ARIA-192-CFB8 ARIA-192-CTR ARIA-192-GCM ARIA-256-CCM ARIA-256-CFB1 ARIA-256-CFB8 ARIA-256-CTR ARIA-256-GCM BF-CFB BF-ECB BF-OFB CAMELLIA-128-CFB1 CAMELLIA-128-CFB8 CAMELLIA-128-CTR CAMELLIA-192-CFB1 CAMELLIA-192-CFB8 CAMELLIA-192-CTR CAMELLIA-256-CFB1 CAMELLIA-256-CFB8 CAMELLIA-256-CTR CAST5-CFB CAST5-ECB CAST5-OFB ChaCha20 ChaCha20-Poly1305 DES-EDE-CBC DES-EDE-CFB DES-EDE-OFB DES-EDE3 des-ede3-ecb DES-EDE3-OFB des3-wrap desx DESX-CBC id-aes128-CCM id-aes128-GCM id-aes128-wrap id-aes128-wrap-pad id-aes192-CCM id-aes192-GCM id-aes192-wrap id-aes192-wrap-pad id-aes256-CCM id-aes256-GCM id-aes256-wrap id-aes256-wrap-pad id-smime-alg-CMS3DESwrap RC2-CFB RC2-ECB RC2-OFB RC4 RC4-40 RC4-HMAC-MD5 SM4-CTR
#

# Determine what we have in this machine
# Determine if we have any PTP-related devices

# shellcheck disable=SC2012
HAVE_PTP_DEVICE="$(ls -1 /dev/ptp* 2>/dev/null | wc -l )"


# TODO: Need to execute ethtool on every 'ip link list' to count each device's
#       timestamping capability

# Precision-time?
NEED_PROTOCOL_PTP=n
if [ "$HAVE_PTP_DEVICE" -ne 1 ]; then
  echo ""
  echo "Decision-Making Tree for Selecting Time Daemon"
  echo "-----------------------------------------------"
  echo ""
  echo "There are a few time synchronization approaches that you can do:"
  echo "  * Ultra-High Precision Time Syncing"
  echo "  * General Precision Time Syncing"
  echo ""
  echo "Ultra-high precision is useful for partical physic, "
  echo "high-speed financial trading, and hyper-implosion computing."
  read -rp "Need precision time syncing to sub-micro second range? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" = 'y' ]; then
    NEED_PROTOCOL_PTP=y
  else
    echo ""
    echo "Are you doing any of the following:"
    echo " * Automobile CAN network"
    echo " * IEEE 1588"
    echo " * Enterprise networking"
    echo " * Telecom (G.8265.1, G.8275.1, and G.8275.2)"
    read -rp "Doing any esoteric time-syncing? (N/y):" -eiN
    REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
    if [ "$REPLY" = 'y' ]; then
      echo "...selected esoteric timesyncing."
      NEED_PROTOCOL_PTP=y
    else
      echo "...selected general timesyncing."
    fi
  fi
fi

# PTP local use (as opposed to PTP network-based
# might be a local atomic clock for local consumption
echo ""
echo "This is not a network-related PTP question, but for local use only."
if [[ "$HAVE_PTP_DEVICE" -ge 1 ]]; then
  HAVE_PROTOCOL_PTP=y
  echo "Detected a Precise Time Protocol (/dev/ptp0) device..."
  read -rp "Use that ultra-high-precision clock on this machine you have? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" = 'y' ]; then
    echo "...using PTP protocol."
    NEED_PROTOCOL_PTP=y
    NEED_LOCAL_PTP=y
  else
    # No need to flip NEED_PROTOCOL_PTP to 'n', this is a float-answer state
    NEED_LOCAL_PTP=n
  fi
else
  # No onboard "atomic" clock
  HAVE_PROTOCOL_PTP=n
  read -rp "Need a ultra-high-precision clock on this machine you have? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" = 'y' ]; then
    NEED_LOCAL_PTP=y
    NEED_PROTOCOL_PTP=y
  else
    NEED_LOCAL_PTP=n
    # No need to flip NEED_PROTOCOL_PTP to 'n', this is a float-answer state
  fi
fi


NEED_NETWORK_MODE=""
# Consuming-network-mode
echo ""
read -rp "Receiving a time update is what this machine needs? (Y/n): " -eiY
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" = 'y' ]; then
  echo "...NTP client mode."
  NEED_NETWORK_MODE='client'
  # Might be PTP, might be NTP
fi

# Producing-network-mode
echo ""
read -rp "Relaying a time update to other machines needed as well? (N/y): " -eiN
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" = 'y' ]; then
  # Might be PTP, might be NTP
  echo "...NTP server mode."
  echo ""
  NEED_NETWORK_MODE='server'
  read -rp "Have any remote macOS to serve times to? (Y/n): " -eiY
  echo ""
  HAVE_REMOTE_MACOS="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  read -rp "Have any remote Windows desktop/workstations to serve times to? (Y/n): " -eiY
  echo ""
  HAVE_REMOTE_WINDOWS="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  # We don't ask about Linux/BSD, for they all support MD5 message digest
  read -rp "Have any Windows Active Directory Controllers on the net? (Y/n): " -eiY
  HAVE_REMOTE_WINDOWS_ADC="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  # Yeah, these Windows ADCs send out SNTPv4+ with their own
  # authenticators/encryptions selections inside the NTP payload
  # extension fields.  Totally not compatible with NTPv4.3.
  # Makes Linux Samba server hell in selecting between NTPv4.3 and SNTPv4+
  if [ "$HAVE_REMOTE_WINDOWS_ADC" = "y" ]; then
    echo ""
    echo "Is that Windows ADC server on your network configured to be using:"
    echo " * WinTime32 Authentication"
    read -rp "Remote Windows ADC is using WinTime32 NTP authentication: (N/y): " -eiN
    HAVE_NTP_EXTENSION_MS_ADC="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
    if [ "$HAVE_NTP_EXTENSION_MS_ADC" = 'y' ]; then
      echo "And for UNIX NTP servers on your network configured to be using "
      echo "NTP authentication (key ID, by any means)?"
      read -rp "UNIX NTP server(s) is using NTP authentication: (N/y): " -eiN
      HAVE_NTP_EXTENSION_AUTH="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
    fi
  fi
fi

echo ""
echo "it is really a MAC digest, specifically a hashed MAC (or HMAC)."
echo "All hashes are derived from private key or PKCS8 signed PEM certificates."
echo "There are no 'encryption' nor 'cipher' going on over NTP network protocol."
read -rp "Press any key to continue."




echo ""
echo "Got public network?  Hackers trying to do man-in-the-middle on NTP?"
echo "Feel like nobody outside of the group deserves these precious NTP packets?"
echo "It's just open-source live-streaming data, like your kitchen clock."
read -rp "Need to secure your time servings over your network? (N/y): " -eiN
NEED_HMAC="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"


# ANALYSIS SECTION
if [ "$NEED_HMAC" = 'y' ]; then
  if [ "$HAVE_NTP_EXTENSION_AUTH" = 'y' ]; then
    if [ "$HAVE_NTP_EXTENSION_MS_ADC" = 'y' ]; then
      echo ""
      echo "CAVEAT: "
      echo "* Mixing MS-ADC and ( NTPv4 Autokey v2 or NTPSec ) is "
      echo "  a bad network engineering decision. Choose one."
    fi
  fi
fi

# RECOMMENDATION SETION
echo ""
echo "RECOMMENDATIONS:"
if [ "$NEED_HMAC" = 'y' ]; then
  NEED_HMAC=1
  if [ "$HAVE_REMOTE_MACOS" = 'y' ]; then
    echo ""
    echo "* To get encrypted part of the NTP protocol for those remote macOS "
    echo "  would requires the following packages installed:"
    echo "    brew ntp"
    echo "    brew openntpd"
    read -rp "Press any key to continue" -n1
  fi
  if [ "$HAVE_REMOTE_WINDOWS" = 'y' ]; then
    echo ""
    echo "CAVEAT: "
    echo "* Windows ADC easily can configure themselves out of NTP network."
    echo "  Windows SNTP leverages their ADC (Kerberos5) into the"
    echo "  vendor-specific part of NTP protocol extension."
    echo "  Also heard something-something about their Kerberos "
    echo "  (I meant, Microsoft Active Domain Controller session) ticket "
    echo "  being inserted into the RefID field of their NTP packets,"
    echo "  or something."
    read -rp "Press any key to continue" -n1
  fi
  if [ "$HAVE_REMOTE_WINDOWS_ADC" = 'y' ] && [ "$HAVE_REMOTE_WINDOWS" ]; then
    echo ""
    echo "CAVEAT: "
    echo "* Might want to ensure that those Windows ADC servers are not"
    echo "  serving out NTP packets in an password-protected"
    echo "  signed certificate manner.  Also do not let Windows ADC servers"
    echo "  do their own MS-ADC authentication (part of their MS-SNTP) as "
    echo "  it will not co-exist well with general NTPv4+ protocol."
    echo "  It is possible to overlap two separate NTP feed stream onto "
    echo "  the same subnet:"
    echo "    - MS-SNTP"
    echo "    - NTPv4+"
    echo "  But the configuration hassle of blocking each other is "
    echo "  simply not worth the admin effort."
    read -rp "Press any key to continue" -n1
  fi
else
  NEED_HMAC=0
  # Just about all OSes can be NTP client
  echo "... All NTP time data are openly sent on your network. That's ok, too!"
fi

if [ "$NEED_PROTOCOL_PTP" = 'y' ]; then
  echo "You need PTP protocol;"
  if [ "$HAVE_PROTOCOL_PTP" = 'n' ]; then
    echo "You do not have PTP protocol support;"
    echo "Linux Kernel Config settings:"
    echo "  CONFIG_PTP_1588_CLOCK=y"
    if [ -n "$NEED_NETWORK_MODE" ]; then
      echo "  CONFIG_NETWORK_PHY_TIMESTAMPING=y"
      echo "  CONFIG_NETWORK_CLASSIFY=y"
    fi
    echo ""
    echo "Some hardware manufacturers for PTP protocol:"
    if [ -n "$NEED_NETWORK_MODE" ]; then
      echo "  Telecom:"
      echo "    Mobatime (https://www.mobatime.com)"
      echo "  Ethernet Network Interface Cards (NIC):"
      echo "    Cavium Networks (https://cavium.com/)"
      echo "    Intel 82574 82580, 82599 (https://e1000.sourceforge.net)"
      echo "    Intel i210 (https://www.intel.com)"
      echo "    LiveWire NIC 802.1avb  (https://www.audioscience.com)"
      # STMICRO, SSMC, STC
    fi
    if [ -n "$NEED_LOCAL_PTP" ]; then
      echo "  GPS receivers:"
      echo "    MasterCLock GMR5000 (https://www.masterclock.com"
      echo "    Microsemi (https://www.microsemi.com"
      echo "    LANTIME M-1000 (https://www.meinbergglobal.com"
      echo "    OTMC-100, OMICRON Lab (https://www.omicron-lab/ptp)"
    fi
  else
    echo "You already have PTP protocol support;"
  fi
else
  echo "You don't need support for PTP protocol."
fi


echo ""
echo "Analysis:"
echo "  There are no further recommendation for your selections."
echo "Done."

