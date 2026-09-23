# Development Environment and Constraints

Termux is **a normal Android application**. Everything a developer does inside
it — compiling, running scripts, starting servers — is subject to Android's
app sandbox and to the fact that Termux packages are built for Android, not for
desktop Linux. This chapter records the constraints that reappear in every
other Power Tools chapter so they can be referenced instead of duplicated.

Read this before the language and tooling chapters. Most of them assume the
rules below. The details that are only device-confirmable are tagged
**[DEVICE]** / **[OEM]** / **[version-sensitive]**.

## What user you are

- Termux processes run as an **unprivileged Android app UID** (typically
  `u0_a*`), *not* root and *not* the Android `shell` user.
- Verify with:

```sh
id          # uid=…(u0_a…) gid=… groups=…
```

- Consequences you will hit again and again:

  - **No `chown` of system paths, no `iptables`, no root-only features.**
  - **No binding ports below 1024.** All Termux servers use high ports;
    the bundled `sshd` is compiled to default to port **8022** for exactly
    this reason (see [SSH and Remote Access](02-ssh-and-remote-access.md)).
  - `pkg` refuses to run as root and wraps the configured package manager
    (`apt` or `pacman` via `termux-setup-package-manager`); normal installs
    run as the app user. Do **not** make the Bible's package commands require
    root — they do not.
- Privileged alternatives (ADB, root, Shizuku, Porter, rish) are **separate
  systems** (AGENTS.md §10) and are covered in their own sections; normal
  development does not use them.

## Paths and shell rules

- `$PREFIX` defaults to `/data/data/com.termux/files/usr`.
- `$HOME` defaults to `/data/data/com.termux/files/home`.
- `~/storage/...` is the `$HOME/storage` symlink farm set up by
  `termux-setup-storage`; it points at `/storage/emulated/0/...` (shared,
  visible storage), **not** the app-private home. Files that should be
  reachable from a computer over USB belong under `~/storage/shared`.
- Desktop-style `/bin`, `/usr/bin`, and `/etc` generally **do not exist**.
  Termux executables live in `$PREFIX/bin`.
- `$PREFIX/tmp` is the scratch directory (a real directory, not Android's
  `/tmp`).
- Config conventions: `$PREFIX/etc`, `$PREFIX/etc/bash_completion.d`,
  `$PREFIX/var/service` (runit services), `$PREFIX/var/run`, `$PREFIX/var/log`.

### Shebangs and `termux-exec`

Termux scripts normally start with `#!/usr/bin/env bash` or
`#!/usr/bin/env python3` — `env` is resolvable and portable. Scripts that
write a literal `/bin/...` shebang still work **inside a Termux session**,
because the essential `termux-exec` package rewrites `/bin/` and `/usr/bin/`
interpreter references to `$PREFIX/bin` (see below). Write portable shebangs;
they also survive being copied out of Termux.

## Executing files: W^X and the Android 10+ app-data restriction

This is the single most important Android constraint for development, and it
is the reason Termux ships `termux-exec`.

- **Android 10+** enforces W^X: apps with `targetSdkVersion >= 29` in the
  `untrusted_app` domain are **blocked from executing** files in their own app
  data directory (`/data/data/<pkg>` — exactly where Termux stores its
  binaries, scripts, and compiled programs). Some OEM variants apply this
  earlier or push it back. **[version-sensitive]** **[OEM]**
- Apps with `targetSdkVersion <= 25` (`untrusted_app_25`) or 26–28
  (`untrusted_app_27`) could still execute data files directly;
  `dlopen()` of data files remains allowed for all `untrusted_app*` domains.
  **[version-sensitive]**
- **Termux's solution — `termux-exec`** (essential package, preinstalled): an
  `LD_PRELOAD` interposer (`$PREFIX/lib/libtermux-exec.so`, with the active
  variant selected by `termux-exec-ld-preload-lib setup` during install) that
  does two things:

  1. Rewrites shebang/interpreter paths (`/bin/`, `/usr/bin/`) to `$PREFIX/bin`.
  2. **System Linker Exec**: when direct execution of an app-data file is
     blocked, re-executes it through the Android linker
     (`/system/bin/linker64 <path>` on 64-bit), which the kernel trusts.

- Control: `TERMUX_EXEC__SYSTEM_LINKER_EXEC__MODE` (`enable` [default] /
  `disable` / `force`); query with `termux-exec-system-linker-exec is-enabled`.
  The linker-exec path only applies when the executable or its interpreter is
  under the Termux app-data directory, the effective user is not root/shell,
  and the SELinux context is not one of the exempted `untrusted_app_25/27`
  ones.
- Practical meaning: `chmod +x program && ./program` generally just works on a
  current Termux, where it failed during the mid-Android-10 era. This is not a
  root or permission change; it is an execution shim. **[version-sensitive]**
  **[DEVICE]**
- Do **not** casually unset `LD_PRELOAD` in child processes — the `termux-exec`
  interposer normally sits there, and removing it in a nested process can
  desync `TERMUX_EXEC__PROC_SELF_EXE`.

## Compiling: which toolchain is which

- On-device compilation uses the **Termux toolchain**: the `clang` package's
  wrappers + `ndk-sysroot` (Android platform headers) + `build-essential`,
  linking against the shared libraries in `$PREFIX/lib` (Android ABI, notably
  `libc++_shared.so`). Binaries built this way run inside Termux. There is
  **no `gcc` package**; `gcc` and `g++` on the PATH are clang symlinks.
  See [C/C++ Toolchain and Build Systems](03-c-cpp-toolchain-and-build-systems.md).
- A Linux distribution inside **proot/proot-distro** has a *different* libc
  toolchain, its own package set, and its own path/fd semantics. Do not mix
  binaries built for one environment into the other; compiling "in Debian on
  Termux" is not the same as compiling with Termux packages.
- The reference flow for **building Termux packages themselves** is the
  `termux-packages` Docker/build environment; building your own package from
  source just for yourself uses the toolchain above. Package-building from
  source is only mentioned here for orientation `[needs verification]` — Phase
  7 does not document a package-maintenance workflow.

## Background execution and process limits

- **Phantom-process killer (Android 12+)**: Android may kill groups of
  background processes or CPU-heavy processes; the symptom in a Termux session
  is `[Process completed (signal 9)]` with no exit code. This affects
  background daemons (`sshd`, database servers) and heavy parallel builds
  (`make -j`, `cargo`, pip building many C-extension wheels). Disabling the
  limit is a developer option on some Android builds. **[version-sensitive]**
  **[DEVICE]** **[OEM]**
- **Battery optimization / app standby** can suspend background sessions.
  Disable battery optimization for Termux if you rely on daemons.
  **[DEVICE]**
- Persistent services should use **`termux-services`** (runit) under
  `$PREFIX/var/service/`. A plain `nohup sshd &` is not persisted across
  force-stops or reboots. **[DEVICE]**
- An ordinary foreground `make`/`cargo`/`pip` build is a foreground process and
  is not affected by the background limits while the session is open.

## Environment variables Termux/Android set

The following are set by Termux/Android in a normal session (exact
per-release exports beyond these are `[needs verification]`):

- `PREFIX`, `HOME` (see [Paths and shell rules](#paths-and-shell-rules)),
  `TERM`, and a `PATH` that starts with `$PREFIX/bin`.
- Recent Termux app versions also export `TERMUX_*` variables describing the
  project/rootfs and app-data directories. **[version-sensitive]**
- `LD_PRELOAD` normally contains the `termux-exec` interposer — see
  [Executing files](#executing-files-wx-and-the-android-10-app-data-restriction).

Do not assume these variables exist identically inside proot-distro guests or
in `adb shell` sessions.

## Native Termux vs. proot for development

| Aspect | Native Termux | proot-distro guest (Ubuntu/Debian/…) |
|--------|---------------|--------------------------------------|
| Package manager | `pkg`/`apt` (Termux repos), real binaries | distro `apt`/`dnf`/etc., its own repos |
| libc / linker | Android Bionic + `$PREFIX/lib` | distro glibc-style toolchain |
| Compiler | `clang` wrappers (no `gcc` package) | distro's `gcc`/`clang` packages |
| Paths | `$PREFIX`, `$PREFIX/bin` | `/usr/bin`, `/etc` inside the guest |
| Foreground builds | normal | normal, but `/proc` and some syscalls are bridged |
| Best for | running Termux packages, `$PREFIX` integration | running software that assumes desktop Linux paths |

Choose the environment for the software you want to run; do not assume one
setup behaves like the other (AGENTS.md §6).

## Cross-references

- Where Termux stores things: [The Filesystem](../00-foundations/03-filesystem.md),
  [Storage and Permissions](../00-foundations/04-storage-and-permissions.md)
- The sandbox this all happens inside:
  [Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md)
- Installable packages: [Package Management](../01-termux/02-package-management.md)
- Background jobs and sessions:
  [Processes and Sessions](../00-foundations/06-processes-and-sessions.md),
  [Processes and Job Control](../02-shell/04-processes-and-jobs.md)
- Why ports above 1023: [SSH and Remote Access](02-ssh-and-remote-access.md)
- The Android execution contexts you are *not* in:
  [The Android Shell](../03-android/01-android-shell.md), [ADB Shell](../04-adb/04-adb-shell.md)

## References

- Phase 7 research notes §2–§9:
  `research/development/05-termux-android-dev-constraints-research.md`.
- `termux-exec` technical/usage documentation and `termux-app` issue #1072
  (W^X / app-data execution), verified 2026-09-22.
- Phantom-process killer background: `research/termux/00-foundations-research.md`
  (citing `termux-app` issue #2366).