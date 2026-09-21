# Archives and Compression

Compressing and archiving is a stable part of the shell workflow. This chapter
covers what is in a fresh install (`tar`, `gzip`, `bzip2`, `xz`, `unzip`) and
what you install when needed (`zip`, `7z`, `cpio`, `rsync`).

## In a fresh install

| Tool | Package | Notes |
|------|---------|-------|
| `tar` | tar | GNU tar 1.35 |
| `gzip`, `gunzip` | gzip | |
| `bzip2`, `bunzip2` | libbz2 (bzip2) | |
| `xz`, `unxz`, `xzcat` | xz-utils | |
| `unzip` | unzip | creating zips requires `zip` (not installed) |
| `zip` | — | **not installed** — `pkg install zip` |
| `7z` | — | **not installed** — `pkg install 7zip` (no `p7zip`) |
| `cpio` | — | **not installed** — `pkg install cpio` |
| `rsync` | — | **not installed** — `pkg install rsync` |

## `tar` — the standard archive

GNU tar in the fresh install.

```sh
tar -czf backup.tar.gz ~/src      # create gzip-compressed archive
tar -xjf big.tar.bz2              # extract bzip2 archive
tar -xJf big.tar.xz               # extract xz archive
tar -tf archive.tar.gz            # list contents without extracting
tar -xvf archive.tar.gz -C /dest  # extract into /dest
tar -czvf a.tgz dir/              # verbose create
```

- `-c` create, `-x` extract, `-t` list, `-z` gzip, `-j` bzip2, `-J` xz,
  `-C` change directory.
- `tar` handles `.tar`, `.tar.gz`/`.tgz`, `.tar.bz2`, `.tar.xz` based on the
  flags you give it; it does **not** handle `.zip` (use `zip`/`unzip`).
- GNU tar auto-detects the compression of **existing** archives on extract if
  you omit the flag — but naming and `-z/-j/-J` flags remain the documented
  way to be explicit.

## `gzip` / `bzip2` / `xz` — compress a single file

```sh
gzip file.txt                # -> file.txt.gz (removes the original)
gunzip file.txt.gz           # restores file.txt
gzip -k file.txt             # keep the original (-k, GNU)
bzip2 -z file.txt            # -> file.txt.bz2 (better ratio, slower)
xz -z file.txt               # -> file.txt.xz (best ratio)
xz -d file.txt.xz            # decompress
xz -t file.txt.xz            # test integrity
```

- Reading compressed files: `zcat` reads gzip; `xzcat` reads xz; use
  `bzip2 -dc file.bz2` for bzip2.
- These tools compress a **single file**; use `tar` first to bundle multiple
  files, then compress: `tar -cf - dir/ | xz -9 > dir.tar.xz`.

## `zip` / `unzip` — ZIP archives

`unzip` is installed; `zip` is not.

```sh
pkg install zip
zip archive.zip file1 file2 dir/     # create
zip -r archive.zip dir/              # recursive
unzip archive.zip                    # extract
unzip -l archive.zip                 # list contents without extracting
unzip archive.zip -d /target         # extract into /target
```

- ZIP is the interoperable format for sharing with Windows/Android apps;
  permissions encoded in ZIP entries are translated to the emulated
  filesystem on extract, and extracted files inherit the 
  external-storage `noexec` caveat when written there (see
  [Permissions and Ownership](05-permissions-and-ownership.md)). Keep
  executables in `$HOME`.

## `7z` — 7-Zip

```sh
pkg install 7zip        # package name is '7zip'; there is NO 'p7zip'
7z a arch.7z dir/       # create
7z x arch.7z            # extract
7z l arch.7z            # list
```

## `cpio` — POSIX archive format (install)

```sh
pkg install cpio
find . -print0 | cpio -0o > backup.cpio     # create
cpio -it < backup.cpio                      # list
cpio -id < backup.cpio                      # extract
```

CPIO is used by several kernel/initramfs and packaging workflows; you will
rarely need it interactively but it is the historical peer of tar. The
`cpio` package provides the standard GNU cpio. 

## `rsync` — sync and copy efficiently (install)

```sh
pkg install rsync
rsync -av src/ dest/            # mirror directory trees
rsync -av --delete src/ dest/   # also delete files absent in src — DESTRUCTIVE at dest
rsync -avz user@host:/path/ ./  # over ssh
```

- `-a` archive (recursive, preserve times/perms), `-v` verbose, `-z`
  compress over the network.
- Local `rsync` works fine between `$HOME` locations; to external storage
  remember the FAT32-emulation permission caveats
  ([Permissions and Ownership](05-permissions-and-ownership.md)).

## Compression interop with pagers and searches

- To view a compressed file with `less`:
  `gunzip -c file.gz | less` (or `xzcat file.xz | less`).
- Piping compressed data into searches: `zcat file.gz | grep pattern`;
  `xzcat file.xz | grep pattern`.
- `zgrep` (gzip package, in the fresh install) greps compressed files
  directly: `zgrep pattern file.gz`. `zegrep` accepts extended regex.

## Native Termux vs. proot

In a proot-distro Ubuntu, `tar`/`gzip`/`bzip2`/`xz` match the distro's
versions; `rsync` and `7z` package names may differ, and the guest's common
file list is not the same as Termux's. See
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Cross-references

- Viewing files: [Viewing and Editing Files](02-viewing-and-editing-files.md)
- Finding files: [Filesystem and Navigation](01-filesystem-and-navigation.md)
- Using these in package install flow:
  [Package Management](../01-termux/02-package-management.md)

## References

- Phase 3 research notes §4.6 (archives/compression), §8 (install list):
  `research/commands/00-shell-command-bible-research.md`.
- GNU tar manual: <https://www.gnu.org/software/tar/manual/>