#!/bin/bash

function remove_inline_comment()
{
  echo "$line"|sed 's/\s*[;#].*$//'

}

line="DNS=4.4.4.4 # not Google"
echo "line: '$line'"
result="$(remove_inline_comment "$line")"
echo "result: '$result'"

line="DNS=9.9.9.9 ; not Cloud"
echo "line: '$line'"
result="$(remove_inline_comment "$line")"
echo "result: '$result'"
