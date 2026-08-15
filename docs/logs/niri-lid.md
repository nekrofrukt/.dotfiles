# Niri closed lid issue on Void

Log of things done/fixed on the Void machine (niri, runit, greetd). Companion to
`arch-to-void.md`; AGENTS.md has the older system-level notes.

## Lid close + external monitor (2026-08-15)

### Symptom
Closing the lid with the external Dell (HDMI-A-2) connected suspended the whole
machine. On Arch the same setup worked: closing the lid left the external
running. (Arch never "migrated" windows either — the external just kept showing
its own workspace.)

### Root cause
Void's **acpid** (base default, runit service) runs `/etc/acpi/handler.sh`,
whose `button/lid close` case calls `zzz` (suspend) **unconditionally** — no
awareness of external displays. Arch had no acpid; `systemd-logind` used its
"docked" detection (external display connected → `HandleLidSwitchDocked=ignore`)
so the lid was ignored.

elogind (252.39) is the other lid handler, but per its man page
`HandleLidSwitchExternalPower` is *ignored by default* (backwards compat), so on
AC it never acts on the lid — acpid was the suspender. Verified: the machine
was on AC and still suspended → acpid guilty.

### Fix (kept)
`/etc/acpi/handler.sh` — `button/lid` `close` case now checks for a connected
external connector before suspending:

```sh
close)
    # Keep running if an external display is connected (like Arch's
    # logind "docked" handling); suspend only when truly on the go.
    for c in /sys/class/drm/card*-*/status; do
        case "$c" in
            *eDP-*|*LVDS-*|*DSI-*) continue ;;
        esac
        [ "$(cat "$c" 2>/dev/null)" = "connected" ] && exit 0
    done
    logger "LID closed, suspending..."
    zzz
    ;;
```

- eDP/LVDS/DSI = internal panels, skipped so they don't count as external.
- `/etc/acpi/handler.sh` is a xbps **conf_file** (`xbps-query -p conf_files
  acpid`) → preserved across package updates.
- Result: lid close + external connected → no suspend, external keeps running.
  No external → still suspends via `zzz`.

### Tried and removed
A `lid-monitor` watcher that collapsed everything onto the external on lid
close. It **worked mechanically** but was decided unnecessary:

- `~/.dotfiles/scripts/utilities/lid-monitor`: polled
  `/proc/acpi/button/lid/LID/state` (verified it updates — "closed"/"open");
  on `closed` ran `niri msg output eDP-1 off` (niri migrates all windows, the
  external becomes the sole output at position 0,0); on `open` ran
  `niri msg output eDP-1 on`. Guarded so it only acted when ≥2 outputs were
  connected.
- Wired via `spawn-at-startup "/home/nekrofrukt/.dotfiles/scripts/utilities/lid-monitor"`
  in `niri/.config/niri/config.kdl`.
- niri 26.04 supports `niri msg output <name> off|on` (temp, not saved to
  config). `output off` leaves the connector in `niri msg outputs` (marked
  Disabled) so it can be turned back on — verified live.
- **Removed 2026-08-15**: Arch never moved windows to the external either; the
  handler.sh fix alone reproduces the Arch behavior. Script deleted, spawn line
  removed, manual instance killed. `config.kdl` is back to the original 15 lines.

### Useful facts (in case it comes up again)
- `/proc/acpi/button/lid/LID/state` exists and updates (proc-based polling works).
- Lid is an evdev input device (`/dev/input/event10`, root:input — not user-readable).
- `/run/acpid.socket` is world-writable (0666) → a user process can connect and
  read the same events acpid acts on, e.g. via `acpi_listen` (`button/lid LID close`).
- elogind is running but NOT a runit service (`/var/service` has no elogind; it's
  dbus-activated). `HandleLidSwitchExternalPower` is deliberately unset by default.
