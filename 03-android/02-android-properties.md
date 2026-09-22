# Android Properties

Android exposes a global set of **system properties** — key/value strings that
describe the device, the build, the runtime, and per-device configuration.
They are read with `getprop` and (where permitted) changed with `setprop`.

## Where `getprop` / `setprop` come from

Both are **toolbox** commands shipped on the device (`system/core/toolbox`), so
on stock Android the implementation and usage come from the device's toolbox,
not from a GNU/"Linux" package. Options and output are the device's. Run
`getprop --help` (or `toybox`/`toolbox` help) on the actual device to see what
the shipped version supports. **[DEVICE]**

## `getprop`

`getprop` reads properties:

```
getprop                 # list all properties
getprop NAME            # value of NAME, empty if unset
getprop NAME DEFAULT    # default value if NAME is unset
```

Verified usage from current AOSP `getprop.cpp`: `getprop [-TZ] [NAME
[DEFAULT]]` — no arguments lists everything, a single `NAME` prints its value,
`NAME DEFAULT` uses `DEFAULT` when `NAME` is unset. **[version-sensitive]**

Inside native Termux, `getprop` is a `termux-tools` wrapper that `exec`s the
device binary at `/system/bin/getprop`, so the same tool is available from a
normal Termux session (see
[Termux Utilities](../01-termux/06-utilities.md) and
[System Information](../02-shell/08-system-information.md)).

Common identifiers:

```
getprop ro.build.version.release   # e.g. the Android version
getprop ro.board.platform          # SoC platform name
getprop ro.serialno                # serial (not readable in every context)
```

- Property names in the `ro.*` (read-only) and `persist.*` (persist across
  reboots) buckets are standard Android conventions, but many values are
  **device/vendor-specific** **[variable]**.
- Reading `ro.*` properties does **not** require root on stock builds.

## `setprop`

`setprop` sets a property:

```
setprop NAME VALUE
```

- `ro.*` properties are read-only once set; `setprop` against them fails.
- Whether the `shell` user may set a given property depends on SELinux policy
  and the property namespace; stock policy restricts what the shell can change.
  **[version-sensitive]**
- **Quoting matters through adb.** The shell on the host expands quotes before
  adb forwards the arguments, so a value with spaces needs the ssh-style
  double-quoting trick (see [ADB Shell](../04-adb/04-adb-shell.md)):

  ```
  adb shell setprop key "'two words'"
  ```

  Without the doubled quotes the local shell splits `two words` into separate
  arguments and the command fails or sets a different value than intended.

> **Caution:** `setprop` changes device state. A wrong value (for example in
> `persist.*`) can persist across reboots and affect device behavior. Do not
> experiment with properties you do not understand; some properties are
> restore-device-critical on certain builds. Prefer reading with `getprop` and
> writing only documented values.

## System information via properties

For the purpose of "how do I see my Android version / model / build", the
ro-table is the fast path:

| Property pattern | Usually shows |
|------------------|---------------|
| `ro.build.version.release` | Android version string |
| `ro.build.version.sdk` | SDK/API level number |
| `ro.product.model` / `ro.product.manufacturer` | device branding |
| `ro.board.platform` | SoC platform |
| `ro.serialno` | serial number |

Values are device-dependent; treat the table as "usually", not as guaranteed.
For deeper inspection of running system state, see [dumpsys](08-dumpsys.md).

## Unresolved behavior (do not assume)

Whether newer Android versions restrict *which* properties are visible to the
`shell` and app contexts (for example on Android 16+) is **reported in
community sources but is not verified against an authoritative source in the
Phase 4 research**. Until it is verified, this documentation does not claim
such a restriction; check the behavior on the relevant API level before
relying on it. **[needs verification]**

## Cross-references

- `getprop` inside Termux: [System Information](../02-shell/08-system-information.md)
- More device/service state: [dumpsys](08-dumpsys.md)
- Reading properties from a computer: [ADB Shell](../04-adb/04-adb-shell.md)

## References

- AOSP `system/core/toolbox/getprop.cpp`, `setprop.cpp` (usage and toolbox
  packaging).
- Phase 4 research notes: `research/adb/01-android-command-ecosystem-research.md` (§8),
  `research/android/00-android-shell-research.md` (§10).