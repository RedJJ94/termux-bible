# Storage and Permissions

Termux's own files live in app-private storage (see
[The Filesystem](03-filesystem.md)). To reach the *shared* storage that other
apps, downloads, and media use, Termux needs an explicit Android permission
and creates a set of symlinks you use from the shell. This chapter covers the
model; the practical setup procedure with `termux-setup-storage` is in the
Termux section ([Storage Setup](../01-termux/04-storage-setup.md)).

## The basic idea

- Shared storage access requires an explicit permission. It is **not** granted
  by default and is **not** requested when Termux starts.
- The standard way to grant and wire it up is the `termux-setup-storage`
  command, which requests the permission and creates the `~/storage` symlink
  set.
- After granting, Termux continues to be a normal Android app: it can see only
  what Android lets it see.

## The `~/storage` symlink set

`termux-setup-storage` creates `$HOME/storage` (usually typed `~/storage`) and
populates it with symlinks into shared storage. The exact set depends on the
Termux version and the device; the commonly documented entries are:

| Symlink | Target |
|---------|--------|
| `~/storage/shared` | root of shared storage (`/storage/emulated/0`) |
| `~/storage/downloads` | Downloads |
| `~/storage/dcim` | DCIM |
| `~/storage/pictures` | Pictures |
| `~/storage/music` | Music |
| `~/storage/movies` | Movies |
| `~/storage/external-1` | Termux-private folder on external SD, if present |

**Version-sensitive:** newer Termux builds add further symlinks (for example
`~/storage/documents`, and external/media variants such as `external-0`,
`media-0`, `media-1`). Re-running `termux-setup-storage` wipes and rebuilds
the `~/storage` directory (with a confirmation prompt); it does not delete the
actual storage contents.

> **Note:** `~/storage` symlinks point into Android shared storage. Use them
> as the intended interface rather than typing `/storage/emulated/0/...`
> everywhere: the emulated path can change across Android/device generations.

## Android permission model by version

The dialog and menu you see depends on your Android version. **These paths are
version-sensitive and can differ by device manufacturer** — treat the exact
menu wording as approximate and follow what your device shows.

- **Android < 11:** `Settings > Apps > Termux > Permissions > Storage`
- **Android 11+:** `Settings > Apps > Termux > Permissions > Files and media`,
  grant "Allow management of all files"
- **Android 13+:** the same thing is also reachable under
  `Settings > Apps > Termux > (Advanced >) Special app access > All files
  access`

During setup, the permission you grant on Android 11+ is **"All files
access" (`MANAGE_EXTERNAL_STORAGE`)** — how the app asks for it depends on the
app version (see below).

> **Version-sensitive (Termux app version):** Termux app v0.118.x requests
> the *legacy* write-storage permission, which may not grant
> root-of-shared-storage access on every device/ROM (e.g. GrapheneOS storage
> scopes). The v0.119 development series requests "All files access"
> directly. On Android 15 with a v0.118.x app it is documented that you may
> need to grant "All Files Access" manually under
> `Settings > Apps > Termux > (Additional >) Special app access`. **If in
> doubt, check which permission the dialog on your device actually asks for.**

## Known problems

- **Android 11+ "Permission denied" after granting.** A known issue: access
  still fails after granting. The documented workaround is to **revoke and
  re-grant** the permission. This is an Android behavior, not a Termux bug.
- **Android 14:** `termux-setup-storage` may appear to do nothing or exit
  with status 255. The maintainer guidance is to install the `termux-am`
  package first (`pkg install termux-am`) and to check the new permission
  location. See termux-app issue #3647.
- **Android 13+ granular media labels.** On Android 13+, the "Files and media"
  screen may list granular categories such as "Photos and videos", "Music and
  audio", and "Files". (These categories relate to apps using media
  permissions.) For Termux, the operative permission remains the all-files
  path above; exact label wording on stock Android 14/15 is device-dependent.

## External SD and USB drives

- External SD and USB drives are generally **read-only** for apps.
- A Termux-private folder may exist on external storage at
  `Android/data/com.termux` (reached via `~/storage/external-1`/`external-0`),
  but it is **deleted when Termux is uninstalled**.

## Keeping things sane

- Keep your working files in internal `$HOME`, not on shared/external
  storage. Shared storage is slower, less reliable, and cannot hold
  executables (see [The Filesystem](03-filesystem.md) re: `noexec`).
- The Termux file picker over the Android Storage Access Framework (SAF) is
  available through `termux-storage-get` (requires the Termux:API add-on and
  the `termux-api` package; see
  [Termux Add-ons](../01-termux/07-add-ons.md)). Prefer this when you need to
  read/write a user-chosen arbitrary file without full "all files access".

## Unix permissions inside Termux

Inside `$PREFIX` and `$HOME` (app-private storage) the `/data` filesystem
supports full Unix permissions: `ls -l`, `chmod`, `chown`, `umask`, symlinks,
and special files all behave as on a normal Linux filesystem. Outside that
(private/shared storage) they largely do not. This is why scripts and
executables you download to `~/storage` may refuse to run, and why shell
scripts must live somewhere executable-capable or be run through an
interpreter (for example `bash ~/storage/script.sh`).

## References

- Research notes §3.6 (Storage access) and §3.7 last item (noexec):
  `research/termux/00-foundations-research.md`.
- termux-tools `scripts/termux-setup-storage.in`.
- termux-app issues: #3647, #4440, #4767, #3320 (permissions on Android
  11–15).