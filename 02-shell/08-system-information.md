# System Information and Utilities

Commands that tell you about the device, the app sandbox, and your own
resources — often the first stop when diagnosing "why is this slow / why
can't I see that". Read the foundations
[Android Sandboxing](../00-foundations/02-android-sandboxing.md) for why some
system info is invisible to an unrooted app.

## In a fresh install

| Command | Provider |
|---------|----------|
| `uname`, `id`, `whoami`, `stat`, `du` | GNU coreutils |
| `df` | termux-tools wrapper → `/system/bin/df` |
| `free`, `uptime`, `vmstat`, `watch` | procps |
| `hostname`, `logger` | inetutils |
| `getprop` | termux-tools wrapper → `/system/bin/getprop` |
| `lscpu`, `column`, `script`, `cal`, `dmesg`, `setterm`, `rev`, `whereis`, `more` | util-linux |
| anything else about device or other apps | `/system/bin` — root/ADB/Shizuku only |

## `uname` — kernel and host info

GNU coreutils `uname`. On Android the kernel is the Android/Linux kernel, so
`uname -s` prints `Linux` and `uname -r` a kernel release like
`5.4.xxx-androidN-...-android12-...`. The **OS name** some systems show can
reflect Android branding. [variable: by device/Android version; record the
real output on your device]

```sh
uname -a            # all details: kernel name, hostname, release, version, machine
uname -m            # machine/arch (aarch64 on 64-bit phones)
uname -r            # kernel release
uname -s            # kernel name (Linux)
```

- On 64-bit phones `uname -m` prints `aarch64`; on 32-bit installs it prints
  `armv7l`. [device variable]

## `id` / `whoami` — user identity

```sh
id                      # uid=u0_aNNN(...) gid=... groups=...
whoami                  # username of the app UID
```

- In native Termux the uid is a high-range Android app uid (`u0_aNNN`); `id`
  also prints the supplementary group memberships Android assigns the process.
  The exact uid number and group list depend on the Android version and
  Termux install. [variable]
- `whoami` output is usually the app username like `u0_aNNN`.
- Inside root/adb contexts (e.g. `su`), `id` shows `uid=0(root)`. See
  [Privileged Access](../00-foundations/02-android-sandboxing.md).

## `getprop` — Android system properties

`getprop` is a `termux-tools` wrapper around `/system/bin/getprop`:

```sh
getprop                # dump all system properties (may be long)
getprop ro.serialno    # a specific property
getprop ro.build.version.release   # Android version
getprop ro.board.platform
```

- Options and output match the device's toybox `getprop`. Property names in
  the `ro.*`/`persist.*` buckets are standard but many values are
  device/vendor-specific. [variable]
- `getprop` requires **no root** to read. See
  [Termux Utilities](../01-termux/06-utilities.md).

## `df` / `du` / `stat` — storage

See [Filesystem and Navigation](01-filesystem-and-navigation.md) for `df` and
`du`. `stat` (GNU coreutils) gives inode-level detail:

```sh
stat file.txt          # size, blocks, inode, mtime, permissions
stat -c '%a %U %n' file.txt   # octal mode, owner, name
```

## `free` / `uptime` / `vmstat` — resource stats

procps tools whose numbers deviate from a desktop because unrooted Android
hides `/proc` and the data honours the app cgroup:

```sh
free -m
uptime
vmstat 2 5
```

- Values are **best-effort and variable** by device/Android version. See
  [Processes and Job Control](04-processes-and-jobs.md).

## `lscpu` — CPU info

`lscpu` is util-linux in the fresh install:

```sh
lscpu
```

- On some devices the output is minimal because `/sys` is restricted
  (unrooted). [variable] If too sparse, combine `nproc` (coreutils) and
  `getprop ro.board.platform`.

## `dmesg` — kernel log (limited)

`dmesg` is util-linux:

```sh
dmesg                 # kernel log — usually empty/unprivileged on Android
dmesg -c
```

- On unrooted Android, `dmesg` is normally **restricted** (returns nothing or
  permission denied). Root/ADB privileged contexts are required; see
  [Privileged Access](../00-foundations/02-android-sandboxing.md).

## `column` / `script` / `cal` / `rev` / `whereis` / `more`

util-linux utilities in the fresh install:

```sh
column -t file.tsv          # align columns to terminal width
printf 'a:b:c\n1:2:3\n' | column -s: -t   # custom separator
script session.log          # record a terminal session to session.log (exit to stop)
cal                         # this month's calendar
rev file.txt                # reverse each line
whereis ls                  # find binaries/man pages
more file.txt               # simple pager (see Viewing chapter)
```

`script` is handy for capturing command sequences for documentation.

## `shuf`, `seq`, `yes`, `factor`, `nproc`, `numfmt`

GNU coreutils odds and ends useful in one-liners:

```sh
seq 1 10 | shuf          # shuffle numbers
yes | <command>          # feed infinite input (careful)
nproc                    # CPU count
numfmt --to=iec 1234567  # format numbers (GNU coreutils)
sha256sum file.zip       # file checksum
```

## `cal` / `date`

- `date` and `cal`: `date` is GNU coreutils; `cal` util-linux. `date` shows
  the device time and formats easily:
  `date '+%Y-%m-%d %H:%M:%S'`.

## Android-specific info restrictions

Without root/ADB/Shizuku you cannot see: other-app processes, full memory
budgets, some `/sys`/`/proc` data, or the device's raw log buffer beyond the
app's own. Use the documented privileged paths when you need them:
[Privileged Access](../00-foundations/02-android-sandboxing.md).

## Native Termux vs. proot

Inside proot-distro, `uname` shows the host kernel (Android's underlying
Linux) even though you are in the guest; `hostname` and CPU info come from
the guest's own tools and `/proc` passthrough. `getprop` is Termux-only (it
invokes `/system/bin/getprop` outside the guest).

## Cross-references

- Storage commands: [Filesystem and Navigation](01-filesystem-and-navigation.md)
- Process resource views: [Processes and Job Control](04-processes-and-jobs.md)
- Privileged introspection:
  [Privileged Access](../00-foundations/02-android-sandboxing.md)

## References

- Phase 3 research notes §4.8 (system info), §5 (environment), §14 (audit
  log):
  `research/commands/00-shell-command-bible-research.md`.
- util-linux manual: <https://www.kernel.org/pub/linux/utils/util-linux/>