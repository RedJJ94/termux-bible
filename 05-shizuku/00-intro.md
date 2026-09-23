# Shizuku

Shizuku is a **privileged-access layer** for Android. In its own words it lets
normal apps "use system APIs directly with adb/root privileges" through a Java
process started with `app_process` — without the app being system-signed and
without a per-command `su` prompt. It is *not* root by itself, *not* a Termux
tool, and *not* interchangeable with ADB, root, rish, or Porter. What Shizuku
can do depends entirely on **who started it** (the adb `shell` user or root).

This section covers Shizuku itself:

- **[What Shizuku Is](01-what-is-shizuku.md)** — the manager app, the
  `shizuku_server` process, the binder delivery model, and the identities
  Shizuku can run as.
- **[Installation](02-installation.md)** — where the manager app comes from,
  the Android version requirement, and why there is **no** Termux package to
  install.
- **[Activation and Startup](03-activation-and-startup.md)** — the three
  startup methods (root, wireless debugging, ADB), and the version conflict
  between the current native starter and the older `start.sh` flow.
- **[Permissions and Application Integration](04-permissions.md)** — the
  `API_V23` runtime permission, how apps are granted access, and the ADB-vs-root
  privilege boundary.
- **[Command-Line Use and Termux](05-command-line-and-termux.md)** — how the
  command-line face of Shizuku is actually [rish](../06-rish/00-intro.md), and
  how Termux users set it up.
- **[Limitations and Troubleshooting](06-limitations-and-troubleshooting.md)** —
  what Shizuku cannot do, OEM breakage, and how to diagnose startup failures.

## Environment distinction to keep in mind

Shizuku adds a **server process** to the device that is separate from every
other execution environment this Bible covers:

| Layer | What it is |
|-------|-----------|
| Native Termux | the app; `$PREFIX` binary environment, normal app UID |
| Android shell | `/system/bin/sh` (mksh) on the device |
| ADB shell | the same `/system/bin/sh` reached from a computer, uid 2000 |
| Shizuku | a privileged **server daemon** (`shizuku_server`) running as uid 2000 or 0 |
| rish | a shell *client* that connects to that daemon |

Commands Shizuku-based apps run execute **with the identity of the server**,
not with the identity of the requesting app. General environment rules are in
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Prerequisites and security at a glance

- **Android 6.0+** is required for Shizuku and Sui. **[version-sensitive]**
- On an **unrooted** device Shizuku must be (re)started **after every boot**;
  there is no permanently-on rootless mode.
- The privilege level is set by the **launch method**: wireless/ADB startup
  gives the adb `shell` permission set; root startup gives root.
- Shizuku grants apps the ability to act **as that identity**. Only install the
  app from the official sources listed in
  [Installation](02-installation.md), and revoke authorizations / stop the
  service when you no longer need it.

## Cross-references

- The shell identity Shizuku usually runs as: [ADB Shell](../04-adb/04-adb-shell.md)
- Enabling the prerequisites: [USB Debugging](../04-adb/02-usb-debugging.md),
  [Wireless Debugging](../04-adb/03-wireless-debugging.md)
- The `app_process` mechanism: [The Android Shell](../03-android/01-android-shell.md)
- The command-line shell that rides on Shizuku: [rish](../06-rish/00-intro.md)
- Environment rules: [Android Sandboxing](../00-foundations/02-android-sandboxing.md)
- Shizuku vs root vs ADB vs rish vs Porter: distinct privileged-access systems,
  not interchangeable (AGENTS.md §10).