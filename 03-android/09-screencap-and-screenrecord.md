# `screencap` and `screenrecord`

The device-side screenshot and screen-recording tools. Both run **on the
device** and are normally invoked through ADB; the computer-side convenience
commands (`adb exec-out screencap -p > file.png`, `adb exec-out
screenrecord`) are covered in
[Capture Workflows](../04-adb/06-capture-workflows.md).

## `screencap`

```
adb shell screencap -p /data/local/tmp/screen.png   # save a PNG on the device
adb exec-out screencap -p > screen.png              # pipe the image to the host
screencap -p                                         # (device) print PNG bytes to stdout
```

- `-d <display-id>` captures a specific display (default is the main display)
  **[version-sensitive]**.
- `-p` asks for PNG output. These are tiny, cheap commands to run; a piped
  capture writes the PNG to stdout, which is what `adb exec-out` (binary-safe)
  uses.
- An **unprivileged shell** can screenshot on stock builds (the shell has
  screencap permission via policy); a capture **inside an app sandbox without
  the screen-capture permission is a different matter**. **[version-sensitive]**

## `screenrecord` (device-side recording)

```
adb shell screenrecord /data/local/tmp/demo.mp4    # record to an MP4 on the device
adb exec-out screenrecord --output-format=h264 -   # stream H.264 to the host stdout
```

Limits (verified against current AOSP `screenrecord.cpp`,
**[version-sensitive]**, **see the "boundary" note below**):

- **No audio** — the tool only records video. This never changes by a flag.
- **Time limit** — default **180 seconds**, maximum **180 seconds** on AOSP
  main builds; current AOSP main additionally supports `--time-limit 0` as
  "unlimited" **[version-sensitive]**.
- **Bit rate** — default ~20 Mbps, configurable with `--bit-rate`; the
  allowed cap on AOSP main is 200 Mbps **[version-sensitive]**.
- Use `--verbose` for progress feedback in the terminal; some devices
  additionally show a status-bar or on-screen indicator while a recording is
  active **[DEVICE]**.

Other documented options: `--size WIDTHxHEIGHT`, `--bugreport <filename>`,
`--rotate`, `--verbose` (see `adb shell screenrecord --help` on the device;
option set is **[version-sensitive]**).

> **Boundary note:** the tool **cannot capture audio**, **does not work on
> Wear OS**, and **does not support screen rotation during recording** (if the
> screen rotates, part of the display is cut off in the output). OEM builds
> can add or remove options, so the exact maximum time and bit rate for your
> device come from `screenrecord --help` and from trying it, not from AOSP
> main. **[DEVICE]**

## Where files land

The shell's `TMPDIR` is `/data/local/tmp`, which is why
`/data/local/tmp/...` is the conventional on-device scratch location for
captures and push/pull staging. See [ADB Shell](../04-adb/04-adb-shell.md) for
the environment, and
[File Transfer](../04-adb/05-file-transfer.md) for getting files to/from it.

## Cross-references

- Full host-side capture workflow (with `exec-out` and decoding):
  [Capture Workflows](../04-adb/06-capture-workflows.md)
- Understanding what the taps in `input` target:
  [settings and input](06-settings-and-input.md)

## References

- AOSP `frameworks/base/cmds/screencap/` and
  `frameworks/av/cmds/screenrecord/screenrecord.cpp` (current main).
- Official adb page: `screencap`, `screenrecord` sections.
- Phase 4 research notes: `research/adb/01-android-command-ecosystem-research.md` (§6).