# Power Tools

Power Tools is the Bible's development and power-user reference: the toolchain
needed to build and run software on Termux, the languages and runtimes
available (`clang`/C/C++, Python, Node.js, Java/Kotlin, Rust, Go, and more),
build systems, editors, local databases, networking and developer utilities,
and the SSH toolset for remote access.

The section assumes you can already install packages and move around the shell
([Package Management](../01-termux/02-package-management.md),
[Shell Commands](../02-shell/00-intro.md)). It is built around the audited
Phase 7 research in `research/development/` (see
[Factual baseline](#factual-baseline)).

The dedicated Git/GitHub material lives in its own section:
[Git and GitHub](../11-git-github/00-intro.md).

## Chapters

- **[Development Environment and Constraints](01-development-environment-and-constraints.md)**
  — how executing, compiling, and running code actually behaves inside the
  Android app sandbox: W^X, `termux-exec`, UIDs, ports, background limits. Read
  this first; every other Power Tools chapter builds on it.
- **[SSH and Remote Access](02-ssh-and-remote-access.md)** — the `openssh`
  package, the `ssh` client, keys and `ssh-keygen` defaults, `sshd` on the
  default port 8022, `ssh-agent` under `termux-services`, `termux-auth`
  password logins, and helper tools (`ssh-copy-id`, `ssha`, `opkssh`, `mosh`,
  `tmate`).
- **[C/C++ Toolchain and Build Systems](03-c-cpp-toolchain-and-build-systems.md)**
  — `clang` (Termux has no `gcc`), `build-essential`, `make`, `cmake`,
  `ninja`, the autotools, `pkg-config`, compiler caches, and
  `gdb`/`lldb`/`strace`.
- **[Editors](04-editors.md)** — `vim`, `neovim`, `emacs`, `nano`, `micro`,
  and `helix`, and where their configuration lives on Termux.
- **[Python](05-python.md)** — the `python` package, `pip`, and where packages
  install on Android.
- **[Node.js and npm](06-nodejs-and-npm.md)** — `nodejs` vs `nodejs-lts`, the
  separate `npm` package, and native-module builds.
- **[Java, Kotlin, and Android Build Tooling](07-java-kotlin-and-android-build-tooling.md)**
  — the OpenJDK packages, Kotlin, `gradle`/`maven`/`ant`, and the on-device
  Android tooling `aapt`/`apksigner`.
- **[Rust](08-rust.md)** — the `rust` package and `cargo` in the Termux
  toolchain (no `rustup`).
- **[Go](09-go.md)** — the `golang` package, `GOROOT`, and how Go links on
  Android.
- **[Databases](10-databases.md)** — `mariadb`, `postgresql`, and `redis` as
  on-device servers (plus `redis`), run through `termux-services`.
- **[Networking and Developer Utilities](11-networking-and-developer-utilities.md)**
  — `curl`/`wget`/`httpie`, `jq`/`yq`, `nmap`/`netcat`/`socat`/`websocat`,
  `tmux`, and the productivity tools `ripgrep`/`fd`/`bat`/`eza`/`fzf`.

## Environment distinction to keep in mind

Everything in this section runs in **native Termux** unless a chapter explicitly
says otherwise:

| Layer | What it is |
|-------|-----------|
| Native Termux | the app; `$PREFIX` binary environment, normal Android app UID |
| Termux packages | software built for Android by `termux-packages`; installs under `$PREFIX` |
| Android shell / ADB shell | `/system/bin/sh` (mksh), uid 2000 — **not** Termux's `$PREFIX` environment |
| Shizuku / Porter / rish / porsh | privileged-access systems; not needed for normal development |
| proot / proot-distro | a Linux distribution (Ubuntu/Debian/…) running over a proot bridge — a **different** libc/toolchain, package set, and paths |

Development inside native Termux is unprivileged: your UID is a normal Android
app UID, `$PREFIX` is normally
`/data/data/com.termux/files/usr`, and `$HOME` is normally
`/data/data/com.termux/files/home`. None of these paths are interchangeable
with root, ADB shell, or proot paths (AGENTS.md §7). See
[Development Environment and Constraints](01-development-environment-and-constraints.md)
for the details that matter when compiling and running programs.

## Prerequisites and security at a glance

- Everything below is installed with `pkg install …` (or `apt` if you switched
  the package manager). Package names and versions were verified against the
  `termux-main` repository index for `aarch64`, fetched 2026-09-22.
  **[version-sensitive]** — versions and dependency lines change as the
  repository updates.
- Normal development **does not require root, ADB, Shizuku, Porter, or rish**.
  If a step would need privileges, the chapter says so and explains why.
- Running **persistent** servers (sshd, databases) on Android is constrained by
  battery optimization and, on Android 12+, the phantom-process killer; read
  [Development Environment and Constraints](01-development-environment-and-constraints.md#background-execution-and-process-limits)
  before relying on a background daemon.
- When chapters show command examples, the environment is native Termux and the
  shell is the Termux bash from
  [Shell and Environment](../00-foundations/05-shell-and-environment.md).

## Factual baseline

These chapters are based on the audited Phase 7 research notes in
`research/development/`:

- `00-git-github-research.md` (Git, GitHub, GitHub CLI)
- `01-ssh-research.md` (SSH client, sshd, agents, keys, signing)
- `02-programming-languages-runtimes-research.md` (Python, Node.js, Java,
  Kotlin, Rust, Go, and other languages)
- `03-build-dev-tools-editors-databases-research.md` (C/C++ toolchain, build
  tools, editors, databases, `termux-services`)
- `04-networking-dev-utilities-research.md` (HTTP, JSON/YAML, network
  diagnostics, terminal multiplexing, productivity tools)
- `05-termux-android-dev-constraints-research.md` (W^X, `termux-exec`, UIDs,
  ports, background limits)

Package names, versions, and dependency lines were verified against the
`termux-main` (aarch64) repository index and the matching
`termux/termux-packages` build scripts, all fetched 2026-09-22. Research was
performed without a physical Android device, so behavior that needs a live
device to confirm is tagged **[DEVICE]**; Android- or version-dependent behavior
is tagged **[version-sensitive]**; OEM-specific behavior is tagged **[OEM]**;
and anything not conclusively verified is tagged `[needs verification]`. These
tags are preserved throughout the chapters **— do not read a tag as a fact.**
Unverified uncertainty is stated as uncertainty.

## Cross-references

- Getting packages: [Package Management](../01-termux/02-package-management.md)
- Where the binaries live: [The Filesystem](../00-foundations/03-filesystem.md),
  [Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md)
- Basic shell work: [Shell Commands](../02-shell/00-intro.md)
- Git and GitHub (dedicated section): [Git and GitHub](../11-git-github/00-intro.md)
- HTTPS/HTTP tools and DNS:
  [Networking (Shell Bible)](../02-shell/07-networking.md)
- Running devices/services persistently:
  [Processes and Sessions](../00-foundations/06-processes-and-sessions.md)
- Privilege layers are *not* required for development:
  [ADB and Android Debugging](../04-adb/00-intro.md),
  [Shizuku](../05-shizuku/00-intro.md), [Porter](../07-porter/00-intro.md)