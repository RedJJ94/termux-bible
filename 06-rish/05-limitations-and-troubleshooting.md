# Limitations and Troubleshooting

## Limitations

- **rish is a client, not a privilege source.** Its privileges are those of
  the daemon it connects to (uid 2000 or 0). On an unrooted device with an ADB
  launcher, it is **not root**.
- **Only Shizuku and Sui backends are documented.** Porter compatibility is
  **unverified** — see
  [Relationship to Privileged Services and Permissions](04-relationship-and-permissions.md).
- **Server version ≥ 12 required.** An old Shizuku server refuses the session
  ("Rish requires server 12 (running <n>)").
- **The remote shell is Android's `/system/bin/sh`**, not a Termux shell.
  Termux-only tools and paths are unavailable unless the env is preserved (root
  backend with `RISH_PRESERVE_ENV=1`, or binaries placed on the Android
  shell's `PATH`). See [Usage](03-usage-and-command-execution.md).
- **Android 14+ dex rule**: rish files under `/sdcard` (writable dex) will not
  work; they must be in the terminal app's private directory.
  **[version-sensitive]**
- **No Termux package.** Setup is the manual export/edit flow
  (there is no installable `rish`/`shizuku`/`sui` Termux package; checked
  2026-09-22). **[version-sensitive]**
- **Device-dependent behavior** is common: battery optimization, OEM quirks,
  and MIUI SAF export problems all belong to `[DEVICE]`/`[OEM]` territory, not
  to rish itself.

## Troubleshooting

### "Request timeout" (5 seconds)

The loader printed: *"Request timeout. The connection between the current app
(...) and Shizuku app may be blocked by your system. Please disable all battery
optimization features for both current app (...) and Shizuku app."*

- Likely causes: **Shizuku is not running**; the terminal app or Shizuku is
  **battery-optimized / background-restricted**.
- Fix: start the server first, disable battery optimization for **both** apps,
  and retry.

### "Rish requires server 12" / "Make sure you have Shizuku v12.0.0 or above"

- The installed Shizuku server is too old (or the manager's `Shell` class
  cannot be loaded). Update Shizuku to a current version (v13.x).

### "Permission denied"

- rish prints this when the Shizuku runtime permission for the terminal app is
  denied, including a **denied-and-don't-ask-again** state.
- Fix: grant the permission inside the Shizuku app (the app list → your
  terminal app → allow), then rerun.

### Dex writable errors (Android 14+)

- The script printed the guidance message about `rish_shizuku.dex` being
  writable.
- Fix: `chmod 400` the dex (the script tries), and **move both files out of
  `/sdcard`** into the terminal app's private data directory (in Termux:
  `~/rish`). See [Installation and Setup](02-installation-and-setup.md).

### Commands "not found" (env)

- You expected a Termux tool but the remote `sh` says `not found`.
- Explanation: adb backend drops the local environment by default — the remote
  shell uses the daemon's environment (`PATH` = `/system/bin` etc.). Use the
  root backend with preserved env, `RISH_PRESERVE_ENV=1` where applicable, or
  call the tool by its full Android path. See
  [Usage](03-usage-and-command-execution.md).

### rish reports an old/wrong application id

- The script or an exported `RISH_APPLICATION_ID` is not set to your terminal
  app's id (still `PKG`).
- Fix: set `export RISH_APPLICATION_ID=com.termux` (or edit the `rish` file).

### Interactive session looks broken

- Confirm the PTY / window-size path works by resizing your terminal and
  re-tapping; behavior depends on the terminal app and the server version.
  **[DEVICE]**

## Unresolved / needs verification

- End-to-end interactive rish session on a real device with Termux —
  **[DEVICE]** — could not be exercised from this container. **[needs verification]**
- rish ↔ Porter compatibility — Phase 6.
- Sui backend details (Magisk module install; not exercised here).
- Stability of internal transaction codes across every server version ≥ 12 —
  assumed stable, per research; verify against a Sui server if
  needed. **[needs verification]**
- `RISH_PRESERVE_ENV` exported-variable override on a real device.
  **[DEVICE][needs verification]**

## References

- Shizuku-API rish README (usage + env semantics).
- Shizuku manager tutorial strings (`ShellTutorialActivity.kt`,
  `strings.xml`) — timeout and dex messages.
- Phase 5 research notes: `research/rish/00-rish-research.md` (§10, §11).