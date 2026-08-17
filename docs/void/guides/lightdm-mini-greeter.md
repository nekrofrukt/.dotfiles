# Void Linux — lightdm + lightdm-mini-greeter setup

Date: 2026-08-16 · Void Linux (runit)

## 1. Install packages
```
xbps-install lightdm lightdm-mini-greeter xorg mesa-dri mesa-vulkan-intel
```
(replace `mesa-vulkan-intel` with `mesa-vulkan-radeon` for AMD, or `nvidia` for NVIDIA)

## 2. Enable services
```
ln -s /etc/sv/dbus /var/service/
ln -s /etc/sv/lightdm /var/service/
```
(`elogind` may also be linked; a one-time "elogind is already running" message at boot is normal and harmless.)

## 3. Configure /etc/lightdm/lightdm.conf
Under `[Seat:*]`:
```
greeter-session=lightdm-mini-greeter
user-session=sway
```
(`user-session` value must match a session file in /usr/share/wayland-sessions/)

## 4. Configure /etc/lightdm/lightdm-mini-greeter.conf
Under `[greeter]`:
```
user = <username>
```

## 5. Start / verify
```
sv up lightdm
sv status lightdm     # -> run
```
Greeter appears on tty7 (Ctrl+Alt+F7).

## 6. Greeter on external display when the lid is closed (2026-08-16)

### Symptom
Rebooting with the lid closed + external monitor connected: the greeter
renders on the closed internal panel (`eDP-1`) instead of the external.

### Root cause
lightdm boots an Xorg server and lightdm-mini-greeter (GTK3/X11) draws on the
**primary** output, which defaults to the built-in `eDP-1`. Sway's lid handling
(`bindswitch` + `lid-state.sh`) only runs *after* login, so nothing fixed it at
the greeter stage.

### Fix
1. Install the X client tool:
   ```
   xbps-install -S xrandr
   ```
2. Script: `~/.dotfiles/lightdm/scripts/lid-external.sh` (in the repo, executable):
   - exits early if the lid is open (`/proc/acpi/button/lid/LID/state`);
   - exits early if no external connector is connected (same `/sys/class/drm`
     loop as `/etc/acpi/handler.sh`, skipping `eDP-*|LVDS-*|DSI-*`);
   - else `xrandr --output eDP-1 --off` so the greeter has only the external left.
3. Hook it in `/etc/lightdm/lightdm.conf` under `[Seat:*]`:
   ```
   display-setup-script=/home/nekrofrukt/.dotfiles/lightdm/scripts/lid-external.sh
   ```
   lightdm runs this right after Xorg starts, before the greeter, with `DISPLAY` set.

### Why it's safe
- Only affects the greeter's X display; sway re-detects outputs on login and
  re-enables `eDP-1` via its own lid handling.
- Lid open or no external → script no-ops, normal behavior.
- `/etc/lightdm/lightdm.conf` is an xbps conf_file → survives updates.
- Verify: lid closed → reboot (or `sudo lightdm --test-mode`).

## Key facts
- lightdm is compiled with default `greeter-session=lightdm-gtk-greeter`; must be overridden for mini-greeter.
- lightdm-mini-greeter is single-user — it requires `user = <username>` or auth always fails.
- Greeter is X11; its output placement is controlled from `display-setup-script` (see §6) — Sway-only lid config can't help there.
- The GPU driver (`mesa-dri` + a Vulkan ICD) is required; without it sway fails with
  `ERROR_INCOMPATIBLE_DRIVER (-9) / Could not initialize EGL`.
- Logs: `/var/log/lightdm/lightdm.log`, `~/.xsession-errors`
