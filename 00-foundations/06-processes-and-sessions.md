# Processes and Sessions

Termux is still an Android app: **the Android OS decides when your processes
may run and when they are killed.** This chapter explains processes, jobs, and
Termux sessions, and the Android-specific limits that affect background work.

## Processes

A process is a running program instance (`ps` lists them; `top` shows live
ones). In Termux, processes are ordinary Linux processes running under the
Termux app's UID — subject to Android's process management on top of normal
Unix rules.

Important Android-specific consequences:

- **Processes can be killed at any time.** When the app is backgrounded, when
  memory is low, or when Android decides the process is disposable, your
  sessions can be terminated. Do not rely on long-running foreground/terminal
  work continuing while the screen is off.
- **Android 12+ phantom process limits.** Android kills processes beyond a
  threshold (~32 "phantom" processes, across all apps) and CPU-heavy
  processes. A common symptom in Termux is `[Process completed (signal 9)]`
  appearing without an error message. **Version-sensitive:** there is a
  developer option on Android 12L/13 to disable the phantom process limit.
  This affects background sessions, servers, and `sshd`.

## Signals

Signals are how the system and the shell tell a process to stop or change
behavior. Relevant ones in day-to-day Termux work:

| Signal | Number | Meaning |
|--------|--------|---------|
| `INT` | 2 | Interrupt (Ctrl+C on the terminal) — ask the foreground job to stop |
| `QUIT` | 3 | Quit (Ctrl+\) — terminate and usually dump core |
| `KILL` | 9 | Kill — cannot be caught or ignored |
| `TERM` | 15 | Terminate — default polite termination |
| `TSTP` | 20 | Stop (Ctrl+Z) — suspend the foreground job |
| `HUP` | 1 | Hangup — often used to make daemons reload config |
| `CONT` | 18 | Continue — resume a stopped job |

Typical use: `kill 1234` sends `TERM` to PID 1234; `kill -KILL 1234` forces
it. Use `pkill -f pattern` to target processes by name/command-line pattern.

## Jobs and foreground/background execution

Inside a shell, **jobs** are processes you started from that shell.

- `Command &` — start a job in the **background** (control returns to the
  prompt).
- `jobs` — list your background jobs.
- `fg` — bring the most recent background job to the **foreground**.
- `bg` — resume a stopped job in the background.
- Ctrl+Z (`TSTP`) — suspend the foreground job; it then appears in `jobs`.

Because Android owns the process lifecycle, a background job still depends on
the app staying alive and on Android not reclaiming the process. For work that
must truly keep running independent of a terminal, consider Termux services or
a wake lock (`termux-wake-lock` acquires one). See
[Termux Utilities](../01-termux/06-utilities.md).

## Sessions

A **session** is a terminal connection (a shell) managed by the Termux app.
Termux supports multiple simultaneous sessions.

- New sessions, session switching, and renaming are configured via the
  `shortcut.*` properties in
  [`termux.properties`](../01-termux/05-configuration.md):
  - `shortcut.create-session` (e.g. `ctrl + t`)
  - `shortcut.next-session` (e.g. `ctrl + 2`)
  - `shortcut.previous-session` (e.g. `ctrl + 1`)
  - `shortcut.rename-session`
- In the app UI, switching sessions is done via **long-press**; the shortcut
  properties define key combinations instead.
- A toast notification on session change can be disabled with
  `disable-terminal-session-change-toast`.

**Version-sensitive:** the default keyboard shortcuts and whether a hardware
keyboard is used depend on the app version and `termux.properties`.

### Sessions vs. processes — the distinction

- A *process* is a running program (independent of any shell).
- A *session* is a terminal/shell instance. A session runs a shell process,
  which runs your commands as jobs/sub-processes.
- Killing a session's shell (e.g. with an exit command) terminates the shell
  and its jobs, but does not by itself affect unrelated processes elsewhere in
  the system.

## Permission and background constraints

The storage permission question (which files an app may read/write) is the
main Android permission affecting Termux day to day; see
[Storage and Permissions](04-storage-and-permissions.md). Privileged access
systems used by Termux-side tools (ADB, Shizuku, rish, root) are
separate mechanisms documented in their own Bible sections; nothing here
depends on them.

## References

- Research notes §3.10 (Sessions) and §3.1 (execution environment, Android
  12/12L/13 phantom processes): `research/termux/00-foundations-research.md`.
- termux-tools `termux.properties` template (for `shortcut.*` keys).
- termux-app issue #2366 (phantom process limit).