# Backup, Restore, and Reset

> **Read this whole chapter before running any of these commands.** All three
> commands modify or delete data inside `$PREFIX`. They are designed to work on
> Termux's own filesystem, not as general-purpose file tools.

## Scope of `$PREFIX` vs other data

`termux-backup` and `termux-restore` operate on **`$PREFIX` only** — the
packages, configuration, and databases of the Termux user-space. They do
*not* include `$HOME` (your personal files, `~/.bashrc`, `~/.termux/...`,
`~/storage`), and they never touch shared storage. To keep `$HOME` files, back
them up separately (for example a tar of `$HOME`).

## termux-backup

Back up `$PREFIX` to a TAR archive.

```sh
termux-backup <file>
```

- Archives **only `$PREFIX`** (stored under `usr/` inside the archive).
- `termux-backup -` writes an **uncompressed** tar to stdout.
- With a named file, compression is chosen **by the file extension**
  (`--auto-compress`), e.g. `.tar.gz`, `.tar.xz`.
- `-f` / `--force` overwrites an existing file.
- `--ignore-read-failure` continues despite read errors (an option for
  unusual file trees; use with care).

Examples:

```sh
termux-backup ~/storage/downloads/termux-backup-2026.tar.gz   # gzip by extension
termux-backup - > /tmp/termux-backup.tar                      # raw archive to stdout
```

> Store backups somewhere safe but remember: writing to `~/storage` keeps the
> archive inside shared storage — fine for exchange, but shared storage is
> `noexec`/less reliable for long-term retention. Prefer copying the archive
> off-device.

## termux-restore

Restore `$PREFIX` from a backup created by `termux-backup`.

```sh
termux-restore <file|->
```

- **Destructive:** restores all files in `$PREFIX` from the archive and
  **erases any files in `$PREFIX` that are not in the archive**
  (`--recursive-unlink --preserve-permissions`). Doing this over an existing
  setup removes packages and state you did not back up.
- **Refuses to run as root** (protects `/data` ownership and SELinux labels).
- Use `-` to restore from stdin.

> Prefer restoring after a clean install: reinstall the app so `$PREFIX` is
> fresh (or `termux-reset` first, below), then `termux-restore` the archive.
> Never restore over a newer/other installation expecting a merge — it is a
> wipe-and-replace operation.

## termux-reset

Wipe the Termux user-space back to a fresh state.

```sh
termux-reset
```

- Asks for confirmation (`y/n`).
- **Deletes everything under `$PREFIX`**: installed packages, package
  databases, system-wide config, and cache.
- **Keeps:** `$HOME` (your files and personal config), shared storage and
  external storage (audio files, documents, and so on), and preserves the
  `termux-am` APK so it can be used later.
- Kills remaining sessions when done.

> **Danger:** this command deletes a large amount of data with no undo. Only
> run it when you intend to start over, and take a
> `termux-backup` first if anything under `$PREFIX` matters to you.

## Which one should you use?

- Just installed and want a clean-after-churn state → `termux-reset`.
- Moving to a new device / reinstall → `termux-backup` on the old device,
  reinstall the app, `termux-restore` on the new one.
- Keep your own files (`$HOME`) → not covered by these tools; tar up `$HOME`
  yourself.

## References

- termux-tools `scripts/termux-backup.in`, `scripts/termux-restore.in`,
  `scripts/termux-reset.in`.
- Research notes §3.8: `research/termux/00-foundations-research.md`.