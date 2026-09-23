# Repository Maintenance and the Git Ecosystem

This chapter covers two things: keeping a repository healthy (maintenance
commands) and the Git-related packages available in `termux-main` beyond the
core `git` package. The package facts below are from the 2026-09-22
`termux-main` aarch64 index **[version-sensitive]**.

## Repository maintenance

Git repositories are self-maintaining for normal use, but occasionally you
want to verify integrity, compact storage, or recover from a mistake. Standard
Git commands apply on Termux:

```sh
git status                    # sanity check before invasive operations
git gc                        # compress objects/dangling refs (housekeeping)
git gc --prune=now            # aggressive: drop unreachable objects now (use with care)
git fsck                      # check object integrity
git reflog                    # the safety net: every HEAD move is logged
```

- **`git gc`** compacts object storage and prunes loose/redundant objects; it
  runs automatically from time to time, but you can run it when a repo feels
  slow or bloated. `--prune=now` drops unreferenced objects immediately —
  only after you are sure you do not need them.
- **`git fsck`** verifies repository integrity; run it to diagnose weird
  corruption errors (for example after copying a repo between devices).
- **`git reflog`** is your recovery tool — a commit "lost" by a bad reset or
  rebase is still reachable from the reflog for a while, so
  `git reflog` → `git reset --hard <sha>` recovers it. This is the cheap
  protection against destructive operations, which is why the Bible warns
  about `git push --force` and `git reset --hard` on shared branches
  ([The Basic Workflow](02-basic-workflow.md)).
- `.git` directories live inside the working tree like everywhere else; if
  `$HOME`-level config is involved, see
  [Git Installation and Setup](01-git-installation-and-setup.md).

## Git ecosystem packages in `termux-main`

All install alongside `git`; none rename or conflict with it.

| Package | Version (2026-09-22) | Notes |
|---------|----------------------|-------|
| `git-lfs` | 3.8.0 | Git Large File Storage; run `git lfs install` to configure filters |
| `git-credential-manager` | 2.9.1 | credential helper; DEPENDS `dotnet-host, dotnet-runtime-10.0` |
| `git-delta` | 0.19.2 | diff viewer (`delta`); DEPENDS `git, libgit2, oniguruma` |
| `lazygit` | 0.65.1 | terminal UI for Git; RECOMMENDS `git`; SUGGESTS `diff-so-fancy` |
| `gitui` | 0.28.1 | terminal UI; DEPENDS `libgit2, libssh2, openssl, zlib` |
| `git-extras` | 7.5.0 | extra commands; DEPENDS `bash, git, util-linux, gawk, findutils, ncurses-utils` |
| `git-annex` | 10.20260901 | large-file/annex workflow; RECOMMENDS `git, rsync, gnupg` |
| `git-crypt` | 0.8.0 | transparent encryption; DEPENDS `git, libc++, openssl` |
| `git-town` | 24.0.0 | branch-workflow tool |
| `git-absorb` | 0.9.0 | auto-fixup commits; DEPENDS `zlib` |
| `gitoxide` | 0.58.0 | Git in Rust; DEPENDS `resolv-conf` |
| `subversion` | 1.14.5-3 | legacy VCS |
| `fossil` | 2.28 | single-file DVCS + bug tracker |

Notable `[needs verification]` areas from the research: the exact
`git-credential-manager` helper recipe on Termux's dotnet runtime **[DEVICE]**,
and whether `git lfs install` needs any Termux workaround for its `~/.gitconfig`
writes **[DEVICE]**.

## Common additions in practice

### Git LFS

```sh
pkg install git-lfs
git lfs install                      # register the filters in ~/.gitconfig
git lfs track "*.zip"                # start tracking a pattern
git add .gitattributes               # the tracking patterns live here
git commit -m "add lfs tracking"
```

The `git-lfs` package installs the `git-lfs` binary; `git lfs install`
registers the smudge/clean filters for your user. Verify your install: after
`git lfs install`, `git lfs ls-files` shows tracked files once any exist.

### delta as the pager

```sh
pkg install git-delta
git config --global core.pager delta      # colored, side-by-side diffs in `git diff/log`
git config --global interactive.diffFilter "delta --color-only"   # for `git add -p`
```

### TUI clients

`lazygit` and `gitui` give full-screen, keyboard-driven Git UIs
(keybindings per each tool's README). Both are single packages, no special
Termux work required besides a color-capable terminal
([Networking and Developer Utilities](../08-power-tools/11-networking-and-developer-utilities.md)).

### git-credential-manager as a helper

If you prefer GCM over the options in
[HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md),
the package installs `git-credential-manager` under `$PREFIX/bin` with its
libraries under `$PREFIX/lib/git-credential-manager`, and the research notes a
recommended helper form along the lines of
`git config --global credential.helper "<path>/git-credential-manager github"`
— exact behavior on the dotnet runtime is unverified, so document it with that
caveat `[needs verification]` **[DEVICE]**.

## Native Termux vs. proot

Inside a proot-distro guest (Ubuntu/Debian), Git comes from the guest's
repositories and maintenance commands behave the same, but storage/patterns are
the guest's filesystem. A repository stays valid across environments because
`.git` is content-based — you can clone on Termux, of course, but do not mix
the two environments' Git config/credentials.

## Security notes

- `git gc --prune=now` and `git reset --hard` are destructive; always check
  `git status`/`git log` first, and lean on `git reflog` if you remove more
  than intended.
- `git-crypt` and `git-annex` both handle sensitive data patterns; with
  `git-crypt` your secrets are only as safe as the repo state mirroring ever
  was — make sure historical plaintext content was never pushed where it
  should not have been.
- Tools like `lazygit` show diffs and status of your whole working tree —
  verify what a repository contains before running them in an untrusted clone.

## Cross-references

- Dangerous-history changes discussed here pair with the workflows in
  [The Basic Workflow](02-basic-workflow.md).
- Token helpers: [HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md)
- delta's color paging shares requirements with the other
  color-capable tools: [Networking and Developer Utilities](../08-power-tools/11-networking-and-developer-utilities.md)

## References

- Phase 7 research notes §8:
  `research/development/00-git-github-research.md`.
- Package versions/deps verified against the `termux-main` (aarch64) index and
  `termux/termux-packages` build.sh files, fetched 2026-09-22; git commands
  are standard behavior per the git-scm manual.