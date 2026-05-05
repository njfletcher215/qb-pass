#!/usr/bin/env bash
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"

# Prompt for a value with a default
prompt() {
    local msg="$1" default="$2" answer
    read -r -p "$msg [$default]: " answer
    printf '%s' "${answer:-$default}"
}

# Yes/no prompt; returns 0 for yes, 1 for no
confirm() {
    local msg="$1" default="${2:-n}" answer
    read -r -p "$msg [${default}]: " answer
    [[ "${answer:-$default}" =~ ^[Yy] ]]
}

# Expand a leading ~ in a path
expand_path() { printf '%s' "${1/#\~/$HOME}"; }

echo "=== qb-pass installer ==="
echo

# ---------------------------------------------------------------------------
# 1. Userscript symlinks
# ---------------------------------------------------------------------------
echo "Where should the userscript symlinks be placed?"
echo "  Typical locations:"
echo "    ~/.config/qutebrowser/userscripts  (default)"
echo "    ~/.local/share/qutebrowser/userscripts"
echo "    /usr/share/qutebrowser/userscripts"
echo
userscripts_dir=$(prompt "Userscripts directory" "~/.config/qutebrowser/userscripts")
userscripts_dir="$(expand_path "$userscripts_dir")"
mkdir -p "$userscripts_dir"

for script in copy-password generate-password new-password; do
    src="$script_dir/${script}.sh"
    dest="$userscripts_dir/${script}"
    if [[ -L "$dest" ]]; then
        ln -sf "$src" "$dest"
        echo "-> Updated symlink: $dest"
    elif [[ -e "$dest" ]]; then
        echo "-> Warning: '$dest' already exists and is not a symlink, skipping."
    else
        ln -s "$src" "$dest"
        echo "-> Created symlink: $dest"
    fi
done

echo

# ---------------------------------------------------------------------------
# 2. qutebrowser config.py — aliases and keybindings
# ---------------------------------------------------------------------------
qb_config=$(prompt "qutebrowser config.py path" "~/.config/qutebrowser/config.py")
qb_config="$(expand_path "$qb_config")"

echo
if confirm "Set up insert-password alias/binding? (requires qute-pass, the built-in qutebrowser userscript)" "y"; then
    insert_password=true
else
    insert_password=false
fi

echo

aliases_block=$(cat <<'PYEOF'

# qb-pass aliases
c.aliases.update({
    'copy-password':     'spawn --userscript copy-password',
    'generate-password': 'spawn --userscript generate-password',
    'new-password':      'spawn --userscript new-password',
})
PYEOF
)

aliases_insert=$(cat <<'PYEOF'
c.aliases.update({'insert-password': "spawn --userscript qute-pass --dmenu-invocation 'rofi -dmenu'"})
PYEOF
)

bindings_block=$(cat <<'PYEOF'

# qb-pass keybindings
config.bind(',pc', 'spawn --userscript copy-password {url:host}')
config.bind(',pg', 'spawn --userscript generate-password {url:host}')
config.bind(',pn', 'spawn --userscript new-password {url:host}')
PYEOF
)

bindings_insert=$(cat <<'PYEOF'
config.bind(',pi', "spawn --userscript qute-pass --dmenu-invocation 'rofi -dmenu'")
PYEOF
)

if $insert_password; then
    aliases_block="${aliases_block}${aliases_insert}"$'\n'
    bindings_block="${bindings_block}${bindings_insert}"$'\n'
fi

if [[ -f "$qb_config" ]]; then
    echo "-> Appending to '$qb_config'..."
    printf '%s\n%s\n' "$aliases_block" "$bindings_block" >> "$qb_config"
else
    echo "-> Creating '$qb_config'..."
    mkdir -p "$(dirname "$qb_config")"
    { printf 'config.load_autoconfig()\n'; printf '%s\n%s\n' "$aliases_block" "$bindings_block"; } > "$qb_config"
fi

echo
echo "Done! Restart qutebrowser for the changes to take effect."
