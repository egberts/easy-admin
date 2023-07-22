#!/bin/bash
# File: 509-dns-bind9-tmpdir.sh
# Title: Create temporary directory under '/run'
# Description:
#   Drop one new tmpfiles.d conf file:
#      var-run-named.conf
#
# Prerequisites:
#
# Env varnames
#   - BUILDROOT - '/' for direct installation, otherwise create 'build' subdir
#   - INSTANCE - Bind9 instance name, if any
#

echo "Creating a temporary directory under '/run' for ISC Bind 'named'"
echo

source ./maintainer-dns-isc.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-bind9-tmpdir${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
  FILE_SETTING_PERFORM=true
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old bind/named settings"
  # Only the first copy is saved as the backup
else
  FILE_SETTING_PERFORM=false
  # relative BUILDROOT directory path
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"
  echo "Creating subdirectories to $BUILDROOT$CHROOT_DIR$sysconfdir ..."
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$sysconfdir"

  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
  # shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for ISC Bind9 client"; \
  } >> "$FILE_SETTINGS_FILESPEC"
fi

ETC_TMPFILESD_DIRSPEC="/etc/tmpfiles.d"

if [ ! -d "$ETC_TMPFILESD_DIRSPEC" ]; then
  echo "systemd-tmpfiles is not installed. Aborted."
  flex_mkdir "$VAR_RUN_NAMED_DIRSPEC"
  exit 1
fi
flex_ckdir "$ETC_TMPFILESD_DIRSPEC"


FILENAME="var-run-${systemd_unitname}.conf"
FILESPEC=${ETC_TMPFILESD_DIRSPEC}/${FILENAME}
echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC..."
cat << BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${ETC_TMPFILESD_DIRSPEC}
# Title: Create /run/named subdir using tmpfiles.d setting 
# Creator: $(basename "$0")
# Created on: $(date)
# Description:
#

#Type Path             Mode User         Group        Age Argument
d  /run/named          0750 ${USER_NAME} ${GROUP_NAME}  - -

# We can then create a separate subdirectories for instantiation
# in a separate /etc/tmpfiles.d/var-run-named-<instance>.conf file.
#
# Might have instantiation-specific settings like:
d  /run/named/public    750 bind bind  - -
d  /run/named/internal  750 bind bind  - -
d  /run/named/root  750 bind bind  - -

BIND_EOF
flex_chown "root:root" "$FILESPEC"
flex_chmod "0644"      "$FILESPEC"

if [ "$FILE_SETTING_PERFORM" == "true" ] \
   || [ "$UID" -eq 0 ]; then
  echo "Activating $FILESPEC tmpfile subdirectory ..."
  systemd-tmpfiles "$FILESPEC" --create
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error in $FILESPEC tmpdir; errno ${retsts}; aborted."
    exit $retsts
  fi
fi
echo
echo "Done."
