# Networking and Developer Utilities

The day-to-day developer toolkit available in `termux-main`: HTTP clients,
JSON/YAML processors, network diagnostics, socket/relay tools, terminal
multiplexing, and the modern search/text productivity tools. Versions are from
the 2026-09-22 `termux-main` aarch64 index **[version-sensitive]**.

## HTTP and download clients

| Tool | Version (2026-09-22) | Termux packaging facts |
|------|----------------------|------------------------|
| `curl` | 8.22.0 | CLI is an essential subpackage of `libcurl`; `bin/curl` + man page |
| `wget` | 1.25.0-1 | DEPENDS `libandroid-support, libiconv, libidn2, libuuid, openssl, pcre2, zlib` |
| `httpie` | 3.2.4-1 | DEPENDS `python, python-pip`; exposes the `http`/`https` CLIs |

```sh
pkg install curl wget httpie jq yq
curl -LO https://example.com/file.zip        # download, keep remote name
curl -s https://api.github.com/repos/termux/termux-app | jq .name
wget -c https://example.com/big.iso          # resume
http https://example.com/api                 # httpie: human-readable response
```

- `curl` is present right after `pkg install curl` (or as a dependency of
  `git`). It is the standard transport for scripting, API calls, and health
  checks.
- `wget` for classic `-q`/`-O`/recursive flows.
- `httpie` is a pip-installed Python tool (hence its DEPENDS); it needs the
  `python`/`python-pip` packages to be usable.

## JSON and YAML

| Tool | Version (2026-09-22) | Notes |
|------|----------------------|-------|
| `jq` | 1.8.2 | JSON processor; DEPENDS `oniguruma` (regex) |
| `yq` | 4.53.6 | YAML→JSON processor; Go binary |

```sh
curl -s https://api.github.com/rate_limit | jq '.resources.core'
yq '.services[0].name' compose.yml
```

## Network diagnostics and socket tools

| Tool | Version (2026-09-22) | Notes |
|------|----------------------|-------|
| `nmap` | 7.991 | installs `nmap`, `nping`, and `netcat-nmap` (ncat **renamed** to avoid colliding with `netcat-openbsd`); PROVIDES `nc, ncat, netcat`; NSE scripts included |
| `netcat-openbsd` | 1.238-1-2 | OpenBSD netcat (`nc`) |
| `socat` | 1.8.1.3 | socket relay; DEPENDS `openssl, readline` |
| `websocat` | 1.14.1 | WebSocket CLI; DEPENDS `openssl` |

```sh
pkg install nmap netcat-openbsd socat websocat
nc -zv example.com 443          # test a TCP port
nmap -sP 192.168.1.0/24         # ping-scan a subnet (privileges may be needed)
socat TCP-LISTEN:8080,fork TCP:example.com:80
websocat ws://127.0.0.1:8080            # connect to a local server
```

- **`nc` name ownership**: with `netcat-openbsd` installed you get `nc` from
  OpenBSD; the nmap package ships its ncat **renamed** to `netcat-nmap`.
  Installing both avoids conflict because of the rename.
- **Ports below 1024 cannot be bound** by a Termux process (unprivileged app
  UID); local test servers use high ports — see the constraints chapter.
- Scanning the Android device's **own** network interfaces needs them up
  (`termux-wifi-enable` via Termux:API) **[DEVICE]**; remote-scanning other
  hosts is normal.
- `websocat` TLS/cert behavior with device certificates is a
  `[needs verification]` item in the research.

## Terminal multiplexing

- **`tmux`** (3.7c-1): keep dev sessions and long-running jobs alive
  independent of a single terminal. Socket/`TMUX_TMPDIR` live under the Termux
  data directory; config `~/.tmux.conf`.

```sh
pkg install tmux
tmux new -s dev       # create a session
# inside: Ctrl-b d  detach; reattach with: tmux attach -t dev
```

  Combine with `termux-services` when you really need a *service* lifecycle
  (see [Databases](10-databases.md)) rather than an interactive session.
- **`tmate`** (2.4.0-3) — terminal sharing for pair sessions — is documented
  with the SSH tools in [SSH and Remote Access](02-ssh-and-remote-access.md).

## Search, text, and shell productivity

| Tool | Version (2026-09-22) | Notes |
|------|----------------------|-------|
| `ripgrep` | 15.2.0 | `rg`; respects `.gitignore` by default; `-L`/`--follow` follows symlinks |
| `fd` | 10.5.0 | `fd`; find replacement; respects `.gitignore` |
| `bat` | 0.26.1-1 | `bat`; cat with syntax highlighting (paging via less) |
| `eza` | 0.23.5 | modern `ls` replacement |
| `fzf` | 0.74.4 | fuzzy finder; pairs with bash/zsh completions |

```sh
pkg install ripgrep fd bat eza fzf
rg -n "TODO" src/                 # search ignoring .gitignore'd files
fd '.md$' docs                    # find markdown files under docs/
bat README.md                     # syntax-highlighted file view
eza -la --git .                   # listing with git status
ls | fzf                          # fuzzy-pick a line
```

- These are single small binaries in `termux-main`; no Termux-specific config
  is required. Color/fullscreen output (`bat --theme`, `fzf`) requires a
  terminal supporting colors; the Termux terminal emulator supports the
  standard `xterm-256color` palette **[DEVICE]**.

## Legacy/other VCS

- `subversion` (1.14.5-3) and `fossil` (2.28) are present in `termux-main` and
  documented in [Git and GitHub](../11-git-github/00-intro.md); for Termux use
  they are normally niche.

## Native Termux vs. proot

Inside proot-distro these tools come from the guest's repositories; `apt
install ripgrep jq tmux socat netcat-openbsd` in a Debian/Ubuntu guest gives
you the guest's builds with guest paths. Prefer the Termux-native packages for
work that must interact with `$PREFIX` programs (e.g. piping JSON from a
`$PREFIX` binary), and the guest's tools for guest-internal work.

## Security notes

- `nmap` port scans / `nc -z` probes against hosts you do not own can be
  treated as hostile; keep scans to your own devices and networks.
- Raw-socket and some scanning features can need privileges that a normal
  Termux session lacks; requiring root/ADB/Shizuku for that is a separate
  topic (see [Android Sandboxing](../00-foundations/02-android-sandboxing.md)).

## Cross-references

- Basic `curl`/`wget`/`ping`/DNS from the shell Bible:
  [Networking](../02-shell/07-networking.md)
- `curl` as Git's HTTPS transport:
  [Git Installation and Setup](../11-git-github/01-git-installation-and-setup.md)
- tmux/tmate with SSH: [SSH and Remote Access](02-ssh-and-remote-access.md)
- Text processing pipelines: [Text Processing and Searching](../02-shell/03-text-processing-and-searching.md)

## References

- Phase 7 research notes: `research/development/04-networking-dev-utilities-research.md`
  (§3–§8).
- Versions/deps verified against the `termux-main` (aarch64) index and the
  matching `termux/termux-packages` build.sh files, fetched 2026-09-22.