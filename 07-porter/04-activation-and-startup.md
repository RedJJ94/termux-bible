# Activation and Startup

Porter runs as a server process (`porter_server`). Nothing else can be used
until it is started. There are **three official startup methods**, chosen on
the home screen while the service is stopped:

| Device situation | Method |
|------------------|--------|
| Android 11+ with wireless debugging | Wireless debugging (in-app pairing) |
| Android 7.0+ and a computer (USB debugging) | Start command run with `adb` on a computer |
| Rooted device | Root start (`su`) |

All three paths execute the **same native starter executable** — a small
binary packaged inside the manager APK as `libporter.so` — which then launches
the Java server with `/system/bin/app_process` and the manager APK as its
classpath. Details are at the end of this chapter.

## Wireless debugging (Android 11+, API 30+) [version-sensitive] [OEM]

Requires a Wi-Fi connection and **Android 11 or newer**. Some device
manufacturers restrict wireless debugging; if it is unavailable, use a
computer. **[OEM]**

1. Enable **Developer options** in Android Settings (usually: open **About
   phone** and tap **Build number** seven times; the location varies by
   device).
2. In Developer options, enable **USB debugging** and **Wireless debugging**.
   Accept Android's network authorization prompt if one appears.
3. In Porter, tap **Pairing** under **Start via Wireless debugging**. Allow
   notifications and, if requested, nearby-device or local-network access.
4. Open Android's **Wireless debugging** settings and tap **Pair device with
   pairing code**. **Keep that dialog open.**
5. Expand Porter's pairing notification and enter the code shown by Android.
   Wait for pairing to succeed.
6. Return to Porter and tap **Start** under **Start via Wireless debugging**.
7. Check that Porter says **Porter is running**.

Notes:

- **Pairing is normally needed only once. Starting the service is a separate
  step and is needed again after every device restart.** If Android forgets the
  pairing, repeat the steps.
- The pairing method is selectable (**Settings → Startup → Pairing method**):
  the system flow above, or the **in-app dialog** (Porter discovers the
  pairing service and you enter the code there). If a port is requested, use
  the **pairing port** from Android's pairing-code dialog, **not** the
  connection port on the main Wireless debugging screen.
- **Android TV** uses a pairing Accessibility service with a one-minute
  window: choose **Pairing** in Porter, enable the accessibility service, then
  within one minute open **Developer options → Wireless debugging → Pair
  device with pairing code** and leave that dialog open while Porter reads the
  code. Porter shows its result screen and turns its accessibility service
  off after pairing; choose **Start** after success.
- Porter leaves Android's debugging settings enabled when it stops; you can
  turn them off in Developer options when you no longer need debugging access.

## With a computer (USB debugging, Android 7.0+)

The official prerequisite is Google's **Android SDK Platform-Tools** for ADB on
the computer (covering ADB itself is [ADB](../04-adb/00-intro.md)).

1. Enable **Developer options** and **USB debugging** on the Android device.
2. Connect the device with a USB data cable, unlock it, and approve the
   debugging connection. **Only authorize a computer you trust.**
3. In Porter, find **Start by connecting to a computer** and tap **View
   command**. Run **that exact command** on the computer (with the correct
   `adb` executable prefix for your OS).
4. Check that Porter says **Porter is running**. You can disconnect the cable
   afterward.

Notes:

- With several devices connected, insert **`-s DEVICE_SERIAL`** immediately
  after `adb` (the serial from `adb devices`).
- **Get a new command after updating or reinstalling Porter; the path can
  change. Do not use a startup command copied from Shizuku or another
  installation.** The path/content differ, and a foreign command will not
  start Porter.
- The command is simply running the starter binary on the device through
  `adb shell` (see below).

## Root

1. Open Porter and tap **Start** in its root startup section.
2. Approve Porter's request in your root manager (`su`).
3. Check that Porter says **Porter is running** and shows **root** as the
  startup mode.

The official framing: **"This method is for devices that already have working
root access. Installing Porter does not root your device."**

Stop the current Porter service before switching between root and debugging
access.

## What the startup command actually is [source-verified]

All three methods run the same starter:

- `<nativeLibraryDir>/libporter.so` — the binary adb or `su` executes. On
  device this is an absolute path such as
  `/data/user/0/eu.darken.porter/lib/<abi>/libporter.so` (the app shows the
  exact path; it can change after updates).
- From a computer it is `adb shell <path>/libporter.so`.
- The in-device paths (wireless and root) use the same binary with
  `--apk=<manager APK path>` so the starter can find the server classes
  without resolving them from `/proc/self/exe`.

Behavior **[version-sensitive]**, verified from the starter's C source:

- Refuses to run unless the caller is **root (uid 0)** or **adb/shell
  (uid 2000)** (exit code **6**).
- As root on Android 10+: switches to the init mount namespace, and verifies
  that `su` allows Binder calls from an app to the `su` SELinux context
  (else exit code **10** with the message "the su you are using does not allow
  app to connect to su with binder").
- Selects the manager APK from `--apk=` (or derives it from `/proc/self/exe`),
  optionally `--replace=<pid>` to replace one `porter_server` (validated by
  process name), then forks a child that `setsid()`s, chdirs to `/`, redirects
  stdio to `/dev/null`, writes a ready byte, and executes:

  ```
  /system/bin/app_process -Djava.class.path=<APK> \
      -Dporter.library.path=<apkdir>/lib/<abi> /system/bin \
      --nice-name=porter_server eu.darken.porter.privileged.PorterServer
  ```

- The parent reports `info: porter_server pid is N`.

Starter exit codes (useful when debugging why a start fails):

| Code | Meaning |
|------|---------|
| 3 | setting the server `CLASSPATH` failed |
| 4 | pipe/fork failed |
| 5 | `app_process` exec failed |
| 6 | caller is not root or adb/shell |
| 7 | manager APK not found/readable |
| 9 | kill/replace of an existing server failed |
| 10 | `su` blocks app-to-su Binder/SELinux (root start) |

The manager's startup screen also shows **"Waiting for service. This may take
up to 1 minute..."** while it waits for the server to come up after the start
command.

## Start-on-boot [version-sensitive]

Porter can automatically re-start after a reboot, but with caveats:

- The boot receiver is declared **disabled** in the manifest and is enabled
  only when the user turns on the **"Start on boot"** setting in the Porter
  settings screen (it uses `PackageManager.SYNCHRONOUS` on API 30+ so the
  enable survives an immediate reboot).
- At boot, Porter acts **only in Android user 0** and **only when the server
  is not already running**. If the last launch mode was **root**, it starts as
  root. If it was ADB, it can start wirelessly only when the manager already
  holds the `WRITE_SECURE_SETTINGS` permission (and API ≥ 30, or a TV, or an
  already-open global ADB TCP port); otherwise it shows a "permission error"
  notification, and if neither method applies it prints "Background start not
  supported".
- The `WRITE_SECURE_SETTINGS` grant is given to the manager by the server
  when the manager attaches — that is, **after a first successful start**.
  This is exactly why the official troubleshooting says: "Start Porter manually
  once after installation before relying on **Start on boot**."
- Automatic boot start still depends on Android making debugging access
  available and allowing Porter to run in the background; on an unrooted
  device, restarting after every boot remains the normal expectation.

## Watchdog

A **watchdog** service (opt-in setting, default off) restarts the Porter
service when the Binder is lost. Per its declared manifest purpose it keeps
the API available for apps; it does **not** poll — it only reacts when the
service stops. The watchdog and the wireless start worker run as foreground
services of type `specialUse` (a requirement for apps targeting newer Android
API levels).

## References

- Official setup guide: `porter.darken.eu/setup`.
- Phase 6 research notes: `research/porter/00-porter-research.md` (§4.1–§4.6).
- Source: `manager/src/main/java/eu/darken/porter/manager/starter/Starter.kt`,
  `manager/src/main/java/eu/darken/porter/manager/receiver/PorterReceiverStarter.kt`,
  `manager/src/main/jni/starter.cpp` (manager, HEAD `585aae5`).