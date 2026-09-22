# Android

This section documents the **Android shell** and the **Android command
ecosystem** — the command-line world that lives on the device outside Termux.
It is the device-side counterpart to the
[ADB and Android Debugging](../04-adb/00-intro.md) section, which shows how a
computer drives this same device shell over USB or Wi-Fi.

- **[The Android Shell](01-android-shell.md)** — what `/system/bin/sh` is
  (mksh), the `toolbox`→`toybox` tool set, the `shell` user and its SELinux
  privileges, and how an `adb shell` session reaches it.
- **[Android Properties](02-android-properties.md)** — `getprop` / `setprop`
  and reading device and system information.
- **[Android Package Management](03-package-management.md)** — `pm`, `cmd
  package`, `adb install`, and how to inspect installed apps — versus Termux's
  `pkg`/`apt` and proot distributions' package managers.
- **[The `cmd` Dispatcher](04-command-dispatcher.md)** — the device-side
  `cmd <service>` dispatcher and the `am`/`pm`/`settings`/`input` front-ends
  that delegate to it.
- **[Activity Manager (`am`)](05-activity-manager.md)** — starting activities,
  services, broadcasts, instrumentation, and process control.
- **[`settings` and `input`](06-settings-and-input.md)** — reading and writing
  device settings, and injecting text, taps, key events, and swipes.
- **[`logcat`](07-logcat.md)** — reading Android's logs.
- **[`dumpsys`](08-dumpsys.md)** — dumping system-service state.
- **[`screencap` and `screenrecord`](09-screencap-and-screenrecord.md)** —
  device-side screenshots and screen recording.

## Which environment does this describe?

Everything here runs **on the Android device itself**, in one of two ways:

1. **Through Termux**, via the `termux-tools` wrappers that `exec` the real
   `/system/bin` binaries (`getprop`, `logcat`, `pm`, `settings`, `cmd`, ...).
   See [Termux Utilities](../01-termux/06-utilities.md).
2. **Through ADB**, from a computer: `adb shell pm list packages`, `adb
   logcat`, and so on. See [ADB shell](../04-adb/04-adb-shell.md).

These are the **Android system** programs — they operate on Android app
packages, Android settings, and the device's logs. They are **not** Termux
tools. Termux packages are managed with `pkg`/`apt`, and a Linux distribution
inside proot has its own package manager and tools. The three package systems
are documented separately in
[Android Package Management](03-package-management.md).

The shell you type these commands into also differs by environment:

| Environment | Shell binary | Notes |
|-------------|--------------|-------|
| Native Termux | bash (`$PREFIX/bin/bash`; `/bin/sh` → dash) | GNU tool set; see the [Shell Commands](../02-shell/00-intro.md) section |
| Android shell (device) | mksh (`/system/bin/sh`) | limited toybox tool set; see [The Android Shell](01-android-shell.md) |
| ADB shell | mksh, again | same `/system/bin/sh`, reached remotely; see [ADB shell](../04-adb/04-adb-shell.md) |
| proot distribution | the guest distribution's shell | the guest's own tools and package manager; see [Android Sandboxing](../00-foundations/02-android-sandboxing.md) |

## On accuracy and version sensitivity

The chapters are based on the audited Phase 4 research notes
(`research/android/00-android-shell-research.md`,
`research/adb/01-android-command-ecosystem-research.md`). The Android command
surface changes between Android releases — front-ends gain subcommands,
`toolbox` shrinks in favor of `toybox`, and output text varies by device and
OEM. Claims that depend on the Android version or on a real device are marked
`[version-sensitive]` or `[DEVICE]`. Where the exact Android version of a
change is not pinned (for example the point where `pm`/`am`/`settings`/`input`
became thin `cmd` scripts), the documentation says so instead of guessing.

If something conflicts with what your device or your `--help` output shows,
trust the device and update the documentation accordingly.

Privileged access beyond the `shell` user — `adb root`, Shizuku, rish, and
Porter — is a separate topic documented in later sections. They are separate
privileged-access systems: not Termux, and not interchangeable with root or
with each other. This section only notes the boundary where it is needed to
keep statements about the shell accurate.