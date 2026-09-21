# Filesystem and Navigation

Working with files is the most common shell task. This chapter covers moving
around the filesystem and the basic file operations you will use constantly.
It assumes native Termux; for the path model itself (what `$HOME`, `$PREFIX`,
`/data`, `~/storage`, and `/sdcard` actually are) see
[The Filesystem](../00-foundations/03-filesystem.md) before going further.

Everything here except `file`, `tree`, `which`, and `locate` is in a fresh
install (see the provenance table in the
[section introduction](00-intro.md)).

## `pwd` — where am I?

`pwd` prints the current working directory.

```sh
pwd
# /data/data/com.termux/files/home
```

`pwd` is a bash built-in and also a GNU coreutils program; either way `pwd`
works identically. With `pwd -L` bash prints the logical (symlink) path;
`pwd -P` prints the physical path with symlinks resolved.

## `cd` — change directory

`cd` is a bash built-in, not a program.

```sh
cd /sdcard            # absolute path
cd ~                  # home directory
cd ..                 # parent directory
cd -                  # previous directory (prints it; repeat to toggle)
cd ~/storage/downloads
cd $PREFIX/bin
```

- `cd` with no argument goes to `$HOME`.
- `cd -` switches back to the previous directory.
- Relative paths resolve against the current directory.

`cd` and `pwd` determine your working directory for everything that follows;
many "file not found" bugs are just being in the wrong place. `ls` first.

## `ls` — list files

`ls` is GNU coreutils in Termux. In a fresh install **output is not
colorized** by default (no `ls` alias or `LS_COLORS` is configured by the
shipped shell startup files). Use `ls --color=auto` if you want colors, or add
an alias in `~/.bashrc`.

```sh
ls                # short listing of the current directory
ls -l             # long listing: permissions, owner, size, mtime
ls -a             # include dotfiles
ls -la $HOME      # combined long + all
ls -R             # recursive
ls -h             # human-readable sizes ("with -l")
ls --color=auto   # colorize
```

`ls` of the external/shared storage (see `~/storage` note below) shows the
emulated-FAT view: every file appears owned by you, case-insensitive names,
no real symlinks.

## `mkdir` / `rmdir` — create / remove directories

```sh
mkdir projects                 # create one directory
mkdir -p a/b/c                 # create parents as needed
rmdir emptydir                 # remove an EMPTY directory only
mkdir -p "$HOME/a/b" && rmdir "$HOME/a/b"   # remove just the innermost
```

Use `rmdir` for empty directories; to remove a directory *with* contents use
`rm -r` (see below — it is destructive).

## `touch` — create empty file / update timestamps

```sh
touch newfile          # creates an empty file if it does not exist
touch existing         # updates the modification time otherwise
touch -t 202601010000 file   # set a specific timestamp (GNU touch)
```

Common use: quickly create placeholder files, or force `make`/build scripts to
see a file as changed.

## `cp` — copy

```sh
cp source.txt dest.txt       # copy one file
cp -r dir /tmp/backup        # copy a directory recursively
cp -i a b                    # prompt before overwriting
cp -n a b                    # do not overwrite existing destination
cp -v a b                    # verbose: say what was copied
cp a.txt ../x.txt "$HOME"    # multiple sources into a directory
cp -a dir newdir             # recursive, preserve permissions/times
```

`cp` overwrites silently by default — use `cp -i` when you want safety on
every overwrite.

## `mv` — move / rename

```sh
mv oldfile newfile       # rename
mv file dir/             # move into a directory
mv -i a b                # prompt before overwriting
mv -n a b                # do not overwrite
mv dir1 dir2             # rename or move a directory
```

`mv` across filesystems copies then deletes; within one filesystem it is a
rename (fast, atomic).

## `rm` — remove (destructive)

```sh
rm file.txt          # remove one file
rm -r dir/           # remove a directory and its contents recursively
rm -f path           # ignore nonexistent files, never prompt
rm -rf dir/          # commonly combined — DESTRUCTIVE
```

> **Warning:** `rm -rf` removes anything it is pointed at with no undo. Termux
> has no trash mechanism by default. Double-check the path; a typo like
> `rm -rf ~ /` vs `rm -rf ~/` is irreversible. Prefer `rm -i` interactively and
> keep backups of anything you cannot afford to lose. See also
> [Permissions and Ownership](05-permissions-and-ownership.md) for the
> related security guidance.

## `ln` — links

```sh
ln -s target linkname        # soft/symbolic link
ln target hardlink           # hard link (same inode) — NAME_MAX/type limits on some fs
```

- **Symbolic links** (`ln -s`) are the common type; they can point anywhere.
- Within app-private storage (`$HOME`, `$PREFIX`) symlinks behave normally.
- On **external/shared storage** (`~/storage`, `/sdcard`) hard and soft
  symlinks **cannot be created** (the FAT-emulating mount does not support
  them). This is why `~/storage` itself is created as a symlink set by
  `termux-setup-storage` in internal storage — see
  [Storage and Permissions](../00-foundations/04-storage-and-permissions.md).

## `find` — search the filesystem

`find` is from findutils (in the fresh install).

```sh
find . -name '*.log'          # by name (glob)
find $HOME -type f            # files only
find $PREFIX -maxdepth 4 -type d -name Cache   # dirs named Cache (scoped, to stay fast)
find . -maxdepth 2 -name x    # limit depth
find . -size +10M             # files larger than 10 MiB
find . -mtime -7              # modified in the last 7 days
find . -fstype ext4           # only on a given filesystem type
find . -name '*.tmp' -delete  # delete matches — DESTRUCTIVE
```

- `-type f` (regular files), `-type d` (directories), `-type l` (symlinks).
- **Termux build detail:** `-fstype` works from `/proc/self/mountinfo`, so
  filesystem-type matching is available even though the unrooted app cannot
  read every mount.
- Piping `find` output into `xargs` or into `-exec` is common; prefer
  `find . -name '*.log' -print0 | xargs -0 rm -f` for names with spaces.

## `locate` / `updatedb` — fast name search (install)

`locate` is **not** in the fresh install.

```sh
pkg install mlocate
updatedb                  # build the index first (see note)
locate mysql              # find every path containing 'mysql'
```

- The database lives at `$PREFIX/var/mlocate/mlocate.db`.
- `updatedb` must be run (again) before `locate` finds new files; there is no
  background indexer in a default install.

## `xargs` — build and run commands from input

`xargs` reads items from standard input (often `find` or `ls` output) and runs
a command on batches of them.

```sh
find . -name '*.bak' -print0 | xargs -0 rm       # delete matches safely
ls *.txt | xargs -n 1 printf 'file: %s\n'        # one argument at a time
printf 'one two three\n' | xargs                  # runs: one two three (as one command)
```

- The `-0`/`-print0` pairing correctly handles filenames with spaces.
- `xargs` is in the fresh install with `find` (findutils).

## `df` — disk usage by filesystem (Android wrapper)

`df` in native Termux is **not** GNU coreutils' `df`. The coreutils build
deliberately excludes `df` ("let system binary prevail"), and `termux-tools`
provides a wrapper that executes the Android system `df` (toybox) at
`/system/bin/df`.

```sh
df -h $HOME              # human-readable sizes for the app data filesystem
df -h /                  # the root (read-only) filesystem view
df -h /sdcard            # shared storage
```

The wrapper unsets `LD_LIBRARY_PATH`/`LD_PRELOAD` and runs the real system
binary, so **output shape and options are those of the Android toybox `df`
on your device, not GNU df** — [variable]. `-h` for human-readable sizes is
widely supported. See
[Termux Utilities](../01-termux/06-utilities.md) for the wrapper mechanism.

## `du` — disk usage by directory

`du` is GNU coreutils (in the fresh install).

```sh
du -sh $HOME            # total size of the home directory, human-readable
du -sh *                # per-item sizes in the current directory
du -h --max-depth=1 $HOME
```

`s` = summary, `h` = human-readable sizes.

## `file` — identify file types (install)

`file` is **not** in the fresh install; it is the `file` subpackage of
`libmagic`.

```sh
pkg install file
file mystery.bin        # prints the detected format
file -z archive        # detect inside compressed files
```

## `tree` — directory tree (install)

```sh
pkg install tree
tree -L 2 $PREFIX/lib   # tree limited to depth 2
tree -a ~/src           # include dotfiles
```

## `mktemp` and temporary files

`mktemp` (GNU coreutils) creates a safe unique filename; prefer it over
hard-coded temp paths in scripts.

```sh
tmp=$(mktemp)                 # e.g. /data/data/com.termux/files/usr/tmp/tmp.XXXX
tmpdir=$(mktemp -d)           # create a directory instead
```

## External storage caveats

Shared/external storage (`~/storage`, `/sdcard`, `/storage/emulated/0`) is
mounted as a **FAT32-emulating** filesystem (via `sdcardfs` or FUSE, depending
on Android version) with special properties:

- **`noexec`** — you cannot execute files directly from there; run scripts
  through an interpreter (`bash ~/storage/script.sh`) or keep them in `$HOME`.
- **No symlinks** — `ln -s` fails on external storage.
- **Case-insensitive** filenames — `foo`, `FOO`, and `Foo` are the same file.
- Permissions/ownership semantics there are **device-dependent and
  ambiguous** (see [Permissions and Ownership](05-permissions-and-ownership.md)).

Keep active work in `$HOME` or `$PREFIX`. See
[Storage and Permissions](../00-foundations/04-storage-and-permissions.md).

## Native Termux vs. proot

Inside a proot-distro distribution (e.g. Ubuntu), these commands come from
that distro's own coreutils and follow FHS paths; `cd`/`pwd` semantics, `ls`,
`cp`, `mv`, `rm`, `find` are the same GNU tools in the common cases, but `df`
is the distro's GNU `df` (not the Android wrapper) and `locate` may be a
different implementation or absent. See
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Cross-references

- Filesystem/path model: [The Filesystem](../00-foundations/03-filesystem.md)
- Storage and `~/storage`: [Storage and Permissions](../00-foundations/04-storage-and-permissions.md)
- Permissions and ownership: [Permissions and Ownership](05-permissions-and-ownership.md)
- Archives: [Archives and Compression](06-archives-and-compression.md)
- `pkg install`: [Package Management](../01-termux/02-package-management.md)

## References

- Phase 3 research notes §4.1 (filesystem commands), §4.5 (permissions),
  §5 (external storage), §9 (device checklist):
  `research/commands/00-shell-command-bible-research.md`.
- GNU coreutils manual: <https://www.gnu.org/software/coreutils/manual/>
- Android `/system/bin` tool behavior is device/Android-version dependent.