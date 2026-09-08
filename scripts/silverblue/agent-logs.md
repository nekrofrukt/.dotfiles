# Agent Session Log — mise-en-place Silverblue bootstrap (2026-09-07)

## Session 5 — brew fully purged, fonts manual, lazy/nvim rocks benign, update alias finalized (2026-09-08)

- **BREW IS GONE.** Prefix + `~/.cache/Homebrew` removed, `brew shellenv` line
  deleted from `bashrc-silverblue/.bashrc`, casks/formulae at zero. Empty
  root-owned dirs `/home/linuxbrew[/.linuxbrew]` remain — `sudo rm -rf /home/linuxbrew`
  to finish. `stow` now resolves to `/usr/bin/stow` (rpm-ostree layered).
- **Java/fonts: brew cask `font-jetbrains-mono-nerd-font` uninstalled; JBM Nerd
  Font re-provisioned MANUALLY + via the mise `[bootstrap.hooks.post-tools]`
  script** (same `JetBrainsMono.zip`, 96 ttfs in `~/.local/share/fonts`,
  `fc-list` registered). Cask guard file:
  `~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf` — hook skips when
  present (idempotence confirmed).
- **hey-cli now on mise:** `mise ls` → `hey-cli 1.4.1` (was `(missing)` pre-
  bootstrap); shim `~/.local/share/mise/shims/hey`, brew's stale `hey` gone.
- **lazy.nvim (11.17.5) rocks warning — DIAGNOSED BENIGN.** The
  `required luarocks` ERROR/WARNING is its *optional* hermetic lua 5.1+
  luarocks check (`~/.local/share/nvim/lazy-rocks/hererocks/bin/` unprovisioned),
  because `rocks.enabled=true` default and no system lua/luarocks. No plugin has
  `build = "rockspec"`; telescope.nvim resolves from **git** (`build=false`,
  `source="rockspec"` in `pkg-cache.lua` is a metadata tag only). Known-good
  pattern from user's prior lazy installs. NO ACTION NEEDED — `rocks = { enabled = false }`
  at ~/.config/nvim/lua/config/lazy.lua remains a future opt-out if it ever
  bothers.
- **NEW `update` alias** (bashrc-silverblue/.bashrc:38), replacing the
  Homebrew one:
  `alias update='mise upgrade; echo "---"; mise bootstrap packages apply --yes; flatpak update'`
  - `mise upgrade` bumps tools (herdr WARN about `minimum_release_age` 24h is
    normal — newer release simply not yet eligible).
  - `mise bootstrap packages apply --yes` = install-only, never upgrades
    already-installed flatpaks (verified `plan` shows `0 update`). Additive
    only.
  - `flatpak update` covers real version bumps of installed apps.
- **Flatpak REMOVAL is manual.** mise `prune` refuses flatpak:
  `package manager 'flatpak' does not support pruning` (`--manager all` is an
  invalid name). So removing an app = `flatpak uninstall <id>` first, then drop
  its line from `mise-silverblue/.config/mise/config.toml`. No reverse-converge
  exists. Deleted-from-config apps are never auto-removed.
- **Adding a flatpak** = add `"flatpak:<id>" = "latest"` to the stowed config
  (single source of truth) + `mise bootstrap packages apply --yes`.
- Left untouched: `bashrc-debian/.bashrc` still has `brew shellenv` (Debian box,
  separate machine, brew still authoritative there).

## Session 4 — brew defoliation underway, stow moves to ostree, pre-reboot state (2026-09-07)

- **Both herdr + opencode confirmed on mise** (`mise ls`: herdr 0.8.2, opencode
  1.18.29; shims at `~/.local/share/mise/installs/<tool>/latest/`). Their exit
  was part of the brew teardown, not a coffee break.
- **Brew is down to 14 formulae / 4 leaves** from the original 53. Dep graph:
  - `fzf` ↔ ncurses
  - `starship` ↔ dbus, expat, zlib-ng-compat
  - `stow` ↔ gdbm, libxcrypt, perl
  - `luarocks` ↔ bzip2, lua, unzip
  - Everything else is covered; neovim + ripgrep already gone.
- **fzf (0.74.3) + starship (1.26.0) already run via mise** → clear for
  `brew uninstall fzf starship` (purges ncurses/dbus/expat/zlib-ng-compat).
- **DECISION — stow migrates from brew to rpm-ostree layering** (matches
  `01-bootstrap.sh` philosophy). Whole-home symlinks verified SAFE:
  every stowed link targets `~/.dotfiles/...` (e.g.
  `~/.config/mise/config.toml → ../../.dotfiles/mise-silverblue/...`);
  GNU Stow is stateless (re-derives ownership from symlinks each run), so the
  ostree-layered stow manages existing links transparently; brew never writes
  outside its own prefix. Version delta brew 2.4.1 vs Fedora ~2.3.x is cosmetic.
- **Order matters, not integrity:** 1) `sudo rpm-ostree install stow`
  (already done) 2) reboot ⏳ IN PROGRESS 3) `brew uninstall fzf starship`
  4) `brew uninstall luarocks` 5) purge brew itself.
  Gotcha after purge: `hash -r` (brew path was command-hash cached).
- **OPEN (carried):** luarocks/lua standalone scripting — user hasn't decided;
  if dropped, it kills the remaining graph (bzip2/lua/unzip) and brew reaches
  zero formulae.

## State (for next session)

- REBOOTING into image with layered stow — nothing else pending on this side.
- resumed brew on live box: fzf, starship, stow, luarocks (+10 transitive).
- next: brew teardown per order above → `brew cleanup --prune=all` → remove brew prefix.
- deferred: remove `config.toml.bak`, tidy stale config header (05-mise ref).

## Session 3 — live install start, stow-folding fix, first tools migrated (2026-09-07)

- **Decision (supersedes Session 2's `~/.bashrc.d/05-mise` plan):** mise shell
  activation now goes DIRECTLY in `bashrc-silverblue/.bashrc` —
  `eval "$(mise activate bash)"` after the brew shellenv eval, before
  starship/fzf. `~/.bashrc.d/` does not exist here; `.bashrc`'s source-loop only
  tolerates that dir. Stale config header still references 05-mise — cleanup deferred.
- **stow folding gotcha confirmed:** stow symlinks a WHOLE directory when the
  target dir doesn't exist (`LINK: .config/mise => …`), letting mise's own future
  writes land in the repo (the herdr problem). Fix: pre-create the real dir
  `mkdir -p ~/.config/mise` BEFORE stow so stow descends and links only the leaf
  `config.toml`. In `02-mise.sh`. Live `~/.config/mise/` is a real dir with
  `config.toml` (and stray `config.toml.bak` — removal deferred) as leaf symlinks.
- **`01-bootstrap.sh`:** clone made idempotent — `if [ ! -d ~/.dotfiles/.git ]`
  clone, else `git -C ~/.dotfiles pull --ff-only`. `bash -n` clean.
- **mise installer verified:** `curl https://mise.run | sh` does NOT modify any
  rc file — it only PRINTS the `eval "$(<path> activate bash)" >> ~/.bashrc` hint.
  Our stowed `.bashrc` line (bare `mise`) is equivalent (PATH includes `~/.local/bin`).
- **Live install (this Silverblue box):** mise 2026.9.1 → `~/.local/bin/mise`.
- **fd + fastfetch removed from brew.** Post-uninstall `No such file` error for the
  brew path was bash's command hash cache (`hash -r` fixes), not residue.
- **mise on-demand auto-install confirmed:** running a declared-but-missing tool
  via its shim auto-installs it (fastfetch 2.68.1 installed on first `fastfetch`).
  Shims in `~/.local/share/mise/shims/` are symlinks to `~/.local/bin/mise`.
- **`flashfetch` is legit:** fastfetch 2.68.1 ships a second slim binary
  `flashfetch` in the same tarball; mise shims every binary in a package, so the
  `flashfetch` shim shares the `fastfetch = "latest"` install. No action needed.
- **Config updated by user:** `[tools]` = fastfetch, fd, fzf, neovim, ripgrep,
  starship; herdr + opencode COMMENTED OUT (still on brew, actively used).
- **Remaining brew→mise migration:** neovim, fzf, ripgrep, starship. Rest of the
  53-formula list is transitive deps — they vanish with the top-level formulae.
- **No bootstrap on this box:** no `mise bootstrap`/flatpaks/font hook; install
  kept as-is; scripts remain rain-day. Flatpaks in config are declared-but-inert.

## State (for next session)

- migrated: fd 10.5.0, fastfetch 2.68.1 (mise) — both working.
- pending: `mise install` → verify → `brew uninstall neovim fzf ripgrep starship`.
- deferred: remove `config.toml.bak`, tidy stale config header comments.

## Session 2 — script fixes, flatpak ID check, stow-vs-mise-dotfiles discussion (2026-09-07)

- **`02-mise.sh`** (user-reduced to bare `mise trust && mise bootstrap --yes`):
  added a `command -v mise` guard (bails with pointer to 01-bootstrap.sh) and a
  warning if `~/.config/mise/config.toml` is missing (stow not run yet). `bash -n` clean.
- **`01-bootstrap.sh`**: "After reboot" block now points at
  `scripts/silverblue/02-mise.sh` instead of inlining the commands; dropped the
  stale `echo "See scripts/silverblue/mise.toml …"` (that file doesn't exist —
  config lives at `mise-silverblue/.config/mise/config.toml`). `bash -n` clean.
- **Flatpak app-IDs verified against Flathub:** `com.ktechpit.whatsie` and
  `org.nicotine_plus.Nicotine` confirmed correct; the other seven are standard IDs.
- **Decision:** this `agent-logs.md` is now the ONLY session log. Top-level
  `docs/agent-logs.md` is untouched; we'll add to it only if/when there's need.
- **Decision:** `mise-silverblue/.config/mise/config.toml` cleanup is deferred to
  the user; no edits to the TOML this session.
- **Open discussion (stow vs mise `[dotfiles]`):** the herdr concern — app writes
  extra files into `.config/herdr` that must NOT land in the repo; solution today
  is "create the real dir manually, then stow only the config file, because the
  dir being a real dir keeps stow from symlinking the whole dir." mise handles this
  via `[dotfiles]` `mode = "symlink-each"` (symlink individual files into a real
  dir, preserve unmanaged neighbors) and `exclude` globs for stale/state files.
  RESOLVED pending user trial — stow remains the authority for now.

## Deliverables

**Config (SINGLE SOURCE OF TRUTH):**
- `mise-silverblue/.config/mise/config.toml` (repo root) — the one config,
  WIP, deployed via stow as `~/.config/mise/config.toml` once pinned. Any
  edits go here; there is NO copy under `scripts/` anymore (the draft was
  deliberately removed to avoid drift).

**In this dir:**
- `silverblue-bootstrap.sh` (renamed from `silverblue-setup.sh`) — first-run
  script on a fresh box:
  1. `curl https://mise.run | sh`
  2. `sudo rpm-ostree install stow` → reboot (prompts)
  3. after reboot: `stow .` → reopen shell → `mise trust && mise bootstrap --yes`
- `agent-logs.md` — this session log.

## Layout note (config placement)

mise reads `~/.config/mise/config.toml` as the global config; it also merges
`~/.config/mise/conf.d/*.toml` fragments (alphabetical, `-E <env>` suffix
switching) and project-level `mise.toml`. Current choice: **single stow
package `mise-silverblue/`** (no shared base + conf.d split yet). Cross-manager
`[bootstrap.packages]` entries auto-skip where a manager is absent, so a future
shared config could carry flatpak+dnf+pacman entries safely.

## Decisions

- **stow stays the dotfile authority.** `rpm-ostree install stow` (layers perl
  too). mise has NO rpm-ostree backend and `dnf:` cannot layer into the atomic
  image, so stow lives in the first-run script, not `[bootstrap.packages]`.
- **Shell activation via stow, not mise.** A stow-managed `~/.bashrc.d/05-mise`
  contains `eval "$(mise activate bash)"`. `.bashrc` already sources
  `~/.bashrc.d/*`, so mise itself never edits a config file stow owns — mise
  is purely tools + flatpaks + font hook.
- **neovim = no system lua/luarocks.** `aqua:neovim/neovim` bundles LuaJIT, and
  the user's LazyVim setup (`~/.config/nvim`) uses no rockspec/luarocks — verified:
  lazy.lua spec has no `rocks` field; plugins are pure-lua git checkouts. The
  `lua`/`luarocks` in the old brew list are NOT neovim deps (brew neovim pulls
  `luajit`, not `lua`).
- **`[tools]` uses registry shorthands** → mise auto-picks the best backend
  (aqua/github prebuilt binaries). Prebuilt binaries bundle their native libs,
  so most brew transitive deps (opencode's ~34 libs, ripgrep's bzip2/pcre2,
  fzf's ncurses…) need zero handling.
- **Flatpaks in `[bootstrap.packages]`** (`flatpak:` prefix). GUI apps only;
  system-level image changes stay in rpm-ostree/first-run script.
- **Font via hook, not flatpak.** JetBrainsMono Nerd Font isn't a flatpak; a
  `[bootstrap.hooks.post-tools]` downloads+unzips into `~/.local/share/fonts`
  + `fc-cache`. Idempotent (guarded on font existence). Prereqs curl/unzip/
  fc-cache are in the Silverblue base (verified).
- **Correct mise `[settings]` key is `jobs = 8`** (default already 8).
  `default_num_jobs` was an early-draft mistake — not a real setting.

## Open questions

- **stow vs mise `[dotfiles]`:** user uneasy about handing dotfile control to
  mise (needs to create some `.config` dirs before symlinking, full control).
  Keeping stow for now; mise `[dotfiles]` (symlink/copy/template + block/line
  edits, `mise bootstrap dotfiles add/edit/status`) is a documented future path.
- **Standalone lua/luarocks:** only needed if scripting Lua outside nvim.
  Currently dropping them from `[tools]`.
- **Flatpak list:** currently Brave, Discord, Dropbox, WhatsApp(whatsie),
  1Password, Spotify, Obsidian, VLC, nicotine+. Confirm final app set.
- **Config placement:** RESOLVED — single `mise-silverblue/` stow package at
  repo root; no `conf.d/` split yet (may add later if other distros adopt
  mise). The old draft under `scripts/silverblue/` was removed.
- **mise installer trust:** `curl ... | sh` runs before `mise trust`; installer
  itself is not verified by mise (out of scope, just noted).
- **Other machines (Arch/Void/Debian/mac):** decided NOT to roll mise out there
  for now — those distros have native PMs (pacman/xbps/apt/brew). Only
  Silverblue gets a mise package.