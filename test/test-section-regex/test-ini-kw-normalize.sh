#!/bin/sh

. ../section-regex.sh

assert_keyword_normalize() {
  local kw expected pass note result
  kw=$1
  expected=$2
  pass=$3
  note=$4
  echo -n "assert_keyword_normalize('${kw}'): "
  result="$(echo "$kw" | ini_keyword_normalize "$kw")"
  if [ "$result" == "$kw" ]; then
    if [ "$pass" == '1' ]; then
      echo "pass: got: '$result'"
    else
      echo "UNEXPECTEDLY FAIL"
      echo " expected: '$expected'"
      echo " result: '$result'"
      exit 1
    fi
  else
    if [ "$pass" == '0' ]; then
      echo "expectedly fail: got: '$result'"
    else
      echo "UNEXPECTEDLY FAILED"
      echo " expected: '$expected'"
      echo " result: '$result'"
      exit 1
    fi
  fi
}


assert_keyword_normalize "DNS" "DNS" 1 "basic keyword"
assert_keyword_normalize "ini_field" "ini_field" 1 "underscore"
assert_keyword_normalize "ini-field" "ini-field" 1 "dash symbol"
assert_keyword_normalize "ini\$field" "ini\$field" 1 "dollar-sign"
assert_keyword_normalize "ini\$field-play_er" "ini\$field-play_er" 1 "mixed symbols"
assert_keyword_normalize "ini.field" "ini.field" 1 "period"

assert_keyword_normalize "D NS" "DNS" 0 "spacey keyword"
assert_keyword_normalize " DNS" "DNS" 0 "space-prefixed keyword"
assert_keyword_normalize "DNS " "DNS" 0 "space-suffixed keyword"
assert_keyword_normalize "D#NS" "DNS" 0 "hashmark"
assert_keyword_normalize "D~NS" "DNS" 0 "tilde"
assert_keyword_normalize "D\`NS" "DNS" 0 "backtick"
assert_keyword_normalize "D!NS" "DNS" 0 "exclaimation mark"
assert_keyword_normalize "D@NS" "DNS" 0 "at symbol"
assert_keyword_normalize "D%NS" "DNS" 0 "percent"
assert_keyword_normalize "D^NS" "DNS" 0 "caret"
assert_keyword_normalize "D*NS" "DNS" 0 "asterisk"
assert_keyword_normalize "D(NS" "DNS" 0 "left parenthesis"
assert_keyword_normalize "D)NS" "DNS" 0 "right parenthesis"
assert_keyword_normalize "D+NS" "DNS" 0 "plus"
assert_keyword_normalize "D=NS" "DNS" 0 "equal"
assert_keyword_normalize "D]NS" "DNS" 0 "right brack"
assert_keyword_normalize "D[NS" "DNS" 0 "left brack"
assert_keyword_normalize "D{NS" "DNS" 0 "left brace"
assert_keyword_normalize "D}NS" "DNS" 0 "right brace"
assert_keyword_normalize "D,NS" "DNS" 0 "comma"
assert_keyword_normalize "D<NS" "DNS" 0 "less than"
assert_keyword_normalize "D>NS" "DNS" 0 "greater than"

assert_keyword_normalize "D/NS" "DNS" 0 "slash"
assert_keyword_normalize "D//NS" "DNS" 0 "double slash"
assert_keyword_normalize "D//NS" "DNS" 0 "triple slash"

assert_keyword_normalize 'D\bS' "DbS" 0 "bell"   # wow, bash limitation there
assert_keyword_normalize "D\bS" "DS" 0 "bell"   # wow, bash limitation there
assert_keyword_normalize 'D\\bS' "DbS" 0 "bell"   # wow, bash limitation there
assert_keyword_normalize "D\tS" "DS" 0 "tab"   # wow, bash limitation there
assert_keyword_normalize "D\nS" "DS" 0 "new-line"   # wow, bash limitation there
assert_keyword_normalize "D\AS" "DNS" 0 "backslash"   # wow, bash limitation there
assert_keyword_normalize "D\nS" "DnS" 0 "backslash"   # wow, bash limitation there
assert_keyword_normalize 'D\nS' "DnS" 0 "double backslash"
assert_keyword_normalize "D\nS" "DS" 0 "double backslash"
assert_keyword_normalize 'D\\nS' "DnS" 0 "double backslash"
assert_keyword_normalize "D\\nS" "DnS" 0 "double backslash"
assert_keyword_normalize 'D\\\nS' "DnS" 0 "triplebackslash"
assert_keyword_normalize "D\\\nS" "DnS" 0 "triplebackslash"

assert_keyword_normalize "D\rS" "DS" 0 "backslash"   # wow, bash limitation there
echo

echo "${BASH_SOURCE[0]}: Done."

