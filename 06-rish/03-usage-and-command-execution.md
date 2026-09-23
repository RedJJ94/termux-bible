# Usage and Command Execution

The basic rule of rish: **replace `sh` with `rish`**. Everything after `rish`
is passed straight through to a remote shell running on the daemon — rish does
not interpret your arguments, and the remote shell is **Android's
`/system/bin/sh`** (mksh), not a Termux bash. See
[The Android Shell](../03-android/01-android-shell.md) for what that tool set
contains.

## One-shot versus interactive

```
rish -c 'ls /sdcard'        # run ONE command, print output, exit
rish                       # interactive session (PTY); exit with Ctrl+D or 'exit'
rish exec /system/bin/sh   # use a different remote shell binary
```

- `-c` runs a single command and returns its exit status.
- Interactive sessions run over a **PTY**: window-size changes are transmitted
  to the remote process (the client transacts the PTY window size over the
  binder channel).

## What happens behind the scenes

1. The loader (`ShizukuShellLoader`) identifies the calling package from the
   terminal app's uid (or `RISH_APPLICATION_ID`), asks the manager for the
   daemon binder, and loads the manager's `Shell` class.
2. The client creates pipes for stdin/stdout/stderr, **serializes the entire
   local environment and the working directory**, and sends them to the
   server together with your arguments (transaction codes `RishConfig` base
   30000). **[version-sensitive: transaction codes are internal; the client
   and server must agree — assumed stable for server ≥ 12]**
3. The server forks a **host process per calling pid**, runs the command under
   a PTY, and streams I/O and the exit code back.

So a rish session is: *Termux UI → rish client → Shizuku/Sui daemon → forked
`/system/bin/sh` child with the daemon's identity.*

## Environment handling: `RISH_PRESERVE_ENV`

The most important practical setting. Because arguments (and the requested
command) pass through to the remote shell, env *options* are given through an
environment variable:

| Value | Meaning |
|-------|---------|
| `RISH_PRESERVE_ENV=0` | do **not** change the remote environment (default for the **adb** backend) |
| `RISH_PRESERVE_ENV=1` | **replace** the remote environment with the local (Termux) one (default for the **root** backend) |

Why this matters (from the official source comments): *Termux sets `PATH` and
`LD_PRELOAD` to Termux's internal paths. ADB does not have sufficient
permissions to access such places. Under adb, users need to set
`RISH_PRESERVE_ENV=1` to preserve env. Under root, keep env unless
`RISH_PRESERVE_ENV=0` is set.*

Consequences:

- **adb backend, default**: the env array is dropped, and the forked
  `/system/bin/sh` **inherits the daemon's own environment** (the adb-shell /
  `app_process`-launched one — `PATH` contains `/system/bin` etc., **not**
  Termux's paths). Termux-only binaries are therefore "not found" unless you
  place them on the Android shell's `PATH` or switch backends.
- **root backend, default**: the client environment is kept, so `rish -c`
  commands can reach Termux's tools when run under a root daemon.

Try it:

```
RISH_PRESERVE_ENV=1 rish -c 'echo $PATH'    # Termux-ish PATH (root backend)
RISH_PRESERVE_ENV=0 rish -c 'echo $PATH'    # Android shell PATH
```

## Practical examples

```
rish -c 'id'                                # verify the daemon identity
rish -c 'ls -l /data/user/0'                # app-private dir as the daemon sees it
rish -c 'pm list packages'                  # the Android package list (cmd/`pm`)
rish                                        # interactive session as that identity
```

> The commands you run with rish are the **device-side Android commands**
> (`pm`, `settings`, `cmd`, ...) from the Android/ADB chapters — e.g.
> [The `cmd` Dispatcher](../03-android/04-command-dispatcher.md). The identity
> (uid 2000 or root) decides how much of them is allowed; App-private data is
> readable only when the daemon is root **[version-sensitive]**.

## Security notes

- A rish command is executed **as the daemon**, bypassing the terminal app's
  own sandbox. Treat it like a privileged shell, not an app command.
- With the **adb backend** the environment-drop is a deliberate mitigation:
  untrusted env from the local app is dropped to keep commands runnable on
  Android's own shell environment (per the source comment).
- Keep `RISH_PRESERVE_ENV` off unless you need it, and never run rish from a
  script that blindly executes remote content.

## References

- Shizuku-API rish README (usage, `RISH_PRESERVE_ENV`).
- Source: `RishService.java`, `RishTerminal.java`, `RishHost.java`,
  `rikka_rish_RishHost.cpp`, `RishConfig.java`.
- Phase 5 research notes: `research/rish/00-rish-research.md` (§5, §6).