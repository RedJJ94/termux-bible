# Porter — Research Notes (Phase 6)

Status: research notes supporting Phase 6 "Porter" (PLAN.md §32) and PLAN.md
§11 (Porter section topics). Not polished documentation. Distinguished from
Bible chapters per AGENTS.md §17 / PLAN.md §21. The Phase 6 chapter will be
written separately from these notes.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Everything
that needs a real device/network/boot to confirm is tagged **[DEVICE]**;
Android/version-dependent items are tagged **[version-sensitive]**; OEM
behavior is tagged **[OEM]**; anything not yet conclusively verified is flagged
`[needs verification]`.

Audit note: all code-level claims below were verified against the official
`d4rken-org/porter` and `d4rken-org/porter-api` repositories (source fetched
2026-09-22; both cloned at depth 200 plus tag `0.1.0` for porter-api) and the
official documentation site `porter.darken.eu` (fetched 2026-09-22). For
porter-api the revision actually analyzed is the commit pinned by porter's
`api` submodule, **`d15868e`** — note this is **not** the `0.1.0` tag, which
dereferences to the older `fe5c0fc` (see A10). Raw source files were read
during the session; full paths are listed in the source inventory. Nothing was
copied from memory-only recollection.

Cross-reference: this file answers the open "rish ↔ Porter" question left in
`research/rish/00-rish-research.md` §8 (see §11 below).

---

## 1. Scope

Phase 6 Porter topics (PLAN.md §11/§32): what Porter is; Porter architecture;
startup methods (USB/ADB, wireless debugging, root); included native shell
client (`porsh`); permissions and authorization; compatibility with Shizuku
apps and the companion ("Shizuku compatibility") app; developer integration
(porter-api SDK); command-line access; relationship to and differences from
ARIS's rish; limitations; troubleshooting; interaction with Termux.

Distinctions that AGENTS.md §10 and §13 require and that this research keeps
separate: **ADB / root / Shizuku / Porter / porsh / rish / Sui / Android shell /
native Termux / proot / proot-distro**. Porter is not Shizuku, porsh is not
rish, and neither porsh nor rish is "root" by itself.

## 2. Source Inventory and Reliability Ranking

Ranking per AGENTS.md §3.2 (A = official project docs/source).

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `d4rken-org/porter` README (main) | A | raw.githubusercontent.com |
| A2 | `d4rken-org/porter-api` README (main) | A | raw.githubusercontent.com |
| A3 | Official docs `porter.darken.eu/` (Overview, "ADB access for your apps") | A | webfetch |
| A4 | Official docs `porter.darken.eu/setup` (Install and start) | A | webfetch |
| A5 | Official docs `porter.darken.eu/compatibility` (App compatibility) | A | webfetch |
| A6 | Official docs `porter.darken.eu/developers` (App integration) | A | webfetch |
| A7 | `d4rken-org/porter-api` `docs/api-reference.md` (Kotlin surface + upstream Shizuku history) | A | webfetch |
| A8 | GitHub Releases API (porter v0.1.1-beta1 assets 2026-09-08; porter-api 0.1.0 2026-09-07; build-info.json) | A | api.github.com |
| A9 | Porter source HEAD `585aae5` v0.1.1-beta1: `build.gradle.kts`, `manager/build.gradle.kts`, `manager/src/main/AndroidManifest.xml`, `common/src/main/java/eu/darken/porter/common/AppTransactions.kt`, `manager/src/main/java/eu/darken/porter/{PorterSettings.kt,PorterApplication.kt}`, `manager/src/main/java/eu/darken/porter/manager/starter/Starter.kt`, `manager/src/main/java/eu/darken/porter/manager/receiver/{PorterReceiverStarter.kt,BinderRequestReceiver.kt}`, `manager/src/main/java/eu/darken/porter/manager/shell/{Shell.kt,ShellBinderRequestHandler.kt,ShellTutorialActivity.kt,ShellRequestHandlerActivity.kt}`, `manager/src/main/java/eu/darken/porter/manager/worker/AdbStartWorker.kt`, `manager/src/main/jni/starter.cpp` + `CMakeLists.txt`, `manager/src/main/assets/porsh`, `server/src/main/java/eu/darken/porter/privileged/{PorterServer.kt,PorterServiceEndpoint.kt,ShizukuServiceEndpoint.kt,ServerConstants.kt,ClientRouting.kt,Compatibility.kt}`, `shell/build.gradle.kts`, `shell/src/main/java/eu/darken/porter/shell/PorterShellLoader.kt`, `compat/build.gradle.kts`, `compat/src/main/AndroidManifest.xml`, `compat/src/main/java/eu/darken/porter/compat/{BinderRequestReceiver.kt,OpenPorterActivity.kt,PorterIdentity.kt}`, `NOTICE` | A | git clone + read |
| A10 | Porter-API source at `d15868e` (commit pinned by porter's `api` submodule; the `0.1.0` tag is an older, differently structured tree at `fe5c0fc` — the porsh/sdk/sdk-extras/shizuku-compat/protocol/manager-protocol/server-shared layout analyzed here exists at `d15868e`, not at the tag): `protocol/src/main/java/eu/darken/porter/protocol/PorterProtocol.kt`, `shared/src/main/java/rikka/shizuku/ShizukuApiConstants.kt`, `porsh/src/main/java/eu/darken/porter/porsh/{Porsh.kt,PorshConfig.kt,PorshService.kt,PorshTerminal.kt,PorshHost.kt,PorshConstants.kt,EnvPolicy.kt}`, `porsh/src/main/cpp/{main.cpp,porsh_host.cpp,porsh_terminal.cpp,CMakeLists.txt}`, `server-shared/src/main/java/eu/darken/porter/endpoint/{PorterEndpoint.kt,PorterManagerEndpoint.kt}`, `server-shared/src/main/java/rikka/shizuku/server/{ShizukuLegacyEndpoint.kt,ClientManager.kt,ClientRecord.kt,ConfigManager.kt,ConfigPackageEntry.kt,UserService*.kt}`, `sdk/src/main/AndroidManifest.xml`, `sdk/src/main/java/eu/darken/porter/sdk/*`, `sdk-extras`, `shizuku-compat`, `build.gradle.kts` (minSdk 24) | A | git clone + read |

## 3. What Porter Is

Verified from [A1][A3]:

- One-line description from the maintainer: **"ADB access for your apps"** —
  "a minimal, maintained fork of [Shizuku] that gives Android apps ADB access
  through the Shizuku APIs, with optional root support."
- Fork lineage in NOTICE [A9]: `Shizuku by RikkaApps... and the Shizuku
  maintenance fork by thedjchi`. Maintainer is **d4rken** (also of SD Maid SE
  and Butler). Motivation (official): the original Shizuku app was no longer
  actively maintained, so a minimal, stable, maintained alternative was
  started for apps that need ADB access.
- Porter has **its own Android app identity** (`eu.darken.porter`) and can run
  **alongside** a genuine Shizuku installation. It is an independent
  continuation, not a replacement that reuses Shizuku's package identity.
- The only thing that reuses Shizuku's identity is the optional
  **Porter Compatibility** companion, which is published separately (and
  embedded in the FOSS build). See §9.
- Runtime floor: **Android 7.0 (API 24)** — `minSdk = 24` in both repos [A9]
  [A10]; docs [A3][A4] repeat "Android 7.0 or newer is required."

## 4. Startup Methods (Official docs [A4], verified against source [A9])

Three official startup methods, chosen on the home screen while the service is
stopped:

| Device situation | Method |
|------------------|--------|
| Android 11+ with wireless debugging | Wireless debugging (in-app pairing) |
| Android 7.0+ and a computer (USB debugging) | Start command run with `adb` on a computer |
| Rooted device | Root start (su) |

### 4.1 Start commands (source [A9], `Starter.kt`)

All three paths execute the same native starter executable, packaged as
`<manager>/lib/<abi>/libporter.so` in the manager's native library directory:

- `userCommand` = `<nativeLibraryDir>/libporter.so`
  (exact absolute path, e.g. under `/data/user/0/eu.darken.porter/lib/<abi>/`).
- `adbCommand` = `adb shell <userCommand>` — this is the command shown by
  Porter's **"Start by connecting to a computer"** screen; the docs tell the
  user to run it on the computer. With several devices attach `-s SERIAL`.
  "Get a new command from Porter after updating or reinstalling it. The path
  can change." [A4]
- `internalCommand` = `<userCommand> --apk=<manager APK path>` — used for the
  in-device paths: wireless debugging (`AdbStarter` over ADB transport
  `shell:<internalCommand>`) and root start (`Shell.cmd(internalCommand)`).

### 4.2 Native starter (`manager/src/main/jni/starter.cpp`)

`libporter.so` is built as an **executable** (`add_executable(libporter.so
starter.cpp misc.cpp selinux.cpp cgroup.cpp)`, project "porter"). Behavior
[version-sensitive]:

- Refuses to run unless `getuid()` is `0` (root) or `2000` (adb/shell)
  (`EXIT_FATAL_UID`, exit code **6**).
- As root: switch cgroup; on Android 10+ (API ≥ 29) switch to the init mount
  namespace (`switch_mnt_ns(1)`); verify the su allows binder call/transfer
  from `u:r:untrusted_app:s0` to the su's SELinux context
  (`selinux_check_access`), otherwise exit `EXIT_FATAL_BINDER_BLOCKED_BY_SELINUX`
  (**10**) with the message "the su you are using does not allow app to connect
  to su with binder".
- `--apk=<path>` selects the manager APK; without it the path is derived from
  `/proc/self/exe` (`<...>/lib/<abi>/libporter.so` → `<...>/base.apk`).
- `--replace=<pid>` kills the named `porter_server` process (validated by
  process name) and replaces it; otherwise kills all running `porter_server`
  processes first.
- Forks a child that `setsid()`, chdirs to `/`, dup2s `/dev/null` onto
  stdio, writes a ready byte, and `execvp`s:
  `/system/bin/app_process -Djava.class.path=<APK> -Dporter.library.path=<apkdir>/lib/<abi> /system/bin --nice-name=porter_server eu.darken.porter.privileged.PorterServer`
  (debug builds add JDWP/`--debuggable` VM args). The parent prints
  `info: porter_server pid is N / porter_starter exit with 0`.
- Additional exit codes: **3** set CLASSPATH failed; **4** pipe/fork failed;
  **5** `app_process` exec failed; **7** manager APK not found/readable;
  **9** kill/replace failed.
- Constants: `SERVER_NAME "porter_server"`,
  `SERVER_CLASS_PATH "eu.darken.porter.privileged.PorterServer"`.
- So `libporter.so` is both the thing adb executes and the thing that starts
  the Java server; it is analogous to Shizuku's older native startup but uses
  `--apk=` rather than the historical `start.sh`/path convention. The docs
  warning "Do not use a startup command copied from Shizuku" is because the
  path/content differs [A4].

### 4.3 Wireless debugging start (Android 11+, API 30+) [version-sensitive] [OEM]

Verified from `AdbStartWorker.kt`, `AdbStarter.kt`, `AdbMdns/AdbPairing*`
(mDNS-based discovery + pairing; the manager contains its own ADB client in
Kotlin, plus a BoringSSL-based `libadb.so`):

1. User flow (docs [A4]): enable Developer options → **USB debugging** and
   **Wireless debugging** → in Porter tap **Pairing** → in Android Wireless
   debugging open **Pair device with pairing code** and keep it open → enter
   the pairing code (from Android) in Porter's notification/dialog → wait for
   pairing → tap **Start**. Android TV variant uses a pairing Accessibility
   service (one-minute window).
2. Program flow: the worker sets `Settings.Global.ADB_ENABLED=1`, discovers
   the device's ADB TCP port via mDNS (or reuses an already-listening ADB TCP
   port), connects to `127.0.0.1:<port>`, authenticates with an ADB key from
   `PreferenceAdbKeyStore` (key stored in the backed-up `settings` prefs as
   ciphertext under an AndroidKeyStore-only key; the auth token lives in the
   `secrets` prefs, which the backup rules exclude — per `BackupRulesTest`),
   then runs `shell:<internalCommand>`.
   While the device is keyguard-locked it waits via an `UnlockWaiter` and
   hands the run to a replacement worker, holding an
   `androidx.work` foreground service of type `specialUse`.
3. OEM caveat (docs [A4]): "Some device manufacturers restrict wireless
   debugging; if it is unavailable, use a computer." **[OEM]**.
4. Pairing method is user-selectable: **In-app dialog** (discover pairing
   service in Porter, enter the code there) or the system flow. When asked for
   a port, use the **pairing port** from Android's pairing-code dialog, not the
   connection port. [A4]

### 4.4 Root start

Porter's root method calls `Shell.cmd(internalCommand).exec()` (libsu),
awaiting the su shell; the docs framing: "This method is for devices that
already have working root access. Installing Porter does not root your
device." [A4] Stop before switching root/ADB mode.

### 4.5 Start-on-boot (source [A9])

- `BootCompleteReceiver` is declared **disabled** in the manifest
  (`android:enabled="false"`); it is enabled when the user turns on the
  **"Start on boot"** setting in the Porter settings screen
  (`PorterSettings.setStartOnBoot`, uses `PackageManager.SYNCHRONOUS` on
  API 30+ so the enable survives an immediate reboot).
- At boot: only in Android user 0 and when not already running. If last
  launch mode was `ROOT` → root start. If `ADB` and (API ≥ 30 **or** TV
  **or** a global ADB TCP port > 0) and the manager holds
  `WRITE_SECURE_SETTINGS` → enqueue the wireless-ADB start worker (with an
  "awaiting Wi-Fi" notification); without the permission → a "permission
  error" notification. Otherwise: "Background start not supported".
- The `WRITE_SECURE_SETTINGS` grant is given to the manager by the server
  whenever the manager attaches (server-side `grantRuntimePermission`), i.e.
  after the **first successful start** — this is why docs say start-on-boot
  needs one manual start first. The manager uses it to set `ADB_ENABLED` and
  to persist the boot receiver reliably.
- `WatchdogService` (foreground, `specialUse`, opt-in setting "watchdog",
  default off) restarts the service when the binder is lost. Its declared
  purpose (manifest property): keep the API available for apps; no polling,
  only reacts when the API service stops.

### 4.6 At a glance (who runs the resulting server)

The server process `porter_server` runs as the uid of whatever started it:
**uid 2000 (adb/shell)** for USB and wireless debugging, **uid 0 (root)** for
the root method. `connection.uid` (2000/0) exposes this to apps [A7][A6].

## 5. Architecture (verified from source [A9][A10])

### 5.1 Processes and packaging

- **Manager APK** (`eu.darken.porter`) contains the server classes: the
  Gradle dependencies `:common`, `:server`, `:porsh`, `:starter`, `:sdk`,
  `:manager-protocol`, `:shizuku-compat` are all packaged into the APK. The
  APK path is the `-Djava.class.path` of the server process (same approach as
  Shizuku). The starter native lib and libporsh native libs ship in
  `jniLibs`/`useLegacyPackaging`.
- Two flavors: **foss** (buildType name in filename, embeds the signed compat
  APK under `assets/compat/porter-compat.apk`) and **gplay** (compat not
  embedded). Release filename rule:
  `porter-v<VERSION>-<foss buildType name, else flavor+BuildType>.apk`, so the
  published **`porter-v0.1.1-beta1-release.apk`** is the FOSS build [A9][A8].
- **Server process** `porter_server`: waits for `package`, `activity`, `user`
  and `app_ops` system services; requires the manager in Android user 0 with a
  verified signature (`PackageIdentity`), else exit code
  `MANAGER_APP_NOT_FOUND` (50); keeps an `ApkReconciler` that watches for
  manager APK replacement and exits when the verification baseline no longer
  matches. It stores app connection history at
  `/data/user_de/0/com.android.shell/porter-connections.json`
  (`ConnectionHistory`) [A9][A10].
- The server delivers its binder to eligible apps and to the manager itself
  by calling the app's provider externally
  (`ActivityManagerApis.getContentProviderExternal`, with a power-save temp
  whitelist `REASON_SHELL(316)`), exactly like Shizuku's "send binder"
  mechanism. Provider to contact and delivery method depend on the wire
  (below). Apps are routed by requested permissions
  (`ClientRouting.route`: request `eu.darken.porter.permission.API` → PORTER
  wire; request `moe.shizuku.manager.permission.API_V23` AND a trusted
  companion installed → SHIZUKU wire; a declared `*.permission.MANAGER`
  excludes a package). Provider authority suffix: `PORTER` → `.porter.api`,
  `SHIZUKU` → `.shizuku`.

### 5.2 Two wires, one core

`PorterServer` exposes **two** binder endpoints over the same core:

**Porter wire — `PorterServiceEndpoint` / `PorterEndpoint`** [A10]:
- Descriptor `eu.darken.porter.server.IPorterService`; protocol
  `VERSION = 4`, `MIN_VERSION = 4` (client floors). Versions are cumulative:
  "a peer at a higher version still speaks every version from its floor up".
  Unsupported attach → reply bundle with `REPLY_UNSUPPORTED`.
- AIDL methods: `attach`, `getUid`, `checkPermission`, `getSELinuxContext`,
  `getSystemProperty/setSystemProperty`, `addUserService`, `removeUserService`,
  `requestPermission`, `checkSelfPermission`,
  `shouldShowRequestPermissionRationale`.
- Raw codes on the descriptor: `100` = `transactRemote`; `200..202` = porsh
  (`createHost`, `setWindowSize`, `getExitCode`); `10000+` = app-only
  transactions (see §6.4). Comment in `PorterProtocol.kt`: codes ≥10000 are
  "the server application's own operations; this protocol never allocates
  one".

**Shizuku wire — `ShizukuServiceEndpoint` / `ShizukuLegacyEndpoint`** [A10]:
- Descriptor `moe.shizuku.server.IShizukuService`;
  `SERVER_VERSION = 13`, `SERVER_PATCH_VERSION = 6`
  (`ShizukuApiConstants`, "as upstream spells it").
- Full legacy AIDL surface: `attachApplication` (AIDL id 17, raw code 14 for
  ≤ v12 clients), `getVersion`, `getUid`, `checkPermission`,
  `getSystemProperty/setSystemProperty`, `newProcess`, `addUserService`,
  `removeUserService`, `checkSelfPermission`, `requestPermission`,
  `shouldShowRequestPermissionRationale`, `exit`, `attachUserService`,
  `dispatchPermissionConfirmationResult`, `getFlagsForUid/supdateFlagsForUid`,
  and `BINDER_TRANSACTION_transact` = `1` (raw) → `transactRemote`.
- The legacy wire also serves porsh terminal codes at base **30000**
  (`createHost 30000`, `setWindowSize 30001`, `getExitCode 30002`). The
  server bootstrap `PorshConfig.init(moe.shizuku.server.IShizukuService, 30000)`
  is a documented prerequisite for terminal transactions on this wire.
- The manager never speaks the Shizuku wire ("none of the app's own
  transaction codes are answered here").

Both endpoints call into the same `PorterCore` (attach record keeping,
permission gate via `ClientRecord.allowed`, `transactRemote`, user services,
system properties), so "the two wires cannot drift apart in what they permit
or record".

### 5.3 server instance facts (verified)

- Attach reply carries `BIND_APPLICATION_SERVER_*`/`REPLY_*` version, uid,
  secontext, granted flag, `SHOULD_SHOW_REQUEST_PERMISSION_RATIONALE`.
- `core.enforceCallingPermission` guards every manager/app operation; the
  manager package in user 0 (`appId == managerAppId && userId == 0`) is
  exempt (`checkCallerManagerPermission`).
- Global switch "Allow app access" toggles `configManager.isAccessPaused`;
  while paused every client `allowed=false` and `checkCallerPermission` throws
  `SecurityException("App access is paused")`.
- Authorization outcomes (`dispatchPermissionConfirmationResult`): on
  allowed → grant runtime permissions (`setRuntimePermissionsForUid`,
  `Android17Compat.grantRuntimePermission`) for `eu.darken.porter.permission.API`
  and, when a trusted companion exists and the app requests it,
  `moe.shizuku.manager.permission.API_V23`; on denied → revoke + force-stop;
  one-time grants not recorded; legacy-only apps without companion →
  `FLAG_PENDING_COMPANION` (grant deferred, uid suspended). A
  `PermissionObserver` re-syncs runtime permissions to decisions.
- `showPermissionConfirmation` starts the manager's
  `RequestPermissionActivity` in user 0 and refuses when another user is on
  screen.

### 5.4 User services (server side, both wires)

- User services are Android services started by the server as a separate
  `app_process` process under the **server's uid** (root/shell) with a
  `Context` that is **not a normal app process** ("a Context obtained there
  cannot register receivers or reach a content resolver" [A6][A7]).
- The server matches a service by tag (else class name) and version; the
  version gate plus AndroidManifest-internal component. `addUserService`
  feedback: `USER_SERVICE_RESULT_BOUND` (0), running version code,
  `NOT_RUNNING` (-1), `removeUserService` → `NO_SUCH_SERVICE` (1).
- Destroy handshake: the server transacts **16777115** (Kotlin) /
  **16777114** (AIDL stub id) on the service binder; the service must
  implement a `destroy()` (e.g. `void destroy() = 16777114;`) that cleans up
  and `System.exit()`. The server does **not** kill the process itself.

## 6. porsh — the included terminal client (source [A9][A10])

porsh is Porter's shell client, the analog of Shizuku's `rish`. It is a
first-class Porter feature (the manager ships `ShellTutorialActivity`,
"Terminal" UI section, `home_terminal_title`).

### 6.1 Exported files and script

- Two files exported via the in-app tutorial (SAF "Export files"):
  **`porsh`** (a `#!/system/bin/sh` script, shipped as
  `manager/src/main/assets/porsh`) and **`porsh.dex`** (the classes.dex of the
  `:shell` module, extracted at build time by `ExtractPorshDex` from the shell
  APK). If a file with the same name exists it is deleted first. MIUI is
  reported to break the SAF export [A9] **[OEM]**.
- The script, verbatim logic:
  - `BASEDIR=$(dirname "$0")`; `DEX="$BASEDIR"/porsh.dex`.
  - Android 14+ (SDK ≥ 34): if the dex is writable, `chmod 400` it; on failure
    instructs to copy to the terminal app's private dir `/data/data/<package>`
    where the permission can be removed.
  - `[ -z "$PORSH_APPLICATION_ID" ] && export PORSH_APPLICATION_ID="PKG" && export MANAGER_APPLICATION_ID="MANAGER_PKG"`
  - Runs
    `/system/bin/app_process -Djava.class.path="$DEX" /system/bin --nice-name=porsh eu.darken.porter.shell.PorterShellLoader "$@"`.
- The export step (in `ShellTutorialActivity`/`ShellTutorialViewModel`)
  replaces the literal `MANAGER_PKG` with the Porter package
  (`eu.darken.porter`) when writing the script; **`PKG` is not substituted** —
  it is a placeholder for the terminal app's application id that the user is
  expected to set only if needed (see §6.4).
- Docs naming: the tutorial text uses the string `rish_description` ("What is
  rish"/equivalent role) with the name **porsh**, and the export step is
  described with `porsh`/`porsh.dex`. The exported files are two: `porsh` +
  `porsh.dex`.

### 6.2 Client flow (verified)

1. `PorterShellLoader.main(args)` (in porsh.dex): determines the calling
   package — if the current uid maps to exactly one package, use it; otherwise
   require `PORSH_APPLICATION_ID` (error message otherwise). `callingPackage`
   is used later as the package name the server records/attaches.
2. Requests the server binder by broadcasting
   **`eu.darken.porter.intent.action.REQUEST_BINDER`**, `setPackage(<manager>)`
   (`MANAGER_APPLICATION_ID`, default `eu.darken.porter`), with
   `FLAG_INCLUDE_STOPPED_PACKAGES` and a bundle `data` containing its own
   receive binder (`putBinder("binder", receiverBinder)`). On Android 8.0/8.1
   (where `broadcastIntent` on an instant/unqualified caller fails) it falls
   back to a chooser **activity** (`ShellRequestHandlerActivity`).
3. **Manager** side: `receiver.BinderRequestReceiver` → `ShellBinderRequestHandler`
   reads `Porter.connection.value?.binder` (the manager's own Porter-wire
   server binder) and writes it plus the manager's `sourceDir` (APK path) back
   to the loader binder with `transact(1, ..., FLAG_ONEWAY)`. Error prints
   "Server is not running".
4. `PorterShellLoader.onBinderReceived(binder, sourceDir)`: computes the
   library search path `<managerAPKdir>/lib/<vmInstructionSet()>` (plus
   `java.library.path`), loads `eu.darken.porter.manager.shell.Shell` from the
   manager APK with a `BaseDexClassLoader`, and invokes
   `Shell.main(args, callingPackage, binder, handler, BuildConfig.LOADER_VERSION)`
   (with the no-version fallback for older managers). "Class not found /
   Make sure the Porter app is installed and up to date" on failure.
5. **Shell** (in the manager APK) — `eu.darken.porter.manager.shell.Shell`:
   - If `loaderVersion < BuildConfig.PORSH_LOADER_VERSION` warns to re-export.
   - `PorshConfig.init(binder, PorterProtocol.DESCRIPTOR, PorterProtocol.TRANSACTION_PORSH_BASE)`
     (= `eu.darken.porter.server.IPorterService`, base 200) — porsh speaks the
     **Porter** wire, not the legacy one.
   - `Porter.onBinderReceived(binder, packageName)` (SDK entry) → waits for
     `Porter.connection` (10 s startup watchdog with a timeout message; the
     watchdog is cancelled once the user's permission decision is invoked).
   - Permission: `connection.checkPermission()`; on
     `PermissionState.Denied(permanentlyDenied=false)` →
     `connection.requestPermission()`; granted → `Porsh.start(args)`. Any
     denial path prints **"Permission denied"** and `exit(1)`.
   - `Porsh.start` → `PorshTerminal`.

### 6.3 Terminal protocol on the Porter wire (verified)

`PorshTerminal` (client, inside the porsh/app_process process):

- `prepare()` (native) detects tty on stdin/stdout/stderr.
- `createHost()` transacts code **200**: writes
  `PorshConfig.getInterfaceToken()`, the tty byte, the read end of a stdin
  pipe, the write end of a stdout pipe (and, when stderr is not a tty, its
  write end), `argv`, the client's full `System.getenv()` as `KEY=VALUE`
  lines, and the cwd. The **client sends the entire environment**, but the
  server filters it before handing it to the host (`EnvPolicy`, below); the
  sent env is not passed through verbatim.
- `start(tty, ...)` (native): raw mode when all three are ttys, then
  `transfer_async` between the app_process stdio and the pipe ends; a
  `SIGWINCH` handler → `setWindowSize` transact code **201**; waits via
  `getExitCode` transact code **202** and `waitForProcessExit`.

`PorshService` (server side, installed on both endpoints with their wire's
descriptor and base):

- `createHost` (base+0): `enforceCallingPermission("createHost")`, creates a
  `PorshHost` in `PorshHostRegistry` keyed by calling pid. On the **Porter**
  endpoint it gates through the core like any client; terminal clients that
  declare no permission are admitted on the uid/package check and still gated
  by the user's explicit decision (`onAttaching` reconciles their uid).
- `setWindowSize` (base+1): `TIOCSWINSZ` on the host's ptmx (`winsize` jlong).
- `getExitCode` (base+2): result of `waitpid`.

Host process (native `libporsh.so`, loaded as described): opens `ptmx` when a
tty was requested, `fork()`s; child `setsid()`, `chdir` (only if `X_OK`),
`dup2`s the pts slave (or pipes) onto fid 0/1/2, `execvpe("/system/bin/sh",
argv, env)`; parent bridges data between its fds and the provided pipe fds and
`SIGKILL`s the child if the client dies. Source files:
`porsh/src/main/cpp/{porsh_host.cpp,porsh_terminal.cpp,pts.cpp}`.

Consequence: **the executed shell is `/system/bin/sh` running with the
server's identity** (uid 2000 adb / 0 root), not a Termux or proot shell;
argv[0] forced to `/system/bin/sh`, all additional arguments appended (so
`porsh -c '<command>'` is the way to run a command).

**Environment is filtered server-side** (`PorshService` runs the received env
through `EnvPolicy(Os.getuid() == 0)`; when it resolves to null the native
host falls back to `execvp`, giving the child the server process's own
environ). The policy mirrors rish's:
- **ADB-launched server** (uid 2000): the client env is **dropped by default**
  unless the client env carries `PORSH_PRESERVE_ENV=1` — or
  `RISH_PRESERVE_ENV=1`, which the code comment says Shizuku's own rish client
  sets through the compatibility companion (see §11).
- **Root server** (uid 0): the client env is **kept by default** unless
  `PORSH_PRESERVE_ENV=0` or `RISH_PRESERVE_ENV=0` overrides it.

So by default under an adb server, Termux's `PATH`/`LD_PRELOAD` from an
env-carrying porsh do **not** leak into `/system/bin/sh`
(`[source-verified]`; end-to-end env behavior on real devices
`[needs verification]`).

### 6.4 Env and per-app notes

- `MANAGER_APPLICATION_ID` — the manager package (default/embedded:
  `eu.darken.porter`). Set it when the script was copied without the export
  substitution or when testing against another build.
- `PORSH_APPLICATION_ID` — normally auto-derived from the uid; only required
  when one uid maps to several packages. Placeholder default `PKG`.
- Termux note: Termux runs as a single package (`com.termux`) so
  `PORSH_APPLICATION_ID` is normally not needed; the tutorial tells the user
  to copy the exported files into the terminal app's private data directory
  and run `sh /path/to/porsh` (the script itself uses `#!/system/bin/sh`).
  This mirrors the documented rish-in-Termux placement (see
  `research/rish/00-rish-research.md` §9), so an analogous chapter should
  point Termux users to a location like `$PREFIX/bin` or `~/porsh`, `chmod +x`,
  and `chmod 400` the dex on Android 14+.

## 7. Permissions and authorization (verified [A9])

- **`eu.darken.porter.permission.API`** — `dangerous`, group
  `eu.darken.porter.permission-group.API`; declared by the manager and
  requested by apps via the SDK; the server enforces it per-call and
  syncs the runtime grant (`ActivityManager.grantRuntimePermission`, server
  runs as shell/root, or via `GrantPermissions` UI elsewhere).
- **`eu.darken.porter.permission.MANAGER`** — `signature`, used by the manager
  itself.
- **`moe.shizuku.manager.permission.API_V23`** — declared **only by the
  compatibility companion**, not by the manager (the manager's merged manifest
  removes the SDK's/legacy copy with `tools:node="remove"` plus a matching
  uses-permission removal). It is the permission legacy Shizuku apps request.
- Server grants/revokes the runtime permissions in sync with the user's
  decision; legacy-only apps' grants are deferred (`FLAG_PENDING_COMPANION`)
  until a trusted companion is present.
- Apps get the binder pushed when they request a recognized permission; using
  the API still requires the user's approval ("Only approve apps you trust:
  they can perform tasks with Porter's debugging or root access." [A4]).
- Granting flow: app calls `requestPermission()` → server
  `showPermissionConfirmation` → manager activity
  `RequestPermissionActivity` (`eu.darken.porter.intent.action.REQUEST_PERMISSION`)
  in user 0 → result dispatched back. Docs: "Porter and Shizuku keep separate
  approvals." [A4]
- "Allow app access" master switch (per-app list preserved). [A4]

## 8. Compatibility with Shizuku apps and the companion (verified [A5][A9])

- Apps supporting Porter directly: only Porter needed.
- Apps that support only Shizuku: **Porter + Porter Compatibility**. The
  companion is what makes them find Porter; Porter still runs the service,
  shows prompts and manages approvals ("Keep the companion installed...").
- Apps with a service selector: install Porter, choose Porter in the app.
- Companion identity: applicationId **`moe.shizuku.privileged.api`**
  (Shizuku's own manager identity — "It uses Shizuku's Android app identity to
  support older apps"), namespace `eu.darken.porter.compat`, signed with
  Porter's key. **It cannot coexist with genuine Shizuku** ("Android treats
  them as competing installations. This also applies to forks using that same
  identity."). Swapping back = uninstall companion, reinstall Shizuku.
- Companion contents (`compat/src/main/AndroidManifest.xml` + sources):
  - declares `moe.shizuku.manager.permission-group.API` and the dangerous
    `moe.shizuku.manager.permission.API_V23` (this is what
    `Compatibility.isAvailable()` checks for, together with matching signing
    certs between manager and companion in user 0);
  - `BinderRequestReceiver` forwards
    **`rikka.shizuku.intent.action.REQUEST_BINDER`** to
    `eu.darken.porter.intent.action.REQUEST_BINDER` (package-scoped,
    `FLAG_INCLUDE_STOPPED_PACKAGES`, forwards the `data` bundle) when Porter is
    installed with a signature match;
  - `OpenPorterActivity` opens Porter on
    `moe.shizuku.manager.intent.action.REQUEST_PERMISSION` and
    `moe.shizuku.privileged.api.intent.action.REQUEST_PERMISSION`.
  - **It contains no server, no porsh dex, and no shell/rish classes** — it is
    a thin bridging app.
- Switch from Shizuku (docs [A5]): the FOSS build embeds the companion APK;
  the **"Shizuku compatibility"** screen offers **Replace** (stops Shizuku
  service, uninstalls the app, installs the companion, imports eligible access
  decisions by checking installed apps and current access; Porter decisions
  take precedence; **Shizuku's app settings and pairing configuration are NOT
  imported**) or **Install automatically** / **Manual**. If the access
  database cannot be read, approve again. Replacement dialog alone does not
  save an import.
- Can Porter and Shizuku run together? **Yes** — both installed and running is
  fine; an app with a selector uses one at a time. Only the companion uses
  Shizuku's identity.
- An old app's settings may still say "Shizuku" while Porter serves it — that
  is expected [A5].

## 9. Developer SDK (`d4rken-org/porter-api`) (verified [A6][A7][A10])

- JitPack coordinate `com.github.d4rken-org.porter-api:sdk:+`; Android 7.0+
  (minSdk 24); coroutines/Flow throughout; **no Java API**.
- SDK manifest merge adds: uses-permission `eu.darken.porter.permission.API`;
  `<queries>` for `eu.darken.porter` and `moe.shizuku.privileged.api`;
  `PorterApiProvider` on `${applicationId}.porter.api` (exported, protected
  with `android:permission="android.permission.INTERACT_ACROSS_USERS_FULL"` so
  only the app itself and the server can reach it).
- `Porter.connection: StateFlow<PorterConnection?>` (null before binder /
  after death; direct transition between live servers). Never poll;
  `connection.isAlive()` for one-offs.
- `Porter.availability(context)` states: `Connected`,
  `InstalledNotConnected`, `NotInstalled`, `InstalledUnrecognized`
  ("an unrecognized app owns that permission" — do not name/launch it on the
  wrong backend), `Incompatible(serverTooOld|clientTooOld)` (both ends name
  their protocol version and floor; a newer peer alone is never incompatible).
- Backend: **`PorterBackend.PORTER | SHIZUKU`**. Backend chosen by what is
  **installed** (Porter wins even if stopped); a live connection never
  switches until it dies. Detection probes for `moe.shizuku.api.BinderContainer`
  on the classpath (provided by `shizuku-compat`, same class as
  `dev.rikka.shizuku:provider`; the two are mutually exclusive). Without the
  class, a Shizuku-only device reports `NotInstalled`.
- Shizuku backend wiring must be declared by the app itself: uses-permission
  `moe.shizuku.manager.permission.API_V23` + meta-data
  `moe.shizuku.client.V3_SUPPORT=true` + `PorterShizukuApiProvider` on
  `${applicationId}.shizuku`. (Declaring the provider without
  `BinderContainer` on the classpath crashes the app in `attachInfo`.)
- Connection API: `checkPermission()`, `requestPermission()` (suspends until
  the user answers; a prompt already shown is not withdrawn by cancellation;
  fails with `PorterConnectionLostException` on replacement/death);
  `permission: StateFlow<PermissionState>` (`Granted` /
  `Denied(permanentlyDenied)`); server pushes revocations on the Porter
  backend but not on the Shizuku backend.
- Privileged work:
  - `connection.wrap(binder)` → `IBinder` whose transactions are re-issued at
    Porter's identity; requires platform AIDL stubs + non-SDK-interface
    bypass (HiddenApiRefinePlugin / AndroidHiddenApiBypass); refusals surface
    as the platform's own `SecurityException`.
  - `connection.userService(UserServiceArgs(...))` — cold `Flow<IBinder>`;
    `start=false` binds-only; `peekUserService` returns running version;
    `stopUserService` sends destroy (16777115 / 16777114 in AIDL); daemon
    flag, per-Android-user isolation, version bumps replace instances; the
    service process runs under root/shell and its Context can't register
    receivers or use the content resolver.
  - `connection.uid` (0 root / 2000 ADB). ADB ≠ root: shell's Android
    permissions are the Shell package's (vary by Android version); shell can't
    read `/data/user/0/<pkg>`; root additionally gets full uid 0 privileges.
  - `sdk-extras`: `PorterSystemServices.getSystemService("package")` and typed
    system property getters (`Int`/`Long`/`Boolean`).
  - Exceptions: `PorterException` → `PorterSecurityException`,
    `PorterRemoteException` (with `DeadObjectException` cause),
    `PorterConnectionLostException`.
- Multi-process: `PorterApiProvider.requestBinderForNonProviderProcess(context)`
  in every non-provider process; nothing is accepted from a broadcast there.
- Versioning promises (docs): `0.x` SDK — binder protocol + provider authority
  stay compatible; data classes are source-only compatible (constructor/copy
  signatures change); no runtime update path for the library.
- `PorterSystemServices`/shizuku-compat/sdk artifact split is summarized in
  `docs/api-reference.md` and `porter.darken.eu/developers`.

## 10. Version-sensitive, environment and diagnostic notes

- minSdk 24 (Android 7.0) both repos [A9][A10]; companion APK versionName
  follows Porter's VERSION (0.1.1-beta1) with its own compat versionCode 1.
- Manager manifest tracks forward-looking permission gates:
  `NEARBY_WIFI_DEVICES` (with `neverForLocation`) for Android 16/SDK 36
  mDNS discovery; `USE_LOOPBACK_INTERFACE` + `ACCESS_LOCAL_NETWORK` for
  Android 17/SDK 37 loopback/local-network gating [A9] **[version-sensitive]**.
- Android 14+ (SDK 34) writable-dex restriction handled by the porsh script.
- Android 15+/targeting-35 foreground-service type requirement
  (`specialUse`) used by the ADB start worker and watchdog. `WRITE_SECURE_SETTINGS`
  is requested (`tools:ignore="ProtectedPermissions"`) to enable boot-time
  wireless debugging ADB.
- App targeting: SDK targets — the SDK docs say targetSdk requirements follow
  Android's own rules (e.g. provider INTERACT_ACROSS_USERS_FULL, FGS types).
- Diagnostics: `GET_DIAGNOSTICS` answer includes
  `eu.darken.porter.version.name`,
  `eu.darken.porter.version.code`, and reconciler state keys
  (`eu.darken.porter.reconciler.*`).

## 11. rish ↔ Porter — the Phase 5 open question, answered

Addresses `research/rish/00-rish-research.md` §8 ("whether the stock rish
client can connect to Porter's server").

Verified from source [A9][A10] + rish notes:

1. **Stock `rish` is not supported by Porter.** rish's client (rish script +
   `rish_shizuku.dex` + `rikka.rish.shizuku.ShizukuShellLoader`) targets the
   Shizuku-manager broadcast
   `rikka.shizuku.intent.action.REQUEST_BINDER` **and loads
   `moe.shizuku.manager.shell.Shell` out of the manager APK** handed back with
   the binder. Porter's manager APK contains `eu.darken.porter.manager.shell.Shell`
   (and porsh's loader), **not** `moe.shizuku.manager.shell.Shell`; the Porter
   companion forwards rish's `REQUEST_BINDER` broadcast [A9]
   (`compat/.../BinderRequestReceiver.kt`), but then the loader's class lookup
   into the Porter APK cannot succeed. Structurally, stock rish **cannot**
   run against Porter and there is no `rish` in Porter. (`[source-verified]`
   for the structural reason; the exact runtime failure string is
   `[DEVICE]`/`[needs verification]`.)
2. **Wire-level compatibility exists but is not what stock rish uses.** Porter's
   legacy endpoint implements the Shizuku wire v13/v6 including the terminal
   codes at base 30000. The Shizuku-wire terminal protocol is what the rish
   protocol would use if it ever reached that binder, but Porter's own client
   (`porsh`) instead uses the **Porter wire** (descriptor
   `eu.darken.porter.server.IPorterService`, codes 200–202) [A10]. The code
   comment in `porsh/.../EnvPolicy.kt` says the legacy wire "also serves
   Shizuku's own rish client through the compatibility companion" and accepts
   `RISH_PRESERVE_ENV` for that reason — that refers to the **terminal
   transport layer** on the legacy wire (reachable by a rish-style client whose
   loader can complete), not to the stock rish *tool*, which is still blocked
   earlier by its class lookup into the Porter APK (point 1).
3. **Do not write "rish works with Porter" in the Bible.** The correct
   statement is: Porter ships its own client, **porsh**, as the rish
   equivalent; the Porter Compatibility companion makes **Shizuku apps**
   (not rish the command) find Porter (AGENTS.md §19; rish notes §8).
4. Env-var naming differs: rish `RISH_APPLICATION_ID` →
   porsh `PORSH_APPLICATION_ID` (and `MANAGER_APPLICATION_ID` for the manager
   package); porsh's default manager package is baked into the exported script
   at export time. rish rejects env mismatch with "Rish requires server 12";
   porsh uses the loader-version handshake instead and warns to re-export when
   stale.
5. Behavior differences worth documenting (partly already in rish notes):
   - rish documents an env-limiting mitigation for adb backends; the porsh
     **client** indeed sends the full client env through `createHost` [A10],
     but the server filters it via `EnvPolicy` (see §6.3): dropped by default
     under an adb server unless `PORSH_PRESERVE_ENV=1`/`RISH_PRESERVE_ENV=1`,
     kept by default under root unless the `=0` variants. The `RISH_PRESERVE_ENV`
     spelling exists because the legacy wire also serves Shizuku's own rish
     client through the companion (code comment). End-to-end behavior on device
     `[needs verification]`.
   - Both run `/system/bin/sh` as the server uid; both need the dex to be
     non-writable on Android 14+; both get the binder via a package-scoped
     broadcast back to the manager (Android 8.0/8.1 chooser fallback in porsh).

## 12. Interaction with Termux (analogous to rish; port from app tutorial)

- Setup flow (from `ShellTutorialActivity` + exported script): export
  `porsh` + `porsh.dex` from Porter (SAF) into a folder Termux can read (e.g.
  `~/storage/...` or via a file manager), then in Termux copy them into the
  app-private area (e.g. `~/porsh/` or `$PREFIX/bin`) — Android 14+ wants the
  dex somewhere where `chmod 400` can remove the write bit (not a writable
  external location) — `chmod +x porsh` (or run `sh porsh`), then
  `sh porsh` / `./porsh` to get a shell at the Porter (adb/root) identity.
- `porsh` interactive gives `/system/bin/sh` (uid 2000 or 0). For a single
  command: `porsh -c 'id'` etc. (argv is forwarded after a fixed
  `/system/bin/sh`).
- First use requires the Porter permission prompt; a prior permanent denial in
  Porter's app list must be lifted there, else porsh prints "Permission
  denied".
- There is **no Termux package** providing porsh; the official distribution is
  the export flow (verify with the termux-packages index during Phase-6
  verification, mirroring the check done for shizuku/rish in Phase 5).
  `[needs verification]` (index not re-checked this session).

## 13. Security considerations (for the chapter per AGENTS.md §11/§13)

- Porter gives authorized apps the identity of the ADB shell (uid 2000,
  wide app/system permissions per Android version) or of root (uid 0). Only
  approve trusted apps; revoke per app or via "Allow app access".
- Root start is not automatic: it requires the su/SELinux setup to allow
  binder to the su (`EXIT_FATAL_BINDER_BLOCKED_BY_SELINUX`, exit 10);
  Porter does not grant root on an unrooted device.
- Server verifies the manager's signature and APK baseline; the companion is
  signature-matched to Porter (`Compatibility.isAvailable`).
- `porsh` (and rish) give whoever can invoke them a shell at the server's
  privilege, but only after the user approved the calling uid — the terminal
  client is gated exactly like any client app.
- Do not run arbitrary `porsh`/`rish` scripts downloaded from the web; the
  exported files are the authentic ones.
- Secure start mode: no plaintext credentials in the manager's backup. The
  auth token lives in the `secrets` prefs (excluded from backup per
  `BackupRulesTest`); the ADB key is deliberately left in the backed-up
  `settings` prefs but only as ciphertext under an AndroidKeyStore-bound key
  that no backup carries, so a restore cannot use it (see §4.3).
  `MANAGER_APPLICATION_ID` tampering on the command line only changes which
  package answers the binder request, not the privilege.

## 14. Troubleshooting items (docs [A4] + source)

- "Cannot start": check Porter says "Porter is running"; wireless-debugging
  must be enabled and the Wi-Fi/nearby permissions granted; some OEMs disable
  wireless debugging **[OEM]**; root start prints the SELinux/su reason and the
  exit codes listed in §4.2.
- The porsh timeout messages: "Waiting for service. This may take up to 1
  minute..." (`waitForBinder`) and the Shell startup/loader timeouts —
  disable battery optimization for both the terminal app and Porter.
- "Class not found" (loader): Porter not installed/up to date, or the files
  were re-exported from a too-old manager (re-export; loader-version check).
- "Permission denied" from porsh: lift the previous denial in Porter →
  Applications.
- Re-export after updating Porter; the startup command path can change, so
  take a fresh "start with a computer" command.

## 15. Unresolved / Needs Verification

- Stock `rish` failure against Porter: structural reason is source-verified;
  actual error output and boundary cases (e.g. a rish that never needs the
  Shell class because a binder is injected manually) `[DEVICE]`.
- Whether the `EnvPolicy` env drop/keep behaves on real devices exactly as
  coded (server-side filtering may interact with SELinux or OEM shells
  differently) `[needs verification]`.
- Wireless-debugging reliability across OEMs/pairing-code UI variants
  `[OEM]` `[DEVICE]`.
- Termux end-to-end porsh walk-through (files, `chmod`, `chmod 400`, run)
  on an actual device `[DEVICE]`.
- termux-packages index: confirm there is still no `porter`/`porsh` package
  (mirror the Phase 5 `[needs verification]` check).
- Whether any released Shizuku terminal client (legacy, rev. 30000 wire)
  exists in the wild that could connect to the legacy endpoint; not observed
  in docs. `[needs verification]`.
- Sui: out of Phase 6 scope; the Bible must still present Sui, rish, porsh,
  Shizuku, Porter, ADB, root as separate mechanisms (AGENTS.md §10) — Sui
  re-verification is a separate task.
- Future Android releases vs. the wired-in `USE_LOOPBACK_INTERFACE`
  /`ACCESS_LOCAL_NETWORK`/`NEARBY_WIFI_DEVICES` gates (SDK 37/SDK 36)
  `[version-sensitive]`.