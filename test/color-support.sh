#  no hash-tag here
#
# File: color-support.sh
# Title: Intensive ways to do coloring of outputs using ANSI
# Description:
#
#  Try it:
#    ./color-support.sh
#    DEBUG=1 ./color-support.sh   # see nicely colorized output
#    ANSI_COLOR= DEBUG=1 ./color-support.sh   # see nicely colorized output

# if a UNIX pipe,
if [ ! -t 1 ]; then
  # then turn off color (even if user overrides, turn them off)
  ANSI_COLOR=
else
  # check if end-user provided ultimate override
  if [ -n "$ANSI_COLOR" ]; then
    ANSI_COLOR="${ANSI_COLOR:-}"
  else
    # check if tty supports color (via LS_COLORS env var)
    if [ -n "$LS_COLORS" ]; then
      ANSI_COLOR=1
    else
      ANSI_COLOR=
    fi
  fi
fi

source relative_dirs.sh
