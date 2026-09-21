# The Filesystem

Termux uses an Android-specific filesystem layout that intentionally differs
from standard Linux. Getting the paths right is essential: many of the most
common Termux mistakes come from confusing Termux paths with Android or Linux
paths.

## The two main variables

Two environment variables are always set in a normal Termux session:

- `$PREFIX` — the Termux user-space root.
- `$HOME` — the user home directory.

Their registered values are stable (they are baked into the app and the
packages):

| Variable | Value |
|----------|-------|
| `$PREFIX` | `/data/data/com.termux/files/usr` |
| `$HOME` | `/data/data/com.termux/files/home` |

`$PREFIX` is also known as `$TERMUX_PREFIX`, and in packaging contexts as
`$TERMUX__PREFIX` (the latter is used by scripts such as proot-distro, default
`/data/data/com.termux/files/usr`). Do not treat these aliases as different
directories.

> **Verify on your device:** `echo "$PREFIX"` and `echo "$HOME"` should print
> the values above. Never rely on a path you haven't checked.

## The prefix layout

`$PREFIX` contains the entire Termux user-space: `bin`, `etc`, `include`,
`lib`, `libexec`, `opt`, `share`, `tmp`, and `var`. There is no `/usr`, no
`/etc` in the FHS sense, and no `/var` at the top of the filesystem — those
top-level system directories are owned by the Android system and are not
writable by Termux.

Two prefix subdirectories have special semantics:

- `$PREFIX/tmp` — **erased on each application restart**. Use it only for
  short-lived scratch files.
- `$PREFIX/var/run` — runtime state: locks, PIDs, and sockets. Termux uses
  this instead of `/run`.

## The home directory

`$HOME` is a normal home directory (`~` alias, `~/.bashrc`, and so on). Keep
user files here; it is inside the app-private area and is the normal,
protected place for everything you create. When you uninstall Termux or wipe
its data, both `$PREFIX` and `$HOME` are deleted.

## What the filesystem supports

`$PREFIX` and `$HOME` live under the app's private directory on `/data`,
which is typically an EXT4 or F2FS filesystem. That means it supports things a
FAT32/SD-card filesystem does not:

- Unix permissions and executable bits;
- symlinks;
- special files (sockets, FIFOs).

This is why `$PREFIX` cannot be moved to external storage: the path is
hardcoded into the binaries, and external storage is typically read-only
except for the Termux private folder, lacks executable attributes, and does not
support the permission model. Only rooted users may even consider relocating
`$PREFIX` or `$HOME` off the internal storage — it is not recommended.

## Android paths you will encounter

These are Android system paths, **not** Termux paths. Understand which is
which before using them:

- `/system/bin` — Android's AOSP tool binaries (e.g. `df`, `ping`, `pm`,
  `settings`, `top`, `getprop`, `logcat`), owned by `root:shell`. Termux
  provides wrappers for several of these so they work from within Termux; see
  below.
- `/bin` — a symlink to `/system/bin`.
- `/sdcard` — the shared/external storage root for the primary user, a symlink
  to `/storage/emulated/0`. Do not confuse `/sdcard` with the app-private
  storage.

> **Recommendation:** do not add `/system/bin` to `$PATH`. It conflicts with
> Termux utilities and can break commands (the Termux `df`, `ping`, etc.
> wrappers already reach the system binaries safely). Type `which df` to see
> which `df` your shell would run.

## Shared storage vs. app-private storage

- **App-private storage** (`/data/data/com.termux/...`) — always available,
  supports full Unix semantics, dies with the app. This is where `$PREFIX`
  and `$HOME` live.
- **Shared storage** (`/sdcard` = `/storage/emulated/0`) — accessible to all
  apps but requires explicit Android permission. It does **not** support
  executable bits generally and is treated specially. Access from Termux is
  arranged through the `~/storage` symlink set — see
  [Storage and Permissions](04-storage-and-permissions.md).

## Storage pressure (low-water marks)

Android maintains a storage low-water limit for caching: current documented
behavior is a free-storage limit of 5% OR 500 MB (whichever is lower), with
caches deleted when free storage reaches 150% of that value. This matters when
Termux apps or package caches consume large amounts of space. **Version /
device sensitive.**

## Wrapper commands for Android system tools

The `termux-tools` package installs small wrappers that let you call several
Android system tools from within Termux as if they were local commands:
`df`, `getprop`, `logcat`, `ping`, `ping6`, `pm`, `settings`, and `top`.
Each wrapper unsets `LD_LIBRARY_PATH`/`LD_PRELOAD`, sets `PATH` to
`/system/bin`, and executes the real system binary. **Important:** `mount`
and `umount` wrappers are *not* installed (they exist only as build rules in
the package's Makefile), so do not expect a Termux `mount` command.

Because they hand off to `/system/bin`, these wrappers behave like the
*Android* tools — not like their GNU namesakes on Linux. Their context is the
Android device, not Termux.

## References

- Termux research notes §3.5 (Filesystem) and §3.8 (termux-tools utilities):
  `research/termux/00-foundations-research.md`.
- Termux wiki "Termux file system layout" and "Getting started" pages;
  termux-tools `scripts/Makefile.am`.