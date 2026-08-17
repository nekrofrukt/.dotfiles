# SSH Agent on Void Linux (sway)

Problem: ssh-agent started from bashrc dies when terminal closes, causing passphrase prompt on every new foot terminal.

## Solution

Use `keychain` to manage the agent. It starts ssh-agent if needed, caches the passphrase to a file, and reuses it across terminals.

### 1. Install keychain

```bash
sudo xbps-install keychain
```

### 2. bashrc-void/.bashrc

```bash
# SSH agent via keychain
eval $(keychain -q --eval --noask id_ed25519)
```

`-q` suppresses per-terminal output. `--noask` prevents prompting if the key is already loaded.

### 3. sway exec.conf

Remove the old `exec ssh-agent` line — keychain manages the agent lifecycle.

## Why keychain over manual ssh-agent?

- **Manual (old way):** sway starts agent, bashrc connects to socket + runs `ssh-add`. Fragile: agent can die on sway reload, `ssh-add` prompts on every new terminal if key isn't loaded.
- **Keychain:** manages agent itself, caches passphrase to `~/.keychain/`, survives across terminals and sway reloads. One passphrase prompt per boot.

## Key files

- `bashrc-void/.bashrc`
- `sway-void/.config/sway/modules/exec.conf` (no ssh-agent line)
