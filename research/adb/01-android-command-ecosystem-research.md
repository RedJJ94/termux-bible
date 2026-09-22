# Android Command Ecosystem — Research Notes (Phase 4)

Status: research notes supporting Phase 4 "Android" and "ADB and Android
Debugging" (PLAN.md §32) and PLAN.md §8 (Android properties, `am`, `cmd`,
`settings`, `input`, `screencap`, `screenrecord`, Android package management,
file transfer, logcat, dumpsys). Not polished documentation. Distinguished from
Bible chapters per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with no live Android runtime; **no command here was executed
on a real device**. Device-run outputs are **[DEVICE]**; version/Android
dependencies are **[version-sensitive]**.

Audit note: command descriptions for `am`/`pm`/`dpm` are taken from the
official developer.android.com adb page (saved full text, 631 lines). The
`cmd`-delegation behavior of `am`/`pm`/`settings`/`input` was verified directly
from AOSP `frameworks/base/cmds/*` on the main branch (2026-09-22), and is a
**recent-Android** behavior. `logcat` and `dumpsys` sections follow the
official tool pages (fetched 2026-09-22).

---

## 1. Scope

On-device command tools reachable via `adb shell` and (for many) inside
Termux through termux-tools wrappers:

- `cmd` dispatcher and the shell-script front-ends (`am`, `pm`, `settings`,
  `input`);
- `dumpsys`;
- `logcat`;
- `getprop`/`setprop` (Android properties);
- Android package management (`pm`, `adb install`);
- file transfer (`push`/`pull`/`forward`, storage paths);
- screenshots/recording device-side (`screencap`, `screenrecord`).

## 2. Source Inventory

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| C1 | developer.android.com/tools/adb (full text) | A | r.jina.ai (saved) |
| C2 | developer.android.com/tools/logcat (full text) | A | r.jina.ai |
| C3 | developer.android.com/tools/dumpsys (full text) | A | r.jina.ai |
| C4 | AOSP `frameworks/base/cmds/{am,pm,settings,input}/*.sh` (main); `services/core/java/com/android/server/input/InputShellCommand.java` (main) | A | googlesource tree/`?format=TEXT` |
| C5 | AOSP `system/core/toolbox/getprop.cpp` (main) | A | googlesource `?format=TEXT` |
| C6 | termux-tools `scripts/Makefile.am`, `src/Makefile.am`, `src/cmd.c` | A | raw.githubusercontent.com |
| C7 | AOSP `frameworks/av/cmds/screenrecord/screenrecord.cpp` (main) | A | googlesource `?format=TEXT` |
| C8 | AOSP `system/sepolicy/private/shell.te` (input-injection backing) | A | googlesource `?format=TEXT` |

## 3. `cmd` — the device-side command dispatcher

- `/system/bin/cmd` runs a service shell command on the device as
  `cmd <service> <args>`, resolving the named system service and invoking its
  shell-command handler; it is the modern dispatcher behind most admin tools.
- **Implementation note [version-sensitive]:** `cmd` historically shipped as a
  script launching `com.android.commands.cmd.Cmd` via `app_process`, but its
  module moved — there is **no `cmds/cmd` module on current AOSP main**;
  re-confirm the exact packaging at drafting.
- On **current Android main**, the familiar front-ends are thin shell scripts
  that delegate to `cmd` [C4] — **[version-sensitive]**:
  - `input` → `input.sh` → `cmd input "$@"`;
  - `settings` → `settings.sh` → `cmd settings "$@"`;
  - `pm` → `pm.sh` → `cmd package "$@"`;
  - `am` → `am.sh` → `cmd activity "$@"`, **except** `am instrument` execs
    `app_process $base/bin com.android.commands.am.Am` with `am.jar` on the
    classpath.
- Official adb-page examples of `cmd` usage [C1]:
  - `adb shell cmd package dump-profiles package` (ART profile/execution
    profiles, Android 7.0+, root-fs access needed to retrieve the file);
  - `adb shell cmd testharness enable` (device-reset harness, Android 10+;
    preserves RSA debugging key across factory reset; disables lock screen,
    emergency alerts, auto-sync, auto-updates).
- Termux ships `cmd` as a **compiled C wrapper** that forks/pumps stdio to the
  device `cmd` [C6] — Termux itself does not provide a "cmd" tool of its own;
  it bridges the Android binary. Details in
  `research/android/00-android-shell-research.md` §10.

## 4. `am` (Activity Manager)

Official `am` command set (adb page, Table 1) [C1] — **[version-sensitive]**
(new subcommands appear across releases):

- `start [opts] intent` (+ `-D` debug, `-W`, `--start-profiler`, `-P`,
  `-R`, `-S`, `--opengl-trace`, `--user`, `--debug-link`
  (Android 17+));
- `startservice`, `force-stop package`, `kill [-u...]`/`--user`,
  `kill-all`, `broadcast`, `instrument [-w ...]`,
  `profile start/stop`, `dumpheap [--user] [-b] [-n] process file` (bitmaps
  API 35+), `dumpbitmaps` (API 36+),
  `set-debug-app`/`clear-debug-app`, `monitor [--gdb]`,
  `screen-compat`, `display-size [reset|WIDTHxHEIGHT]`,
  `display-density DPI`, `to-uri`/`to-intent-uri`, and
  `memory-limiter` (Android 17+ subcommands `ignore`, `manual`, `status`).
- Intent specification uses `-a action -d data -t mime -c category -n
  component -f flags` and typed extras (`-e/--es`, `--ez`, `--ei`, `--el`,
  `--ef`, `--eu`, `--ecn`, `--eia`; `--grant-read-uri-permission`, etc.).
- Official example: `adb shell am start -a android.intent.action.VIEW`.

## 5. `pm` (Package Manager)

Official `pm` command set (adb page, Table 2) [C1]:

- Queries: `list packages [-f] [-d|-e] [-s|-3] [-i] [-u] [--user] [filter]`,
  `list permission-groups`, `list permissions`, `list instrumentation`,
  `list features`, `list libraries`, `list users`, `path package`.
- Install/remove: `install [-r] [-t] [-i pkg] [--user] [--install-location
  0|1|2] [-f] [-d] [-g] [--fastdeploy|--incremental|--wait]`; `uninstall
  [-k] [--user] [--versionCode]`.
- App state: `clear`, `enable`/`disable`/`disable-user`, `grant`/`revoke`
  (permission grant notes: Android 6.0+ any manifest permission; on ≤5.1 only
  optional permissions), `set-*`/`get-install-location`
  (debug-only warning), `set-permission-enforced`, `trim-caches`,
  `create-user`/`remove-user`/`get-max-users`.
- App links: `get-app-links`, `reset-app-links`, `verify-app-links`,
  `set-app-links`, `set-app-links-user-selection`,
  `set-app-links-allowed`, `get-app-link-owners`.
- Example documented: `adb shell pm uninstall com.example.MyApp`.
- Official adb page also documents `adb install MULTIPLE` for splits and the
  `-t` requirement for test APKs [C1].

## 6. `settings` (System/Global/Secure namespace)

- Front-end `settings` → `cmd settings` on current main [C4] (a device-side
  service shell command; not covered verbatim on developer.android.com).
- Core namespaces: `system`, `global`, `secure`; core verbs: `list`, `get`,
  `put`, `delete`, `reset` (`set-system` exists on some builds). **Exact flags
  are **[version-sensitive]** and were only partially verified from source
  here** — take the authoritative surface from the target device via
  `adb shell settings help` (**[DEVICE]**) or the current AOSP
  `SettingsShellCommand` at drafting, not from third-party listings.
- Termux ships a `settings` wrapper that execs the device binary [C6].

## 7. `input` (input injection)

- Front-end `input` → `cmd input "$@"` on current main [C4].
- Subcommands **verified 2026-09-22** from the current implementation
  `.../com/android/server/input/InputShellCommand.java` (main): `text`,
  `keyevent`, `tap`, `swipe`, `press`, `roll`, `motionevent`,
  `keycombination`; help via `adb shell input help`. **[version-sensitive]**.
- Backing: the `shell` SELinux domain is explicitly allowed `uhid_device`
  rw_file_perms (input injection) [C8]; input injection works from `adb
  shell`/`shell` user without root on stock policy.

## 8. `getprop` / `setprop` (Android system properties)

- Both are **toolbox** commands today (system/core/toolbox: getprop.cpp,
  setprop.cpp) [C5]; Android 15 still lists `getprop setprop` under toolbox
  (research/android note §4).
- `getprop` usage: `getprop [-TZ] [NAME [DEFAULT]]` — no args lists
  properties, `getprop NAME`, `getprop NAME DEFAULT` [C5].
- Quoting caution from adb docs: `adb shell setprop key 'two words'` fails at
  the local shell; use `adb shell setprop key "'two words'"` (ssh-like double
  quoting) [C1].
- Termux ships a `getprop` wrapper (execs device binary) [C6].
- **Unresolved**: whether Android 16+ restricts property visibility for the
  shell/app context is only community-reported — NOT verified from an
  authoritative source; do not document as fact until verified (AGENTS.md §2).

## 9. `logcat` (Android logging)

From the official logcat page [C2] (all verified):

- `logcat` dumps system/app logs; logging system = structured **circular
  buffers in `logd`**: `main` (apps), `system` (OS), `crash`; each entry has
  priority/tag/message.
- Native interface `liblog` `<android/log.h>`; all language loggers call
  `__android_log_write`; default writer `__android_log_logd_logger` (socket to
  logd); API 30+ allows `__android_set_log_writer`.
- Four filtering levels: compile-time (e.g. ProGuard), system-property
  (`log.tag.<Tag>`, `persist.log.tag.<Tag>`, `log.tag`, `persist.log.tag` —
  value = first letter `V D I W E S`), app min-priority (`__android_log_set_minimum_priority`,
  default INFO), display filters.
- Usage: `[adb] shell logcat [options] [filter-spec]`; `adb logcat` =
  `adb shell logcat`; `adb logcat --help`; **many options are root-only**
  (tool for both OS and app devs).
- Filter expressions `tag:priority ...`; allowlist idiom
  `adb logcat ActivityManager:I MyApp:D *:S`; `*:W` = warn+. Quote `*` in
  shells that glob (e.g. Markdown/bash). Env var `ANDROID_LOG_TAGS` sets a
  default filter on the host (not exported to device/emulator).
- Output formats (`-v`): `brief`, `long`, `process`, `raw`, `tag`,
  `thread`, `threadtime` (default), `time`.
- Format modifiers: `color`, `descriptive`, `epoch`, `monotonic`,
  `printable`, `uid`, `usec`, `UTC`, `year`, `zone`.
- Buffers (`-b`): `radio`, `events`, `main`, `system`, `crash`, `all`,
  `default`(main+system+crash); repeatable/CSV (`-b main,radio,events`).
- Priorities: V D I W E F S (Fatal; S = silent/disable).

## 10. `dumpsys` (system service dumps)

From the official dumpsys page [C3] (verified):

- Runs on-device; invoke via adb: `adb shell dumpsys [-t timeout] [--help |
  -l | --skip services | service [arguments] | -c | -h]`; default timeout
  10s.
- `-l` lists service names; `--skip` excludes services; `service` name +
  optional args; `-h` per-service help; `-c` machine-friendly output.
- Documented service workflows (official examples):
  - `dumpsys input` (event hub/input reader/input dispatcher state —
    verbose, version-varying);
  - `dumpsys gfxinfo package-name`, `gfxinfo ... framestats` (UI perf);
  - `dumpsys netstats [detail]` (network usage; requires `dumpsys package
    pkg | grep userId` to map UIDs);
  - `dumpsys batterystats ...` and `--checkin` CSV (`-h` for options);
  - `dumpsys procstats --hours 3` (PSS/USS/RSS over time);
  - `dumpsys meminfo [-d] package|pid` (+`-h`) (memory breakdown:
    PSS, Private Dirty/Clean, Dalvik/ART details).
- Output "varies depending on the version of Android" — tag accordingly.
- Use under less-privileged context: much `dumpsys` detail is reduced when
  run as non-root; SELinux `shell` domain explicitly may `binder_call` to
  `storaged`/`statsd`/`gpuservice` (research/android note §6).

## 11. `screencap` / `screenrecord` (device side)

- `screencap`: `adb shell screencap /sdcard/screen.png`; raw PNG to stdout
  with `-p`, capture to host file via
  `adb exec-out screencap -p > screen.png` [C1].
- `screenrecord`: MPEG-4; Android 4.4+; default & max 180 s; options
  `--size/--bit-rate/--time-limit/--rotate/--verbose`; no audio; not Wear OS;
  rotation unsupported; AOSP main allows `--time-limit 0` = unlimited and caps
  bitrate at 200 Mbps [C1][C7]. Full detail + version notes in
  `research/adb/00-adb-research.md` §13.

## 12. Android Package Management (device side) vs Termux

- Android-side package management happens through **system package manager**
  (`pm`, `cmd package`, `adb install/install-multiple`) — covered in §5/§3
  [C1]. `pm`/`adb install` interacts with the *system* package manager; it is
  unrelated to Termux package management (`pkg`/`apt` — Phase 2,
  `research/termux/00-foundations-research.md`) or proot distributions
  (`/data/data/com.termux/files/usr` + proot-distro — Phase 2/3).
- Distinction for the Bible: `pkg install android-tools` gives you adb; `pm`
  on the device manages installed Android APKs; running `pm` inside Termux
  executes the **device** pm via the termux wrapper [C6].

## 13. File Transfer and Storage Paths

- `adb push`/`pull` (arbitrary files/dirs; Android 4.x+ usage in docs),
  `adb forward tcp:hostport tcp:deviceport` [C1].
- Paths (PLAN.md §7 / AGENTS.md §7): shell-user readable areas include
  `/sdcard` (FUSE media storage) — push/pull from adb into `/sdcard` works;
  app-private `/data/data/<pkg>` requires the calling context (shell for
  debuggable/`run-as`, root otherwise); document that `adb push` to
  `/data/data/...` generally fails for non-debuggable apps from shell.
  (Forwarding + `exec-out` for raw binary streams.)
  **Note:** the permission statements in this bullet are inferences from the
  Android data model, not from a fetched source — confirm on-device
  **[DEVICE]** before drafting.
- `adb pull /data/misc/profman/package.prof.txt` example requires root-fs
  access (docs note) [C1].

## 14. Version-Sensitive / Device-Dependent Items (must carry a tag in the Bible)

- `cmd` delegation of `am`/`pm`/`settings`/`input` — current-main behavior;
  pin the Android version where the final scripts appeared; `cmd`'s own module
  location changed on main (no `cmds/cmd`). §3/§6/§7
- `am` extras like `dumpbitmaps` (API 36+), `--debug-link` and
  `memory-limiter` (Android 17+), `dumpheap -b` (API 35+). §4
- `pm` permission-grant semantics: Android 6.0+ vs ≤5.1. §5
- `testharness` reset: Android 10+. §3
- `dumpsys` output varies per Android version; some services/meminfo sections
  differ between Dalvik (old) and ART. §10
- `screenrecord` limits; time-limit-0 semantics. §11
- `getprop`/toolbox status. §8
- Many `logcat` options are root-only; option set varies by OS version. §9

## 15. Unresolved / Missing Research

1. `settings` full option surface: still not verified verbatim from source
   (as of 2026-09-22). The `input` side is now verified from
   `InputShellCommand.java` (§7), but `settings` must be captured via
   `adb shell settings help` **[DEVICE]** or the current AOSP
   `SettingsShellCommand` at drafting. (The old
   `frameworks/base/cmds/{settings,input}` Java sources no longer exist on
   main.)
2. Android 16+ `getprop`/property-visibility restriction for shell/apps:
   community-reported only; unverified — do not write as fact.
3. Exact Android version at which `am`/`pm`/`settings`/`input` became
   `cmd`-delegating shell scripts (only "current main" is pinned).
4. Whether `cmd` is available on all devices/OEM builds (AOSP provides it;
   some OEM builds may restrict `cmd windows`/`cmd activity` — **[DEVICE]**).
5. `dumpsys battery` and service list is version/device dependent; do not
   promise a canonical list in the Bible; use `-l` on device.

## 16. Source URL List

- https://developer.android.com/tools/adb
- https://developer.android.com/tools/logcat
- https://developer.android.com/tools/dumpsys
- https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/cmds/{am,pm,settings,input}/
- https://android.googlesource.com/platform/system/core/+/refs/heads/main/toolbox/getprop.cpp
- https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/cmds/screenrecord/screenrecord.cpp
- https://android.googlesource.com/platform/system/sepolicy/+/refs/heads/main/private/shell.te
- https://raw.githubusercontent.com/termux/termux-tools/master/scripts/Makefile.am

## 17. Research Audit Log

- 2026-09-22 Initial compile. `am`/`pm`/`dpm` tables transcribed from the
  official adb page; `logcat`/`dumpsys` from their official pages; front-end
  delegation verified from AOSP main. Audit item: cross-check the "cmd
  delegation" change with the next Android release notes, and verify
  §15.2/15.3 per AGENTS.md before drafting.
- 2026-09-22 Phase 4 RESEARCH AUDIT: verified the `input` subcommands from
  `InputShellCommand.java` (main); qualified §6 `settings` (removed the
  unverified `put --reset`/`set-system` specifics, kept core verbs as
  [DEVICE]-verify); fixed the `--opengltrace`→`--opengl-trace` typo (§4); noted
  the `cmd` module relocation (§3); updated §15.1.