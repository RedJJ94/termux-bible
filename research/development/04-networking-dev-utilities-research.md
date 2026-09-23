# Networking & Developer Utilities — Research Notes (Phase 7)

Status: research notes supporting Phase 7 (PLAN.md §12: networking,
"networking tools", web development, local servers; §14 advanced networking).
Not polished documentation; kept separate from Bible chapters per AGENTS.md
§17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Items
needing a live device are tagged **[DEVICE]**; version-dependent behavior is
tagged **[version-sensitive]**.

Audit note: versions below were verified against the `termux-main` index
(`binary-aarch64/Packages`, fetched 2026-09-22) and dependency/install facts
against the matching `termux/termux-packages` master build.sh files where a
fact is stated.

Cross-reference: `curl` is also the transport for git HTTPS
(`00-git-github-research.md` §3); SSH/remote-access tools are in
`01-ssh-research.md`; server/daemon lifecycle via `termux-services` in
`03-build-dev-tools-editors-databases-research.md` §9.

---

## 1. Scope

Developer-facing command-line utilities that are common in Termux workflows:
transfer/download clients (`curl`, `wget`, `httpie`), JSON/YAML processing
(`jq`, `yq`), network diagnostics (`nmap`, `netcat-openbsd`), socket/relay
tools (`socat`, `websocat`), terminal multiplexing/sharing (`tmux`, `tmate`),
search/text tools (`ripgrep`, `fd`, `bat`, `eza`, `fzf`), and legacy VCS/SCM
tooling (`subversion`, `fossil`). DNS/`openssl`-level crypto tools are
cross-referenced from other research when needed.

## 2. Source Inventory and Reliability Ranking

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `termux-main` index `binary-aarch64/Packages` (versions) | A | packages.termux.dev |
| A2 | `termux/termux-packages` `build.sh` for curl (libcurl subpkg), wget, httpie, jq, yq, nmap, netcat-openbsd, socat, websocat, tmux, tmate, ripgrep, fd, bat, eza, fzf, subversion, fossil | A | raw.githubusercontent.com |

## 3. HTTP/Download Utilities

| Tool | Version | Termux packaging facts |
|---|---|---|
| `curl` | 8.22.0 | CLI is an essential subpackage of `libcurl` (8.22.0); `bin/curl` + man page |
| `wget` | 1.25.0-1 | DEPENDS `libandroid-support, libiconv, libidn2, libuuid, openssl, pcre2, zlib` |
| `httpie` | 3.2.4-1 | DEPENDS `python, python-pip` (installed via pip as the `http`/`https` CLI) |
| `jq` | 1.8.2 | DEPENDS `oniguruma` (regex) |
| `yq` | 4.53.6 | yaml→json processing; Go binary |

- `curl` is present after `pkg install curl` or as a dependency of git; it is
  the standard transport for scripting, API calls, downloads
  (`curl -LO`), and health checks.
- `wget` for classic scripting (`-q`, `-O`, recursive).
- `httpie` is a pip-installed python tool; requires `python` + `python-pip`
  (hence only DEPENDS on those) and exposes `http`/`https`.
- `jq`/`yq` are the standard JSON/YAML processors for pipelines; both are
  single binaries.

## 4. Network Diagnostics and Socket Tools

| Tool | Version | Packaging / notes |
|---|---|---|
| `nmap` | 7.991 | DEPENDS `libc++, libpcap, libssh2, lua54, openssl, pcre2, resolv-conf, zlib`; installs `nmap`, `nping`, and `netcat-nmap` — the ncat binary is **renamed** to `netcat-nmap` in the Termux build (verified in nmap/build.sh) to avoid colliding with `netcat-openbsd`; the package PROVIDES `nc, ncat, netcat` |
| `netcat-openbsd` | 1.238-1-2 | OpenBSD netcat (`nc`) |
| `socat` | 1.8.1.3 | DEPENDS `openssl, readline`; swiss-army socket relay |
| `websocat` | 1.14.1 | DEPENDS `openssl`; WebSocket CLI |

- `nmap` scripts rely on NSE (lua) — included. Scanning remote hosts is
  normal; scanning on the *Android device's own* network interfaces requires
  their interface to be up (`termux-wifi-enable`/`termux-wifi-*` via
  termux-api) `[DEVICE]`.
- `nc` (netcat-openbsd) and `netcat-nmap` (renamed ncat): connection
  testing, port checking, debug probes. On non-root Termux a port below 1024
  cannot be bound (Android app uid is non-privileged) — see constraints file.
- `socat`/`websocat` for relays/tunnels and WebSocket testing against local
  or remote API servers.

## 5. Terminal Multiplexing and Sharing

| Tool | Version | Notes |
|---|---|---|
| `tmux` | 3.7c-1 | terminal multiplexer; socket/`TMUX_TMPDIR` under Termux data dir; config `~/.tmux.conf` |
| `tmate` | 2.4.0-3 | tmux-based terminal sharing; DEPENDS `libandroid-support, libevent, libmsgpack, libssh, ncurses` |

- tmux is frequently used to keep dev sessions/daemons alive independent of
  a single terminal. Combine with `termux-services` note (§9 of 03) when a
  real service lifecycle is needed.
- tmate requires outbound SSH; use for pair/remote support
  `[DEVICE] [needs verification]` on exact web client behavior.

## 6. Search, Text, and Shell Productivity

| Tool | Version | Notes |
|---|---|---|
| `ripgrep` | 15.2.0 | `rg`; respects `.gitignore` by default (like `git grep`); `-L/--follow` follows symlinks |
| `fd` | 10.5.0 | `fd`; find replacement; respects .gitignore by default |
| `bat` | 0.26.1-1 | `bat`; cat with syntax highlighting (paging via less) |
| `eza` | 0.23.5 | `ls` replacement |
| `fzf` | 0.74.4 | fuzzy finder; often paired with bash/zsh completions |

- All are single static-ish binaries in `termux-main`; no special
  Termux-only config needed. `bat --theme`/`fzf` need a terminal supporting
  colors; Termux's terminal emulator supports the standard xterm-256color
  palette `[DEVICE]`.

## 7. Legacy/Other VCS

- `subversion` 1.14.5-3 and `fossil` 2.28 are present (deps in
  `00-git-github-research.md` §8). They are normally niche for Termux use but
  documented as available.

## 8. Unresolved / Device-Verified Items

- `nmap` scanning behavior/performance on-device and NSE usage over Android's
  network stack `[DEVICE]`.
- tmate pairing flow from the mobile client `[needs verification]`.
- Color/highlight rendering of `bat`/`eza`/`fzf` under the Termux terminal
  `[DEVICE]`.
- WebSocket CLI (`websocat`) TLS/cert behavior on device certificates
  `[needs verification]`.