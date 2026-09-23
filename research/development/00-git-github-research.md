# Git & GitHub (incl. GitHub CLI) — Research Notes (Phase 7)

Status: research notes supporting Phase 7 "Power Tools and Development" (PLAN.md
§2 items 26–27, §12, §14 sections on SSH servers/remote access/development
environments, and §15 "Git and GitHub"). Not polished documentation. Kept
separate from Bible chapters per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research was performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Anything
that requires a live device to confirm is tagged **[DEVICE]**; Android/Termux
or tool-version-dependent items are tagged **[version-sensitive]**; OEM
behavior is tagged **[OEM]**; anything not conclusively verified is flagged
`[needs verification]`.

Audit note: package names/versions were verified against the **current
`termux-main` repository index** (`binary-aarch64/Packages`, fetched
2026-09-22) and against **`termux/termux-packages` master `build.sh` files**
(fetched 2026-09-22 from raw.githubusercontent.com). Git behavior was checked
against the git-scm.com `git-config` man page for **git 2.55.0** and against
official GitHub documentation. Nothing was copied from memory-only
recollection; items that could not be verified are marked.

Cross-reference: SSH keys and SSH-based authentication/signing are researched
in `research/development/01-ssh-research.md` and referenced here where
relevant.

---

## 1. Scope

Phase 7 Git/GitHub topics (PLAN.md §15): Git installation; repository
initialization; cloning; remotes; branches; commits; merging; rebasing; pull
requests; tags; releases; GitHub CLI; authentication; HTTPS authentication;
SSH authentication; SSH keys; commit signing; verified commits; GitHub
Actions; repository maintenance. This file adds: what the Termux `git` and
`gh` packages are built from (authoritative packaging facts), how Git behaves
under Termux defaults (editor/pager, completion, credential helpers), commit
signing configuration (`gpg.format`), and the surrounding Git ecosystem
packages available in `termux-main` (LFS, credential manager, delta, lazygit,
gitui, git-extras, git-annex, git-crypt, git-town, git-absorb, gitoxide,
fossil, subversion).

Environment distinction (AGENTS.md §6/§7): Termux's `$PREFIX` is normally
`/data/data/com.termux/files/usr`; `$HOME` is
`/data/data/com.termux/files/home`. Git config and SSH files live under
`$HOME` unless overridden. None of this is interchangeable with root, ADB
shell, or proot paths.

## 2. Source Inventory and Reliability Ranking

Ranking per AGENTS.md §3.2 (A = official project documentation/source).

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `termux-main` repository index `dists/stable/main/binary-aarch64/Packages` (3000 packages; package versions used throughout) | A | packages.termux.dev |
| A2 | `termux/termux-packages` master `packages/git/build.sh` | A | raw.githubusercontent.com |
| A3 | `termux/termux-packages` master `packages/gh/build.sh` | A | raw.githubusercontent.com |
| A4 | `cli/cli` `docs/install_linux.md` ("Android" section: GitHub CLI Termux community support) | A | raw.githubusercontent.com |
| A5 | git `git-config(1)` man page (git 2.55.0, 2026-06-29): `gpg.format`, `gpg.ssh.program`, `user.signingKey`, `commit.gpgSign`, `tag.gpgSign`, `gpg.ssh.allowedSignersFile`, `gpg.ssh.defaultKeyCommand`, `credential.helper`, `core.editor`, `user.name/user.email` | A | git-scm.com |
| A6 | GitHub docs "About commit signature verification" | A | docs.github.com |
| A7 | GitHub docs "About SSH" | A | docs.github.com |
| A8 | `termux/termux-packages` master `packages/npm/build.sh` + `packages/nodejs/build.sh` (npm bundling history) | A | raw.githubusercontent.com |
| A9 | `termux/termux-packages` master `build.sh` for git-lfs, git-credential-manager, opkssh, git-delta, lazygit, gitui, git-annex, git-crypt, git-extras, git-town, git-absorb, gitoxide, fossil, subversion | A | raw.githubusercontent.com |
| A10 | GitHub CLI manual `gh auth login` (auth methods: web, device, token) | A | cli.github.com |

## 3. Git Package (termux-main)

Verified from [A1][A2].

- Package: `git`; current version 2.55.0 (aarch64 index). No bundled GUI; the
  package installs the standard `git` CLI plus **bash** completion and prompt
  scripts (verified in the termux-main Contents index:
  `git-completion.bash`, `git-prompt.sh` under `$PREFIX/etc/bash_completion.d/`).
  No zsh completion file is shipped by the `git` package itself.
- Depends on: `libcurl, libexpat, libiconv, less, openssl, pcre2, zlib`.
  `libcurl` provides HTTPS transport (git's `git-remote-https`). The build
  enforces that `git-remote-https` exists, i.e. HTTPS remotes are supported.
- Recommends: `openssh`. Suggests: `perl` (needed for `git add -p` full
  features and some helper commands; Termux builds git WITHOUT a bundled
  Perl dependency — `perl` is only a suggestion).
- Build-time specifics (from build.sh, worth documenting as Termux behavior):
  - `NO_GETTEXT=1` (no gettext in Termux), `USE_LIBPCRE2=1` (regex via PCRE2),
    `NO_NSEC=1`.
  - `INSTALL_SYMLINKS=1` (hardlinks replaced by symlinks), `CSPRNG_METHOD=openssl`.
  - `DEFAULT_PAGER=pager` and `DEFAULT_EDITOR=editor` — git is **compiled** so
    that, when no pager/editor is configured by the user, it invokes the
    commands `pager` and `editor` (rather than `less`/`vi`). Important caveat:
    as of the 2026-09-22 `termux-main` (aarch64) Contents index, **no package
    ships `$PREFIX/bin/pager` or `$PREFIX/bin/editor`** — so on a fresh install
    `git commit`/`git log` without `core.editor`/`core.pager` (or
    `GIT_EDITOR`/`EDITOR`/`PAGER`) will fail to find the fallback command.
    Users should set `core.editor`/`core.pager` explicitly. `[needs verification]`
    whether the Termux app or a later Termux-tools release provides these
    helpers.
  - `--with-shell=$PREFIX/bin/sh`, `--with-tcltk=$PREFIX/bin/wish`.
  - The build runs `termux_setup_rust` and exports `CARGO_BUILD_TARGET` in
    `termux_step_pre_configure` (purpose not explained in build.sh — likely for
    upstream git's optional Rust components; do not over-attribute to
    "gitoxide-backed features" without a source).
- Installs bash completion to `$PREFIX/etc/bash_completion.d/`:
  `git-completion.bash` and `git-prompt.sh`. Global `core.excludesfile` and
  user setup are left to the user after install.
- The `git` package does **not** install credential helpers; Git's default is
  on-terminal prompt for HTTPS credentials. See §6.

## 4. Git Configuration Notes (git 2.55.0 semantics)

Verified from [A5]. Configuration is standard Git; the values below are the
ones most relevant to Termux/GitHub use:

- `user.name` / `user.email` — set the author and committer fields. There is
  no Termux-specific default; the user must set them (e.g.
  `git config --global user.name "..."` / `git config --global user.email ...`).
- `core.editor` — used by `commit`/`tag` when `GIT_EDITOR` is not set. Git's
  selection order is `$GIT_EDITOR` → `core.editor` → `$VISUAL` → `$EDITOR` →
  the compiled-in default; on this Termux build the compiled-in default is the
  command `editor` (see §3), so without any configuration `git commit` tries
  `editor` and fails if none exists. Users normally set `core.editor` to one of
  the editors in
  `research/development/03-build-dev-tools-editors-databases-research.md`.
- `credential.helper` — external helper consulted when a username/password is
  needed; multiple helpers may be defined; helpers may be absolute paths or
  `!`-prefixed shell commands. On Termux there is no OS keyring by default,
  so common choices are Git's built-in `cache` (memory, temporary) or
  `store` (plaintext `$HOME/.git-credentials`), the `gh` helper
  (§7), or `git-credential-manager` (available as a Termux package, §8).
- Commit/tag signing defaults: `gpg.format = openpgp` by default; `commit.gpgSign`
  and `tag.gpgSign` are opt-in booleans (`git commit -S` / `git tag -s` do it
  per-command). For signing with SSH keys see `research/development/01-ssh-research.md`
  §6.
- `gpg.program` defaults to `gpg` (GPG package in Termux: see
  `01-ssh-research.md`); when `gpg.format=ssh` the signing program defaults to
  `ssh-keygen` (`gpg.ssh.program`).

## 5. Termux-specific Git Packaging Facts

- Git HTTPS/SSH both work out of the box after installing `git` (+ `openssh`
  recommended): `git clone https://...`, `git clone git@github.com:...`.
- Completion: add `source $PREFIX/etc/bash_completion.d/git-completion.bash`
  (or use `bash-completion` package) and optionally the prompt from
  `git-prompt.sh`.
- No `git` config is created by the package; first-use identity is required.
- Git LFS is a separate package (`git-lfs`, §8). Installing `git-lfs` plus
  running `git lfs install` per-user is the documented workflow
  ([needs verification] of exact postinst behavior — the Termux git-lfs
  package only installs the binary, `git lfs install` registers the filter).

## 6. HTTPS Authentication & Credentials on Termux

Verified [A10] + [A5], practical on-device behavior [DEVICE].

- Without a credential helper, `git push`/`git fetch` over HTTPS prompts once
  per command; on Android the prompt is terminal input, and tokens typed there
  are not stored. Users typically either:
  - enable Git's `store` helper (plaintext `~/.git-credentials` — warn that
    this stores tokens in clear text in the Termux data dir), or
  - use `gh auth login --git-protocol https` which configures `gh` as the
    credential helper (§7), or
  - use SSH remotes (recommended, see `01-ssh-research.md`).
- GitHub no longer accepts account passwords for Git operations; tokens
  (fine-grained or classic PAT), SSH keys, or device-based `gh` auth are the
  supported paths (verified: GitHub docs/gh manual; token requirements are
  [needs verification] for exact 2026 policy wording).

## 7. GitHub CLI (`gh`)

Verified from [A3][A4][A10].

- Package: `gh` (version 2.101.0). There is **no** `github-cli` package; the
  official name is `gh`. Installed via `pkg install gh`.
- The upstream `cli/cli` project officially lists Termux as a supported Android
  channel: "The GitHub CLI package is supported by the Termux community with
  updates powered by termux/termux-packages" [A4].
- Termux build specifics [A3]: built from source (`cli/cli`) with Go;
  `RECOMMENDS openssh` (SSH flows); postinst generates bash/zsh/fish
  completions via `gh completion` into `$PREFIX/share/bash-completion/
  completions/gh.bash`, `$PREFIX/share/zsh/site-functions/_gh` and
  `$PREFIX/share/fish/vendor_completions.d/gh.fish` (NOT
  `$PREFIX/etc/bash_completion.d/`).
- **Dependencies**: needs `git` for most repository operations (the `gh`
  package itself does not vendor git). Install order `pkg install git gh` is
  the practical baseline [DEVICE].
- **Authentication** (`gh auth login`, [A10]):
  - Web/browser flow (the **default authentication mode** per the gh manual):
    `gh auth login` opens/points to a browser to complete the OAuth
    handshake. On a device without a registered browser, gh shows a one-time
    code and a URL; `gh auth login --web --clipboard` copies the one-time
    OAuth device code to the clipboard. Practical Termux usage is the device
    flow: one-time code printed/ copied, completed from any browser on
    another device [DEVICE] [needs verification].
  - Token flow: `gh auth login --hostname github.com --with-token < file`
    reads a PAT (classic) from standard input. There is **no**
    `-t`/`--token` flag on `gh auth login` (verified against the gh manual);
    the manual recommends `GH_TOKEN` environment for fine-grained PATs. For
    git-protocol and host selection use `-p/--git-protocol {ssh|https}` and
    `-h/--hostname`.
  - Credential storage: gh stores the token in the system credential store
    when one is found; otherwise it **falls back to writing the token to a
    plain text file** ("See gh auth status for its stored location"; on
    Termux that is normally `$HOME/.config/gh/hosts.yml`). `--insecure-storage`
    forces plaintext. Warn accordingly [security note per AGENTS.md §11].
- **Git integration**: `gh auth setup-git` configures `credential.helper` to
  use gh for github.com HTTPS. `gh repo clone`, `gh pr create`, `gh release
  create`, etc., all operate through git.
- **GitHub Actions**: usable from Termux for triggering/managing workflows
  (`gh workflow run`, `gh run watch`). Running workflows/self-hosted runners
  from Termux is beyond Phase 7 research scope (runners are a separate topic;
  mark as [needs verification] if pursued in a later phase).

## 8. Git Ecosystem Packages Available in termux-main

All versions verified against [A1][A9] (aarch64 index). None of these renames
the `git` package; install alongside `git`.

| Package | Version | Notes (from build.sh/index) |
|---|---|---|
| `git-lfs` | 3.8.0 | Git Large File Storage; installs `bin/git-lfs`; run `git lfs install` to configure filters |
| `git-credential-manager` | 2.9.1 | DEPENDS `dotnet-host, dotnet-runtime-10.0`; installs to `$PREFIX/lib/git-credential-manager`, `git-credential-manager` in `$PREFIX/bin`; configure with `git config --global credential.helper "<path>/git-credential-manager github"` [needs verification] |
| `git-delta` | 0.19.2 | Diff viewer (`delta`); DEPENDS `git, libgit2, oniguruma`; pager: `git config --global core.pager delta` |
| `lazygit` | 0.65.1 | TUI; RECOMMENDS `git`; SUGGESTS `diff-so-fancy` |
| `gitui` | 0.28.1 | TUI; DEPENDS `libgit2, libssh2, openssl, zlib` |
| `git-extras` | 7.5.0 | Extra git commands; DEPENDS `bash, git, util-linux, gawk, findutils, ncurses-utils`; RECOMMENDS `curl, procps, rsync` |
| `git-annex` | 10.20260901 | Large-file/annex workflow; DEPENDS `botan3, zlib, libandroid-posix-semaphore, libandroid-utimes, libffi, libiconv, libgmp, libmagic, libsqlite`; RECOMMENDS `git, rsync, gnupg` |
| `git-crypt` | 0.8.0 | Transparent encryption; DEPENDS `git, libc++, openssl` |
| `git-town` | 24.0.0 | Git workflow tool (branch operations) |
| `git-absorb` | 0.9.0 | Auto-fixup commits; DEPENDS `zlib` |
| `gitoxide` | 0.58.0 | Git in Rust (`cargo` alternative); DEPENDS `resolv-conf` |
| `gh` | 2.101.0 | GitHub CLI, §7 |
| `subversion` | 1.14.5-3 | DEPENDS `apr, apr-util, serf, libexpat, libsqlite, liblz4, utf8proc, zlib, libmagic` |
| `fossil` | 2.28 | Single-file DVCS + bug tracker; DEPENDS `openssl, zlib` |

`opkssh` (0.16.0, OpenPubkey SSH) is covered in `01-ssh-research.md`.

## 9. Unresolved / Device-Verified Items

- Whether `$PREFIX/bin/pager` and `$PREFIX/bin/editor` exist in any Termux
  app/release build (absent from termux-main 2026-09-22) and what git's
  default fallback failure looks like on a device **[DEVICE]** `[needs verification]`.
- `gh` browser flow behavior on a physical device without a default browser
  **[DEVICE]**.
- git-credential-manager helper recipe on Termux dotnet runtime **[DEVICE]**.
- Whether `git lfs install` needs any Termux workaround (`~/.gitconfig`
  writes) **[DEVICE]**.
- GitHub PAT/policy wording current as of 2026 `[needs verification]` (rated
  against gh 2.101.0 behavior).