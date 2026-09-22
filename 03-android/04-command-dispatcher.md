# The `cmd` Dispatcher

`cmd` is the device-side command dispatcher that most Android administration
tools sit on top of. Understanding it explains why `am`, `pm`, `settings`, and
`input` all behave the way they do on recent Android.

## What `cmd` does

`cmd <service> <args>` resolves the named **system service** (for example
`package`, `activity`, `settings`, `input`) and runs that service's
shell-command handler, so the general shape is:

```
adb shell cmd <service> <command> [args]
```

Each service exposes its own subcommands. For example, `pm`'s real target is
the `package` service, so `cmd package list packages` is the dispatcher form of
`pm list packages`.

The mapping of the familiar front-ends (**[version-sensitive]** — verified from
AOSP main; the exact Android release where these became scripts is **not
pinned** in the research) is:

| Front-end | Dispatcher form |
|-----------|-----------------|
| `am` | `cmd activity` (except `am instrument`) |
| `pm` | `cmd package` |
| `settings` | `cmd settings` |
| `input` | `cmd input` |

So on current Android you can usually write either `pm list packages` or `cmd
package list packages`. Prefer the short `pm`/`am`/`settings`/`input` names in
examples — they are what most documentation, including this Bible, uses — and
remember that the long `cmd` form is what actually runs underneath.

## Packaging note (version-sensitive)

- Historically `cmd` shipped as a script that launched a Java class via
  `app_process`. The implementation module has since moved in AOSP — there is
  **no `cmds/cmd` module on current AOSP main** (verified 2026-09-22). The
  user-visible interface (`cmd <service> <args>`) is stable, but do not
  cite an implementation path without re-checking the tree. **[version-sensitive]**
- OEM builds generally provide `cmd`, but some OEMs restrict certain
  subcommands (for example `cmd windows` / `cmd activity` on locked-down
  variants). Try the command; if denied, check the device. **[DEVICE]**

## Inside Termux

Termux ships a **`cmd` command that is a compiled wrapper** (from
`termux-tools`), not a Termux tool of its own. It forks and pipes
stdin/stdout/stderr to the device's `/system/bin/cmd`. The specific reason for
the compiled C rewrite is **not documented** in `termux-tools` sources — do not
repeat any guessed rationale. See [Termux Utilities](../01-termux/06-utilities.md).

## Documented `cmd` examples

```
adb shell cmd package dump-profiles <package>   # ART execution/optimization profiles;
                                                #  Android 7.0+, root/fs access needed to retrieve the file
adb shell cmd testharness enable                 # test-harness device reset path
```

- `cmd package dump-profiles` is documented on the official adb page.
- `cmd testharness enable` (Android 10+) resets the device into a test
  harness: it keeps the RSA debugging key across the factory reset and
  disables the lock screen, emergency alerts, auto-sync, and auto-updates. It
  is a **device-reset** command — use deliberately:

> **Warning:** `cmd testharness enable` performs a device reset (factory
> restore minus the saved debug key) and changes lock/alert/update settings.
> It will wipe the device's user data. Do not run it on a device you care
> about without reviewing what "testharness" means on your Android version.

## Cross-references

- `am`: [Activity Manager](05-activity-manager.md)
- `pm` / the `package` service: [Android Package Management](03-package-management.md)
- `settings` / `input` services: [settings and input](06-settings-and-input.md)
- Reaching `cmd` from a computer: [ADB Shell](../04-adb/04-adb-shell.md)
- The Termux `cmd` wrapper: [Termux Utilities](../01-termux/06-utilities.md)

## References

- AOSP `frameworks/base/cmds/{am,pm,settings,input}/*.sh` (current-main
  front-ends).
- Official adb page (`cmd package dump-profiles`, `cmd testharness`).
- Phase 4 research notes: `research/adb/01-android-command-ecosystem-research.md` (§3),
  `research/android/00-android-shell-research.md` (§8, §10).