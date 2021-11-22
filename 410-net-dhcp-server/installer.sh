#
# File: installer.sh
# Title: Create an install script that handles file permissions

function flex_mkdir() {
  if [ $UID -eq 0 ]; then
    # NO '-p' option in root-mode, script MUST make each subdir manually
    mkdir "${BUILDROOT}${CHROOT_DIR}${1}"
  else
    # It is probably the user's build area, make all parent directories
    # Do nothing with build area, this is portable script building
    mkdir -p "${BUILDROOT}${CHROOT_DIR}${1}"
    DESTDIR_FILESPEC="${CHROOT_DIR}${1}"
    if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
      echo "mkdir -p $DESTDIR_FILESPEC" >> "$FILE_SETTINGS_FILESPEC"
    else
      echo "\$dry-run: mkdir $DESTDIR_FILESPEC"
    fi
  fi
}

function flex_chown() {
  # Is current user 'root'?
  if [ $UID -eq 0 ]; then
    # Sure go ahead and set the file permission, even in build areas
    chown "$1" "${BUILDROOT}${CHROOT_DIR}$2"
  else
    # Do nothing with build area, this is portable script building
    DESTDIR_FILESPEC="${CHROOT_DIR}${2}"
    if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
      echo "chown $1 $DESTDIR_FILESPEC" >> "$FILE_SETTINGS_FILESPEC"
    else
      echo "\$dry-run: chown $1 $DESTDIR_FILESPEC"
    fi
  fi
}

function flex_chmod() {
  # Is current user 'root'?
  if [ $UID -eq 0 ]; then
    # Sure go ahead and set the file permission, even in build areas
    chmod "$1" "${BUILDROOT}${CHROOT_DIR}$2"
  else
    # Do nothing with build area, this is portable script building
    DESTDIR_FILESPEC="${CHROOT_DIR}${2}"
    if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
      echo "chown $1 $DESTDIR_FILESPEC" >> "$FILE_SETTINGS_FILESPEC"
    else
      echo "\$dry-run chown $1 $DESTDIR_FILESPEC"
    fi
  fi
}

function flex_touch() {
  if [ $UID -eq 0 ]; then
    touch "$1"
  fi
  # Do nothing with build area, this is only for portable script building
}


