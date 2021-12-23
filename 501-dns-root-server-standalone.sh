#!/bin/bash
# File: dnssec-create-root.sh
# Title: Create standalone "13" Root Servers for whitelab
# Description:
#   This script will create a Root Server for local use only.
#
#   This script will do the following:
#   - generate ZSK and KSK public key-pairs for '.' zone
#   - generate root zone file by cloning f.root-server.net via AXFR
#   - place the files into their Fedora-default named subdirectories
#   - create partial named.conf configuration files for your own inclusion
#   - Set correct file ownership/permissions 
#   - If SELinux-enabled, set the correct SELinux context for all files.
#
# Env vars:
#   RUNDIR
#   SYSCONFDIR
#   NAMED_HOME_DIRSPEC
#   NAMED_DATA_DIRSPEC
#   ZONE_DB_DIRSPEC
#   KEYS_DIRSPEC

echo "Create a standalone root server for a closed network whitelab usage"
echo ""

DOMAIN_TTL=86400
SYSCONFDIR="${SYSCONFDIR:-/etc/named}"   # typically /etc/bind or /etc/named
if [ -z "$NAMED_HOME_DIRSPEC" ]; then
  NAMED_HOME_DIRSPEC="$(grep named /etc/passwd | awk -F: '{print $6}')"
fi
NAMED_DATA_DIRSPEC="${NAMED_DATA_DIRSPEC:-${NAMED_HOME_DIRSPEC}/data}"
# Directory of Zone DBs are always a separate declaration than named's $HOME 
ZONE_DB_DIRSPEC="${ZONE_DB_DIRSPEC:-/var/named}"  # typically /var/lib/bind or /var/named
KEYS_DIRSPEC="${KEYS_DB_DIRSPEC:-$ZONE_DB_DIRSPEC/keys}"   # typically /var/lib/bind/keys or /var/named/keys
NAMED_CONF_FILESPEC="${SYSCONFDIR}/standalone-named.conf"

echo "This will write over your Bind9 settings."
echo "Or you could define the following and rerun for a local daemon copy:"
echo ""
echo "    RUNDIR=. SYSCONFDIR=. NAMED_HOME_DIRSPEC=. \\"
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

exit
PRIVATE_TLD="my-root"  # could be 'home', 'private', 'lan', 'internal'
NS1_IP="10.10.0.1"  # could be whatever netdev IP that is private or NOT NAT'd 
SN="$(date +%Y%m%d%H)"
T1="1800"
T2="900"
T3="604800"
T4="86400"
NS1_NAME="ns1.a.myroot-servers.${PRIVATE_TLD}."
CONTACT="hostmaster.${PRIVATE_TLD}."

# In ALGORITHSM, the first entry is the input default
echo "List of supported DNSSEC algorithms:"
ALGORITHMS=("ecdsaP256Sha256" "ecdsaP384Sha384" "ed25519" "rsaSha256" "rsaSha512")
idx=1
for alg in ${ALGORITHMS[@]}; do
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

if [ ! -d "$NAMED_HOME_DIRSPEC" ]; then
  echo "named $HOME directory '$NAMED_HOME_DIRSPEC' does not exist; aborted."
  exit 3
fi

if [ ! -d "$ZONE_DB_DIRSPEC" ]; then
  echo "Zone database directory '$ZONE_DB_DIRSPEC' does not exist; aborted."
  exit 3
fi

if [ ! -d "$KEYS_DIRSPEC" ]; then
  echo "Key directory '$KEYS_DIRSPEC' does not exist; aborted."
  exit 3
fi

# file_perms <filespec> 0640 named:named <se-context>
function file_perms()
{
  FILESPEC=$1
  FILE_MODE=$2
  OWNER_GROUP=$3
  SECONTEXT=$4
  chmod "$FILE_MODE" "$FILESPEC"
  chown "$OWNER_GROUP" "$FILESPEC"
  selinuxenabled
  RETSTS=$?
  if [ "$RETSTS" -eq 0 ]; then
    chcon "system_u:object_r:$SECONTEXT:s0" "$FILESPEC"
  fi
  unset FILESPEC FILE_MODE OWNER_GROUP SECONTEXT
}


cd "$ZONE_DB_DIRSPEC" || exit 9


echo "Creating Zone-Signing-Key (ZSK) files ..."
ZSK_ID="$(dnssec-keygen -T DNSKEY \
    -K "$KEYS_DIRSPEC" \
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
file_perms "$ZSK_KEY_FILESPEC" 0644 named:named named_cache_t
file_perms "$ZSK_PRIVATE_FILESPEC" 0600 named:named named_cache_t

echo "Creating Key-Signing-Key (KSK) files ..."
KSK_ID="$(dnssec-keygen -T DNSKEY \
    -K "$KEYS_DIRSPEC" \
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
file_perms "$KSK_KEY_FILESPEC" 0644 named:named named_cache_t
file_perms "$KSK_PRIVATE_FILESPEC" 0600 named:named named_cache_t
echo ""

# Make sure that all other NS records for the root zone "." have been removed
#echo "Removing all '$DOMAIN_ROOT_PART' domain part from temp root zone file ..."
#sed -i "/^\.\s/d" "$TMP_ROOT_ZONE_FILESPEC"

# Create SOA, NS, and A glue records
echo "Creating SOA, NS, annd A glue record in ${ROOT_ZONE_FILESPEC} ..."
cat << ROOT_ZONE_EOF > ${ROOT_ZONE_FILESPEC}
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

# Copy the big full zone transfer file after our SOA, NS, A header
cat "$TMP_ROOT_ZONE_FILESPEC" >> "$ROOT_ZONE_FILESPEC"
file_perms "$ROOT_ZONE_FILESPEC" 0644 named:named named_zone_t
echo "$ROOT_ZONE_FILESPEC created."
rm "$TMP_ROOT_ZONE_FILESPEC"

# Append the DNSKEYs at the end of the zone file
cat "$ZSK_KEY_FILESPEC" >> "$ROOT_ZONE_FILESPEC"
cat "$KSK_KEY_FILESPEC" >> "$ROOT_ZONE_FILESPEC"
echo ""

rm -f "$DSSET_FILESPEC"
# input directory -d
# input directory -K
# input file db.root
dnssec-signzone \
    -d "$ZONE_DB_DIRSPEC" \
    -K "$KEYS_DIRSPEC" \
    -o "." \
    -R \
    -S \
    -t \
    -T 86400 \
    -N keep \
    -D \
    -a \
    "$ROOT_ZONE_FILESPEC"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "dnssec-signzone failed: Error $retsts; aborted."
  exit $retsts
fi
# $ROOT_ZONE_FILESPEC.signed created
# dsset-. created
mv "${ZONE_DB_DIRSPEC}/dsset-." "${ZONE_DB_DIRSPEC}/dsset-root"
echo "$DSSET_FILESPEC created."
file_perms "$DSSET_FILESPEC" 0644 named:named named_zone_t

SIGNED_ZONE_FILESPEC="${ROOT_ZONE_FILESPEC}.signed"
echo "$SIGNED_ZONE_FILESPEC created."
file_perms "$SIGNED_ZONE_FILESPEC" 0644 named:named named_zone_t

# Create the view and its zone file
VIEW_NAMED_CONF_FILESPEC="${SYSCONFDIR}/standalone-view-recursive-zone-root-named.conf"
echo "Creating $VIEW_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$VIEW_NAMED_CONF_FILESPEC" >/dev/null

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
        key "rndc-key"; // only RNDC on localhost

        };
    zone "." {
        type master;
        file "${ROOT_ZONE_FILESPEC}";
        check-names fail;
    };
};
PARTIAL_NAMED_CONF_EOF
file_perms "$VIEW_NAMED_CONF_FILESPEC" 0640 root:named named_conf_t

OPTIONS_NAMED_CONF_FILESPEC="${SYSCONFDIR}/standalone-options-named.conf"
echo "Creating $OPTIONS_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$OPTIONS_NAMED_CONF_FILESPEC" >/dev/null

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

    session-keyfile "${RUNDIR}/named-session.key";
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
    trust-anchor-telemetry no;
};
PARTIAL_NAMED_CONF_EOF
file_perms "$OPTIONS_NAMED_CONF_FILESPEC" 0640 root:named named_conf_t

# And for the 'key' clause for RNDC of named configuration
KEY_NAMED_CONF_FILESPEC="${SYSCONFDIR}/standalone-key-named.conf"
echo "Creating $KEY_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$KEY_NAMED_CONF_FILESPEC" >/dev/null

# File: $KEY_NAMED_CONF_FILESPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: key clause for 'rndc' of named configuration file

include "/etc/rndc.key";
PARTIAL_NAMED_CONF_EOF
file_perms "$KEY_NAMED_CONF_FILESPEC" 0640 root:named named_conf_t

# And now for the 'managed-keys' clause of named configuration
TA_NAMED_CONF_FILESPEC="${SYSCONFDIR}/standalone-trust-anchors-named.conf"
echo "Creating $TA_NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$TA_NAMED_CONF_FILESPEC" >/dev/null

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
TA_DOMAIN="$(grep -v '^;' "$ZSK_KEY_FILESPEC" |awk '{print $1}')"
TA_DNSSEC_ID="$(grep -v '^;' "$ZSK_KEY_FILESPEC" |awk '{print $5}')"
TA_ALG_ID="$(grep -v '^;' "$ZSK_KEY_FILESPEC" |awk '{print $6}')"
TA_ALG_SID="$(grep -v '^;' "$ZSK_KEY_FILESPEC" |awk '{print $7}')"
TA_HASH="$(grep -v '^;' "$ZSK_KEY_FILESPEC" |awk '{print $8}')"
printf '%s initial-key %s %s %s \"%s\";\n' \
  "$TA_DOMAIN" "$TA_DNSSEC_ID" "$TA_ALG_ID" "$TA_ALG_SID" "$TA_HASH" \
   >> "$TA_NAMED_CONF_FILESPEC"

# Insert in the Key-Signing-Key as a managed-key
TA_DOMAIN="$(grep -v '^;' "$KSK_KEY_FILESPEC" | awk '{print $1}')"
TA_DNSSEC_ID="$(grep -v '^;' "$KSK_KEY_FILESPEC" |awk '{print $5}')"
TA_ALG_ID="$(grep -v '^;' "$KSK_KEY_FILESPEC" |awk '{print $6}')"
TA_ALG_SID="$(grep -v '^;' "$KSK_KEY_FILESPEC" |awk '{print $7}')"
TA_HASH="$(grep -v '^;' "$KSK_KEY_FILESPEC" |awk '{print $8}')"
printf '%s initial-key %s %s %s \"%s\";\n' \
  "$TA_DOMAIN" "$TA_DNSSEC_ID" "$TA_ALG_ID" "$TA_ALG_SID" "$TA_HASH" \
   >> "$TA_NAMED_CONF_FILESPEC"
echo "};" >> "$TA_NAMED_CONF_FILESPEC"
file_perms "$TA_NAMED_CONF_FILESPEC" 0640 root:named named_conf_t

# A final named.conf to include all the above partial named.conf files
echo "Creating $NAMED_CONF_FILESPEC ..."
cat << PARTIAL_NAMED_CONF_EOF | tee "$NAMED_CONF_FILESPEC" >/dev/null
# File: $NAMED_CONF_FILESPEC
# Date: $(date +"%Y%M%D %H%M")"
# Title: named configuration file for standalone CLOSED-NET root server

include "${SYSCONFDIR}/logging-named.conf";
include "$KEY_NAMED_CONF_FILESPEC";
include "$OPTIONS_NAMED_CONF_FILESPEC";
include "$TA_NAMED_CONF_FILESPEC";
include "$VIEW_NAMED_CONF_FILESPEC";

PARTIAL_NAMED_CONF_EOF
echo ""

# Perform syntax-checking
echo "Performing syntax-checking on newly created config files ..."
named-checkconf -z "$NAMED_CONF_FILESPEC" >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Mmmmm, syntax error in $NAMED_CONF_FILESPEC"
  echo "Error output:"
  named-checkconf -z "$NAMED_CONF_FILESPEC" 
  exit $retsts
fi
echo ""

echo "Use this file: "
echo "     $NAMED_CONF_FILESPEC"
echo "in your /etc/sysconfig/named or /etc/default/named for "
echo "your configuration file startup of named daemon."

echo "Done."

