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
- Phases 4–13: not started.

| Phase | Topic | Status |
|-------|-------|--------|
| 1 | Foundation and Repository Setup | complete |
| 2 | Termux Foundations | complete, audited |
| 3 | Shell Command Bible | complete, audited |
| 4 | Android and ADB | not started |
| 5 | Shizuku and rish | not started |
| 6 | Porter | not started |
| 7 | Power Tools | not started |
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
by subject (currently `research/termux/` for Phase 2 and `research/commands/` for
Phase 3).

`00-foundations/` and `01-termux/` contain the completed Phase 2 chapters;
`02-shell/` contains the completed Phase 3 Shell Command Bible. The remaining
sections currently contain only their introduction stubs and are filled in by
later phases.

## Editing Workflow

Substantial technical documentation follows this workflow:

Research → Audit → Draft → Content Audit → Verify → Build

The research notes are audited before drafting, then the draft itself is audited
for content, the resulting documentation is verified against the research and a
target environment, and the EPUB build is run as a verification step. Detailed
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