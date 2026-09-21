# Termux Foundations Research Notes (Phase 2)

Status: research notes supporting Phase 2 "Termux Foundations" (PLAN.md §32).
Not polished documentation. Distinguished from Bible chapters per AGENTS.md §17 / PLAN.md §21.
Compiled: 2026-09-21. Environment note: research performed from a proot (Ubuntu) container; no live Termux device was available, so anything requiring empirical device verification is marked accordingly.

Audit round 2026-09-21 (Phase 2 research audit): re-verified against upstream sources (termux-tools scripts/Makefile.am, proot-distro README, termux-packages packages/*/build.sh and scripts/generate-bootstraps.sh, GitHub issues termux-app #3647/#4440/#4767, termux-packages #8327, termux/glibc-packages README). Corrections applied inline and new facts are tagged [AUDIT]. The distinction between **native Termux package management** and **Linux-distro-in-proot package management** is documented in new section §3.12.

## 1. Scope

Topics covered by PLAN.md Phase 2 and Volume I:

- installation sources;
- package management (`pkg` vs `apt`, limitations);
- repositories (main, x11, root, TUR, glibc, mirrors);
- filesystem and `$PREFIX`/`$HOME`;
- storage (`termux-setup-storage`, `~/storage`);
- shell basics and environment variables;
- permissions and sandboxing;
- sessions;
- configuration (`termux.properties`, `termux-reload-settings`);
- Termux utilities (`termux-tools` scripts and wrappers);
- add-ons.

## 2. Source Inventory

Reliability ranking as used in this document (AGENTS.md §3.2):

- A — Official project README/repo/source (termux-app, termux-tools, termux-packages).
- B — Official Termux developer wiki (GitHub wiki of termux-packages).
- C — Termux user wiki (wiki.termux.com / wiki.termux.dev) — DEPRECATION NOTICE present; content can be stale.
- D — Community mirrors/documentation (termux-wiki.vercel.app, termux-pacman, TUR READMEs).
- E — Tertiary (Wikipedia, third-party blogs). Used only for discovery, never as authority.

Primary sources checked:

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| S1 | https://github.com/termux/termux-app README.md (master) | A | raw.githubusercontent.com |
| S2 | https://github.com/termux/termux-tools scripts/Makefile.am | A | raw.githubusercontent.com |
| S3 | https://github.com/termux/termux-tools scripts/pkg.in | A | raw.githubusercontent.com |
| S4 | https://github.com/termux/termux-tools scripts/termux-setup-package-manager.in | A | raw.githubusercontent.com |
| S5 | https://github.com/termux/termux-tools termux.properties (template) | A | raw.githubusercontent.com |
| S6 | https://github.com/termux/termux-tools mirrors/default | A | websearch cache |
| S7 | https://packages.termux.dev/ index | A | websearch cache |
| S8 | https://github.com/termux/termux-packages/wiki (Package Management, Termux-file-system-layout, Termux-execution-environment, Mirrors, package-management) | B | websearch cache (direct wiki fetch is truncated/blocked by Anubis) |
| S9 | https://wiki.termux.dev/wiki/{Main_Page,Termux-setup-storage,Internal_and_external_storage,Package_Management,Terminal_Settings,Building_packages,Getting_started,Differences_from_Linux} | C | websearch cache (direct fetch blocked by Anubis 1.25) |
| S10 | https://github.com/termux/termux-app/issues/3647 (termux-setup-storage on Android 14) | A (issue) | websearch cache |
| S11 | https://github.com/termux-user-repository/tur README | D | websearch cache |
| S12 | https://github.com/termux/glibc-packages README (repo mirror) | D | websearch cache |
| S13 | https://termux-pacman.dev + https://github.com/termux-pacman | D | websearch cache |
| S14 | termux-packages releases (bootstrap archives) | A | websearch cache |
| S15 | https://wiki.termux.dev/wiki/ (Anubis page — evidence of bot protection; articles retrieved only via search engine cache) | — | direct fetch |
| S16 | https://github.com/termux/proot-distro README (master, raw) | A | raw.githubusercontent.com |
| S17 | https://github.com/termux/termux-packages packages/apt, x11-repo, tur-repo build.sh + scripts/generate-bootstraps.sh (master, raw) | A | raw.githubusercontent.com |
| S18 | GitHub issues: termux/termux-app #3647, #4440, #4767, #3320; termux/termux-packages #8327 | A (issue) | websearch cache |
| S19 | https://github.com/termux/glibc-packages README (official mirror) + termux-pacman org pages | A/D | websearch cache |
| S20 | termux-tools releases (v1.45.0, v1.46.0 release notes) | A | websearch cache |

Access barriers encountered: wiki.termux.com and wiki.termux.dev both run Anubis 1.25 bot protection and refuse automated fetches; GitHub wiki pages fetch partially but with truncation; search-engine caches returned full page text and are used as the retrieval mechanism. The official user wiki carries a DEPRECATION NOTICE (verified [AUDIT, S18]): new user contributions and account creation are no longer accepted; material "might be outdated" and the wiki "is planned to be moved elsewhere, likely to GitHub wiki pages with possibility to make changes by opening a PR in a repo" (planned migration issue termux/termux-packages#8327). GitHub raw file fetches (raw.githubusercontent.com) worked reliably during the audit and are the best direct-fetch path.

## 3. Facts Verified and Their Sources

Facts below are stated with the strongest available source. Where a fact is version-sensitive it is marked **[version-sensitive]**. Facts I could not verify from an authoritative source are in §10.

### 3.1 What Termux is / execution environment

- Termux is an Android terminal application and Linux environment that runs without rooting. [S1, S9 Main_Page]
- A minimal base system is installed automatically; additional packages come from the package manager. [S9]
- Termux uses Bionic libc, not glibc; programs must be patched/recompiled for the Termux environment. [S9 Differences_from_Linux]
- Termux cannot follow the FHS (Filesystem Hierarchy Standard): no write access to `/bin`, `/etc`, `/usr`, `/var` as Android system tree. [S9 Differences_from_Linux, S8 file-system-layout]
- Termux is single-user: everything runs under the Termux app UID (e.g. `u0_aXXX`); username is derived from the UID by Bionic libc and cannot be changed. [S9 Differences_from_Linux]
- Root filesystem and home live in the app-private directory on `/data`; uninstalling Termux or wiping its data deletes `$PREFIX` and `$HOME`. [S9]
- `/data` is typically EXT4 or F2FS, so the app data directory supports unix modes, executable permission, symlinks, and special files. [S8 file-system-layout]
- On Android 12+ Termux may be unstable: Android kills >32 phantom processes (all apps combined) and CPU-heavy processes; symptom is `[Process completed (signal 9)]` without exit. See termux-app issue #2366. Disabling this is a developer option in Android 12L/13. [S1]
- Termux app's child processes: TermuxTasks via `Runtime.exec()`, sessions via `execvp()`. [S8 execution-environment]

### 3.2 Installation

- Current stable version at time of research: **v0.118.3** (released 2025-05-22). Latest prerelease: **v0.119.0-beta.3** (2025-05-22). **[version-sensitive]** [S1]
- **[AUDIT]** The v0.119 series is the current development line: its betas export `TERMUX_APP_PACKAGE_MANAGER` (see §3.8/§3.12), request the Android "All files access" (MANAGE_EXTERNAL_STORAGE) permission instead of the legacy write-storage permission, and include `android-5` APK variants (see Android 5/6 bullet below). **[version-sensitive]** [S1 assets list, S18 #4767]
- Supported sources: **F-Droid** (recommended for most users), **GitHub** (Release APKs for >=0.118.0 and build-action artifacts), **Google Play (experimental branch)**. [S1]
- Full app + package support requires **Android >= 7**. [S1]
- Android 5/6: package support dropped 2020-01-01 at v0.83; app-only support re-added 2022-05-24 via GitHub builds, **without package updates**. **[AUDIT]** The v0.119 series re-adds full android-5/6 support, including `apt-android-5` bootstrap/APK variants (developer wiki: "re-added support for android 5/6 to termux-app starting from termux-app version 0.119"). **[version-sensitive]** [S1, via S1 wiki link Termux-on-android-5-or-6; S18 dev-wiki Home]
- APK/bootstrap sizes: ~180 MB universal, ~120 MB architecture-specific. [S1]
- **Mixing install sources is not allowed:** Termux and all plugins share `sharedUserId` `com.termux`; all APKs on a device must be signed the same way and come from one source. Switching source requires uninstalling everything Termux-related. [S1]
- F-Droid builds use an untrusted, but non-public, signing key; GitHub builds use a **publicly known test key** — a security warning: malicious builds can be installed over GitHub builds. [S1]
- Google Play build: exists for Android 11+; built from a separate repo (https://github.com/termux-play-store/); missing functionality compared to F-Droid build; Play may try to auto-update away from F-Droid installs. **[AUDIT] Version-sensitive history:** Play distribution was suspended (policy/API-level problems), then Termux became available again on Google Play starting June 2024 after adjustments for updated Google Play policy; the user wiki still labels Play versions "deprecated". [S1, S18 wiki Installation]
- "Bootstrap" = minimal packages shipped with the app to start a working shell; zip bootstrap archives are released on termux-packages releases (e.g. `bootstrap-2026.08.30-r1+apt.android-7`). [S1, S14]
- System requirements per wiki: Android 5.0–12.0 (issues on 12+), CPUs AArch64/ARM/i686/x86_64, >=300 MB disk; ARM without NEON unsupported; VMOS/F1VM sandboxes unsupported. **[version-sensitive; wiki content may be stale]** [S9 Main_Page]

### 3.3 Package management

- Termux uses `apt` and `dpkg` (Debian-style), default package format `.deb`. [S9 Package_Management]
- **Prefer `pkg` over calling `apt` directly.** `pkg` is a wrapper that: provides command shortcuts (`pkg in` = install); runs `apt update` when needed; performs client-side repo load-balancing by rotating mirrors. [S9, S3]
- `pkg` refuses to run as root. [S3]
- Full `pkg` subcommand set: `autoclean`, `clean`, `files P`, `install P`, `list-all`, `list-installed`, `reinstall P`, `search Q`, `show P`, `uninstall P`, `upgrade`, `update`, plus `--check-mirror` flag, `pkg help`. [S3]
- `apt` has restrictions in Termux: only a single architecture; no downgrades (no version history kept); apt usage under root is restricted (to protect ownership/SELinux labels on `/data`). [S9 Package_Management]
- Debian/Ubuntu packages must NOT be used (not FHS compliant). [S9]
- Recommended cadence: `pkg upgrade` regularly; check for updates at least weekly. [S9]
- Removal: `pkg uninstall P` leaves config files; `apt purge` removes them. [S9]
- **[AUDIT]** apt version: as of research date termux-packages master ships **apt 2.8.1+r2** (build.sh TERMUX_PKG_VERSION=2.8.1); termux-tools v1.46.0 (2025-11) release notes say "Prepare pkg and termux-info for apt 3.0.0", i.e. tooling is prepared for a future apt 3.x, but apt 3.0.0 is not yet packaged. **[version-sensitive]** [S17 apt/build.sh, S20]
- **[AUDIT]** The `apt` package depends on `termux-keyring` (which holds the repository signing keys — this resolves the "keyring package name" open question). The apt package also `CONFLICTS`/`REPLACES`/`PROVIDES` `game-repo`, `science-repo` and `unstable-repo`, i.e. those merged repos are now delivered by apt itself. [S17 apt/build.sh]

### 3.4 Repositories and mirrors

- Official repos (host shape, structurally current; host domain has moved over time **see §10**):
  - Main: `deb https://packages.termux.dev/apt/termux-main stable main`
  - Root: `deb https://packages.termux.dev/apt/termux-root root stable`
  - X11: `deb https://packages.termux.dev/apt/termux-x11 x11 main` [S7]
- The main repo is reachable via both hosts; **[AUDIT]** the default `$PREFIX/etc/apt/sources.list` written by the current apt package lists `deb https://packages-cf.termux.dev/apt/termux-main/ stable main` (Cloudflare cache, "with cloudflare cache") first and the plain `packages.termux.dev` line commented out. `pkg` mirror rotation may rewrite this file, so the active default depends on mirror selection. **[version-sensitive]** [S6, S8 Mirrors, S17 apt/build.sh]
- Enable optional repos by installing `-repo` packages: `pkg install x11-repo` (Android 7+), `pkg install root-repo`, community `pkg install tur-repo`. The game/science/unstable repos were **merged into main**; legacy `science-repo`/`game-repo` should be removed. [S9 Package_Management, S8 package-management]
- `glibc-repo` (a deb-format mirror of termux-pacman/glibc-packages) and `glibc-runner` exist for installing glibc-based programs. **[AUDIT] Boundary resolved:** the repo `termux/glibc-packages` is an official-org mirror which compiles termux-pacman/glibc-packages content into **debian format** and publishes it to the Termux service; the upstream source and contributions live in `termux-pacman/glibc-packages`. Usage: `pkg install glibc-repo -y`, then `pkg install glibc-runner -y`. So the package is distributed through official channels but the project originates with the termux-pacman (community) org. [S12/S19]
- Sources files: `$PREFIX/etc/apt/sources.list` (main) and `$PREFIX/etc/apt/sources.list.d/` for extra repos. **[AUDIT] Correction:** current `-repo` packages write the **legacy `.list` one-line format**, not deb822 `.sources` — verified: x11-repo writes `sources.list.d/x11.list` (`deb https://packages-cf.termux.dev/apt/termux-x11/ x11 main`), tur-repo writes `sources.list.d/tur.list`. Deb822 `*.sources` remains a supported format but is not what shipped `-repo` packages produce today. [S3, S6, S17]
- `pkg`/`termux-change-repo` manage these; mirrors defined under `$PREFIX/etc/termux/mirrors/` (default, asia, chinese_mainland, europe, north_america, oceania, russia) with `WEIGHT=` lines; user selection stored in `$PREFIX/etc/termux/chosen_mirrors` (file, symlink, or directory). [S3, S6]
- `termux-change-repo` (part of termux-tools) is the user-facing mirror picker; `termux-info` shows current mirrors. [S8 package-management]
- Mirror rotation logic in `pkg`: checks current mirror, tests up to 10 mirrors in parallel, weighted random pick, rewrites the active `sources.list`/`*.sources`. [S3]
- **[AUDIT]** TUR (Termux User Repository) detail: `tur-repo` is now a package inside official termux-packages but points at community hosting — it writes `sources.list.d/tur.list` = `deb https://tur.kcubeterm.com tur-packages tur tur-on-device tur-continuous` and installs its own gpg key to `$PREFIX/etc/apt/trusted.gpg.d/tur.gpg`. TUR packages are explicitly not official Termux packages. [S17 tur-repo/build.sh, S11]
- Android 5/6 (obsolete) era has separate repo `termux-main-21`. [S7]

### 3.5 Filesystem

- `$PREFIX` = `/data/data/com.termux/files/usr`. Exported in shell. [S9 Getting_started, S8 file-system-layout]
- Also referred to as `$TERMUX_PREFIX` / `$TERMUX__PREFIX` (latter used in packaging context). [S8 file-system-layout]
- `$HOME` = `/data/data/com.termux/files/home`. [S9, S8]
- Prefix layout: `bin`, `etc`, `include`, `lib`, `libexec`, `opt`, `share`, `tmp`, `var` (incl. `var/run`). [S8 file-system-layout]
  - `$PREFIX/tmp` — "Erased on each application restart". [S8]
  - `$PREFIX/var/run` — locks, PIDs, sockets (replaces `/run`). [S8]
- `$PREFIX` cannot be moved: path is hardcoded into binaries; filesystem must support unix perms/symlinks/sockets. [S9 Getting_started]
- Do not put `$PREFIX`/`$HOME` on external/SD storage. Only rooted users may consider it; external storage is typically read-only except the Termux private dir and lacks exec/perms. [S9 Internal_and_external_storage, S9 Differences_from_Linux]
- Android paths useful to document: `/system/bin` (AOSP tools, `root:shell` perms, generally `rwxr-xr-x`), `/bin` is a symlink to `/system/bin`, `/sdcard` is `/storage/emulated/0` for the primary user. Avoid adding `/system/bin` to `$PATH` (conflicts with Termux utilities). [S8 file-system-layout, S8 execution-environment]
- Storage low-water marks: Android free-storage limit = 5% or 500 MB (whichever lower); caches deleted when free storage reaches 150% of that value. [S8 file-system-layout]

### 3.6 Storage access

- Shared storage access needs an explicit permission; not granted by default and not requested at startup. [S9 Termux-setup-storage]
- `termux-setup-storage` (in termux-tools) requests the permission and creates `$HOME/storage` symlink set:
  - `~/storage/shared` — root of shared storage
  - `~/storage/downloads`, `~/storage/dcim`, `~/storage/pictures`, `~/storage/music`, `~/storage/movies`
  - `~/storage/external-1` — Termux-private folder on external SD (only if present)
  - Re-running wipes and rebuilds `~/storage`; it asks confirmation. [S9 Termux-setup-storage]
- Permission grant paths by Android version:
  - Android <11: Settings > Apps > Termux > Permissions > Storage
  - Android >=11: Permissions > Files and media > "Allow management of all files"
  - Android >=13: (Advanced >) Special app access > All files access [S10]
- Android 11+ known issue: `Permission denied` even after granting; workaround = revoke and re-grant. Not a Termux bug. [S9 Termux-setup-storage]
- Android 14: `termux-setup-storage` may do nothing / exit 255; maintainer guidance says install `termux-am` first (`pkg install termux-am`) and check the new permission location. See issue #3647. **[version-sensitive]** [S10]
- **[AUDIT] Version-sensitive permission-model change:** in termux-app **v0.118.x** the app still requests the *legacy* write-storage permission (`Settings > Apps > Termux > Permissions > Storage`, or "Files and media" on Android 11+), which may not grant root-of-shared-storage access on every device/ROM (e.g. GrapheneOS storage scopes); the v0.119.* betas request **"All files access" (MANAGE_EXTERNAL_STORAGE)** instead. On Android 15 with 0.118.x the documented fallback is to manually grant "All Files Access" under `Settings > Apps > Termux > (Additional >) Special app access`. Sources: maintainer replies in issues #4767, #4440, #3320. [S18]
- **[AUDIT] Android 13+ granular media labels** ("Photos and videos", "Music and audio", "Files" under "Files and media") apply to apps using READ_MEDIA_*; for Termux the operative permission remains the all-files path above. Exact label text on stock Android 14/15 is device-dependent and still needs a device screenshot. [S18 #3320; Android docs]
- External SD/USB drives are generally read-only for apps; a Termux-private dir exists at `Android/data/com.termux` and **is deleted on uninstall**. [S9 Internal_and_external_storage]
- `termux-storage-get` (needs Termux:API + termux-api package) uses the Android file picker / SAF for files by content URI. [S9 Internal_and_external_storage]
- Keep content out of external storage for performance and correctness; internal (`$HOME`) is the normal location. [S9]

### 3.7 Shell and environment

- Termux shell starts `bash` (default) via a login mechanism; environment is set up by Termux app + `login` script from termux-tools. [S2, S1]
- Exported environment: `$PREFIX`, `$HOME` (and other standard vars). See §10 for a complete authoritative variable list.
- Shared libraries: before Android 7, Termux exported `$LD_LIBRARY_PATH`; on Android 7+ the linker uses `DT_RUNPATH` in the ELF header instead. **[version-sensitive]** **[AUDIT] Confirmed at C-tier** (user wiki + its vercel mirror carry identical wording) and **corroborated** by the termux-tools wrappers, which explicitly `unset LD_LIBRARY_PATH LD_PRELOAD` before executing `/system/bin` tools "to avoid conflicting with system libraries". Still verify on-device with `readelf -d`. [S9, S2 wrapper-rule]
- Shebangs: standard scripts with `#!/bin/sh` may fail; `termux-fix-shebang` rewrites them; `termux-exec` package provides a lib (LD_PRELOAD) wrapper allowing standard `#!/bin/sh` execution. [S9 Differences_from_Linux, S8 execution-environment]
- Executables cannot be executed directly on external storage (`noexec` mount); scripts can be run through an interpreter (`bash /sdcard/script`). [S8 execution-environment]

### 3.8 termux-tools utilities (official command set)

Scripts in the `termux-tools` package (bin_SCRIPTS): `chsh`, `dalvikvm`, `login`, `pkg`, `su`, `termux-backup`, `termux-change-repo`, `termux-fix-shebang`, `termux-info`, `termux-open`, `termux-open-url`, `termux-reload-settings`, `termux-reset`, `termux-restore`, `termux-setup-package-manager`, `termux-setup-storage`, `termux-wake-lock`, `termux-wake-unlock`. [S2]

Wrappers around `/system/bin` tools (installed alongside): `df`, `getprop`, `logcat`, `ping`, `ping6`, `pm`, `settings`, `top`. **[AUDIT] Open question #3 resolved:** the Makefile contains build rules for `mount`/`umount` wrappers too, but `mount` and `umount` are **not** in `bin_SCRIPTS`, so they are *not installed* by the termux-tools package — do not document a `mount`/`umount` wrapper as present. Wrappers unset `LD_LIBRARY_PATH` and `LD_PRELOAD`, set `PATH=/system/bin`, and `exec /system/bin/$1`. [S2]

`termux-open` is symlinked/aliased as `xdg-open`. [S2]

**[AUDIT] Backup/restore/reset scope (open question from §10 resolved, from script sources):**
- `termux-backup [options] FILE`: archives **only `$PREFIX`** (as `usr/` under the base dir), never `$HOME` or storage; TAR output, compression by file extension (`--auto-compress`), `-` writes uncompressed to stdout; options `-f/--force` (overwrite) and `--ignore-read-failure`. [S2 termux-backup.in]
- `termux-restore FILE|-`: restores `$PREFIX` from a termux-backup archive; **erases all files in `$PREFIX` not present in the archive** (`--recursive-unlink --preserve-permissions`); refuses to run as root. [S2 termux-restore.in]
- `termux-reset`: wipes everything under `$PREFIX` (packages, configs, databases) after a y/n prompt; **does not remove `$HOME`, shared storage or external storage**; preserves the `termux-am` APK for later use and kills remaining sessions. **Dangerous operation — documentation must carry a warning.** [S2 termux-reset.in]

- `termux-setup-package-manager`: sets `TERMUX_APP_PACKAGE_MANAGER` to `apt` or `pacman`. Normally exported by the app (v0.119.0+) or by `login` script via `TERMUX_MAIN_PACKAGE_FORMAT`. **[AUDIT] Version-note:** the script source comments reference "termux-tools v0.161+" — likely a stale/typo reference, since termux-tools versions are 1.x (latest v1.48.0 at research time); do not propagate that version number into the Bible. The important threshold is the termux-app 0.119.0 version comparison, not a termux-tools version. **[This indicates the package manager situation is evolving; see §4/§10.]** [S4, S20]
- `pkg` maps to either apt subcommands or pacman subcommands depending on `TERMUX_APP_PACKAGE_MANAGER` (e.g. `pkg upgrade` → `apt update && apt full-upgrade`, or `pacman -Syu`). [S3]

### 3.9 Configuration

- Main config: `~/.termux/termux.properties` (`$HOME/.termux/termux.properties`). Java `.properties` key=value syntax; `#` comments; shipped template has most properties commented out. [S9 Terminal_Settings, S5]
- Apply with `termux-reload-settings` or restart the app; some properties need an app process restart. [S9, S5]
- Template-documented properties (all shipped commented out, current-master list): `allow-external-apps`, `default-working-directory`, `disable-terminal-session-change-toast`, `hide-soft-keyboard-on-startup`, `soft-keyboard-toggle-behaviour`, `terminal-transcript-rows` (scrollback, max 50000), `volume-keys`, `fullscreen`, `use-fullscreen-workaround`, `terminal-cursor-blink-rate`, `terminal-cursor-style`, `extra-keys-style`, `extra-keys-text-all-caps`, `extra-keys` (incl. popups/macros JSON-like syntax), `use-black-ui`, `disable-hardware-keyboard-shortcuts`, `shortcut.create-session`, `shortcut.next-session`, `shortcut.previous-session`, `shortcut.rename-session`, `bell-character` (vibrate/beep/ignore), `back-key` (back/escape), `enforce-char-based-input`, `ctrl-space-workaround`, `terminal-margin-horizontal`, `terminal-margin-vertical`. [S5]
- Color schemes/fonts: Termux:Styling add-on; `colors.properties` and `font.ttf` traditionally live in `~/.termux/`. [S9, S5 mention]

### 3.10 Sessions

- Sessions: Termux supports multiple terminal sessions with shortcuts `shortcut.create-session`, `shortcut.next-session`, `shortcut.previous-session`, `shortcut.rename-session` (examples use `ctrl + t`, `ctrl + 2`, `ctrl + 1`, `ctrl + n`). [S9 Terminal_Settings, S5]
- Session switching via long-press in app; toasts on session change can be disabled (`disable-terminal-session-change-toast`). [S5]

### 3.11 Add-ons

- Official plugins referenced by termux-app README: Termux:API, Termux:Boot, Termux:Float, Termux:Styling, Termux:Tasker, Termux:Widget. [S1]
- Wiki also lists Termux:Float; community/separate: Termux:X11 (termux-x11 repo) and Termux:GUI (termux-gui repo). **[X11/GUI status to verify]** [S9 Main_Page, S1]
- All plugins must come from the same source as the main app (shared UID + signing). [S1]

### 3.12 Native Termux vs proot-distro package management [AUDIT — new section]

Requirement from the audit: the Bible must never conflate the two. They are separate package ecosystems with separate package databases, separate package managers, and separate repositories.

**Native Termux (the base environment in `$PREFIX`):**

- Native packages are what the Termux app installs at first run (the "bootstrap") and later via `pkg`/`apt`. They are compiled for Android/Bionic by the official termux-packages build system and are unsuitable to copy from Debian/Ubuntu/other distros. [S9, S17]
- Native package manager (current default): **apt + dpkg**, front-ended by the `pkg` wrapper; package format `.deb`. Repos: termux-main by default, plus optional official `root-repo`, `x11-repo` (and the merged-out game/science/unstable — now provided by apt) and community `tur-repo`/glibc sources. Sources live under `$PREFIX/etc/apt/`, keys under `$PREFIX/etc/apt/trusted.gpg.d/` and keyring package `termux-keyring`. No FHS, no `/usr`, single architecture, no downgrades, root restriction. [S8, S9, S17]
- The pacman transition (§4) is a **native-Termux** evolution: `pkg` can dispatch to pacman and termux-packages can generate `pacman.android-7` bootstraps, but the Termux app does **not yet** install pacman bootstraps (infrastructure TODO); default remains apt. This is about the native environment only. [S4, S17 generate-bootstraps.sh]

**Linux distributions inside proot-distro:**

- proot-distro manages **separate root filesystems** (containers) pulled as Docker/OCI images or tarballs; it does not touch native `$PREFIX` packaging. [S16]
- Inside a container, the distro's **own package manager** applies: e.g. Debian/Ubuntu use their `apt`/`dpkg`; Alpine `apk`; Arch `pacman`; Fedora/SUSE `dnf`/`zypper`. Ubuntu's `apt` inside the container is **not Termux's package manager** — it operates on the container rootfs (`/etc/apt/`, `/var/lib/dpkg/`), a different dpkg database and different repositories, following FHS inside the container. [S16]
- Consequently: native-Termux facts that do **not** transfer into a proot distro include — "pkg over apt", single-architecture restriction, no-downgrade policy, repo/mirror handling (`termux-change-repo`), termux-keyring, Bionic linkage, non-FHS layout, and the apt→pacman transition. Within a proot distro you use that distro's tools (`apt-get`, `apk`, `pacman`, `dnf`, `zypper`) against FHS paths (`/usr`, `/etc`, `/var`). [S16, reasoning from sources]
- Discovery/usage model (verified from proot-distro README master): install with native `pkg install proot-distro` (pulls in `proot`); `proot-distro search/install/login/run/list/remove/backup/restore/copy/sync`; alias `pd`. Default login user is **root** inside the container (and proot-distro warns if launched as root on the host). Guest environment is **not** inherited from the host; a clean env is built and `$PREFIX/bin` is appended to the guest `PATH`; for normal-type containers the Termux `$PREFIX` is bind-mounted into the guest at its original path so `pkg`/`termux-api` are reachable. [S16]
- Storage layout [AUDIT, S16]: runtime data under `$RUNTIME_DIR` = `$TERMUX__PREFIX/var/lib/proot-distro/` (with `TERMUX__PREFIX` defaulting to `/data/data/com.termux/files/usr`). Current container layout: `containers/<name>/rootfs/` + `containers/<name>/manifest.json`, plus `locks/`, `sessions/`, OCI caches under `$BASE_CACHE_DIR` (`$RUNTIME_DIR/cache` on Termux). The legacy `installed-rootfs/<name>/` path from older proot-distro versions is auto-migrated to the new layout on first `login` — so older documentation that cites the `installed-rootfs/<distro>` path is **historical**. [S16]
- Example distro workflows to document later (Phase 9): `proot-distro install ubuntu:24.04`, `proot-distro login ubuntu`, then `apt-get update && apt-get install ...` inside — apt here belongs to the container's Debian/Ubuntu, not to Termux. [S16]

Rule for drafting: any package-management sentence must specify the environment (native Termux vs the distro inside proot), per AGENTS.md §6.

## 4. Important Current-Development Signals

- **Package manager transition (native Termux only, in progress):** termux-tools supports both `apt` and `pacman` backends behind `pkg`, gated by `TERMUX_APP_PACKAGE_MANAGER`, which termux-app v0.119.0+ exports (verified `=apt` in v0.119.0-beta.3; for app < 0.119.0 the `login` script derives format via `TERMUX_MAIN_PACKAGE_FORMAT`). termux-packages `generate-bootstraps.sh` supports both `apt` and `pacman` bootstraps (`TERMUX_PACKAGE_MANAGERS=("apt" "pacman")`, pacman repo base `https://sync.termux-pacman.dev/main`) but contains a TODO: "Remove it when Termux app supports `pacman` bootstraps installation" — i.e. **the Termux app does not yet install pacman bootstraps**; apt remains the default. The termux-pacman org (community) publishes `bootstrap-*.pacman.android-7` archives and states its pacman support work "has been moved to the termux/termux-packages repository". **[version-sensitive; as of research date]** [S3, S4, S13, S14, S17 generate-bootstraps.sh]
- The user wiki (wiki.termux.com / wiki.termux.dev) carries a DEPRECATION NOTICE: contributions/accounts no longer accepted and pages "might be outdated"; migration to GitHub wiki pages with PR-based contribution is planned (issue termux/termux-packages#8327). The wiki is still live and partly stale (e.g. still lists `packages.termux.org` repo URLs). Cite it as deprecated/stale (tier C). [S1, S9, S18]
- Google Play builds are an experimental branch under a separate repo (termux-play-store); availability on Play was restored June 2024. [S1, S18]
- **[AUDIT]** Android 5/6: package (bootstrap) support, dropped in 2020, is being re-added in the v0.119 development series (betas ship `apt-android-5` variants). [S18 dev-wiki]
- **[AUDIT]** Storage permission model is changing with the v0.119 series: request moves from legacy write-storage to "All files access" (MANAGE_EXTERNAL_STORAGE). Materially affects `termux-setup-storage` documentation per app version. [S18 #4767, #4440]

## 5. Version-Sensitive Items Requiring a Date/Version Tag in the Bible

- Termux app version and supported-Android matrix (README: "Android >= 7"; wiki Main Page: "Android 5.0–12.0" — these conflict; the README reflects current reality, wiki is stale).
- Google Play branch features/limitations (restored on Play 2024-06; still experimental).
- Android 12+/phantom-process behavior (affects background sessions, servers, sshd; developer-option mitigation).
- `termux-setup-storage` on Android 14/15 behavior, required `termux-am`, and the legacy-permission vs "All files access" split between v0.118.x and v0.119.x (see §3.6).
- **Native package manager:** apt (default) vs the in-progress pacman backend; app does not yet install pacman bootstraps; `TERMUX_APP_PACKAGE_MANAGER` exported by v0.119.0+ (betas exist), `TERMUX_MAIN_PACKAGE_FORMAT` fallback by login script for < 0.119.0.
- apt version: 2.8.1+r2 shipped in termux-packages master at research time; termux-tools prepared for apt 3.0.0 (v1.46.0+).
- Repo host domain: `packages.termux.dev` / `packages-cf.termux.dev` are current (CF-cached first in default sources.list); older docs reference `packages.termux.org`. Verify at documentation time.
- `$LD_LIBRARY_PATH` pre-Android-7 vs `DT_RUNPATH` behavior (historical for Android 7+).
- proot-distro container layout: `containers/<name>/rootfs/` is current; `installed-rootfs/<name>/` is legacy (auto-migrated).
- Android 5/6: package support being re-added in v0.119 (betas have `apt-android-5` builds).

## 6. Commands that Need Live Verification (device or emulator)

Run on a real Termux (target ≥ Android 11) and record outputs:

- `echo $PREFIX; echo $HOME; echo $LD_LIBRARY_PATH` (check whether LD_LIBRARY_PATH still exported)
- `pkg --version` / `pkg help`; `pkg update`; `termux-info` (verify shown mirror + version fields)
- `ls -l $PREFIX/etc/apt` and `$PREFIX/etc/apt/sources.list.d/` (confirm `*.list` vs `*.sources` on current bootstrap; audit found `-repo` packages write `.list` files)
- `which termux-setup-package-manager` and its output; `echo $TERMUX_APP_PACKAGE_MANAGER`; `echo $TERMUX_MAIN_PACKAGE_FORMAT`
- `apt --version` (expect 2.8.x at research time; watch for 3.x)
- `termux-setup-storage` end-to-end on Android 13/14/15 (record permission dialog labels; check whether legacy "Storage" or "All files access" is requested — differentiates 0.118.x vs 0.119.x)
- `readelf -d $PREFIX/bin/<bin>` to confirm DT_RUNPATH (vs old LD_LIBRARY_PATH claim)
- List installed wrapper binaries in `$PREFIX/bin` (confirm the 9 wrappers df/getprop/logcat/ping/ping6/pm/settings/top only — audit concluded mount/umount are NOT installed)
- `ls $PREFIX/etc/apt/trusted.gpg.d/` (`termux-keyring` keys, plus `tur.gpg` if tur-repo installed)
- `proot-distro list` and `ls $TERMUX_PREFIX/var/lib/proot-distro/containers` (confirm current container layout vs legacy `installed-rootfs`); `proot-distro login alpine -- cat /etc/os-release` or similar to show guest package manager/rootfs independence

## 7. Claims Found in Lower-Quality Sources — Treated as Unverified

- Some wiki/mirror text states optional repo enabling also via `apt edit-sources`; primary guidance is `termux-change-repo`/`pkg`. (Keep `termux-change-repo` primary.)
- Third-party blog claims about `/data/user/0/com.termux/...` path on Android 12+ — not independently confirmed; treat as speculation until verified.
- Wikipedia claim "three repositories included in default bootstrap" is imprecise (bootstrap ships main only; x11/root are opt-in). Ignore for content.

## 8. Open Questions for Phase 2 Drafting

1. Should the Bible describe `pkg` only, or `apt` too, and how prominently should the pacman transition be covered? (Decision needed; affects cross-links and quick-reference.)
2. Where does glibc/TUR/root-repo content belong for the foundation reader? Propose one "repositories" page in 00-foundations or 01-termux with detailed package indexes in appendices.
6. Session behavior under app backgrounding/Doze — link to troubleshooting, not foundations.
7. **[AUDIT, new]** How far should proot-distro documentation go in the foundations volume vs Phase 9 (Advanced Termux)? Recommend: a one-page "native vs proot" boundary note in foundations, full proot-distro chapter in Phase 9.
8. **[AUDIT, new]** Whether the pacman transition should be presented as "current" once termux-app supports pacman bootstraps (track termux-app releases; TODO still present at research time).

Resolved during audit (2026-09-21): #3 mount/umount wrappers are built by Makefile rules but NOT in `bin_SCRIPTS`, hence not installed. #4 Android 15 permission labels partially documented from issues (legacy vs "All files access"; exact stock-UI labels still need a device screenshot). #5 keyring package is `termux-keyring` (official repos); `tur-repo` installs its own `tur.gpg`; glibc repo handled via glibc-repo/glibc-runner.

## 9. Suggested Drafting Structure (for the eventual chapter; not to be written now)

Foundations/Volume I material that Phase 2 should produce, mapped to sources:

1. What Termux is / how it differs from Linux (sandboxing, Bionic, single-user, non-FHS).
2. Installation: sources table, mixing-source warning, bootstrap explanation, min requirements, Android 12+ caveat.
3. Package management: `pkg` (primary), `apt` (advanced), limitations, cadence.
4. Repositories: main/x11/root/TUR/glibc + mirrors + change-repo + termux-info.
5. Filesystem: `$PREFIX`/`$HOME`, dir roles, tmp/var/run semantics, no-exec storage.
6. Storage: `termux-setup-storage`, symlink table, permission matrix by Android version.
7. Shell + environment: default shell, env vars, shebang handling, exec limitations.
8. Permissions: Android runtime permissions relevant to Termux, SAF.
9. Sessions: creation, switching, renaming, shortcuts; background limits.
10. Configuration: `termux.properties` table (from S5) + reload mechanics + colors/fonts.
11. Utility index (termux-tools + wrappers) with one-line purposes.
12. **[AUDIT]** "Native Termux vs proot": short boundary page/framing note in foundations (what `pkg`/`apt` apply to, and that distros inside proot-distro use their own package managers); full proot-distro treatment belongs to Phase 9.

## 10. Explicitly Unverified Facts (must not be written as fact without follow-up)

- Whether `termux-open`/`xdg-open` and `termux-open-url` behavior matches generic expectations in current version.
- Whether `pm`/`settings`/`getprop` wrappers are sufficient for typical Bible examples on non-rooted devices (they target `adb`-shell style access; device test needed).
- Bootstrap package list / first-run console output (need device capture).
- Exact default of `TERMUX_APP_PACKAGE_MANAGER`/`TERMUX_MAIN_PACKAGE_FORMAT` across **stable** app builds (0.119.0-beta.3 showed `TERMUX_APP_PACKAGE_MANAGER=apt`; stable v0.118.3 predates the variable — verify empirically after the v0.119 stable release).
- `cmd` binary in termux-tools: v1.45.0 release notes say `scripts/cmd` was replaced with a C implementation, yet it is absent from the master `Makefile.am` bin_SCRIPTS list — clarify how/where `cmd` is shipped.
- Whether a glibc-repo signing key setup differs from termux-keyring (device check of `trusted.gpg.d/` after `pkg install glibc-repo`).

Removed from this list during audit (2026-09-21) because verified from termux-tools sources: `termux-backup`/`termux-restore`/`termux-reset` scope and flags (see §3.8); keyring package name (`termux-keyring`, §3.3); glibc-repo maintainer boundary (§3.4).

## 11. Wiki Accessibility Notes (for reproducibility of further research)

- wiki.termux.com and wiki.termux.dev: blocked by Anubis 1.25 for automated fetches. Use:
  - GitHub wiki (termux-app, termux-packages) — partially truncated when fetched directly;
  - search-engine page caches (worked well, full article text);
  - mirror https://termux-wiki.vercel.app (community mirror of user wiki content);
  - official site termux.dev and termux.github.io when available.
- GitHub wiki raw content endpoint `https://raw.githubusercontent.com/wiki/<org>/<repo>/<Page>.md` should be tried for future page pulls (mirroring page shows it works for at least some pages).