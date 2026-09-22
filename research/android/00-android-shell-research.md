# Android Shell — Research Notes (Phase 4)

Status: research notes supporting Phase 4 "Android" (PLAN.md §32) and PLAN.md §8
(Android shell, Android properties, Android commands, screenshots, screen
recording). Not polished documentation. Distinguished from Bible chapters per
AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot (Ubuntu)
container exposing a live Termux rootfs at `/data/data/com.termux/files`, but
with **no real Android runtime** (no `/system/bin`, no real `/proc`/SELinux, no
device). Facts that require empirical on-device confirmation are marked
**[DEVICE]**. Everything version/Android-sensitive is tagged **[version-sensitive]**.

Audit note: AOSP sources below were read directly from
`android.googlesource.com` (main branch) on 2026-09-22. Claims from the earlier
subagent pass (2026-09-22) were re-verified where they could not be confirmed
and are flagged in §13/§14.

---

## 1. Scope

Phase 4 "Android" includes the Android shell / command-line, the Android
command ecosystem, and related workflows. This note covers:

- the Android shell (`/system/bin/sh`);
- the shell's user identity and SELinux privileges;
- the tool set (toolbox → toybox migration);
- what "adb shell" actually runs as;
- the boundary toward privileged access (`adb root`, Shizuku, Porter, rish) —
  **detail deferred to Phases 5/6**, captured here only to keep Phase 4
  statements accurate.

Related notes: `research/adb/00-adb-research.md` (ADB connection/transfer),
`research/adb/01-android-command-ecosystem-research.md` (`am`, `pm`, `cmd`,
`dumpsys`, `settings`, `input`, `logcat`, `getprop`, `screencap`,
`screenrecord`).

## 2. Source Inventory and Reliability Ranking

Ranking per AGENTS.md §3.2:

- A — Official project source/docs (AOSP, Termux).
- B — Official project wikis/release notes.
- C — Maintainer documentation.
- D — Community/forums (never an authority for technical claims).

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| S1 | AOSP `system/core/shell_and_utilities/README.md` (main) | A | googlesource `?format=TEXT` |
| S2 | AOSP `external/mksh/Android.bp` (main) | A | googlesource `?format=TEXT` |
| S3 | AOSP `system/core/libcutils/include/private/android_filesystem_config.h` (main) | A | googlesource `?format=TEXT` |
| S4 | AOSP `system/sepolicy/private/shell.te` (main) | A | googlesource `?format=TEXT` |
| S5 | AOSP `packages/modules/adb/daemon/restart_service.cpp` (main) | A | googlesource `?format=TEXT` |
| S6 | AOSP `system/core/toolbox/{getprop.cpp,setprop.cpp,start.cpp,getevent.c}` (main) | A | googlesource tree + `?format=TEXT` |
| S7 | AOSP `frameworks/base/cmds/{am,pm,settings,input}/*.sh` (main) | A | googlesource tree + `?format=TEXT` |
| S8 | developer.android.com/tools/adb (official adb page) | A | r.jina.ai proxy (full text saved) |
| S9 | termux-tools `scripts/Makefile.am`, `src/Makefile.am`, `src/cmd.c`, `scripts/su.in` (master) | A | raw.githubusercontent.com |
| S10 | termux-packages `packages/android-tools/build.sh` (master) | A | raw.githubusercontent.com |
| S11 | nmeum/android-tools `CMakeLists.txt`, `vendor/CMakeLists.txt` | A | raw.githubusercontent.com |
| S12 | AOSP `packages/modules/adb/daemon/shell_service.cpp` (main) | A | googlesource `?format=TEXT` |
| S13 | termux-packages `packages/tsu/build.sh` (master) | A | raw.githubusercontent.com |
| S14 | termux-packages `packages/sudo/build.sh` (master) | A | raw.githubusercontent.com |
| S15 | termux-packages PR #25129 (state) | A | api.github.com |

## 3. The Android Shell Binary

- `/system/bin/sh` is **mksh**; "Since IceCreamSandwich Android has used mksh as
  its shell. Before then it used ash (which actually remained unused in the tree
  up to and including KitKat)." [S1] — i.e. **mksh since Android 4.0 (ICS);
  ash before**.
- The `sh` binary is built from `external/mksh` as `cc_binary { name: "sh" }`
  [S2]. There is **no separate "sh wrapper"**: `/system/bin/sh` *is* the mksh
  binary. mksh also builds `sh.recovery` (recovery ramdisk) and `sh_vendor`
  (vendor partition) variants with their own defaults [S2].
  - System-build flags (current main) [S2]:
    - `MKSH_DEFAULT_PROFILEDIR="/system/etc"`, `MKSHRC_PATH="/system/etc/mkshrc"`;
    - `MKSH_DEFAULT_EXECSHELL="/system/bin/sh"`;
    - `MKSH_DEFAULT_TMPDIR="/data/local"` — mksh's *compile-time default* tmpdir
      when `TMPDIR` is unset; note `adb shell` sessions set `TMPDIR` explicitly
      (see §7), so the mksh default is secondary there.
  - `sh_vendor` instead uses `MKSHRC_PATH="/vendor/etc/mkshrc"`,
    `MKSH_DEFAULT_EXECSHELL="/vendor/bin/sh"`, and a
    `/vendor/bin:/vendor/xbin` defpath override [S2].
- **[version-sensitive]** — the section describes stock Android build behavior;
  OEM builds rarely replace `/system/bin/sh`, but all phrasings above are about
  stock builds, and the `cc_binary` packaging reflects current main.

## 4. Tool Set: toolbox → toybox

[S1] is the authoritative, version-timeline statement:

- Early Android: a very limited command-line in a single "toolbox" binary.
- "Since Marshmallow almost everything is supplied by toybox instead."
  (Marshmallow = Android 6.0.)
- Lollipop began the end of toolbox; the move to toybox started in
  Marshmallow.
- Exceptions still shipped from their own distributions: bzip2 tools (bzip2
  distribution), `awk` = "one true awk" added in Android P, `bc` = Gavin
  Howard's bc added in Android Q.
- The remaining Android 15 toolbox commands are only: `getevent getprop
  setprop start stop` [S1, Android 15 list] — consistent with
  `system/core/toolbox` today (getevent.c, getprop.cpp, setprop.cpp,
  start.cpp, modprobe.cpp, toolbox.c) [S6].
- `toybox` contains more commands than there are symlinks in `/system/bin`;
  run `toybox` on the device for the full list **[DEVICE]** [S1].
- Official adb docs: "Many of the shell commands are provided by
  [toybox](http://landley.net/toybox/)." Use `toybox --help` for toybox-wide
  help, and `adb shell ls /system/bin` to list available tools [S8].

## 5. Shell User Identity (uid/gid)

Verified from `android_filesystem_config.h` [S3] (comments in source):

| AID | value | comment |
|-----|-------|---------|
| AID_ROOT | 0 | traditional unix root user |
| AID_SYSTEM | 1000 | system server |
| AID_ADB | 1011 | "android debug bridge (adbd)" |
| AID_SHELL | 2000 | "**adb and debug shell user**" |
| AID_CACHE | 2001 | cache access |
| AID_APP / AID_APP_START | 10000 | first app user |

Implications (documented, version-sensitive to the table above):

- `adb shell` runs commands as **uid 2000 (shell user)**, not root, on a normal
  (user) build. The shell user's access is defined both by the uid and by
  SELinux (§6).
- `adbd` itself runs as **uid 1011 (AID_ADB)**.
- App uids start at 10000; regular apps are uid 10000+ and are NOT the shell
  user. This is why "adb shell" and "app context" have different access.

## 6. SELinux: the `shell` Domain

Verified from `system/sepolicy/private/shell.te` [S4] (main branch,
**[version-sensitive]**):

- `typeattribute shell coredomain, mlstrustedsubject;`
- Notable explicit permissions:
  - **input injection** via `uhid_device` (`allow shell uhid_device:chr_file
    rw_file_perms;`) — this is what lets the `input` command work from the
    shell.
  - **runs `app_process`** (`app_domain(shell)`) — this is the mechanism used by
    Shizuku/Porter-style tools to start a Java process from the shell (see §11;
    deferred detail to Phase 5/6).
  - reads tombstones (`tombstone_data_file` r/r_dir perms);
  - perfetto/atrace access (`traced_consumer` socket, debugfs tracing dirs);
  - `selinux_check_access(shell)` (CTS);
  - Binder access to selected services only (`storaged`, `statsd`, `gpuservice`
    are explicitly named; not general).
- SELinux policy is a **modern-main** view; individual rules change across
  Android versions, so any specific "shell can X" claim must carry the Android
  version.

## 7. `adb shell` and `adb root` — what privileges are involved

Verified from `packages/modules/adb/daemon/restart_service.cpp` [S5]
(documented per-command output strings):

- `adb root` (`restart_root_service`):
  - already root → "adbd is already running as root";
  - **non-debuggable build → "adbd cannot run as root in production builds"**;
  - otherwise sets property `service.adb.root=1` and restarts (re-execs)
    adbd as root.
- `adb unroot` (`restart_unroot_service`) reverses it (`service.adb.root=0`,
  "restarting adbd as non root").
- Consequence: **`adb root` only works on debuggable builds** (userdebug/eng,
  emulators, or otherwise debuggable). On a production/retail build `adb
  shell` stays as the shell user (uid 2000) [S5] **[DEVICE]/[version-sensitive]**.
- `adb shell` environment (**[version-sensitive]**, `shell_service.cpp` main,
  2026-09-22 [S12]): adbd's shell subprocess sets `HOME`, `HOSTNAME`,
  `LOGNAME`, `SHELL`, `USER` from the target uid's passwd entry,
  **`TMPDIR=/data/local/tmp`**, and `TERM` when a terminal type was requested.
  So `adb shell` overrides mksh's `/data/local` compile-time default (see §3).
- The interception of `pkg`/`settings`/`pm`/`df`/`top` etc. is a Termux-side
  concern — see §10.

## 8. On-Device Command Front-Ends: the `cmd` Dispatcher

Verified from AOSP `frameworks/base/cmds/` [S7] (main branch,
**[version-sensitive]** — this reflects recent Android):

- `input` → `input.sh`: `#!/system/bin/sh\ncmd input "$@"`
- `settings` → `settings.sh`: `#!/system/bin/sh\ncmd settings "$@"`
- `pm` → `pm.sh`: `#!/system/bin/sh\ncmd package "$@"`
- `am` → `am.sh`: `cmd activity "$@"` **except** that `am instrument` execs
  `app_process $base/bin com.android.commands.am.Am "$@"` (CLASSPATH
  `am.jar`).
- So on recent Android, `am`/`pm`/`settings`/`input` are thin shell scripts
  that delegate to `cmd` (usage `cmd <service> <args>`), a device-side
  dispatcher that resolves the named system service and invokes that service's
  shell-command handler [S7]. **Implementation note [version-sensitive]:** the
  `cmd` module location has moved in AOSP — there is no `cmds/cmd` module on
  current main — re-confirm the exact packaging at drafting. Full detail in
  `research/adb/01-android-command-ecosystem-research.md` §3.

## 9. Screenshot and Screen Recording on the Device Side

- `screencap` and `screenrecord` are on-device shell utilities run via
  `adb shell`; character-for-character examples (`adb shell screencap
  /sdcard/screen.png`; `adb exec-out screencap -p > screen.png`; `adb shell
  screenrecord /sdcard/demo.mp4`) are official [S8]. Constant-level detail
  (`screenrecord` 180-second default/max, 200 Mbps max bitrate, `--time-limit
  0` = no limit) is verified from AOSP `frameworks/av` in
  `research/adb/00-adb-research.md` §13.

## 10. Termux ↔ Android Shell Distinctions (Phase 4 relevant)

Already largely covered by Phase 2/3 notes; reminder list for drafting:

- Termux's interactive login shell is bash (`$PREFIX/bin/bash`); `/bin/sh` in
  Termux is a **bash** symlink — this is DIFFERENT from the device's mksh
  `/system/bin/sh`. Do not write "Termux's sh is mksh".
- Termux ships no root-acquisition tool; `termux-tools` `su` (`scripts/su.in`)
  only searches known su locations and errors if none exist — verified
  message: "No su program found on this device. Termux does not supply tools
  for rooting..." [S9]. Do not imply Termux can "run adb" devices or grant
  root.
- Termux root-helper packages (boundary toward Phases 5/6; all verified
  2026-09-22 against termux-packages master — **[version-sensitive]** because
  the packages change):
  - `tsu` (`packages/tsu`, cswl/tsu, v8.6.0-rev1) is **still packaged**; its
    build installs `tsu` and a `sudo` symlink → tsu [S13]. termux-packages
    PR #25129 ("rmpkg(main/tsu): replaced with agnostic-apollo sudo") was
    **closed without merging** (2025-09-24) — tsu was NOT removed.
  - `sudo` (`packages/sudo`, agnostic-apollo/sudo **v1.2.0**) declares
    `TERMUX_PKG_CONFLICTS="tsu"` + `TERMUX_PKG_REPLACES="tsu"` [S14] —
    installing it replaces the tsu-provided `sudo`. Auto-updated.
  - Like the `su` wrapper, neither tool grants Android superuser privileges by
    itself; they dispatch to a su binary the device supplies (rooted device /
    kernel su) or fail if none exists. Do not conflate them with Shizuku,
    Porter, or rish (AGENTS.md §6/§10); detail belongs to Phase 5/6 research.
- Termux's `cmd` **is a compiled C wrapper** (`src/cmd.c`, which in Aug 2024
  replaced an earlier shell-script wrapper) that forks and pumps
  stdin/stdout/stderr to the device `/system/bin/cmd`. It is NOT a Termux tool
  named "cmd"; it wraps the Android one [S9]. The specific rationale for the C
  rewrite is not documented in termux-tools sources — do not assert a reason at
  drafting without evidence.
- Termux also ships transparent wrappers for `df`, `getprop`, `logcat`,
  `ping`, `ping6`, `pm`, `settings`, `top` — these exec the Android
  `/system/bin` binaries with a cleaned `LD_LIBRARY_PATH` [S9]. So running
  `logcat`/`getprop`/`pm`/`settings` inside Termux actually executes the
  **Android system binaries**, with the same privileges they have on the
  device.
- Environment note: within the research proot container there is NO
  `/system/bin`, so none of the wrapper behavior could be executed here; it is
  verified by source, not by running **[DEVICE]**.

## 11. Boundary Toward Privileged Access (deferred to Phases 5/6)

Recorded here so Phase 4 drafting does not misstate them. Detailed research
will be done in Phase 5 (Shizuku/rish) and Phase 6 (Porter).

- The shell domain may run `app_process` (§6); tools such as Shizuku/Porter
  start a Java server process via `app_process` from an **adb shell** context.
- Shizuku v11.2.0+ official start-over-ADB command:
  `adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh`
  (startup must be repeated after reboot) — verified from the official Shizuku
  user manual (shizuku.rikka.app/guide/setup).
- The shell interface "rish" (Shizuku) and "porsh" (Porter) are programs that
  attach to that privileged daemon and execute `/system/bin/sh` with the
  daemon's privileges; they are NOT "root" by themselves and their behavior
  depends on the backend (ADB vs root). **Do not conflate** rish/porsh with
  root (AGENTS.md §6/§10).
- `adb root` ≠ app root ≠ Shizuku: each is a separate privilege layer (§7,
  and AGENTS.md §10).

## 12. Version-Sensitive / Device-Dependent Items (must carry a tag in the Bible)

- All SELinux `shell`-domain statements: main-branch view; change across
  Android versions. **§6**
- `am`/`pm`/`settings`/`input` delegating to `cmd`: recent-Android behavior
  (shell-script front-ends). **§8** **[version-sensitive]**
- toolbox remnants (`getevent getprop setprop start stop`): as of Android 15
  per [S1]; the rest toybox. **§4**
- `adb root`/`adb unroot` availability: debuggable builds only. **§7**
- mksh being `/system/bin/sh`: since Android 4.0; before was ash. **§3**
- `screencap`/`screenrecord` exact option sets and defaults: the constants are
  AOSP-main values; device/OEM and Android-version variation exists. **§9**
- uid table (§5) is the AOSP-main table; values (root 0, system 1000, adb
  1011, shell 2000, app 10000) are stable historically, but the table as a
  whole is version-locked.
- `adb shell` env (`TMPDIR=/data/local/tmp`, `HOME`/`USER`/etc. from passwd):
  main view, `shell_service.cpp`. **§7**
- Termux root-helper packages (`tsu` still packaged v8.6.0-rev1; `sudo` v1.2.0
  replaces/conflicts with tsu): verified status as of 2026-09-22; packages are
  auto-updated. **§10**

## 13. Unresolved / Missing Research

1. **RESOLVED 2026-09-22 (audit):** `adb shell` sessions DO set an explicit
   `TMPDIR=/data/local/tmp` (plus `HOME`, `USER`, `SHELL`, `LOGNAME`,
   `HOSTNAME`, and `TERM` when a terminal type is requested) — adbd
   `daemon/shell_service.cpp`, main branch → see §7. mksh's `/data/local`
   compile-time default only applies when `TMPDIR` is unset.
2. Exact toolbox→toybox symlink removal timeline (which Android version
   shipped which symlinks last) is not needed if the Bible cites [S1]
   ("since Marshmallow almost everything supplied by toybox"); fine-grained
   per-release lists live in [S1] and are linkable rather than copyable.
3. Whether `input`/`settings`/`pm`/`am` front-end delegation to `cmd` landed
   in a specific Android version is not pinned; only the "current main" state
   is verified. **[version-sensitive]**
4. OEM shell variations (custom `/system/bin/sh`, extra restrictions,
   removed toybox commands) unverified by design — device testing required.
5. `getprop` property-visibility restrictions for the shell/app context on
   Android 16+ are reported in community sources but NOT verified against an
   authoritative source; do not document until verified (AGENTS.md §2).

## 14. Conflicting / Outdated Sources Identified

- The subagent pass (2026-09-22, Android-shell subagent) reported shell
  uid/gid and SELinux facts that were truncated on delivery; everything reused
  here was re-verified directly from [S3]/[S4]/[S5] on 2026-09-22.
- Community pages sometimes claim "toolbox is still the default toolset"; the
  authoritative AOSP text [S1] says toybox since Marshmallow and is preferred.
- Some tutorials state `adb root` works "on any device with a rooted kernel";
  AOSP [S5] explicitly gates it on a debuggable build (`__android_log_is_debuggable`),
  plus device-level `ro.debuggable`. Prefer [S5].
- Community sources state "tsu has been removed from termux-packages"; PR
  #25129 was closed unmerged (2025-09-24) and `packages/tsu` remains on master
  (2026-09-22) [S15]. Prefer the package tree.

## 15. Source URL List

- https://android.googlesource.com/platform/system/core/+/refs/heads/main/shell_and_utilities/README.md
- https://android.googlesource.com/platform/external/mksh/+/refs/heads/main/Android.bp
- https://android.googlesource.com/platform/system/core/+/refs/heads/main/libcutils/include/private/android_filesystem_config.h
- https://android.googlesource.com/platform/system/sepolicy/+/refs/heads/main/private/shell.te
- https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/daemon/restart_service.cpp
- https://android.googlesource.com/platform/system/core/+/refs/heads/main/toolbox/
- https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/cmds/{am,pm,settings,input}/
- https://developer.android.com/tools/adb
- https://raw.githubusercontent.com/termux/termux-tools/master/{scripts/Makefile.am,src/Makefile.am,src/cmd.c,scripts/su.in}
- https://raw.githubusercontent.com/termux/termux-packages/master/packages/android-tools/build.sh
- https://raw.githubusercontent.com/nmeum/android-tools/master/{CMakeLists.txt,vendor/CMakeLists.txt}
- https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/daemon/shell_service.cpp
- https://raw.githubusercontent.com/termux/termux-packages/master/packages/tsu/build.sh
- https://raw.githubusercontent.com/termux/termux-packages/master/packages/sudo/build.sh
- https://github.com/termux/termux-packages/pull/25129

## 16. Research Audit Log

- 2026-09-22 Initial compile. All AOSP reads direct from googlesource main.
  Subagent-derived claims re-verified where possible; items that could not be
  re-verified are in §13. Audit still outstanding: cross-check §5 uid table and
  §6 SELinux rules against a release branch (e.g., android15-release) before
  drafting, and confirm §8 delegation version.
- 2026-09-22 Phase 4 RESEARCH AUDIT: resolved §13.1 (adb shell `TMPDIR` via
  `shell_service.cpp`); corrected §3 (mksh packaging — no "sh wrapper",
  `sh.recovery`/`sh_vendor` variants); qualified §8 (`cmd` implementation
  location no longer `cmds/cmd` on main); corrected the §10 `cmd`-wrapper
  rationale (no evidence for the previously stated reason) and added the
  verified tsu/sudo package facts; added S12–S15 sources. Still outstanding
  before drafting: cross-check §5 uid table / §6 SELinux against a release
  branch.