# Agent Session Logs

Log entries from each working session, newest on top.

## TODO: Check SSH agent after reboot (2026-08-17)

- Moved ssh-agent start to sway exec.conf (fixed socket at `$XDG_RUNTIME_DIR/ssh-agent.sock`)
- bashrc-void just connects to the agent + adds key
- Needs reboot/re-login to verify: does agent persist across foot terminals? Does it prompt only once?

## Session notes (2026-08-17 ~22:00)

- **M720 Bluetooth MAC fix**: MAC changed from `F0:8D` to `F0:96` in `rofi-void/.config/rofi/scripts/bluetooth` (bluetoothctl showed device as `F0:96`, script had wrong MAC)
- **Rofi main menu restructure**: renamed `main-utils` → `main-menu`, two-level menu: Utilities (BT/VPN/SSH), Applications (Spotify/Nom), Notes, Power
- **Rofi drun styling fix**: `theme.rasi` needed `background-color: transparent` on `element-icon`/`element-text` so selected state was visible; final style: `@bg-alt` bg + `@selected` text
- **nom install**: installed from GitHub releases tarball (v3.3.2). README references outdated v3.0.0. No Void package exists. No auto-update mechanism
- **bashrc-void updates**: added `~/.local/bin` to PATH, bash-completion sourcing
- **SSH agent**: moved to sway `exec.conf` with fixed socket, bashrc connects to it

## Agent logs reorganization (2026-08-17 ~21:00)

- Reorganized agent files: all dated session logs moved from `AGENTS.md` to `docs/agent-logs.md` (newest on top). `AGENTS.md` is now 4 rules only.
- `playerctl` and `libnotify` in `base-install.md` are not needed for sway — `playerctl` is only used by niri media keys, `notify-send` (from libnotify) isn't wired into any sway config. Not removed yet (user didn't ask).

## Void/sway VPN + sudoers fix (2026-08-17 ~15:00)

- Sway cursor: `seat * xcursor_theme Adwaita 24` needs to be added to sway config (not stowed yet, user told to add manually).
- Rewrote `waybar-sway/.config/waybar/scripts/vpn.sh` from NordVPN to WireGuard/Mullvad — shows `WRG ↑`/`WRG ↓`, supports `--toggle` for click.
- Added `on-click` to `custom/vpn` module in `waybar-sway/.config/waybar/config.jsonc`.
- Rewrote `rofi-void/.config/rofi/scripts/vpn` from NordVPN to WireGuard/Mullvad — shows status as `-mesg`, options are Connect/Disconnect.
- Created `/etc/sudoers.d/wg-quick` (NOPASSWD rule for wg-quick up/down/show on `se-sto-wg-001`).
- **Sudoers file ordering bug**: `@includedir /etc/sudoers.d` processes files alphabetically, last match wins. `wg-quick` sorted before `wheel` → `%wheel ALL=(ALL:ALL) ALL` overrode the NOPASSWD rule. Fixed by renaming to `z-wg-quick`.
- Also: Void ships `/etc/sudoers.d/wheel` with wrong permissions (not 0440) — sudo silently skips the entire `sudoers.d/` directory if any file has bad perms. Fixed.
- Updated `rofi-void/manual.md` and `docs/void/base-install.md` VPN section with both quirks.

## Void/pipewire audio fix (2026-08-17)

- XM5 still wouldn't connect after the day-1 fix. Real cause: **two wireplumber session managers**. `/etc/pipewire/pipewire.conf.d/10-wireplumber.conf` (symlink to `/usr/share/examples/wireplumber/10-wireplumber.conf`, dropped in during setup) makes the pipewire daemon auto-spawn wireplumber (`PIPEWIRE_INTERNAL=1`), AND sway exec.conf had `exec wireplumber` → duplicate.
- Duplicate wireplumbers fight on the registry: `wpctl status` hangs, `pactl info` → "Connection failure: Timeout", and there are NO audio cards/sinks at all → A2DP can't establish → XM5 fails to connect. (M720 mouse was fine — HID only.)
- Fix (user applied): `sway-void/.config/sway/modules/exec.conf` now has ONLY `exec pipewire` — pipewire-pulse (`20-pipewire-pulse.conf`) and wireplumber (`10-wireplumber.conf`) are auto-spawned by the daemon via the `/etc/pipewire/pipewire.conf.d/` drop-ins. Those drop-ins are symlinks to /usr/share/examples, NOT package conf_files → permanent, survive updates.
- Verify: `ps -e | grep wireplumber` → exactly ONE; `timeout 5 wpctl status` lists sinks; `pactl info` responds instantly; `bluetoothctl connect AC:80:0A:16:10:39` → connects with A2DP.
- CORRECTION: waybar exec commands DO expand `~`. Both `util/command.hpp` (`execlp("/bin/sh", "sh", "-c", ...)`) and `command_line_stream.cpp` wrap commands in `/bin/sh -c`, and POSIX sh tilde-expands a word-leading `~`, so the `custom/vpn` + `custom/hey` paths in `config.jsonc` are fine. The only reason those modules show nothing is that `nordvpn`/`hey-cli` aren't installed yet (vpn.sh still prints its "VPN Offline" fallback). If waybar still doesn't appear after reboot: `swaymsg reload`, else run `waybar -b bar-0` in a terminal to read the startup error.

## Void/sway fresh install day 1: lid, waybar, fonts, dark mode, audio (2026-08-16)

- Lid close: verified the external-display-aware acpid handler is already in `/etc/acpi/handler.sh` (loop over `/sys/class/drm/card*-*/status`, skip `*eDP-*|*LVDS-*|*DSI-*`, `zzz` only when nothing external is connected); elogind keeps `HandleLidSwitch*=ignore`. Documented as step 2.2.1 in `docs/base-install.md` (source: `docs/logs/niri-lid.md`).
- Waybar fix #1: sway-void `bar` block had `swaybar_command Waybar` — capital-W is the xbps package name, the binary is lowercase `/usr/bin/waybar`, so sway silently failed to spawn it. Fixed to `waybar`. (sway-arch/sway-debian were already correct.)
- Missing symbols (opencode in foot): the input-bar loading bar (Knight Rider scanner, blocks style hardcoded in prompt/index.tsx) renders `■` active / `⬝` (U+2B1D) inactive; diamond style uses ⬥◆⬩⬪. JetBrainsMono Nerd Font covers all waybar icons (charset f0001–f1af0) but NOT U+2B1D → foot fell back to FreeMono (tiny/misaligned). Noto Sans Symbols 2 is ALREADY system-wide at `/usr/share/fonts/noto/` and covers 2Bxx/geometric/braille + monochrome U+1F512; no emoji font installed at all (🔒 had zero coverage). I temporarily copied NSS2 to `~/.local/share/fonts` and added a foot.ini fallback — BOTH REVERTED at user request; user is installing font packages manually.
- Health check (fresh Void): disk 4% (7.8G/233G), RAM 1.7Gi/15Gi, NO swap/zram (zramen still a migration to-do), all runit services up, 721 pkgs, `xbps-install -nu` clean, `/etc/sway/config.d` absent, no passwordless sudo.
- Dark mode: created `gtk-3.0/.config/gtk-3.0/settings.ini` (`gtk-theme-name=Adwaita`, `gtk-application-prefer-dark-theme=1` — GTK3 bundles the Adwaita dark variant, no packages needed) and added `color-scheme=prefer-dark` to `gtk-4.0/.../settings.ini` (libadwaita reads this). NOT symlinked into `~/.config` yet — user stows manually.
- Waybar fix #2 + headphones disconnect (WH-1000XM5): root cause was NO audio daemon running at all. `pipewire`/`wireplumber`/`alsa-pipewire` installed but never started: sway has no XDG autostart handler (no `dex`/`sway-launch`), so Void's `/usr/share/applications/pipewire*.desktop` are never processed (same reason `blueman-applet`/`nm-applet` aren't running). With no audio server BlueZ can't set up A2DP → XM5 connects then drops (M720 mouse is fine — HID only). FIX SUPERSEDED (see "Void/pipewire audio fix" below): the `exec pipewire-pulse` + `exec wireplumber` lines were redundant and BROKE audio; the current exec.conf has only `exec pipewire`.

## Void/lightdm greeter on closed lid → external display (2026-08-16)

- lightdm + lightdm-mini-greeter renders on the primary X output, which is the built-in `eDP-1` — with the lid closed the greeter is invisible on reboot. Sway's own lid handling (`bindswitch`, `lid-state.sh`) only runs after login.
- Fix: `xrandr` installed; `~/.dotfiles/lightdm/scripts/lid-external.sh` in the repo (exits early unless lid is `closed` AND an external connector is `connected`, then `xrandr --output eDP-1 --off`); wired via `display-setup-script=.../lid-external.sh` in `/etc/lightdm/lightdm.conf` `[Seat:*]` — runs after Xorg starts, before the greeter, with `DISPLAY` set. lightdm.conf is an xbps conf_file → survives updates. Full log: `docs/logs/lightdm-mini-greeter.md` §6.

## Arch → Void migration planning (2026-08-14)

- Planning notes live in `~/Dropbox/_nekrofrukt/docs/arch-to-void.md`, grounded in live Arch system inspection (pacman -Qqe, systemctl). Dotfiles carry over as-is (niri/foot/mako/waybar/nvim/tmux/starship/yazi are distro-agnostic). runit-from-scratch is part of the appeal.
- 4 must-have apps: 1Password, Dropbox, NordVPN (CLI only — no GUI), Brave (native xbps-src build, not Flatpak, to keep the 1Password extension native-messaging manifest).
- Package availability: most in XBPS main; `dropbox` in nonfree (wrapper, needs Void's `fuse` = fuse v2); missing from XBPS: 1password, brave, nordvpn, nom, obsidian, opencode, signal-desktop, ly, zram-generator.
- Renames to remember: gst-plugin-pipewire→gstreamer1-pipewire, libpulse→libpulseaudio, ttf-*-nerd fonts→nerd-fonts, noto-fonts→noto-fonts-ttf, zram-generator→zramen.
- runit service map (systemd→/etc/sv): udevd, elogind, dbus (no broker), chronyd, bluetoothd, NetworkManager, tailscaled, polkitd, rtkit, power-profiles-daemon. `udisks2` ships NO sv — create manually. upower is D-Bus activated. No user services — pipewire/wireplumber via XDG autostart, ssh-agent via shell rc / .xinitrc.
- KEY: `deb2xbps` is gone from xtools (0.70). Convert debs with `xdeb` (`xdeb-org/xdeb`, single script): deps `xbps-install -S binutils tar curl xbps xz`, then `./xdeb -Sedf <file>.deb`.
- NordVPN: deb pool live at 5.3.0 (`repo.nordvpn.com/.../nordvpn_5.3.0_amd64.deb`). Needs `/etc/sv/nordvpnd/run` + `usermod -aG nordvpn`. 1Password: official tarball to /opt/1Password + after-install.sh; SSH agent via app autostart + `IdentityAgent` in ~/.ssh/config.
- Brave sync is the source of truth, NOT the local profile — keep the 24-word recovery code; extension data/settings won't sync and reset on fresh install.
- Updates: Brave is the only truly manual app (1Password/Dropbox self-update). Brave loop: git pull template → `./xbps-src pkg brave-bin` → install from hostdir/binpkgs. OPEN ITEM: pick (a) `bup()` bashrc function, (b) manual check during weekly `-Syu`, or (c) weekly cron — decide during migration. Fallback if soanvig/brave-bin goes stale: convert Brave's deb via xdeb.
- I wrote `~/.local/bin/update-local-pkgs` once; user planned to remove it. Don't recreate unless asked.

## Polkit auth agent on Arch/niri (2026-08-13)

- `gnome-disks` (udisks) USB flashing failed with "you don't have authority", even though polkit was installed and `polkitd` was active.
- Root cause: niri (bare Wayland compositor, no DE) ships no polkit auth agent, so nothing could prompt for a password; admin actions were silently denied. `wheel` is already the admin group per `50-default.rules`, so an agent alone was the missing piece.
- Fix: added `spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"` to `niri/.config/niri/config.kdl:7`. Applies next niri start; launch manually for the current session.
- `polkit-gnome` was already installed, just never launched. No sway changes — sway on the Debian box is unaffected.
- Alternatives deliberately NOT used: `run0 --empower` (temporary per boot; `empower.rules` grants YES to all actions) and CLI `sudo dd` (works via wheel, but no GUI prompting).

## SSH agent on Arch/niri (2026-08-06)

- Arch + niri, session started via `niri-session` (ly DM on tty1, sway runs on the Debian box only). Before the fix there was NO agent: `SSH_AUTH_SOCK` was unset everywhere, no ssh-agent process, no environment.d, and nothing in `~/.bashrc`. `~/.ssh/id_ed25519` is passphrase-protected, so every `git push` prompted for the passphrase.
- Fix: enabled Arch's systemd user socket (from `openssh`, listens on `/run/user/1000/ssh-agent.socket`, `%t/ssh-agent.socket`): `systemctl --user enable --now ssh-agent.socket`.
- `~/.bashrc` exports `SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"` so every new terminal finds the agent. `ssh/.ssh/config` already has `AddKeysToAgent yes`, so the first `git push`/ssh asks the passphrase once and the key stays cached in the agent for the session.
- Deliberately NOT used: niri's `environment {}` block (only reaches processes niri spawns, value is a literal — no `$XDG_RUNTIME_DIR` expansion, would need hardcoding UID) and `~/.config/environment.d/` (read only at user-manager start). `.bashrc` covers the terminal use case and needs no re-login.
- `sway/.config/sway/modules/exec.conf:12` has `exec ssh-add ~/.ssh/id_ed25519` — that's the Debian/sway box's (broken, no TTY) attempt, unrelated here.

## Rofi on Debian (2026-08-03)

- `~/.config/rofi` is a directory symlink into the repo (`../.dotfiles/rofi/.config/rofi`) — edits apply live, no restow needed.
- Debian `debian/main-utils` mirrors Arch's structure but drops Notes/RSS/APT: obsidian CLI, `hey`, and the Dropbox vault don't exist on Debian, and `nom` isn't installed. Menu: Bluetooth / VPN / SSH / Power.
- Power is the root `scripts/sway-power` (used by both the `$mod+Alt+l` bind and the main-utils Power entry); `debian/sway-power` is an unused copy, kept in sync. Lockscreen wallpaper: `~/.dotfiles/walls/night01.jpg`.
- `["swaymsg" "exit"]` (implicit string concat) was a bug in sway-power files; fixed to `["swaymsg", "exit"]`. Arch `arch/power` logout uses `["niri", "msg", "action", "quit"]` (Arch runs niri, not sway); `swaylock` is fine there since niri spawns it too.
- `arch/sway-power` is unreferenced cruft (identical to root) — deliberately kept.
- Debian uses `foot` as terminal (Arch's too); `ghostty` and `nom` are NOT installed on Debian. `notify-send`/`libnotify` not installed either — use `gdbus` or `makoctl` instead.

## Mako notifications on Debian/Sway (2026-08-03)

- Mako works via `exec mako` added to sway/.config/sway/modules/exec.conf.
- `exec`, not `exec_always` — reload would spawn a duplicate daemon.
- systemd `mako.service` (Debian package, /usr/lib/systemd/user) is masked/failed: a GNOME session (tty3) grabs org.freedesktop.Notifications first, and sway never reaches graphical-session.target.
- D-Bus activation (fr.emersion.mako.service) respawns mako on demand as fallback, so it self-heals.
- Config is fine on Debian's mako 1.10.0; `mako --version` is unsupported.
- niri/Arch needs nothing — left untouched.
