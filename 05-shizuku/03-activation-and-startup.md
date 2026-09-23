# Activation and Startup

Shizuku is idle until its **server process** is started. The user manual
documents three ways to start it, and the startup command has changed between
Shizuku versions — the exact command you run depends on which version you
have. This chapter covers both the *methods* and the *version conflict*.

## Prerequisites

- Developer options enabled (**Settings → Developer options**, see
  [USB Debugging](../04-adb/02-usb-debugging.md)).
- For the ADB-based and wireless methods: **USB debugging** on, and for the
  wireless method **Wireless debugging** on (Android 11+, see
  [Wireless Debugging](../04-adb/03-wireless-debugging.md)).

## The three startup methods

| Method | Needs | Notes |
|--------|-------|-------|
| **Root** | a rooted device with `su` | "For rooted devices, just start directly" (manual). Can optionally auto-start on boot `[version-sensitive]` |
| **Connect to a computer** | a computer with `adb`, unrooted **Android 10 and below** | run an adb command; must be redone after every reboot |
| **Wireless debugging** | **Android 11+**, no computer | pair once from the device; must be redone after every reboot |

### Root startup

For rooted devices, start directly from the manager (home → start with root).
If root startup is used, the manager can also start on boot automatically
(the `settings_start_on_boot` preference; a receiver watches
`LOCKED_BOOT_COMPLETED`/`BOOT_COMPLETED` and starts via the root backend)
**[version-sensitive]**.

### Wireless debugging startup (Android 11+)

The "no computer" path [version-sensitive: gates on Android 11+ / API 30]:

1. Enable **Developer options → USB debugging → Wireless debugging**.
2. In Shizuku, pick the wireless-debugging method. The device shows an
   **IP:port** and a **pairing code**; the pairing code is entered into
   Shizuku's notification, then Shizuku starts over the wireless connection.
3. **After every reboot** the pairing/startup steps must be repeated "due to
   system limitations" (manual).

The current manager embeds its own ADB stack for this — pairing/pairing-client
code (`AdbClient`, `AdbKey`, `AdbMdns`, `AdbPairingClient`) lives inside the
manager app, so this does not require a host machine. Error messages the app
shows map to internal failures such as: could not connect to the port,
pairing required, or root-required-without-root (resource strings) **[DEVICE:
exact on-screen wording varies]**.

### ADB-based startup (computer, unrooted)

This is the classic path for unrooted devices:

```
adb shell <start-command>
```

The `<start-command>` is where **versions differ** — see below. After running
it, the manager's success screen looks for the marker
`info: shizuku_starter exit with 0`. If you see that, startup succeeded.

> Keep **USB debugging** (and Developer options) enabled, pick the "Charge
> only" USB mode, and on Android 11+ consider the "Disable adb authorization
> timeout" developer option so the session stays usable.

## The startup-command conflict: current vs. documented

This is the **[version-sensitive]** part. Shizuku **v13.6.0** replaced the
startup flow, and the official user manual page (`shizuku.rikka.app`,
last updated 2023-06-21) still documents the *old* command. Do not assume the
website matches the app you have.

### Historical (Shizuku ≤ v13.5.x, "Command for Shizuku v11.2.0+")

The documented command was:

```
adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh
```

- `start.sh` was a small bootstrap script shipped inside the manager. It
  **staged** a copy of the native starter binary from the app's install
  directory to **`/data/local/tmp/shizuku_starter`** (mode 700, owned by
  `shell`) and exec'd it with the manager APK path. The script itself was not
  the server.
- This `start.sh` asset was **removed in v13.6.0** (commit `de83bd11d7`,
  2025-05-25). For Shizuku v11.2.0 through v13.5.x the website command matches
  the app; for v13.6.0+ it is stale (for older pre-v11.2.0 versions the manual
  does not document this command).

### Current (Shizuku v13.6.0+)

The manager now targets the native starter binary **`libshizuku.so`**
(built from `starter.cpp`) directly:

- `userCommand` = `<app nativeLibraryDir>/libshizuku.so` (a path inside the
  manager's install directory — **device/ABI dependent**):
  ```
  adb shell /data/app/<...>/lib/<abi>/libshizuku.so ...
  ```
  The exact constituent paths are generated at runtime from the installed app
  and are not fixed strings — treat them as `[DEVICE]`-generated, and always
  read the exact command that the Shizuku app offers (home → "start" → it
  shows the adb command to run).
- The starter accepts an optional `--apk=<manager apk path>`; without it it
  runs `pm path moe.shizuku.privileged.api` to locate the manager APK itself.
- Release note v13.6.0: "You can copy this file to any executable location,
  such as `/data/local/tmp/shizuku`" — i.e. you may copy `libshizuku.so`
  somewhere shell-writable and run it from there.

### What `libshizuku.so` actually does (v13.6.0, verified from source)

When executed it:

1. Checks the caller is **uid 0** (root) or **uid 2000** (adb/shell) — else it
   exits with `fatal: run Shizuku from non root nor adb user`.
2. Kills any existing `shizuku_server` (SIGKILL by process name); on EPERM it
   tells you to stop the existing Shizuku from the app first.
3. Sets `CLASSPATH` to the manager APK, computes the native library path, and
   runs `/system/bin/app_process -Djava.class.path=<apk> ... --nice-name=shizuku_server rikka.shizuku.server.ShizukuService`.
4. On success prints `info: shizuku_starter exit with 0`.

Exit codes emitted by the starter (for troubleshooting):
**3** classpath, **4** fork, **5** app_process, **6** uid, **7** manager APK
path, **9** kill, **10** SELinux/root.

## Auto-start (rootless) on Android 13+ [version-sensitive]

With the ADB backend, the manager has a boot-time receiver
(`BootCompleteReceiver`) that can restart itself after boot **without root** on
**Android 13+ (API 33)** when the last launch mode was ADB, the app holds
`android.permission.WRITE_SECURE_SETTINGS` **[version-sensitive]**, and the
device is on a **trusted WLAN**: it uses a
local TLS connection (mDNS-announced, `127.0.0.1:<port>`) to run the start
command, setting `adb_wifi_enabled`/`ADB_ENABLED` (`Settings.Global`) as needed.
This matches the
v13.6.0 release note ("Support auto start without root on Android13+ when
connected to a trusted WLAN"). Behavior depends on the OEM's power-management
policy: **[DEVICE][OEM]**. Root mode can also start on boot directly.

## After a successful start

- The server runs as the identity that started it — see
  [What Shizuku Is](01-what-is-shizuku.md) and
  [Permissions](04-permissions.md) for what that means.
- Apps that already requested Shizuku access get the binder delivered and can
  start working; new apps request permission at runtime.

## Troubleshooting startup

The detail list lives in
[Limitations and Troubleshooting](06-limitations-and-troubleshooting.md); the
common quick checks:

- Superuser/root method fails → confirm root actually works (`su -c id` or the
  rooting tool's own test) before blaming Shizuku.
- `cannot_connect_port` / pairing-required errors → restart Shizuku, keep the
  wireless-debugging screen open, allow Shizuku in the background.
- The stale-website trap: copying the old `start.sh` command text instead of
  the current-app command.

## References

- Official user manual setup page: `shizuku.rikka.app/guide/setup.html` (stale
  for v13.6.0 — see above).
- Source: `manager/src/main/jni/starter.cpp` (incl. exit codes), `Starter.kt`,
  `StarterActivity.kt`, `BootCompleteReceiver.kt`, verified at v13.6.0/master.
- Phase 5 research notes: `research/shizuku/00-shizuku-research.md` (§5).
- Wireless-debugging background: [Wireless Debugging](../04-adb/03-wireless-debugging.md).