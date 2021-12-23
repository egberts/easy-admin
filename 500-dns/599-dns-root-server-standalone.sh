#!/bin/bash
# File: dnssec-create-root.sh
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
#   NAMED_HOME_DIRSPEC (defaults to os-distro-selected named/bind $HOME)
#   NAMED_DATA_DIRSPEC
#   ZONE_DB_DIRSPEC
#   KEYS_DIRSPEC

echo "Create a standalone root server for a closed network whitelab usage"
echo ""


source dns-isc-common.sh

DOMAIN_TTL=86400
sysconfdir="${sysconfdir:-/etc/named}"   # typically /etc/bind or /etc/named
NAMED_DATA_DIRSPEC="${NAMED_DATA_DIRSPEC:-${NAMED_HOME_DIRSPEC}/data}"
# Directory of Zone DBs are always a separate declaration than named's $HOME 
ZONE_DB_DIRSPEC="${ZONE_DB_DIRSPEC:-/var/named}"  # typically /var/lib/bind or /var/named
KEYS_DIRSPEC="${KEYS_DB_DIRSPEC:-$ZONE_DB_DIRSPEC/keys}"   # typically /var/lib/bind/keys or /var/named/keys
NAMED_CONF_FILESPEC="${sysconfdir}/standalone-named.conf"

if [ "${BUILDROOT:0:1}" == "/" ]; then
  echo "This will write over your Bind9 settings."
  echo "Or you could define the following and rerun for a local daemon copy:"
  echo ""
  echo "    rundir=. sysconfdir=. NAMED_HOME_DIRSPEC=. \\"
  echo "        NAMED_DATA_DIRSPEC=. ZONE_DB_DIRSPEC=.  \\"
  echo "        KEYS_DIRSPEC=.  \\"
  echo "        ./dns-root-server-standalone.sh"
  echo "    named -4 -d65535 -g -c ${NAMED_CONF_FILESPEC} -T mkeytimers=1/6/180"
  echo ""
  echo " 'mkeytimers' for a 3-minute DNSSEC key rollover interval at root server-level"
  echo ""
  read -rp "Enter in 'yes' to contiinue: "
  if [ "$REPLY" != "yes" ]; then
    echo "Aborted."
    exit 2
  fi
  if [ "$USER" != "root" ]; then
    echo "Must be root to run $0"
    exit 9
  fi
fi

PRIVATE_TLD="my-root"  # could be 'home', 'private', 'lan', 'internal'
NS1_IP="10.10.0.1"  # could be whatever netdev IP that is private or NOT NAT'd 
SN="$(date +%Y%m%d%H)"
T1="1800"
T2="900"
T3="604800"
T4="86400"
NS1_NAME="ns1.a.myroot-servers.${PRIVATE_TLD}."
CONTACT="hostmaster.${PRIVATE_TLD}."

BUILDROOT="${BUILDROOT:-build/}"
if [ "${BUILDROOT:0:1}" != '/' ]; then
  mkdir -p build
else
  BUILDROOT=""
fi
FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-dns-root-server-standalone.sh"
rm -f "$FILE_SETTINGS_FILESPEC"

flex_mkdir "$libdir"
flex_mkdir "$libdir/dynamic"
flex_mkdir "$libdir/keys"
flex_mkdir "$libdir/data"
flex_mkdir "$localstatedir"
flex_mkdir "$sysconfdir"
flex_mkdir "$sysconfdir/keys"

# In ALGORITHSM, the first entry is the input default
echo "List of supported DNSSEC algorithms:"
ALGORITHMS=("ecdsaP256Sha256" "ecdsaP384Sha384" "ed25519" "rsaSha256" "rsaSha512")
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
  echo ""
fi


DOMAIN_ROOT_PART="."  # must be the same as 1st field of SOA line in zone file
ROOT_ZONE_FILESPEC="${ZONE_DB_DIRSPEC}/db.root.standalone"
TMP_ROOT_ZONE_FILESPEC="${ROOT_ZONE_FILESPEC}.tmp"


DSSET_FILESPEC="$ZONE_DB_DIRSPEC/dsset-root"

if [ ! -d "${BUILDROOT}${CHROOT_DIR}$NAMED_HOME_DIRSPEC" ]; then
  echo "named $HOME directory '${BUILDROOT}${CHROOT_DIR}$NAMED_HOME_DIRSPEC' does not exist; aborted."
  exit 3
fi

if [ ! -d "${BUILDROOT}${CHROOT_DIR}$ZONE_DB_DIRSPEC" ]; then
  echo "Zone database directory '${BUILDROOT}${CHROOT_DIR}$ZONE_DB_DIRSPEC' does not exist; aborted."
  exit 3
fi

if [ ! -d "${BUILDROOT}${CHROOT_DIR}$KEYS_DIRSPEC" ]; then
  echo "Key directory '${BUILDROOT}${CHROOT_DIR}$KEYS_DIRSPEC' does not exist; aborted."
  exit 3
fi

#cd "$ZONE_DB_DIRSPEC" || exit 9


echo "Creating Zone-Signing-Key (ZSK) files in $PWD PWD..."
ZSK_ID="$(dnssec-keygen -T DNSKEY \
    -K "${BUILDROOT}${CHROOT_DIR}$KEYS_DIRSPEC" \
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
ZSK_KEY_FILESPEC="${KEYS_DIRSPEC}/${ZSK_ID}.key"
ZSK_PRIVATE_FILESPEC="${KEYS_DIRSPEC}/${ZSK_ID}.private"
flex_chmod 0644 "$ZSK_KEY_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$ZSK_KEY_FILESPEC" 
flex_chcon named_cache_t "$ZSK_PRIVATE_FILESPEC" 

echo "Creating Key-Signing-Key (KSK) files ..."
KSK_ID="$(dnssec-keygen -T DNSKEY \
    -K "${BUILDROOT}${CHROOT_DIR}$KEYS_DIRSPEC" \
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
KSK_KEY_FILESPEC="${KEYS_DIRSPEC}/${KSK_ID}.key"
KSK_PRIVATE_FILESPEC="${KEYS_DIRSPEC}/${KSK_ID}.private"
flex_chmod 0644 "$KSK_KEY_FILESPEC"
flex_chown "${USER_NAME}:${GROUP_NAME}" "$KSK_KEY_FILESPEC"
flex_chcon named_cache_t "$KSK_KEY_FILESPEC"
flex_chmod 0600 "$KSK_PRIVATE_FILESPEC" 
flex_chown "${USER_NAME}:${GROUP_NAME}" "$KSK_PRIVATE_FILESPEC"
flex_chcon named_cache_t "$KSK_PRIVATE_FILESPEC" 
echo ""

# Make sure that all other NS records for the root zone "." have been removed
#echo "Removing all '$DOMAIN_ROOT_PART' domain part from temp root zone file ..."
#sed -i "/^\.\s/d" "$TMP_ROOT_ZONE_FILESPEC"

# Create SOA, NS, and A glue records
echo "Creating SOA, NS, annd A glue record in ${ROOT_ZONE_FILESPEC} ..."
cat << ROOT_ZONE_EOF > "${BUILDROOT}${CHROOT_DIR}${ROOT_ZONE_FILESPEC}"
.		${DOMAIN_TTL}	IN	SOA	mname.invalid. nm.invalid. (
						$SN	; Serial Number
						$T1	; Refresh
						$T2	; Retry
						$T3	; Expire
						$T4	; Negative Cache TTL
						)
.				NS	ns.root.
ns.root.			A	10.10.0.1

invalid.			NS	ns.invalid.
ns.invalid.			A	10.10.0.1

example.			NS	ns.example.
ns.example.			A	10.10.0.1

.				TXT	"This is the example root zone."

ROOT_ZONE_EOF

# Append the big full zone transfer file after our SOA, NS, A header
# shellcheck disable=SC2129
cat "$TMP_ROOT_ZONE_FILESPEC" >> "${BUILDROOT}${CHROOT_DIR}$ROOT_ZONE_FILESPEC"

# Append the DNSKEYs at the end of the zone file
cat "${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC" >> "${BUILDROOT}${CHROOT_DIR}$ROOT_ZONE_FILESPEC"
cat "${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC" >> "${BUILDROOT}${CHROOT_DIR}$ROOT_ZONE_FILESPEC"

echo "$ROOT_ZONE_FILESPEC created."
flex_chmod 0644 "$ROOT_ZONE_FILESPEC" 
flex_chown "${USER_NAME}:${GROUP_NAME}" "$ROOT_ZONE_FILESPEC" 
flex_chcon named_zone_t "$ROOT_ZONE_FILESPEC" 
rm "${BUILDROOT}${CHROOT_DIR}$TMP_ROOT_ZONE_FILESPEC"
echo ""

rm -f "${BUILDROOT}${CHROOT_DIR}$DSSET_FILESPEC"
# input directory -d
# input directory -K
# input file db.root
dnssec-signzone \
    -d "${BUILDROOT}${CHROOT_DIR}$ZONE_DB_DIRSPEC" \
    -K "${BUILDROOT}${CHROOT_DIR}$KEYS_DIRSPEC" \
    -o "." \
    -R \
    -S \
    -t \
    -T 86400 \
    -N keep \
    -D \
    -a \
    "${BUILDROOT}${CHROOT_DIR}$ROOT_ZONE_FILESPEC"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "dnssec-signzone failed: Error $retsts; aborted."
  exit $retsts
fi
# $ROOT_ZONE_FILESPEC.signed created
# dsset-. created
mv "${BUILDROOT}${CHROOT_DIR}${ZONE_DB_DIRSPEC}/dsset-." "${BUILDROOT}${CHROOT_DIR}${ZONE_DB_DIRSPEC}/dsset-root"
echo "${BUILDROOT}${CHROOT_DIR}$DSSET_FILESPEC created."
flex_chmod 0644 "$DSSET_FILESPEC" 
flex_chown "${USER_NAME}:${GROUP_NAME}" "$DSSET_FILESPEC" 
flex_chcon named_zone_t "$DSSET_FILESPEC" 

SIGNED_ZONE_FILESPEC="${ROOT_ZONE_FILESPEC}.signed"
echo "$SIGNED_ZONE_FILESPEC created."
flex_chmod 0644 "$SIGNED_ZONE_FILESPEC" 
flex_chown "${USER_NAME}:${GROUP_NAME}" "$SIGNED_ZONE_FILESPEC" 
flex_chcon named_zone_t "$SIGNED_ZONE_FILESPEC" 

# Create the view and its zone file
VIEW_NAMED_CONF_FILESPEC="${sysconfdir}/standalone-view-recursive-zone-root-named.conf"
echo "Creating $VIEW_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$VIEW_NAMED_CONF_FILESPEC" >/dev/null

# File: $VIEW_NAMED_CONF_FILESPEC
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
flex_chown "root:${GROUP_NAME}" "$VIEW_NAMED_CONF_FILESPEC" 
flex_chcon named_conf_t "$VIEW_NAMED_CONF_FILESPEC" 

OPTIONS_NAMED_CONF_FILESPEC="${sysconfdir}/standalone-options-named.conf"
echo "Creating $OPTIONS_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$OPTIONS_NAMED_CONF_FILESPEC" >/dev/null

# File: $OPTIONS_NAMED_CONF_FILESPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: options clause of named configuration file

options {
    # Make sure that 'directory' is near the beginning of named.conf
    # before any relative directory settings.
    # Because it actually does LIVE change-directory while reading config
    # ISC has said WONTFIX on the shortcoming of this 'directory' statement.
    directory "${NAMED_HOME_DIRSPEC}";
    key-directory "${KEYS_DIRSPEC}";

    dump-file "${NAMED_DATA_DIRSPEC}/cache_dump.db";
    statistics-file "${NAMED_DATA_DIRSPEC}/named_stats.txt";
    memstatistics-file "${NAMED_DATA_DIRSPEC}/named.memstats";

    session-keyfile "${rundir}/named-session.key";
    pid-file none;

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
flex_chmod 0640 "$OPTIONS_NAMED_CONF_FILESPEC"
flex_chown "root:${GROUP_NAME}" "$OPTIONS_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$OPTIONS_NAMED_CONF_FILESPEC"

# And for the 'key' clause for RNDC of named configuration
KEY_NAMED_CONF_FILESPEC="${sysconfdir}/standalone-key-named.conf"
echo "Creating $KEY_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$KEY_NAMED_CONF_FILESPEC" >/dev/null

# File: $KEY_NAMED_CONF_FILESPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: key clause for 'rndc' of named configuration file

include "/etc/rndc.key";
PARTIAL_NAMED_CONF_EOF
flex_chmod 0640 "$KEY_NAMED_CONF_FILESPEC"
flex_chown "root:${GROUP_NAME}" "$KEY_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$KEY_NAMED_CONF_FILESPEC"

# And now for the 'managed-keys' clause of named configuration
TA_NAMED_CONF_FILESPEC="${sysconfdir}/standalone-trust-anchors-named.conf"
echo "Creating $TA_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$TA_NAMED_CONF_FILESPEC" >/dev/null

# File: $TA_NAMED_CONF_FILESPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: trust-anchors clause of named configuration file
# Description:
#   Formerly 'managed-keys' clause, which got obsoleted in v9.15.0

trust-anchors {
PARTIAL_NAMED_CONF_EOF

# Insert in the Zone-Signing-Key as a managed-key
# Instead of reusing the DNSKEYs in the "db.root", use our newly created ones
# Following bash script is similiar to the famous managed-keys.pl Perl script.
TA_DOMAIN="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC" |awk '{print $1}')"
TA_DNSSEC_ID="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC" |awk '{print $5}')"
TA_ALG_ID="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC" |awk '{print $6}')"
TA_ALG_SID="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC" |awk '{print $7}')"
TA_HASH="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$ZSK_KEY_FILESPEC" |awk '{print $8}')"
printf '%s initial-key %s %s %s \"%s\";\n' \
  "$TA_DOMAIN" "$TA_DNSSEC_ID" "$TA_ALG_ID" "$TA_ALG_SID" "$TA_HASH" \
   >> "${BUILDROOT}${CHROOT_DIR}$TA_NAMED_CONF_FILESPEC"

# Insert in the Key-Signing-Key as a managed-key
TA_DOMAIN="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC" | awk '{print $1}')"
TA_DNSSEC_ID="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC" |awk '{print $5}')"
TA_ALG_ID="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC" |awk '{print $6}')"
TA_ALG_SID="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC" |awk '{print $7}')"
TA_HASH="$(grep -v '^;' "${BUILDROOT}${CHROOT_DIR}$KSK_KEY_FILESPEC" |awk '{print $8}')"
printf '%s initial-key %s %s %s \"%s\";\n' \
  "$TA_DOMAIN" "$TA_DNSSEC_ID" "$TA_ALG_ID" "$TA_ALG_SID" "$TA_HASH" \
   >> "${BUILDROOT}${CHROOT_DIR}$TA_NAMED_CONF_FILESPEC"
echo "};" >> "${BUILDROOT}${CHROOT_DIR}$TA_NAMED_CONF_FILESPEC"
flex_chmod 0640 "$TA_NAMED_CONF_FILESPEC"
# shellcheck disable=SC2086
flex_chown "root:${GROUP_NAME}" "$TA_NAMED_CONF_FILESPEC"
flex_chcon named_conf_t "$TA_NAMED_CONF_FILESPEC"

# A final named.conf to include all the above partial named.conf files
echo "Creating $NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$NAMED_CONF_FILESPEC" >/dev/null
# File: $NAMED_CONF_FILESPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: named configuration file for standalone CLOSED-NET root server

# include "${sysconfdir}/logging-named.conf";
include "$KEY_NAMED_CONF_FILESPEC";
include "$OPTIONS_NAMED_CONF_FILESPEC";
include "$TA_NAMED_CONF_FILESPEC";
include "$VIEW_NAMED_CONF_FILESPEC";

PARTIAL_NAMED_CONF_EOF
echo ""

# Perform syntax-checking
echo "Performing syntax-checking on newly created config files ..."
if [ ! -z "${BUILDROOT}${CHROOT_DIR}" ] && [ "${BUILDROOT:0:1}" != "/" ]; then
  NAMED_VIRT_DIROPT="-t $(realpath "${BUILDROOT}${CHROOT_DIR}")"
  cat << RNDC_KEY_EOF | tee "${BUILDROOT}${CHROOT_DIR}/etc/rndc.key"
# Faux RNDC key for testing with $0
key "rndc-key" {
	algorithm hmac-sha256;
	secret "x+cr8Uxj4pUPf9UwrZRGcoU6b9jQxBc0d+Zl5oJAgUQ=";
};
RNDC_KEY_EOF
fi
# shellcheck disable=SC2086
named-checkconf $NAMED_VIRT_DIROPT -z "$NAMED_CONF_FILESPEC" >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Mmmmm, syntax error in ${BUILDROOT}$NAMED_CONF_FILESPEC"
  echo "Error output:"
  # shellcheck disable=SC2086
  named-checkconf $NAMED_VIRT_DIROPT -l -z "$NAMED_CONF_FILESPEC" 
  exit $retsts
fi
echo 

echo "Use this file: "
echo "     ${BUILDROOT}${CHROOT_DIR}$NAMED_CONF_FILESPEC"
echo "in your /etc/sysconfig/named or /etc/default/named for "
echo "your configuration file startup of named daemon."

echo "Done."

