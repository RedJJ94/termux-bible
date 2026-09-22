# Capture Workflows

End-to-end screenshots and screen recording. The on-device tools are
documented in detail in
[screencap and screenrecord](../03-android/09-screencap-and-screenrecord.md);
this chapter is the workflow layer: getting the result to your computer.

## Screenshot (one-liner, recommended)

The device-side `screencap -p` with no filename writes PNG bytes to stdout;
`adb exec-out` (not `adb shell`) relays them without mangling:

```
adb exec-out screencap -p > screen.png
```

- `-p` selects PNG.
- `exec-out` matters: `adb shell screencap -p > screen.png` tends to corrupt
  the binary because the shell transport may do line-ending/`\r` conversion.
- Save elsewhere on the host as usual (`> "${HOME}/shot.png"`).

## Screenshot (interactive on-device path)

```
adb shell
shell$ screencap /sdcard/screen.png      # capture to a file
shell$ exit
adb pull /sdcard/screen.png .            # and pull it over
```

Useful when you are already in an interactive session.

## Screen recording

```
adb shell screenrecord /data/local/tmp/demo.mp4   # starts recording
# let it run, then interrupt (Ctrl+C in the shell session)
adb pull /data/local/tmp/demo.mp4 .
```

- Recording is **MPEG-4 video only — no audio**; stopping at 3 minutes is the
  default and (on released Android) the maximum. Current AOSP main also
  accepts `--time-limit 0` as "unlimited" and caps the bit rate at 200 Mbps;
  both are **[version-sensitive]** relative to your device's `screenrecord
  --help`. See the on-device chapter for the exact options.
- Use `--verbose` for progress feedback in the recording terminal; some
  devices also show a status-bar or on-screen indicator while a recording is
  active. **[DEVICE]**
- For un-synced but convenient capture, record to `/sdcard/...` and pull from
  there; `/data/local/tmp/...` is equivalent for a quick local file that you
  pull immediately.

## Stream to the host (no file left behind)

A current AOSP `screenrecord` mode writes raw H.264 to stdout:

```
adb exec-out screenrecord --output-format=h264 - > stream.h264
```

- **This is a host stream**, not a file on the device — useful for live
  processing, but the h264 bare format is not directly the MP4's container.
  Behavior and availability vary by adb/Android version. **[version-sensitive]**
- Press Ctrl+C on the host to stop the stream.

## Version and device notes

- `screencap -d` for display selection and whether an unprivileged shell can
  capture everything are device/version dependent —
  see [screencap and screenrecord](../03-android/09-screencap-and-screenrecord.md).
- Wear OS: screen recording is **not supported** there.
- OEM builds can change defaults (max length, bit rate) —
  **[DEVICE]**: `adb shell screenrecord --help` is authoritative for the
  device in your hand.

## Security note

Screenshots and recordings capture whatever is on screen — which can include
credentials, cards, and personal data, and are transmitted plaintext on the
legacy `adb tcpip` transport. Capture only what you intend, and delete captures
with sensitive content (see [Wireless Debugging](03-wireless-debugging.md) for
the plaintext-transport caveat).

## References

- Official adb reference: developer.android.com/tools/adb (`screencap`,
  `screenrecord`, `exec-out`).
- AOSP `frameworks/av/cmds/screenrecord/screenrecord.cpp` (main).
- Phase 4 research notes: `research/adb/00-adb-research.md` (§13),
  `research/adb/01-android-command-ecosystem-research.md` (§11).