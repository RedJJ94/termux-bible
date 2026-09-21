# Processes and Job Control

Managing running processes is essential on Android where the system kills
background processes aggressively. This chapter covers monitoring (`ps`,
`top`, `free`, `uptime`, `vmstat`, `watch`, `pstree`, `lsof`) and control
(`kill`, `pkill`, `pgrep`, `pidof`, `killall`, `fuser`, plus the shell's
`jobs`/`fg`/`bg`).

Termux-specific facts that differ from desktop Linux:

- `top` and `df` are **Android system** binaries behind `termux-tools`
  wrappers, not procps tools. `ps`, `free`, `uptime`, `vmstat`, `watch`,
  `pgrep`, `pkill`, `pidof` are from **procps** 4.0.7 in the fresh install
  and behave GNU-style.
- `kill` in the fresh install is the **bash built-in** (coreutils' `kill` is
  also present and `kill` is a POSIX shell builtin); procps' `kill` is **not
  built** for Termux.
- `htop` is a separate package — `pkg install htop`.

## `ps` — process snapshots

`ps` is from procps 4.0.7 (in the fresh install). In an unrooted native
Termux session you see **your own processes only**; you cannot see other
apps' processes without elevated access.

```sh
ps                     # processes of your session
ps -ef                 # full listing with parent PID
ps aux                 # BSD-style listing with %CPU, %MEM
ps -eo pid,ppid,cmd --sort=-%cpu   # custom columns sorted by CPU
```

- Termux's procps reads process statistics from a mock `procfs`
  (`$PREFIX/var/procps/stat`) because `/proc`/`/sys` are restricted on
  unrooted Android; `ps aux` columns for CPU/memory percentages are estimates
  that may differ from a real `/proc`. [variable]
- Output fields and their accuracy depend on device and Android version.

## `top` — dynamic process view (Android wrapper)

`top` in native Termux is the **Android system `top`** (toybox) reached via a
`termux-tools` wrapper that execs `/system/bin/top`:

```sh
top            # interactive view; q quits
```

The output layout and options (delay, one-shot mode, sorting) are whatever
your device's `/system/bin/top` supports — **not** GNU/procps `top`, so
options in the toybox/handheld `top` may differ from what you know. [variable]
See [Termux Utilities](../01-termux/06-utilities.md).

For a GNU-style `top`, install `htop`:

```sh
pkg install htop
htop
```

## `pgrep` / `pidof` — find PIDs

```sh
pgrep -l ssh           # print matching PID and name
pgrep -u $(id -un)     # processes of the current user
pidof bash             # PIDs matching a process name (bash here)
```

`pgrep` and `pidof` are from procps (in the fresh install). Note that Android
process names are usually package names (the Termux app shows as `com.termux`),
so `pidof <name>` matches whatever the process's name actually is. Prefer
`pgrep <name>` over `ps aux | grep <name>` in scripts — `grep` can match its
own invocation and the pipelines add noise.

## `kill` — signal processes

`kill` is a shell built-in here (bash provides it); `kill -l` lists signal
names.

```sh
kill 1234              # ask PID 1234 to terminate (SIGTERM)
kill -9 1234           # force kill (SIGKILL) — last resort, no cleanup
kill -l                # list signal names
pkill -9 sshd          # by name pattern
killall nano           # by exact command name (psmisc; fresh install)
fuser -k /path/to/lockfile  # kill processes holding a file (psmisc)
```

- `killall` is from **psmisc** (fresh install) and matches on command name.
- `fuser` (psmisc) finds processes using a file or socket:
  `fuser -n tcp 8080` shows the PID bound to TCP port 8080.
- `pkill` from procps matches a pattern (regex), careful with broad patterns.

Signaling background jobs (e.g. `kill %1`) is covered in
[Pipes, Redirection, and Shell Built-ins](09-pipes-redirection-and-builtins.md).

## `jobs` / `fg` / `bg` — job control (bash built-ins)

Job control belongs to the shell, not the OS:

```sh
sleep 100 &
jobs            # list background jobs: [1]+ Running
fg %1           # bring job 1 to the foreground
bg %1           # resume job 1 in the background
```

- `Ctrl-Z` suspends the foreground job; `bg` resumes it in the background.
- On Android, background shell jobs are still subject to the activity/process
  limits of the Termux app (see Foundations
  [Android Process Model](../00-foundations/06-processes-and-sessions.md) — background
  restrictions [variable]).

## `free` / `uptime` / `vmstat` / `watch` — resource views

procps tools, all in the fresh install. On unrooted Android these read from
the mock procfs statistics; **values are best effort and reflect the app
cgroup, not necessarily the whole device**. [variable]

```sh
free -m              # memory in MiB
uptime               # load averages (procps)
vmstat 2 5           # virtual memory snapshot every 2s, 5 times
watch -n 2 free      # re-run `free` every 2 seconds
```

## `pstree` — process tree

`pstree` is from psmisc (in the fresh install):

```sh
pstree               # tree of processes
pstree -p            # with PIDs
```

Useful to see parent/child relationships in the Termux environment.

## `lsof` — open files and sockets

`lsof` is **in the fresh install** (lsof package):

```sh
lsof | grep txt      # files opened by the current user
lsof -p $$           # what the current shell has open
lsof -iTCP:8080      # who is listening on TCP 8080
lsof +D $PREFIX/var  # processes referencing paths under a directory
```

- Unrooted `/proc` access limits what lsof can report; results on a normal
  device are reliable for your own session, limited for system processes.
  [variable]

## Android-specific process caveats

- **You see only your own processes** without root/ADB/Shizuku. `ps`, `top`,
  `pgrep` therefore cannot see other apps.
- Termux processes may be **killed by Android** under memory pressure; this is
  the OS, not a bug in a command.
- `sysctl` (procps) is present but most kernel sysctls are **not writable**
  from an unrooted app; don't expect `sysctl -w` to change system behavior.

## Native Termux vs. proot

Inside a proot-distro distribution, `ps`, `top`, `free`, `uptime`, `vmstat`,
`watch` come from that distro's procps and read the **guest's** `/proc`.
Because the guest's kernel is still the Android kernel enforced via proot,
the guest may show host-level processes or refuse some operations. `top` in
the guest is GNU/procps `top`, **not** the Android wrapper. See
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Cross-references

- Permissions/ownership: [Permissions and Ownership](05-permissions-and-ownership.md)
- Filtering output: [Text Processing and Searching](03-text-processing-and-searching.md)
- Job control built-ins: [Pipes, Redirection, and Shell Built-ins](09-pipes-redirection-and-builtins.md)

## References

- Phase 3 research notes §4.4 (processes), §9 (device checklist):
  `research/commands/00-shell-command-bible-research.md`.
- procps manual: <https://gitlab.com/procps-ng/procps>
- psmisc manual: <https://gitlab.com/psmisc/psmisc>