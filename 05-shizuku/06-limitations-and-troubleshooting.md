# Limitations and Troubleshooting

## Limitations

- **Not root.** On an unrooted device Shizuku provides the adb `shell`
  permission set (uid 2000), not root. It is also not ADB, rish, Sui, or
  Porter — distinct systems (AGENTS.md §10).
- **Restart after every boot (rootless).** Non-root Shizuku must be started
  again after each reboot (wireless pairing / adb). Root mode can start on
  boot.
- **Android 6.0 minimum** for Shizuku and Sui. **[version-sensitive]**
- **Startup depends on ADB/debugging being enabled.** In ADB mode, USB or
  wireless debugging must be on; turning it off stops the ability to start.
  [version-sensitive: Android 13+ rootless auto-start on trusted WLAN is a
  separate, newer path — see Activation.]
- **OEM breakage.** Some systems interfere with the start:
  - MIUI: enable **"USB debugging (Security options)"** (in addition to normal
    USB debugging);
  - ColorOS/OnePlus: disable **"Permission monitoring"**;
  - Flyme: disable **"Flyme payment protection"**.
  **[OEM] — these are bullets from the official manual; behavior on a real
  device must be confirmed.**
- **Background restrictions are the most common cause of failure or random
  stops**: allow Shizuku to run in background, keep USB debugging / Developer
  options enabled, choose the "Charge only" USB mode, and enable "Disable adb
  authorization timeout" (Android 11+).
- **GrapheneOS**: "Secure app spawning" may need to be disabled (per the user
  manual's note).
- **Hidden-API restriction**: since Android 9, apps cannot use hidden APIs; a
  Shizuku app wishing to do so usually bundles its own bypass. The restriction
  itself is Android's, not Shizuku's.
- **Termux-side absence**: there is no `shizuku`/`rish`/`sui` package in the
  termux-packages repository (verified 2026-09-22). **[version-sensitive]**

## Troubleshooting

### Server not starting

- Confirm the prerequisites: Developer options, USB debugging (and for the
  wireless method, Wireless debugging + Android 11+).
- Run the start command the **app itself shows** (home → start). Remember the
  command changed at v13.6.0 — the website's `start.sh` text is **stale** for
  v13.6.0+ (see [Activation and Startup](03-activation-and-startup.md)).
  **[version-sensitive]**
- Success is indicated by the marker **`info: shizuku_starter exit with 0`**.
- Starter exit codes (v13.6.0): 3 classpath, 4 fork, 5 app_process, 6 uid, 7
  manager APK path, 9 kill, 10 SELinux/root.

### Wireless debugging problems

- "Searching for pairing service" loop → allow Shizuku background/network
  activity, keep the wireless-debugging screen open, disable battery
  optimization for Shizuku.
- Pairing prompt on MIUI doesn't appear / behaves oddly → switch notification
  style to "Android" (per manual). **[OEM][DEVICE]**
- After reboot the session is gone → re-pair (system limitation).

### rish-related failures

Handled in detail in the
[rish section](../06-rish/05-limitations-and-troubleshooting.md); the most
common Shizuku-side cause is **the server is not running**, or the terminal
app and Shizuku are battery-optimized (5-second request timeout).

### Apps cannot start / previous grants gone

- One-time grants are not persisted — re-grant.
- After updating the manager APK, the server may detect a changed APK and the
  setup restarts; re-start Shizuku and re-grant.

## Diagnostics overview

| Symptom | Likely cause | See |
|---------|--------------|-----|
| "Request timeout" in rish | battery optimization / background restrictions | [Command-Line Use and Termux](05-command-line-and-termux.md) |
| No pairing service found | background restrictions, wrong method/Android version | [Activation and Startup](03-activation-and-startup.md) |
| Starter exit codes | classpath/app_process/kill/SELinux issues | [Activation and Startup](03-activation-and-startup.md) |
| Commands behave differently than as root | server is running as uid 2000, not root | [Permissions](04-permissions.md) |

## Unresolved / needs verification

- Exact on-screen start-command string on a real device (paths are generated,
  and the v13.6.0 native-command wording is not pinned to a release note).
  **[DEVICE][needs verification]**
- Wireless-debugging pairing behavior on a real device. **[DEVICE]**
- Trusted-WLAN auto-start behavior across OEM power-management policies.
  **[DEVICE][OEM]**
- Pre-v11 permission scheme details (history only). **[needs verification]**
- rish ↔ Porter compatibility — deferred to Phase 6.

## References

- Official user manual (FAQ/OEM notes): `shizuku.rikka.app/guide/setup.html`.
- Source: `Starter.kt`, `StarterActivity.kt`, `BootCompleteReceiver.kt`,
  `starter.cpp`.
- Phase 5 research notes: `research/shizuku/00-shizuku-research.md` (§9, §10).