#!/bin/bash
# File: 511-dns-bind9-service-default.sh
# Title: Service default startup setting for Bind9
# Description:
#
# Prerequisites:
#   - RNDC_PORT - Port number for Remote Name Daemon Control (rndc)
#   - RNDC_CONF - rndc configuration file
#   - INSTANCE_NAME - Bind9 instance name, if any
#

source dns-bind9-common.sh

function create_sysv_default() {

  # Make it work for both 'rndc.conf' and 'rndc-public.conf', et. al.
  # /etc/default/bind9
  # /etc/default/bind9-default
  # /etc/default/bind9-public
  BIND_INIT_DEFAULT_FILESPEC="$INIT_DEFAULT_DIRSPEC/$BIND_SERVICE_FILENAME"

  # build/etc/default
  flex_mkdir "$INIT_DEFAULT_DIRSPEC"

  echo "Creating $BIND_INIT_DEFAULT_FILESPEC"
  cat << EOF | tee "${BUILDROOT}${CHROOT_DIR}$BIND_INIT_DEFAULT_FILESPEC" >/dev/null
#
# File: ${BIND_SERVICE_FILENAME}
# Path: ${INIT_DEFAULT_DIRSPEC}
# Title: Bind9 configuration for SysV/systemd service startup
# Description:
#   Service startup init settings
#     OPTIONS -      passthru CLI options for 'named' daemon
#     RNDC_OPTIONS - passthru CLI options for 'rndc' utility
#                    cannot use -p option (use RNDC_PORT)
#                    cannot use -c option (uses /etc/bind/named-%I.conf)
#     RNDC_PORT - Port number
#
#     RESOLVCONF - Do a one-shot resolv.conf setup. 'yes' or 'no'
#           Only used in SysV/s6/OpenRC/ConMan; Ignored by systemd.

RESOLVCONF=no

# Fork all subsequential daemons as 'bind' user.
OPTIONS="-u bind"

# the "rndc.conf" should have all its server, key, port, and IP address defined
RNDC_OPTIONS="-c $RNDC_CONF"

# There may be other settings in a unit-instance-specific default
# file such as /etc/default/bind9-public.conf or
# /etc/default/bind9-dmz.conf.
EOF
}


create_sysv_default

echo ""
echo "Done."
exit 0

