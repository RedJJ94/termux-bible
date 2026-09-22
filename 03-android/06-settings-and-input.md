# `settings` and `input`

Two related device-side commands: `settings` reads and writes Android
settings, and `input` injects synthetic touch, key, and text events. Both are
front-ends that dispatch through the `cmd` system on recent Android
(see [The `cmd` Dispatcher](04-command-dispatcher.md)).

## `settings`

`settings` reads and writes the system settings that the Settings app and
Android itself store.

```
adb shell settings list [namespace]        # list settings table(s)
adb shell settings get <namespace> <key>   # read one value
adb shell settings put <namespace> <key> <value>   # write one value
adb shell settings delete <namespace> <key>
adb shell settings reset <namespace> [key] # reset to defaults
```

- The three state namespaces are **`system`**, **`global`**, and **`secure`**.
  Not every key exists in every namespace, and whether the shell may write a
  given key depends on the key itself, Android-version Settings permission
  checks, and SELinux policy. The `secure` namespace is the most restricted;
  some keys there are **not writable from the shell** on stock builds.
  **[version-sensitive]**
- Example — a `global` namespace write:

  ```
  adb shell settings put global airplane_mode_on 1
  ```

> **Note:** toggling airplane mode also involves broadcasting the
> `AIRPLANE_MODE_CHANGED` intent, which a bare `settings put` does not send —
> on some Android versions the setting change alone is not enough for the
> state change to take full effect. Verify on the target device. **[DEVICE]**
- **The full `settings` surface could not be verified during Phase 4**
  research: the AOSP `SettingsShellCommand` source was **not reachable** at
  the time (checked 2026-09-22), so the exact option set is **not documented
  here**. For the authoritative list on your device run the `settings` help
  directly:

  ```
  adb shell settings help
  ```

  Treat anything in that output as authoritative for that device, and keep
  this chapter's statements generic (`list`/`get`/`put`/`delete`/`reset` with
  `system`/`global`/`secure`). **[version-sensitive]**

> **Caution:** `settings put` writes device state directly. A wrong value in
> `secure` or `global` can change device behavior (or, on some builds, degrade
> it) and is not always obvious to undo. Know the key before writing it, and
> prefer verifying with `settings get` first.

## `input`

`input` injects input events as if a user (or the touch screen) produced them.
This is what automation and "tap this coordinate" workflows use from the shell.

General form (verified from current AOSP `InputShellCommand.java`):

```
input [<source>] [-d DISPLAY_ID] <command> [<arg>...]
```

Documented commands:

```
input text 'STRING'                    # type text (think clipboard paste)
input keyevent [--longpress] <KEYCODE>          # press a key, e.g. KEYCODE_HOME
input keyevent --duration <ms> <KEYCODE>        # hold a key for a duration
input tap <x> <y>                      # tap at screen coordinates
input swipe <x1> <y1> <x2> <y2> [duration]     # swipe in ms (default is immediate)
input draganddrop <x1> <y1> <x2> <y2> [duration]
input press                            # brief touch at current pointer position
input roll <dx> <dy>                   # move the pointer relative
input motionevent <DOWN|UP|MOVE|CANCEL> <x> <y>
input scroll                           # scroll (with a move event per AOSP)
input keycombination [keycombination...]         # e.g. input keycombination KEYCODE_CTRL_LEFT KEYCODE_P
```

- `<source>` can be `keyboard`, `touchscreen`, `mouse`, `trackball`, `stylus`,
  `dpad`, `gamepad`, `touchpad`, `touchnavigation`, `joystick`, or
  `rotaryencoder` (source names and behavior depend on the device). **[version-sensitive]**
- `-d DISPLAY_ID` targets a display other than the default.
- Coordinates are in **screen-pixel coordinates of the target display**.
- `keyevent` takes the keycode name (`KEYCODE_HOME`, `KEYCODE_POWER`,
  `KEYCODE_ENTER`, `KEYCODE_BACK`, ...) or the numeric keycode defined in
  AOSP's `KeyEvent` class. `keyevent --longpress` is the documented form of the
  long-press keycode.
- `input text` needs a focused text field, and whatever source/target the
  current focus accepts.

Common examples:

```
adb shell input keyevent KEYCODE_HOME
adb shell input tap 540 960
adb shell input swipe 540 1500 540 500 300
adb shell input text "hello"
```

**Quoting caution:** through `adb shell`, your local shell eats quote layers.
A string with characters the shell interprets (spaces, `&`, `|`, `$`)
typically needs the doubled-quote trick:
`adb shell input text "'a b'"`. See [ADB Shell](../04-adb/04-adb-shell.md).
Behavior also varies by device and by what `input text` resolves to on that
Android version **[DEVICE]**.

> **Note:** arbitrary coordinates depend on your device's resolution. Get the
> real dimensions first (e.g. `adb shell wm size`) — blind taps on guessed
> coordinates are the most common `input` failure. **[DEVICE]**

## Cross-references

- The dispatcher they run through: [The `cmd` Dispatcher](04-command-dispatcher.md)
- Reading/writing system properties (related read path): [Android Properties](02-android-properties.md)
- Screenshots to see tap targets: [screencap and screenrecord](09-screencap-and-screenrecord.md)

## References

- AOSP `frameworks/base/cmds/input/input.sh` (current-main `input` front-end)
  and `services/core/java/com/android/server/input/InputShellCommand.java`
  (the Java implementation; both decoded during Phase 4 research).
- AOSP `frameworks/base/packages/SettingsProvider/...` (`SettingsShellCommand`,
  **not reachable during Phase 4** — hence the `[needs verification]` note).
- Official adb page settings examples.
- Phase 4 research notes: `research/android/00-android-shell-research.md`,
  `research/adb/01-android-command-ecosystem-research.md` (§2).