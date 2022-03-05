#!/bin/bash

# Find the keyword in a specified section name

# Read each file
# 


function find_include_clauses()
{
# find 'include' clauses
  local val
  echo "INFO: May prompt for sudo to perform protected read-only activities"
  echo "Begin scanning for 'include' clauses..."
  val="$( \
        cat "$NAMED_CONF_FILESPEC" | \
        grep -E -- "^\s*[\s\{]*\s*include\s*" \
	)"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  val="$(echo "$val" | xargs)"
  CONFIG_VALUE="$val"
  unset val
}

# Find the 'keyvalue' using its 'section' name and keyword
# This function is useful in extracting B from string "A B", "A B;" or "{ A B;".
function get_keyvalue_by_section_keyword
{
  local val
  local filespec
  keyword="$1"
  filespec="$2"
  echo "Scanning for '$1' ..."
  val="$(echo "$filespec" | grep -E -- "^\s*[\s\{]*\s*${1}\s*")"
  val="$(echo "$val" | awk '{print $2}' | tr -d ';')"
  val="${val//\"/}"
  CONFIG_VALUE="$val"
  unset val
  unset filespec
}

# Searchs multi-line for 'file' statement within its clause block of statements
# of all requested zone/channel clause
function find_file_statement()
{
  local regex_file_statements zone_idx_tmp=$1 t=$2 tmp_fidx=0 zone_files_list=""
  regex_file_statements='[^file]file[\n[:space:]]*"([a-zA-Z0-9\_\-\/\.]{1,64})"[\n[:space:]]*;[\n[:space:]]'

  # Don't while loop this one, we are grabbing first 'file' in 'zone'
  # TODO: Must while loop this one, we are grabbing the last 'file' in 'zone'
  # named-checkconf will error out if multiple 'file' statements are found
  # echo "regex_file_statements: '$regex_file_statements'"
  if [[ $t =~ $regex_file_statements ]]; then

    # BASH_REMATCH is a bash internal variable to [[ regex ]]
    add_file="${BASH_REMATCH[1]}"
    t=${t#*"${BASH_REMATCH[0]}"}
    t=${t#*"${BASH_REMATCH[1]}"}
    t=${t#*"${BASH_REMATCH[2]}"}
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      return
    fi
    # echo "BASH_REMATCH: ${BASH_REMATCH[@]}"
    # echo "Zone file: ${BASH_REMATCH[1]}"
    zone_files_list="$zone_files_list $add_file"
    ((tmp_fidx+=1))
  fi
  # echo "zone_idx_tmp: ${zone_idx_tmp}"
  zone_file_statements_A[$zone_idx_tmp]="$zone_files_list"
  unset regex_file_statements t tmp_fidx zone_files_list zone_idx_tmp
}

# syntax: find_section "<entire_ini_file_content_in_a_string>" "<section>"
# s=$1 - entire INI file content in a string variable
# section=$2 - section name to find
find_section()
{
  section="$2"
  ZONE_IDX=0
  zone_clauses_A=()
  local s="$1" named_conf_by_zone_a=()
  regex_x="[^${section}]"
  # If you added any more pairs of (), you must add BASH_REMATCH[n+1] below
  regex_zone_clauses='[^zone]*zone[\n[:space:]]*"(\S{1,80})"[\n[:space:]]*\S{0,6}[\n[:space:]]*(\{[\n[:space:]]*)[^zone]*'
  # echo "find_zone_clauses: called"
  while [[ $s =~ $regex_zone_clauses ]]; do
    # echo "RegedRegexRegexRegexRegexRegexRegexRegex"
    # echo "'$regex_zone_clauses'"
    # echo "+++++++++++++++++++++++++++++++++++++++"
    # echo "s: '$s'"
    # echo "---------------------------------------"
    # echo "ZONE_IDX: '$ZONE_IDX'"
    # echo "BASH_REMATCH[0]: ${BASH_REMATCH[0]} "
    # echo "Found Zone name: ${BASH_REMATCH[1]} idx: $ZONE_IDX"
    # echo "BASH_REMATCH[2]: ${BASH_REMATCH[2]} "
    zone_clauses_A[$ZONE_IDX]="$(echo "${BASH_REMATCH[1]}" | xargs)"
    # BASH_REMATCH is a bash internal variable to [[ regex ]]
    s=${s#*"${BASH_REMATCH[0]}"}
    named_conf_by_zone_a[$ZONE_IDX]="$s" # echo "$s" | xargs )"
    s=${s#*"${BASH_REMATCH[1]}"}
    # echo "s(1): $s"
    #s=${s#*"${BASH_REMATCH[2]}"}
    ## echo "s(2): $s"
    ((ZONE_IDX+=1))
    if [[ -z "${BASH_REMATCH[1]}" ]]; then
      break
    fi
    # if zone clause but no file statement; DNS server is a forwarder
  done
  idx=0
  while [ "$idx" -lt "$ZONE_IDX" ]; do
    # echo "find_file_statement $idx '${named_conf_by_zone_a[$idx]}'"
    find_file_statement $idx "${named_conf_by_zone_a[$idx]}"
    ((idx+=1))
  done
  unset named_conf_by_zone_a s
  unset regex_file_statements regex_zone_clauses
}


if [ -n "$UNITTEST" ]; then
  function match_keyvalue()
  {
    filecontent="$1"
    section="$2"
    keyword="$3"
    expected_keyvalue="$4"
    find_section "$filecontent" "$section" "$keyword"
    if [ "result" == "$expected_keyvalue" ]; then
      echo "matched."
    else
      echo "not matched. aborted"
      exit 1
    fi
  }
  loaded_file="$(\
cat << DATA_EOF | cat
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See resolved.conf(5) for details

[Resolve]
# Some examples of DNS servers which may be used for DNS= and FallbackDNS=:
# Cloudflare: 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
# Google:     8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844
# Quad9:      9.9.9.9 2620:fe::fe
#DNS=
#FallbackDNS=
#Domains=
#DNSSEC=no
#DNSOverTLS=no
#MulticastDNS=yes
#LLMNR=yes
#Cache=yes
#DNSStubListener=yes
#DNSStubListenerExtra=
#ReadEtcHosts=yes
#ResolveUnicastSingleLabel=no

DNS=1.1.1.1
FallbackDNS=

[Nosuchresolve]
DNS=2.2.2.2
FallbackDNS=8.8.8.8

DATA_EOF
)"
  echo "loaded file: $loaded_file"
  match_keyvalue "$loaded_file" 'Resolve' 'DNS' ''
fi

