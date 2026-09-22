# ADB Shell

`adb shell` gives you a command line **on the device**, from your computer. It
is the doorway to everything the
[Android Shell](../03-android/01-android-shell.md) can do.

## One-shot vs interactive

```
adb shell <command> <args>     # run ONE command, print output, exit
adb shell                       # interactive session; end with Ctrl+D or 'exit'
```

- One-shot form is what most examples use (`adb shell pm list packages`, `adb
  shell dumpsys battery`).
- Interactive form is useful for bidirectional/split-screen work and for
  keeping a session while transferring over it.
- Combine with host-pipe tools freely:
  `adb shell pm list packages | grep foo` pipes *on the host*; the device's
  stdout crosses the transport as a stream.

## What `adb shell` actually gives you

- The device shell is **mksh** at `/system/bin/sh` — the Android shell, not a
  Termux bash and not a proot shell. Tool set is toybox/remaining toolbox.
  See [The Android Shell](../03-android/01-android-shell.md).
- You run as **uid 2000, the `shell` user**, in the **`shell` SELinux
  domain** — not root and not an app. The one exception (`adb root`) exists
  only on debuggable builds; on production builds adbd answers "adbd cannot
  run as root in production builds". See [USB Debugging](02-usb-debugging.md).
- The session sets `HOME`, `HOSTNAME`, `LOGNAME`, `SHELL`, `USER` from the
  root/user entry, `TMPDIR=/data/local/tmp`, and `TERM` when a terminal type
  was requested **[version-sensitive]**.
- Consequences:
  - Scratch files and pushed binaries belong in **`/data/local/tmp`** (the
    shell user's writable temp), not under `/data/app`.
  - App-private paths (`/data/data/<pkg>`) are **not** readable by uid 2000
    for non-debuggable apps; `run-as` works only for debuggable ones. See
    [File Transfer](05-file-transfer.md).
  - `adb shell` is a good place to run the on-device commands in the
    `03-android/` chapters: `cmd`, `am`, `pm`, `settings`, `input`, `logcat`,
    `dumpsys`, `getprop`, `screencap`, `screenrecord`.

## Passing arguments correctly

Since adb passes arguments the way `ssh(1)` does (a change from older adb),
your local shell parses once and adb prefixes the command. A value containing
characters your shell would interpret can be escaped normally, but through a
whole `adb shell` just prefixing one layer is usually **not enough**. The
documented idiom for a value with spaces is **double quoting**:

```
adb shell setprop key "'two words'"
```

Without the extra quotes, the local shell normally splits the value. For
simple unflagged values, plain quoting also works on many shells, but the
doubled form is the portable one to teach.

## Raw binary output: `adb exec-out`

`adb shell` mangles binary data (it treats output as text, converting CR/LF,
and may add terminal-type bytes). For raw output use `adb exec-out`:

```
adb exec-out screencap -p > screen.png
```

Full capture workflow: [Capture Workflows](06-capture-workflows.md).

## Exploring the device

```
adb shell                        # interactive session
shell$ ls /system/bin            # the Android tool set
shell$ toybox                    # full service list of the multicall binary
shell$ getprop ro.build.version.release
shell$ wm size                   # display size (informative, device-side)
```

## Debugging loops

- **Logs**: `adb logcat` — for streams, one-shots (`-d`), buffers, and
  filtering see [logcat](../03-android/07-logcat.md).
- **Service state**: `adb shell dumpsys` — see [dumpsys](../03-android/08-dumpsys.md).
- **Screen taps/typing**: `adb shell input ...` —
  see [settings and input](../03-android/06-settings-and-input.md).

## References

- Official adb reference: developer.android.com/tools/adb (`adb shell`).
- AOSP `packages/modules/adb/daemon/shell_service.cpp`.
- Phase 4 research notes: `research/adb/00-adb-research.md` (§10, §12),
  `research/android/00-android-shell-research.md` (§5–§7).