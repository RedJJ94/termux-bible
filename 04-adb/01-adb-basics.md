# ADB Basics

## What ADB is

The Android Debug Bridge has three components (official definition):

| Component | Where | What it does |
|-----------|-------|--------------|
| **client** | your computer (or Termux/proot) | sends commands |
| **daemon (`adbd`)** | the Android device | executes commands on the device |
| **server** | your computer | manages communication between client and daemon |

- The server listens on local TCP port **5037** and runs in the background.
  All `adb` clients talk to it.
- The server discovers devices: it scans odd ports **5555–5585** for
  emulators (first 16; for example Emulator 1's console is on 5554 and adb on
  5555), and USB/wireless devices are managed through the platform's
  backends.
- `adb` is distributed as part of Android SDK **Platform Tools**
  (`platform-tools/adb`), with a standalone download available from the
  Android Studio releases page.

## Installing `adb`

### Desktop (Platform Tools)

Download Platform Tools for your OS from the official Android Studio releases
page and run `adb` from the extracted folder, or install it with your
distribution's package manager where available. The official pages treat the
standalone download as the standard source.

### Inside Termux

```
pkg install android-tools
```

Termux builds the **`android-tools`** package from `nmeum/android-tools` (an
adb/fastboot reimplementation) using android-vendored sources. Facts verified
at drafting (2026-09-22; the package auto-updates, so re-check):

- Version **37.0.0** at drafting time, with `TERMUX_PKG_AUTO_UPDATE=true` in
  the Termux build recipe **[version-sensitive]** (the version can move on its
  own).
- It installs the `adb` client and `fastboot`, and **removes `bin/mkbootimg`**
  because that name conflicts with the separate `mkbootimg` package.
- Build dependencies include `abseil-cpp brotli fmt libc++ liblz4 libprotobuf
  pcre2 zlib zstd`.
- **mDNS is NOT enabled** in the Termux build: the bundled-libusb USB backend
  is on, but the mDNS option is off by default upstream and the Termux recipe
  does not turn it on. Consequences:
  - `adb mdns` auto-discovery and **ADB Wi-Fi 2.0** auto-connect are
    **unavailable/not to be expected** with the Termux `adb`.
  - Manual flows are unaffected: `adb connect`, `adb pair`, and everything
    over USB work normally.
  - This can change when the recipe or upstream defaults change.
    **[version-sensitive]**
- `adb`'s behavior is intended to be close to Platform Tools, but it is a
  reimplementation — treat esoteric flags as worth confirming against `adb
  help`.

### Inside a proot distribution

You can compile adb there, or vendor the platform-tools binary; this Bible
does not document proot-side installation because the termux-native
`android-tools` package already provides adb in native Termux.

## First commands

```
adb --help            # adb help (the usage text; also 'adb help')
adb version           # prints client and server version
adb devices           # list connected devices
adb devices -l        # long listing: product/model/device
adb kill-server       # stop the server
adb start-server      # start the server
```

- `adb kill-server` followed by any adb command restarts the server on the
  next invocation.
- **`adb devices` output states**: `offline` (device is present but not
  usable/authorized), `device` (usable), and nothing (disconnected
  [sometimes shown as `no device`]). A `device` state registers during
  boot — it does **not** mean boot completed.
- Serial formats seen in practice: `emulator-5554` (emulators), USB serials
  such as `0a388e93`, and wireless entries that look like `0.0.0.0:6520`.

## Choosing a device

```
adb -s <serial> <command>     # target one device by serial
adb -d <command>              # only if exactly ONE hardware device is present
adb -e <command>              # only if exactly ONE emulator is present
```

- The `ANDROID_SERIAL` environment variable selects a device for a session;
  explicit `-s` overrides it.
- With several devices and no selector, adb errors: `adb: more than one
  device/emulator`.
- Other global options: `-H <host>` (adb server host, default `localhost`),
  `-P <port>` (adb server port, default 5037), `-L <socket>` (listen socket
  for the adb server), and `--one-device <serial|usb-address>`, which makes
  the **server** hold exactly one USB device — identified by serial number or
  USB device address — and is only accepted with `start-server` / `server
  nodaemon`. **[version-sensitive]**

## Transport and version notes

This is a **[version-sensitive]** summary of how adb reaches devices (from the
official reference, verified 2026-09-22):

| Feature | Gate | Notes |
|---------|------|-------|
| USB via libusb default | adb **v34+** | default on all OS except Windows, which keeps the native backend by default; needed for `attach`/`detach` and USB-speed reporting; `ADB_LIBUSB` selects |
| mDNS backend `libadbmdns` default | adb **v37**+ | `ADB_MDNS_OPENSCREEN` flips to the openscreen backend (macOS support since v35, others since v34) |
| Burst mode (pipelined transfers) | experimental, adb **36.0.0+** | off by default; `ADB_BURST_MODE=1` or Android Studio debugger setting |

- The Termux `android-tools` package bundles libusb; the mDNS limitation is
  its own separate note (above).

## Security notes

- Port 5037 is a **local** server port on your own machine; any local process
  could talk to it. Do not forward/expose it unless you understand the
  consequences.
- An `adb` client only sees devices that (a) advertise and (b) you authorized
  — see [USB Debugging](02-usb-debugging.md) and
  [Wireless Debugging](03-wireless-debugging.md).

## Cross-references

- Connecting: [USB Debugging](02-usb-debugging.md),
  [Wireless Debugging](03-wireless-debugging.md)
- What to do once connected: [ADB Shell](04-adb-shell.md),
  [File Transfer](05-file-transfer.md),
  [Capture Workflows](06-capture-workflows.md)

## References

- Official adb reference: developer.android.com/tools/adb.
- Termux recipe: `raw.githubusercontent.com/termux/termux-packages/master/packages/android-tools/build.sh`.
- Upstream project: `github.com/nmeum/android-tools`.
- Phase 4 research notes: `research/adb/00-adb-research.md` (§3, §8, §9).