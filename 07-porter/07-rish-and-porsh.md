# rish and porsh

Porter's own shell client is **`porsh`** — not rish. This chapter answers the
question left open in [rish — Relationship, rish vs Sui](../06-rish/04-relationship-and-permissions.md):
**does the stock rish client work with Porter?**

## Short answer

**No.** Porter implements the Shizuku *binder protocol*, but the terminal
compatibility layer that a **stock `rish` binary** needs is **not** present in
Porter's manager APK. Porter ships its **own** terminal client, `porsh`, which
speaks the same terminal wire (see below). Porting/installation guidance is in
[porsh — Command Line and Termux](08-porsh-command-line-and-termux.md).

## Why stock rish cannot connect to Porter [source-verified]

- rish (from the userland `rikka-rish` project) is **part of Shizuku's
  own runtime**: it relies on `moe.shizuku.privileged.api` broadcasting
  `rikka.shizuku.intent.action.REQUEST_BINDER` and returning a *Shizuku
  manager* APK path, from whose `sourceDir` it **class-loads the
  `moe.shizuku.manager.shell.Shell` class** to drive the terminal.
- In a Porter-owned device, the manager (the APK the request resolves to) is
  **Porter's own manager APK**, not a Shizuku manager/daemon APK. Porter's APK
  contains **`eu.darken.porter.manager.shell.Shell`** (and `PorterShellLoader`
  / `ShellBinderRequestHandler`), i.e. a Porter-managed shell handler, not
  `moe.shizuku.manager.shell.Shell`. The lookup therefore fails with a
  **`ClassNotFoundException`**.
- Porter's **Porter Compatibility** companion forwards the broadcast to
  Porter (`BinderRequestReceiver`), but the class in question still doesn't
  exist in the package it gets back, so the resolution ends there. No amount
  of forwarding makes a rish loader find a class that isn't there.

A cross-check that produced this conclusion is documented in the
[Phase 6 research notes](../research/rish/00-rish-research.md) (§8).

## Wire-level nuance: the Shizuku wire *does* carry terminal calls

To avoid overclaiming, note the distinction:

- Porter's **Shizuku-wire endpoint** serves the **terminal protocol** from
  downstream-style rish at **base codes 30000/30001/30002** (`createHost`,
  `setWindowSize`, `getExitCode`) and a source comment in Porter's
  `EnvPolicy` says the wire "also serves Shizuku's own rish client through
  the compatibility companion" and accepts **`RISH_PRESERVE_ENV`**.
- That comment describes the **Binder-wire transport layer only** (the legacy
  AIDL-compatible terminal calls); it does **not** mean the stock
  `rish_shizuku.dex`/`ShizukuShellLoader` can *boot* against Porter, because
  of the missing class, above.
- `porsh` uses the **Porter wire** base-200 terminal codes instead, with
  `PORSH_PRESERVE_ENV`.

So: **the wire vocabulary is shared, the client loader is not.** Do not write
"rish works with Porter"; write "Porter's Shizuku-wire endpoint serves the
low-level rish-style terminal calls; the stock rish client itself is not
compatible".

## porsh vs rish — the differences that matter

| Aspect | rish | porsh |
|--------|------|-------|
| Purpose | shell client for a **Shizuku/Sui** daemon | shell client for a **Porter** daemon |
| Loader | `ShizukuShellLoader` (searches for `moe.shizuku.manager.shell.Shell`) | `PorterShellLoader` (detects the installed Porter daemon wire) |
| Application ID env default | `RISH_APPLICATION_ID` | `PORSH_APPLICATION_ID` |
| Preserve-env toggle | `RISH_PRESERVE_ENV` (1 / 0) | `PORSH_PRESERVE_ENV` (1 / 0) |
| Terminal wire codes | 30000-base (Shizuku wire) | 200-base (Porter wire) |
| Root detection | `IS_ROOT = Os.getuid() == 0` (client-side check) | server-side `EnvPolicy` keyed on the daemon's uid (root: uid 0) |
| Access gating | daemon's `enforceCallingPermission` | Porter core's `enforceCallingPermission` |
| Works with a genuine Shizuku daemon | yes | no (expects a Porter daemon) |
| Works with Porter | **no** | **yes** |

Common ground: both are **not** the daemon — they are thin **citizens** that
talk to a daemon running elsewhere, and both run `/system/bin/sh` **as the
daemon's uid** (2000 or 0) when they hand you a shell session.

## Environment filtering shared by both clients

Both clients implement the same **env policy** (Porter's `EnvPolicy` maps the
rish and porsh variants onto one rule). The client sends its full
`System.getenv()` map; the **server** decides what to set for the spawned
`/system/bin/sh`:

- Server **uid 2000** (ADB start): env is **dropped by default**; to keep it,
  set `PORSH_PRESERVE_ENV=1` (or `RISH_PRESERVE_ENV=1`).
- Server **uid 0** (root start): env is **kept by default**; to drop it, set
  `PORSH_PRESERVE_ENV=0` (or `RISH_PRESERVE_ENV=0`).
- Exec fallback: when the env cannot be pushed as a whole, the server falls
  back to `execvp` with the **server's** environ, so the shell starts with the
  daemon's environment instead of the client's.

Practical use from Termux is covered in
[porsh — Command Line and Termux](08-porsh-command-line-and-termux.md).

## Sui is not involved

Porter, porsh, and the companion have **nothing to do with Sui**. Sui is only
a rish backend that requires Magisk/root; it is the subject of the
[Phase 5 rish chapters](../06-rish/00-intro.md).

## References

- Phase 6 research notes: `research/porter/00-porter-research.md` (§5.3, §6.3,
  §11.5); `research/rish/00-rish-research.md` (§8).
- The rish viewpoint: [rish — What it is](../06-rish/01-what-is-rish.md).