# SSH Agent on Void Linux (sway)

Problem: ssh-agent started from bashrc dies when terminal closes, causing passphrase prompt on every new foot terminal.

## Solution

Start the agent from sway's `exec.conf` with a fixed socket path. Bashrc connects to it.

### 1. sway exec.conf

```sway
exec ssh-agent -a "$XDG_RUNTIME_DIR/ssh-agent.sock"
```

This starts the agent when sway launches and keeps it alive for the entire session.

### 2. bashrc-void/.bashrc

```bash
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.sock"
ssh-add ~/.ssh/id_ed25519 2>/dev/null
```

Each terminal sets the socket path and adds the key. If the key is already loaded, `ssh-add` is a no-op (no prompt).

## Why not bashrc-only?

Starting `ssh-agent` from bashrc means:
- Each terminal may spawn its own agent (orphaned processes)
- Agent dies when last terminal closes (SIGHUP)
- Passphrase prompt on every new terminal

Starting from sway ties the agent lifecycle to the session — one agent, all terminals share it.

## Why not systemd user service?

Void uses runit, not systemd. No `systemctl --user`. The sway exec approach is the idiomatic solution for Void.

## Key files

- `sway-void/.config/sway/modules/exec.conf`
- `bashrc-void/.bashrc`
