#!/bin/sh

#  ini_buffer="$(echo "$1" | awk '/^\[.*\]$/{obj=$0}/=/{gsub(/^[ \t]+|[ \t]+$/, ""); print obj $0}')"

echo  '/^\[.*\]$/{obj=$0}/=/{gsub(/^\[[ \t]*/, "["); gsub(/[ \t]*\]/, "]"); print obj $0}'  > /tmp/xyzz
echo "[     prefixed_space    ]DNS=" > /tmp/test-xyzz
gawk -D -f /tmp/xyzz  /tmp/test-xyzz