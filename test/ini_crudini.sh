#!/bin/bash
#
# Interface synopsis:
# crudini --set [--existing] config_file section [param] [value]
#         --get [--format=sh|ini|lines] config_file [section] [param]
#         --del [--existing] config_file section [param] [list value]
#         --merge [--existing] config_file [section]
# Repo: http://www.pixelbeat.org/programs/crudini/
#
#  Example usage of 'crudini'
#  Capability:
#    get section
#    get keyword
#    get keyvalue
#    Append
#    file interactive
#    variable interaction
#    array support
#    

conf=/etc/puppet/puppet.conf
crudini --set "$conf" agent server "$PUPPET_MASTER_TCP_HOST"
crudini --set "$conf" agent masterport "$PUPPET_MASTER_TCP_PORT"

or a single atomic invocation like:

echo "
[agent]
server=$1
masterport=$2" |

