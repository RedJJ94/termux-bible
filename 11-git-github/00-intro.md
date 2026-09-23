# Git and GitHub

Git is the version-control system nearly every development workflow on Termux
uses, and GitHub is where most of those repositories live — reachable over
HTTPS or SSH, with the [GitHub CLI](06-github-cli.md) (`gh`) as the direct
command-line face of GitHub features (repositories, pull requests, releases,
Actions). This section covers all of it for a Termux environment.

Everything here runs in **native Termux** unless a chapter says otherwise: the
`git`, `gh`, and `openssh` packages are Termux builds that operate on
repositories under `$HOME`/`$PREFIX` paths and authenticate with whatever
credential method you configure. None of this requires root, ADB, Shizuku,
Porter, or rish.

## Chapters

- **[Git Installation and Setup](01-git-installation-and-setup.md)** — the
  `git` package (2.55.0), its dependencies, first-use identity, the editor and
  pager quirk, and completion.
- **[The Basic Workflow](02-basic-workflow.md)** — `init`/`clone`, `add`,
  `status`, `commit`, `log`, branches, `merge`/`rebase`, remotes, and tags.
- **[HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md)**
  — tokens instead of passwords, and the credential-helper options on Termux.
- **[SSH Authentication and Keys](04-ssh-authentication-and-keys.md)** — key
  generation, enrolling a key with GitHub, and connecting over SSH.
- **[Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md)**
  — signing commits with SSH keys (and GPG), and GitHub's "Verified" status.
- **[GitHub CLI](06-github-cli.md)** — the `gh` package, authentication, and
  the everyday `gh` commands.
- **[Releases and GitHub Actions](07-github-releases-and-actions.md)** —
  `gh release`, tags, and driving workflows with `gh workflow run`.
- **[Repository Maintenance and the Git Ecosystem](08-repository-maintenance-and-git-ecosystem.md)**
  — keeping repositories healthy, plus the Git-related packages available in
  `termux-main` (LFS, credential manager, delta, TUI clients, and more).

## Environment distinction to keep in mind

| Layer | What it is |
|-------|-----------|
| Native Termux | the app; `$PREFIX` binary environment, normal app UID |
| `git` config | per-user config in `$HOME/.gitconfig`; repository config in `.git/config` |
| SSH in Termux | user-space `openssh`; `$HOME/.ssh`, agent socket under `$PREFIX/var/run` |
| Android shell / ADB shell | `/system/bin/sh` — a different environment; `git` is not there by default |
| Shizuku / Porter / rish | privileged access; **not needed** for Git/GitHub |

`$HOME` is the Termux data home (`/data/data/com.termux/files/home`), `$PREFIX`
is normally `/data/data/com.termux/files/usr`, and these are **not**
interchangeable with root, ADB-shell, or proot paths (AGENTS.md §7).

## Prerequisites and security at a glance

- Install `git` (and preferably `openssh`), set `user.name`/`user.email`, and
  set an editor (see
  [Git Installation and Setup](01-git-installation-and-setup.md)).
- **GitHub does not accept account passwords for Git operations.** Use a
  personal access token (HTTPS), an SSH key, or `gh`'s device-flow
  authentication. `[needs verification]` on the exact 2026 policy wording.
- HTTPS token storage on Termux has **no OS keyring by default**; if you use
  Git's `store` helper the token lands in plain text in `$HOME/.git-credentials`.
  Prefer `gh` as the credential helper or SSH keys.
- Never put real tokens or private keys in documentation or examples; use
  placeholders.
- License/verification note: commit "Verified" status is a GitHub UI feature
  about signature state — it does not change what Git locally verifies
  (`git verify-commit`/`verify-tag`).

## Factual baseline

This section is based on the audited Phase 7 research:

- `research/development/00-git-github-research.md` (Git and GitHub CLI,
  Termux packaging, git-config semantics for git 2.55.0).
- `research/development/01-ssh-research.md` (SSH keys, agent, commit signing,
  OpenSSH defaults).

Package names, versions, dependency lines, and git-config semantics were
verified against the `termux-main` (aarch64) repository index, the
`termux/termux-packages` master build.sh files, the `git-config` man page for
git 2.55.0, and official GitHub/`gh` documentation, all fetched 2026-09-22.
Research was performed without a physical Android device: behavior needing a
live device is tagged **[DEVICE]**, version-dependent behavior
**[version-sensitive]**, OEM behavior **[OEM]**, and unresolved items
`[needs verification]` — do not read a tag as a fact.

## Cross-references

- The SSH toolset this relies on: [SSH and Remote Access](../08-power-tools/02-ssh-and-remote-access.md)
- The environment all commands run in:
  [Development Environment and Constraints](../08-power-tools/01-development-environment-and-constraints.md)
- Setting an editor to configure in Git: [Editors](../08-power-tools/04-editors.md)
- `curl`/HTTPS underneath: [Networking (Shell Bible)](../02-shell/07-networking.md)
- Text/viewing tools used with Git output:
  [Viewing and Editing Files](../02-shell/02-viewing-and-editing-files.md)