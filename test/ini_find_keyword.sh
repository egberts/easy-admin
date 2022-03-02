#!/bin/bash
#
# Title: Parse an INI file
# Description:
#
# Design:
#   * must be secured (no 'eval' statement)
#   * no array storage (due to aliasing of 'echo' and 'rm' statement)
#   * no new variable definition for sections nor keywords
#   * must be 'source'able with minimal declarations of its global variables
#     * global variable names must be prefixed uniquely with 'ini_'?
#     * function names must be prefixed uniquely with 'ini_'?
#
# Understandably, the .INI file MAY get read each time a function 
# gets evoked.  
#
# Perhaps, the entire .INI file could be pre-stored as-is 
# in a variable/array then subsequentially function/API' into this?
#
# For now, it is stored in a list/array
#
# 


if [ -n "$UNITTEST" ]; then
  # temp_file="$(mktemp "/tmp/unittest_$(basename ${0})-XXXX.tmp")"
  temp_file="/tmp/unittest.ini-file-parser"
  cat << TEST_EOF | tee "$temp_file"
#
varBeforeDefault=1
more_var_before_default=2
# DNS=1.1.1.1

[Resolve]
DNS=    # inline comment
#DNS=2.2.2.2
FallbackDNS=8.8.8.8    # inline comment2

[Notaresolve]
DNS=8.8.8.8
FallbackDNS=

TEST_EOF
  # source ini-file-parser.sh
  process_ini_file "$temp_file"
  echo "Result-DNS is: $(get_value 'Resolve' 'DNS')"
  echo "default varBeforeDefault is: $default_varBeforeDefault"
  echo "default DNS is: $default_DNS"  # should be commented out
  echo "Resolve DNS is: $(get_value 'Resolve' 'DNS') # should be empty"
  echo "Resolve DNS is: $Resolve_DNS # should be empty"
  echo "'Notaresolve' DNS is: $(get_value 'Notaresolve' 'DNS') # should be 8.8.8.8"
  echo "Resolve FallbackDNS is: $(get_value 'Resolve' 'FallbackDNS') # should be 8.8.8.8"
fi
