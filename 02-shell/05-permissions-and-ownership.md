# Permissions and Ownership

Android is a single-user system: every installed app runs as its own Linux
UID under one user, and a normal Termux session has **no root**. This chapter
documents `chmod`, `chown`, `chgrp`, `umask`, and what they do — and do not —
do on Android. Read the foundations
[Permissions and Storage](../00-foundations/04-storage-and-permissions.md) for
the model that drives these commands.

## Who are you?

```sh
id           # uid, gid, groups — known-working in a fresh install
whoami       # username (usually 'u0_aNNN' on Android)
```

- `id` is GNU coreutils. `whoami` is also GNU coreutils (verified live during
  the Phase 3 research audit) — it is one of the commands shipped by the Termux
  `coreutils` package; note coreutils deliberately omits `df`, `pinky`,
  `users`, `who`.
- `$HOME` is `/data/data/com.termux/files/home`, owned by your app's UID.
- `whoami` prints the bionic-derived user name for your app's uid (the
  `u0_aNNN`-style name that `id` shows); the numeric slot differs per device,
  the format is stable. In a root/adb context it prints `root`. [variable:
  the exact number is device-dependent]

## `chmod` — change permissions

```sh
chmod +x script.sh      # add execute (owner/group/other as applicable)
chmod 755 script.sh     # rwxr-xr-x — owner rwx, others rx
chmod 644 README.md     # rw-r--r--
chmod -R 755 dir/       # recursive
chmod u=rwx,g=rx,o=r file
```

- Termux coreutils include `chmod`, `chown`, `chgrp` (fresh install).
- **Execute permission matters** because scripts are run directly
  (`./script.sh`) from filesystems that honor it (`$HOME`, `$PREFIX`).
  External/shared storage is `noexec`, so even `chmod +x` does **not** make a
  file there executable.
- Symbolic (`u/g/o`, `+/=/`) and octal forms are interchangeable; `chmod` on
  Android is a normal filesystem operation on app-private storage.

## chmod on external/shared storage — ambiguous

On external storage (`~/storage`, `/sdcard`, `/storage/emulated/0`):

- The filesystem is a FAT32 **emulation** (sdcardfs/FUSE) whose contract does
  not support real POSIX permission bits in the normal sense.
- Android documents that *files do support modifications of file permissions
  or ownership attributes* in the shared-storage view — but the effective
  behavior (whether your `chmod`/`chown` sticks and what it means) is
  **device- and Android-version-dependent** and has historically varied.
  [variable] If a `chmod` there appears to "fail" or silently do nothing,
  that matches the filesystem's emulation, not a command bug.
- Practical rule: treat external storage as holding content, and keep
  executable/scripts in `$HOME`.

## `chown` / `chgrp` — change ownership

```sh
chown user:group file     # GNU chown syntax
chgrp group file
```

- **Without root you can only change ownership of files you own**, and on
  Android you generally **cannot** reassign a file to another UID at all from
  an unrooted app. These commands are documented for completeness and for
  root/adb/shizuku contexts. See
  [Privileged Access](../00-foundations/02-android-sandboxing.md).
- In a **proot-distro** container you can effectively `chown` guest files
  because the guest's `root` is mapped to your app UID, so `chown` behaves
  like root inside the guest.
- `chown` and `chgrp` are GNU coreutils (fresh install), as is `chmod`.

## `umask` — default permission mask

`umask` is a shell built-in. On an audited live Termux install the effective
default is **`0022`** (files created `644`, directories `755`); the shipped
`$PREFIX/etc/bash.bashrc` does not set a `umask` at all. [device variable —
an interactive user may set `umask` in `~/.bashrc`]

```sh
umask           # prints 0022
umask 0022      # reset to default
umask 077       # restrictive: files 600, dirs 700
```

- Files are created with `0666 minus umask` and directories `0777 minus
  umask` — the shell applies the mask, not the filesystem.

## setuid / setgid bits — mostly inert without root

- **setuid** (`chmod u+s`) does **not** grant extra privilege to app processes
  on Android: Android/SELinux restricts domain transitions, so a setuid bit you
  set on app-private files cannot make a binary run as root. Exact behavior is
  SELinux/kernel-governed and device-verified; treat it as non-functional for
  privilege gain. [device — behavior must be observed on a real device]
- Termux **forbids setuid/setgid** binaries in its repo for this reason.
- For actual privileged operation use the documented paths:
  [Privileged Access](../00-foundations/02-android-sandboxing.md).

## Filesystems and what they allow

| Location | Exec `+x` | Symlinks | chmod/chown honored |
|----------|-----------|----------|---------------------|
| `$HOME`, `$PREFIX` (app data, ext4) | yes | yes | yes |
| `~/storage`, `/sdcard` (FAT32 emulation) | **no** (`noexec`) | no | [variable] |
| `/` (root), `/system` | read-only, unrooted | read-only | no |

See [Storage and Permissions](../00-foundations/04-storage-and-permissions.md).

## Native Termux vs. proot

Inside proot-distro (Ubuntu etc.), `chmod`/`chown`/`chgrp`/`umask` come from
the guest's coreutils and apply to the guest's filesystem; because proot
maps guest root to your UID, `chown` of guest files works as the guest's
root without device root. Permissions on the shared **host** storage from
inside the guest still go through the host FAT32 emulation caveats above.

## Cross-references

- Paths and storage model:
  [The Filesystem](../00-foundations/03-filesystem.md),
  [Storage and Permissions](../00-foundations/04-storage-and-permissions.md)
- Real root/ADB/Shizuku/Porter paths:
  [Privileged Access](../00-foundations/02-android-sandboxing.md)
- Executing scripts: [Shell and Environment](../00-foundations/05-shell-and-environment.md)

## References

- Phase 3 research notes §4.5 (permissions), §5 (environment),
  §14 (audit log — default umask 0022, whoami/cat behaviors verified live):
  `research/commands/00-shell-command-bible-research.md`.
- Android shared storage (Documents & Files): developer.android.com
  (`StorageAccessFramework`, scoped storage, FUSE).