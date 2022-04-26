#!/bin/bash
# File: 599-dns-root-server-standalone.sh
# Title: Create standalone "13" Root Servers for whitelab
# Description:
#   This script will create a Root Server for local use only.
#
#   This script will do the following:
#   - generate ZSK and KSK public key-pairs for '.' zone
#   - generate root zone file by cloning f.root-server.net via AXFR
#   - place the files into their named subdirectories
#   - create partial named.conf configuration files for your own inclusion
#   - Set correct file ownership/permissions
#   - If SELinux-enabled, set the correct SELinux context for all files.
#
# Env vars:
#   rundir
#   sysconfdir
#   NAMED_HOME_DIRSPEC (defaults to distro-os-selected named/bind $HOME)
#   DATA_DIRSPEC
#   ZONE_DB_DIRSPEC
#   KEYS_DIRSPEC
#
# References:
#
# 
# * https://www.freeipa.org/page/Howto/DNSSEC#DNSSEC_in_isolated_networks
# * https://www.freeipa.org/page/Howto/DNS_in_isolated_networks
# * https://www.cymru.com/Documents/secure-bind-template.html
#

echo "Create a standalone root server for a closed network whitelab usage"
echo

source ./maintainer-dns-isc.sh

# NAMED_CONF_FILESPEC="/etc/named/standalone-named.conf"

DOMAIN_TTL=86400

FILE_SETTING_PERFORM=true
if [ "${BUILDROOT:0:1}" == "/" ]; then
  echo "This will write over your Bind9 settings."
  echo "Or you could define the following and rerun for a local daemon copy:"
  echo
  echo "    rundir=. sysconfdir=. NAMED_HOME_DIRSPEC=. \\"
  echo "        DATA_DIRSPEC=. ZONE_DB_DIRSPEC=.  \\"
  echo "        KEYS_DIRSPEC=.  \\"
  echo "        ./dns-root-server-standalone.sh"
  echo "    named -4 -d65535 -g -c ${NAMED_CONF_FILESPEC} -T mkeytimers=1/6/180"
  echo
  echo " 'mkeytimers' for a 3-minute DNSSEC key rollover interval at root server-level"
  echo
  read -rp "Enter in 'yes' to contiinue: "
  if [ "$REPLY" != "yes" ]; then
    echo "Aborted."
    exit 2
  fi
  if [ "$USER" != "root" ]; then
    echo "Must be root to run $0"
    exit 9
  fi
else
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-dns-root-server-standalone${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  rm -f "$FILE_SETTINGS_FILESPEC"

  mkdir -p build
  flex_ckdir "/etc"
  flex_ckdir "$sysconfdir"
  flex_ckdir "$VAR_DIRSPEC"
  flex_ckdir "$VAR_LIB_DIRSPEC"
  flex_ckdir "$VAR_LIB_NAMED_DIRSPEC"
  flex_ckdir "$extended_sysconfdir"
  flex_ckdir "${VAR_CACHE_DIRSPEC}"
  flex_ckdir "${NAMED_HOME_DIRSPEC}"  # TBD not sure we want this for all 3 tri-states
fi
flex_ckdir "$INSTANCE_CONF_KEYS_DIRSPEC"
flex_ckdir "$DEFAULT_DYNAMIC_DIRSPEC"
flex_ckdir "$DEFAULT_KEYS_DB_DIRSPEC"
flex_ckdir "$DEFAULT_DATA_DIRSPEC"
# flex_mkdir "$DEFAULT_ZONE_DB_DIRSPEC"

PRIVATE_TLD="my-root"  # could be 'home', 'private', 'lan', 'internal'
NS1_IP="10.10.0.1"  # could be whatever netdev IP that is private or NOT NAT'd
SN="$(date +%Y%m%d%H)"
T1="1800"
T2="900"
T3="604800"
T4="86400"
NS1_NAME="ns1.a.myroot-servers.${PRIVATE_TLD}."
CONTACT="hostmaster.${PRIVATE_TLD}."

# DO NOT WORK on $localstatedir for its file perms/owners

# /etc/bind[/instance]/keys directory
flex_chmod 0750 "$INSTANCE_CONF_KEYS_DIRSPEC"
flex_chown "${USER_NAME}:$GROUP_NAME" "$INSTANCE_CONF_KEYS_DIRSPEC"
flex_chcon named_cache_t "$INSTANCE_CONF_KEYS_DIRSPEC"

# In ALGORITHMS, the first entry is the input default
echo "List of supported DNSSEC algorithms:"
# ALGORITHMS=("ecdsaP256Sha256" "ecdsaP384Sha384" "ed25519" "rsaSha256" "rsaSha512")
ALGORITHMS=("ed25519" "ecdsaP256Sha256" "ecdsaP384Sha384" "rsaSha256" "rsaSha512")
idx=1
for alg in ${ALGORITHMS[*]}; do
  echo "  $idx: $alg"
  ((idx++))
done
read -rp "Enter in desired algorithm index: " -ei1
ALGORITHM="${ALGORITHMS[$REPLY]}"
if [ -z "$ALGORITHM" ]; then
  echo "No algorithm selected; aborted."
  exit 3
fi

if [ "${ALGORITHM:0:3}" == "rsa" ]; then
  read -rp "Number of RSA bits: " -i4096
  DNSSEC_KEYGEN_OPTS="-b $RSA_BITS"
  echo
fi


DOMAIN_ROOT_PART="."  # must be the same as 1st field of SOA line in zone file
ROOT_ZONE_FILENAME="db.root.standalone"
ROOT_ZONE_DIRSPEC="${DEFAULT_ZONE_DB_DIRSPEC}"
ROOT_ZONE_FILESPEC="${ROOT_ZONE_DIRSPEC}/$ROOT_ZONE_FILENAME"

TMP_ROOT_ZONE_FILESPEC="${ROOT_ZONE_FILESPEC}.tmp"

if [ ! -d "${BUILDROOT}${CHROOT_DIR}$NAMED_HOME_DIRSPEC" ]; then
  echo "named $HOMED_HOME_DIRSPEC directory '${BUILDROOT}${CHROOT_DIR}$NAMED_HOME_DIRSPEC' does not exist; aborted."
  exit 3
fi

if [ ! -d "${BUILDROOT}${CHROOT_DIR}$ZONE_DB_DIRSPEC" ]; then
  echo "Zone database directory '${BUILDROOT}${CHROOT_DIR}$ZONE_DB_DIRSPEC' does not exist; aborted."
  exit 3
fi

DEFAULT_KEYS_DB_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$DEFAULT_KEYS_DB_DIRSPEC"
if [ ! -d "$DEFAULT_KEYS_DB_FULLSPEC" ]; then
  echo "Key directory '$DEFAULT_KEYS_DB_FULLSPEC' does not exist; aborted."
  exit 3
fi


echo "Creating Zone-Signing-Key (ZSK) files in $PWD PWD..."
ZSK_ID="$(dnssec-keygen -T DNSKEY \
    -K "$DEFAULT_KEYS_DB_FULLSPEC" \
    -n ZONE \
    -p 3 \
    -a "${ALGORITHM}" \
    $DNSSEC_KEYGEN_OPTS \
    -L 86400 \
    -v 1 \
    "$DOMAIN_ROOT_PART" )"
# created K.+000+99999.key     # contains DNSSKEY RR
# created K.+000+99999.private
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error creating Zone-Signed-Key (ZSK) files; aborted"
  exit 3
fi
ZSK_KEY_FILESPEC="${DEFAULT_KEYS_DB_DIRSPEC}/${ZSK_ID}.key"
ZSK_PRIVATE_FILESPEC="${DEFAULT_KEYS_DB_DIRSPEC}/${ZSK_ID}.private"
flex_chmod 0644 "$ZSK_KEY_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$ZSK_KEY_FILESPEC"
flex_chcon named_cache_t "$ZSK_KEY_FILESPEC"

flex_chmod 0600 "$ZSK_PRIVATE_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$ZSK_PRIVATE_FILESPEC"
flex_chcon named_cache_t "$ZSK_PRIVATE_FILESPEC"

echo "Creating Key-Signing-Key (KSK) files ..."
KSK_ID="$(dnssec-keygen -T DNSKEY \
    -K "$DEFAULT_KEYS_DB_FULLSPEC" \
    -f KSK \
    -n ZONE \
    -p 3 \
    -a "${ALGORITHM}" \
    $DNSSEC_KEYGEN_OPTS \
    -L 86400 \
    -v 1 \
    "$DOMAIN_ROOT_PART" )"
# created K.+000+99999.key     # contains DNSSKEY RR
# created K.+000+99999.private
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error creating Key-Signed-Key (KSK) files; aborted"
  exit 3
fi
KSK_KEY_FILESPEC="${DEFAULT_KEYS_DB_DIRSPEC}/${KSK_ID}.key"
KSK_PRIVATE_FILESPEC="${DEFAULT_KEYS_DB_DIRSPEC}/${KSK_ID}.private"
flex_chmod 0644 "$KSK_KEY_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$KSK_KEY_FILESPEC"
flex_chcon named_cache_t "$KSK_KEY_FILESPEC"

flex_chmod 0600 "$KSK_PRIVATE_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$KSK_PRIVATE_FILESPEC"
flex_chcon named_cache_t "$KSK_PRIVATE_FILESPEC"
echo


# Make sure that all other NS records for the root zone "." have been removed
#echo "Removing all '$DOMAIN_ROOT_PART' domain part from temp root zone file ..."

TMP_ROOT_ZONE_FULLSPEC="${BUILDROOT}${CHROOT_DIR}${TMP_ROOT_ZONE_FILESPEC}"

#sed -i "/^\.\s/d" "$TMP_ROOT_ZONE_FULLSPEC"

# Create SOA, NS, and A glue records
ROOT_ZONE_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$ROOT_ZONE_FILESPEC"
echo "Creating SOA, NS, annd A glue record in ${ROOT_ZONE_FULLSPEC} ..."
cat << ROOT_ZONE_EOF > "${ROOT_ZONE_FULLSPEC}"
; File: $ROOT_ZONE_FILENAME
; Path: $ROOT_ZONE_DIRSPEC
; Date: $(date +"%Y%M%D %H%M")"
; Title: Root Cache (hint) database file
.       ${DOMAIN_TTL}   IN  SOA mname.invalid. nm.invalid. (
                        $SN ; Serial Number
                        $T1 ; Refresh
                        $T2 ; Retry
                        $T3 ; Expire
                        $T4 ; Negative Cache TTL
                        )
.                   NS  ns.root.
ns.root.            A   10.10.0.1

invalid.            NS  ns.invalid.
ns.invalid.         A   10.10.0.1

example.            NS  ns.example.
ns.example.         A   10.10.0.1

.                   TXT "This is the example root zone."

ROOT_ZONE_EOF

# Append the big full zone transfer file after our SOA, NS, A header
# shellcheck disable=SC2129
#cat "$TMP_ROOT_ZONE_FULLSPEC" >> "$ROOT_ZONE_FULLSPEC"

# Append the DNSKEYs at the end of the zone file
ZSK_KEY_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC"
cat "$ZSK_KEY_FULLSPEC" >> "$ROOT_ZONE_FULLSPEC"

KSK_KEY_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC"
cat "$KSK_KEY_FULLSPEC" >> "$ROOT_ZONE_FULLSPEC"

echo "$ROOT_ZONE_FULLSPEC created."
flex_chmod 0644 "$ROOT_ZONE_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$ROOT_ZONE_FILESPEC"
flex_chcon named_zone_t "$ROOT_ZONE_FILESPEC"
rm -f "$TMP_ROOT_ZONE_FULLSPEC"
echo

# dnssec-keygen cannot write key files outside of this script's $PWD directory
# there is no CLI option to redirect these key files
# must do a change directory to keys DB directory then run dnssec-keygen
####cd "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_NAMED_DIRSPEC" || exit 9

DSSET_FILENAME="dsset-."
DSSET_DIRSPEC="$DEFAULT_KEYS_DB_DIRSPEC"
DSSET_FILESPEC="${DSSET_DIRSPEC}/$DSSET_FILENAME"
DSSET_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$DSSET_FILESPEC"

rm -f "$DSSET_FULLSPEC"
# input directory -d
# input directory -K
# input file db.root
echo "Creating signed zone key pair ..."
dnssec-signzone \
    -d "$DEFAULT_KEYS_DB_FULLSPEC" \
    -K "$DEFAULT_KEYS_DB_FULLSPEC" \
    -o "." \
    -R \
    -S \
    -t \
    -T 86400 \
    -N keep \
    -D \
    -a \
    "$ROOT_ZONE_FULLSPEC"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "dnssec-signzone failed: Error $retsts; aborted."
  exit $retsts
fi
# $ROOT_ZONE_FILESPEC.signed created
# dsset-. created
# dnssec-signzone can now place 'dsset-.' elsewhere
echo "Created ${DSSET_FULLSPEC}."
echo
flex_chmod 0644 "$DSSET_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$DSSET_FILESPEC"
flex_chcon named_zone_t "$DSSET_FILESPEC"

SIGNED_ZONE_FILESPEC="${ROOT_ZONE_FILESPEC}.signed"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$SIGNED_ZONE_FILESPEC ..."
flex_chmod 0644 "$SIGNED_ZONE_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$SIGNED_ZONE_FILESPEC"
flex_chcon named_zone_t "$SIGNED_ZONE_FILESPEC"

# Create the view and its zone file
VIEW_NAMED_CONF_FILENAME="standalone-view-recursive-zone-root-named.conf"
VIEW_NAMED_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
VIEW_NAMED_CONF_FILESPEC="${VIEW_NAMED_CONF_DIRSPEC}/$VIEW_NAMED_CONF_FILENAME"
VIEW_NAMED_CONF_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$VIEW_NAMED_CONF_FILESPEC"
echo "Creating $VIEW_NAMED_CONF_FULLSPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$VIEW_NAMED_CONF_FULLSPEC" >/dev/null
# File: $VIEW_NAMED_CONF_FILENAME
# Path: $VIEW_NAMED_CONF_DIRSPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: View 'recursive' and 'root' zone

view "recursive" IN {
    match-clients { any; };
    allow-query { any; };
    recursion yes;

    allow-recursion { any; };

    // Tony Finch recommends 'no' at global, but 'auto' within 'view's.
    dnssec-validation auto;

    # can only choose one: 'update-policy' or 'allow-update'
    # update-policy local;
    allow-update {
        !{ !{ localhost; 10.10.0.1; }; any; };
        // only localhost got past this point here
        // no one can update except localhost RNDC
        key "rndc-key"; // only RNDC on localhost or 10.10.0.1

        };
    zone "." {
        type master;
        file "${ROOT_ZONE_FILESPEC}";
        check-names fail;
    };
};
PARTIAL_NAMED_CONF_EOF
flex_chmod 0640 "$VIEW_NAMED_CONF_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$VIEW_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$VIEW_NAMED_CONF_FILESPEC"

ROOT_OPTIONS_NAMED_CONF_FILENAME="standalone-options-named.conf"
ROOT_OPTIONS_NAMED_CONF_DIRSPEC="$INSTANCE_ETC_NAMED_DIRSPEC"
INSTANCE_ROOT_OPTIONS_NAMED_CONF_FILESPEC="${ROOT_OPTIONS_NAMED_CONF_DIRSPEC}/$ROOT_OPTIONS_NAMED_CONF_FILENAME"
INSTANCE_ROOT_OPTIONS_NAMED_CONF_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$INSTANCE_ROOT_OPTIONS_NAMED_CONF_FILESPEC"
echo "Creating $INSTANCE_ROOT_OPTIONS_NAMED_CONF_FULLSPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$INSTANCE_ROOT_OPTIONS_NAMED_CONF_FULLSPEC" >/dev/null

# File: $ROOT_OPTIONS_NAMED_CONF_FILENAME
# Path: $ROOT_OPTIONS_NAMED_CONF_DIRSPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: options clause of named configuration file

options {
    # Make sure that 'directory' is near the beginning of named.conf
    # before any relative directory settings.
    # Because it actually does LIVE change-directory while reading config
    # ISC has said WONTFIX on the shortcoming of this 'directory' statement.
    directory "${INSTANCE_NAMED_HOME_DIRSPEC}";
    key-directory "${INSTANCE_KEYS_DB_DIRSPEC}";

    dump-file "${DUMP_CACHE_FILESPEC}";
    statistics-file "${INSTANCE_DATA_DIRSPEC}/named_stats.txt";
    memstatistics-file "${INSTANCE_DATA_DIRSPEC}/named.memstats";

    session-keyfile "${INSTANCE_SESSION_FILESPEC}";

    zone-statistics yes;

    recursion yes;

    // Authoritative root server notifies nobody.
    notify no;

    allow-recursion { any; };


    // Tony Finch recommends 'no' at global, but 'auto' within 'view's.
    # dnssec-validation auto;
    dnssec-validation no;
    # dnssec-enable yes;  # obsoleted in v9.15.0

    auth-nxdomain no;

    listen-on { 127.0.0.1; 10.10.0.1; };

    // The magical word:
    root-delegation-only;

    // Keep that one to ourself
    //trust-anchor-telemetry yes;
};
PARTIAL_NAMED_CONF_EOF
flex_chmod 0640 "$INSTANCE_ROOT_OPTIONS_NAMED_CONF_FILESPEC"
flex_chown "root:${GROUP_NAME}" "$INSTANCE_ROOT_OPTIONS_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$INSTANCE_ROOT_OPTIONS_NAMED_CONF_FILESPEC"

# And for the 'key' clause for RNDC of named configuration
KEY_NAMED_CONF_FILENAME="standalone-key-named.conf"
KEY_NAMED_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
KEY_NAMED_CONF_FILESPEC="${KEY_NAMED_CONF_DIRSPEC}/$KEY_NAMED_CONF_FILENAME"
KEY_NAMED_CONF_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$KEY_NAMED_CONF_FILESPEC"
echo "Creating $KEY_NAMED_CONF_FULLSPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$KEY_NAMED_CONF_FULLSPEC" >/dev/null

# File: $KEY_NAMED_CONF_FILENAME
# Path: $KEY_NAMED_CONF_DIRSPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: key clause for 'rndc' of named configuration file

include "/etc/rndc.key";
PARTIAL_NAMED_CONF_EOF
flex_chmod 0640 "$KEY_NAMED_CONF_FILESPEC"
flex_chown "root:${GROUP_NAME}" "$KEY_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$KEY_NAMED_CONF_FILESPEC"

# And now for the 'managed-keys' clause of named configuration
TA_NAMED_CONF_FILENAME="standalone-trust-anchors-named.conf"
TA_NAMED_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
TA_NAMED_CONF_FILESPEC="${TA_NAMED_CONF_DIRSPEC}/$TA_NAMED_CONF_FILENAME"
TA_NAMED_CONF_FULLSPEC="${BUILDROOT}${CHROOT_DIR}${TA_NAMED_CONF_FILESPEC}"
echo "Creating $TA_NAMED_CONF_FULLSPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$TA_NAMED_CONF_FULLSPEC" >/dev/null

# File: $TA_NAMED_CONF_FILENAME
# Path: $TA_NAMED_CONF_DIRSPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: trust-anchors clause of named configuration file
# Description:
#   Formerly 'managed-keys' clause, which got obsoleted in v9.15.0

trust-anchors {
PARTIAL_NAMED_CONF_EOF

# Insert in the Zone-Signing-Key as a managed-key
# Instead of reusing the DNSKEYs in the "db.root", use our newly created ones
# Following bash script is similiar to the famous managed-keys.pl Perl script.
TA_DOMAIN="$(grep -v '^;' "$ZSK_KEY_FULLSPEC" |awk '{print $1}')"
TA_DNSSEC_ID="$(grep -v '^;' "$ZSK_KEY_FULLSPEC" |awk '{print $5}')"
TA_ALG_ID="$(grep -v '^;' "$ZSK_KEY_FULLSPEC" |awk '{print $6}')"
TA_ALG_SID="$(grep -v '^;' "$ZSK_KEY_FULLSPEC" |awk '{print $7}')"
TA_HASH="$(grep -v '^;' "$ZSK_KEY_FULLSPEC" |awk '{print $8}')"
printf '%s initial-key %s %s %s \"%s\";\n' \
  "$TA_DOMAIN" "$TA_DNSSEC_ID" "$TA_ALG_ID" "$TA_ALG_SID" "$TA_HASH" \
   >> "$TA_NAMED_CONF_FULLSPEC"

# Insert in the Key-Signing-Key as a managed-key
TA_DOMAIN="$(grep -v '^;' "$KSK_KEY_FULLSPEC" | awk '{print $1}')"
TA_DNSSEC_ID="$(grep -v '^;' "$KSK_KEY_FULLSPEC" |awk '{print $5}')"
TA_ALG_ID="$(grep -v '^;' "$KSK_KEY_FULLSPEC" |awk '{print $6}')"
TA_ALG_SID="$(grep -v '^;' "$KSK_KEY_FULLSPEC" |awk '{print $7}')"
TA_HASH="$(grep -v '^;' "$KSK_KEY_FULLSPEC" |awk '{print $8}')"
printf '%s initial-key %s %s %s \"%s\";\n' \
  "$TA_DOMAIN" "$TA_DNSSEC_ID" "$TA_ALG_ID" "$TA_ALG_SID" "$TA_HASH" \
   >> "$TA_NAMED_CONF_FULLSPEC"
echo "};" >> "$TA_NAMED_CONF_FULLSPEC"
flex_chmod 0640 "$TA_NAMED_CONF_FILESPEC"
# shellcheck disable=SC2086
flex_chown "root:${GROUP_NAME}" "$TA_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$TA_NAMED_CONF_FILESPEC"


# A final named.conf to include all the above partial named.conf files

ROOT_NAMED_CONF_FILENAME="standalone-$NAMED_CONF_FILENAME"
ROOT_NAMED_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
ROOT_NAMED_CONF_FILESPEC="${ROOT_NAMED_CONF_DIRSPEC}/$ROOT_NAMED_CONF_FILENAME"
ROOT_NAMED_CONF_FULLSPEC="${BUILDROOT}${CHROOT_DIR}$ROOT_NAMED_CONF_FILESPEC"
echo "Creating ${ROOT_NAMED_CONF_FULLSPEC} ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$ROOT_NAMED_CONF_FULLSPEC" >/dev/null
# File: standalone-$ROOT_NAMED_CONF_FILENAME
# Path: $ROOT_NAMED_CONF_DIRSPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: named configuration file for standalone CLOSED-NET root server

# include "${INSTANCE_ETC_NAMED_DIRSPEC}/logging-named.conf";
include "$KEY_NAMED_CONF_FILESPEC";
include "$INSTANCE_ROOT_OPTIONS_NAMED_CONF_FILESPEC";
include "$TA_NAMED_CONF_FILESPEC";
include "$VIEW_NAMED_CONF_FILESPEC";

PARTIAL_NAMED_CONF_EOF
echo

# Perform syntax-checking
echo "Performing syntax-checking on newly created config files ..."
if [ ! -z "${BUILDROOT}${CHROOT_DIR}" ] && [ "${BUILDROOT:0:1}" != "/" ]; then
  NAMEDCC_VIRT_DIROPT="-z -t ${BUILDROOT}${CHROOT_DIR}"
  cat << RNDC_KEY_EOF | tee "${BUILDROOT}${CHROOT_DIR}/etc/rndc.key"
# Faux RNDC key for testing with $0
key "rndc-key" {
    algorithm hmac-sha256;
    secret "x+cr8Uxj4pUPf9UwrZRGcoU6b9jQxBc0d+Zl5oJAgUQ=";
};
RNDC_KEY_EOF
fi
# shellcheck disable=SC2086
${named_checkconf_filespec} $NAMEDCC_VIRT_DIROPT "$ROOT_NAMED_CONF_FILESPEC" >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Mmmmm, syntax error in ${BUILDROOT}$ROOT_NAMED_CONF_FILESPEC"
  echo "Error output:"
  # shellcheck disable=SC2086
  ${named_checkconf_filespec} $NAMEDCC_VIRT_DIROPT "$ROOT_NAMED_CONF_FILESPEC"
  echo "Aborted."
  exit $retsts
fi
echo "Syntax check passed."

echo "Use this file: "
echo "     ${BUILDROOT}${CHROOT_DIR}$ROOT_NAMED_CONF_FILESPEC"
echo "in your /etc/sysconfig/named or /etc/default/named for "
echo "your configuration file startup of named daemon."
echo

echo "Done."

