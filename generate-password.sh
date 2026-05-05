#!/bin/bash

# generate-password utility for pass using rofi
# presumes a flat organization structure
# (${PASSWORD_STORE_DIR:-$HOME/.password-store}/$HOST/$USER)
#
# pass the host as the sole arg
# primarily intended for integration with a browser
# ex. qutebrowser:
#   :spawn --userscript generate-password.sh {url:host}

if [ $# -ne 1 ]; then
    echo "1 required arg: host" >&2
    exit 1
fi

# select either the fully-qualified host or just the domain.tld (or manual entry).
HOST_OPTIONS="$([[ $1 == *.*.* ]] && echo "${1#*.}"; echo "$1")"
HOST="$(echo "$HOST_OPTIONS" | rofi -dmenu -p "host")"
[ -z "$HOST" ] && exit 0  # provide no selection to cancel

# select from existing users under that host
mkdir -p "${PASSWORD_STORE_DIR:-$HOME/.password-store}/$HOST"  # for new domains
USER="$(ls "${PASSWORD_STORE_DIR:-$HOME/.password-store}/$HOST" | sed 's/\.gpg$//' | rofi -dmenu -p "user")"
[ -z "$USER" ] && exit 0  # provide no selection to cancel

pass generate --force -c "$HOST/$USER"

