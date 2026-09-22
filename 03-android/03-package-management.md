# Android Package Management

Android applications are installed as **APK** packages and managed by the
device's system **Package Manager**. From the command line you reach it with
`pm` (on the device), `cmd package` (the modern dispatcher form), and from a
computer with `adb install` and friends. This chapter is about that system —
and about keeping it clearly separate from the two other package systems you
will meet in a Termux workflow.

## Three package systems, three tools

| System | What it manages | Tool | Where |
|--------|-----------------|------|-------|
| **Android** | installed APKs (apps) | `pm`, `cmd package`, `adb install` | on the device / via ADB |
| **Native Termux** | environment packages (`.deb` for Android/Bionic) | `pkg` / `apt` | inside Termux |
| **proot distribution** | that distribution's packages | the guest's manager (`apt`, `apk`, `pacman`, `dnf`, ...) | inside the proot container |

The differences are not cosmetic:

- `pkg install android-tools` (native Termux) gives you the `adb` client; it
  does **not** install an Android app.
- `pm` inside Termux is a `termux-tools` wrapper that `exec`s the **device**
  `/system/bin/pm`, so it operates on **Android** apps, not Termux packages.
- Inside a proot distribution, Android's `pm` normally does **not** exist;
  install/uninstall there uses the guest's own manager.

See [Package Management](../01-termux/02-package-management.md) and
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## `pm` — the package manager command

`pm` runs on the device. You normally invoke it through ADB:

```
adb shell pm <command>
```

On recent Android, `pm` is a thin shell script that delegates to `cmd package`
(see [The `cmd` Dispatcher](04-command-dispatcher.md)); the user-visible
commands below are the ones documented on the official adb page and are
**[version-sensitive]** because subcommands are added across releases.

### Querying installed packages (application inspection)

```
pm list packages                    # all installed packages
pm list packages -3                 # only third-party packages
pm list packages -s                 # only system packages
pm list packages -f                 # include the APK file path
pm list packages -i                 # include the installer package
pm path com.example.app             # print the APK path of a package
pm list users                       # Android user profiles
pm list permission-groups
pm list features
pm list libraries
```

- `list packages` accepts a filter: `pm list packages com.android` lists
  packages whose names start with `com.android`.
- Combine through the shell as usual: `adb shell pm list packages | grep foo`.

Debugging aid: to see a package's manifest-ish details, apply `dumpsys package
<package>` (see [dumpsys](08-dumpsys.md)). To map UIDs for network usage, the
official docs show `dumpsys package pkg | grep userId`.

### Install / uninstall / app state

```
pm install <path-to-apk>            # installs an APK file already on-device
pm uninstall <package>              # removes a package      (example from the
                                    #  official docs: adb shell pm uninstall com.example.MyApp)
pm clear <package>                  # delete ALL app data for a package
pm enable  <package>
pm disable <package>
pm disable-user <package>
pm grant <package> <permission>
pm revoke <package> <permission>
```

- `pm uninstall [-k] [--user <id>] [--versionCode <code>]` — `-k` keeps the
  data/cache directories. **[version-sensitive: option set varies]**
- `pm grant`/`pm revoke`: from **Android 6.0+** any manifest-declared runtime
  permission can be toggled; on **Android 5.1 and lower** only optional
  permissions are grantable. **[version-sensitive]**
- Other documented `pm` verbs: `install-location` getters/setters (with a
  debug-only warning), `set-permission-enforced`, `trim-caches`, user
  management (`create-user`, `remove-user`, `get-max-users`), and the app-link
  family (`get-app-links`, `reset-app-links`, `set-app-links`,
  `verify-app-links`, ...).

> **Warning:** `pm clear` deletes an app's data and cache permanently, and
> `pm uninstall` removes the app. There is no trash. Confirm the package name
> (use `pm list packages`) before using either.

### `pm install` vs `adb install`

- `pm install` runs **on the device** and needs the APK to already be on the
  device (for example under `/data/local/tmp` or `/sdcard`).
- `adb install` runs **on the computer** and pushes the APK to the device
  before installing. For that reason `adb install` is the common path from a
  workstation; `pm install` is what you use from an existing shell.

## `adb install` and `adb uninstall` (from a computer)

From the adb client (see [ADB Basics](../04-adb/01-adb-basics.md) and
[File Transfer](../04-adb/05-file-transfer.md)):

```
adb install app.apk                 # install one APK
adb install -t app-test.apk         # -t is REQUIRED for test APKs
                                    #  (e.g. from Gradle/monkey)
adb install-multiple part1.apk part2.apk ...   # split ("multi") APKs, one package
adb uninstall <package>             # uninstall an application
adb uninstall -k <package>          # uninstall but keep data and cache
```

- `adb install-multiple` is the documented tool for split APKs.
- Version note: exact `adb install` option sets differ between adb releases;
  check `adb help` for your version. **[version-sensitive]**

If you install an APK that is already present, whether the existing app's
data is kept depends on your adb/Android version and the flags you pass. The
official `-r` option is documented as "reinstall an existing app, keeping its
data"; check `adb help` or `adb install --help` on your version.
**[version-sensitive]**

## Package-system summary to remember

- **`pkg`/`apt`** = Termux environment packages (has nothing to do with apps).
- **`pm` / `cmd package` / `adb install`** = Android apps.
- **proot guest manager** = whatever distro you are running inside proot.

Mixing them up is a common source of "I installed it with pkg but the app is
still gone" confusion.

## Cross-references

- Termux's own package manager: [Package Management](../01-termux/02-package-management.md)
- `adb install`/`push`/`pull`: [File Transfer](../04-adb/05-file-transfer.md)
- Inspecting package state further: [dumpsys](08-dumpsys.md)
- The `cmd package` form and dispatcher: [The `cmd` Dispatcher](04-command-dispatcher.md)
- Reading system properties: [Android Properties](02-android-properties.md)

## References

- Official adb page package-manager command table (developer.android.com/tools/adb).
- AOSP `frameworks/base/cmds/pm/pm.sh` (current-main `pm` front-end).
- AOSP adb user man page (`adb install`, `install-multiple`, `uninstall`).
- Phase 4 research notes: `research/adb/01-android-command-ecosystem-research.md` (§3, §5, §12).