# qb-pass

qutebrowser userscripts for managing [pass](https://www.passwordstore.org/) passwords via [rofi](https://github.com/davatorium/rofi).

Assumes a flat password store layout: `$PASSWORD_STORE_DIR/$HOST/$USER` (e.g. `~/.password-store/github.com/nat`).

While primarily designed for qutebrowser, the scripts can be invoked from any context that can call a shell script with a hostname argument.

## Scripts

| Script | Description |
|---|---|
| `copy-password.sh` | Copy an existing password to the clipboard |
| `generate-password.sh` | Generate and copy a new password for an existing or new user |
| `new-password.sh` | Insert a manually-entered password for an existing or new user |

The install script and manual installation instructions below also optionally set up an `insert-password` alias and `,pi` binding, which wrap qutebrowser's built-in [qute-pass](https://github.com/qutebrowser/qutebrowser/blob/main/misc/userscripts/qute-pass) userscript to auto-fill credentials into the current page using rofi as the picker.

## Dependencies

- [pass](https://www.passwordstore.org/) — the standard Unix password manager
- [rofi](https://github.com/davatorium/rofi) — dmenu-compatible launcher used as the picker
- A GPG key set up for use with `pass`
- For contexts without an interactive terminal (such as qutebrowser): a GUI pinentry program — [pinentry-rofi](https://github.com/plattfot/pinentry-rofi) is recommended

## Installation

### Via install script (recommended)

```sh
git clone https://github.com/you/qb-pass ~/qb-pass
cd ~/qb-pass && ./install.sh
```

The script will:
1. Create symlinks for the three userscripts in your qutebrowser userscripts directory
2. Append aliases and keybindings to your `config.py`

### Manual installation

1. Clone or download this repository somewhere permanent:

   ```sh
   git clone https://github.com/you/qb-pass ~/qb-pass
   ```

2. Symlink the scripts into your qutebrowser userscripts directory:

   ```sh
   userscripts=~/.config/qutebrowser/userscripts
   src=~/qb-pass

   mkdir -p "$userscripts"
   ln -s "$src/copy-password.sh"     "$userscripts/copy-password"
   ln -s "$src/generate-password.sh" "$userscripts/generate-password"
   ln -s "$src/new-password.sh"      "$userscripts/new-password"
   ```

3. Add the following to your `~/.config/qutebrowser/config.py`:

   ```python
   # qb-pass aliases
   c.aliases.update({
       'copy-password':     'spawn --userscript copy-password',
       'generate-password': 'spawn --userscript generate-password',
       'new-password':      'spawn --userscript new-password',
   })

   # qb-pass keybindings
   config.bind(',pc', 'spawn --userscript copy-password {url:host}')
   config.bind(',pg', 'spawn --userscript generate-password {url:host}')
   config.bind(',pn', 'spawn --userscript new-password {url:host}')
   ```

   Optionally, if you want the `insert-password` / `,pi` binding via `qute-pass`:

   ```python
   c.aliases.update({'insert-password': "spawn --userscript qute-pass --dmenu-invocation 'rofi -dmenu'"})
   config.bind(',pi', "spawn --userscript qute-pass --dmenu-invocation 'rofi -dmenu'")
   ```

## Usage

All commands that take a host as their sole argument. When invoked via the keybindings or aliases above, `{url:host}` is substituted automatically by qutebrowser. rofi will then present a prompt to confirm or override the host, followed by a prompt to select or enter a username.

### `,pc` — `copy-password`

```
:copy-password [host]
```

Prompts for a host and user, then copies the stored password to the clipboard using `pass -c`.

### `,pg` — `generate-password`

```
:generate-password [host]
```

Prompts for a host and user, then calls `pass generate --force -c` to generate a new random password and copy it to the clipboard. Creates the host directory in the store if it does not yet exist.

### `,pn` — `new-password`

```
:new-password [host]
```

Prompts for a host and user, then opens a rofi password prompt to enter the password manually. Inserts it into the store with `pass insert`. Creates the host directory in the store if it does not yet exist.

### `,pi` — `insert-password`

```
:insert-password
```

Invokes the qutebrowser built-in `qute-pass` userscript with rofi as the dmenu picker. Looks up credentials for the current page's host in the password store and fills them into the focused form fields.

> **Note:** `qute-pass` is bundled with qutebrowser and does not need to be installed separately. See its [documentation](https://github.com/qutebrowser/qutebrowser/blob/main/misc/userscripts/qute-pass) for additional options such as `--username-target` and `--password-only`.

## Pinentry

Because qutebrowser does not run in an interactive terminal, GPG cannot use a terminal-based pinentry program to ask for your key passphrase. You need a GUI pinentry configured.

[pinentry-rofi](https://github.com/plattfot/pinentry-rofi) is recommended. Install it and set it as your pinentry program in `~/.gnupg/gpg-agent.conf`:

```
pinentry-program /usr/bin/pinentry-rofi
```

Then reload the agent:

```sh
gpg-connect-agent reloadagent /bye
```

## Password store layout

These scripts expect passwords stored as:

```
~/.password-store/
└── github.com/
    ├── nat.gpg
    └── work.gpg
```

Equivalent to having been inserted with:

```sh
pass insert github.com/nat
```

If your `$PASSWORD_STORE_DIR` is set to a non-default location, the scripts will respect it automatically.
