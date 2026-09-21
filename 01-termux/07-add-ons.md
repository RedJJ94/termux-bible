# Termux Add-ons

Termux has companion Android apps (plugins/add-ons) that extend the
environment. Some are official Termux project products; others are maintained
separately. Keep the **same-source rule** in mind (below): forced by Android's
shared-UID design.

## The same-source rule (applies to every add-on)

All Termux apps share the Android `sharedUserId` `com.termux`. Android allows
that only when all APKs are signed identically, so:

- **every add-on must be installed from the same source as the main Termux
  app** (F-Droid, GitHub, or Play — consistently);
- mixing sources breaks installation;
- switching sources requires uninstalling everything Termux-related first.

See [Installing Termux](01-installation.md).

## Official add-ons

The official plugin set referenced by the Termux README:

| Add-on | Package command | Purpose |
|--------|-----------------|---------|
| **Termux:API** | `pkg install termux-api` | Access device APIs from the shell: `termux-battery-status`, `termux-camera-photo`, `termux-clipboard-get/set`, `termux-location`, `termux-sms-send`, `termux-speech-to-text`, `termux-storage-get`, `termux-toast`, `termux-vibrate`, `termux-volume`, and others |
| **Termux:Boot** | — (app; script directory `~/.termux/boot/`) | Run scripts at device boot |
| **Termux:Float** | — | Run Termux sessions in a floating/overlay window |
| **Termux:Styling** | — | Change colors and fonts of the terminal |
| **Termux:Tasker** | — | Use Termux commands in Tasker tasks (via a plugin bridge) |
| **Termux:Widget** | — | Place short-lived scripts/widgets on the home screen |

The app install commands (`termux-api` etc.) are *native Termux packages*; the
AR app itself is a separate APK installed like a normal app (respecting the
same-source rule).

## Community / separate projects

- **Termux:X11** — X11 server for Termux, developed in the separate
  `termux-x11` repository, commonly used with proot/X11 GUI environments.
- **Termux:GUI** — a separate project providing a GUI/display server for
  Termux (`termux-gui`).

> These are maintained under their own projects and may have their own
> package/repo setup. Treat versioned capabilities as belonging to those
> projects, not to Termux itself. **[status to be verified at documentation
> time]**

## Using the add-ons

Each official add-on is documented under its own repository in the Termux
GitHub org. Practical examples of API commands:

```sh
pkg install termux-api
termux-battery-status | jq   # needs jq installed
termux-toast "hello"         # Android toast from the shell
termux-storage-get /tmp/file   # pick a file via SAF picker; see Storage Setup
```

The `termux-*` commands generally require the corresponding app installed,
same source, and (for sensors/location) the app-level runtime permissions.

## Requirements and limitations

- Same-source rule (above).
- Storage-related API commands (e.g. `termux-storage-get`) are the
  SAF/content-URI alternative to broad storage permission — see
  [Storage Setup](04-storage-setup.md).
- Device capability varies: if a sensor/feature does not exist, the command
  reports an error rather than working around it.

## References

- termux-app README (official plugin list, same-source rule).
- Termux GitHub org repositories for each add-on.
- Research notes §3.11, §5: `research/termux/00-foundations-research.md`.