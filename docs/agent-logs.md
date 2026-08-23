# Agent Session Logs

Log entries from each working session, newest on top.

## xu-src hardening against incomplete releases (2026-08-23)

- Obsidian v1.13.8 was tagged on GitHub but shipped only the `.apk` asset — no Linux tarball — so `xu-src` 404'd mid-download and `set -e` killed the whole run (brave-origin never processed).
- Changes to `scripts/void/xbps/update-xbps-src`:
  - Check phase: when an update is detected, query the release via GitHub API and verify the configured distfile exists among assets; skip with a clear message if not published yet.
  - Tag-resolution curl guarded so network/API failure skips the package instead of aborting (`set -euo pipefail`).
  - Update phase: download failures and empty checksums now `continue` to the next package instead of killing the script; `rm` → `rm -f` on tmpfile cleanup.
- Verified: v1.13.7 tarball matches asset check, v1.13.8 correctly skipped, brave-origin v1.93.138 still offered; templates untouched by aborted dry run.
- Note: obsidian update will appear once upstream uploads `obsidian-1.13.8.tar.gz`; re-run `xu-src` then.

## Swaylock restyle to Gruvbox (2026-08-23)

- Replaced mixed-palette indicator colors in `swaylock/.config/swaylock/config` with Gruvbox dark: ring `8ec07c`, fill `282828d9`, verifying `83a598`, wrong `fb4934`, key-hl `fabd2f`, bs-hl `fe8019`.
- Kept wallpaper (`walls/night01.jpg`), font, radius/thickness, transparent line colors.
- Live config applies via existing symlink `~/.config/swaylock -> .dotfiles/swaylock/.config/swaylock`.

## Printscreening setup (2026-08-21)

- **TODO**: Set up screenshots properly on sway — currently no screenshot tool configured.
- Plan: `grim` + `slurp` (region select), `wl-copy` for clipboard; bind Print / region / window variants in sway config. Also registered in `~/Downloads/todo.md`.

## Boot clutter cleanup (2026-08-20)

- Removed 6 orphaned boot files (~121MB): vmlinuz/initramfs/config for 6.12.103_1 and 6.18.44_1.
- Regenerated GRUB — now shows 2 kernels (6.18.45_1 default + 6.12.104_1 LTS).
- **TODO**: After testing `sudo vkpurge rm all` manually at next kernel update, add `/etc/kernel.d/post-install/99-cleanup-old-kernels` hook that calls `vkpurge rm all` to automate future cleanup. Hooks run as root via xbps-triggers, no sudo needed.

## hey-cli xbps-src template + agent state file (2026-08-20)

### hey-cli xbps-src template (OPEN — blocked on Go 1.26.6)
- Created template at `srcpkgs/hey-cli/template` in void-packages.
- hey-cli requires Go 1.26.6, Void ships 1.26.5. `GOTOOLCHAIN=local` in xbps-src blocks the build.
- Attempted `pre_configure` hook to sed go.mod from 1.26.6 → 1.26.5. Still failed — pattern likely didn't match (need to verify go.mod format in builddir, or hook didn't run as expected).
- Decision: wait for xbps to update Go to 1.26.6 rather than hacking around it. **This build is still open.**
- hey-cli has no GitHub releases, only tag v0.1.0. Source tarball checksum: `26b379825628bbe4fbc5470d74c605fd1c960a839a5eddcc9340694a6f03fafe`.

### Agent state file
- Created `docs/void/xbps-src.md` — persistent state file for xbps-src. Meant for agent session-start reference: current packages, workflow, gotchas. NOT a manual — the vault manual (`void-xbps-src.md`) is the user's reference.
- Key distinction: vault manual = for user; state file = for agent. Don't conflate them.

### Opencode config
- Added verbosity instruction to `~/.config/opencode/opencode.jsonc`: "Be concise but explain context when it matters."
- Discussed but didn't implement: persisting `XBPS_ALLOW_RESTRICTED=yes` in `etc/conf` (doesn't exist yet, passes as env var per build).

### Polkit auth agent
- Added `exec /usr/libexec/polkit-gnome-authentication-agent-1` to sway exec.conf for GNOME Disks / udisks2 password prompts.
- Corrected path: Void uses `/usr/libexec/`, not `/usr/lib/polkit-gnome/`.

### D-Bus + Obsidian session
- D-Bus session fix confirmed working — Discord launches, all services running.
- Obsidian light mode: `appearance.json` was missing `"theme"` key. Added it back. Logged in vault manual entry.
- Created vault manual `void-dbus-session.md` with `#linux/void #linux/dbus` tags.

## Vault manual + Obsidian theme fix (2026-08-20)

- Added `#linux/void #linux/dbus` tags to `void-dbus-session.md` for agent discovery.
- Vault agent (`opencode/.config/opencode/agents/vault.md`) confirmed has `read: allow` for `~/Dropbox/obsidian/home_vault`.

- Created `void/manuals/dbus-session.md` in the vault — general D-Bus session bus guide (not Flatpak-specific), covering problem, two-part fix (.xprofile + sway exec.conf), and why the order matters.
- Obsidian suddenly in light mode: `appearance.json` was missing the `"theme"` key. Added `"theme": "obsidian"` back. Likely lost during a sync conflict (many conflicted workspace copies in `.obsidian/`). Our GTK dark mode changes didn't cause this — Obsidian uses its own Electron theming, not GTK.
- Discord confirmed working after the D-Bus session bus fix.

## Flatpak Discord D-Bus session bus fix (2026-08-20)

- Flatpak Discord still failed after reboot: `zypak-helper` couldn't connect to session bus (`DBUS_SESSION_BUS_ADDRESS` not set).
- Root cause: no session D-Bus daemon was running. Only the system bus (`dbus-daemon --system`) and the at-spi accessibility bus existed. `dbus-update-activation-environment` was trying to push env vars to a non-existent session bus.
- Two-part fix:
  1. Created `~/.xprofile` with `export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"` — lightdm's `Xsession` sources this before running sway, so all children (sway, flatpak, etc.) inherit the env var.
  2. Changed `exec.conf` line to: `exec sh -c 'dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus --fork && dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS'` — starts the daemon first, then pushes env vars into it.
- Key insight: `dbus-update-activation-environment` reads `DBUS_SESSION_BUS_ADDRESS` from the current environment to connect to the bus — it needs the var set before it runs. That's why `.xprofile` must come before sway.
- Testing: `export DBUS_SESSION_BUS_ADDRESS=...` in a terminal, start daemon, run `dbus-update-activation-environment`, launch Discord — same as what the config does manually. Rebooting to verify.

## OpenCode email issue + Flatpak Discord + D-Bus fix (2026-08-20)

### OpenCode GitHub email
- User had old GitHub email persisting in OpenCode dashboard after revoking OAuth and re-authenticating.
- Local OpenCode auth data (`~/.local/share/opencode/opencode.db`, `auth.json`) confirmed empty — no local caching.
- Issue is server-side in OpenCode's cloud backend. Old email appears under "members" in dashboard, payment flow defaults to it.
- Reached out on Discord (https://opencode.ai/discord). Awaiting response.

### Flatpak Discord
- Discord template exists in xbps-src (`srcpkgs/discord/template`, v1.0.154, orphaned, `nonfree` repo).
- Not published in remote repos — must be built locally with `XBPS_ALLOW_RESTRICTED=yes`.
- User opted for Flatpak instead (simpler, auto-updates). Installed via `flatpak install flathub com.discordapp.Discord`.

## spotify_player config + troubleshooting (2026-08-19)

- Created `spotify-player/.config/spotify-player/app.toml` stowable package. Based on user's existing `~/.config/spotify-player/app.toml` (dracula theme, custom playback format) with `audio_cache = true` and `device_type = "computer"`.
- Identified two issues: (1) token refresh broken due to Spotify's June 2026 policy change — requires v0.24.1+, user is on xbps v0.22.1; (2) `client_id` in app.toml is only for Spotify Connect, not needed for basic playback.
- Removed `client_id` from config. User will re-authenticate via browser each launch as workaround until spotify-player is updated.
- Also added AGENTS.md rule: never run stow, user handles it manually.
- Attempted cargo install but failed (missing openssl-devel). Cargo artifacts cleaned up.
- xbps package compiled without `image` and `notify` features (`spotify_player features` confirms) — cover art and mako notifications won't work until built from source with `--features image,notify`.
- Created rofi spotify controls (`rofi-void/.config/rofi/scripts/spotify`): prev/play-pause/next with horizontal layout (matches power-sway), pre-selects play button, truncates long track names at 40 chars. Uses `common.rasi` + `-theme-str` override.
- Created waybar spotify script (`waybar-sway/.config/waybar/scripts/spotify.sh`): Python, shows "Artist • Track" when playing, exits silently otherwise. No jq dependency.
- Added `Super+Alt+S` sway keybind for rofi spotify.
- Waybar config has module name mismatch: `modules-left` lists `"sway/spotify"` but module is defined as `"custom/spotify"` — user to fix.
- Rofi spotify track truncation at 40 chars may not be aggressive enough for the message bar width — revisit later.
- **PRIORITY**: Update spotify_player to v0.24.1+ via cargo or xbps-src. v0.22.1 has broken token refresh (Spotify June 2026 policy change). This causes: (1) app freezes with "Token is not valid" errors, (2) browser auth loops when any CLI command is called (including waybar script), (3) no cover art or mako notifications (image/notify features not compiled in xbps package). User must remove `custom/spotify` from waybar config until this is resolved.

## Swap file setup (2026-08-19)

- Created 4G swap file at `/swapfile` (`fallocate -l 4G`, `mkswap`, `swapon`). Added to `/etc/fstab`. Set `vm.swappiness=20` via `/etc/sysctl.d/`. Verified with `free -h` (4.0Gi swap), `swapon --show`, `/proc/sys/vm/swappiness`.

## Brave Origin xbps-src + mako/BT fix (2026-08-18)

- **Brave Origin**: replaced VUP install with xbps-src build. Created template at `~/src/void-packages/srcpkgs/brave-origin/` following the vivaldi pattern — downloads `brave-origin-{version}-linux-amd64.zip` from `github.com/brave/brave-browser/releases`, installs to `/opt/brave-origin/`, wrapper script in `files/brave-origin` adds Wayland flags. Key gotchas:
  - Zip extracts flat (no subdirectory), so `vinstall` icon loop must run before `vcopy . opt/brave-origin` and reference icons directly.
  - `vinstall FILE 0755 usr/bin/brave-origin` creates a directory — use `vinstall FILE 0755 usr/bin` (3-arg form installs to `destdir/$(basename file)`).
  - The actual binary is `brave` (300MB ELF), not `brave-origin` (shell wrapper). `vcopy . opt/brave-origin` copies both.
- **Update script** (`~/.dotfiles/scripts/void/xbps/update-xbps-src`): fully rewritten with:
  - `packages.conf` now has5 fields: `pkgname|source_type|source_args|distfile_suffix|running_check`
  - Download progress bar (curl `--progress-bar` to temp file, then sha256sum) instead of silent pipe.
  - `check_running()` function: checks comma-separated process names via `pgrep -x` before each update. Aborts with error if any are running.
  - Auto-install after build: finds `.xbps` in `hostdir/binpkgs/` (handles main vs nonfree), runs `sudo xbps-install`, falls back to printing manual command on failure.
  - Bug fix: nested `${}` in `${distfile_pattern:-${pkgname}-{version}.tar.gz}` caused bash brace-matching issues, producing broken URLs like `.zip.tar.gz}`. Fixed by resolving the default before storing in the UPDATES array.
- **Mako/BT**: `blueman-applet` was installed but not auto-started — sway has no XDG autostart handler. Added `exec blueman-applet` to `sway-void/.config/sway/modules/exec.conf`. Bluetooth connect/disconnect notifications now work again.

## LTS vmlinuz missing from GRUB menu (2026-08-18)

- linux-lts (meta-package) and linux6.12 were installed in earlier session, but LTS kernel didn't appear in GRUB advanced boot menu.
- Investigation: `vmlinuz-6.12.103_1` and `config-6.12.103_1` were **missing from `/boot`** despite `linux6.12` showing `[*]` installed status. Only `initramfs-6.12.103_1.img` existed. No file named `vmlinuz-6.12*` found anywhere on disk.
- Root cause: partial extraction during original package install — initramfs generated (post-install hook), but vmlinuz/config never landed in `/boot`. XBPS database wasn't aware.
- Key difference: `linux-lts` is a 0B meta-package depending on `linux6.12`. Force-reinstalling `linux-lts` only reinstalled the meta-package, not the actual kernel. Had to `sudo xbps-install -f linux6.12` directly.
- Fix: `xbps-install -f linux6.12` restored vmlinuz, regenerated initramfs via dracut, and `grub-mkconfig -o /boot/grub/grub.cfg` added both kernels to the boot menu.
- Note: `linux6.12` has `preserve: yes` so it won't auto-remove when orphaned.

## Kernel cleanup + LTS install (2026-08-18)

- User noticed 3 kernel images in `/boot`: `6.12.103_1`, `6.12.11_1`, `6.18.44_1` (running).
- Only `linux6.18-6.18.44_1` package is installed. The two 6.12 entries are orphaned boot files (no matching xbps packages, no initramfs for 6.12.103, config files only).
- Plan: install `linux-lts` (6.12 LTS) + `linux-lts-headers`, remove orphaned `/boot` files, `update-grub`, reboot to test LTS from GRUB.
- `sudo xbps-remove linux6.12-*` confirmed no packages to remove — orphaned files are just left in `/boot`.
- `linux-lts` available in Void repos (`xbps-query -Rs linux-lts`).

## LightDM mini-greeter config + preview (2026-08-18)

- Created `src/oc-temp/lightdm-preview.html` — static HTML mimicking the actual GTK rendering based on lightdm-mini-greeter source (`ui.c`). Learned that:
  - Layout is a 2-column GtkGrid (label left, input right), not stacked centered
  - `layout-space` = main window border-width (GTK container), not inner padding
  - `border-width` is shared between `#main` and `#password`, but `password-border-width` overrides for the input
  - No transparency option exists — blending into background is the only way to hide the main window
  - `password-character` accepts any unicode character (e.g. `●` for big dot)
  - Nerd Font icons work in `password-label-text` via font fallback
- Config changes applied to `/etc/lightdm/lightdm-mini-greeter.conf`:
  - `window-color` → `#1B1D1E` (matches background, no visible box)
  - `border-width` → `0px` (main window border removed)
  - `border-color` → `#F8F8F8`
  - `text-color` → `#F8F8F8` (lock icon white)
  - `password-border-color` → `#F8F8F8` (input border white)
  - `password-border-width` → `2px` (kept for input field)
  - `password-label-text` → `󰌾` (Nerd Font lock icon, U+F033E)
  - `password-alignment` → `center`
- User will reboot to test; also asked about `password-character` for bigger dot and icon scaling with font-size.

## Vault analysis of codex/linux/void (2026-08-18)

- Read all 5 log files from 2026-08-15 to catch up (PipeWire/waybar, VPN, elogind, lid handling).
- Ran full analysis of `~/Dropbox/obsidian/home_vault/codex/linux/void/` (7 files: 1 main handbook + 6 manuals).
- Key findings:
  - **Sway/niri identity crisis**: Part 2 of `void-base-install.md` says "Sway" and installs sway packages, but elogind-lidrules.md and the trial logs all reference niri. Never reconciled after switching compositors.
  - **Broken wikilink**: `elogind-lidrules.md` references `docs/logs/niri-lid.md` which doesn't exist in the vault.
  - **Wrong service in verify check**: `void-base-install.md:203` says `greetd`, should be `lightdm`.
  - ~~Part 3 TODOs~~: Done.
  - **Part 4**: Stub only (xbps-src, ssh-agent mentioned, not written).
  - **No troubleshooting section** anywhere.
  - WireGuard/Mullvad docs are the most polished (~95%).
- Cleaned up `elogind-lidrules.md`: removed debug log below the `opencode q:` marker (lines 85–155). Content was duplicate of §3.1 (same fix code) + historical context (lid-monitor script tried and removed, proc/acpi facts). User confirmed removal.
- ~~Still open: PipeWire/waybar remaining steps, sway/niri reconciliation, broken wikilink, greetd→lightdm fix, Part 3/4 completion.~~ All fixed.

## Opencode config cleanup + vault agent (2026-08-18)

- Removed unused files from `~/.dotfiles/opencode/.config/opencode/`: `package.json`, `package-lock.json`, `node_modules/` (leftover `@opencode-ai/plugin` dependency with no plugin code), `.gitignore`. Only `opencode.jsonc` and `agents/vault.md` remain.
- Decided on vault documentation structure: tags for agent discovery, `[[wikilinks]]` for user navigation, folders are loose (doesn't affect agent much).
- User moved Void docs from `~/.dotfiles/docs/void/` into Obsidian vault at `~/Dropbox/obsidian/home_vault/codex/linux/void/`. Structure: one main overview (`void-base-install.md`) + focused guides under `manuals/`.
- Introduced `ocq` convention: user marks questions/directives for opencode/vault agent in documents.
- Rewrote vault agent (`agents/vault.md`):
  - `mode: all` → `mode: subagent` (invoked by build agent via Task, no manual switching)
  - Updated directory list to match actual vault structure
  - Added explicit search strategy: grep tags → read files → follow `[[wikilinks]]` → check `ocq` markers
- User will restart opencode for agent changes to take effect.

## Session notes (2026-08-17 ~22:00)

- **M720 Bluetooth MAC fix**: MAC changed from `F0:8D` to `F0:96` in `rofi-void/.config/rofi/scripts/bluetooth` (bluetoothctl showed device as `F0:96`, script had wrong MAC)
- **Rofi main menu restructure**: renamed `main-utils` → `main-menu`, two-level menu: Utilities (BT/VPN/SSH), Applications (Spotify/Nom), Notes, Power
- **Rofi drun styling fix**: `theme.rasi` needed `background-color: transparent` on `element-icon`/`element-text` so selected state was visible; final style: `@bg-alt` bg + `@selected` text
- **nom install**: installed from GitHub releases tarball (v3.3.2). README references outdated v3.0.0. No Void package exists. No auto-update mechanism
- **bashrc-void updates**: added `~/.local/bin` to PATH, bash-completion sourcing
- **SSH agent**: moved to sway `exec.conf` with fixed socket, bashrc connects to it

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
- Health check (fresh Void): disk 4% (7.8G/233G), RAM 1.7Gi/15Gi, swap file set up (4G at /swapfile), zramen still a migration to-do, all runit services up, 721 pkgs, `xbps-install -nu` clean, `/etc/sway/config.d` absent, no passwordless sudo.
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
- Updates: Brave is the only truly manual app (1Password/Dropbox self-update). Brave loop: git pull template → `./xbps-src pkg brave-bin` → install from hostdir/binpkgs. ~~OPEN ITEM: pick (a) `bup()` bashrc function, (b) manual check during weekly `-Syu`, or (c) weekly cron — decide during migration.~~ Done — update-xbps-src script + packages.conf handles this.
- I wrote `~/.local/bin/update-local-pkgs` once; user planned to remove it. Don't recreate unless asked.




