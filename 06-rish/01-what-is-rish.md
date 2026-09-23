# What rish Is

`rish` is an **Android program for interacting with a shell that runs on a
high-privileged daemon process** (official description). You run it from a
normal terminal app and it lets your commands execute **as the daemon's
identity** — the adb `shell` user or root, depending on how the daemon was
started.

The full name history and packaging facts (verified from the official
`RikkaApps/Shizuku` and `RikkaApps/Shizuku-API` repositories, audited
2026-09-22):

- rish was originally named **`bsh`** and was renamed to rish (commit
  `70bb1e570c`, 2021-07-23, on master) because the name collided with
  BeanShell.
- The **`rish` asset** (plus the `ShizukuShellLoader`/`Shell` runtime) ships
  from **Shizuku v12.4.3** onward — it does **not** ship with v11.x. Tags
  v11.0.0–v11.2.2 have no rish/bsh asset; v11.3.0+ had a differently-named
  predecessor asset (`shizuku`). **[version-sensitive]** — this is a shipping
  fact about releases, worth keeping straight from any "v11.2.0" claim seen in
  old how-to articles.
- The rish **client requires a server of major version ≥ 12** (checked at
  runtime; see below).

## What rish actually is

- A **shell client**. Commands are passed through (arguments are not parsed by
  rish) to a remote shell — `/system/bin/sh` by default — that is **forked as
  a child process of the daemon**, using a **PTY** for interaction.
- It is **not itself root**. Its privileges are exactly those of the daemon it
  connects to: adb uid **2000** or root **0**.
- It is **not ADB** (it does not go through the debug-bridge transport), and
  it is **not the Shizuku server** — it is the command-line *bridge* into a
  Shizuku/Sui-compatible server.

## Supported backends

The rish module documents **two** backends (you "follow the guide from Shizuku
or Sui" to create the files):

| Backend | What it is | Notes |
|---------|-----------|-------|
| **Shizuku** | the manager app / server (`moe.shizuku.privileged.api`) | the standard path documented throughout this section |
| **Sui** | RikkaApps' **Magisk module** | requires an unlocked bootloader / root; produces its own rish files |

**Porter is not one of the documented rish backends.** Porter is a separate,
maintained Shizuku-like project; whether the stock `rish` client can connect
to a Porter server is **not verified** and is a Phase 6 research question (see
[Relationship to Privileged Services and Permissions](04-relationship-and-permissions.md)).

## What a rish session looks like

```
$ rish                                   # interactive session (PTY) as the daemon identity
$ rish -c 'id'                           # run ONE command and exit
$ rish exec /system/bin/sh               # choose a different remote shell
```

The client requires:

- the **Shizuku server running** (or a Sui module), with the requesting app
  granted access;
- **server major version ≥ 12** — otherwise the client prints
  "Rish requires server 12 (running <n>)".

## References

- Shizuku-API rish README: `github.com/RikkaApps/Shizuku-API` (rish module).
- Rename commit history: `RikkaApps/Shizuku` master (v12.4.3 and later trees).
- Phase 5 research notes: `research/rish/00-rish-research.md` (§1, §3).