# Storage Setup

How to give Termux access to the device's **shared storage** and use the
`~/storage` symlink set. The conceptual model and permission details are in
[Storage and Permissions](../00-foundations/04-storage-and-permissions.md);
here is the practical procedure.

## What `termux-setup-storage` does

- Requests the Android storage permission (it requests what the current app
  version asks for — see the version note below).
- Creates the `~/storage` symlink set in `$HOME` pointing into shared storage.
- If `~/storage` already exists, it rebuilds the directory (asking for
  confirmation first) without deleting the actual storage contents.

## Procedure

```sh
termux-setup-storage
```

- Android will show a permission dialog. Approve it.
- When it finishes, `ls ~/storage` shows the symlinks:

```
dcim  downloads  movies  music  pictures  shared  ...
```

- `~/storage/shared` is the root of shared storage; the named subfolders
  (Downloads, DCIM, Pictures, Music, Movies) and possibly others are linked
  individually. `external-1` (and newer variants) point at Termux-private
  folders on external storage when present.
- Re-run `termux-setup-storage` any time you revoke-and-re-grant the
  permission or want the symlinks rebuilt (it will ask first).

> **Version-sensitive (app version):** Termux app v0.118.x requests the
> legacy write-storage permission; the v0.119 series requests "All files
> access" (`MANAGE_EXTERNAL_STORAGE`). Follow what the dialog on your device
> actually asks.

## If nothing happens, or it fails

Common failure cases and what to check:

- **Android 14 (and some Android 11+ devices):** run
  `pkg install termux-am` first, then re-run `termux-setup-storage`. The AM
  (Activity Manager) helper is needed for some storage permission flows. A
  documented symptom is the command appearing to do nothing or exiting with
  status 255 (see termux-app issue #3647).
- **"Permission denied" even after granting (Android 11+):** revoke the
  permission and grant it again. This is a known Android behavior, not a
  Termux bug.
- **The dialog never appears:** check the app's permission screen in Android
  Settings (`Apps > Termux > Permissions`), then run the command again.

## Granting/checking the permission by hand

- **Android < 11:** `Settings > Apps > Termux > Permissions > Storage`.
- **Android 11+:** `Settings > Apps > Termux > Permissions > Files and media →
  Allow management of all files`, or `Settings > Apps > Termux > Special app
  access > All files access` on Android 13+.
- **Android 15 fallback (v0.118.x app):** grant "All Files Access" under
  `Settings > Apps > Termux > (Additional >) Special app access`.

Exact wording is version/device dependent; use the option that grants the
"all files access" / storage management permission.

## After setup: how to use it

```sh
ls ~/storage/shared                    # root of shared storage
cp ~/storage/downloads/report.pdf .    # copy a file into Termux
echo hi > ~/storage/dcim/note.txt      # write to shared storage (permissions permitting)
```

Rules to remember:

- Executables and scripts placed on shared storage **cannot be executed**
  (`noexec`); run them with an interpreter (`bash ~/storage/foo.sh`) or keep
  them in `$HOME`.
- Keep active work in `$HOME` (app-private); use shared storage only to
  exchange files with other apps.
- Uninstalling Termux deletes `$HOME`/`$PREFIX` but **not** shared storage
  files.

## Files by content URI (SAF alternative)

`termux-storage-get <output-file>` (needs [Termux:API](07-add-ons.md) +
`termux-api` package) opens the Android file picker and copies the
user-chosen file to the given output path — useful when you want to
read/write a specific document without granting broad storage permission.

## References

- termux-tools `scripts/termux-setup-storage.in`.
- Termux wiki "Termux-setup-storage" / "Internal and external storage" pages.
- termux-app issues #3647, #4440, #4767 (Android 11–15 storage permissions).
- Research notes §3.6 and §5: `research/termux/00-foundations-research.md`.