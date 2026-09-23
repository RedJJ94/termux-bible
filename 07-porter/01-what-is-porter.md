# What Porter Is

Porter is an Android application plus a privileged **server process**. Normal
apps (or the command line) talk to that server and can then run code *with the
ADB (`shell`) identity or root* — without the app being system-signed and
without per-command root prompts. Its own one-line description is
**"ADB access for your apps"**: "a minimal, maintained fork of Shizuku that
gives Android apps ADB access through the Shizuku APIs, with optional root
support."

Factual baseline: the official `d4rken-org/porter` and `d4rken-org/porter-api`
repositories, the official documentation site `porter.darken.eu`, and release
data, all fetched 2026-09-22 and audited (see the
[Phase 6 research notes](../research/porter/00-porter-research.md)).

## Official description

> "ADB access for your apps" — a minimal, maintained fork of Shizuku that
> gives Android apps ADB access through the Shizuku APIs, with optional root
> support.

- The **manager app** is the package **`eu.darken.porter`**.
- Normal apps use the SDK `porter-api` to reach the server and request system
  APIs (details in [App Integration and the SDK](09-app-integration-and-sdk.md)).
- It works on **rooted and non-rooted devices**. On non-rooted devices the
  server runs as the adb `shell` identity and (like Shizuku) usually must be
  restarted after every boot, although Porter has an optional start-on-boot
  mode (see [Activation and Startup](04-activation-and-startup.md)).

## Origin and the fork lineage

- Porter is a fork of **Shizuku** by RikkaApps, via the Shizuku maintenance
  fork by **thedjchi** (acknowledged in Porter's `NOTICE` file).
- The maintainer is **d4rken** (also of SD Maid SE and Butler). The stated
  motivation: the original Shizuku app was no longer actively maintained, so a
  minimal, stable, maintained alternative was started for apps that need ADB
  access.
- Porter has **its own Android app identity** (`eu.darken.porter`) and can run
  **alongside** a genuine Shizuku installation. It is an independent
  continuation, not a replacement that reuses Shizuku's package identity.
- The only component that reuses Shizuku's identity is the optional **Porter
  Compatibility** companion app (see
  [Shizuku Compatibility and the Companion](06-shizuku-compatibility.md)).

## The pieces

| Piece | What it is |
|-------|-----------|
| **Manager app** | `eu.darken.porter`; owns the APK that also serves as the server's `CLASSPATH`, and drives startup |
| **Server process** | `porter_server`, started with `/system/bin/app_process`; main class `eu.darken.porter.privileged.PorterServer`; runs as uid 2000 or 0 |
| **Native starter** | `libporter.so`, an executable native binary shipped in the manager APK; used by all three startup methods |
| **porsh** | porter's own shell *client* (the analog of rish), turned into a per-use loader dex + script via an in-app export |
| **Client API** | the `porter-api` SDK (`eu.darken.porter.sdk`) + a content-provider that delivers the binder to apps |
| **Permissions** | runtime permission `eu.darken.porter.permission.API`; plus the legacy `moe.shizuku.manager.permission.API_V23` handled via the companion |
| **Porter Compatibility** | an optional thin app published under Shizuku's own identity (`moe.shizuku.privileged.api`) so Shizuku-only apps find Porter |

The server exposes its identity to clients: `connection.uid` returns whether
the server actually runs as **2000** (ADB) or **0** (root).

## What Porter is NOT

- **Not root by itself.** On an unrooted device the server runs as the
  adb/`shell` identity — it gives the *ADB `shell` permission set*, not root.
- **Not a Termux package.** There is no `porter`/`porsh` package in the
  termux-packages repository as far as verified (an index re-check is listed
  in the research notes as pending — `[needs verification]`). It is an
  Android app, plus the manual `porsh` file export for command-line use.
- **Not interchangeable with ADB, root, Shizuku, rish, or Sui.** Each is a
  distinct privileged-access mechanism (AGENTS.md §10). porsh is the shell
  *client* that connects to Porter's *server*; it is not the same thing as
  Porter, and it is not rish.
- **Not a drop-in Shizuku replacement for every purpose.** Apps must either
  support Porter directly or reach it through the compatibility companion;
  the stock `rish` terminal client is **not** a Porter client (see
  [rish and porsh](07-rish-and-porsh.md)).

## Version model [version-sensitive]

- Porter versioning: **v0.1.1-beta1** is the current GitHub release
  (2026-09-08) as of drafting, published as a **pre-release**. The project is
  early in its release cycle and interfaces may change between beta releases.
- Runtime floor: **Android 7.0 (API 24)** — `minSdk = 24` in both
  `porter` and `porter-api`; the official docs repeat "Android 7.0 or newer is
  required".
- The **server** (hence everything running through it) always has exactly the
  permissions of the identity that started it: uid **0** (root) or **2000**
  (adb/`shell`).

## Relationship at a glance

| System | What it is | Relationship to Porter |
|--------|-----------|------------------------|
| **Shizuku** | a server daemon (uid 2000 or 0) apps can call | the project Porter forks; Porter runs its **own** server and has its **own** identity |
| **Porter Compatibility** | an optional thin app under Shizuku's package identity | the only thing that reuses Shizuku's identity; makes Shizuku-only apps find Porter |
| **Sui** | RikkaApps' **Magisk module** (root required) | a rish backend only; **unrelated** to Porter's startup or access |
| **ADB** | the debug bridge from a computer | the usual way Porter's server is started; not "Porter" itself |
| **Root** | uid 0 via `su`/Magisk | one of Porter's startup methods; "root-start" Porter runs as uid 0 |
| **rish** | a shell *client* for Shizuku/Sui | **not** a Porter client; Porter ships its own client, `porsh` |

## What "using Porter" looks like to a user

1. Install the manager app ([Installation and Updates](02-installation.md)).
2. Start the server with one of the methods in
   [Activation and Startup](04-activation-and-startup.md).
3. Approve an app's (or porsh's) access request
   ([Permissions and Identities](05-permissions-and-identities.md)); the app
   then calls system APIs — or a shell runs commands — on the server's behalf.

## References

- Porter repository: `github.com/d4rken-org/porter`.
- Porter SDK repository: `github.com/d4rken-org/porter-api`.
- Official documentation: `porter.darken.eu` (Overview, Install and start,
  App compatibility, App integration, Troubleshooting).
- Phase 6 research notes: `research/porter/00-porter-research.md` (§1–§3).