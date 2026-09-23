# Termux Bible

The Termux Bible is a comprehensive, practical, research-driven reference for using
Termux and Android as a powerful command-line environment. It covers beginning to
advanced topics: Termux fundamentals, the shell command set, Android and ADB
workflows, privileged-access systems (Shizuku, rish, Porter), development tools,
scripting and automation, document/media/data workflows, troubleshooting, and
security.

Markdown is the canonical documentation source. The content is compiled to an EPUB
with Pandoc via `build.sh`.

The project is developed in phases according to the roadmap and architecture in
`PLAN.md`. The permanent operating and research rules are defined in `AGENTS.md`.

## Current Status

- Phase 1 — Foundation and Repository Setup: **complete**.
- Phase 2 — Termux Foundations: **complete** (research, chapters, audit, and verification done).
- Phase 3 — Shell Command Bible: **complete** (research, audit, chapters, content audit, verification, and EPUB build done).
- Phase 4 — Android and ADB: **complete** (research, audit, chapters, and EPUB build done).
- Phase 5 — Shizuku and rish: **complete** (research, audit, chapters, content audit, final verification, and EPUB build done).
- Phase 6 — Porter: **complete** (research, audit, chapters, content audit, final verification, and EPUB build done).
- Phase 7 — Power Tools / Git & GitHub: **complete** (research, audit, chapters, content audit, final verification, and EPUB build done).
- Phases 8–13: planned in `PLAN.md`, not yet started.

| Phase | Topic | Status |
|-------|-------|--------|
| 1 | Foundation and Repository Setup | complete |
| 2 | Termux Foundations | complete, audited |
| 3 | Shell Command Bible | complete, audited |
| 4 | Android and ADB | complete, audited |
| 5 | Shizuku and rish | complete, audited |
| 6 | Porter | complete, audited |
| 7 | Power Tools / Git & GitHub | complete, audited |
| 8 | Documents, Media, and Data | not started |
| 9 | Advanced Termux | not started |
| 10 | Scripting and Automation | not started |
| 11 | Troubleshooting and Security | not started |
| 12 | Command Encyclopedia and Quick Reference | not started |
| 13 | Final Verification and Publication | not started |

Phase 3 added the **Shell Command Bible** in `02-shell/`: a ten-chapter command
reference written for a fresh native Termux install. It opens with an
introduction covering command provenance (which tool provides each command in a
fresh install) and what needs `pkg install`, then covers filesystem and
navigation, viewing and editing files, text processing and searching, processes
and job control, permissions and ownership, archives and compression,
networking, system information and utilities, and pipes, redirection, and shell
built-ins. The chapters are based on the audited research in
`research/commands/00-shell-command-bible-research.md`, distinguish command
availability in a fresh Termux install from what requires package installation,
and mark version- or device-dependent behavior rather than asserting it as
universal.

Phase 4 added the **Android and ADB** documentation in `03-android/` and
`04-adb/`: the device-side Android command ecosystem and the ADB (Android
Debug Bridge) channel that drives it from a computer. The `03-android/`
chapters cover the Android shell (`/system/bin/sh`, mksh, and the
toolbox/toybox tool set), Android properties (`getprop`/`setprop`), Android
package management (`pm`, `cmd package`, `adb install` — versus Termux's
`pkg`/`apt` and a proot distribution's package manager), the `cmd` dispatcher,
the `am` activity manager, `settings` and `input`, `logcat`, `dumpsys`, and
`screencap`/`screenrecord`. The `04-adb/` chapters cover ADB's
client/server/`adbd` architecture and installation (including `android-tools`
in Termux), USB and wireless debugging, `adb shell`, file transfer (`adb
push`/`pull`), and end-to-end capture workflows. The chapters are based on the
audited research in `research/android/00-android-shell-research.md`,
`research/adb/00-adb-research.md`, and
`research/adb/01-android-command-ecosystem-research.md`, keep native Termux,
the Android shell, ADB shell, and proot distributions distinct, and mark
version- or device-dependent behavior (`[version-sensitive]`, `[DEVICE]`)
rather than asserting it as universal.

Phase 5 added the **Shizuku and rish** documentation in `05-shizuku/` and
`06-rish/`: the privileged-access layer that lets normal Android apps call
system APIs with ADB/root privileges, and the shell client (`rish`) that reaches
it from a terminal app. The `05-shizuku/` chapters cover Shizuku fundamentals
and architecture (manager app, `shizuku_server`, binder delivery), installation
and activation/startup (root, wireless debugging, ADB), permissions and the
server's identity (`API_V23`, uid 2000 vs root), command-line/Termux usage, and
limitations and troubleshooting. The `06-rish/` chapters cover rish architecture
and setup (the `rish` + `rish_shizuku.dex` export flow), command-line
execution and environment handling (`RISH_PRESERVE_ENV`), and the relationship
between rish and its Shizuku/Sui backends. The chapters track version-sensitive
startup behavior — including the transition from the older `start.sh` flow to
the native `libshizuku.so` starter in Shizuku v13.6.0 — and Android 14+
writable-Dex considerations, and they keep rish's relationship to Porter
strictly out of scope: Porter compatibility is deferred to Phase 6 and is not
claimed here. The chapters are based on the audited research in
`research/shizuku/00-shizuku-research.md` and
`research/rish/00-rish-research.md`, keep Shizuku, rish, Sui, ADB, root, and
Termux distinct, and mark version- or device-dependent behavior
(`[version-sensitive]`, `[DEVICE]`, `[OEM]`) rather than asserting it as
universal.

Phase 6 added the **Porter** documentation in `07-porter/`: the privileged-access
daemon that is an independent continuation of Shizuku and gives Android apps and
the command line the ADB `shell` identity or root. The chapters cover Porter's
architecture and its two Binder interfaces — the Porter wire
(`eu.darken.porter.server.IPorterService`, with the `transactRemote`, porsh, and
app transaction codes) and the legacy Shizuku wire (`IShizukuService`) over one
shared core — installation and the Android 7.0+ requirement, the three startup
methods (wireless debugging, a computer, root) and the start-on-boot mode, and
the identity model: the server runs as uid 2000 (`shell`) when started with
debugging access, or uid 0 (root) when started as root. Permissions and security
are covered for the approval/confirmation flow (Deny / Allow all the time,
deny-permanently, one-time grants, and the "Allow app access" pause switch) and
for what each identity can and cannot do. porsh, Porter's own shell client, is
documented for command-line use from Termux: the `porsh` + `porsh.dex` export
flow, app-private placement on Android 14+, and
`PORSH_PRESERVE_ENV`/`RISH_PRESERVE_ENV` environment filtering. The chapters
distinguish porsh from rish, explain that the stock rish client is **not** a
Porter client (its loader needs `moe.shizuku.manager.shell.Shell`, which
Porter's manager APK does not ship, so it fails with `ClassNotFoundException`),
and cover the optional Porter Compatibility companion that lets Shizuku-only
apps reach Porter. Developer integration via the `porter-api` SDK (availability
and connection StateFlows, permissions, `wrap`, user services) and the
limitations and troubleshooting of the project are also documented. The
chapters are based on the audited research in
`research/porter/00-porter-research.md`, with the Phase 6 rish/Porter
cross-reference in `research/rish/00-rish-research.md`; they keep Porter,
Shizuku, Sui, rish, porsh, ADB, and root distinct, and mark version-, device-,
or OEM-dependent behavior (`[version-sensitive]`, `[DEVICE]`, `[OEM]`) rather
than asserting it as universal.

Phase 7 added the **Power Tools** and **Git & GitHub** documentation in
`08-power-tools/` and `11-git-github/`: the Bible's development and
power-user reference. The `08-power-tools/` chapters open with the Termux
development environment and the Android constraints that shape all on-device
development (W^X, `termux-exec`, UIDs, ports, and background/phantom-process
limits), then cover the C/C++ toolchain and build systems (`clang` — Termux
has no `gcc` — `make`, `cmake`, `ninja`, the autotools, `pkg-config`, and
debuggers), editors (`vim`, `neovim`, `emacs`, `nano`, `micro`, `helix`),
Python, Node.js/npm, Java/Kotlin and on-device Android build tooling
(`aapt`/`apksigner`), Rust and Go, local databases (`mariadb`, `postgresql`,
`redis` through `termux-services`), networking and developer utilities
(`curl`/`wget`/`httpie`, `jq`/`yq`, network diagnostics, `tmux`, and
productivity tools), and SSH and remote access (the `openssh` client and
`sshd` on port 8022, key generation, `ssh-agent` under `termux-services`,
`termux-auth`, and helper tools). The `11-git-github/` chapters cover Git
installation/setup and the basic workflow, HTTPS authentication and credential
handling, SSH authentication and keys, commit signing and verified commits,
GitHub CLI (`gh`), GitHub releases and Actions, and repository maintenance and
the Git ecosystem. The chapters are based on the audited research in
`research/development/`, keep native Termux distinct from ADB/root/proot
environments, and mark version-, device-, or OEM-dependent behavior
(`[version-sensitive]`, `[DEVICE]`, `[OEM]`) rather than asserting it as
universal.

The project currently builds successfully as an EPUB with `./build.sh`.

## Repository Structure

- `AGENTS.md` — permanent operating and research rules.
- `PLAN.md` — project roadmap, architecture, phases, and planned contents.
- `metadata.yaml`, `epub-style.css`, `build.sh` — EPUB publishing toolchain.
- `00-foundations/` through `16-quick-reference/` — the numbered Bible sections.
  These directories (plus `appendices/`) are the EPUB content.
- `appendices/` — supporting reference material (glossary, indexes, and similar).
- `research/` — research notes supporting the Bible. This is working material, not
  publication-ready documentation, and is excluded from the EPUB.

Bible chapters live in the numbered directories (`00-foundations/`, `01-termux/`,
and so on) and in `appendices/`. Research notes live under `research/`, organized
by subject (currently `research/termux/` for Phase 2, `research/commands/` for
Phase 3, `research/android/` and `research/adb/` for Phase 4,
`research/shizuku/` and `research/rish/` for Phase 5, `research/porter/`
for Phase 6, which also added the Phase 6 rish/Porter cross-reference to
`research/rish/00-rish-research.md`, and `research/development/` for Phase 7).

`00-foundations/` and `01-termux/` contain the completed Phase 2 chapters;
`02-shell/` contains the completed Phase 3 Shell Command Bible; `03-android/`
and `04-adb/` contain the completed Phase 4 Android and ADB chapters;
`05-shizuku/` and `06-rish/` contain the completed Phase 5 Shizuku and rish
chapters, `07-porter/` contains the completed Phase 6 Porter chapters, and
`08-power-tools/` and `11-git-github/` contain the completed Phase 7 Power
Tools and Git & GitHub chapters. The remaining sections currently contain only
their introduction stubs and are filled in by later phases.

## Editing Workflow

Substantial technical documentation follows this workflow:

Research → Research Audit → Draft → Content Audit → Final Verification → Phase
commit containing research + chapters → README update → separate README commit

The research notes are audited before drafting, then the draft itself is audited
for content, the resulting documentation is verified against the research and a
target environment in a final verification pass, and the EPUB build is run as a
verification step. Each phase is committed together with its research and
chapters, and the README status update is then committed separately. Detailed
behavior for each stage — including source priority, verification rules, and
the requirement that corrections be independently verified — is defined in
`AGENTS.md`. Information that cannot be verified is marked as needing research
rather than invented.

## Native Termux vs. proot

The Bible documents several distinct execution environments and does not assume a
command behaves identically across them. In particular, native Termux (the
environment under `$PREFIX`, normally `/data/data/com.termux/files/usr`) differs
from a Linux distribution running inside proot/proot-distro: package names, paths,
`PATH`, and even which tool provides a given command can differ. Individual
chapters state which environment they describe.

## How to Build the EPUB

Requires `pandoc` (EPUB3 support) on the `PATH`. From the repository root:

```sh
./build.sh
```

An optional output path may be given:

```sh
./build.sh path/to/termux-bible.epub
```

`build.sh`:

- locates `pandoc` with `command -v pandoc`;
- gathers Markdown files from the numbered sections (`00` through `16`) in numeric
  order, followed by `appendices/`;
- sorts files lexicographically within each directory;
- excludes `AGENTS.md`, `PLAN.md`, the root `README.md`, `research/`, and all
  non-Markdown files from the book;
- generates an EPUB3 file with a table of contents, using `metadata.yaml` and
  `epub-style.css`.

## How to Contribute

Follow the rules in `AGENTS.md`. Substantive technical claims must be researched,
verified, and audited before they are added to the documentation, and they must be
reproducible for a stated environment.

## Important References

- Termux app: <https://github.com/termux/termux-app>
- Termux packages and developer wiki: <https://github.com/termux/termux-packages/wiki>
- Pandoc user's guide: <https://pandoc.org/MANUAL.html>