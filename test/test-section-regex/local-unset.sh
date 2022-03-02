#!/bin/bash


function aa()
{
  local b
  echo "function: a=$a  b=$b"
  a=3
  b=4
  echo "function: a=$a  b=$b"
  unset a b  # unset inside function impacts globally!!!!!!!!!
}

a=1
b=2
echo "main: a=$a  b=$b"
aa
echo "main: a=$a  b=$b"
