# Networking

Network tooling in Termux is mostly standard GNU/BSD software compiled for
Android, with a few Termux-specific twists: `ping`/`ping6` are Android system
binaries behind wrappers; `hostname` comes from inetutils; `getprop` (Android
property) and the `cmd`/`pm`/`settings` wrappers live in
[Termux Utilities](../01-termux/06-utilities.md).

## In a fresh install

| Command | Package | Notes |
|---------|---------|-------|
| `curl` | curl | full-featured transfer tool |
| `ping`, `ping6` | termux-tools wrapper → `/system/bin` | toybox on device |
| `hostname` | inetutils | prints hostname |
| `logger` | inetutils | syslog-ish logging |
| `telnet`, `tftp`, `ftp`, `dnsdomainname` | inetutils | |
| `netstat`, `ifconfig`, `route`, `arp` | net-tools | legacy but present |
| `ssh`* | — | **not installed** — `pkg install openssh` |
| `wget` | — | **not installed** — `pkg install wget` |
| `dig`, `nslookup`, `host` | — | **not installed** — `pkg install dnsutils` |
| `ip`, `ss` | — | **not installed** — `pkg install iproute2` |
| `traceroute`, `nmap`, `socat`, `netcat-openbsd` | — | install each |

## `curl` — transfer data

`curl` is in the fresh install.

```sh
curl https://example.com/file.txt -o file.txt      # download
curl -O https://example.com/file.txt               # keep the remote filename
curl -L https://example.com                       # follow redirects
curl -s https://api.example.com/x | jq .           # silent + JSON tool
curl -H 'Authorization: Bearer TOKEN' https://api.example.com   # header
curl -I https://example.com              # fetch headers only
```

- `-o` output file, `-O` remote name, `-L` follow redirects, `-I` HEAD,
  `-H` headers, `-u` HTTP basic auth, `-k` skip TLS verification (*only* for
  testing; avoid in production), `--data` for POST.
- TLS certificates are configured via `$PREFIX/etc/tls/cert.pem` (verified
  in the Phase 3 audit). `curl` handles `https` out of the box.

## `wget` (install)

```sh
pkg install wget
wget https://example.com/file.zip
wget -c https://example.com/big.iso     # resume a partial download
wget -r -np https://example.com/dir/    # recursive mirror (careful)
```

## `ping` / `ping6` — the Android wrapper

`ping` and `ping6` in native Termux are **`termux-tools` wrappers** that
`exec /system/bin/ping` (etc.) — the device's toybox ping, not the Linux
`iputils` you may know.

```sh
ping 8.8.8.8            # does it reach?
ping -6 example.com     # IPv6 — the wrapper invokes /system/bin/ping6
```

- Options you can pass depend on the device's toybox `ping`; behavior,
  output format, and even whether `ping6` exists are
  **[device/Android-version variable]**. On newer Android versions the separate
  `ping6` binary has been dropped and toybox `ping` gained `-6`.
- `ping` is often the first thing to reach for when Wi-Fi/cellular seems off.
  The Termux app holds the standard Android `INTERNET` permission, so `ping`
  works from a normal session. See
  [Termux Utilities](../01-termux/06-utilities.md).

## `netstat` — sockets and routes (net-tools)

`netstat` is from net-tools in the fresh install.

```sh
netstat -tlnp                          # listening TCP + PID lookup
netstat -an | grep ESTABLISHED         # established connections
netstat -rn                            # routing table
```

- `-t` TCP, `-u` UDP, `-l` listening, `-n` numeric, `-p` show PID/program
  (requires that the process owner allows it — again limited without root).
- net-tools is legacy; the modern replacement is `ss` from **iproute2**
  (`pkg install iproute2`). Both are documented; `ss` is preferred for new
  scripts.

## `ss` / `ip` (iproute2, install)

```sh
pkg install iproute2
ss -tlnp                # listening TCP with process
ip addr                # addresses
ip route               # routing table
ip link                # interfaces
```

## DNS: `$PREFIX/etc/resolv.conf` and dig/nslookup/host (install)

- Termux configures `$PREFIX/etc/resolv.conf` with `8.8.8.8` and `8.8.4.4`
  nameservers (verified in the Phase 3 audit).
- The `dnsutils` CLI clients (`dig`, `nslookup`, `host`) read
  `$PREFIX/etc/resolv.conf` directly. Other network programs use the Android
  system resolver; for command-line lookups against the Termux file, use these
  tools.

```sh
pkg install dnsutils            # package name is 'dnsutils', not 'bind-tools'
dig example.com
dig +short example.com
nslookup example.com
host example.com
```

- The name 'dnsutils' is the Termux package name (the "bind-tools" name used
  on some distros does **not** exist in the Termux repo). [version-sensitive:
  exact bind tool set shipped may change]

## SSH — `ssh`, `scp`, `sftp` (install)

SSH is **not** in the fresh install.

```sh
pkg install openssh
ssh-keygen -t ed25519           # generate a key pair (~/.ssh/id_ed25519)
ssh-copy-id user@host           # install your key on the host
ssh user@host                   # connect
scp file user@host:/dest        # copy over ssh
sftp user@host                  # interactive file transfer
```

- Config: `$PREFIX/etc/ssh` is the sysconfdir; host keys live there
  (`ssh_host_*_key`). The `openssh` package depends on `termux-auth`.
- On Android, OpenSSH also integrates with the Android credentials/keychain
  (`~/.ssh`, `ssh-agent`) and exposes `sshd`/`ssh-agent` as Termux services
  under `$PREFIX/var/service/`. See
  [Processes and Sessions](../00-foundations/06-processes-and-sessions.md)
  for how Termux services stay alive.
- `ssh` is preferable to telnet for any interactive remote session; `telnet`
  is part of the fresh install (inetutils) but is legacy and unencrypted.

## `logger` — write to the Android log

`logger` is inetutils (in the fresh install) with a **Termux-specific patch**:
messages go to the **Android log** (`logcat`), not to `/var/log` or a syslog
daemon (there is no syslog daemon on Android). This rerouting is
Termux-package behavior, verified in the Phase 3 audit, not device-variable.

```sh
logger 'message text'        # write a line to the Android log
logcat -d | tail             # read recent log lines (see Termux Utilities)
```

- The Termux `logger` name and the logcat-backed destination are documented in
  the inetutils build; the exact lines Android keeps and how long they persist
  depend on the device/OS [`dmesg`/logcat retention is [variable]].
- This makes `logger` useful for tagging app events from scripts that you can
  later read back with `logcat`.

## `traceroute` / `nmap` / `socat` / `netcat` (install)

```sh
pkg install traceroute
traceroute -n example.com

pkg install nmap
nmap -sP 192.168.1.0/24        # ping-scan a subnet (may need privileges)

pkg install socat
socat TCP-LISTEN:8080,fork TCP:example.com:80

pkg install netcat-openbsd
nc -zv example.com 80          # test a TCP port
```

- Some scanning/raw-socket features can require elevated privileges; on a
  normal unrooted Termux you may need Shizuku/ADB for full function. See
  [Privileged Access](../00-foundations/02-android-sandboxing.md).

## Hostname and loopback

- `hostname` (inetutils) prints your device's configured hostname
  (typically empty or the device model). [variable]
- `localhost` resolves via the loopback interface normally.

## Native Termux vs. proot

Inside proot-distro, the network stack is the same Android kernel, but the
guest's `/etc/resolv.conf` may not be configured automatically — many
distributions need `resolv.conf` set up inside the guest. `ping` there is
the distro's `iputils` `ping` (not the toybox wrapper). See
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Cross-references

- The termux-tools wrappers (ping, ping6, getprop, logcat, pm, settings, cmd):
  [Termux Utilities](../01-termux/06-utilities.md)
- Using curl/wget + jq for API work:
  [Text Processing and Searching](03-text-processing-and-searching.md)
- Privileges for advanced networking:
  [Privileged Access](../00-foundations/02-android-sandboxing.md)

## References

- Phase 3 research notes §4.7 (networking), §5 (environment — resolv.conf,
  cert.pem), §9 (device checklist), §14 (audit log):
  `research/commands/00-shell-command-bible-research.md`.
- curl manual: <https://curl.se/docs/manual.html>
- OpenSSH manual: <https://www.openssh.com/manual.html>