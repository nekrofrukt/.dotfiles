# Void migration — decisions & gotchas (2026-08-15)

Verified against the live trial machine (this laptop) while writing `base-install.md`.
That trial box is not the migration target — the handbook is for the fresh install.

## Decisions

- **Session manager: elogind, explicitly.** No seatd. elogind is installed and
  enabled as a runit service (`/var/service/elogind`), not D-Bus activation.
  Rationale: the Void handbook — *"If you're having any issues with elogind,
  enable its service, as waiting for a D-Bus activation can lead to issues."*
- **Greeter: greetd + tuigreet.** Replaces agreety. F12 power menu wired to
  `loginctl poweroff/reboot/suspend`; session `dbus-run-session niri --session`.
- **Power actions via `loginctl` only** — never plain `shutdown`/`reboot`/
  `systemctl suspend` (raw runit halt while niri owns DRM → warning spam).
  Power button stays power-off (Void acpid default), routed through elogind.
- **Networking: NetworkManager** replaces dhcpcd + wpa_supplicant.
- **Power profiles: power-profiles-daemon — yes** (laptop).
- **1Password: Brave extension only for now.** Desktop app deferred, revisit later.
- **VPN: Mullvad over WireGuard** (replaces NordVPN). waybar `vpn.sh` and rofi
  VPN script rewritten for `wg`/`mullvad status`.
- **GNOME track: `gnome-core`, not `gnome`.** Minimal shell+settings+nautilus;
  no ~30-app suite. `gdm` pulled in by core; `power-profiles-daemon`,
  `NetworkManager`, `bluez` are NOT pulled in — installed explicitly.
- **Rofi power menu uses `loginctl`; rofi-vpn uses Mullvad.** Void dotfile
  variants staged in `docs/_temp-void-dots` (trial box: no git push).

## Void gotchas

- **`xbps-query -Rs "^pkg$"` (anchored) returns false negatives.** Use the
  unanchored form `xbps-query -Rs pkgname`. In output, `[-]` = available,
  `[*]` = installed.
- **Package names are case-sensitive**: `NetworkManager`, `Waybar`.
  Lowercase `networkmanager`/`waybar` do not resolve.
- **Nothing pulls in elogind** — it has zero reverse-deps in the base install.
  Install it explicitly: `xbps-install -S dbus elogind polkit`.
- **Service dirs ship via `vsv` in templates** (e.g. `gdm`, `power-profiles-daemon`).
- **`intel-ucode` is in the nonfree repo**, not main. `linux-firmware-intel`
  carries only i915 GPU firmware, no CPU microcode. After installing, rebuild
  initramfs: `xbps-reconfigure -f linux` (`early_microcode=yes` already set).
- **man-db is not needed on Void** — base uses mandoc (mdocml) + man-pages.
- **PipeWire** pulls wireplumber (session manager) but not `alsa-pipewire` or
  `libspa-bluetooth` — add those for ALSA/Bluetooth audio.
- **dhcpcd/wpa_supplicant are installed with base; whether they're *enabled*
  depends on the installer's Network step.** Disable before starting
  NetworkManager (`rm -f /var/service/dhcpcd`).
