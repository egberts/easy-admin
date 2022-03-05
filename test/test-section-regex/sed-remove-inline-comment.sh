#!/bin/bash

function remove_inline_comment()
{
  local line len kv
  line="$1"
  len=${#line}

  # Ideally, we want to scan over our known data field: '\[\S*\]\S*='
  # which stands for '[section_name]keyword='
  # then start analysis on that keyvalue (after '=')
  #
  #  's/^\[[\$\-\.\/0-9\:\?@A-Z\_a-z\~]*\][\$\-\.\/0-9\:\?@A-Z\_a-z\~]*=\s*//'
  #
  # For the keyvalue, our first repetitive regex block to skip over
  # is the '([\'\"]\S*[\'\"])+' to pass-by any quoted contents
  # next requirement is processing any un-quoted un-commented string 
  # after this 'pass the pair of any-matching-quote' pattern
  # and stopping at any 'inline comment' of ';', '#', or '//'
  # then edit for comment removal to end-of-line.
  #
  # echo "kv1: $kv"
  # Remove inline comment after ';'
  #
  #
  # (
  #  (
  #   \'
  #    [ \!\"\#\$\%\&\(\)\*\+\-\.\/0-9\:\;\<\=\>\?@A-Z\[\\\]\^\_\`a-z\|\~]*
  #   \'\s*
  #  )
  # |
  #  (
  #   \"
  #    [ \!\#\$\%\&\'\(\)\*\+\-\.\/0-9\:\;\<\=\>\?@A-Z\[\\\]\^\_\`a-z\|\~]*
  #   \"\s*
  #  )
  # |
  #  (
  #   [ \!\$\%\&\(\)\*\+\-\.\/0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]*
  #  )*
  # )
  # ([;#]|(\/\/))*.*$


  # Strip off '[section]keyword=' indices to get to keyvalue
  kv="$(echo "$line" | sed -e 's/^\[[a-z]\][A-Z]=\(.*\)$/\1/')"
  kv_len=${#kv}
  if [ $kv_len -ge 1 ]; then

    # Extended Regular Expression; different OS has different sed argument option
    source /etc/os-release
    if [ "$ID" == "debian" ]; then
      sed_opt="-r"
    else
      sed_opt="-E"
    fi

    # uncommented keyvalue
#	    sed $sed_opt -e 's/^('\
#'[a-z]+ \"[a-z]+\" [a-z] '\
#')[;#(\/\/)]+.*$/\1/')"
    unc_kv="$(echo "$kv" | \
  	    sed $sed_opt -e 's/^'\
'(((\x27[ 0-9A-Za-z\x27\s*)|(\"[ 0-9A-Za-z\"\s*)|([ 0-9A-Za-z]*\s*)*)*)([;#]|(\/\/))*.*$'\
'/\1/'\
)"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "uncommented keyvalue failed in sed; aborted."
      exit 1
    fi
    unc_kv_len=${#unc_kv}

    # If data is NULL (after de-commenting), skip further actions
    if [ $unc_kv_len -ge 1 ]; then


      # remove leading whitespaces
      unc_kv="$(echo "$unc_kv" | sed -- 's/^[ \t]*//g')"
      # remove trailing whitespaces
      unc_kv="$(echo "$unc_kv" | sed -- 's/[ \t]*$//g')"
    fi

    # output results
    echo "$unc_kv"
  fi
}

assert_dl()
{
  local keyvalue expected note
  keyvalue="$1"
  expected="$2"
  note="$3"
  # echo "Test data: '$keyvalue'"
  echo -n "remove_inline_comment()= "
  result="$(remove_inline_comment "$1")"
  if [ "$result" == "$expected" ]; then
    echo "pass	# $note"
  else
    echo "FAILED:	# $note"
    echo "  expected: ${expected}"
    echo "  result  : ${result}"
    exit 1
  fi
}


assert_dl '[s]D=' '' 'empty'
assert_dl '[s]D=a' 'a' 'empty'
assert_dl '[s]D=a "aaaa" b ; inline' 'a "aaaa" b' 'inline comment, semicolon'
assert_dl '[s]D=a "aaaa" b # inline' 'a "aaaa" b' 'inline comment, hash'
assert_dl '[s]D=a "aaaa" b // inline' 'a "aaaa" b' 'inline comment, double-slash'
exit
assert_dl '[s]D=' '[s]D=' 'standard, empty'
assert_dl '[s]D= ' '[s]D=' 'standard, empty, space-padded'
assert_dl '[s]D=4' '[s]D=4' 'standard, minimal'
assert_dl '[s]D=4.4' '[s]D=4.4' 'value has period'
assert_dl '[ssss]DDDD=4444' '[ssss]DDDD=4444' 'standard, expansive'
assert_dl '[s]D=4  # inline' '[s]D=4' '# inline'
assert_dl '[s]D=4.4  # inline' '[s]D=4.4' 'period value, inline'
assert_dl '[s]D= 4.4.4.4  # inline' '[s]D= 4.4.4.4' ' period value, inline, padded'
assert_dl '[s]D=     4.4.4.4  # inline' '[s]D=     4.4.4.4' 'period value, inline, max-padded'
assert_dl '[s]D= 4.4.4.4  # inline' '[s]D= 4.4.4.4' 'standard X'
echo
echo "Done."
