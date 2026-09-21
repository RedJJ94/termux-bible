# Shell Command Bible — Research Notes (Phase 3)

Status: research notes supporting Phase 3 "Shell Command Bible" (PLAN.md §32) and
PLAN.md §7 (Shell Command Encyclopedia) / Volume II (Shell Command Bible).
Not polished documentation. Distinguished from Bible chapters per AGENTS.md §17 / PLAN.md §21.
Compiled: 2026-09-21. Environment note: research performed from a proot (Ubuntu)
container; **no live Termux device was available**. Facts that require empirical
on-device confirmation are marked **[DEVICE]** and listed in §9. Everything
version/Android/device-sensitive is tagged **[version-sensitive]** / **[device]**.

Audit note: primary authority for "is command X available, and which package
provides it" is the **termux-packages repository at `master`** (bootstrap script
`scripts/generate-bootstraps.sh` + per-package `build.sh` + subpackage files),
plus **termux-tools** `scripts/Makefile.am` (system-command wrappers) and the
**termux-packages developer wiki** (cloned GitHub wiki). Package lists were read
from the GitHub trees API snapshot of `master`, not from memory.

---

## 1. Scope

PLAN.md §32 Phase 3 must build the core command reference. Topics:

- filesystem commands;
- text processing;
- process management;
- permissions;
- archives;
- networking;
- system utilities;
- command pipelines;
- redirection.

Deliverable: a substantial shell command encyclopedia.

Volume II scope also lists: navigation, files and directories, viewing and editing
files, searching, pipes, compression, package management, common GNU/Linux
utilities. PLAN.md §7 enumerates the concrete command set (filesystem: pwd, ls,
cd, mkdir, rmdir, touch, cp, mv, rm, ln, find, locate; text: cat, less, head,
tail, grep, sed, awk, cut, sort, uniq, tr, wc; processes: ps, top, pgrep, pkill,
kill, jobs, fg, bg; archives: tar, gzip, gunzip, zip, unzip; networking: curl,
wget, ssh, scp, sftp, DNS utilities, socket/network diagnostic utilities; system
info: uname, id, whoami, df, du, free, uptime).

This research verifies, for the native Termux environment, which of those commands
are present in a fresh install (the "bootstrap"), which require `pkg install`,
and which differ from a standard GNU/Linux distribution. `cd`, `jobs`/`fg`/`bg`,
pipes and redirection are **bash shell features**, not packages; they are covered
in §4.9.

---

## 2. Source Inventory and Reliability Ranking

Reliability tiers (AGENTS.md §3.2):

- A — official repository source (`termux-packages` build scripts, `termux-tools`
  Makefile.am, bootstrap generator).
- B — official developer wiki (`github.com/termux/termux-packages/wiki`, cloned).
- C — user wiki (wiki.termux.com / wiki.termux.dev) — carries DEPRECATION NOTICE,
  content can be stale; used only for cross-checking.
- D — community material. Used only for discovery.

| Ref | Source | Kind | How obtained |
|-----|--------|------|--------------|
| P1 | `termux-packages/scripts/generate-bootstraps.sh` (master) — authoritative current bootstrap package list | A | raw.githubusercontent.com |
| P2 | `termux-packages/packages/{package}/build.sh` + `*.subpackage.sh` (master) | A | raw.githubusercontent.com |
| P3 | GitHub trees API snapshot of `termux-packages` master (package existence + file lists) | A | api.github.com |
| P4 | `termux-tools/scripts/Makefile.am` (master) — installed scripts + `/system/bin` wrappers | A | raw.githubusercontent.com |
| P5 | Developer wiki `Termux-execution-environment.md` (clone of `termux-packages.wiki`) | B | git clone |
| P6 | Developer wiki `Termux-file-system-layout.md` (clone of `termux-packages.wiki`) | B | git clone |
| P7 | Developer wiki `Package-Management.md`, `For-maintainers.md` (clone) | B | git clone |
| P8 | Phase 2 research notes: `research/termux/00-foundations-research.md` | project | local |

Access notes: `raw.githubusercontent.com` fetches worked reliably. The GitHub
wikis clone cleanly with `git clone --depth 1` (recommended future technique;
direct wiki HTML is truncated). User wiki still blocked by Anubis (see Phase 2
notes §11).

**Bootstrap list authoritative-ness:** the exact package set listed in
generate-bootstraps.sh is the single most important source for "what exists in a
fresh Termux install". It is **[version-sensitive]**; it changes with releases.

---

## 3. What a Fresh Termux Install Contains (the "bootstrap")

Source: P1 (`scripts/generate-bootstraps.sh`, master, research date 2026-09-21).
Interpretation: the script `pull_package`s these; the Termux app installs this
bootstrap at first run. **[version-sensitive]**.

### 3.1 Core utilities (always included, apt manager)

- `apt` (the package manager itself)
- `bash`, `dash`
- `bzip2` (binary subpackage of `libbz2`, P2/P3)
- `command-not-found` (non-Android-10 bootstrap variant; replaced by `proot` in the
  Android-10 variant) — provides "command not found" package suggestions
- `coreutils` (GNU coreutils 9.11, P2) — see §4.1/§4.9 for what it *excludes* in Termux
- `curl` (8.22.0, binary subpackage of `libcurl`, P2/P3)
- `diffutils` (3.12, P2)
- `findutils` (4.10.0, P2) — provides `find` and `xargs`; `locate`/`updatedb`
  explicitly removed (they come from `mlocate`)
- `gawk` (5.3.2, P2) — GNU awk
- `grep` (3.12, P2; links pcre2, so `grep -P` is available)
- `gzip` (1.14, P2)
- `less` (710, P2)
- `procps` (4.0.7, P2) — `ps`, `free`, `uptime`, `vmstat`, `watch`, `pgrep`,
  `pkill`, `pidof`, `sysctl`, etc.; `kill` and `top` are disabled/removed (see §4.4)
- `psmisc` (23.7, P2) — `killall`, `fuser`, `pstree`, `pidof`(dup), `peekfd`
- `sed` (GNU sed 4.10, P2)
- `tar` (GNU tar 1.35, P2)
- `termux-core`, `termux-exec`, `termux-keyring`, `termux-tools` (P1)
- `util-linux` (2.42.1, P2) — `column`, `script`, `hexdump`, `dmesg`, `setterm`,
  `ul`, `cal`, `lscpu`…; notable *disabled* tools §4.8
- `xz-utils` (binary subpackage of `liblzma`, P2/P3) — `xz`, `unxz`, `xzcat`
- `debianutils` (5.24, P2; apt manager only) — its `which` is removed by the build
  (see §4.1): `which` therefore comes from the separate `which` package

### 3.2 Additional utilities in the same bootstrap

- `ed`, `dos2unix`, `inetutils` (2.7, P2 — see §4.7), `lsof`, `nano`, `net-tools`
  (2.10, P2 — `netstat`/`ifconfig`/`route`/`arp`; `hostname` disabled), `patch`,
  `unzip` (6.0, P2)

### 3.3 Explicitly NOT in the bootstrap (verified from P1)

`zip`, `wget`, `openssh` (`ssh`/`scp`/`sftp`), `mlocate` (`locate`/`updatedb`),
`dnsutils` (`dig`/`nslookup`/`host`), `file`, `which`, `iproute2` (`ss`/`ip`),
`traceroute`, `nmap`, `jq`, `rsync`, `htop`, `ncdu`, `tree`, `bat`, `fd`,
`fzf`, `ripgrep`, `vim`/`neovim`/`emacs`, `netcat-openbsd`, `socat`, `zsh`
(`btop`/`bpytop`/`bashtop` are not present in termux-packages master, P3).
Each of these installs with `pkg install <name>` and is confirmed present as a
package in termux-packages master (P3). Package names are authoritative and
Termux-specific (e.g. DNS clients are **`dnsutils`**, not "bind-tools" —
`bind-tools` does **not** exist in termux-packages).

---

## 4. Verified Findings by Category

All package/command presence facts below are from P1/P2/P3 unless noted.

### 4.1 Filesystem commands (including navigation and permissions basics)

| Command | Provider | In bootstrap? | Notes / Termux-specific |
|---------|----------|---------------|--------------------------|
| `pwd` | bash builtin + coreutils | yes | both exist; fine |
| `cd` | bash builtin | n/a | shell feature |
| `ls` | coreutils (GNU) | yes | default is not colorized; add color with `ls --color=auto`. `ls` of `/sdcard` shows FAT-emulated fs semantics (§5). |
| `mkdir`, `rmdir`, `touch`, `cp`, `mv`, `rm`, `ln` | coreutils | yes | work on app-private storage (`$HOME`, `$PREFIX`). On shared/external storage (`~/storage/...`) symlinks cannot be created and file-type features are limited (§5, P5). |
| `find` | findutils 4.10.0 | yes | Termux build enables `-fstype` parsing from `/proc/self/mountinfo` (P2 build.sh) |
| `xargs` | findutils | yes | |
| `locate` / `updatedb` | mlocate 0.26 | **no** | `pkg install mlocate`; DB at `$PREFIX/var/mlocate/mlocate.db`; must run `updatedb` first (postinst reminder, P2). findutils deliberately does not install locate/updatedb (P2). |
| `which` | which 2.25 | **no** | `pkg install which`. debianutils′ `which` is removed from the termux build (P2). `type`/`command -v` are bash builtins and always work. |
| `df` | termux-tools wrapper → `/system/bin/df` (toybox) | yes | **coreutils `df` is explicitly NOT built** ("df does not work either, let system binary prevail", P2 coreutils build.sh). So `df` in Termux is the Android toybox `df` via the termux-tools wrapper (P4). `df -h` is the common invocation. **[DEVICE]** verify output shape. |
| `du` | coreutils | yes | standard GNU |
| `chmod` / `umask` | coreutils / bash | yes | see §4.5 (permissions) |
| `chown` / `chgrp` | coreutils | yes | see §4.5 — mostly non-functional without root |
| `file` | libmagic subpackage `file` | **no** | `pkg install file` (P2/P3) |
| `tree` | tree pkg | **no** | `pkg install tree` |
| `locate` alternatives | `find`, `fd`, `fzf` | find yes / others **no** | `fd` and `fzf` are separate packages |

### 4.2 Text processing and searching

| Command | Provider | In bootstrap? | Notes |
|---------|----------|---------------|-------|
| `cat`, `head`, `tail`, `cut`, `sort`, `uniq`, `tr`, `wc` | coreutils | yes | standard GNU behavior |
| `less` | less 710 | yes | pager; works with `$TERM=xterm-256color` |
| `grep` | grep 3.12 | yes | GNU grep; pcre2 dependency → `grep -P` supported (P2). `grep -E` (ERE) standard. |
| `sed` | GNU sed 4.10 | yes | GNU stream editor |
| `awk` | gawk 5.3.2 | yes | `gawk` provides awk; **[DEVICE]** confirm `$PREFIX/bin/awk` vs `gawk` (no subpackage file in repo; assumed symlink/copy installed by gawk). Alternative `mawk` is **not** in termux-packages (P3). |
| `sort`/`uniq`/`cut`/`tr` | coreutils | yes | |
| `diff`, `cmp`, `diff3`, `sdiff` | diffutils 3.12 | yes | |
| `nl`, `join`, `paste`, `comm`, `expand`, `unexpand`, `fold` | coreutils | yes | |
| `base64`, `od`, `hexdump` | coreutils / util-linux | yes | `od` from coreutils; `hexdump` from util-linux |
| `dos2unix` / `unix2dos` | dos2unix | yes | in bootstrap |
| `col`, `column` | util-linux | yes | in bootstrap (P2 dependency comments list `column`) |
| `jq` | jq pkg | **no** | `pkg install jq` (JSON; often used in Termux workflows) |
| `ripgrep`/`rg`, `bat`, `fd`, `fzf` | separate pkgs | **no** | modern alternatives, all present in termux-packages (P3) |

### 4.3 Viewing and editing files

| Command | Provider | In bootstrap? | Notes |
|---------|----------|---------------|-------|
| `cat`, `less`, `head`, `tail` | coreutils / less | yes | standard |
| `nano` | nano | yes | default editor shipped in bootstrap |
| `vim`, `neovim`, `emacs` | packages | **no** | `pkg install vim` (vim-python does not exist as separate package; P3) |
| `ed` | ed | yes | historical text editor, included in bootstrap |

### 4.4 Process management and job control

| Command | Provider | In bootstrap? | Notes / Termux-specific |
|---------|----------|---------------|--------------------------|
| `jobs`, `fg`, `bg`, `wait`, `kill`(builtin), `disown` | bash builtins | n/a | shell job control; works normally in foreground Termux sessions |
| `kill` | coreutils (`--enable-install-program=kill`, P2) | yes | external `kill` from coreutils; procps `kill` is disabled AND removed (P2 procps). |
| `ps` | procps 4.0.7 | yes | procps `ps` (reads `/proc`). **Termux build detail:** `/proc/stat` is not readable unrooted, so procps is compiled with `-DMOCK_STAT_FILE` and a static mock is installed to `$PREFIX/var/procps/stat` (P2). **[DEVICE]** verify `ps` output and whether percentages look sane. |
| `top` | termux-tools wrapper → `/system/bin/top` (toybox) | yes | **`top` in Termux is the Android system (toybox) top, not procps top.** procps `top` is disabled (`--disable-modern-top`) and removed from the package (P2), because "the system top works better". For a GNU-style top use `pkg install htop` (`btop` is **not** in termux-packages main, P3). |
| `pgrep`, `pkill` | procps | yes | |
| `pidof` | procps | yes | toybox also has pidof under /system/bin |
| `killall`, `fuser`, `pstree` | psmisc | yes | |
| `free` | procps | yes | reads `/proc/meminfo`; **[DEVICE]** verify sane numbers on Android |
| `uptime` | procps | yes | coreutils does NOT ship uptime in Termux (it is provided by procps, P2 coreutils comment); procps reads `/proc/uptime` |
| `vmstat`, `watch`, `sysctl` | procps | yes | |
| `w`, `slabtop` | procps (removed) | — | explicitly removed from the Termux procps package (`TERMUX_PKG_RM_AFTER_INSTALL`, P2) |
| backgrounding `... &` | bash | n/a | see §5 daemon/phantom-process notes |

Job control / backgrounding caveats (P5): daemonized processes reparent to
`init` (ppid 1) and "have a higher chance of getting killed"; keeping a process
in the foreground (e.g. `sshd -D`) ties it to the app process and is less likely
to be killed (assuming the phantom process killer is disabled; see Phase 2 notes
for Android 12+ phantom process behavior).

### 4.5 Permissions and ownership (Android-specific)

- `chmod`, `umask` work on files you own in app-private storage (`$HOME`,
  `$PREFIX`). **[DEVICE]** verify the default `umask` on a real device.
- `chown` / `chgrp`: on an unrooted phone you cannot change ownership; Termux is
  effectively single-user and all files belong to the app uid (e.g. `u0_a160`,
  see P6). `chown` will not be permitted. `chgrp` is limited to groups the
  process is a member of, which on Android is essentially the app's own group.
  Treat "`chown user:group file`" as **root-only** in Termux.
- **setuid/setgid bits do not grant extra privilege to app processes on Android.**
  Android/SELinux restricts domain transitions; do not document setuid as a
  privilege mechanism. Behavior is SELinux/kernel governed and should be
  **[DEVICE]-verified before any claim.** (No authoritative source confirming a
  universal rule was obtained; mark as needing verification, draft accordingly.)
- External storage (`~/storage/...`, `/sdcard`): FAT-emulating mounts (`sdcardfs`
  or FUSE), `noexec`, no symlinks, case-insensitive filenames (P5). Permission /
  ownership changes are effectively unsupported there. A wiki statement reads
  "Files do support modifications of file permissions or ownership attributes"
  (P5) — this appears to be missing a "not" (contradicts the surrounding text and
  reality of the FAT emulation); **treat as ambiguous, verify on device**.
- **Security note for the encyclopedia:** `chmod`, `chown`, `chgrp`, `rm -rf`,
  and anything that overwrites files must carry appropriate warnings per
  AGENTS.md §11. `rm -rf` on a wrong path is destructive anywhere, and Termux has
  no trash mechanism by default.

### 4.6 Archives and compression

| Command | Provider | In bootstrap? | Notes |
|---------|----------|---------------|-------|
| `tar` | GNU tar 1.35 | yes | current is GNU tar (P2). Historical Termux shipped a busybox-style tar with fewer options — do not document old behavior as current. |
| `gzip`, `gunzip` | gzip 1.14 | yes | GNU gzip |
| `bzip2`, `bunzip2` | bzip2 (libbz2 subpackage) | yes | |
| `xz`, `unxz`, `xzcat` | xz-utils (liblzma subpackage) | yes | |
| `zip` | zip 3.0 | **no** | `pkg install zip` (P2) |
| `unzip` | unzip 6.0 | yes | in bootstrap (P1) |
| `7z` | 7zip | **no** | `pkg install 7zip` (P3; last blocker: on-device build). There is no `p7zip` package. |
| `cpio` | cpio | **no** | not verified in list; check at draft time |
| `rsync` | rsync | **no** | `pkg install rsync` |
| `bsdtar` | libarchive | **no** | libarchive package exists; bsdtar is offered inside proot-distro (`proot-distro` pulls `bsdtar`?) — **unverified**, do not claim. |

### 4.7 Networking, downloads, DNS, and diagnostics

| Command | Provider | In bootstrap? | Notes / Termux-specific |
|---------|----------|---------------|--------------------------|
| `curl` | curl 8.22.0 (libcurl subpackage) | yes | essential. CA store at `$PREFIX/etc/tls/cert.pem` (built into curl via `--with-ca-bundle`, P2; file maintained by `ca-certificates` package, which `openssl` depends on). TLS works out of the box. |
| `wget` | wget 1.25.0 | **no** | `pkg install wget` (P2). |
| `ssh`, `scp`, `sftp`, `ssh-keygen`, `ssh-agent`, `ssh-add`, `ssh-copy-id`, `ssh-keyscan`, `sshd` | openssh 10.5p1 | **no** | `pkg install openssh`. Config under `$PREFIX/etc/ssh/`; depends on `termux-auth`; `slogin` removed; wrappers `ssha`/`scpa`/`sftpa` installed (P2). sshd service scripts under `$PREFIX/var/service/sshd` require `termux-services` (runit). **Port note:** binding ports <1024 on Android generally requires root — relevant when documenting sshd port choice (Phase 9 topic; do not fix a default here). |
| `ping`, `ping6` | termux-tools wrappers → `/system/bin/ping[6]` | yes | wrapper unsets `LD_LIBRARY_PATH`/`LD_PRELOAD`, sets `PATH=/system/bin`, execs the toybox binary (P4). **[DEVICE, version-sensitive]** `ping6` may not exist on newer Android; toybox `ping` gained `-6`. Verify which exists per Android version before documenting. |
| `netstat`, `ifconfig`, `route`, `arp` | net-tools 2.10 | yes | in bootstrap. `hostname` is NOT built (`HAVE_HOSTNAME_TOOLS=0`, P2). |
| `ss`, `ip` | iproute2 | **no** | `pkg install iproute2` (modern replacement for net-tools). |
| `dig`, `nslookup`, `host` (BIND clients) | dnsutils 9.20.29 | **no** | `pkg install dnsutils` (package name is `dnsutils`, not bind-tools). Reads `$PREFIX/etc/resolv.conf`. **[DEVICE]** confirm exact binary set with `pkg files dnsutils`. |
| `telnet`, `tftp`, `ftp`, `hostname`, `logger` | inetutils 2.7 | yes | in bootstrap. **Disabled in the Termux build:** ifconfig, ping, ping6, rcp, rlogin, rsh, traceroute, whois (P2). So `hostname`/`logger` come from inetutils. |
| `logger` | inetutils (patched) | yes | **Termux-specific:** inetutils `logger.c` is patched to `PATH_LOG="logcat"` and linked with `-llog` — messages go to Android logcat (P2). Document this difference from Linux. |
| `traceroute` | traceroute pkg | **no** | `pkg install traceroute` (P3). GNU inetutils traceroute disabled. |
| `nmap` | nmap | **no** | `pkg install nmap` |
| `hostname` | inetutils | yes | prints/reads Android hostname via gethostname; **[DEVICE]** verify expected output. |
| `resolv.conf` / `hosts` | resolv-conf 1.3 | yes (pulled as dependency) | files: `$PREFIX/etc/resolv.conf` = `nameserver 8.8.8.8` / `8.8.4.4`; `$PREFIX/etc/hosts` = localhost entries (P2). **[version-sensitive; conffile]** users may modify; the values are a Termux packaging default. |

### 4.8 System information and utilities

| Command | Provider | In bootstrap? | Notes |
|---------|----------|---------------|-------|
| `uname` | coreutils | yes | GNU uname; **[DEVICE]** record real output (kernel version of device). |
| `id` | coreutils | yes | shows app uid/gid (e.g. `uid=10160(u0_a160)`), not `root`. |
| `whoami` | coreutils | yes | derived from uid via bionic → prints `u0_aXXX`-style name (P6) **[DEVICE]** |
| `df` | wrapper → toybox | yes | see §4.1 |
| `du` | coreutils | yes | |
| `free` | procps | yes | /proc/meminfo |
| `uptime` | procps | yes | /proc/uptime |
| `getprop` | termux-tools wrapper → toybox | yes | Android system properties (`getprop ro.build.version.release`, etc.) — useful Termux-specific system info |
| `dmesg` | util-linux | yes | may be restricted by SELinux on unrooted devices; **[DEVICE]** |
| `lscpu`, `lspci`(?)/`lsusb` | util-linux | yes (lscpu) | toybox lspci/lsusb exist under /system/bin; Termux util-linux does not provide lspci/lsusb (not in P1/P2 dependency list) — verify at draft time |
| `logger` | inetutils | yes | logcat-backed (see §4.7) |
| `column`, `script`, `hexdump`, `setterm`, `ul`, `cal` | util-linux 2.42.1 | yes | util-linux in bootstrap |
| **Disabled in Termux util-linux build** | util-linux | — | `wall`, `logger`, `mesg`, `kill`, `ipcs/ipcmk/ipcrm`, `last`, `agetty`, `mountpoint`, `pivot_root`, `switch_root`, `eject`, `rfkill`, `hwclock(-cmos)`, `nologin`, `raw`, `fdformat`, `copyfilerange`(?), `chmem`, `lsmem`, `poman`, `makeinstall-chown` (P2 flags). Consequence: `wall` and `logger` are NOT available from util-linux; logger comes from inetutils. `mountpoint`, `ipcs` etc. are absent — do not document as present. |
| `bc` / `dc` | bc / dc(?) pkg | **no** | `pkg install bc` (P3). |

### 4.9 Pipes, redirection, and shell builtins

These are **bash** features (no package):

- pipes `|`, redirection `>` `>>` `<`, here-docs/here-strings, `2>&1`, `2>/dev/null`,
  `&` backgrounding, `&&`/`||`, command substitution `$(...)`, job control
  `jobs/fg/bg/wait`, `&`/`disown`.
- Builtins available in bash: `cd`, `pwd`, `echo`, `printf`, `test`/`[`, `read`,
  `type`, `command`, `alias`, `export`, `unset`, `set`, `shift`, `umask`,
  `ulimit`, `exec`, `source`/`.`, `return`, `exit`, `trap`, `kill`, `jobs`, `fg`,
  `bg`, `wait`, `setopt`/`shopt` (bash), `local`, `declare`, `let`, `case`,
  `select`, `getopts`, etc. Standard bash semantics; verify interactively with
  `type -a <cmd>`.
- **Termux-specific bash build notes (P2 bash build.sh):**
  - Process substitution `<(cmd)` works via `/proc/self/fd` (`bash_cv_dev_fd=whacky`);
  - `getcwd` handling is fixed for the `/data/data/com.termux/files` depth
    (`bash_cv_getcwd_malloc=yes`) — addresses termux-app issue #200;
  - `dash` is also installed (as `/bin/sh`-capable shell); **do not assume
    `sh` == bash** — **[DEVICE]** confirm `readlink -f $PREFIX/bin/sh` and which
    interpreter a `#!/bin/sh` script actually selects.
- Script shebangs: `/bin/*`-style shebangs resolve through the Android link layer
  (`/bin` is a symlink to `/system/bin`); `termux-exec` (installed by default,
  loaded via `LD_PRELOAD`) hooks exec to fix `/bin/sh`-style shebangs and app-data
  W^X execute restrictions (P5). `termux-fix-shebang` rewrites shebangs explicitly.
  Relevant to the encyclopedia's "scripts / shebang" entries.
- Executing scripts/bins on external storage fails (`noexec`); run through an
  interpreter (e.g. `bash /sdcard/script`) (P5).

---

## 5. Termux-Specific Behaviors That Affect the Command Encyclopedia

Verified against P4/P5/P2 (each tagged above in §4):

1. `df` and `top` are **not GNU coreutils/procps tools** — they are the Android
   system toybox binaries executed through termux-tools wrappers. This is the
   single most important "looks standard but is not" case in the Phase 3 set.
2. Default `$PATH` in Termux is `$PREFIX/bin` only (Android >=7). `/system/bin` is
   deliberately excluded to avoid conflicts (P5/P6). Documentation should not tell
   users to add `/system/bin` to `$PATH` before Termux paths.
3. `chown`/`chgrp` are effectively unusable unrooted; the environment is
   single-user; username strings derive from the app uid (P6).
4. External storage (`~/storage/...`) behaves like FAT (noexec, no symlinks,
   case-insensitive); keep command examples under `$HOME`/`$PREFIX`.
5. Daemonized background processes are more likely to be killed (ppid becomes 1;
   phantom-process killer on Android 12+) — document `sshd -D`-style foreground
   suggestions where applicable (P5).
6. `logger` writes to Android logcat instead of `/var/log` (P2 inetutils).
7. `resolv.conf` defaults to 8.8.8.8/8.8.4.4 (P2 resolv-conf).
8. GNU tool versions (P2): coreutils 9.11, grep 3.12, sed 4.10, gawk 5.3.2,
   findutils 4.10.0, tar 1.35, less 710, diffutils 3.12 — so documented options
   should follow current GNU manuals; **[version-sensitive]** review at draft time.
9. CA bundle for TLS tools at `$PREFIX/etc/tls/cert.pem` (curl built against it;
   `ca-certificates` maintains it) (P2).
10. `command-not-found` package (bootstrap, non-Android-10) prints install hints
    for unknown commands — useful for a "command not found" troubleshooting note.

## 6. Native Termux vs proot / proot-distro

- The map in §3–§4 applies to **native Termux** (the environment provided by the
  Termux bootstrapping toolchain in `$PREFIX`).
- Inside a **proot-distro** container (e.g. Ubuntu/Debian/Arch), the commands come
  from that distribution's own packages and follow FHS paths (`/bin`, `/usr/bin`,
  `/etc`). GNU-flavored tools (coreutils, grep, sed, awk, tar) share option syntax
  with native Termux in the common cases, but package names, paths, `PATH`, and
  even command sets differ (e.g. distro `df` is GNU coreutils df, while native
  Termux `df` is the system wrapper; distro `ps` may be procps or busybox).
- Per AGENTS.md §6, the Phase 3 chapters must state which environment a command
  entry assumes. Recommended: the encyclopedia describes **native Termux** and
  adds a short cross-link/framing note that inside a proot distro the reader
  should consult that distro's own documentation. No behavior was assumed to
  transfer between the two environments.

## 7. Version-Sensitive / Device-Dependent Items (must carry a tag in the Bible)

- Bootstrap package list (P1) — changes over releases; re-check at draft time.
- Package/command versions above (§5.8).
- `ping6` existence and behavior — Android version dependent (P4 wrapper always
  installed; target binary may differ by Android version) **[DEVICE]**.
- toybox `/system/bin` tool availability and option support — Android version and
  device dependent (P5 lists Android 14 `/system/bin`).
- App uid/username representation (`id`, `whoami` output) — derived from uid;
  differs per device but follows the documented formula (P6).
- `ps` / `free` / `uptime` / `vmstat` output on real devices — procps against
  Android `/proc`; mock `/proc/stat` file in place for stat-dependent features
  (P2) **[DEVICE]**.
- `setuid`/`setgid` effectiveness — SELinux/Android governed; **[DEVICE, needs
  verification]** treat as non-functional for privilege gain, do not assert detail.
- Default `umask` and `ls` aliasing/color `LS_COLORS` in the shipped
  `etc/bash.bashrc` — **[DEVICE]** record on a real install.
- `sh` → dash vs bash resolution — [DEVICE] `readlink -f $PREFIX/bin/sh`.
- ca-certificates bundle refresh date (2026.08.13 at research time) — not
  important to document; TLS path is.
- Android 12+ phantom process killer affects long-running/background commands
  (Phase 2 note; link from process/job section).

## 8. Commands Commonly Expected but NOT Available in a Fresh Termux (install list)

Verified via P1 (bootstrap) + P3 (package existence). The encyclopedia's
"prerequisites" lines should state `pkg install` for these:

- `zip` → `pkg install zip`
- `wget` → `pkg install wget`
- `ssh`/`scp`/`sftp`/`sshd` → `pkg install openssh`
- `dig`/`nslookup`/`host` → `pkg install dnsutils`
- `locate`/`updatedb` → `pkg install mlocate`
- `file` → `pkg install file`
- `which` → `pkg install which`
- `ss`/`ip` → `pkg install iproute2`
- `traceroute` → `pkg install traceroute`
- `nmap` → `pkg install nmap`
- `jq` → `pkg install jq`
- `htop` → `pkg install htop` — modern `top` (`btop`/`bpytop`/`bashtop` are **not** in termux-packages main, P3)
- `tree`, `ncdu`, `bat`, `fd`, `fzf`, `ripgrep` → respective packages
- `rsync` → `pkg install rsync`
- `7z` → `pkg install 7zip` (no p7zip package)
- `screen` / `tmux` → `pkg install screen` / `tmux`

Absent entirely from termux-packages master (P3): `bind-tools`, `p7zip`, `mawk`,
`vim-python` (use `vim`), `file` as a top-level package (it is the `libmagic`
subpackage `file`).

## 9. Live-Device Verification Checklist [DEVICE]

Run on a real Termux install (Android >= 11 preferred) and record outputs for the
Phase 3 draft:

- `pkg list-installed | head` and `pkg files coreutils`, `pkg files procps`,
  `pkg files termux-tools`, `pkg files util-linux`, `pkg files inetutils`,
  `pkg files dnsutils` (post `pkg install dnsutils`) → confirm exact binary sets.
- `readlink -f $PREFIX/bin/sh; readlink -f $PREFIX/bin/awk; readlink -f $PREFIX/bin/ls`
- `type -a df top ps pwd kill which ls` → show wrapper vs coreutils vs builtin.
- `df -h $HOME /sdcard /data` → capture toybox df output text.
- `top -n 1` (if supported) → capture toybox top banner/options; test `-d`/`-o`.
- `ps aux; ps -ef; pgrep -l bash; pkill -l` — confirm options work.
- `free; uptime; vmstat 1 3; watch -n 1 date` (watch needs tty).
- `echo $PATH; echo $PREFIX; umask; whoami; id; uname -a; getprop ro.build.version.release; getprop ro.product.model`
- `ls -l $HOME $PREFIX`; `ls -l /sdcard` (record fake perms/symlink absence);
  attempt `ln -s` and `touch` on `~/storage` to record failure modes.
- `ls --color=auto /` vs plain `ls`; check `alias ls`, `$LS_COLORS`.
- `hostname`; `logger test123; logcat -d | tail` to confirm logcat routing.
- `cat /proc/self/mountinfo | head` for -fstype examples; `find / -maxdepth 1 -fstype ext4`
- `curl -I https://example.com` (TLS/CA works); `wget --version`; `dig +short google.com`
  (after `pkg install wget dnsutils`).
- `nslookup`/`host` behavior; `cat $PREFIX/etc/resolv.conf`.
- `setuid` experiment (if comfortable): create a setuid copy of a harmless binary
  in `$HOME` and check `ps`/effective uid — result should be "stays app uid".
- `ping6` and `ping -6` availability per Android version.
- `cat <(date)` (process substitution); unnamed pipe / FIFO in `$HOME`;
  `bash -c 'echo hi' /bin/sh` shebang behavior under termux-exec.
- `pkg search zip wget openssh` (confirm package names and availability).

## 10. Conflicting / Outdated Sources Identified

- **User wiki (deprecated)** — still live but carries DEPRECATION NOTICE; do not
  cite for Phase 3. Some old wiki claims (e.g. "df differs", "top is removed")
  are **corroborated** by current repo sources (P2) and safe to document; claims
  that contradict P1/P2/P4 should be ignored.
- **Ambiguous wiki statement in P5:** "Files do support modifications of file
  permissions or ownership attributes" on external storage — almost certainly a
  missing "not"; contradicted by surrounding text. Resolve on device (§9) before
  drafting; otherwise phrase carefully.
- **Historical package layout confusions:** (a) `curl`, `bzip2`, `xz-utils`,
  `file` are *subpackages* of `libcurl`/`libbz2`/`liblzma`/`libmagic`
  respectively — `pkg install curl` works, but reading the package directory
  listing alone would imply they don't exist; (b) `dnsutils` is the Termux name
  for BIND clients — "bind-tools" does not exist; (c) findutils alone does not
  provide `locate` — mlocate does.
- **Old `tar` behavior:** older Termux shipped a busybox-based tar with limited
  options; current is GNU tar 1.35 (P2). Do not carry forward old tar examples.

## 11. Unresolved Questions / Missing Research

1. Exact binary file list per package (e.g. `psmisc`, `util-linux`, `dnsutils`,
   `gawk`/`awk` symlink) — resolved inventory is from build.sh flags; a device
   `pkg files <pkg>` run is the authoritative final check.
2. `setuid`/`setgid` precise behavior on stock Android for app-data files — no
   authoritative single source found; needs device result and/or Android
   documentation, then phrase accordingly.
3. Default `umask` and shipped bash aliases/`LS_COLORS` in `etc/bash.bashrc` —
   needs device capture (file exists in repo: `packages/bash/etc-bash.bashrc` —
   fetch at draft time to confirm default aliases).
4. `ping6` wrapper target on current Android (what `/system/bin/ping6` is, if
   present) — device/Android version dependent.
5. Whether `lspci`/`lsusb` need documenting (Termux util-linux does not build
   them; toybox `/system/bin` versions only, and `lsusb` often needs the USB
   service) — low priority; decide at draft time.
6. `command-not-found` behavior (which prompt does it print) — device capture.
7. Whether "ed" deserves encyclopedia coverage (in bootstrap, but niche) —
   editorial decision.
8. Whether to document `/system/bin` toybox commands at all in Phase 3, or hand
   them to Phase 4 (Android/ADB). Recommendation: only document them where they
   ARE the selected binary behind a Termux command (`df`, `top`, `ping`) or as a
   cross-link, per AGENTS.md §6.

## 12. Suggested Drafting Structure (do not draft now)

Mapping Phase 3 topics → planned encyclopedia locations (PLAN.md §7 directory
`15-command-encyclopedia/`, Volume II = chapter group `02-shell/`):

1. **Navigation & filesystem** (pwd, ls, cd, mkdir, rmdir, touch, cp, mv, rm, ln,
   find, xargs, df, du, file, tree) + external-storage caveats (§5.4).
2. **Viewing/editing** (cat, less, head, tail, nano, vim; od/hexdump).
3. **Searching/text** (grep, sed, awk, cut, sort, uniq, tr, wc, comm, paste, join,
   diff family, dos2unix, jq, ripgrep/fd/bat/fzf as extensions).
4. **Processes & jobs** (ps, top, pgrep, pkill, pidof, killall, fuser, pstree,
   kill, jobs/fg/bg, free, uptime, vmstat, watch) + phantom-process/daemon notes
   (§5.5).
5. **Permissions** (chmod, chown, chgrp, umask) + Android single-user/setuid
   reality (§4.5) + security warnings (AGENTS.md §11).
6. **Archives/compression** (tar, gzip/gunzip, bzip2, xz, zip/unzip, 7z) with the
   "install required" package table (§8).
7. **Networking** (curl, wget, ssh/scp/sftp, ping, netstat/ss, dig/nslookup/host,
   hostname, logger, traceroute/nmap) + CA bundle + resolv.conf facts (§4.7).
8. **System utilities** (uname, id, whoami, getprop, dmesg, lscpu, free, uptime,
   column, script, hexdump) (§4.8).
9. **Pipelines/redirection/builtins** — shell feature chapter (§4.9) with bash
   build notes and shebang/termux-exec framing.
10. **Prerequisites per command** — reuse the §8 install table; state environment
    (native Termux) at the volume/chapter intro; add a "native vs proot" framing
    note (§6) early in the volume.

Cross-links to keep: this volume ↔ 00-foundations shell/env chapter; process
backgrounding ↔ 01-termux processes/sessions; TLS/CA ↔ the security volume;
`logger` ↔ logcat/ADB chapter (Phase 4).

## 13. Source URL List

- P1 https://raw.githubusercontent.com/termux/termux-packages/master/scripts/generate-bootstraps.sh
- P2 per-package build.sh, e.g.
  - https://github.com/termux/termux-packages/tree/master/packages/{coreutils,procps,zip,wget,openssh,dnsutils,mlocate,net-tools,inetutils,util-linux,debianutils,tar,gzip,findutils,which,busybox,grep,less,diffutils,libcurl,libbz2,liblzma,libmagic,ca-certificates,resolv-conf,openssl,bash,unzip,psmisc,libacl}/
- P3 https://api.github.com/repos/termux/termux-packages/git/trees/master?recursive=1 (package existence)
- P4 https://raw.githubusercontent.com/termux/termux-tools/master/scripts/Makefile.am
- P5 https://github.com/termux/termux-packages/wiki (clone: https://github.com/termux/termux-packages.wiki.git) — Termux-execution-environment.md
- P6 same clone — Termux-file-system-layout.md
- P7 same clone — Package-Management.md, For-maintainers.md
- P8 research/termux/00-foundations-research.md (project)