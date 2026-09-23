# Termux & Android Development Constraints — Research Notes (Phase 7)

Status: research notes supporting Phase 7 (PLAN.md §12/§14 development
environments; AGENTS.md §6 environment distinctions, §7 paths, §10 privileged
access). These constraints frame every "how-to develop on Termux" chapter and
are cross-referenced from the other Phase 7 research files. Not polished
documentation; kept separate from Bible chapters per AGENTS.md §17 /
PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Items
needing a live device are tagged **[DEVICE]**; Android/API-version dependent
behavior is tagged **[version-sensitive]**; OEM-specific behavior **[OEM]**;
unresolved claims `[needs verification]`.

Audit note: W^X / app-data-execution facts were verified against the official
`termux/termux-exec` project documentation (repo docs, technical/usage pages)
and `termux/termux-app` issue #1072 (fetched 2026-09-22). The phantom-process
killer note is cross-referenced from `research/termux/00-foundations-research.md`
(which cites termux-app #2366). Package-manager facts come from the
`termux-tools` `pkg.in` script and `termux-main` index.

---

## 1. Purpose

Termux is a normal Android app. Everything a developer does inside it is
subject to Android's app sandbox and to Termux's runtimes being built for
Android, not for desktop Linux. This file records the constraints that
reappear in many future chapters so they can be referenced instead of
duplicated.

## 2. Environment Distinctions (AGENTS.md §6)

Keep separate: normal Termux (user's app UID), Termux packages, the Android
shell (`adb shell`), the root shell, Shizuku/Porter/rish, and proot-distro
distributions. Practical differences that matter for development:

- Termux processes run as an **unprivileged Android app UID** (typically
  `u0_a*`), not root, and not the `shell` user (except in adb-backed
  scenarios).
- All `$PREFIX` binaries/scripts operate within `/data/data/com.termux/...`
  (developer-configurable rootfs location; `TERMUX__PROJECT_DIR`/
  `TERMUX__ROOTFS` exported by the app since 0.119 — see §4).
- adb-issued commands (e.g. `adb shell`) run as `shell` uid in a different
  context and do NOT automatically see Termux's `$PREFIX` paths; using them
  interchangeably is an error.
- proot-distro runs a Linux distro on top of a proot bridge (different
  toolchain view, `/proc` limited) — compiling "in Debian on Termux" is not
  the same as compiling with Termux packages.

## 3. Paths and Shell Rules (AGENTS.md §7)

- `$PREFIX` defaults to `/data/data/com.termux/files/usr`.
- `$HOME` defaults to `/data/data/com.termux/files/home`.
- `~/storage/...` = `$HOME/storage` symlink farm (set up by `termux-setup-storage`)
  pointing at `/storage/emulated/0/...` — shared/visible storage, **not** the
  app-private home.
- `/bin`, `/usr/bin`, `/etc` generally do not exist as desktop-Linux paths.
  Termux scripts use `$PREFIX/bin`. `termux-exec` rewrites shebang `/bin/...`
  and `/usr/bin/...` references to `$PREFIX/bin` for scripts run inside Termux
  (see §5). Example shebangs should therefore either be portable
  (`#!/usr/bin/env python3`) or `#!$PREFIX/bin/...`.
- `$PREFIX/tmp` is the scratch dir (a real dir, not the Android `/tmp`).
- Config conventions: `$PREFIX/etc`, `$PREFIX/etc/bash_completion.d`,
  `$PREFIX/var/service` (runit), `$PREFIX/var/run`, `$PREFIX/var/log`.

## 4. Executing Files: W^X / App Data File Execute Restrictions

Verified: termux-exec technical/usage docs and termux-app #1072/2155.

- **Android 10+** enforces W^X: `targetSdkVersion >= 29` apps (`untrusted_app`
  domain, Android 10+; some OEM variants earlier/later) are **blocked from
  executing** (and `exec()`-ing) files in their app data directory (the
  `app_data_file` context). App data (`/data/data/<pkg>`) is exactly where
  Termux stores its binaries, scripts, and compiled programs.
- Backward-compat domain exemptions: apps with `targetSdkVersion <= 25`
  (`untrusted_app_25`) or `26–28` (`untrusted_app_27`) can still execute data
  files directly; `dlopen()` of data files remains allowed for all
  `untrusted_app*` domains `[version-sensitive]`.
- **Termux solution — `termux-exec`** (essential package, preinstalled): a
  `LD_PRELOAD` interposer (package ships `$PREFIX/lib/libtermux-exec.so`;
  the currently active variant, `libtermux-exec-ld-preload.so`, is selected by
  `termux-exec-ld-preload-lib setup` during install based on
  `termux-exec-system-linker-exec is-enabled` — see termux-exec technical
  docs) does two things:
  1. Rewrites shebangs/interpreter paths (`/bin/`, `/usr/bin/`) to
     `$PREFIX/bin`.
  2. **System Linker Exec**: when direct execution of an app-data file is
     blocked, re-executes it through the Android linker, i.e.
     `/system/bin/linker64 <path>` (supported on Android 10+). The kernel only
     sees the trusted `/system/bin/linker64` process.
- Control: `TERMUX_EXEC__SYSTEM_LINKER_EXEC__MODE` (`enable` [default] /
  `disable` / `force`); query with `termux-exec-system-linker-exec
  is-enabled`. The linker-exec path applies only when the executable or
  interpreter is under the Termux app-data dir, the effective user is not
  root/shell, and the SELinux context is not the exempted
  `untrusted_app_25/27` ones.
- This is precisely why "install and run `./program` in Termux" generally
  works, while it failed mid-Android-10 era (see issues #1072, #2155).
  Chapters should explain this once and reference `termux-exec`; do not
  present it as a root/permission change `[version-sensitive]` `[DEVICE]`.

## 5. No Root / No High Ports / No Traditional Privileged Services

- Termux users are unprivileged: no `chown` on system paths, no `iptables`,
  no binding **ports below 1024** (all Termux servers use high ports, e.g.
  sshd's compiled default 8022 — see `01-ssh-research.md`). Anything *requiring*
  root is out of scope unless root is explicitly involved (e.g. `tsu`, ADB
  root, Magisk).
- Privileged alternates (ADB/root/Shizuku/Porter/rish) are separate systems
  (AGENTS.md §10); development in Termux does not normally require them.
- `pkg` refuses to run as root and wraps the configured package manager
  (`apt` or `pacman` via `termux-setup-package-manager`); normal installs run
  as the app user.

## 6. Background Execution and Process Limits

- **Phantom process killer (Android 12+)**: Android may kill >32 phantom
  processes (aggregated across apps) and CPU-heavy processes; symptom is
  `[Process completed (signal 9)]` with no exit code. Disabling this is a
  developer option on Android 12L/13 (see `research/termux/00-foundations-research.md`,
  which cites termux-app #2366). Affects background daemons (`sshd`, db
  servers), parallel build jobs (`make -j`, `cargo`, `pip` heavy builds).
- Battery optimization / app standby can suspend background sessions; users
  disable battery optimization for Termux for daemons `[DEVICE]`.
- Persistent services use `termux-services` (runit) under
  `$PREFIX/var/service/`; a plain `nohup sshd &` is not persisted across
  force-stops/reboots `[DEVICE]`.

## 7. Compiling vs. Termux Packages vs. Other Toolchains

- On-device compilation uses the Termux toolchain (`clang` + `ndk-sysroot`
  + `build-essential`), and links against `$PREFIX/lib` shared libs
  (Android ABI, `libc++_shared.so`). This is what makes binaries run inside
  Termux.
- The `termux-packages` CI builds packages for all arches; a developer can
  **build-and-install packages from source** on-device, but the reference
  flow for maintaining packages is the termux-packages Docker/build
  environment `[needs verification]` if a later phase documents package
  building.
- proot / proot-distro (Ubuntu/Debian on Termux) has a *different* libc
  toolchain and its own path/fd semantics; do not mix binaries built for one
  into the other.
- Nothing here implies root; ADB/Shizuku/Porter/rish topics live in their
  own research files (`research/adb/`, `research/shizuku/`,
  `research/rish/`, `research/porter/`).

## 8. Files, Storage, and Permissions for Dev Workflows

- Files meant to be moved to the host/computer via USB should live under
  `~/storage/shared` (to `/storage/emulated/0`); app-private data is not
  visible to other apps `[DEVICE]`.
- `pkg install termux-api` + `termux-*` binaries give intents, clipboard,
  sensors, notifications, toasts, storage permission helpers from scripts;
  cross-ref Phase 1 research (`research/termux/00-foundations-research.md`).
- Many package postinstalls write shell helpers into `$PREFIX/etc/termux/`
  and drop completions into `$PREFIX/etc/bash_completion.d/`.

## 9. Environment Variables Termux/Android Set

Verified: termux-exec/app docs and termux-tools `pkg.in` [environment facts
are `[needs verification]` for exact per-release exports beyond the below]:

- `PREFIX`, `HOME` (see §3), `TERM`, `PATH` starting with `$PREFIX/bin`.
- The app exports `TERMUX_*` variables in recent versions (project/rootfs dir,
  app data dir, process context helpers) `[version-sensitive]`.
- `LD_PRELOAD` normally contains the `termux-exec` interposer — do not unset
  it casually in child processes (termux-exec usage docs: unsetting in a
  nested process can desync `TERMUX_EXEC__PROC_SELF_EXE`).

## 10. Unresolved / Device-Verified Items

- Exact `TERMUX_*` exports for the current stable Termux app release
  `[DEVICE] [needs verification]`.
- Behavior of the phantom-process limit under load on real devices/brands
  `[DEVICE] [OEM]`.
- Whether `system linker exec` path applies on all OEM Android 10+ devices
  `[DEVICE] [OEM]`.
- High-port binding restrictions on all Android devices (standard, but
  `[DEVICE]` check for unusual OEM sandboxes).