#!/bin/bash

# copy-password utility for pass using rofi
# presumes a flat organization structure
# (${PASSWORD_STORE_DIR:-$HOME/.password-store}/$HOST/$USER)
#
# pass the host as the sole arg
# primarily intended for integration with a browser
# ex. qutebrowser:
#   :spawn --userscript copy-password.sh {url:host}
#
# NOTE: if using from a context without an interactive terminal
#       (ex. qutebrowser), you will need a GUI pinentry program,
#       such as pinentry-qt or pinentry-rofi

DMENU_INVOCATION="rofi -dmenu"

while [ $# -gt 0 ]; do
    case "$1" in
        --dmenu-invocation)
            DMENU_INVOCATION="$2"
            shift 2
            ;;
        --dmenu-invocation=*)
            DMENU_INVOCATION="${1#*=}"
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -ne 1 ]; then
    echo "1 required arg: host" >&2
    exit 1
fi

# split on whitespace, respecting quotes (but not performing any other shell expansion)
DMENU_CMD=()
while IFS= read -r -d '' word; do
    DMENU_CMD+=("$word")
done < <(xargs printf '%s\0' <<< "$DMENU_INVOCATION")

# select either the fully-qualified host or just the domain.tld (or manual entry).
HOST_OPTIONS="$([[ $1 == *.*.* ]] && echo "${1#*.}"; echo "$1")"
HOST="$(echo "$HOST_OPTIONS" | "${DMENU_CMD[@]}" -p 'host')"
[ -z "$HOST" ] && exit 0  # provide no selection to cancel

# select from existing users under that host
USER="$(ls "${PASSWORD_STORE_DIR:-$HOME/.password-store}/$HOST" | sed 's/\.gpg$//' | "${DMENU_CMD[@]}" -p 'user')"
[ -z "$USER" ] && exit 0  # provide no selection to cancel

pass -c "$HOST/$USER"

