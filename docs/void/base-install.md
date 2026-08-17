# Void Linux — install handbook

A step-by-step checklist for building a working Void desktop from a fresh base install.

Two desktop tracks — **pick one**:

- **Track A — Niri** — tiling Wayland compositor (this laptop).
- **Track B — GNOME** — full desktop (the old MacBook).

Parts **0**, **1** and **2** are shared and needed by both tracks.
After your track, install **Part 3 (other apps)**.

> Tip: commands with `#` run as root, `$` as your user.

---

## Part 0 — Before you start

### 0.1 Install the base system

Boot the Void **base** ISO and run `void-installer` (glibc image).

- Everything in the base install is **already included** — do **not** re-install it:
  base-system, linux kernel, dracut, GRUB, man-pages + mandoc, acpid, sudo,
  openssh, dhcpcd, wpa_supplicant, eudev, runit.
- Reboot into your new system. Log in as `root`.

### 0.2 Update

```
# xbps-install -Syu
```

### 0.3 Enable the nonfree repo (needed for Intel microcode)

```
# xbps-install -S void-repo-nonfree
# xbps-install -Syu
```

### 0.4 Install CPU microcode

**Intel CPU** → do this step.

**AMD CPU** → skip. `linux-firmware-amd` (already in base) contains AMD CPU microcode and loads it automatically.

For Intel:

```
# xbps-install -S intel-ucode
```

Then rebuild the initramfs so the microcode is included at early boot:

```
# xbps-reconfigure -f linux
```

> Why: `linux-firmware-intel` only carries GPU (i915) firmware, not CPU microcode. `early_microcode=yes` is already set in `/usr/lib/dracut/dracut.conf.d/amd_ucode.conf` — after installing `intel-ucode`, dracut picks it up automatically on reconfigure.

**Check:** `sudo reboot`, then `grep -m1 microcode /proc/cpuinfo` — a non-`0x100` value means the update applied.


### 0.5 Install base packages

```
# xbps-install -Syu
# xbps-install -S base-devel git wget vim stow dbus elogind polkit pipewire alsa-pipewire alsa-utils alsa-lib alsa-plugins alsa-firmware libspa-bluetooth rtkit pavucontrol NetworkManager network-manager-applet blueman power-profiles-daemon
```

### 0.6 Optional — LTS kernel as a fallback

Keeps a proven kernel around in case a new mainline release misbehaves on your hardware.

```
# xbps-install -S linux-lts linux-lts-headers
# grub-mkconfig -o /boot/grub/grub.cfg
```

**Check:** reboot into the GRUB menu (5 s timeout) — both kernels are listed. Pick with the arrow keys. To boot LTS by default, set `GRUB_DEFAULT` in `/etc/default/grub`.

---

## Part 1 — Services (shared)

### 1.1 Enable the core services

Then enable them, one symlink each. Order matters: **dbus first**, then elogind and polkitd.
> If a symlink already exists in `/var/service/` (the installer may have linked `dbus`), skip it — `ln -s` would just error out.

```
# ln -s /etc/sv/dbus /var/service/
# sv up dbus
# sv check dbus
# ln -s /etc/sv/elogind /var/service/
# ln -s /etc/sv/polkitd /var/service/
```

**Check:** `ls /var/service/` shows `dbus`, `elogind`, `polkitd`; `sv status elogind polkitd` reports `run`.

> Why elogind as a service (not D-Bus activation): the elogind package can auto-start on demand, but that lazy fallback causes session/power weirdness. The Void handbook: *"If you're having any issues with elogind, enable its service."* The service wrapper also mounts the cgroup and `/run/user` tmpfs (your `XDG_RUNTIME_DIR`).

### 2.1 Tell elogind to leave the hardware keys to acpid

`/etc/elogind/logind.conf`, under `[Login]`, set:

```ini
HandlePowerKey=ignore
HandleSuspendKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

> `ignore` only stops elogind reacting to *physical buttons*. Explicit commands like `loginctl poweroff` still work. acpid becomes the single hardware-key handler (next step).

### 2.2 Make the power button shut down cleanly

acpid is already installed and running (it comes with the base install). Edit `/etc/acpi/handler.sh`:

1. Find the `button/power` case.
2. Replace the `shutdown -P now` line with:

```sh
logger "PowerButton pressed: $2, shutting down..."
loginctl poweroff
```

The lid handler is the one thing we deliberately **don't** keep stock — the default `close)` case calls `zzz` unconditionally, so the laptop suspends even when docked to an external monitor. Fix it in step 2.2.1.

> Default behaviour: the power button **powers the machine off**, not suspends (the Void acpid default is `shutdown -P now`). This step keeps that behaviour but routes it through elogind for a clean quit. To make the power button suspend instead, use `loginctl suspend` on that line and drop the log message.

**Check:** `sv status acpid` reports `run`; restart it if you changed anything: `# sv restart acpid`.

### 2.2.1 Don't suspend on lid close when an external display is connected

The stock `button/lid` `close)` case in `/etc/acpi/handler.sh` calls `zzz` unconditionally. With elogind ignoring the lid (2.1), acpid is the only thing reacting to it — so a lid close suspends even when the laptop is docked. Make the handler only suspend when no external display is connected (the equivalent of logind's "docked" handling on Arch):

```sh
close)
    # keep running if an external display is connected
    for c in /sys/class/drm/card*-*/status; do
        case "$c" in
            *eDP-*|*LVDS-*|*DSI-*) continue ;;
        esac
        [ "$(cat "$c" 2>/dev/null)" = "connected" ] && exit 0
    done
    # suspend-to-ram
    logger "LID closed, suspending..."
    zzz
    ;;
```

> `*eDP-*|*LVDS-*|*DSI-*` are the internal panels; anything else that's `connected` counts as external. Closing the lid with the HDMI monitor connected keeps the session running (sway disables eDP-1, the external stays on); unplugged, it suspends. See `docs/logs/niri-lid.md` for the original debugging of this exact issue.

### 2.3 The shutdown rule

Use `loginctl` for power actions. **Never** plain `shutdown`, `reboot`, or `systemctl suspend`.

| Instead of | use |
|---|---|
| `sudo shutdown now` | `loginctl poweroff` |
| `reboot` | `loginctl reboot` |
| `systemctl suspend` | `loginctl suspend` |

> Why: runit's `/sbin/halt` (which `shutdown`/`reboot` call) does a raw `reboot()` syscall while niri still owns the DRM device → the terminal spams `WARN niri::backend::tty: error queueing frame: ...` and shutdown looks broken. `loginctl` first tells niri to quit gracefully (it releases DRM), then powers off.

Optional — add these aliases to `~/.bashrc`:

```bash
alias poweroff='loginctl poweroff'
alias reboot='loginctl reboot'
alias suspend='loginctl suspend'
```

The rofi power menu in the dotfiles already uses `loginctl` (see Part 3 / Track A).

---

### 3 Audio

> `pipewire` pulls `wireplumber` (session manager) and `pulseaudio-utils` automatically.
> `libspa-bluetooth` = Bluetooth audio; `rtkit` = real-time scheduling permissions for PipeWire.

### 3.1 Route ALSA apps through PipeWire

```
# mkdir -p /etc/alsa/conf.d
# ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
# ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/
```

### 3.2 Make `pipewire` start its helpers

These two symlinks tell the `pipewire` process to launch the session manager
(wireplumber) and the PulseAudio server (pipewire-pulse) itself — one command
starts everything.

```
# mkdir -p /etc/pipewire/pipewire.conf.d
# ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
# ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
```

> PipeWire runs **per user session**, not as a runit service. Each track below shows the startup step (just launch `pipewire`).

**Check (once running):** `pactl info | grep "Server Name"` shows `PulseAudio (on PipeWire ...)`, and `wpctl status` lists devices.

### 4 Networking + extra services

NetworkManager (replaces the base dhcpcd/wpa_supplicant):

```
# ln -s /etc/sv/NetworkManager /var/service/
# rm -f /var/service/dhcpcd
# rm -f /var/service/wpa_supplicant
```

> dhcpcd/wpa_supplicant ship with the base install; whether they are enabled depends on the `void-installer` "Network" step (it can enable dhcpcd). If they are enabled, remove the symlinks before starting NetworkManager so they don't fight over the interface. `rm -f` is safe even if the symlink does not exist.
> Package names are case-sensitive: it's `NetworkManager` (capital N) and `Waybar` (capital W).

Bluetooth and power profiles:

```
# ln -s /etc/sv/bluetoothd /var/service/
# ln -s /etc/sv/power-profiles-daemon /var/service/
```

- `blueman` — Bluetooth tray/manager app.
- `power-profiles-daemon` — laptop power profiles over D-Bus.
- Tailscale (if you use it): `# xbps-install -S tailscale && ln -s /etc/sv/tailscaled /var/service/`

**Check:** `sv status NetworkManager bluetoothd power-profiles-daemon` all report `run`.

---

## Part 3 — Niri

### A.0 Dotfiles (niri session)

The repo carries niri/foot/mako/waybar/etc. configs. With stow:

```
$ git clone <your dotfiles repo> ~/.dotfiles
$ cd ~/.dotfiles && stow -t ~ niri foot mako waybar swaybg swayidle swaylock rofi dejavu-fonts-ttf xorg-fonts
```

- `config.kdl` already spawns waybar, mako, polkit-gnome agent, swayidle and swaybg on startup — the polkit-gnome spawn now works that the package is installed.
- Use the **`rofi-void`** variant (power menu uses `loginctl`, VPN script uses Mullvad).
- On the trial install (no git push), stage Void-specific files in `~/.dotfiles/docs/_temp-void-dots`.

PipeWire runs per session. With the Part 2.3 symlinks in place, one spawn starts
wireplumber and pipewire-pulse too. Add to the `spawn-at-startup` block in `config.kdl`:

```kdl
spawn-at-startup "pipewire"
```

### A.1 Install

```
# xbps-install -S sway lightdm lightdm-mini-greeter xorg-minimal mesa-dri mesa-vulkan-intel xwayland-satellite swaybg swayidle swaylock Waybar mako nautilus sushi foot fuzzel firefox rofi polkit-gnome xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-wlr brightnessctl xdg-utils void-docs-browse dejavu-fonts-ttf xorg-fonts noto-fonts-ttf nerd-fonts noto-fonts-emoji xrandr bash-completion
```

- `niri` — the compositor.
- `greetd` — the login screen (greeter).
- `xwayland-satellite` — runs X11 apps under niri.
- `swaybg` / `swayidle` / `swaylock` — wallpaper, idle, screen lock.
- `polkit-gnome` — the GUI password prompt (niri ships no auth agent, so without it every polkit action is silently denied).
- `xdg-desktop-portal` + `xdg-desktop-portal-gnome` — screen sharing in Brave calls, Flatpak integration.
- `brightnessctl` — backlight control.

### A.2 Login screen (lightdm)

```
# ln -s /etc/sv/lightdm /var/service/
```

**Check:** reboot — you land on the greeter.

### A.3 Verify

- `sv status dbus elogind polkitd greetd NetworkManager bluetoothd acpid` — all `run`
- `loginctl list-sessions` — your session on `seat0`
- `pactl info | grep "Server Name"` — PulseAudio on PipeWire
- `wpctl status` — devices listed
- `loginctl poweroff` — clean quit, **no** DRM warning
- Screen share in Brave works (portal)

---

## Part 3 — Other apps (install after your track)

### Terminal & shell

```
# xbps-install -S fzf neovim starship ripgrep tree unzip dialog fastfetch yazi tailscale wl-clipboard
```

### Status bar & notifications

`xbps-install -S playerctl libnotify`


### Browser & passwords

```
# xbps-install -S vuru
# vuru sync && vuru install brave-bin
```

- Brave is built natively via vuru (`brave-bin`) so the **1Password extension** keeps its native-messaging manifest.
- **1Password**: Brave extension only for now (desktop app deferred). Keep the 24-word recovery code — sync is the source of truth.

### VPN — Mullvad (WireGuard)

```
# xbps-install -S wireguard-tools
```

After placing your config in `/etc/wireguard/` and setting permissions:

```
# chown root:root /etc/wireguard/*.conf && chmod 600 /etc/wireguard/*.conf
```

Enable passwordless `wg-quick` for the rofi/waybar toggle (drop-in sudoers rule):

```
# visudo -f /etc/sudoers.d/z-wg-quick
```

```
nekrofrukt ALL=(root) NOPASSWD: /usr/bin/wg-quick up <interface>, /usr/bin/wg-quick down <interface>, /usr/bin/wg show <interface>
```

Replace `<interface>` with your config filename (e.g. `se-sto-wg-001`).

> **Void quirks**:
> - The filename **must sort after `wheel`** alphabetically (e.g. `z-wg-quick`).
>   `@includedir` processes files in lexical order, and the **last matching rule
>   wins** in sudo — if your file sorts before `wheel`, the `%wheel ALL=(ALL:ALL) ALL`
>   rule overrides your NOPASSWD.
> - The stock `/etc/sudoers.d/wheel` ships with wrong permissions — sudo silently
>   skips the whole directory. Fix: `# chmod 0440 /etc/sudoers.d/wheel`

Verify: `sudo -n wg show <interface>` should work without a password.

The waybar `vpn.sh` and rofi VPN scripts are already rewritten for `wg`/`mullvad status`.

### Media & misc

```
# xbps-install -S vlc ffmpeg
```

---

## Reference — package availability

Everything below is in the main repo unless noted. `[-]` in `xbps-query -Rs` output means *available*, `[*]` means *installed*.

| package | repo | notes |
|---|---|---|
| `tuigreet` | main | 0.9.1_1 |
| `polkit-gnome` | main | GUI auth agent |
| `xdg-desktop-portal-gnome` | main | niri screen-share backend |
| `NetworkManager` | main | sv dir: `/etc/sv/NetworkManager` (capital N) |
| `power-profiles-daemon` | main | sv dir: `/etc/sv/power-profiles-daemon` |
| `rtkit`, `alsa-pipewire` | main | PipeWire stack |
| `intel-ucode` | **nonfree** | enable `void-repo-nonfree` |
| `linux-lts` | main | optional fallback kernel |
