
# File: easy-admin-installer.sh
# Title: Create an installer script that handles file permissions
# Description:
#
# Envvars:
#
#    BUILDROOT - scratch build area; if empty, it is an actual install
#    CHROOT_DIR - directory specification to a chroot area
#    FILE_SETTINGS_FILESPEC - output file containing bash file settings script
#
# shellcheck disable=SC2148


###############################################################
# Flexible mkdir()
# Description:
#   Make a directory
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with 
#                            file permission settings
# Arguments:
#   $1 - absolute directory specification
# Outputs:
#   none
################################################################
function flex_mkdir() {

  if [ "${1:0:1}" != "/" ]; then
    echo "flex_mkdir: argument '$1' must be an absolute directory path"
    exit 9
  fi
  destdir_dirspec="${CHROOT_DIR}${1}"

  # mkdir is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -n "${BUILDROOT}${CHROOT_DIR}" ] ||
     [ $UID -eq 0 ]; then

    if [ ! -d "${BUILDROOT}${CHROOT_DIR}$destdir_dirspec" ]; then
      echo "Creating ${BUILDROOT}${CHROOT_DIR}$destdir_dirspec directory ..."
      mkdir "${BUILDROOT}${CHROOT_DIR}$destdir_dirspec"
    fi
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "mkdir -p $destdir_dirspec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run: mkdir $destdir_dirspec"
  fi
  unset destdir_dirspec
}

###############################################################
# Flexible chown()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with 
#                            file permission settings
# Arguments:
#   $1 - chown file ownership options
#   $2 - absolute directory specification
# Outputs:
#   none
################################################################
function flex_chown() {

  destdir_filespec="$(realpath -m ${CHROOT_DIR}${2})"

  # chown is driven by no $BUILDROOT and 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
     [ "$UID" -eq 0 ]; then
    chown "$1" "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "chown $1 $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run: chown $1 $destdir_filespec"
  fi
  unset destdir_dirspec
}

###############################################################
# Flexible chmod()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with 
#                            file permission settings
# Arguments:
#   $1 - chmod file permission options
#   $2 - absolute directory specification
# Outputs:
#   none
################################################################
function flex_chmod() {

  destdir_filespec="$(realpath -m ${CHROOT_DIR}${2})"

  # chmod is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
     [ "$UID" -eq 0 ]; then

    echo "chmod $1 to ${BUILDROOT}${CHROOT_DIR}$destdir_filespec ..."
    chmod "$1" "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "chmod $1 $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run chmod $1 $destdir_filespec"
  fi
  unset destdir_dirspec
}

###############################################################
# Flexible touch()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with 
#                            file permission settings
# Arguments:
#   $1 - absolute directory specification
# Outputs:
#   none
################################################################

function flex_touch() {

  destdir_filespec="$(realpath -m ${CHROOT_DIR}${1})"

  # touch is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
     [ "$UID" -eq 0 ]; then

    echo "touching ${BUILDROOT}${CHROOT_DIR}$destdir_filespec file ..."
    touch "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "touch $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run touch $destdir_filespec"
  fi
}

###############################################################
# Flexible flex_chcon()
# Description:
#   if BUILDROOT is undefined, then mkdir is from the '/' or '$CHROOT_DIR'
# Globals:
#   BUILDROOT - if undefined or '/', then there is no build but a direct install
#   CHROOT_DIR - a full directory specification for chroot use.
#   FILE_SETTINGS_FILESPEC - if BUILDROOT then create script file with 
#                            file permission settings
# Arguments:
#   $1 - absolute directory specification
# Outputs:
#   none
################################################################

function flex_chcon() {

  destdir_filespec="$(realpath -m ${CHROOT_DIR}${2})"

  # chcon is driven by $BUILDROOT$CHROOT_DIR, or 'root' UID, or not at all
  if [ -z "${BUILDROOT}" ] &&
    [ "$UID" -eq 0 ]; then

    selinuxenabled
    retsts=$?
    if [ "$retsts" -eq 0 ]; then

      echo "chmcon system_u:object_r:$1:s0 to ${BUILDROOT}${CHROOT_DIR}$destdir_filespec ..."
      chmod "$1" "${BUILDROOT}${CHROOT_DIR}$destdir_filespec"
      chcon "system_u:object_r:${1}:s0" "$FILESPEC"
    fi
  fi

  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    echo "chcon $1 $destdir_filespec" >> "$FILE_SETTINGS_FILESPEC"
  else
    echo "\$dry-run chcon $1 $destdir_filespec"
  fi
  unset destdir_dirspec
}


