#!/bin/bash
# File: 080-gnupg-setup.sh
# Title: GNU Pretty Good Privacy setup for maintainers of packages.
#
# Design
#   install gnupg2 package, if needed
# watchgnupg
#

# Set the maximum time a cache entry used for SSH keys is valid to n seconds.
# After this time a cache entry will be expired even if it has been accessed
# recently or has been set using gpg-preset-passphrase.  The default is 2 hours
# (7200 seconds).
GPG_AGENT_MAX_CACHE_TTL=7200

# Set the time a cache entry is valid to n seconds.  The default is 600 seconds.
# Each time a cache entry is accessed, the entry's timer is reset.  To set an
# entry's maximum lifetime, use max-cache-ttl.  Note that a cached passphrase
# may not be evicted immediately from memory if no client requests a cache
# operation.  This is due to an internal housekeeping function which is only run
# every few seconds.
GPG_AGENT_DEFAULT_CACHE_TTL=1800

DROPIN_FILENAME="gpg-agent.bash"

echo "GNU Pretty Good Privacy (gpg) setup for maintianers of packages."
echo ""

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
  retsts=$?
  if [ $retsts -eq 0 ]; then
    migrate-pubring-from-classic-gpg --default
  fi
fi

GPGCONF="gpgconf"
GPGCONF_BIN="$(whereis -b $GPGCONF|awk -F: '{print $2}'|awk '{print $1}')"
if [ -z "$GPGCONF_BIN" ]; then
  echo "GNU migrate-pubring-from-classic-gpg is not installed"
  # gpgconf, makes it easier to view GPG settings and make any safer changes
  sudo apt install gnupg-utils gpgconf
  if [ -n "$MIGRATE_BIN" ]; then
    migrate-pubring-from-classic-gpg --default
  fi
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

USER_NAME="$USER"
GROUP_NAME="$(id -g -n "$USER" )"

# Ensure that file ~/.gnupg/gpg-agent.conf exists before going any further
DOT_GNUPG_DIRNAME=".gnupg"
DOT_GNUPG_DIRPATH="$HOME/$DOT_GNUPG_DIRNAME"
if [ ! -d "$DOT_GNUPG_DIRPATH" ]; then
  echo "Creating $DOT_GNUPG_DIRPATH directory..."
  chmod 0700 "$DOT_GNUPG_DIRPATH"
  chown "${USER_NAME}:${GROUP_NAME}" "$DOT_GNUPG_DIRPATH"
  mkdir "$DOT_GNUPG_DIRPATH"
fi

# Check permission or bail
if [ "$(stat -c %a "$DOT_GNUPG_DIRPATH")" != "700" ]; then
  echo "File permission of $DOT_GNUPG_DIRPATH directory is not SAFE!"
  ls -lat "$DOT_GNUPG_DIRPATH"
  exit 6
fi

GPG_CONF_FILENAME="gpg.conf"
GPG_CONF_FILESPEC="$DOT_GNUPG_DIRPATH/$GPG_CONF_FILENAME"
if [ -f "$GPG_CONF_FILESPEC" ]; then
  touch "$GPG_CONF_FILESPEC"
  chmod 0600 "$GPG_CONF_FILESPEC"
  chown "${USER_NAME}:${GROUP_NAME}" "$GPG_CONF_FILESPEC"
  GPG_CONF_APPEND="-a"
  echo "Appending to $GPG_CONF_FILESPEC config file..."
else
  echo "File $GPG_CONF_FILESPEC is missing, creating..."
fi

# Check permission or bail
if [ "$(stat -c %a "$GPG_CONF_FILESPEC")" != "600" ]; then
  echo "File permission of $GPG_CONF_FILESPEC file was not SAFE; adjusted."
  chmod 0600 "$GPG_CONF_FILESPEC"
fi

# Drop some settings into ~/.gnupg/gpg-agent.conf
cat << GPG_EOF | tee -p "$GPG_CONF_APPEND" "$GPG_CONF_FILESPEC" >/dev/null 2>&1
#
# File: gpg.conf
# Path: ~/.gnupg
# Title: GPG configuration file
# Creator: $(basename "$0")
# Date: $(date)
#
utf8-strings

# verbose

# debug-level 5

max-cert-depth 5

#
# default-new-key-algo option can be used to change the default algorithms for
# key generation.  The string is similiar to the arguments required for the
# command --add-quick-key but slightly different.  For example, the current
# default of "rsa2048/cert,sign+rsa2048/encr" (or "rsa3072") can be changed to
# the value of what we currently call future default, which is
# "ed25519/cert,sign+cv25519/encr".  You need to consult the source code to
# learn the details.  Note that the advanced key generation commands can always
# be used to specify a key algorithm directly.

# default-new-key-algo "rsa2048/cert,sign+rsa2048/encr"  # old default
default-new-key-algo "ed25519/cert,sign+cv25519/encr"

# trust-model "classic"
trust-model "pgp"

GPG_EOF
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Error writing to $GPG_CONF_FILESPEC. Errcode: $retsts"
  exit $retsts
fi
echo "File $GPG_CONF_FILESPEC created."

GPG_AGENT_CONF_FILENAME="gpg-agent.conf"
GPG_AGENT_CONF_FILESPEC="$DOT_GNUPG_DIRPATH/$GPG_AGENT_CONF_FILENAME"
if [ ! -f "$GPG_AGENT_CONF_FILESPEC" ]; then
  echo "File $GPG_AGENT_CONF_FILESPEC is missing, creating..."
  touch "$GPG_AGENT_CONF_FILESPEC"
  chmod 0600 "$GPG_AGENT_CONF_FILESPEC"
  chown "${USER_NAME}:${GROUP_NAME}" "$GPG_AGENT_CONF_FILESPEC"

  # Drop some settings into ~/.gnupg/gpg-agent.conf
  echo "Creating $GPG_AGENT_CONF_FILESPEC config file..."
  echo "GPG Agent Default Cache TTL: $GPG_AGENT_DEFAULT_CACHE_TTL"
  echo "GPG Agent Maximum Cache TTL: $GPG_AGENT_MAX_CACHE_TTL"
  cat << GPG_AGENT_EOF | tee "$GPG_AGENT_CONF_FILESPEC" >/dev/null 2>&1
#
# File: gpg-agent.conf
# Path: ~/.gnupg
# Title: GPG Agent configuration file
# Creator: $(basename "$0")
# Date: $(date)
#

# This 'ignore-cache-for-signing' option will let gpg-agent bypass the
# passphrase cache for all signing operation.  Note that there is also a
# per-session option to control this behavior but this command line option takes
# precedence.

ignore-cache-for-signing


# Enforce the passphrase constraints by not allowing the user to bypass them
# using the "Take it anyway" button

enforce-passphrase-constraints


# min-passphrase-len sets the minimal length of a passphrase.
# When entering a new passphrase shorter than this value
# a warning will be displayed. min-passphrase-len defaults to 8.

min-passphrase-len 10


# min-passphrase-nonalpha sets the minimum number of
# digits or special characters required in a passphrase.
# When entering in a new passphrase shorter than this
# value a warning will be displayed.
# min-passphrase-non-alpha defaults to 1.

min-passphrase-nonalpha 1


# Set the maximum time a cache entry used for SSH keys is valid to n seconds.
# After this time a cache entry will be expired even if it has been accessed
# recently or has been set using gpg-preset-passphrase.  The default is 2 hours
# (7200 seconds).

default-cache-ttl $GPG_AGENT_DEFAULT_CACHE_TTL

# Set the time a cache entry is valid to n seconds.  The default is 600 seconds.
# Each time a cache entry is accessed, the entry's timer is reset.  To set an
# entry's maximum lifetime, use max-cache-ttl.  Note that a cached passphrase
# may not be evicted immediately from memory if no client requests a cache
# operation.  This is due to an internal housekeeping function which is only run
# every few seconds.

max-cache-ttl $GPG_AGENT_MAX_CACHE_TTL


#
# ssh-fingerprint-digest selects the digest algorithm used to compute such
# ssh fingerprints that are communicated to the user, e.g. in pinentry dialogs.
# OpenSSH has transitioned from MD5 to the more secured SHA256.

ssh-fingerprint-digest SHA256

pinentry-timeout 60

GPG_AGENT_EOF
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    echo "Error writing to $GPG_AGENT_CONF_FILESPEC. Errcode: $retsts"
    exit $retsts
  fi
  echo "File $GPG_AGENT_CONF_FILESPEC created."
fi

# Refresh any existing keys
echo ""
echo "Refreshing GnuPG keys ..."
gpg --refresh >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 -a "$retsts" -ne 2 ]; then
  echo "Error refreshing GPG keyfile. Errcode: $retsts"
  exit $retsts
fi

echo ""
echo "Dropping in GPG-specific bash profile login script snippet."
#  Update bashrc via 'drop-in'
BASHRC_DROPIN_DIRNAME=".bashrc.d"
HOME_DIRPATH="$HOME"
BASHRC_DROPIN_DIRSPEC="$HOME_DIRPATH/$BASHRC_DROPIN_DIRNAME"
if [ ! -d "$BASHRC_DROPIN_DIRSPEC" ]; then
  echo "No $BASHRC_DROPIN_DIRSPEC directory found."
  # ~/.profile: executed by the command interpreter for login shells.
  # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
  # exists.
  BASH_PROFILE="$HOME/.bashrc"
  if [ ! -r "$BASH_PROFILE" ]; then
    echo "No $BASH_PROFILE found,"
    BASH_PROFILE="$HOME/.bash_profile"
    if [ ! -r "$BASH_PROFILE" ]; then
      echo "No $BASH_PROFILE found,"
      BASH_PROFILE="$HOME/.bash_login"
      if [ ! -r "$BASH_PROFILE" ]; then
        echo "No $BASH_PROFILE found,"
        BASH_PROFILE="$HOME/.profile"
        # No test, just use .profile anyway... (Strange shell environment)
      fi
    fi
  fi
  echo "Updating ${BASH_PROFILE}..."
  GPG_TTY_FOUND="$(grep -c GPG_TTY "${BASH_PROFILE}")"
  if [ "$GPG_TTY_FOUND" -eq 0 ]; then
    echo "Add the following to your ${BASH_PROFILE}:"
    echo "    export GPG_TTY=\"\$(tty)\""
  else
    echo "Already found GPG_TTY export in ${BASH_PROFILE}; no change done."
  fi
  echo ""
  echo "Done."
  exit 0
else
  echo "Found bashrc drop-in ($BASHRC_DROPIN_DIRSPEC) directory."
  # Try for '.bashrc.d/plugins'
  DROPIN_PLUGINS_DIRNAME="plugins"
  DROPIN_PLUGINS_DIRSPEC="$BASHRC_DROPIN_DIRSPEC/$DROPIN_PLUGINS_DIRNAME"
  if [ -d "$DROPIN_PLUGINS_DIRSPEC" ]; then
    echo "Found bashrc plugins drop-in ($DROPIN_PLUGINS_DIRSPEC) subdirectory."
    DROPIN_DIRPATH="$DROPIN_PLUGINS_DIRSPEC"
  else
    DROPIN_DIRPATH="$BASHRC_DROPIN_DIRSPEC"
  fi
fi
DROPIN_FILEPATH="$DROPIN_DIRPATH"
DROPIN_FILESPEC="$DROPIN_FILEPATH/$DROPIN_FILENAME"

echo "Creating $DROPIN_FILESPEC ..."
touch "$DROPIN_FILESPEC"
chmod a+rx "$DROPIN_FILESPEC"
exit
cat << DROPIN_EOF | sudo tee "$DROPIN_FILESPEC" >/dev/null 2>&1
#
# File: $DROPIN_FILENAME
# Path: $DROPIN_FILEPATH
# Title: .bashrc for GPG
# Creator: $(basename "$0")
# Date: $(date)
#

# Kill off any lingering ssh-agent for this user
trap 'test -n "\$SSH_AUTH_SOCK" && ssh-add -D && ssh-agent -k; rm \$HOME/.ssh/ssh_auth_sock; exit 0' 0

# Automatically start ssh-agent
if [ ! -S ~/.ssh/ssh_auth_sock ]; then
  eval \$(ssh-agent)
  ln -sf "\$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
ssh-add -l > /dev/null || ssh-add

DROPIN_EOF
echo ""
echo "Done."
exit 0

