#!/bin/sh
# NOTE: ssh runs this without a login shell, so no locale is set and tmux then
# draws every non-ASCII cell as "_" -- which looks like a missing Nerd Font.
# Probed, not hardcoded: en_US.UTF-8 is often absent on a server image.
if [ -z "${LC_ALL:-}${LC_CTYPE:-}${LANG:-}" ]; then
    if command -v locale >/dev/null 2>&1 &&
       locale -a 2>/dev/null | grep -qiE '^en_US\.(utf-?8)$'; then
        LANG=en_US.UTF-8
    else
        LANG=C.UTF-8
    fi
    export LANG
fi

# No -f: this path is on tmux's built-in config search path from 3.1 onward.
exec tmux new -A -s server
