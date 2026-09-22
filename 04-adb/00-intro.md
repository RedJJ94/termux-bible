# ADB and Android Debugging

ADB — the **Android Debug Bridge** — is the standard channel between a
computer (**host**) and an Android device or emulator. With it you install
apps, copy files, capture screenshots and recordings, read logs, and reach the
device's shell. This section covers ADB itself:

- **[ADB Basics](01-adb-basics.md)** — what the client/server/adbd architecture
  is, how to install `adb` (including in Termux), and how to select a device.
- **[USB Debugging](02-usb-debugging.md)** — enabling developer options and
  connecting over USB.
- **[Wireless Debugging](03-wireless-debugging.md)** — Android 11+ pairing,
  trusted networks, mDNS, and the legacy `adb tcpip` path.
- **[ADB Shell](04-adb-shell.md)** — what an `adb shell` session is, and who
  it runs as.
- **[File Transfer](05-file-transfer.md)** — `adb push`/`pull`/`forward` and
  where files can go.
- **[Capture Workflows](06-capture-workflows.md)** — end-to-end screenshots
  and screen recording with the device-side tools documented in
  [screencap and screenrecord](../03-android/09-screencap-and-screenrecord.md).

## Where `adb` runs

ADB has three parts (details in [ADB Basics](01-adb-basics.md)): a **client**
that runs the command, a device-side **daemon** (`adbd`), and a **server**
that brokers the connection on the host. You normally think only about the
`adb` client command.

You can run that client:

- On a **desktop** — from Android Studio's Platform Tools.
- **Inside Termux** — `pkg install android-tools` (see
  [ADB Basics](01-adb-basics.md) for what the Termux build does and does not
  include).
- **Inside a proot distribution** — you may compile or vendor the tools there;
  that is build-your-own and not covered here.

The **device side** (`adbd`) is Android itself; you do not install it.

## Environment distinction to keep in mind

`adb shell` gives you the **Android shell** (`/system/bin/sh`,
see [The Android Shell](../03-android/01-android-shell.md)) running as the
**`shell` user** — not a Termux shell, not root, and not a proot
distribution. Commands documented here are device-side unless stated
otherwise. General environment rules are in
[Android Sandboxing](../00-foundations/02-android-sandboxing.md).

## Prerequisites and security at a glance

- You need **Developer options** enabled and **USB debugging** (or **Wireless
  debugging**) turned on — see [USB Debugging](02-usb-debugging.md).
- Since Android 4.2.2, connecting a new host requires an **RSA-key
  authorization** ("Allow USB debugging") prompt on the device. That
  authorization is what protects the debug channel.
- Debugging access is powerful: with an authorized host, the device shows you
  logs, screenshots, and app data it would otherwise keep private. **Revoke
  authorizations before lending or selling the device**, and only enable
  debugging when you need it.
- Version-sensitive behaviour is tagged throughout, e.g. **wireless debugging
  requires Android 11+ (phones)** and **ADB Wi-Fi 2.0 auto-connect requires
  Android 17 + adb 37.0.0**. See each chapter for the boundary.

## Cross-references

- The shell you reach through ADB: [The Android Shell](../03-android/01-android-shell.md)
- On-device tools: [The `cmd` Dispatcher](../03-android/04-command-dispatcher.md),
  [Android Package Management](../03-android/03-package-management.md),
  [logcat](../03-android/07-logcat.md),
  [dumpsys](../03-android/08-dumpsys.md)
- Adb `shell` vs root vs Shizuku vs rish vs Porter: later sections; they are
  distinct privileged-access systems, not interchangeable.