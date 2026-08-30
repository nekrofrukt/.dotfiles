# xbps-src state

Persistent state for the xbps-src build system. Read at session start for context, but always verify critical things against the actual system before acting.

## Current state

- **masterdir**: EXISTS
- **etc/conf**: does not exist — `XBPS_ALLOW_RESTRICTED=yes` not persisted (pass as env var when needed)
- **Built packages** (in `hostdir/binpkgs/`):
  - `brave-origin` 1.93.137 (nonfree, restricted=yes)
  - `obsidian` 1.13.7
- **packages.conf** (for update script): obsidian, brave-origin

## Workflow

### Bootstrap (only when masterdir is missing)

```bash
cd ~/src/void-packages
./xbps-src binary-bootstrap
```

Chroot is big. Gets cleaned up to save space — that's why it's missing sometimes.

### New package

1. `mkdir srcpkgs/<pkgname>`
2. Create `srcpkgs/<pkgname>/template` (see vault manual `void-xbps-src.md` for anatomy)
3. Get checksum: `curl -sL <tarball URL> | sha256sum`
4. Build: `./xbps-src pkg <pkgname>`
5. Install: `sudo xbps-install -R hostdir/binpkgs/<pkgname>-<version>_<revision>.<arch>.xbps`

Restricted packages need `XBPS_ALLOW_RESTRICTED=yes`.

### Updating packages

`scripts/void/xbps/packages.conf` defines tracked packages.
`scripts/void/xbps/update-xbps-src` checks GitHub for new releases, bumps template, builds, installs.

### Update template manually

1. Bump `version=` in template
2. Download new tarball, get sha256sum
3. Update `checksum=` in template
4. Build and install

## Gotchas

- `masterdir` is a full chroot — gets purged to save disk space. Re-bootstrap is normal.
- After `git pull` in void-packages, custom templates (brave-origin, obsidian) may conflict — stash or rebase.
- `restricted=yes` in template + `XBPS_ALLOW_RESTRICTED=yes` required for nonfree packages.
- Built `.xbps` files persist in `hostdir/binpkgs/` even after masterdir is cleaned.
- Go version in xbps-src chroot may differ from what a package's `go.mod` requires — check `srcpkgs/go/template` version.
