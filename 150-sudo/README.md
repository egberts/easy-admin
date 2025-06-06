

Need to add the following to a sudo configuration file:

    Defaults env_keep += "TERM TERMINFO"

If none of these are suitable for you, you can run sudo as

    sudo TERMINFO="$TERMINFO"

This will make `TERMINFO` available in the sudo environment. 
Need to add the following to the basrc, et. al.

    alias sudo="sudo TERMINFO=\"$TERMINFO\""
    # If you have double width characters in your prompt, you may also need to explicitly set a UTF-8 locale, like:
    export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

