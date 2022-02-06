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
#  * https://bimigroup.org/how-bimi-avoids-unauthorized-or-fraudulent-use-of-logos/
#  * https://bimigroup.org/bimi-generator/
#  * https://mxtoolbox.com/SuperTool.aspx?action=a%3aegbert.net&run=toolpage
#  * https://bimigroup.org/vmcs-arent-a-golden-ticket-for-bimi-logo-display/
#  * 

echo "Set up BIMI icon for other people's remote webmail client to extract"
echo "and denoate each of your e-mail to them."
echo


# Needs a pretty simple SVG file (no radialGradient, no 
#    style, no IRI, and version="1.2").
#

#  dig +short default._bimi.egbert.net TXT
#
# look for a 'v=BIMI1' tag
#
# extract value to 'l=' containing URL to SVG image
#
# wget $extracted_bimi_image
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
# Use https://bimigroup.org/bimi-generator/ to check for SVG flaws
# 
