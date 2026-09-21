# Shell Commands

This section is the **Shell Command Bible** (Volume II of the Termux Bible). It
documents the command set you actually have in a fresh native Termux
installation and how to use it: navigation and files, viewing and editing
files, text processing and searching, processes and job control, permissions
and ownership, archives and compression, networking, system information, and
shell features such as pipes, redirection, and built-ins.

## What environment does this describe?

The chapters describe **native Termux** — the environment rooted at `$PREFIX`
(normally `/data/data/com.termux/files/usr`) that the Termux bootstrap
installs. Most commands behave as standard GNU/Linux tools because they *are*
GNU tools compiled for Termux, but several important differences are called out
in every chapter:

- **Which tool provides a command can differ from a desktop Linux distro.** For
  example `df` and `top` in Termux are the *Android system* (toybox) binaries
  reached through `termux-tools` wrappers, not GNU coreutils/procps tools.
- **The default `$PATH` is only `$PREFIX/bin`** (Android >= 7); `/system/bin`
  is deliberately excluded. See
  [Shell and Environment](../00-foundations/05-shell-and-environment.md).
- **A fresh install is smaller than a desktop distro.** Many familiar commands
  (`zip`, `wget`, `ssh`, `vim`, `file`, `which`, `locate`, ...) are **not**
  installed by default; every chapter states the exact `pkg install` line when
  a command requires it. See
  [Package Management](../01-termux/02-package-management.md).

Inside a **proot-distro** container (Ubuntu, Debian, Arch, ...) the commands
come from that distribution's own packages, follow FHS paths (`/bin`,
`/usr/bin`, `/etc`), and can differ in package names, `PATH`, and even which
tool provides a command (e.g. the distro's `df` is GNU coreutils `df`, while
native Termux's `df` is the Android wrapper). See
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).
Nothing here is assumed to transfer between the two environments.

## Where commands come from (provenance)

Knowing *which tool you are really running* matters in Termux. A command may be
a shell built-in, a GNU utility, a procps utility, a `termux-tools` wrapper
around an Android system binary, or a package you install yourself.

| Provider | Commands | Notes |
|----------|----------|-------|
| bash built-ins | `cd`, `pwd`, `echo`, `printf`, `test`/`[`, `type`, `command`, `kill`, `jobs`, `fg`, `bg`, `wait`, `read`, `export`, `source`, `trap`, `umask`, `ulimit`, `exec`, `alias`, `set`, `shift`, `local`, `declare`, ... | Always available; see [Pipes, Redirection, and Shell Built-ins](09-pipes-redirection-and-builtins.md). |
| dash (as `sh`) | `sh` is a symlink to `dash` | `#!/bin/sh` scripts run under dash, **not** bash. |
| GNU coreutils (`coreutils` package, one multicall binary) | `ls`, `mkdir`, `rmdir`, `touch`, `cp`, `mv`, `rm`, `ln`, `pwd`, `chmod`, `chown`, `chgrp`, `du`, `kill`, `uname`, `id`, `whoami`, `cat`, `head`, `tail`, `cut`, `sort`, `uniq`, `tr`, `wc`, `od`, `base64`, `stat`, `echo`, `printf`, `test`, `mktemp`, ... | In the fresh install. The Termux build **deliberately omits** `df`, `pinky`, `users`, `who`; `uptime` comes from procps. |
| GNU text tools | `sed` (GNU sed), `awk` (gawk → `awk` symlink), `grep` (GNU grep), `diff`/`cmp`/`diff3`/`sdiff` (diffutils) | In the fresh install. |
| findutils | `find`, `xargs` | In the fresh install. `locate`/`updatedb` are **not** included (they come from `mlocate`). |
| procps (`procps` package) | `ps`, `pgrep`, `pkill`, `pidof`, `free`, `uptime`, `vmstat`, `watch`, `sysctl` | In the fresh install. `kill` and `top` are **explicitly not built**; `w`/`slabtop` are removed. |
| psmisc | `killall`, `fuser`, `pstree`, `peekfd` | In the fresh install. |
| util-linux | `hexdump`, `column`, `script`, `dmesg`, `setterm`, `ul`, `cal`, `lscpu`, `more`, `rev`, `rename`, `whereis`, ... | In the fresh install. Many tools (e.g. `mountpoint`, `ipcs`, `wall`, `agetty`) are intentionally not built — they are either Android-owned or meaningless under the app sandbox. |
| gzip / bzip2 (libbz2) / xz-utils | `gzip`/`gunzip`, `bzip2`/`bunzip2`, `xz`/`unxz`/`xzcat` | In the fresh install. |
| tar | GNU `tar` | In the fresh install. |
| other bootstrap packages | `nano`, `ed`, `curl`, `less`, `patch`, `dos2unix`, `unzip`, `lsof`, `net-tools` (`netstat`, `ifconfig`, `route`, `arp`), `inetutils` (`hostname`, `logger`, `telnet`, `tftp`, `ftp`, `dnsdomainname`) | In the fresh install. |
| `termux-tools` wrappers | `df`, `top`, `ping`, `ping6`, `getprop`, `logcat`, `pm`, `settings` (shell wrappers) and `cmd` (compiled wrapper) | All exec the **Android system** `/system/bin` binary. See [Termux Utilities](../01-termux/06-utilities.md). |
| `termux-tools` scripts | `pkg`, `termux-*` helpers, `chsh`, `su`, `login`, ... | See [Termux Utilities](../01-termux/06-utilities.md). |
| installed packages | `zip`, `wget`, `openssh`, `mlocate`, `dnsutils`, `file`, `which`, `iproute2`, `traceroute`, `nmap`, `jq`, `rsync`, `htop`, `vim`, `bc`, `7zip`, ... | See the table below; **not** present in a fresh install. |

## Commands that require `pkg install`

| Command(s) | Package | Notes |
|------------|---------|-------|
| `zip` | `zip` | creating ZIP archives |
| `unzip` is already installed | `unzip` | in the fresh install |
| `wget` | `wget` | |
| `ssh`, `scp`, `sftp`, `sshd`, `ssh-keygen`, `ssh-agent`, `ssh-add`, `ssh-copy-id`, `ssh-keyscan` | `openssh` | config under `$PREFIX/etc/ssh/` |
| `locate`, `updatedb` | `mlocate` | run `updatedb` first; database at `$PREFIX/var/mlocate/mlocate.db` |
| `dig`, `nslookup`, `host` | `dnsutils` | Termux uses the name `dnsutils`, not "bind-tools" (which does not exist) |
| `file` | `file` | subpackage of `libmagic` |
| `which` | `which` | `debianutils` deliberately ships without `which` |
| `ip`, `ss` | `iproute2` | modern replacement for net-tools |
| `traceroute` | `traceroute` | |
| `nmap` | `nmap` | |
| `jq` | `jq` | |
| `rsync` | `rsync` | |
| `htop` | `htop` | GNU-style `top` alternative |
| `tree`, `ncdu`, `bat`, `fd`, `fzf`, `ripgrep` | respective packages | |
| `vim`, `neovim`, `emacs` | respective packages | no separate "vim-python" package |
| `7z` | `7zip` | there is no `p7zip` package |
| `screen`, `tmux`, `zsh`, `cpio`, `bc`, `socat`, `netcat-openbsd` | respective packages | |

Package names above are verified against the current Termux package
repositories; they are **not** necessarily present in other Linux
distributions' naming. **[version-sensitive]:** the exact bootstrap set and
versions change over time.

## How to read the chapters

- **[Filesystem and Navigation](01-filesystem-and-navigation.md)** — `pwd`,
  `ls`, `cd`, `mkdir`, `rmdir`, `touch`, `cp`, `mv`, `rm`, `ln`, `find`,
  `locate`, `xargs`, `df`, `du`, `file`, `tree`.
- **[Viewing and Editing Files](02-viewing-and-editing-files.md)** — `cat`,
  `less`, `head`, `tail`, `nano`, `vim`, `ed`, `od`, `hexdump`, `patch`.
- **[Text Processing and Searching](03-text-processing-and-searching.md)** —
  `grep`, `sed`, `awk`, `cut`, `sort`, `uniq`, `tr`, `wc`, `diff`, `dos2unix`,
  `jq`, and the modern alternatives (`ripgrep`, `bat`, `fd`, `fzf`).
- **[Processes and Job Control](04-processes-and-jobs.md)** — `ps`, `top`,
  `pgrep`, `pkill`, `pidof`, `kill`, `killall`, `fuser`, `pstree`, `jobs`,
  `fg`, `bg`, `free`, `uptime`, `vmstat`, `watch`, `lsof`.
- **[Permissions and Ownership](05-permissions-and-ownership.md)** — `chmod`,
  `chown`, `chgrp`, `umask`, and the Android single-user/setuid reality.
- **[Archives and Compression](06-archives-and-compression.md)** — `tar`,
  `gzip`, `bzip2`, `xz`, `zip`, `unzip`, `7z`, `cpio`, `rsync`.
- **[Networking](07-networking.md)** — `curl`, `wget`, `ssh`/`scp`/`sftp`,
  `ping`, `netstat`, `ss`/`ip`, `dig`/`nslookup`/`host`, `hostname`, `logger`,
  `traceroute`, `nmap`.
- **[System Information and Utilities](08-system-information.md)** — `uname`,
  `id`, `whoami`, `getprop`, `df`, `du`, `free`, `uptime`, `lscpu`, `dmesg`,
  `column`, `script`.
- **[Pipes, Redirection, and Shell Built-ins](09-pipes-redirection-and-builtins.md)**
  — pipelines, redirection, command substitution, process substitution,
  built-ins, and shebang/script execution.

For the concepts behind these commands — the filesystem layout, storage,
permissions model, shells, and the Android process lifecycle — start in the
[Foundations](../00-foundations/00-intro.md) section. Installation and package
management are documented in the
[Termux](../01-termux/00-intro.md) section.

## On accuracy and version sensitivity

Every chapter is based on the audited Phase 3 research notes
(`research/commands/00-shell-command-bible-research.md`). Claims that are
**version-sensitive** (depend on Android or Termux versions) or **device
-dependent** (output text, sizes, or behavior that must be observed on a real
device) are explicitly marked. Unresolved device-dependent behavior is
documented as *variable* rather than asserted as a universal fact. If
something conflicts with what your installed Termux shows, trust your device
and your `--help` output and update the documentation accordingly.