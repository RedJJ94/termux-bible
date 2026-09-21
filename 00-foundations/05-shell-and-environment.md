# Shell and Environment

This chapter covers the basics of working with the Termux shell itself: which
shell you get, how it is started, what environment variables are set, and how
executables and scripts are found and run. It builds on
[What Termux Is](01-what-is-termux.md) and
[Android Sandboxing](02-android-sandboxing.md).

## Default shell and login

- Termux uses **bash** as its default shell.
- Sessions are started through a **login mechanism**: the Termux app sets up a
  minimal environment and the `login` script (from the `termux-tools` package)
  configures the rest, then execs your shell.
- Your own per-user shell choice can be set with `chsh`; the default is bash.

## Shell startup files

In a normal Termux login session, these files are involved in order (all paths
are under `$PREFIX` for the system files, `$HOME` for your personal files):

| File | Role |
|------|------|
| `$PREFIX/etc/profile` | System-wide profile; sources everything in `$PREFIX/etc/profile.d/*.sh` |
| `$PREFIX/etc/bash.bashrc` | System-wide bash configuration |
| `$HOME/.bashrc` | Your personal interactive bash configuration (not sourced for plain non-interactive runs) |
| `$HOME/.bash_profile` / `~/.profile` | Personal login/profile configuration |

Because bash is started as a login shell, your interactive configuration is
loaded from `.bash_profile`/`.profile` (which conventionally sources
`~/.bashrc`). **Version-sensitive:** the exact startup-file set can change
between Termux releases; `etc/profile` is maintained by Termux packages and
should not be edited directly — use your own files in `$HOME` instead.

`chsh` (part of termux-tools) changes which shell `login` execs for you.

## Environment variables

Two variables are fundamental (see [The Filesystem](03-filesystem.md)):

- `$PREFIX` — the Termux user-space root.
- `$HOME` — your home directory.

The Termux app exports several others at session start. A sample (verified
live on a current installation; names may vary with app version — the app
writes its environment file at `$PREFIX/etc/termux/termux.env`):

- `$TERM` — usually `xterm-256color`.
- `$TMPDIR` — points under `$PREFIX/tmp`.
- `$LANG` — `en_US.UTF-8` by default.
- `$TERMUX_VERSION` — the installed Termux app version.
- `$TERMUX_APP_PACKAGE_MANAGER` — normally `apt` (or `pacman` once the
  transition is enabled; see
  [Package Management](../01-termux/02-package-management.md)). **Version-
  sensitive / planned:** the app exports this since v0.119.0; the `login`
  script falls back to `$TERMUX_MAIN_PACKAGE_FORMAT` (see below) for older
  app versions.
- `$TERMUX_MAIN_PACKAGE_FORMAT` — `debian`/`pacman`; used to derive
  `TERMUX_APP_PACKAGE_MANAGER` on app versions below 0.119.0. **Version-
  sensitive.**
- `$LD_LIBRARY_PATH` — see the note below.

> **Historical note:** Before Android 7, Termux exported `$LD_LIBRARY_PATH` so
> binaries could find libraries. On Android 7+ the dynamic linker instead uses
> the `DT_RUNPATH` field in each ELF executable. The termux-tools wrappers
> around `/system/bin` tools explicitly `unset LD_LIBRARY_PATH LD_PRELOAD` to
> avoid conflicting with system libraries. This behavior is confirmed
> C-tier/on-device; verify with `readelf -d <binary>` if needed.

## How executables are found

- Executables live in `$PREFIX/bin`, which is the main component of `$PATH`
  (the `login` script historically also handled a `$PREFIX/bin/applets`
  subdirectory — that PATH shape only applies to legacy Play Store installs).
- Do **not** add `/system/bin` to `$PATH` on top of the Termux paths: it
  provides Android/AOSP tools that conflict with Termux utilities (see
  [The Filesystem](03-filesystem.md)).
- The `termux-tools` package installs wrapper scripts named like the Android
  system tools (`df`, `getprop`, `logcat`, `ping`, `ping6`, `pm`, `settings`,
  `top`). When you type those names in Termux you are using the wrappers,
  which exec the real binaries from `/system/bin`. `mount` and `umount` are
  **not** among the installed wrappers.

## Executing scripts

- Scripts with a `#!/bin/sh` shebang may fail in Termux because the kernel
  resolves `sh` via the Android path. Two tools help:
  - `termux-fix-shebang` — rewrites a script's first line to the correct
    Termux interpreter path; and
  - `termux-exec` (package) — provides a loader hook that lets standard
    `#!/bin/sh` (and similar) scripts run unchanged. **Termux installs
    `termux-exec` automatically as part of the base setup.**
- Scripts located on external/shared storage cannot be executed directly
  (`noexec` mount); run them explicitly through an interpreter, e.g.
  `bash ~/storage/myscript.sh` (see
  [Storage and Permissions](04-storage-and-permissions.md)).

## Basic command line

- A command is a program name plus arguments, e.g. `ls -l /data`. Long options
  use `--` (`ls --all`). Programs are found via `$PATH`.
- Multiple commands on one line: `a; b` (run both), `a && b` (b only if a
  succeeded), `a || b` (b only if a failed).
- Pipes `a | b` feed the output of `a` into `b`; redirection `>` / `<` /
  `>>` connects files to a command's input/output.
- Background a job with `&`; manage jobs with the shell's job control
  (`jobs`, `fg`, `bg`) — see [Processes and Sessions](06-processes-and-sessions.md).
- Redirect stream 2 to discard error output: `command 2>/dev/null`; to keep
  errors in the file instead: `command >file 2>&1`. (A full command
  encyclopedia is a later section of the Bible.)

## Checking what your shell sees

- `env` — prints all exported environment variables.
- `echo "$PREFIX" "$HOME"` — confirm the fundamental paths.
- `which pkg bash login termux-info` — confirm commands resolve as expected.
- `termux-info` — prints installed version, repository, and environment
  diagnostics.

## References

- termux-tools `scripts/login` and `scripts/Makefile.am`; research notes
  §3.7–§3.8: `research/termux/00-foundations-research.md`.
- Termux wiki "Execution environment / shell" pages (deprecated/stale warning
  applies).