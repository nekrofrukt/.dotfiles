# elogind & shutdown — DRM warning fix

Date: 2026-08-15 · Context: trial Void install with greetd → niri

## Symptom

`sudo shutdown` (and the power button) made niri spam:

```
WARN niri::backend::tty: error queueing frame: The underlying drm surface encountered ...
```

then shut down ugly.

## Root cause

Two independent power paths existed on the system:

- `sudo shutdown` → runit's `/sbin/shutdown` script → `/sbin/halt`
  (an ELF that calls `reboot()` **directly** — never consults any session manager).
- elogind, which owns the session and can end it gracefully, was only running
  as a **D-Bus-activated fallback** (`org.freedesktop.login1.service` →
  `elogind --daemon`) — nothing ever routed shutdown through it.

So the kernel halved the DRM device while niri still held DRM master → warning loop.
On Arch this never happened because systemd-logind SIGTERMs the session first
(niri quits gracefully on SIGTERM — niri#2435) and only then powers off.

## The fix (matches the handbook, Part 1)

1. **Enabled elogind + polkitd as runit services** (the Void handbook: D-Bus
   activation "can lead to issues" — always enable the service):
   ```
   # ln -s /etc/sv/elogind /var/service/
   # ln -s /etc/sv/polkitd  /var/service/
   ```
   > Transition on a machine where elogind is already running via D-Bus:
   > `# pkill -x elogind` first, or runit's instance exits (an instance exists)
   > and runit restarts it → loop. On a fresh install (handbook) this race
   > doesn't exist.

2. **elogind config** (`/etc/elogind/logind.conf`): `HandlePowerKey`,
   `HandleSuspendKey`, `HandleLidSwitch*` → `ignore`. acpid stays the single
   hardware-key handler (previously both acpid and elogind reacted to the
   power button).

3. **acpid** (`/etc/acpi/handler.sh`): `button/power` now calls
   `loginctl poweroff` instead of `shutdown -P now` — the power button goes
   through elogind's graceful path too.

4. **Shutdown rule going forward**: `loginctl poweroff|reboot|suspend`.
   Never plain `shutdown`/`reboot`/`systemctl suspend`.

## Result

`loginctl poweroff` → elogind SIGTERMs the session → niri quits cleanly and
releases DRM → elogind execs `/sbin/poweroff` → clean shutdown. No warning loop.
