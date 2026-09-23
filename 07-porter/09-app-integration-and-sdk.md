# App Integration and the SDK

Most Termux users will only ever use **porsh**
([porsh — Command Line and Termux](08-porsh-command-line-and-termux.md)).
This chapter is for **app developers** who want to make an Android app use
Porter.

## How an app integrates, in brief

1. Declare `<uses-permission android:name="eu.darken.porter.permission.API"/>`
   (and the provider + `moe.shizuku.manager.permission.API_V23` for
   Shizuku-only apps — details in
   [Shizuku Compatibility](06-shizuku-compatibility.md)).
2. Add the **`porter-api` SDK** via JitPack.
3. Use `Porter.availability` and `Porter.connection`, then call the manager
   operations you need.
4. The system delivers the server binder to the **app's provider**
   (`${applicationId}.porter.api`, or `.shizuku` for the Shizuku backend).

## The SDK at a glance

- Maven coordinate (JitPack):
  `com.github.d4rken-org.porter-api:sdk:+` (the `+` resolves the newest
  release). **`[version-sensitive]`** — check for a newer tag.
- **Kotlin/Flow API only; there is no Java API.** `minSdk = 24` (Android 7.0).
- `porter-sdk-extras` and `porter-api/shizuku-compat` are separate artifacts
  for extras and the Shizuku backend respectively.

## Main API pieces [source-verified]

| API | What it gives you |
|-----|-------------------|
| `Porter.availability` | a suspending query returning a `PorterAvailability` state: `Connected`, `InstalledNotConnected`, `NotInstalled`, `InstalledUnrecognized`, or `Incompatible(serverTooOld *|* clientTooOld)` |
| `Porter.connection` | a `StateFlow` reflecting server reachability |
| `Porter.checkPermission()` / `Porter.requestPermission()` | permission gate |
| `Porter.permission` | a `StateFlow` of the current permission state, refreshed after requests |
| `Porter.wrap(binder)` | **re-issues the given binder at the Porter identity**: server-side (see `transactRemote` in [Architecture](03-architecture.md)) |
| `Porter.userService(args)` | cold `Flow<IBinder>` of a **user service** instance (you control the lifecycle) |
| `Porter.peekUserService(args)` / `Porter.stopUserService(args)` | peek, or stop via destroy handshake (codes 16777115 / 16777114) |
| `connection.uid` | an `Int` binder value — **0** (root), **2000** (ADB shell) |

All manager (server) calls are **suspend functions** run off the calling
thread (on Porter's io dispatcher). A connection replaced or dead while a
call is in flight fails it with `PorterConnectionLostException`; a server
that dies surfaces as `PorterRemoteException` carrying a `DeadObjectException`
cause. `PorterSecurityException` covers permission refusals.

## Backend detection and the Shizuku backend

- The runtime backend is chosen by **what is installed**: any package owning
  `eu.darken.porter.permission.API` → **PORTER** (even if its service is
  stopped); otherwise the **shizuku-compat** artifact on the classpath plus a
  package owning `moe.shizuku.manager.permission.API_V23` → **SHIZUKU**;
  neither → `NotInstalled`. A **live connection never switches backend** until
  it dies; a process without one re-resolves when an app is installed.
- BinderContainer: when the app includes the **shizuku-compat** artifact, the
  app has `moe.shizuku.api.BinderContainer` on its classpath (the same class
  that `dev.rikka.shizuku:provider` supplies). **The two are mutually
  exclusive** (duplicate class), so a Shizuku-backend app must include exactly
  one of them.
- Shizuku-backend connection requires, in the app's own manifest:
  `uses-permission` for `moe.shizuku.manager.permission.API_V23`, a meta-data
  entry `moe.shizuku.client.V3_SUPPORT` = `true`, and a provider
  `eu.darken.porter.sdk.PorterShizukuApiProvider` on authority
  `${applicationId}.shizuku`.
- Important: declaring that provider **without** the shizuku-compat artifact
  on the classpath **throws in `attachInfo`** ("shizuku-compat is not on the
  classpath"). The SDK's own provider (`PorterApiProvider`, `${applicationId}.porter.api`)
  is the Porter-wire path.[source-verified]

## What the SDK re-issues (transactRemote)

The **transactRemote** (`case 100`) lets an app forward a binder *transaction
to a remote Android-object binder* (e.g. an inner binder returned by a
manager call) and execute it **at the server identity**. It is analogous to
Shizuku's override and is how apps call `wm size`, `pm`, `settings`, etc.
wrapped from public API stubs. Because the server implements it without
permission checks per-call for the *app-returned* sub-binders, it is a
powerful primitive; gate it with your own permission checks in the app.

## User services caution

- The server starts user service processes **as its own uid**, with a Context
  that is **not attached to an application** — service classes must not assume
  a `Context.getApplicationContext()` with receivers/resolver.
- The lifecycle is a **cold flow**: each collection starts a service; the
  server destroys it on cancellation (destroy handshake). `destroy()` must be
  implemented in your service to `System.exit()`, or the process lingers.

## sdk-extras

- `PorterSystemServices.getSystemService("package")` and typed system
  property getters (`Int` / `Long` / `Boolean`) wrap manager calls; no
  `mirror`-style reflection in your code.
- Check the `porter-sdk-extras` docs/artifact for the complete supported
  service list (not enumerated fully here). [needs verification]

## Versioning promise [version-sensitive]

During the 0.x phase, the SDK makes these compatibility guarantees (from the
porter-api README):

- The **Binder protocol** (wires and transaction codes) is stable and does
  not reset between releases.
- The **provider authority suffix** (`.porter.api` / `.shizuku`) is stable.
- **Data classes are source-compatible only** — the serialized shape may
  change; do **not** persist SDK data structures across versions.
- There is **no runtime update path** yet (apps won't auto-upgrade the SDK
  fragments).

## References

- porter-api README and `PorterDocumentation` sources
  (`d4rken-org/porter-api`, commit `d15868e`).
- Phase 6 research notes: `research/porter/00-porter-research.md` (§7.4–§7.7).
- The app-facing documentation site: `porter.darken.eu/docs/app-integration`.