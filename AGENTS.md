# Notes

## Mako notifications on Debian/Sway (2026-08-03)

- Mako works via `exec mako` added to sway/.config/sway/modules/exec.conf.
- `exec`, not `exec_always` — reload would spawn a duplicate daemon.
- systemd `mako.service` (Debian package, /usr/lib/systemd/user) is masked/
  failed: a GNOME session (tty3) grabs org.freedesktop.Notifications first,
  and sway never reaches graphical-session.target.
- D-Bus activation (fr.emersion.mako.service) respawns mako on demand as
  fallback, so it self-heals.
- Config is fine on Debian's mako 1.10.0; `mako --version` is unsupported.
- niri/Arch needs nothing — left untouched.

## Rofi on Debian (2026-08-03)

- `~/.config/rofi` is a directory symlink into the repo (`../.dotfiles/rofi/.config/rofi`) — edits apply live, no restow needed.
- Debian `debian/main-utils` mirrors Arch's structure but drops Notes/RSS/APT:
  obsidian CLI, `hey`, and the Dropbox vault don't exist on Debian, and `nom`
  isn't installed. Menu: Bluetooth / VPN / SSH / Power.
- Power is the root `scripts/sway-power` (used by both the `$mod+Alt+l` bind
  and the main-utils Power entry); `debian/sway-power` is an unused copy, kept
  in sync. Lockscreen wallpaper: `~/.dotfiles/walls/night01.jpg`.
- `["swaymsg" "exit"]` (implicit string concat) was a bug in sway-power files;
  fixed to `["swaymsg", "exit"]`. Arch `arch/power` logout uses
  `["niri", "msg", "action", "quit"]` (Arch runs niri, not sway); `swaylock` is
  fine there since niri spawns it too.
- `arch/sway-power` is unreferenced cruft (identical to root) — deliberately kept.
- Debian uses `foot` as terminal (Arch's too); `ghostty` and `nom` are NOT
  installed on Debian. `notify-send`/`libnotify` not installed either — use
  `gdbus` or `makoctl` instead.

## SSH agent on Arch/niri (2026-08-06)

- Arch + niri, session started via `niri-session` (ly DM on tty1, sway runs on
  the Debian box only). Before the fix there was NO agent: `SSH_AUTH_SOCK` was
  unset everywhere, no ssh-agent process, no environment.d, and nothing in
  `~/.bashrc`. `~/.ssh/id_ed25519` is passphrase-protected, so every `git push`
  prompted for the passphrase.
- Fix: enabled Arch's systemd user socket (from `openssh`, listens on
  `/run/user/1000/ssh-agent.socket`, `%t/ssh-agent.socket`):
  `systemctl --user enable --now ssh-agent.socket`.
- `~/.bashrc` exports `SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"` so
  every new terminal finds the agent. `ssh/.ssh/config` already has
  `AddKeysToAgent yes`, so the first `git push`/ssh asks the passphrase once
  and the key stays cached in the agent for the session.
- Deliberately NOT used: niri's `environment {}` block (only reaches processes
  niri spawns, value is a literal — no `$XDG_RUNTIME_DIR` expansion, would need
  hardcoding UID) and `~/.config/environment.d/` (read only at user-manager
  start). `.bashrc` covers the terminal use case and needs no re-login.
- `sway/.config/sway/modules/exec.conf:12` has `exec ssh-add ~/.ssh/id_ed25519`
  — that's the Debian/sway box's (broken, no TTY) attempt, unrelated here.

## Polkit auth agent on Arch/niri (2026-08-13)

- `gnome-disks` (udisks) USB flashing failed with "you don't have authority",
  even though polkit was installed and `polkitd` was active.
- Root cause: niri (bare Wayland compositor, no DE) ships no polkit auth agent,
  so nothing could prompt for a password; admin actions were silently denied.
  `wheel` is already the admin group per `50-default.rules`, so an agent alone
  was the missing piece.
- Fix: added
  `spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"`
  to `niri/.config/niri/config.kdl:7`. Applies next niri start; launch manually
  for the current session.
- `polkit-gnome` was already installed, just never launched. No sway changes —
  sway on the Debian box is unaffected.
- Alternatives deliberately NOT used: `run0 --empower` (temporary per boot;
  `empower.rules` grants YES to all actions) and CLI `sudo dd` (works via
  wheel, but no GUI prompting).

## Arch → Void migration planning (2026-08-14)

- Planning notes live in `~/Dropbox/_nekrofrukt/docs/arch-to-void.md`,
  grounded in live Arch system inspection (pacman -Qqe, systemctl). Dotfiles
  carry over as-is (niri/foot/mako/waybar/nvim/tmux/starship/yazi are
  distro-agnostic). runit-from-scratch is part of the appeal.
- 4 must-have apps: 1Password, Dropbox, NordVPN (CLI only — no GUI), Brave
  (native xbps-src build, not Flatpak, to keep the 1Password extension
  native-messaging manifest).
- Package availability: most in XBPS main; `dropbox` in nonfree (wrapper, needs
  Void's `fuse` = fuse v2); missing from XBPS: 1password, brave, nordvpn,
  nom, obsidian, opencode, signal-desktop, ly, zram-generator.
- Renames to remember: gst-plugin-pipewire→gstreamer1-pipewire,
  libpulse→libpulseaudio, ttf-*-nerd fonts→nerd-fonts, noto-fonts→noto-fonts-ttf,
  zram-generator→zramen.
- runit service map (systemd→/etc/sv): udevd, elogind, dbus (no broker),
  chronyd, bluetoothd, NetworkManager, tailscaled, polkitd, rtkit,
  power-profiles-daemon. `udisks2` ships NO sv — create manually. upower is
  D-Bus activated. No user services — pipewire/wireplumber via XDG autostart,
  ssh-agent via shell rc / .xinitrc.
- KEY: `deb2xbps` is gone from xtools (0.70). Convert debs with `xdeb`
  (`xdeb-org/xdeb`, single script): deps `xbps-install -S binutils tar curl
  xbps xz`, then `./xdeb -Sedf <file>.deb`.
- NordVPN: deb pool live at 5.3.0 (`repo.nordvpn.com/.../nordvpn_5.3.0_amd64.deb`).
  Needs `/etc/sv/nordvpnd/run` + `usermod -aG nordvpn`. 1Password: official
  tarball to /opt/1Password + after-install.sh; SSH agent via app autostart +
  `IdentityAgent` in ~/.ssh/config.
- Brave sync is the source of truth, NOT the local profile — keep the 24-word
  recovery code; extension data/settings won't sync and reset on fresh install.
- Updates: Brave is the only truly manual app (1Password/Dropbox self-update).
  Brave loop: git pull template → `./xbps-src pkg brave-bin` → install from
  hostdir/binpkgs. OPEN ITEM: pick (a) `bup()` bashrc function, (b) manual
  check during weekly `-Syu`, or (c) weekly cron — decide during migration.
  Fallback if soanvig/brave-bin goes stale: convert Brave's deb via xdeb.
- I wrote `~/.local/bin/update-local-pkgs` once; user planned to remove it.
  Don't recreate unless asked.
