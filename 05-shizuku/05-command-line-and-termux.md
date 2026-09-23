# Command-Line Use and Termux

Shizuku itself is a Java server. Its **command-line face is `rish`** — a client
shell program that connects to the Shizuku (or Sui) daemon so you can run
shell commands with the daemon's identity from a terminal app such as Termux.
Full rish documentation is the
[rish section](../06-rish/00-intro.md); this chapter covers the Shizuku side,
the setup a Termux user performs, and what to expect.

## How the command line is provided

- The manager app has a home-card **"Use Shizuku in terminal apps"** that opens
  a tutorial.
- The tutorial **exports two files** from inside the manager APK:
  - **`rish`** — a small `/system/bin/sh` script (the client);
  - **`rish_shizuku.dex`** — the loader dex (Shizuku API + shell glue).
- Export uses **SAF** (the Android storage-access framework); existing
  same-named files in the chosen folder are **deleted first** — do not point it
  at a folder whose `rish`/`rish_shizuku.dex` you still need.

## Setting it up in Termux (the documented tutorial flow)

1. **Export** the two files with the tutorial.
2. **Edit `rish`**, replacing the `PKG` placeholder with your terminal app's
   application id. The tutorial itself uses **Termux / `com.termux`** as the
   concrete example:
   ```
   PKG -> com.termux
   ```
   The alternative to editing the file is setting the environment variable at
   call time:
   ```
   export RISH_APPLICATION_ID=com.termux
   ```
3. **Move the files** to a directory Termux can access and add to `PATH`:
   ```
   mkdir -p ~/rish
   mv rish rish_shizuku.dex ~/rish/
   chmod +x ~/rish/rish
   PATH="$HOME/rish:$PATH"
   export PATH
   rish
   ```
   (Any directory on Termux's `PATH` works; keep the files **out of
   `~/storage`** — shared storage is `noexec` for Termux, so the script cannot
   execute there (see [Storage Setup](../01-termux/04-storage-setup.md)), and on
   Android 14+ the writable-dex rule below also applies.)

Android 14+ (API 34) note **[version-sensitive]**: `app_process` will not load
a **writable** dex. The `rish` script attempts `chmod 400` on the dex; if the
file turns out still writable (for example on `/sdcard`), the script prints
guidance to put it in the terminal app's private directory —
`/data/data/<package>` — and exits. In Termux, place the files somewhere
inside the Termux **app-private** tree (e.g. `~/rish` under
`/data/data/com.termux/files/home`) **not** under `~/storage`. The Shizuku
v13.5.2 release note says the same thing: on Android 14+, rish files on
`/sdcard` will not work; copy them to the terminal app's data folder.

MIUI caveat **[OEM]**: the tutorial notes that SAF export can be broken on
MIUI; the fallback is extracting the files from the APK or downloading them
from the GitHub release.

## What the exported `rish` script does

Verified from the shipped script:

```
/system/bin/app_process -Djava.class.path=<rish_shizuku.dex> /system/bin \
    --nice-name=rish rikka.shizuku.shell.ShizukuShellLoader "$@"
```

- The loader asks the manager for the daemon binder (broadcast
  `rikka.shizuku.intent.action.REQUEST_BINDER`, extra `data` carrying a
  receiver binder).
- On Android 8.0/8.1 it falls back to a chooser activity ("Request binder from
  Shizuku"). **[version-sensitive]**
- There is a **5-second timeout**: if no binder arrives the loader prints
  "Request timeout. The connection between the current app (...) and Shizuku
  app may be blocked by your system" and tells you to disable battery
  optimization for both the terminal app and Shizuku.
- It then loads the manager's `Shell` class from the **manager APK** and runs
  the session. If that class cannot be found it prints "Make sure you have
  Shizuku v12.0.0 or above installed".

## Requirements for a working session

- The **Shizuku server must be running** (see
  [Activation and Startup](03-activation-and-startup.md)); rish has no server
  of its own.
- **Server version ≥ 12** (current servers are 13.x). `Shell` checks
  `Shizuku.getVersion() >= 12` and prints
  "Rish requires server 12 (running <n>)" otherwise.
- The terminal app must be granted the Shizuku permission (see
  [Permissions](04-permissions.md)), or the request flow runs on first use.

## Environment expectations inside rish

- Commands run as the **server's** identity (adb uid 2000 or root), not as
  Termux's uid.
- The remote shell the script talks to is **Android's `/system/bin/sh`**, not
  a Termux bash — see
  [The Android Shell](../03-android/01-android-shell.md). Termux-only tools and
  `$PATH` are generally not visible across the boundary unless explicitly
  preserved (see
  [rish usage and environment](../06-rish/03-usage-and-command-execution.md) and
  `RISH_PRESERVE_ENV`).

## Quick checks

- `rish` with nothing else → interactive session (PTY).
- `rish -c 'ls /data/user/0'` → run one command and exit.
- First failures are usually: server not running, battery optimization,
  missing/`PKG`-placeholder application id, or dex on a writable location on
  Android 14+.

## References

- Source: `manager/src/main/assets/rish`,
  `shell/.../ShizukuShellLoader.java`, `manager/.../Shell.java`,
  tutorial strings (`ShellTutorialActivity.kt`, `strings/strings.xml`).
- Phase 5 research notes: `research/shizuku/00-shizuku-research.md` (§7),
  `research/rish/00-rish-research.md` (§4, §5, §9).