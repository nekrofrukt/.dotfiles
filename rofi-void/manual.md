# rofi-void manual setup

## sudoers for WireGuard (VPN toggle)

The rofi VPN menu and waybar VPN click need to run `wg-quick up/down` without a
password prompt. Add a sudoers drop-in:

```
sudo visudo -f /etc/sudoers.d/z-wg-quick
```

Paste this line (replace username if needed):

```
nekrofrukt ALL=(root) NOPASSWD: /usr/bin/wg-quick up se-sto-wg-001, /usr/bin/wg-quick down se-sto-wg-001, /usr/bin/wg show se-sto-wg-001
```

This limits passwordless sudo to exactly those three commands — nothing else.

**Important — two gotchas**:

1. The file must be `0440` (sudoers won't read it otherwise):

```
sudo chmod 0440 /etc/sudoers.d/z-wg-quick
```

2. The filename **must sort after `wheel`** alphabetically (e.g. `z-wg-quick`).
   `@includedir` processes files in lexical order, and the **last matching rule
   wins** in sudo. If your file sorts before `wheel`, the `%wheel ALL=(ALL:ALL) ALL`
   rule (requires password) overrides your NOPASSWD rule.

Fix if you already created it as `wg-quick`:

```
sudo mv /etc/sudoers.d/wg-quick /etc/sudoers.d/z-wg-quick
```

Also fix the stock `wheel` file permissions (ships with wrong mode on Void):

```
sudo chmod 0440 /etc/sudoers.d/wheel
```

Verify:

```
sudo -n wg show se-sto-wg-001
```

If it asks for a password, check the file name, content, and permissions.
