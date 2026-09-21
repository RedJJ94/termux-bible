# What Termux Is

## What is it?

Termux is a terminal application and Linux environment for Android. It runs
**without rooting the device** and without an emulator: it is a real,
on-device Linux user-space environment compiled for Android.

At first launch, Termux installs a minimal base system automatically. After
that, you install more software through a package manager, the same way you
would on a Linux distribution.

## Why would I use it?

- A real shell on your phone or tablet with access to hundreds of packages.
- Scripting, automation, SSH, file management, and development tools on
  Android.
- A gateway to other environments: proot-based Linux distributions (see
  [Execution Environments](02-android-sandboxing.md)), ADB, and Android
  debugging.
- No root required.

## What Termux is not

Termux is not a fork of Ubuntu or any other Linux distribution, and it is not
a full Linux distro by itself (native Termux has a minimal, non-FHS user-space,
and it cannot install Debian/Ubuntu `.deb` packages directly — see
[Package Management](../01-termux/02-package-management.md)). For a more
complete FHS-compliant Linux or a systemd-based desktop, users typically run a
Linux distribution inside proot-distro (see
[Native Termux vs. proot-distro](02-android-sandboxing.md)).

## Key technical differences from desktop Linux

These points are what make Termux different, and they drive almost every path
and permission rule in the rest of the Bible.

- **Bionic libc.** Termux uses Android's Bionic C library, not glibc. Programs
  must be patched/recompiled for Termux; you cannot copy binaries from a
  Debian or Ubuntu system. **Version-sensitive:** this is why Debian/Ubuntu
  packages are not usable in native Termux.
- **No FHS.** Termux has no write access to `/bin`, `/etc`, `/usr`, or `/var`
  of the Android *system* tree. Its own user-space has a non-standard layout
  rooted at `$PREFIX` (see [The Filesystem](03-filesystem.md)).
- **Single user.** Everything runs under the Termux app UID (for example
  `u0_aXXX`). The username is derived from the UID by Bionic and cannot be
  changed. There is no `root` account by default.
- **No root by default.** Termux works without root. `pkg` intentionally
  refuses to run as root when executed from a root shell.
- **App-private storage.** The root filesystem and the home directory both
  live in the app's private directory on `/data`. Uninstalling Termux (or
  wiping its data) deletes `$PREFIX` and `$HOME` completely.

## Requirements

At the time of writing, **full app plus package support requires Android
>= 7**. Package (bootstrap) support for Android 5/6 was dropped in 2020;
app-only builds (without ongoing package updates) were provided from 2022.
Full Android 5/6 support is being re-added in the v0.119 development series.
**Version-sensitive:** exact requirements change with each app release —
check the official project documentation (linked below) for the currently
supported matrix.

Architecture must be one of AArch64, ARM, i686, or x86_64. ARM CPUs without
NEON support are unsupported.

> **Warning:** Termux must not be installed inside Android sandbox layers such
> as VMOS or F1VM. These are unsupported and will not work correctly.

## How execution actually works

The Termux app is an Android `Activity` with a terminal emulator that talks to
a `Service` (`com.termux.app.TermuxService`). The service is responsible for
starting terminal sessions and for running the bash environment. Because it is
an Android app, **the Android OS governs process life and death**, not
anything Termux does. This matters for background sessions (see
[Processes and Sessions](06-processes-and-sessions.md)).

## References

- Official project README: <https://github.com/termux/termux-app>
- Termux wiki "What is Termux / Getting started / Differences from Linux"
  pages (deprecated/stale warning applies): <https://wiki.termux.dev/>
- Termux packages and developer wiki: <https://github.com/termux/termux-packages/wiki>

All facts in this chapter were verified against the sources above and the
Termux research notes in `research/`; version-sensitive claims are marked
inline.