# Foundations

This first section of the Termux Bible contains the concepts you need before
anything else. It explains what Termux actually is, how Android constrains it,
how its filesystem and storage work, and the execution environments you will
encounter.

The chapters build from the ground up:

- **[What Termux Is](01-what-is-termux.md)** — what Termux is (and is not), how
  a minimal environment is installed, and the key differences between Termux
  and a regular Linux distribution.
- **[Android Sandboxing and Execution Environments](02-android-sandboxing.md)**
  — the Android application sandbox, Android's process limits, and how native
  Termux differs from proot/proot-distro, ADB, and privileged-command shells.
- **[The Filesystem](03-filesystem.md)** — `$PREFIX`, `$HOME`, the terms that
  name important paths, and the rules that govern where everything lives.
- **[Storage and Permissions](04-storage-and-permissions.md)** — shared
  storage, `~/storage`, and how Android permissions gate file access.
- **[Shell and Environment](05-shell-and-environment.md)** — the default
  shell, startup files, environment variables, and executable handling.
- **[Processes and Sessions](06-processes-and-sessions.md)** — processes,
  signals, jobs, and the session model.

If you already know Linux well, read **[What Termux Is](01-what-is-termux.md)**
and **[The Filesystem](03-filesystem.md)** first — the places where Termux
deliberately differs from a desktop Linux system are where most beginners and
power users make mistakes.

The practical "how to" side of the same material — installing, package
management, repositories, storage setup, configuration — lives in the
**[Termux](../01-termux/00-intro.md)** section, which this section links to
throughout. Later sections cover the Android shell, ADB, privileged access
systems, and the shell command encyclopedia.