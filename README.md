# Termux Bible

The Termux Bible is a comprehensive, practical, research-driven reference for using
Termux and Android as a powerful command-line environment. It is written as
Markdown and compiled to an EPUB with Pandoc.

This repository is currently in Phase 1 (foundation and repository setup): the
planning documents, publishing toolchain, and directory scaffold are in place.
Substantive documentation content is added in later phases.

## Project Goals

The project aims to:

- explain Termux from beginner to advanced levels;
- document important shell commands and a broad command encyclopedia;
- explain Android command-line workflows, ADB, and Android debugging;
- document Shizuku, rish, and Porter as distinct privileged-access systems;
- cover development tools, Git and GitHub, scripting, and automation;
- cover documents, media, and data workflows;
- provide troubleshooting, security guidance, quick-reference material, and
  practical examples;
- remain maintainable as Termux and Android evolve.

The operating and research rules for the project are defined in `AGENTS.md`.
The project roadmap and architecture are defined in `PLAN.md`.

## Repository Structure

- `AGENTS.md` — permanent operating rules for the project.
- `PLAN.md` — project roadmap, architecture, phases, and planned contents.
- `README.md` — this file.
- `metadata.yaml`, `epub-style.css`, `build.sh` — EPUB publishing toolchain.
- `00-foundations/` through `16-quick-reference/` — numbered documentation sections.
- `appendices/` — supporting reference material (glossary, indexes, and similar).
- `research/` — research notes; supporting material that is not publication-ready
  documentation and is excluded from the EPUB.

## How to Read It

Each numbered directory (`00-foundations/`, `01-termux/`, and so on) will contain
the documentation for one section of the Bible. The sections are read in numeric
order. `appendices/` is read last. Detailed reference material (command entries,
troubleshooting, security) is cross-linked from the sections that depend on it.

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
verified, and audited before they are added to the documentation. Information that
cannot be verified is marked as needing research instead of being invented.

## Project Status

- Phase 1 — Foundation and Repository Setup: complete.
- Phase 2 — Termux Foundations: not started.

## Important References

- Termux app: <https://github.com/termux/termux-app>
- Termux packages and developer wiki: <https://github.com/termux/termux-packages/wiki>
- Pandoc user's guide: <https://pandoc.org/MANUAL.html>