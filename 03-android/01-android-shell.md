# The Android Shell

When you read about "the Android shell" you are reading about the command-line
environment that Android itself provides on the device: the shell binary at
`/system/bin/sh` and the tool set alongside it. It is what an
[ADB shell](../04-adb/04-adb-shell.md) session drops you into, and it is a
**different environment from Termux** and from a Linux distribution running
inside proot. This chapter explains what it is and how to keep the three
separate.

## What `/system/bin/sh` is

- On stock Android since **Android 4.0 (Ice Cream Sandwich)**, `/system/bin/sh`
  is **mksh** (the MirBSD Korn shell). Before that it was `ash`. No separate
  "wrapper" exists: `/system/bin/sh` *is* the mksh binary. **[version-sensitive]**
- The system shell reads `/system/etc/mkshrc` at startup, and mksh's
  compile-time default temporary directory is `/data/local` when `TMPDIR` is
  unset. A shell arriving over ADB overrides this — see [ADB Shell](../04-adb/04-adb-shell.md).
- OEM builds almost always keep `/system/bin/sh` as mksh, but an OEM **can**
  ship something else. Assume mksh on stock builds; if you need certainty,
  check the actual device. **[DEVICE]**

By contrast:

- **Native Termux** runs bash (`$PREFIX/bin/bash`) as its interactive login
  shell, and `/bin/sh` in Termux is a symlink to **dash** (from the essential
  `dash` package). It is **not** mksh and not bash. See
  [Shell and Environment](../00-foundations/05-shell-and-environment.md).
- A **proot distribution** (Ubuntu, Debian, ...) uses that distribution's own
  shell as `/bin/sh`. See
  [Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

Do not write scripts assuming that `/bin/sh` behaves identically in Termux, on
the device, and inside proot.

## The tool set: `toolbox` → `toybox`

Android's command-line tool set is provided by multicall binaries:

| Era | Provider | Notes |
|-----|----------|-------|
| Early Android | `toolbox` | a single limited binary |
| Lollipop–Marshmallow | transition to `toybox` | began in Lollipop |
| **Since Android 6.0 (Marshmallow)** | `toybox` | "almost everything is supplied by toybox" (**[version-sensitive]**, from AOSP's `shell_and_utilities` README) |

- A few tools are still exceptions: `bzip2` family ships from its own package,
  `awk` is the "one true awk" (added in Android P), and `bc` was added in
  Android Q.
- As of **Android 15**, the remaining `toolbox` commands are only `getevent
  getprop setprop start stop`. Everything else is toybox. **[version-sensitive]**
- Toybox ships more commands than there are symlinks in `/system/bin`. Run
  `toybox` on the device for the full list **[DEVICE]**; `toybox --help` for
  toybox-wide help; `adb shell ls /system/bin` lists the available tool names.

This is why "I have `ls` on Android" does not mean the GNU `ls` you know from a
desktop or from Termux. Options and output are toybox's, and a flag that GNU
coreutils supports may not exist here.

## Who the shell runs as

When ADB gives you a shell, the commands run as a dedicated Unix user. The
AOSP UID table (README from `android_filesystem_config.h`,
**[version-sensitive]**, historically stable) defines:

| AID | value | meaning |
|-----|-------|---------|
| AID_ROOT | 0 | traditional Unix root |
| AID_SYSTEM | 1000 | the system server |
| AID_ADB | 1011 | "android debug bridge (adbd)" — adbd itself runs as this |
| AID_SHELL | 2000 | **"adb and debug shell user"** — your `adb shell` commands run as this |
| AID_APP / AID_APP_START | 10000 | first application user |

Consequences:

- On a **normal (user) build**, `adb shell` runs as **uid 2000**, **not root**.
  Root is not available in that context; see [ADB shell](../04-adb/04-adb-shell.md)
  for the `adb root` boundary.
- Regular apps use uid 10000+, so the *shell* user is a different identity from
  an *app* user. If you type `id` in an ADB shell you will see the shell user;
  inside Termux you will see the Termux app's own uid. These are different
  sandboxes with different access.

## SELinux: the `shell` domain

Access is restricted not only by UID but by SELinux. On stock policy the shell
runs in the **`shell` SELinux domain**, which is a `coredomain` and an
`mlstrustedsubject` **[version-sensitive: this is a view of current AOSP
`shell.te`; individual rules change between Android versions]**. Explicitly
allowed behavior that matters to this section includes:

- **Input injection** (write permissions on `uhid_device`) — this is what lets
  the [`input` command](06-settings-and-input.md) work from the shell.
- **Running `app_process`** (`app_domain(shell)`) — the mechanism that
  privileged tools such as Shizuku and Porter use to start a Java server
  process from a shell context. The details belong to the later Shizuku, rish,
  and Porter sections; they are separate privileged-access systems, not
  interchangeable with root or each other.
- Reading tombstones (`tombstone_data_file`), and access to debugging
  infrastructure such as `perfetto`/`atrace`.
- Binder access to **only selected services** — `storaged`, `statsd`, and
  `gpuservice` are explicitly named in policy; it is not a general "talk to any
  system service" grant.

## What a shell arrives with

An ADB-provided shell sets `HOME`, `HOSTNAME`, `LOGNAME`, `SHELL`, and `USER`
from the target user's password entry, sets `TMPDIR=/data/local/tmp`, and sets
`TERM` when a terminal type was requested. **[version-sensitive: verified from
current AOSP `shell_service.cpp`; treat as current-main behavior]**

## Reading device system information

- `uname`, `id`, and the limited `/proc`/`/sys` views visible to the shell are
  the same basics as in the Termux environment — see
  [System Information](../02-shell/08-system-information.md) for how much an
  unprivileged context can see.
- `getprop` exposes Android system properties; see
  [Android Properties](02-android-properties.md).
- `dumpsys` reaches system services; see [dumpsys](08-dumpsys.md).

## Native Termux vs. Android shell vs. proot — reminder

| | Native Termux | Android shell / ADB shell | proot distribution |
|--|---------------|---------------------------|--------------------|
| Shell | bash (login); `/bin/sh` → dash | mksh (`/system/bin/sh`) | the guest's shell |
| Tool set | GNU tools under `$PREFIX` | toybox (+ few toolbox leftovers) | the guest's tools |
| User | the Termux app UID (`u0_a…`) | uid 2000 `shell` | whatever user you log in as (often root) |
| Package manager | `pkg` / `apt` | `pm`, `cmd package`, `adb install` | the guest's (`apt`, `apk`, `pacman`, `dnf`, ...) |
| Root | no | only on debuggable builds (`adb root`) | depends on the guest setup |

## Cross-references

- Reaching this shell from a computer: [ADB Shell](../04-adb/04-adb-shell.md)
- What `pm`/`cmd`/`settings` are inside the shell: [The `cmd` Dispatcher](04-command-dispatcher.md)
- Termux's wrappers that exec the same Android binaries: [Termux Utilities](../01-termux/06-utilities.md)
- Environment distinctions in general: [Android Sandboxing](../00-foundations/02-android-sandboxing.md)
- Privileged access beyond the shell user is deferred to the later Shizuku,
  rish, and Porter sections (separate privileged-access systems, not
  interchangeable with root or each other).

## References

- AOSP `system/core/shell_and_utilities/README.md` — the toolbox→toybox story
  and the mksh history.
- AOSP `external/mksh/Android.bp` — how the `sh` binary is built.
- AOSP `system/core/libcutils/include/private/android_filesystem_config.h` —
  the AID table.
- AOSP `system/sepolicy/private/shell.te` — the `shell` SELinux domain.
- Phase 4 research notes: `research/android/00-android-shell-research.md`
  (§3–§7, §10–§11).