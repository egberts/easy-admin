#!/bin/bash
# File: 415-net-dhclient-debug.sh
# Title: Debug the DHCP hook routines
# Description:
#
#

echo "Add debug hooks to the DHCLIENT enter/exit hooks"
echo

source ./maintainer-dhcp-client-isc.sh
readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-dhclient-hooks-debug.sh"


# Do not create any directory in existing filesystem
if [ -n "$BUILDROOT" -a "${BUILDROOT:0:1}" != '/' ]; then
  if [ ! -d "$BUILDROOT" ]; then
    mkdir $BUILDROOT
  fi
fi

flex_ckdir "$ETC_DIRSPEC"
flex_ckdir "$ETC_DHCP_DIRSPEC"

flex_ckdir "$VAR_DIRSPEC"
flex_ckdir "$VAR_LIB_DIRSPEC"

flex_mkdir "$VAR_LIB_DHCP_DIRSPEC"
flex_chmod 0750 "$VAR_LIB_DHCP_DIRSPEC"
flex_chown "root:$GROUP_NAME" "$VAR_LIB_DHCP_DIRSPEC"

flex_mkdir "$ENTER_HOOKS_DIRSPEC"
flex_chmod 0750 "$ENTER_HOOKS_DIRSPEC"
flex_chown "root:$GROUP_NAME" "$ENTER_HOOKS_DIRSPEC"

flex_mkdir "$EXIT_HOOKS_DIRSPEC"
flex_chmod 0750 "$EXIT_HOOKS_DIRSPEC"
flex_chown "root:$GROUP_NAME" "$EXIT_HOOKS_DIRSPEC"

# ISC DHCP client hook routines do not need ".sh" filetype
hook_debug_filename="debug-my-env-vars"

# Exit hook routine
hook_exit_debug_filespec="${EXIT_HOOKS_DIRSPEC}/$hook_debug_filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$hook_exit_debug_filespec ..."
cat << DHCLIENT_HOOK_DEBUG_EOF | tee "${BUILDROOT}${CHROOT_DIR}${hook_exit_debug_filespec}" > /dev/null
#
# File: ${hook_exit_debug_filespec}
# Path: ${EXIT_HOOKS_DIRSPEC}
# Title: Debug environment variables within DHCP client enter/exit hooks
# Generated by: $(basename $0)
# Created on: $(date)
# Description:
#
# The purpose of this script is just to show the variables that are
# available to all the scripts in this directory. All these scripts are
# called from dhclient-script, which exports all the variables shown
# before. If you want to debug a problem with your DHCP setup you can
# enable this script and take a look at /tmp/dhclient-script.debug.

# To enable this script set the following variable to "yes"
RUN_ME='yes'

LOG_LEVEL=info


# Not commonly changed settings beyond this point here
LOG_FACILITY=daemon

# DHCP client script hanlders passes script name in \$1, check for that
# otherwise fallback to \$0 for its script-name
if [ -z "\$1" ]; then
  REAL_CMD=\$(realpath -L "\$0")
else
  REAL_CMD="\$1"
fi
CMD_FILENAME=\$(basename "\$REAL_CMD")
CMD_FILEPATH=\$(dirname "\$REAL_CMD")
CMD_FILEPATH_SHORT=\$(basename "\$CMD_FILEPATH")
CMD_FILESPEC="\${CMD_FILEPATH}/\$CMD_FILENAME"
LOGGER_PRIORITY="\${LOG_FACILITY}.\$LOG_LEVEL"
# Catch any sudo user reporting a semi-anonymous 'root' message
if [ ! -z "\$SUDO_USER" ]; then
  THIS_USER="\$SUDO_USER"
elif [ ! -z "\$USER" ]; then
  THIS_USER="\$USER"
else
  THIS_USER='dhclient'
fi
LOGGER="logger -t"\${THIS_USER}:\${CMD_FILEPATH_SHORT}/\$CMD_FILENAME" --priority \$LOGGER_PRIORITY"

$LOGGER "start: writing reason: \$reason p1: \$1 p2: \$2 p3: \$3"

# Dynamic output filename
DEBUG_OUTPUT="/tmp/dhclient-debug-\${interface}-\${reason}.log"

if [ "yes" = "\${RUN_ME}" ]; then
    echo "entering \${1%/*}, dumping variables." >> "\$DEBUG_OUTPUT"

    # loop over the 4 possible prefixes: (empty), cur_, new_, old_
    for prefix in '' 'cur_' 'new_' 'old_'; do
        # loop over the DHCP variables passed to dhclient-script
        for basevar in 1 2 3 4 5 \\
                               reason interface medium alias_ip_address \\
                   ip_address host_name network_number subnet_mask \\
                   broadcast_address routers static_routes \\
                   rfc3442_classless_static_routes \\
                   domain_name domain_search domain_name_servers \\
                   netbios_name_servers netbios_scope \\
                   ntp_servers \\
                   ip6_address ip6_prefix ip6_prefixlen \\
                   dhcp6_domain_search dhcp6_name_servers \\
                               dhcp6_server_id alias_ip_address ; do
            var="\${prefix}\${basevar}"
            eval "content=\\\$\$var"

            # show only variables with values set
            if [ -n "\${content}" ]; then
                # Save in a file
                echo "\$var='\${content}'" >> "\$DEBUG_OUTPUT"
                # Log it via syslog
                \$LOGGER "\$var='\${content}'"
            fi
        done
    done

    echo '--------------------------' >> "\$DEBUG_OUTPUT"
fi

DHCLIENT_HOOK_DEBUG_EOF
echo

# ISC DHCP client hook routines do not need hashbang '#!/bin/bash' in 1st line
# ISC DHCP client hook routines do not need executable bit set
flex_chmod 0640 "${hook_exit_debug_filespec}"
if [ -n "$GROUP_NAME" ]; then
  flex_chown "root:$GROUP_NAME" "$hook_exit_debug_filespec"
fi


# Enter hook routine
hook_enter_debug_filespec="${ENTER_HOOKS_DIRSPEC}/$hook_debug_filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$hook_enter_debug_filespec ..."
cat << DHCLIENT_HOOK_DEBUG_EOF | tee "${BUILDROOT}${CHROOT_DIR}$hook_enter_debug_filespec" > /dev/null
#
# File: ${hook_enter_debug_filespec}
# Path: ${EXIT_HOOKS_DIRSPEC}
# Title: Debug environment variables within DHCP client enter/exit hooks
# Description:
# Generated by: $(basename $0)
# Created on: $(date)
#
# The purpose of this script is just to show the variables that are
# available to all the scripts in this directory. All these scripts are
# called from dhclient-script, which exports all the variables shown
# before. If you want to debug a problem with your DHCP setup you can
# enable this script and take a look at /tmp/dhclient-script.debug.

# To enable this script set the following variable to "yes"
RUN_ME='yes'

LOG_LEVEL=info


# Not commonly changed settings beyond this point here
LOG_FACILITY=daemon

# DHCP client script hanlders passes script name in \$1, check for that
# otherwise fallback to \$0 for its script-name
if [ -z "\$1" ]; then
  REAL_CMD=\$(realpath -L "\$0")
else
  REAL_CMD="\$1"
fi
CMD_FILENAME=\$(basename "\$REAL_CMD")
CMD_FILEPATH=\$(dirname "\$REAL_CMD")
CMD_FILEPATH_SHORT=\$(basename "\$CMD_FILEPATH")
CMD_FILESPEC="\${CMD_FILEPATH}/\$CMD_FILENAME"
LOGGER_PRIORITY="\${LOG_FACILITY}.\$LOG_LEVEL"
# Catch any sudo user reporting a semi-anonymous 'root' message
if [ ! -z "\$SUDO_USER" ]; then
  THIS_USER="\$SUDO_USER"
elif [ ! -z "\$USER" ]; then
  THIS_USER="\$USER"
else
  THIS_USER='dhclient'
fi
LOGGER="logger -t"\${THIS_USER}:\${CMD_FILEPATH_SHORT}/\$CMD_FILENAME" --priority \$LOGGER_PRIORITY"

$LOGGER "start: writing reason: \$reason p1: \$1 p2: \$2 p3: \$3"

# Dynamic output filename
DEBUG_OUTPUT="/tmp/dhclient-debug-\${interface}-\${reason}.log"

if [ "yes" = "\${RUN_ME}" ]; then
    echo "entering \${1%/*}, dumping variables." >> "\$DEBUG_OUTPUT"

    # loop over the 4 possible prefixes: (empty), cur_, new_, old_
    for prefix in '' 'cur_' 'new_' 'old_'; do
        # loop over the DHCP variables passed to dhclient-script
        for basevar in 1 2 3 4 5 \\
                               reason interface medium alias_ip_address \\
                   ip_address host_name network_number subnet_mask \\
                   broadcast_address routers static_routes \\
                   rfc3442_classless_static_routes \\
                   domain_name domain_search domain_name_servers \\
                   netbios_name_servers netbios_scope \\
                   ntp_servers \\
                   ip6_address ip6_prefix ip6_prefixlen \\
                   dhcp6_domain_search dhcp6_name_servers \\
                               dhcp6_server_id alias_ip_address ; do
            var="\${prefix}\${basevar}"
            eval "content=\\\$\$var"

            # show only variables with values set
            if [ -n "\${content}" ]; then
                # Save in a file
                echo "\$var='\${content}'" >> "\$DEBUG_OUTPUT"
                # Log it via syslog
                \$LOGGER "\$var='\${content}'"
            fi
        done
    done

    echo '--------------------------' >> "\$DEBUG_OUTPUT"
fi

DHCLIENT_HOOK_DEBUG_EOF
echo

# ISC DHCP client hook routines do not need hashbang '#!/bin/bash' in 1st line
# ISC DHCP client hook routines do not need executable bit set
flex_chmod 0640 "${hook_enter_debug_filespec}"
if [ -n "$GROUP_NAME" ]; then
  flex_chown "root:$GROUP_NAME" "$hook_enter_debug_filespec"
fi

# do not call shell 'exit' here,
# as this 'exit' here will kill later chaining of DHCP client hooked scripts
echo "Done."
