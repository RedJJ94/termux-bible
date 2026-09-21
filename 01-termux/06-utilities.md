# Termux Utilities

The `termux-tools` package is part of every installation and provides the
official, always-available commands. This chapter is an index; details for
the storage-related tools live in
[Storage Setup](04-storage-setup.md), and the destructive ones are covered in
[Backup, Restore, and Reset](08-backup-restore-reset.md).

## Shell / environment

| Command | Purpose |
|---------|---------|
| `login` | Login script used to start your shell session (usually invoked by the app; no need to call manually) |
| `chsh` | Change your default login shell |
| `pkg` | Package-management wrapper (see [Package Management](02-package-management.md)) |
| `termux-setup-package-manager` | Set/export which package manager is in use (`apt`, planned `pacman`) |

## Setup and configuration

| Command | Purpose |
|---------|---------|
| `termux-setup-storage` | Request storage permission + create `~/storage` symlinks (see [Storage Setup](04-storage-setup.md)) |
| `termux-change-repo` | Interactive mirror/repository picker (see [Repositories](03-repositories.md)) |
| `termux-reload-settings` | Reload `termux.properties` (see [Configuration](05-configuration.md)) |

## Information and diagnostics

| Command | Purpose |
|---------|---------|
| `termux-info` | Print app version, architecture, repositories/mirrors, and environment diagnostics |

## Opening files and URLs

| Command | Purpose |
|---------|---------|
| `termux-open <file>` | Open a file with the default Android app for it |
| `termux-open-url <url>` | Open a URL in a browser |
| `xdg-open` | Alias/symlink of `termux-open` (freely usable as a drop-in for scripts expecting `xdg-open`) |

## Persistent/background behaviour

| Command | Purpose |
|---------|---------|
| `termux-wake-lock` | Acquire a partial wake lock so the app/process keeps running in the background |
| `termux-wake-unlock` | Release the wake lock |

> **Note on backgrounding:** wake locks help against screen-off/Doze killing
> your work, but Android's process management (including the Android 12+
> phantom-process behaviour described in
> [Processes and Sessions](../00-foundations/06-processes-and-sessions.md))
> still applies.

## Shebang handling

| Command | Purpose |
|---------|---------|
| `termux-fix-shebang <script>` | Rewrite the script's `#!` line to a Termux-compatible interpreter path |

(Installation of the `termux-exec` package provides the transparent loader
that lets normal `#!/bin/sh` scripts run — see
[Shell and Environment](../00-foundations/05-shell-and-environment.md).)

## Wrappers for Android system tools

`termux-tools` also installs wrappers around the *Android* system binaries, so
you can run them from the Termux shell. They `unset LD_LIBRARY_PATH
LD_PRELOAD`, set `PATH` to `/system/bin`, and execute the real tools:

`df`, `getprop`, `logcat`, `ping`, `ping6`, `pm`, `settings`, `top`

These are the **Android** versions of the tools (targeting device state), not
GNU/Linux equivalents. There is **no** `mount`/`umount` wrapper (the
`mount`/`umount` build rules are not installed). Use them where docs say, for
example `pm list packages`, `settings get global`, `getprop
ro.build.version.release`, `logcat`.

> **Environment-dependent:** the wrappers exec `/system/bin/<tool>`, so they
> work in a normal Termux session on the device. In other contexts (e.g. a
> Linux distribution inside proot-distro, or through ADB) they may not exist
> or may behave differently — verify before relying on them.

## `su` and privileged commands

`su` in `termux-tools` is a **lookup wrapper**: it searches the usual Android
root-binary locations (for example `/sbin/su`, `/system/xbin/su`, Magisk's
paths) and `exec`s the first one it finds, with a PATH suited to that binary.
If no `su` program exists on the device it prints an explanatory message and
exits.

Consequences:

- `su` does **not** provide root itself — it only locates the rooting tool the
  device actually has (Magisk, SuperSU, and so on).
- It is **not** a Termux privilege-escalation interface. Privileged access in
  Termux is a separate topic handled by the ADB / Shizuku / rish / root
  documentation; do not assume `su` in Termux grants root on its own.

## Other packaged entry points

Several commands shipped by other always- or commonly-present packages overlap
with this index (e.g. `termux-am` from the `termux-am` package provides `am`,
the Android Activity Manager wrapper — needed by some storage flows, see
[Storage Setup](04-storage-setup.md)). `dalvikvm` (from `termux-tools`)
launches the Android Dalvik/ART VM. See also
[Add-ons](07-add-ons.md) for `termux-*` commands provided by Termux:API
such as `termux-battery-status`, `termux-storage-get`, `termux-toast`.

## References

- termux-tools `scripts/Makefile.am` (the authoritative command list).
- Research notes §3.8 and §10: `research/termux/00-foundations-research.md`.
- Official source: <https://github.com/termux/termux-tools>