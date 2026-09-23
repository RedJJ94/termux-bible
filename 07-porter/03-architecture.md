# Architecture

This chapter explains how Porter is put together: the manager APK, the
`porter_server` process, the native starter, and — most importantly — the
**two Binder wires** (Porter and Shizuku) that are answered by **one shared
core**. All of it is verified from the official source ([A9]/[A10] in the
[Phase 6 research notes](../research/porter/00-porter-research.md)).

## Processes and packaging

| Piece | What it is |
|-------|-----------|
| **Manager APK** (`eu.darken.porter`) | contains the server classes (`:common`, `:server`, `:porsh`, `:starter`, `:sdk`, `:manager-protocol`, `:shizuku-compat`) packaged into the APK, plus the native starter and the `libporsh.so` native terminal library |
| **Server process** | `porter_server` — started with `/system/bin/app_process` using the manager APK path as `-Djava.class.path=...` (the same approach Shizuku uses), main class `eu.darken.porter.privileged.PorterServer` |
| **Native starter** | `libporter.so`, built as an **executable**; it is what `adb` (or `su`) actually runs, and it starts the Java server (see [Activation and Startup](04-activation-and-startup.md)) |
| **porsh** | an exported `porsh.dex` (the `:shell` module classes) + a `porsh` script; the terminal client runs in its own `app_process` process (`--nice-name=porsh`) |
| **Porter Compatibility** | a separate thin APK published under Shizuku's identity (see [Shizuku Compatibility](06-shizuku-compatibility.md)) |

The server stores its app-connection history at
`/data/user_de/0/com.android.shell/porter-connections.json`
(implementation detail, path verifiable from source). It also keeps an
`ApkReconciler` that watches for manager APK replacement and exits the server
when the signature/APK baseline no longer matches — updating or reinstalling
Porter under a running server therefore causes the server to stop.

## The server delivers a Binder, like Shizuku

After starting, `porter_server` delivers its binder to eligible apps (and to
the manager itself) by calling the app's content provider **externally**
(`ActivityManagerApis.getContentProviderExternal`, with a temporary
power-save whitelist) — exactly the "send binder" mechanism Shizuku uses.
Which provider to contact and which delivery method is used depends on the
wire, below.

Apps are routed to a wire by the permission they request
(`ClientRouting`):

- request **`eu.darken.porter.permission.API`** → **PORTER wire**;
- request **`moe.shizuku.manager.permission.API_V23`** **and** a trusted
  companion is installed → **SHIZUKU wire**;
- a declared `*.permission.MANAGER` excludes that package from routing.

Provider authority suffix: **`PORTER` → `.porter.api`**,
**`SHIZUKU` → `.shizuku`** (these are the `<applicationId>.porter.api` and
`.shizuku` provider authorities).

## Two wires, one core

`PorterServer` exposes **two** Binder endpoints over the same core logic.

### The Porter wire [source-verified]

- Binder descriptor: `eu.darken.porter.server.IPorterService`.
- Protocol `VERSION = 4`, `MIN_VERSION = 4` (client floors). Versions are
  cumulative: "a peer at a higher version still speaks every version from its
  floor up". An unsupported attach gets a `REPLY_UNSUPPORTED` reply.
- AIDL surface: `attach`, `getUid`, `checkPermission`,
  `getSELinuxContext`, `getSystemProperty`/`setSystemProperty`,
  `addUserService`, `removeUserService`, `requestPermission`,
  `checkSelfPermission`, `shouldShowRequestPermissionRationale`.
- Raw transaction codes: **100** = `transactRemote`; **200–202** = the porsh
  terminal protocol (`createHost`, `setWindowSize`, `getExitCode`);
  **10000+** = app-only transactions (the protocol reserves those for apps
  and never allocates one itself).

### The Shizuku wire [source-verified]

- Binder descriptor: `moe.shizuku.server.IShizukuService`.
- Self-reported server version `SERVER_VERSION = 13`, `SERVER_PATCH_VERSION
  = 6` (the legacy version numbers "as upstream spells them").
- Full legacy AIDL surface from Shizuku: `attachApplication`, `getVersion`,
  `getUid`, `checkPermission`, `getSystemProperty`/`setSystemProperty`,
  `newProcess`, `addUserService`, `removeUserService`, `checkSelfPermission`,
  `requestPermission`, `shouldShowRequestPermissionRationale`, `exit`,
  `attachUserService`, `dispatchPermissionConfirmationResult`,
  `getFlagsForUid`/`updateFlagsForUid`, and the `transactRemote`-style
  transaction (`1`).
- The legacy wire **also** serves porsh-style terminal codes at base
  **30000** (`createHost 30000`, `setWindowSize 30001`, `getExitCode 30002`)
  — the same 30000-base the rish protocol uses on the Shizuku wire. This is
  what makes the wire-level terminal transport compatible (see
  [rish and porsh](07-rish-and-porsh.md)).
- The **manager app itself never speaks the Shizuku wire** — none of the
  app's own transaction codes are answered there.

### The shared core

Both endpoints call into the same `PorterCore`: attach record keeping, the
permission gate (`ClientRecord.allowed`), `transactRemote`, user services,
and system properties. The two wires therefore "cannot drift apart in what
they permit or record" — a client granted on the Porter wire is granted on
the core, not on a wire-specific list.

## What the server enforces [source-verified]

- Every manager/app operation is guarded by
  `core.enforceCallingPermission`; the manager package **in Android user 0**
  is exempt.
- A global setting "Allow app access" toggles whether clients are accepted at
  all; while paused, every client check throws a `SecurityException` (see
  [Permissions and Identities](05-permissions-and-identities.md)).
- Authorization outcomes grant or revoke the runtime permissions
  (`eu.darken.porter.permission.API`, and `moe.shizuku.manager.permission.API_V23`
  client-side when a trusted companion exists); denials revoke **and
  force-stop** the app; one-time grants are not recorded; legacy-only apps
  without a companion get a deferred grant ("companion pending") and their uid
  is suspended until a trusted companion appears.

## User services

- User services are Android **services started by the server** as a separate
  `app_process` process under the **server's uid** (shell/root) with a Context
  that is **not a normal app process** (a Context obtained there cannot
  register receivers or reach a content resolver).
- Shutdown handshake: the server transacts code **16777115** (Kotlin) /
  **16777114** (AIDL stub id) on the service binder; the service must
  implement a `destroy()` method that cleans up and calls `System.exit()`. The
  server does **not** kill the process itself. (Details for app developers:
  [App Integration and the SDK](09-app-integration-and-sdk.md).)

## Identity at a glance

The server process runs as **the uid of whatever started it**:

| Startup method | Server uid | Identity |
|----------------|-----------|----------|
| Wireless debugging / computer (ADB) | **2000** | adb `shell` permission set |
| Root | **0** | root |

The consequences of that identity for permissions are explained in
[Permissions and Identities](05-permissions-and-identities.md).

## References

- Phase 6 research notes: `research/porter/00-porter-research.md` (§5.1–§5.4).
- Source: `d4rken-org/porter` (server/manager modules) and
  `d4rken-org/porter-api` (protocol, porsh, server-shared modules), commit
  `d15868e`.