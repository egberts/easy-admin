#!/bin/bash
# File: 080-gnupg-setup-global.sh
# Title: GNU Pretty Good Privacy setup for host-wide global settings
#
#

echo "GNU Pretty Good Privacy (gpg) setup for maintianers of packages."
echo ""

if [ "$UID" -ne 0 ]; then
  echo "This is a non-root user; May prompt for sudo password"
fi
GPG_BIN="$(whereis -b gpg|awk -F: '{print $2}'|awk '{print $1}')"
if [ -z "$GPG_BIN" ]; then
  echo "GNU PGP is not installed"
  # gnupg-utils, makes it easier to upgrade from older GPGv1
  # gpgconf, makes it easier to view GPG settings and make any safer changes
  sudo apt install gnupg2 gnupg-utils gpgconf
fi
MIGRATE="migrate-pubring-from-classic-gpg"
MIGRATE_BIN="$(whereis -b $MIGRATE|awk -F: '{print $2}'|awk '{print $1}')"
if [ -z "$MIGRATE_BIN" ]; then
  echo "GNU migrate-pubring-from-classic-gpg is not installed"
  # gnupg-utils, makes it easier to upgrade from older GPGv1
  sudo apt install gnupg-utils gpgconf
  migrate-pubring-from-classic-gpg --default
fi

GPGCONF="gpgconf"
GPGCONF_BIN="$(whereis -b $GPGCONF|awk -F: '{print $2}'|awk '{print $1}')"
if [ -z "$GPGCONF_BIN" ]; then
  echo "GNU migrate-pubring-from-classic-gpg is not installed"
  # gpgconf, makes it easier to view GPG settings and make any safer changes
  sudo apt install gnupg-utils gpgconf
  migrate-pubring-from-classic-gpg --default
fi

MIN_GPG_VERSION="2.2.0"
GPG_VERSION="$(gpg --version | head -n1 | awk '{print $3}')"
# Magic trick of version comparison using 'sort -V'
# supplied version-in-question must get sorted toward the bottom (or past)
# the acceptable GPG version
PASSED_MIN_GPG_VERSION="$(echo "$GPG_VERSION
$MIN_GPG_VERSION" | sort -V -b | head -n1)"
if [ "$MIN_GPG_VERSION" != "$PASSED_MIN_GPG_VERSION" ]; then
  echo "GPG version is too old. Aborted."
  exit 2
fi
echo "Passed minimum GPG $MIN_GPG_VERSION version check."


ETC_GNUPG_GPGCONF_CONF_FILENAME="gpgconf.conf"
ETC_GNUPG_GPGCONF_CONF_DIRPATH="/etc/gnupg"
ETC_GNUPG_GPGCONF_CONF_FILESPEC="$ETC_GNUPG_GPGCONF_CONF_DIRPATH/$ETC_GNUPG_GPGCONF_CONF_FILENAME"

# Check if directory exist
if [ ! -d "$ETC_GNUPG_GPGCONF_CONF_DIRPATH" ]; then
  sudo mkdir "$ETC_GNUPG_GPGCONF_CONF_DIRPATH"
fi

# Override file permission settings
sudo chmod 0755 "$ETC_GNUPG_GPGCONF_CONF_DIRPATH"
ROOT_GROUP="`id -g -n root`"
sudo chown root:${ROOT_GROUP} "$ETC_GNUPG_GPGCONF_CONF_DIRPATH"

# Drop some settings into /etc/gnupg/gpgconf.conf
echo ""
echo "Creating global GPG settings for all users..."
cat << GPG_EOF | sudo tee -p "$ETC_GNUPG_GPGCONF_CONF_FILESPEC" >/dev/null 2>&1
#
# File: $ETC_GNUPG_GPGCONF_CONF_FILENAME
# Path: $ETC_GNUPG_GPGCONF_CONF_DIRPATH
# Title: Global GPG configuration settings file
# Creator: $(basename "$0")
# Date: $(date)
#

# GPG (gpg) component #######################################################
* gpg max-cert-depth [no-change] 5

# default-new-key-algo option can be used to change the default algorithms for
# key generation.  The string is similiar to the arguments required for the
# command --add-quick-key but slightly different.  For example, the current
# default of "rsa2048/cert,sign+rsa2048/encr" (or "rsa3072") can be changed to
# the value of what we currently call future default, which is
# "ed25519/cert,sign+cv25519/encr".  You need to consult the source code to
# learn the details.  Note that the advanced key generation commands can always
# be used to specify a key algorithm directly.

* gpg default-new-key-algo [change] ed25519/cert,sign+cv25519/encr

* gpg trust-model [change] pgp


# GPG-AGENT (gpg-agent) component #############################################

# This 'ignore-cache-for-signing' option will let gpg-agent bypass the
# passphrase cache for all signing operation.  Note that there is also a
# per-session option to control this behavior but this command line option takes
# precedence.

* gpg-agent ignore-cache-for-signing [no-change] 0


# Enforce the passphrase constraints by not allowing the user to bypass them
# using the "Take it anyway" button

# Remove user's settings
* gpg-agent enforce-passphrase-constraints [default]
* gpg-agent enforce-passphrase-constraints [no-change]


# Set the maximum time a cache entry used for SSH keys is valid to n seconds.
# After this time a cache entry will be expired even if it has been accessed
# recently or has been set using gpg-preset-passphrase.  The default is 2 hours
# (7200 seconds).

* gpg-agent default-cache-ttl [change] 1800


# Set the time a cache entry is valid to n seconds.  The default is 600 seconds.
# Each time a cache entry is accessed, the entry's timer is reset.  To set an
# entry's maximum lifetime, use max-cache-ttl.  Note that a cached passphrase
# may not be evicted immediately from memory if no client requests a cache
# operation.  This is due to an internal housekeeping function which is only run
# every few seconds.

* gpg-agent max-cache-ttl [change] 7200

* gpg-agent min-passphrase-len [no-change] 10
* gpg-agent min-passphrase-nonalpha [change] 0

* keyserver <fill-in-key-server>
keyserver 127.0.0.1


GPG_EOF
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Error writing to $ETC_GNUPG_GPGCONF_CONF_FILESPEC. Errcode: $retsts"
  exit $retsts
fi
echo "File $ETC_GNUPG_GPGCONF_CONF_FILESPEC created."
echo 
echo "Changing file permission for ${ETC_GNUPG_GPGCONF_CONF_FILESPEC} ..."
sudo chmod 0644 "${ETC_GNUPG_GPGCONF_CONF_FILESPEC}"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Error changing file permission on $ETC_GNUPG_GPGCONF_CONF_FILESPEC. Errcode: $retsts"
  exit $retsts
fi
sudo chown root:${ROOT_GROUP} "${ETC_GNUPG_GPGCONF_CONF_FILESPEC}"
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Error changing owner:group on $ETC_GNUPG_GPGCONF_CONF_FILESPEC. Errcode: $retsts"
  exit $retsts
fi
echo ""
echo "Done."
exit 0

