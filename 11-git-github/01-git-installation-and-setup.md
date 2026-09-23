# Git Installation and Setup

Git in Termux is the standard Git command-line tool compiled for Android
(there is no bundled GUI and no separate gitk-style helper; it is the `git`
binary plus some shell pieces).

## Install

```sh
pkg install git openssh      # openssh is a RECOMMEND of git; pull it now
git --version                # git version 2.55.0 (aarch64 index, 2026-09-22) [version-sensitive]
```

Facts about the package (verified against `termux-main` and
`termux/termux-packages` `packages/git/build.sh`, fetched 2026-09-22):

- **DEPENDS:** `libcurl, libexpat, libiconv, less, openssl, pcre2, zlib`.
  `libcurl` provides the HTTPS transport; the build enforces that
  `git-remote-https` exists, so **HTTPS remotes work out of the box**.
- **RECOMMENDS `openssh`** — SSH remotes (`git@github.com:…`) work once you
  have keys (see [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)).
- **SUGGESTS `perl`** — needed for the full features of `git add -p` and some
  helper commands. Termux builds Git **without** a bundled Perl; install `perl`
  if you rely on those.
- Build-time behavior you can feel: regex via **PCRE2**, `NO_GETTEXT=1`, and
  `INSTALL_SYMLINKS=1` (helper binaries are symlinks). `gpg.program` defaults
  to `gpg` (from the `gnupg` package if installed).

## The editor and pager quirk (read this)

The Termux `git` is **compiled** with `DEFAULT_PAGER=pager` and
`DEFAULT_EDITOR=editor`. That means: when you have configured nothing, `git
commit`/`git log` try to run commands named `pager` and `editor`.

As of the 2026-09-22 `termux-main` (aarch64) index, **no package ships
`$PREFIX/bin/pager` or `$PREFIX/bin/editor`**, so on a fresh install
`git commit`/`git log` without further configuration will fail to find the
fallback command. `[needs verification]` whether the Termux app or a later
`termux-tools` release provides these helpers **[DEVICE]**.

Set an editor and pager explicitly:

```sh
git config --global core.editor nano        # or: vim, nvim, emacs, micro, helix
git config --global core.pager less
# environment variables work too: GIT_EDITOR, EDITOR, GIT_PAGER, PAGER
```

Git's selection order for the editor is `$GIT_EDITOR` → `core.editor` →
`$VISUAL` → `$EDITOR` → compiled-in default (`editor`); the settings above
cover you.

## First-use identity

The package creates **no** Git configuration; run `.gitconfig` setup yourself.
Global config lives in `$HOME/.gitconfig`.

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --list --show-origin        # see where configuration comes from
```

`user.name`/`user.email` set the author and committer fields; there is no
Termux-specific default. (If you sign commits, also see
[Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md).)

## Completion and prompt

The `git` package ships completion and prompt scripts to
`$PREFIX/etc/bash_completion.d/`:

- `git-completion.bash` — command/option completion.
- `git-prompt.sh` — the `__git_ps1` prompt helper.

Enable them for the interactive bash session:

```sh
source $PREFIX/etc/bash_completion.d/git-completion.bash
source $PREFIX/etc/bash_completion.d/git-prompt.sh
```

(persist by adding the `source` lines to `~/.bashrc`). The `bash-completion`
package also activates these globally in `$PREFIX/etc/bash_completion.d/`. The
`git` package itself ships **no zsh** completion file.

## HTTPS remotes without configuration

Users who set nothing else still get working HTTPS clones:

```sh
git clone https://github.com/termux/termux-app.git
```

Authentication on `push` is the separate topic of
[HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md).

## Native Termux vs. proot

Inside proot-distro, Git comes from the guest's package manager (`apt install
git` in a Debian/Ubuntu guest): same upstream software, different package
sources, different `$HOME`/config, and a glibc runtime. Never assume a config
or credential set up in one environment exists in the other.

## Cross-references

- Choosing a `core.editor`: [Editors](../08-power-tools/04-editors.md)
- Where `$HOME`/`$PREFIX` resolve: [The Filesystem](../00-foundations/03-filesystem.md)
- The OpenSSH dependency: [SSH and Remote Access](../08-power-tools/02-ssh-and-remote-access.md)

## References

- Phase 7 research notes §3–§5:
  `research/development/00-git-github-research.md`.
- git `git-config(1)` man page for git 2.55.0 (git-scm.com), and
  `termux/termux-packages` `packages/git/build.sh`, fetched 2026-09-22.