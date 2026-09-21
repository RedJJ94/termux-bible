# Repositories and Mirrors

Native Termux pulls its `.deb` packages from apt repositories. This chapter
documents the official and community repositories, how mirrors work, and how
to manage them. It applies to **native Termux only**; distributions inside
proot-distro bring their own repositories.

## The default repository (main)

The first repository (always enabled, containing the core package set) is
**main**:

```
deb https://packages.termux.dev/apt/termux-main stable main
```

Some older documentation or devices may show the domain
`packages.termux.org`. The current domain is `packages.termux.dev`.
**Version/date-sensitive.** The default `$PREFIX/etc/apt/sources.list`
shipped by the current apt package lists the Cloudflare-cache host
(`packages-cf.termux.dev`) first; after `pkg` performs mirror rotation the
active file may show a different mirror — see "Mirrors" below.

Historical separation note: `game-repo`, `science-repo`, and `unstable-repo`
existed as separate repositories; they were **merged into main**, and the apt
package now `CONFLICTS`/`REPLACES`/`PROVIDES` their names. If you still have
`science-repo`/`game-repo` installed, remove them.

## Optional and community repositories

Enable an extra repository by installing its `-repo` package:

| Repository | Install command | Content / notes |
|------------|-----------------|-----------------|
| **x11** | `pkg install x11-repo` | GUI/X11 packages; **Android 7+ only** |
| **root** | `pkg install root-repo` | Packages that need or provide root access |
| **TUR** (Termux User Repository) | `pkg install tur-repo` | Community packages; **not official Termux packages** (community-maintained) |

After installing the `-repo` package, run `pkg update` so `apt` sees the new
repository.

### glibc repositories

There is a glibc-based package source for programs that need glibc rather than
Bionic:

- `pkg install glibc-repo` adds the repository. It is a deb-format mirror of
  the glibc packages project (the sources live in the community
  termux-pacman/glibc-packages organization, mirrored by the Termux org).
- `pkg install glibc-runner` provides the runtime used to run those binaries.

> These are **separate** from native Bionic packages. Enabling glibc-repo does
> not change which packages `pkg` installs by default.

### Historical Android 5/6 repository

Android 5/6-era devices used a separate `termux-main-21` repository. This is
**historical** — current installs use the main repository and the Android 5/6
package support is being re-added in the v0.119 app series (see
[Installation](01-installation.md)).

> **Worth knowing:** extra repositories are a setting of the *installation*,
> not just the app. If you reinstall Termux you must re-run the `-repo`
> installs (`pkg install x11-repo`, etc.).

## Where repository config lives

- `$PREFIX/etc/apt/sources.list` — the main repository line (one-line
  `.list` format, e.g. `deb https://.../termux-main stable main`).
- `$PREFIX/etc/apt/sources.list.d/` — files for extra repositories, e.g.
  `x11.list` (`deb https://packages-cf.termux.dev/apt/termux-x11/ x11 main`),
  `tur.list`.
- `$PREFIX/etc/apt/trusted.gpg.d/` — signing keys. The `termux-keyring`
  package populates this; `tur-repo` installs its own `tur.gpg` key here.

> **Format note:** current `-repo` packages write the legacy one-line `.list`
> format. The deb822 `*.sources` format is *supported* by apt but is not what
> the shipped packages produce today.

When in doubt, `pkg update` will tell you whether the repositories are
correctly configured, and `termux-info` prints the active mirrors.

## Mirrors

Repositories are replicated to multiple **mirrors** across the world:

- Mirror definitions: `$PREFIX/etc/termux/mirrors/` (files named `default`,
  `asia`, `chinese_mainland`, `europe`, `north_america`, `oceania`, `russia`,
  each containing `WEIGHT=` entries).
- Active selection: `$PREFIX/etc/termux/chosen_mirrors` (can be a file,
  symlink, or directory).
- **`termux-change-repo`** is the user-facing mirror picker; choose a mirror
  group, then run `pkg update`.
- **`pkg` mirror rotation:** `pkg` may check the current mirror, test up to 10
  mirrors in parallel, pick one by weighted random selection, and rewrite the
  active `sources.list`. `pkg --check-mirror` forces a re-check.

Because `pkg` can rewrite `sources.list`, the file on your device may show a
mirror URL (for example a regional mirror) rather than the canonical
`packages.termux.dev` line. That is expected behavior.

## Checking the current state

```
termux-info
```

shows the app version, architecture, and the active repositories/mirrors.

## Security considerations

- Only use mirrors you trust, and prefer the official hosts listed above.
- Repository config and `trusted.gpg.d/` are **system state inside `$PREFIX`**:
  back them up with the rest of `$PREFIX` (see
  [Backup, Restore, and Reset](08-backup-restore-reset.md)) and do not hand
  random "fix scripts" that rewrite them blindly.
- Community repositories such as TUR are not vetted by the Termux project —
  install from them knowingly.

## References

- termux-tools `scripts/pkg.in`, `scripts/termux-change-repo` and mirror
  definitions.
- termux-packages `packages/{apt,x11-repo,tur-repo}/build.sh`.
- Research notes §3.4, §10: `research/termux/00-foundations-research.md`.