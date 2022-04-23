#!/bin/bash
# File: 540-dns-bind-caching-only.sh
# Title: Create a Caching-Only Name Server
# Description:
#   The following sample configuration is appropriate 
#   for a caching-only name server for use by clients 
#   internal to a corporation. All queries from 
#   outside clients are refused using the allow-query 
#   option. The same effect can be achieved using 
#   suitable firewall rules.
#
# acl caching-only-allow-query-subnet { 192.168.4.0/24; 192.168.7.0/24; };
# options {
#     // Working directory
#     directory "/etc/namedb";
# 
#     recursion no;
#     allow-query { none; };
#     allow-transfer { none; };
#     allow-notify { none; };
#     };
#
# view "localhost" IN {
#
#     allow-query { caching-only-allow-query-subnet; };
#     recursion yes;
#
#     // Provide a reverse mapping for the loopback
#     // address 127.0.0.1
#     zone "0.0.127.in-addr.arpa" {
#         type primary;
#         file "localhost.rev";
#         notify no;
#         };
#     };
# 
#
# Dependencies:
#   ipcalc-ng
#   awk (gawk)
#   coreutils
#
# Environment Names
#   VIEW_NAME - The name of the view to create
#   VERBOSE - see more things less tersely
#

ACL_NAME="acl-localhost_loopback-caching-only_allow-query_named"
default_view_name="${VIEW_NAME:-public}"

echo "Create a Caching-Only Name Server"
echo


source ./maintainer-dns-isc.sh

instance_view_conf_dirspec="${INSTANCE_ETC_NAMED_DIRSPEC}"

if [ "${BUILDROOT:0:1}" == '/' ]; then
  FILE_SETTING_PERFORM=true
  echo "Absolute build"
else
  FILE_SETTING_PERFORM=false
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-named-views${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  mkdir -p "$BUILDROOT"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$ETC_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_DIRSPEC"
  flex_ckdir "$ETC_NAMED_DIRSPEC"
  flex_ckdir "$VAR_LIB_NAMED_DIRSPEC"
  flex_ckdir "$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"
fi
echo


# Create ACL file
ACL_FILENAME="${ACL_NAME}.conf"
ACL_DIRSPEC="/etc/named"
ACL_FILESPEC="${ACL_DIRSPEC}/$ACL_FILENAME"
create_header "$ACL_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "ACL \"caching only allow-query\" clause"
printf "acl ${ACL_NAME} {\n    127.0.0.1/24;\n    };" \
    >> "${BUILDROOT}${CHROOT_DIR}$ACL_FILESPEC"

# Add this ACL to the master ACLs file
unique_add_line "$ACL_FILESPEC" "/etc/named/acls-named.conf"

# Create Zone data file
ZONE_LOOPBACK_DATA_DIRSPEC="/var/named/primaries"
ZONE_LOOPBACK_DATA_FILENAME="pz.localhost.db"
ZONE_LOOPBACK_DATA_FILESPEC="$ZONE_LOOPBACK_DATA_DIRSPEC/$ZONE_LOOPBACK_DATA_FILENAME"
cat << LOOPBACK_DATA_EOF | tee "${ZONE_LOOPBACK_DATA_FILESPEC}" > /dev/null
@               1D IN SOA   localhost. root.localhost. (
                       42    ; serial (yyyymmdd##)
                       3H    ; refresh
                       15M   ; retry
                       1W    ; expiry
                       1D )  ; minimum ttl

                1D  IN  NS      localhost.

localhost.      1D  IN  A       127.0.0.1
localhost.      1D  IN  AAAA    ::1

LOOPBACK_DATA_EOF
flex_chmod 0640 "${ZONE_LOOPBACK_DATA_FILESPEC}"
flex_chown "${USER_NAME}:$GROUP_NAME" "${ZONE_LOOPBACK_DATA_FILESPEC}"

# Create Zone reverse data file
ZONE_LOOPBACK_REV_DATA_DIRSPEC="/var/named/primaries"
ZONE_LOOPBACK_REV_DATA_FILENAME="pz.0.0.127.in-addr-arpa.db"
ZONE_LOOPBACK_REV_DATA_FILESPEC="$ZONE_LOOPBACK_REV_DATA_DIRSPEC/$ZONE_LOOPBACK_REV_DATA_FILENAME"
cat << LOOPBACK_REV_EOF | tee "${ZONE_LOOPBACK_REV_DATA_FILESPEC}" > /dev/null
@               1D IN SOA   localhost. root.localhost. (
                            42    ; serial (yyyymmdd##)
                            3H    ; refresh
                            15M   ; retry
                            1W    ; expiry
                            1D )  ; minimum ttl

                1D  IN  NS      localhost.

localhost.      1D  IN  A       127.0.0.1
localhost.      1D  IN  AAAA    ::1

LOOPBACK_REV_EOF
flex_chmod "0640" "${ZONE_LOOPBACK_REV_DATA_FILESPEC}"
flex_chown "${USER_NAME}:$GROUP_NAME" "${ZONE_LOOPBACK_REV_DATA_FILESPEC}"

# Create View localhost file
VIEW_LOCALHOST_DIRSPEC="/etc/named"
VIEW_LOCALHOST_FILENAME="view-localhost-named.conf"
VIEW_LOCALHOST_FILESPEC="${VIEW_LOCALHOST_DIRSPEC}/${VIEW_LOCALHOST_FILENAME}"
create_header "${VIEW_LOCALHOST_FILESPEC}" \
    "${USER_NAME}:${GROUP_NAME}" 0640 "View \"localhost\""

cat << VIEW_LOCALHOST_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$VIEW_LOCALHOST_FILESPEC" >/dev/null
view "localhost" IN {

    allow-query { ${ACL_NAME}; };
    recursion yes;

    // Provide a reverse mapping for the loopback
    // address 127.0.0.1
    zone "localhost" {
        type primary;
        file "$ZONE_LOOPBACK_DATA_FILESPEC";
        notify no;
        };
    zone "0.0.127.in-addr.arpa" {
        type primary;
        file "$ZONE_LOOPBACK_REV_DATA_FILESPEC";
        notify no;
        };
    };

VIEW_LOCALHOST_EOF
flex_chmod 0640 "$VIEW_LOCALHOST_FILESPEC"
flex_chown "${USER_NAME}:$GROUP_NAME" "${VIEW_LOCALHOST_FILESPEC}"

# Append Views file
# Add this view to the master Views file
unique_add_line "$VIEW_LOCALHOST_FILESPEC" "/etc/named/views-named.conf"

echo
echo "Done."
