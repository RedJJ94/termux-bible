# `dumpsys`

`dumpsys` prints the current state of Android **system services**. It is the
"everything about the live system" command: battery, package details, activity
stack, connectivity, storage — whatever a service can report, `dumpsys` can
dump.

## Basic usage

```
adb shell dumpsys                      # dump EVERY service (huge)
adb shell dumpsys <service>            # dump one service
adb shell dumpsys <service> <args>     # some services take extra args
adb shell dumpsys --list               # list available services
```

- From a computer, `adb shell dumpsys ...` from the
  [ADB shell](../04-adb/04-adb-shell.md). On the device there is no `dumpsys`
  inside a normal Termux session unless you ship the binary — Termux does **not**
  provide it as a standard termux-tools wrapper (it is a privileged/system
  binary). Use it from ADB, or in an appropriately elevated context (the later
  Shizuku/rish sections cover such contexts). **[needs verification: Termux
  `dumpsys` availability — check `which dumpsys` in Termux before relying on it]**
- `dumpsys --list` shows the long list of service names; a service name is the
  argument form of `dumpsys <service>`.

## Common targets

```
adb shell dumpsys package <package>    # app package details
adb shell dumpsys package com.example.MyApp | grep userId   # official example:
                                     #  map an app to its linux user/group ids
adb shell dumpsys activity            # activity stack / tasks
adb shell dumpsys battery             # battery statistics
adb shell dumpsys connectivity        # network state
adb shell dumpsys settings            # settings state (system/global/secure tables)
```

- The exact set of services and their dump content is **highly
  version- and OEM-dependent** **[version-sensitive]** **[DEVICE]**. There is
  no single stable "dumpsys format" — treat the service list and names as
  contextual.
- `dumpsys package <pkg> | grep ...` pipelines work because dumpsys output is
  plain text.

> **Note:** `dumpsys` is read-only diagnostics — it does not change state (it
> may reset some counters on hardware-specific services, which is rare; treat
> by default as a read tool). It can still help attackers fingerprint a device,
> so keep dumps from devices you don't want to leak.

## Cross-references

- Package details interplay with `pm`: [Android Package Management](03-package-management.md)
- Live properties: [Android Properties](02-android-properties.md)
- Whether `dumpsys` is available inside Termux: [Termux Utilities](../01-termux/06-utilities.md)

## References

- Official dumpsys tool page: `dumpsys` examples (`dumpsys package ... | grep
  userId`).
- AOSP `services/dumpsys/` (the `dumpsys` binary) and service clients.
- Phase 4 research notes: `research/android/00-android-shell-research.md`,
  `research/adb/01-android-command-ecosystem-research.md` (§5, §9).