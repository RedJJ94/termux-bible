# Package Management

Termux's native package management is Debian-style, but with deliberate
restrictions that make it behave differently from a desktop Debian/Ubuntu
system. Everything in this chapter applies to **native Termux only** — a Linux
distribution inside proot-distro has its own package manager (see
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md)).

## The two layers: `pkg` and `apt`

Termux uses **apt + dpkg** with `.deb` packages. Users are encouraged to use
the **`pkg`** wrapper instead of calling `apt` directly:

- `pkg` provides command shortcuts (`pkg in <pkg>` = install).
- `pkg` automatically runs `apt update` when needed.
- `pkg` performs client-side repository load-balancing by rotating mirrors
  (see [Repositories and Mirrors](03-repositories.md)).

> **Version-sensitive / planned:** Termux tooling is being prepared to also
> support `pacman` as an alternative backend, selected by the
> `TERMUX_APP_PACKAGE_MANAGER` environment variable (`apt` today, `pacman` in
> the future). At the time of research the Termux app still installs `apt`
> bootstraps only; the default remains `apt`. `pkg` maps its subcommands to
> whichever backend is active.

## The `pkg` subcommands

```
pkg [--check-mirror] command [arguments]
```

| Subcommand | Meaning |
|------------|---------|
| `pkg install <pkg>` / `pkg in <pkg>` | Install package(s) |
| `pkg uninstall <pkg>` | Remove package(s) (leaves config files) |
| `pkg reinstall <pkg>` | Reinstall |
| `pkg update` | Refresh package lists from repositories |
| `pkg upgrade` | Upgrade all installed packages |
| `pkg search <query>` | Search packages |
| `pkg show <pkg>` | Show package info |
| `pkg list-all` | List all available packages |
| `pkg list-installed` | List installed packages |
| `pkg files <pkg>` | List files owned by a package |
| `pkg clean` | Clear the package cache |
| `pkg autoclean` | Remove outdated cached packages |
| `pkg help` | Show help |

> **`pkg` refuses to run as root.** If you are in a root shell (or inside a
> proot environment running as root), `pkg` will refuse to run — run it from a
> normal Termux session.

## `apt` for advanced use

Since `pkg` hides much of `apt`, the following notes are for users who
deliberately use `apt` directly:

- Standard helpers apply: `apt update`, `apt install`, `apt search`,
  `apt show`, `apt full-upgrade`, `apt autoremove`.
- **Remove config files too:** `pkg uninstall` leaves package configuration
  behind; use `apt purge` to remove it.
- **`apt` under root is restricted**, to protect ownership/SELinux labels on
  `/data`. Prefer `pkg`; if you must use apt as a privileged user, know that
  behavior is limited by design.

## Restrictions specific to Termux

These restrictions are the most important difference from a desktop distro:

- **Do not use Debian/Ubuntu packages.** Termux packages are compiled for
  Android/Bionic and a non-FHS layout; foreign `.deb` files will not work and
  can damage the environment.
- **Single architecture only.** There is no multi-arch support or mixed-arch
  installation as on Debian.
- **No downgrades.** Version history is not kept; you cannot `apt install
  pkg=oldversion` or roll back an upgrade from the repositories.
- **No systemd, no `/usr` FHS tree** (see
  [The Filesystem](../00-foundations/03-filesystem.md)).
- **Root is separate.** Installing packages does not give you root, and root is
  not required to install packages.

## Signing and keys

Package lists and packages are signed. The `apt` package depends on
**`termux-keyring`**, which ships the repository signing keys into
`$PREFIX/etc/apt/trusted.gpg.d/`. Community repositories add their own keys
(such as `turb.tur.gpg` from TUR; see
[Repositories and Mirrors](03-repositories.md)). Do not remove or replace
these keyring files casually — package verification stops working.

## Update cadence

- Run `pkg upgrade` regularly; at minimum check weekly. Android's application
  storage hygiene and Termux's rolling release model mean security and
  compatibility fixes arrive continuously.
- After a major `pkg upgrade`, if a command behaves oddly, restart the session
  (some binaries update in place).

## What package is this, and where does it come from

- `pkg search <query>` and `apt show <pkg>` describe a package.
- `termux-info` lists your active repositories and mirrors
  (see [Repositories and Mirrors](03-repositories.md)).
- `pkg files <pkg>` lists the files it installed.

## Troubleshooting common problems

- **`pkg` complains about mirrors / cannot download.** Run
  `pkg --check-mirror` then `pkg update`; or pick a mirror with
  `termux-change-repo` (see [Repositories and Mirrors](03-repositories.md)).
- **"Cannot run 'pkg' command as root".** Exit the root/proot shell and run
  from a normal Termux session.
- **A state error after an interrupted upgrade.** Run `pkg upgrade` again;
  if apt states "held broken packages", ask in official channels before
  removing packages manually.
- **`apt` version expectations:** as of research time apt was at 2.8.x
  (master 2.8.1+r2; a device may show 2.8.3); tooling is prepared for apt
  3.0.0. **Version-sensitive.**

## References

- termux-tools `scripts/pkg.in` and `scripts/termux-setup-package-manager.in`.
- termux-packages docs/wiki "Package Management" pages.
- Research notes §3.3 and §3.12: `research/termux/00-foundations-research.md`.