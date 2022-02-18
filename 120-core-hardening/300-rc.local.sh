#!/bin/bash
# File: 300-rc.local.sh
# Title: RC local system startup bash script
# Description:
#
#  Until the kernel movement toward hardened-linux and kernel-hardened
#  is completed, we will require this rc.local script.
#
# Reference:
#  * https://blog.frehi.be/2019/01/30/linux-security-hardening-recommendations/
#
rc_local_filespec="/etc/rc.local"
proc_kallsyms_filespec="/proc/kallsyms"

echo "Ensure $rc_local_filespec exist."
echo
echo "Until movement toward kernel hardening is completed,"
echo "this rc local system startup bash script is required"
echo "to block read access to ${proc_kallsyms_filespec}."
echo
curmod="$(stat -c%a "${proc_kallsyms_filespec}")"
if [ "$curmod" == "400" ]; then
  echo "${proc_kallsyms_filespec} file is properly file-permission set."
  echo
  echo "Done."
  exit 0
fi

if [ $UID -ne 0 ]; then
  echo "Non-root user detected."
  echo "May be prompting you for 'sudo' password."
  SUDO_BIN="/usr/bin/sudo"
fi

if [ -a "$rc_local_filespec" ]; then
  echo "File '${rc_local_filespec}' exists."
  echo "Examing this file for any unwanted but persistent behavior"
  if [ $($SUDO_BIN grep -E -c "\s*chmod\s*[0]400\s*${proc_kallsyms_filespec}" "${rc_local_filespec}") -eq 0 ]; then
    echo "Insert in following file into '${rc_local_filespec}':"
    echo
    $SUDO_BIN bash echo "    chmod 0400 ${proc_kallsyms_filespec}" >> "${rc_local_filespec}"
  else
    echo "Found the 'chmod 400 ${proc_kallsyms_filespec}'."
    echo
    # echo "In file '${rc_local_filespec}', some wierd stuff is going on with"
    # echo "${proc_kallsyms_filespec}."
    # echo
    # echo "Check that 'chmod 400 ${proc_kallsyms_filespec}' is in the"
    # echo "${rc_local_filespec} file."
  fi
else
  echo "File '${rc_local_filespec}' does not exist."
  echo
  cat << RC_LOCAL_EOF | $SUDO_BIN tee "${rc_local_filespec}"
#!/bin/bash
# File: $(basename ${rc_local_filespec})
# Path: $(dirname ${rc_local_filespec})
# Title: RC local system startup bash script
# Description:
#
# References:
#  * https://blog.frehi.be/2019/01/30/linux-security-hardening-recommendations/
#

# Clamp down access to /proc/kallsyms
chmod 0400 ${proc_kallsyms_filespec}

RC_LOCAL_EOF
  chmod 0750 "$rc_local_filespec"
fi

curmod="$(stat -c%a "${rc_local_filespec}")"
if [ "$curmod" == "755" -o "$curmod" == "750" ]; then
  echo "${rc_local_filespec} file is properly file-permission set."
else
  echo "Please review ${rc_local_filespec} before enabling execution bit."
  echo
  echo "    chmod ug+x /etc/rc.local"
fi
echo

# No need to create rc.local.service file as the systemd's
# rc-local-generator.service will do that work for us for as
# long as that /etc/rc.local has an executable bit set.

# rclocal_systemd_unitname="rc-local.service"
# systemd_system_dirspec="/etc/systemd/system"
# rclocal_systemd_filespec="${systemd_system_dirspec}/$rclocal_systemd_unitname"
# echo "Checking if ${rc_local_filespec} is evoked at startup"
# if [ 0 -ne 0 ]; then
#   cat << RC_LOCAL_SERVICE_EOF | $SUDO_BIN tee "${rclocal_systemd_filespec}" >/dev/null
# [Unit]
#  Description=/etc/rc.local Compatibility
#  ConditionPathExists=/etc/rc.local
#
# [Service]
#  Type=forking
#  ExecStart=/etc/rc.local start
#  TimeoutSec=0
#  StandardOutput=tty
#  RemainAfterExit=yes
#  SysVStartPriority=99
#
# [Install]
#  WantedBy=multi-user.target
#
# RC_LOCAL_SERVICE_EOF

echo
echo "Done."
