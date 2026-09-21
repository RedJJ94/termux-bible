# Installing Termux

## Supported sources

Termux is distributed through three sources. **They cannot be mixed** (see the
"mixing sources" rule below), and the behavior differs between them.

| Source | Status | Notes |
|--------|--------|-------|
| **F-Droid** | Recommended | The standard, widely used source. Uses a non-public signing key held by the project. Missing only a few options compared to GitHub builds. |
| **GitHub releases** | Official | Release APKs for version >= 0.118.0 and build-action artifacts. Uses a **public test signing key** — see security warning below. |
| **Google Play** | Experimental | Built from a separate repo (`termux-play-store`), Android 11+, and missing functionality compared with F-Droid builds. Play may try to auto-update over an F-Droid-installed copy. Historically suspended, then restored in June 2024. **Version-sensitive.** |

> **Current version note (version-sensitive, research date):** stable
> v0.118.3 (2025); the v0.119 development series is where current changes
> land (package-manager variable export, new storage permission model,
> Android 5/6 support). Check the official release page for the current
> version when you install.

## System requirements

- **Full app plus package support: Android >= 7.**
- **Android 5/6:** package (bootstrap) support was dropped in 2020; app-only
  builds existed from 2022. **Version-sensitive:** the v0.119 series re-adds
  full Android 5/6 support (including `apt-android-5` bootstrap/APK
  variants).
- **Architecture:** AArch64, ARM (with NEON), i686, or x86_64.
- **Disk:** at least ~300 MB free is a common guidance figure.

> **Unsupported environments:** VMOS/F1VM virtual-Android sandboxes are
> explicitly unsupported; installing Termux inside them will not work.

## Bootstrap

At first launch the app installs a minimal package set called the
**bootstrap** — a small, pre-built archive (for example a file named
`bootstrap-<date>-r1+apt.android-7`) that gives you a working shell and `pkg`.
After that you install everything else through the package manager
([Package Management](02-package-management.md)). Sizes are roughly 180 MB for
the universal APK/bootstrap and about 120 MB for architecture-specific ones
(**device-dependent**). The APK itself and the bootstrap are separate
downloads; you can download the bootstrap archive manually from the
termux-packages releases if needed.

## The mixing-sources rule (important)

All Termux apps share the Android `sharedUserId` `com.termux`. Android only
allows apps signed the same way to share this UID — so **every Termux APK on
your device must come from the same source and be signed identically.**

Consequences:

- You cannot install the app from F-Droid and then install a plugin from
  GitHub, and vice versa.
- To switch sources you must **uninstall every Termux-related app** first and
  reinstall from the new source.

> **Security warning:** F-Droid builds use an untrusted, but non-public,
> signing key. GitHub builds use a **publicly known test key**; anyone can
> produce updates signed with that key, so only install GitHub builds you have
> obtained from the official repository.

## After installation

1. Open Termux and wait for the bootstrap to install (first run may take a
   moment and print progress).
2. Run `pkg update` to refresh package lists,
   then `pkg upgrade` to update everything (see
   [Package Management](02-package-management.md)).
3. If you want to use the shared storage of the device, run
   `termux-setup-storage` (see [Storage Setup](04-storage-setup.md)).
4. Check the environment with `termux-info`.

## Verifying what you have

- `termux-info` prints the app version, architecture, and current
  repositories and mirrors.
- `echo "$TERMUX_VERSION"` shows the app version exported in the env.
- `pkg help` shows the package manager you are on (`apt` today, `pacman`
  planned — see [Package Management](02-package-management.md)).

## Uninstalling

Uninstalling the Termux app deletes `$PREFIX` and `$HOME` — that is, every
package and every personal file inside Termux, with no recovery. Back up first
if the data matters (see [Backup, Restore, and Reset](08-backup-restore-reset.md)).

## References

- termux-app README (official sources, versions, signing, requirements):
  <https://github.com/termux/termux-app>
- termux-packages developer wiki page "Termux-Android-5-or-6":
  <https://github.com/termux/termux-packages/wiki>
- Research notes §3.2 and §5: `research/termux/00-foundations-research.md`.