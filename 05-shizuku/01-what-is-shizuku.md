# What Shizuku Is

Shizuku is an Android application plus a privileged **server process**. Normal
apps talk to that server and can then run Java/JNI code *with root or ADB
(`shell`) identity* — without the app itself being system-signed, and without
per-command root prompts.

Factual baseline: the official `RikkaApps/Shizuku` and `RikkaApps/Shizuku-API`
source and READMEs, the official user manual, and release notes, all fetched
2026-09-22 and audited (see the
[Phase 5 research notes](../research/shizuku/00-shizuku-research.md)).

## Official description

> "Using system APIs directly with adb/root privileges from normal apps through
> a Java process started with `app_process`."

- The **manager app** is the package **`moe.shizuku.privileged.api`**.
- Normal apps use the client libraries `dev.rikka.shizuku:api` and
  `dev.rikka.shizuku:provider` to reach the server and request system APIs.
- It works on **rooted and non-rooted devices**. On non-rooted devices it must
  be restarted with ADB after every boot (before Android 11 a computer was
  required; Android 11+ can restart it from the device via wireless debugging).

## The pieces

| Piece | What it is |
|-------|-----------|
| **Manager app** | `moe.shizuku.privileged.api`; owns the APK that also serves as the server's `CLASSPATH`, and drives startup |
| **Server process** | `shizuku_server`, started with `/system/bin/app_process`; main class `rikka.shizuku.server.ShizukuService` |
| **Client API** | `rikka.shizuku` package (`Shizuku` static class) + a content-provider that delivers the binder to apps |
| **Permission** | runtime permission `moe.shizuku.manager.permission.API_V23` (details in [Permissions](04-permissions.md)) |
| **Sui** | a separate project: a **Magisk module** (needs root/unlocked bootloader) that Shizuku-API can use as an alternative backend |

The current API exposes the server process's identity to clients:
`Shizuku.getUid()` and `Shizuku.getSELinuxContext()` return who the server
actually runs as **[version-sensitive: API shape verified on current master]**.

## What Shizuku is NOT

- **Not root by itself.** On an unrooted device Shizuku restarts as the
  adb/shell identity — it gives the *adb `shell` permission set*, not root.
- **Not a Termux package.** There is no `shizuku` package in the
  termux-packages repository (verified against the full package index,
  2026-09-22). It is an Android app, plus the manual `rish` file export for
  command-line use.
- **Not interchangeable with ADB, root, rish, Sui, or Porter.** Each is a
  distinct privileged-access mechanism (AGENTS.md §10). rish is the shell
  *client* that connects to a Shizuku—or Sui—*server*; it is not the same thing
  as Shizuku.

## Version model [version-sensitive]

- Shizuku versioning: **v13.6.0** is the latest GitHub release (2025-05-25) as
  of drafting; master (HEAD `b844bc49`, 2025-06-18) matches v13.6.0 for every
  code path discussed in this section (only license/LTO/AGP/fa-strings commits
  follow the release — verified via the GitHub compare API).
- **API version**: the current API identifies the protocol as
  `SERVER_VERSION = 13`, `SERVER_PATCH_VERSION = 6`. The rish client checks the
  *server* major version (≥ 12).
- The **server** (hence everything running through it) always has exactly the
  permissions of the identity that started it: uid **0** (root) or **2000**
  (adb/shell).

## What "using Shizuku" looks like to a user

1. Install the manager app ([Installation](02-installation.md)).
2. Start the server with one of the methods in
   [Activation and Startup](03-activation-and-startup.md).
3. Grant a previously-authorized app the `API_V23` permission when it requests
   it ([Permissions](04-permissions.md)); the app then calls system APIs on
   the server's behalf.

## References

- Shizuku README: `github.com/RikkaApps/Shizuku`.
- Shizuku-API README: `github.com/RikkaApps/Shizuku-API` (`Shizuku`,
  `Sui`, `ShizukuProvider`).
- Official user manual: `shizuku.rikka.app/guide/setup.html` (note: the setup
  page predates v13.6.0 — see [Activation and Startup](03-activation-and-startup.md)).
- Phase 5 research notes: `research/shizuku/00-shizuku-research.md` (§3, §4, §8).