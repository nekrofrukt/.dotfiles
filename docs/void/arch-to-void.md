# Arch → Void migration notes

Planning notes. Grounded in live Arch system inspection (pacman -Qqe, systemctl) and live Void repodata checks (2026-08-14).
Living document — tracked at `~/.dotfiles/docs/arch-to-void.md` (moved from Dropbox 2026-08-14).

## Context / decisions

- Moving from Arch (systemd, pacman + yay/AUR) to Void (runit, XBPS).
- Learning runit from scratch is part of the appeal — systemd knowledge is minimal anyway.
- 4 must-have apps must work on Void: 1Password, Dropbox, NordVPN, Brave.
- Dotfiles/configs (niri, foot, mako, waybar, neovim, tmux, starship, yazi, etc.) carry over as-is — they're distro-agnostic.
- Session user-services (mako, pipewire stack) currently run under `systemd --user`; on Void they move to Niri `spawn-at-startup` (already used for waybar/polkit-agent/swayidle/swaybg).

## Non-official-repo apps — decided

| App | Method | Updates |
|---|---|---|
| Brave | VUP via `vuru install brave` | `vuru install -Su` |
| 1Password | official tar.gz → `/opt/1Password` | manual `1pass-update` script (Option A) |
| NordVPN | xdeb (deb → xbps) + runit service | re-run xdeb on deb bump |
| Dropbox | `void-repo-nonfree` | re-downloads daemon on launch |
| Signal | **main repo** (`Signal-Desktop-8.21.0_1`) | `xbps-install -Su` |
| nom | `cargo install nom` (via rustup) | re-run `cargo install nom` |
| Obsidian | OPEN — see below | depends on choice |
| opencode | official install script | re-run script |

## Package map (explicitly installed → Void)

### Available in XBPS (main repo)
alacritty, bash-completion, blueman, bluez, efibootmgr, fastfetch, fd, firefox, foot, fuzzel, fzf, gimp, git, go, htop, intel-ucode, linux, linux-lts, linux-firmware, lua51, mako, man-db, man-pages, nano, neovim, NetworkManager, network-manager-applet, nicotine+, niri, noto-fonts-ttf, pipewire (+ alsa/jack/pulse subpkgs), polkit-gnome, power-profiles-daemon, ripgrep, rofi, ruby, Signal-Desktop, smartmontools, sof-firmware, spotify-player, starship, stow, sudo, sushi, swaybg, swayidle, swaylock, tailscale, tmux, transmission (qt subpkg), tree, ufw, vim, vlc, waybar, wget, wireplumber, wl-clipboard, wpa_supplicant, xdg-utils, xdg-desktop-portal-gnome, xorg-xwayland, yazi, gnome-disk-utility, gnome-music, gnome-text-editor, xf86-video-amdgpu/ati, vulkan drivers (via mesa), base → base-system, base-devel, nerd fonts → nerd-fonts (covers Cascadia/JetBrainsMono/symbols)

### Renamed in Void
- gst-plugin-pipewire → gstreamer1-pipewire (pipewire subpkg)
- libpulse → libpulseaudio (pulseaudio subpkg)
- ttf-cascadia-mono-nerd / ttf-jetbrains-mono-nerd / ttf-nerd-fonts-symbols → nerd-fonts
- noto-fonts → noto-fonts-ttf
- zram-generator → zramen (different tool, runit-native)
- network-manager-applet includes nm-connection-editor

### Available in XBPS nonfree
- dropbox (confirmed `dropbox-2026.03.20_1`; wrapper; downloads real proprietary daemon on first run; needs `fuse` v2 = Void's `fuse`)
- intel-media-driver (nonfree kernel variant build option)

### Enabling nonfree
```
xbps-install void-repo-nonfree      # installs /usr/share/xbps.d/10-repository-nonfree.conf
xbps-install -S                     # (or -Syu) sync the new repo index
xbps-install dropbox
```
nonfree = still official Void infrastructure, just segregated by license (proprietary software). Not enabled by default.

### Third-party only (not in any XBPS repo)
- 1password — official tar.gz (see below)
- brave — VUP (see below)
- nordvpn — xdeb (see below)
- nom, obsidian, opencode — see below

## Must-have apps

### 1Password
- Void deps: `xbps-install nss gtk+3 xdg-utils hicolor-icon-theme` (+ optional `libsecret` for keychain, `pcsc-lite libusb` for YubiKey).
- Official tarball ("other distros" path):
  ```
  curl -LO https://downloads.1password.com/linux/tar/stable/x86_64/1password-latest.tar.gz
  tar -xzf 1password-latest.tar.gz
  cd 1password-<ver>-x86_64
  sudo ./after-install.sh           # → /opt/1Password, desktop entry, icons, updater
  ```
- Same layout as current Arch install (`/opt/1Password`) — binary carries over, no source/build.
- Autostart: **no systemd generator on Void** → add to niri config:
  `spawn-at-startup "/opt/1Password/1password" "--silent"`
- **Updates: manual (Option A, decided 2026-08-14).** Built-in updater does NOT reliably update on Linux — verified live: binary stuck at 8.12.30 while 8.12.32 exists, no updater process. Plan for a `1pass-update` script (curl tar.gz → extract → `sudo ./after-install.sh`). If updates become frequent, promote to a VUP template.
- SSH agent: **not in use** on Arch (no `agent.sock`, no `IdentityAgent`, todo unchecked) → deferred. Add later in app + `IdentityAgent ~/.config/1Password/ssh/agent.sock`.
- Do NOT use Flatpak build (native-messaging / SSH-agent isolation; irrelevant anyway since Brave will be native).

### Dropbox
- Enable nonfree, then `xbps-install dropbox`.
- Runs as user session; no runit service. `fuse` v2 = Void's `fuse`.
- dropbox.py CLI not packaged — fetch from dropbox.com if needed.

### NordVPN (CLI)
- **No flatpak exists** — verified: Flathub has no `com.nordvpn.Linux`; "flatpak" sightings in app stores are the native deb. Do not trust unverified VPN flatpaks.
- Official `install.sh` doesn't support Void (deb/rpm repo detection only).
- Native install via xdeb is the only real path. **Decided: scripted** — migration includes a `nordvpn-setup.sh` that runs all steps below. Commands documented for understanding:
  1. `xbps-install binutils tar curl xbps xz`
  2. `curl -LO https://github.com/xdeb-org/xdeb/releases/latest/download/xdeb && chmod 0744 xdeb`
  3. Resolve current version from the pool (don't trust hardcoded):
     `curl -s https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn/ | grep -oE 'nordvpn_[0-9.]+_amd64.deb' | sort -V | tail -1`
  4. `./xdeb -Sedf nordvpn_<ver>_amd64.deb`
     (`-S` sync shlibs/dep list, `e` rm empty dirs, `d` auto dependency resolution, `f` auto resolve file conflicts)
  5. `xbps-install --repository=$HOME/.config/xdeb/binpkgs nordvpn` (install on the SAME machine you converted on — xdeb conflict checks only work there)
  6. Group: `getent group nordvpn || groupadd -r nordvpn`; `usermod -aG nordvpn $USER`
  7. `/etc/sv/nordvpnd/run`:
     ```sh
     #!/bin/sh
     install -d -m 0750 -o root -g nordvpn /run/nordvpn
     exec /usr/sbin/nordvpnd
     ```
     (`install -d` replaces systemd's `RuntimeDirectory=nordvpn`; runs as root like the systemd unit; runit restarts on crash for free; socket activation dropped — daemon creates `/run/nordvpn/nordvpnd.sock` itself)
  8. `ln -s /etc/sv/nordvpnd /var/service/`
  9. Killswitch persists in daemon config: `nordvpn set killswitch on` (no unit needed)
  - Verify: `sv status nordvpnd`, `nordvpn status`, `nordvpn connect`
  - waybar `vpn.sh` calls `nordvpn status` — unchanged.

### Brave
- **VUP** (Void User Packages, `voiduserpackages.org`) — the AUR equivalent. Prebuilt, CI-built, RSA-signed `.xbps`, no compiling:
  ```
  xbps-install -R https://github.com/VUP-Linux/vup/releases/download/core-x86_64-current -S vuru
  vuru install brave
  ```
- Template repackages the **official Brave zip** to `/opt/brave` — native install, so the 1Password extension native-messaging manifest is seen (Flatpak would isolate it). Wrapper auto-adds `--ozone-platform=wayland` on Wayland sessions.
- **Update handling RESOLVED** (was open item): VUP CI bumps the version; `vuru install -Su` handles it.
- Caveat: VUP is unofficial, small (~27 packages), policy is "builds are not review" — inspect templates. Official repos stay primary.
- Fallback if VUP goes stale: convert Brave's `.deb` via xdeb (same path as NordVPN).

### nom (RSS reader)
- Not in Void. `rustup` then `cargo install nom` (repo: guyfedwards/nom). Updates = re-run install.

### Obsidian
- Not in Void, not in VUP. Options (decide during migration):
  - **AppImage** (official): needs `fuse`; add `--ozone-platform=wayland`; manual updates.
  - **Flatpak** (`md.obsidian.Obsidian`): auto-updates; sandbox needs `--filesystem=~/Dropbox` overrides + git talk-name for the sync plugin.
  - **tar.gz → `/opt/Obsidian`** (recommended, same pattern as 1Password): native, no FUSE/sandbox; manual updates.
  - **xdeb** of the `.deb`: reuses NordVPN toolchain; native.
- Vault lives in `~/Dropbox/obsidian/home_vault` — native installs see it without sandbox overrides.

### opencode
- Not in Void. `curl -fsSL https://opencode.ai/install | bash` → `~/.local/bin`.
- Config/db (`~/.local/share/opencode`, `~/.config/opencode`) carry over as-is.

## Session layer (user services on Void)

Currently under `systemd --user`; re-parent on Void:

| Now (systemd --user) | On Void |
|---|---|
| mako.service | `spawn-at-startup "mako"` in niri config |
| pipewire / wireplumber / pipewire-pulse | `spawn-at-startup` ×3 |
| ssh-agent.service | shell rc or runit-user |
| gvfs-*, xdg-desktop-portal-*, at-spi | D-Bus activated (works on Void) |
| dbus-broker | Void uses classic dbus (`/etc/sv/dbus`) |
| app-*@autostart (1Password, dropbox, blueman, nm-applet) | XDG autostart or `spawn-at-startup` |

- PipeWire has **no runit system service on Void** (issue #59608) — Void docs recommend per-session start; `spawn-at-startup` is exactly the recommended pattern.
- No `systemd --user` = no automatic D-Bus session bus. Need one manually: start Niri via `dbus-run-session -- niri`, or install **elogind** (also gives loginctl/suspend/lid handling). OPEN — decide during migration.

## Service map (systemd → runit)

| systemd | Void /etc/sv |
|---|---|
| systemd-udevd | udevd |
| systemd-logind | elogind |
| dbus-broker | dbus (no broker) |
| systemd-journald | svlogd/vlogger per-service logs (no journald) |
| systemd-resolved | none — NetworkManager + openresolv |
| systemd-timesyncd | chronyd |
| bluetooth | bluetoothd |
| NetworkManager | NetworkManager |
| wpa_supplicant | wpa_supplicant (usually unnecessary; NM handles wifi) |
| tailscaled | tailscaled |
| polkit | polkitd |
| power-profiles-daemon | power-profiles-daemon |
| rtkit-daemon | rtkit |
| udisks2 | NOT shipped — create /etc/sv/udisks2 manually |
| upower | D-Bus activated — no sv |
| user@1000 | none — session via elogind |
| systemd-userdbd | n/a |
| ly@tty1 | not in Void — use greetd or tty + startx |
| nordvpnd (+ socket) | nordvpnd (see NordVPN) |

User services (pipewire.socket, pipewire-pulse.socket, wireplumber, ssh-agent, p11-kit-server, xdg-user-dirs):
- pipewire/wireplumber: `spawn-at-startup` (see session layer).
- ssh-agent / p11-kit-server: start via shell rc, or user-level runsvdir.
- xdg-user-dirs: run xdg-user-dirs-update once; no service.

## Gotchas / open items

- udisks2 has no shipped runit service in void-packages → manual sv.
- `-S` + install is idiomatic on Void (xbps resolves full dep transaction); still prefer `-Syu` habit before installing on a stale system. `void-repo-nonfree` requires a follow-up `-S`/`-Syu` to sync the new repo index.
- Services enable = symlink into /var/service; never auto-enabled by install.
- No systemd timers → cron for things like fstrim.
- Session bootstrap: no systemd --user → D-Bus session via `dbus-run-session -- niri` or elogind. OPEN (decide during migration).
- 1Password updates: **manual** (Option A). Built-in updater unreliable on Linux — verified (binary stuck at 8.12.30 while 8.12.32 exists).
- Brave update handling: **RESOLVED** via VUP (was open item as of 2026-08-14).
- NordVPN: re-run xdeb after deb version bumps; no update tracking. Install on same machine as conversion.
- Obsidian install method: OPEN.
- VUP: unofficial repo, "builds are not review" — inspect templates before installing.
