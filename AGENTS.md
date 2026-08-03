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
