# Limitations and Troubleshooting

This chapter collects what Porter **cannot** do (so you don't build false
expectations) and the failure modes you are most likely to hit. Device-level
behavior is what the official docs claim; things that need a real device to
confirm are tagged **[DEVICE]**.

## Limitations

- **Not root by itself; access is identity-bound.** On an unrooted device the
  server runs as **uid 2000 (adb `shell`)**. It has the adb `shell` permission
  set: it can read/write system settings, use `pm`-style operations granted to
  `shell`, run `sh`, and modify system properties — but it **cannot** read
  other apps' private storage under `/data/user/0/...`, and it is still held by
  SELinux/MAC. To do those things, start Porter via **root** (or root the
  device and use the real `su` path).
- **Untrusted wireless/computer environments.** The wireless ADB handshake is
  the trust anchor; a spoofed pairing/port can impersonate a computer. Keep
  debugging access enabled only when needed; Android's pairing is designed for
  the home Wi-Fi scenario and is **a trust anchor, not a security boundary** —
  treat a device with debugging access enabled as one you fully control. Use
  `adb devices` to review authorized computers. (See the ADB files, e.g.
  [ADB — USB Debugging Notes](../04-adb/02-usb-debugging.md) and
  [ADB Shell identity](../04-adb/04-adb-shell.md).)
- **Boot behavior varies.** On an unrooted device the server must usually be
  started again after every reboot. **Start on boot** is an opt-in
  mitigation that still depends on Android making debugging access available
  after boot (see [Activation and Startup](04-activation-and-startup.md)).
- **Not a drop-in for every Shizuku use-case.** Stock `rish` does not connect
  to Porter (the client loader needs Shizuku's own class; see
  [rish and porsh](07-rish-and-porsh.md)). If you rely on rish, that is a
  Phase 5 tool and targets a Shizuku/Sui daemon, not Porter.
- **The companion cannot coexist with genuine Shizuku.**
  ([Shizuku Compatibility](06-shizuku-compatibility.md)).
- **Early release lifecycle.** v0.1.1-beta1 is a pre-release; interfaces can
  change between beta releases ([version-sensitive]). The SDK's update path is
  not stable yet ([App Integration and the SDK — Versioning](09-app-integration-and-sdk.md)).
- **OEM restrictions.** Some devices/ROMs restrict wireless debugging or
  background starts; MIUI keeps the SAF copy caveat for porsh export
  **[OEM] [needs verification]**.

## Troubleshooting

### Porter will not start

The start command itself — see [starter exit codes](04-activation-and-startup.md).
The most common cases:

| Symptom | Likely cause / fix |
|---------|--------------------|
| Start via **computer** fails | Get a **fresh command** from Porter after updating/reinstalling; the path can change. Never reuse a Shizuku command. Check `adb devices` shows **device** (not `unauthorized`/`offline`). |
| Wireless pairing fails | Keep the Android **pairing-code dialog open** while entering the code; use the **pairing port** (not the connection port); allow local-network/notification access for Porter; restart Wireless debugging and re-pair. **[DEVICE]** |
| Wireless debugging option missing | Older Android (< 11) — use the computer/USB method (the method list behind the docs). **[version-sensitive]** |
| Root start fails | Real root/su is required; "Porter does not root your device". Check the root manager's version — the starter refuses if `su` blocks app→su Binder (exit code 10); earlier `app_process` errors appear as codes 3–5. |
| "startup by root failed"/"Could not start" toast (not on TV) | The starter requires the calling identity to be adb/shell (uid 2000) or root (uid 0), or the manager APK is not found/readable (code 6/7). |
| After update, service stops | The server detects the APK replacement (signature/APK baseline) and exits; just start Porter again and **re-export porsh**. |

### Start-on-boot issues

- "Permission error" notification → grant happened only after first successful
  start; **start manually once** first.
- "Background start not supported" → API < 30, not a TV, and no
  always-available debugging gateway (details in
  [Activation and Startup](04-activation-and-startup.md)). **[version-sensitive]**
- Background limits: disable battery optimization for Porter if it keeps
  dropping. **[DEVICE]**

### porsh errors

| Error | Cause / fix |
|-------|-------------|
| `Could not read the porsh.dex file` / "the dex can't be read" | Android 14+ storage: put `porsh.dex` in an **app-private** directory and `chmod 400` (e.g. under a directory private to the app you run it from). MIUI: SAF copy corruption — move the files via a file manager instead. **[OEM]** |
| **`Permission denied`** after first run | A prior permanent denial is stored; go to **Porter → Applications**, lift the denial for your client, then retry. Denying permanently is the only path that stores such a denial. |
| Empty/foreign env | Default env filtering; set `PORSH_PRESERVE_ENV=1` (uid 2000) or `=0`/unset (uid 0) as needed (see [Environment filtering](07-rish-and-porsh.md)). |
| `Waiting for service. This may take up to 1 minute...` | This is normal at first start (the server comes up); if it never connects, check the server is actually running (Porter home screen). |
| Shell times out / hangs | The client waits for `Porter.connection` with a **10s startup watchdog** (cancelled once a permission decision is invoked) and prints a timeout message; if it never connects, the daemon is not reachable or the client has no permission — check the running server identity with `porsh -c 'id'`. |

### "Permission denied" / authorization semantics

- Deny permanently = stored in Porter until you lift it in **Porter →
  Applications** ([Permissions and
  Identities](05-permissions-and-identities.md)).
- One-time grant works only for the session — next request will ask again.
- Legacy-only apps work only while a trusted **Porter Compatibility**
  companion is installed; without it, their request is deferred as
  "companion pending".

### Generic

- **Restart:** stop and start Porter (or toggle **Allow app access**) — the
  welcome fix for most glitchy states. New porsh sessions are refused while
  access is paused; already-running porsh sessions continue until they exit,
  then stay stopped until the server is started again.
- Any report to the maintainer should include the device model, Android
  version, Porter version, and the startup method used; the project issue
  tracker is the official channel for bugs. (Do not file bugs against
  Shizuku; unrelated.)

## References

- Official docs: `porter.darken.eu/troubleshooting` and
  `porter.darken.eu/docs/sc/porsh-in-shell`.
- Phase 6 research notes: `research/porter/00-porter-research.md` (§5.3, §6.1,
  §10–§11); `research/rish/00-rish-research.md` (§8).

## Security reminders

- Any porsh/root session you run is **uid 2000 or uid 0** — treat it as a
  privileged shell, not a sandbox.
- Approve only apps you trust for access; audit **App access** periodically.
- Keep debugging access disabled when not in use.
- This documentation separates verified facts from device-dependent behavior;
  do not treat **[DEVICE]**/[OEM] items as universally applicable.