# GitHub CLI

The GitHub CLI (`gh`) is the command-line face of GitHub: repository
management, pull requests, issues, releases, and even Actions — all driven
from the shell. The Termux package is the official `cli/cli` build: the
upstream project explicitly lists Termux as a supported Android channel
("supported by the Termux community with updates powered by
termux/termux-packages").

## Install

```sh
pkg install git gh              # gh depends on git for repository operations
gh --version                    # gh version 2.101.0 (aarch64 index, 2026-09-22) [version-sensitive]
```

- The package name is **`gh`** — there is **no** `github-cli` package.
- The `gh` package declares **no hard package dependencies** (it ships as a Go
  binary), but `gh` does not vendor Git and still needs it for repository
  operations — the practical install is the baseline `pkg install git gh`
  **[DEVICE]**. The Termux build sets `RECOMMENDS=openssh` (SSH flows).
- The postinst generates completions with `gh completion` into
  `$PREFIX/share/bash-completion/completions/gh.bash`,
  `$PREFIX/share/zsh/site-functions/_gh`, and
  `$PREFIX/share/fish/vendor_completions.d/gh.fish` (note: **not**
  `$PREFIX/etc/bash_completion.d/`).

## Authenticate

```sh
gh auth login                     # interactive; chooses web or token flow
gh auth status                    # see which account/host is logged in
```

Flow options (from the gh manual, cli.github.com):

- **Web/browser flow** (the default). It normally opens a browser for the
  OAuth handshake; on a device without a suitable browser, gh prints a
  **one-time code** and a URL. Complete it from any browser (including on
  another device), then come back. `gh auth login --web --clipboard` copies
  the one-time code to the clipboard. Practical on-device behavior
  **[DEVICE]** `[needs verification]`.
- **Token flow.** There is **no** `-t`/`--token` flag on `gh auth login`.
  Read a **classic PAT** from standard input:

```sh
gh auth login --hostname github.com --with-token < tokenfile
```

  The manual recommends `GH_TOKEN` for **fine-grained** PATs
  (`export GH_TOKEN=…`), and `-p/--git-protocol {ssh|https}` plus
  `-h/--hostname` select protocol and host.

### Where the token is stored

- gh uses the system credential store when one is found; otherwise it
  **falls back to writing the token to a plain-text file** — on Termux that is
  normally `$HOME/.config/gh/hosts.yml`. `gh auth status` reports its stored
  location.
- `--insecure-storage` forces plaintext storage. Treat the token file like any
  other credential: app-private, backed-up, and revocable.
  (Security guidance: see [HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md#security-notes).)

## Wire Git into gh

```sh
gh auth setup-git
```

This configures Git's `credential.helper` so that HTTPS operations against
github.com authenticate with gh's stored token — Git pushes no longer prompt
per command. Full details in
[HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md).

## Everyday commands

```sh
gh repo clone termux/termux-app            # clone via gh (uses git under the hood)
gh repo create mynewrepo --public --clone  # create remotely + clone locally

gh pr create --title "Add feature" --body "…"   # open a PR from the current branch
gh pr list                                   # list open PRs
gh pr view 12                                # view a PR
gh pr merge 12 --merge                       # merge it (--squash / --rebase too)
gh pr checkout 12                            # check out a PR locally

gh issue list --assignee @me                 # your assigned issues
gh issue create --title "Bug" --body "…"

gh release create v1.0.0 --title "1.0" --generate-notes   # release + notes
gh release upload v1.0.0 ./artifact.apk                  # attach files

gh run list                                   # recent workflow runs
gh workflow run test.yml                      # trigger a workflow
gh run watch                                  # follow the latest run
gh run view <run-id>                          # details of one run
```

- `gh repo clone`, `gh pr create`, and friends all operate **through git**
  under the hood, so your Git setup from the earlier chapters applies.
- `gh auth setup-git` also understands SSH as a `--git-protocol`, so an
  SSH-based setup (see [SSH Authentication and Keys](04-ssh-authentication-and-keys.md))
  is equally supported.

## GitHub Actions from Termux

Using `gh` to **trigger and watch** workflows (`gh workflow run`, `gh run
watch`, `gh run list`) is documented above and works from Termux. Running a
**self-hosted runner** on the phone is a separate topic that Phase 7 research
deliberately leaves out of scope; mark it `[needs verification]` if you pursue
it.

## Native Termux vs. proot

Inside proot-distro you would use the guest's `gh` (its package manager or the
official `gh` script/flatpak) with the guest's config paths. The Termux `gh`
package and its `$PREFIX/share/...` completions are specific to native Termux.

## Security notes

- `gh auth login` hands GitHub an OAuth token; only authenticate on the device
  you control, and use `gh auth logout` on shared/pre-owned hardware.
- Tokens in `GH_TOKEN` environment variables can leak via scripts or `env`
  output; prefer scoped tokens and revoke when unused.

## Cross-references

- Installing Git and setting `user.name`/`user.email`:
  [Git Installation and Setup](01-git-installation-and-setup.md)
- `gh auth setup-git` vs manual helpers:
  [HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md)
- SSH-based flows: [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)
- Releases and Actions details:
  [Releases and GitHub Actions](07-github-releases-and-actions.md)

## References

- Phase 7 research notes §7:
  `research/development/00-git-github-research.md`.
- `cli/cli` install docs ("Android" section) and the gh manual
  (`gh auth login`), fetched 2026-09-22; package facts verified against
  `termux/termux-packages` `packages/gh/build.sh` and the `termux-main`
  index.