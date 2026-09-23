# rish

`rish` is an **Android program for interacting with a shell that runs on a
high-privileged daemon process** — in practice, a shell client that connects
to a **Shizuku** (or **Sui**) daemon so terminal apps such as Termux can run
commands with the daemon's identity. It is a *client* layer: it has no
privileges of its own and is **not** root, **not** ADB, and **not** the daemon
itself.

- **[What rish Is](01-what-is-rish.md)** — the client, its backends
  (Shizuku/Sui), and what privileges it actually has.
- **[Installation and Setup](02-installation-and-setup.md)** — where the two
  files come from, the `PKG` edit, `PATH`, and the Android 14+ dex rule.
- **[Usage and Command Execution](03-usage-and-command-execution.md)** —
  `rish` as a `sh` replacement, env handling (`RISH_PRESERVE_ENV`), and how
  commands reach the daemon.
- **[Relationship to Privileged Services and Permissions](04-relationship-and-permissions.md)**
  — rish vs Shizuku/Sui/ADB/root/Porter, the server-side permission checks,
  and the version boundaries.
- **[Limitations and Troubleshooting](05-limitations-and-troubleshooting.md)** —
  the common failure modes on device and how to fix them.

The setup most Termux users want (export + edit + run) is also summarized from
the Shizuku side in
[Command-Line Use and Termux](../05-shizuku/05-command-line-and-termux.md).

## Environment distinction to keep in mind

| Thing | What it is |
|-------|-----------|
| `rish` | a **client** program run from the terminal app; sends commands over a binder to a daemon, which runs them in an Android shell |
| Shizuku server | the daemon `rish` talks to when Shizuku is the backend |
| Sui | a Magisk module; the other supported rish backend |
| ADB shell | a shell from a computer; a different way to reach the device |
| Termux shell | a normal-app shell; `rish` runs from here but is not a Termux tool |

Parts of the system are **[version-sensitive]**: which backend is used, which
Shizuku version (server ≥ 12) is required, and how the environment is handled.

## Cross-references

- The Shizuku side of the setup: [Shizuku](../05-shizuku/00-intro.md)
- The Android shell rish commands run in: [The Android Shell](../03-android/01-android-shell.md)
- Env/PATH rules that affect rish: [Shell and Environment](../00-foundations/05-shell-and-environment.md)
- rish vs Porter: the Porter question is **Phase 6** — see
  [Relationship to Privileged Services](04-relationship-and-permissions.md).