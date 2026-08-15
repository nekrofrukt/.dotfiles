# Void pipewire / waybar fix (in progress)

Log of the "waybar not working" investigation on Void (niri, greetd, runit,
elogind). **Paused 2026-08-15 — way too tired. Resume from "Remaining steps".**

## Symptom

Waybar never appeared under niri. `mako` and `swaybg` (spawned the same way)
run fine, so spawning itself works. Also noticed: **`swayidle` is not
installed** on Void (separate issue — idle lock/timeout silently failing).

## Diagnostic trail (2026-08-15)

Run `waybar 2>&1 | head -40` in a terminal:

```
[warning] module niri/mode: Unknown module: niri/mode
[info] Niri IPC starting
Failed to create secure directory (/run/user/1000/pulse): Too many open files
socket(): Too many open files
shared memfd open() failed: Too many open files
...
```

- `niri/mode` unknown → Void's waybar 0.15.0 build lacks that module
  (workspaces/window loaded fine — "Niri IPC starting"). Cosmetic.
- The libpulse errors are the killer: `Too many open files` = **EMFILE**, the
  process hit its FD limit before libpulse could even initialize.

While waybar was alive: `ls /proc/$(pgrep -x waybar)/fd | wc -l` ≈ 1024, of
which **1005 were `(deleted)`** files. Anonymous in-memory files (memfd) always
show as deleted → **~1000 leaked memfd FDs**.

### Limits / system health

- Session soft nofile **1024 / hard 4096** (PAM default; nothing in
  `/etc/security/limits.conf` or `limits.d/` except Void-shipped
  `25-pw-rlimits.conf` for pipewire RT — references a `@_pipewire` group that
  isn't created by default, so RT falls back to rtkit).
- The limit is set at greetd login → niri → waybar all inherit 1024. (An
  interactive shell showed 4096 — different PAM path, misleading.)
- System is healthy: 15Gi RAM / 13Gi available, `max_map_count` 65530, no
  cgroups, low load. The `fork(): Cannot allocate memory` (ENOMEM) seen later
  is downstream noise of the FD exhaustion, not a memory problem.

### No audio server

- `/run/user/1000/` has no `pulse` dir. `pipewire`/`wireplumber`/`pipewire-pulse`
  are **not running**. No pulse/pipewire runit services exist.
- Only client libs were installed at first (`libpipewire`, `libpulseaudio`,
  `wireplumber`); the `pipewire` daemon was missing.

### Root cause (conclusion)

waybar's `pulseaudio` module has no Pulse server to connect to, so libpulse
retries, **leaking one memfd per attempt** until the FD table hits the soft
limit 1024 → EMFILE → waybar dies before rendering. `niri/mode` is unrelated
and cosmetic. (Waybar also died from SIGPIPE after the manual `| head -40`
test — it is not running now.)

## Important Void fact: there is no `pipewire-pulse` package

`sudo xbps-install -S pipewire-pulse` → "Package 'pipewire-pulse' not found in
repository pool." On Void the PulseAudio-compatible server is **built into
`pipewire`**: `/usr/bin/pipewire-pulse` (symlink to the pipewire binary),
`/usr/share/pipewire/pipewire-pulse.conf`, and the man pages come from the
`pipewire` package itself. Nothing to install for the pulse server — just run
`pipewire-pulse`.

## Current installed state

- Installed (by me, via `sudo xbps-install`): `pipewire` (with `wireplumber`),
  `pulseaudio-utils`. `alsa-pipewire` **NOT** installed yet.
- `pipewire`, `wireplumber`, `pipewire-pulse` **not running**, not configured,
  no drop-ins, nothing in niri config yet.

## Void Handbook grounding (docs.voidlinux.org/config/media/pipewire.html)

- Prereqs: active D-Bus session bus (we have `dbus-run-session niri --session`)
  and `XDG_RUNTIME_DIR` (set). elogind present → audio/video groups not
  required (user is in them anyway).
- Session management: "ensure proper startup ordering, PipeWire should be
  configured to launch the session manager directly" → per-user drop-in
  symlink `10-wireplumber.conf` into `~/.config/pipewire/pipewire.conf.d/`.
- PulseAudio interface: same idea, `20-pipewire-pulse.conf` into
  `~/.config/pipewire/pipewire.conf.d/`.
- ALSA integration: install `alsa-pipewire`, then symlink
  `/usr/share/alsa/alsa.conf.d/50-pipewire.conf` and
  `99-pipewire-default.conf` into `/etc/alsa/conf.d/`.
- Launching: "**Use your window manager's startup scripts**: pipewire can be
  launched directly from your window manager or Wayland compositor's startup
  script." → niri `spawn-at-startup "pipewire"`. "Launching pipewire should be
  sufficient to establish a working PipeWire session that uses wireplumber."
- Other launch options considered and rejected: system runit symlink
  (`/etc/sv/pipewire` → `/var/service`) is wrong (must run as $USER; this
  pipewire package ships no /etc/sv files anyway); XDG autostart symlinks
  (`~/.config/autostart/` + `dex`) and vsv user services were offered, user
  chose **plain niri spawn**.

## Decision

User chose **plain niri spawn-at-startup** (1 line). During planning, the
Handbook's drop-in method was adopted as the refined version: **one** spawn of
`pipewire`, which then launches `wireplumber` + `pipewire-pulse` itself via the
two config drop-ins → no startup-order race. (Alternative still available: 3
explicit spawns, racier.)

## Remaining steps

1. Install: `sudo xbps-install alsa-pipewire` (+ optional `rtkit` for RT
   priority). **OPEN DECISION**: do the system-wide ALSA symlinks (step 2) or
   skip ALSA for now and only fix waybar?
2. ALSA integration (root, only if wanted):
   ```
   sudo mkdir -p /etc/alsa/conf.d
   sudo ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
   sudo ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/
   ```
3. Per-user drop-ins (correct startup ordering):
   ```
   mkdir -p ~/.config/pipewire/pipewire.conf.d
   ln -s /usr/share/examples/wireplumber/10-wireplumber.conf ~/.config/pipewire/pipewire.conf.d/
   ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf ~/.config/pipewire/pipewire.conf.d/
   ```
   (Both example files verified present.)
4. niri config: add to `~/.dotfiles/niri/.config/niri/config.kdl`:
   `spawn-at-startup "pipewire"`.
5. Insurance — raise the session nofile ceiling (applies next login):
   `/etc/security/limits.d/99-user.conf` → `nekrofrukt soft nofile 4096`
   (coexists with the shipped `25-pw-rlimits.conf`).
6. Cleanup — remove the dead `niri/mode` block from
   `~/.dotfiles/waybar/.config/waybar/config.jsonc` (unknown module in Void's
   waybar 0.15.0 build).
7. Verify (in a terminal, before rebooting):
   - `wpctl status` → device list, not empty
   - `pactl info` → `Server Name: PulseAudio (on PipeWire ...)`
   - `waybar 2>&1 | head -20` → no `Too many open files`
8. Reboot (greetd re-applies limits; niri spawns pipewire at login).
9. Also still open from earlier: `swayidle` is not installed (idle lock
   silently broken) — install and wire it up.

## Fallback if the pulse module still misbehaves

Drop `pulseaudio` from `modules-right` in the waybar config (and/or raise
nofile further). The module only worked when a real server was reachable.
