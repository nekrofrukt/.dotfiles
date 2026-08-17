# Void nordvpn install (xdeb conversion)

NordVPN CLI + daemon installed on Void via xdeb (2026-08-15). Works with the
waybar `custom/vpn` module (`~/.config/waybar/scripts/vpn.sh`).

## Why not in the repos

`nordvpn` is not in XBPS. Nord ships a self-contained 44 MB deb
(`nordvpn_5.3.0_amd64.deb` from `https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/`).
Void's old `deb2xbps` (xtools) is gone; the current tool is **xdeb**
(`https://github.com/xdeb-org/xdeb`, single shell script).

## What was done

1. Deps for xdeb: `sudo xbps-install -S binutils xz` (tar/xbps/curl already present).
2. Download deb to `/tmp/opencode/nordvpn_5.3.0_amd64.deb`.
3. `git clone --depth 1 https://github.com/xdeb-org/xdeb /tmp/opencode/xdeb`.
4. Convert: `./xdeb -Sedf <deb>` → `binpkgs/nordvpn-5.3.0_1.x86_64.xbps`.
   Deps resolved: glibc, libcap-ng, libgcc, libnl3, sqlite.
5. Install + wire up: `sudo sh /tmp/opencode/install-nordvpn.sh`:
   - `xbps-install -R /tmp/opencode/binpkgs nordvpn-5.3.0_1`
   - `groupadd -r nordvpn` (if missing), `usermod -aG nordvpn $USER`
   - wrote `/etc/sv/nordvpnd/run` (runit translation of `nordvpnd.service`)
   - `ln -s /etc/sv/nordvpnd /var/service/`

### Pitfall: xdeb does NOT run the deb's `postinst`

The deb's postinst does critical setup that has to be replicated manually
(`sudo sh /tmp/opencode/complete-nordvpn.sh`):
- `echo "/usr/lib/nordvpn" > /etc/ld.so.conf.d/nordvpn.conf` + `ldconfig`
  (twice — postinst notes a flaky first-start quirk otherwise).
- `chmod 0644 /usr/lib/nordvpn/*.so`
- `ln -sf <system libsqlite3.so.0> /usr/lib/nordvpn/libsqlite3.so` (bundled
  libs reference the unversioned name).
- `mkdir -m 0750 /var/log/nordvpn; chown root:nordvpn /var/log/nordvpn`
- `/dev/net/tun` — already existed via udev on this box (conditional in script).

### The runit service `/etc/sv/nordvpnd/run`

```sh
#!/bin/sh
if [ ! -d /run/nordvpn ]; then
    mkdir -m 0750 /run/nordvpn
    chown root:nordvpn /run/nordvpn
fi
exec /usr/bin/nordvpnd
```

- xdeb moved the binary `usr/sbin` → `usr/bin` (it reported "Moved conflict
  'usr/sbin' -> 'usr/bin'"), so the daemon is `/usr/bin/nordvpnd`, NOT
  `/usr/sbin/nordvpnd` as the shipped systemd/init scripts assume.
- `runsv` supervision replaces systemd `Restart=always`. The shipped
  `nordvpnd.socket` + `nordvpnd-killswitch.service` are not needed (the
  daemon creates `/run/nordvpn/nordvpnd.sock` itself; SysV init doesn't run
  killswitch mode at boot either).

## Verified state

- `ldd /usr/bin/nordvpnd`: `libmoosenordvpnapp.so => /usr/lib/nordvpn/...`
  resolved, `libsqlite3.so.0 => /usr/lib/...` resolved (initially "not found" —
  that was the daemon crash loop in `runsvdir`'s log).
- Daemon running: `/usr/bin/nordvpnd` (sv-managed, auto-restarts).
- Socket: `/run/nordvpn/nordvpnd.sock` — `srw-rw---- root:nordvpn` (0660).
- `nordvpn status` as user → "Permission denied ... reboot your device" —
  expected: the `nordvpn` group membership only applies after re-login/reboot.

## Remaining / next time

- **Reboot** (already planned) → group takes effect.
- `nordvpn login` — needs a token from my.nordaccount.com (user action).
- `nordvpn connect` — then the waybar `custom/vpn` module shows the country
  and `class: on`.
- Daemon survives reboots via `/var/service/nordvpnd`.

## Updating nordvpn later

Re-download the newest deb → `./xdeb -Sedf <deb>` → `sudo xbps-install -R
./binpkgs nordvpn-<ver>_1` → re-run the postinst-equivalent steps (script
`/tmp/opencode/complete-nordvpn.sh` is idempotent). `/tmp/opencode/` survives
until reboot; consider copying the two scripts + `xdeb` elsewhere if updates
will happen before the next reboot.
