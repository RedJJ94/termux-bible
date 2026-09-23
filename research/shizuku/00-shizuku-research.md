# Shizuku — Research Notes (Phase 5)

Status: research notes supporting Phase 5 "Shizuku and rish" (PLAN.md §32) and
PLAN.md §9 (Shizuku section topics). Not polished documentation. Distinguished
from Bible chapters per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Everything
that needs a real device/network/boot to confirm is tagged **[DEVICE]**;
Android/version-dependent items are tagged **[version-sensitive]**;

Audit note: all code-level claims below were verified against the official
`RikkaApps/Shizuku` and `RikkaApps/Shizuku-API` repositories (master and
version tags) fetched 2026-09-22, plus the official user manual and release
notes. Raw source files were saved during the session; URLs are listed in the
source inventory. Nothing was copied from memory-only recollection.

Re-audited 2026-09-22 (Phase 5 audit): version dates and the v11.2.0 rish
claim corrected (rises to v12.4.3), master-vs-v13.6.0 confirmed via the
`compare/` API, client API method list corrected against `Shizuku.java`,
enforcement list and A6/A8 paths corrected. See §5.1/§6/§7/§8.

---

## 1. Scope

Phase 5 Shizuku topics (PLAN.md §9/§32): what Shizuku is; installation;
activation; supported startup methods; wireless debugging; ADB-based startup;
root startup; permissions; application integration; command-line use;
limitations; troubleshooting; interaction with Termux.

Deep Porter documentation is a Phase 6 deliverable; only the rish↔Porter
relationship is in Phase 5 scope and is recorded in the rish notes.

## 2. Source Inventory and Reliability Ranking

Ranking per AGENTS.md §3.2 (A = official project docs/source).

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `RikkaApps/Shizuku` repo README (master) | A | raw.githubusercontent.com |
| A2 | `RikkaApps/Shizuku-API` repo README (master) | A | raw.githubusercontent.com |
| A3 | Shizuku official user manual `shizuku.rikka.app/guide/setup.html` (Last updated 2023-06-21) | A | webfetch |
| A4 | Shizuku download page `shizuku.rikka.app/download.html` | A | webfetch |
| A5 | Shizuku GitHub Releases API (v11.2.0→v13.6.0) | A | api.github.com |
| A6 | Shizuku source, master ≈ v13.6.0 for the code paths discussed (see §8): `Starter.kt`, `StarterActivity.kt`, `BootCompleteReceiver.kt`, `manager/src/main/jni/starter.cpp`, `manager/src/main/res/raw/start.sh` (removed as of v13.6.0), `manager/src/main/assets/rish`, `shell/src/main/java/rikka/shizuku/shell/ShizukuShellLoader.java`, `manager/src/main/java/moe/shizuku/manager/shell/Shell.java`, `manager/src/main/AndroidManifest.xml`, `manager/src/main/res/values*/strings.xml`, `server/src/main/java/rikka/shizuku/server/ServerConstants.java`, `server/src/main/java/rikka/shizuku/server/ShizukuService.java`, `manager/src/main/java/moe/shizuku/manager/adb/*.kt` | A | raw.githubusercontent.com |
| A7 | Same files at tags v11.0.0, v11.2.0, v12.4.3, v13.0.0, v13.6.0 for version comparison (plus `git/compare/v13.6.0...master`) | A | raw.githubusercontent.com |
| A8 | `RikkaApps/Shizuku-API` (HEAD a27f6e41, 2025-05-29): `api/src/main/java/rikka/shizuku/Shizuku.java`, `api/src/main/java/rikka/sui/Sui.java`, `shared/src/main/java/rikka/shizuku/ShizukuApiConstants.java`, `server-shared/src/main/java/rikka/shizuku/server/Service.java`, `rish/src/main/java/rikka/rish/{Rish,RishConfig,RishConstants,RishTerminal,RishService,RishHost,FileDescriptors}.java`, `rish/src/main/cpp/{main.cpp,rikka_rish_RishHost.cpp}`, `rish/README.md` | A | raw.githubusercontent.com |
| A9 | AOSP `frameworks/base/packages/Shell/AndroidManifest.xml` (adb/shell uid granted permissions) | A | android.googlesource.com |
| A10 | `d4rken-org/porter`, `d4rken-org/porter-api` READMEs (identify Porter; see rish notes) | A | raw.githubusercontent.com |
| B1 | termux-packages full package index (shizuku/rish package absence check, 4000 names) | A | api.github.com |

## 3. What Shizuku Is

Verified from [A1][A2]:

- Official description: "Using system APIs directly with adb/root privileges
  from normal apps through a Java process started with `app_process`." Repo
  created 2017-05-24.
- A standard Android application (manager, package **`moe.shizuku.privileged.api`**)
  that runs a privileged server process; normal apps talk to that server with
  the `dev.rikka.shizuku:api` + `dev.rikka.shizuku:provider` libraries and can
  run Java/JNI code *with root/shell (ADB) identity* — without the app itself
  being system-signed or having per-command `su` prompts.
- Works on rooted and non-rooted devices. On non-rooted devices it must be
  restarted with adb after every boot (before Android 11 a computer was
  required; Android 11+ can re-start via wireless debugging from the device).
- Runtime requirement: **Android 6.0+** for Shizuku and Sui [A2].
- Distribution [A4]: Google Play, GitHub Releases, Coolapk, IzzyOnDroid F-Droid
  repository.
- Terms to keep distinct (AGENTS.md §10): ADB, root, Shizuku, Porter, rish,
  Sui. Shizuku grants access to exactly the privileges of the mechanism that
  started it (adb shell uid `2000` or root uid `0`); it is *not* root by
  itself on an unrooted device.

## 4. Architecture (verified from source [A6][A8])

- **Manager app** `moe.shizuku.privileged.api` owns the shared APK. The APK is
  used as the `CLASSPATH` of the server process (server classes live in the
  manager APK).
- **Server process** `shizuku_server`, main class
  `rikka.shizuku.server.ShizukuService`, started with `/system/bin/app_process`
  (DdmHandleAppName set to `shizuku_server`). It waits for the `package`,
  `activity`, `user`, `app_ops` system services; requires the manager installed
  (else `System.exit(ServerConstants.MANAGER_APP_NOT_FOUND)`); watches for
  manager uninstall / APK change (`ApkChangedObservers`).
- **Server identity**: the process runs as whatever uid started it — uid `0`
  (root) or `2000` (adb/shell). The API exposes this via `Shizuku.getUid()`
  and `BIND_APPLICATION_SERVER_UID` (verified constant names in
  `ShizukuApiConstants`). So "Shizuku permissions" == the permissions of the
  adb `shell` uid or of root, depending on launch mode. **[version-sensitive]**.
- **Binder delivery**: on startup the server delivers its `IShizukuService`
  binder to the manager and to every app that declares the Shizuku permission,
  via an exported content provider `authorities = "<applicationId>.shizuku"`
  (call `sendBinder`), adding each recipient to the power-save temporary
  whitelist for 30 s, with a force-stop-and-retry path when a provider is
  found dead [A6][A8].
- **Client API** (`rikka.shizuku` package): `Shizuku` static class with
  `addBinderReceivedListener` (+sticky variant), `addBinderDeadListener`,
  `addRequestPermissionResultListener`, `onBinderReceived`, `pingBinder`,
  `transactRemote`, `getUid`, `getVersion`, `getServerPatchVersion`,
  `getSELinuxContext`, `UserServiceArgs` +
  `bindUserService/unbindUserService/peekUserService`, `checkRemotePermission`,
  `requestPermission`, `checkSelfPermission`,
  `shouldShowRequestPermissionRationale`. There is **no `Shizuku.bind()`** and
  **no `getSystemProperty`/`setSystemProperty`** in the current API — binder
  acquisition for apps is done automatically via `ShizukuProvider`
  (declared with `android:permission=...INTERACT_ACROSS_USERS_FULL`), which
  triggers `onBinderReceived` for apps that declared the Shizuku permission
  [A8]. Binder descriptor: **`moe.shizuku.server.IShizukuService`**;
  `SERVER_VERSION = 13`, `SERVER_PATCH_VERSION = 6` on Shizuku-API master
  (v13.6.0-era server) [A8].
- **Sui**: separate project (`RikkaApps/Sui`), a **Magisk module** (requires
  unlocked bootloader / root). Shizuku-API works against both; since
  **Shizuku-API v12.1.0** (library changelog; no server release v12.1.0 exists)
  `ShizukuProvider` auto-initializes Sui (opt-out:
  `disableAutomaticSuiInitialization()`). Sui is referenced as a *rish backend*.

## 5. Startup Methods

The user manual [A3] documents three ways to start the server:

1. **Root**: "For rooted devices, just start directly." With root, a
   **start-on-boot** setting exists (`settings_start_on_boot`; receiver
   watches `LOCKED_BOOT_COMPLETED`/`BOOT_COMPLETED` and starts via root shell)
   [A6].
2. **Wireless debugging (Android 11+, API 30)**: no computer needed; enable
   Developer options → USB debugging → Wireless debugging; pair once with
   pairing code (entered into Shizuku's notification); then start from the
   app. Steps must be redone after each reboot "[due to] system limitations"
   [A3]. The manual notes background restrictions and OEM quirks (see §10).
3. **Connecting to a computer (unrooted, Android 10 and below)**: run an adb
   command on a computer; must be redone after each reboot [A3].

### 5.1 Start command — CURRENT (v13.6.0) vs DOCUMENTED (start.sh) — CONFLICT

- **Current (v13.6.0+, source)**: the manager ships the starter as a native
  binary `manager/src/main/jni/starter.cpp` built as `libshizuku.so` and
  installed into the manager's `nativeLibraryDir`. `Starter.kt` (verified)
  builds: `userCommand = <nativeLibraryDir>/libshizuku.so`;
  `adbCommand = "adb shell $userCommand"`;
  `internalCommand = "$userCommand --apk=<manager apk sourceDir>"`.
  So the app-facing ADB command looks like
  `adb shell /data/app/<...>/lib/<abi>/libshizuku.so --apk=<manager apk path>`
  (exact path is device-dependent `[DEVICE]`). Release note v13.6.0: "Update
  the start command. You can copy this file to any executable location, such
  as /data/local/tmp/shizuku." The binary accepts `--apk=`; without it it
  runs `pm path moe.shizuku.privileged.api` to locate the APK [A6].
  Note: `starter.cpp` itself has existed since at least v11.0.0 — the v13.6.0
  change was to *stop using a shell script* and target the binary directly.
- **Historical (≤ v13.5.4)**: the command documented in the official user
  manual [A3] and shipped as `manager/src/main/res/raw/start.sh`:
  `adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh`
  ("Command for Shizuku v11.2.0+"). The script was *not* the server starter —
  it was a bootstrap that staged a copy of the native `libshizuku.so` in the
  app's install dir to `/data/local/tmp/shizuku_starter` (chmod 700,
  chown 2000:2000) and exec'd it with the manager APK path as `$1`. That file
  was **removed** by commit `de83bd11d7` ("Remove start.sh", 2025-05-25),
  which updated `Starter.kt`/`StarterActivity` to run `libshizuku.so`
  directly; the manual page's "Last Updated: Jun 21, 2023" date predates
  this. **For v13.6.0 the website instructions are outdated** — record this
  as a version-sensitive conflict in the Bible chapter.

### 5.2 starter.cpp internals (v13.6.0) [A6]

Verified from source:

- UID check: refuses anyone other than `uid 0` (root) or `uid 2000`
  (adb/shell) — "fatal: run Shizuku from non root nor adb user (uid=%d)."
- Prints `info: shizuku_starter exit with 0` on success (StarterActivity waits
  for that exact string before treating startup as done).
- Kills any existing `shizuku_server` first (SIGKILL by process name); if EPERM
  → "fatal: can't kill %d, please try to stop existing Shizuku from app first."
- For root: switches cgroup (`/acct`, `/dev/cg2_bpf`, `/sys/fs/cgroup`, or
  `/dev/memcg/apps` if `ro.config.per_app_memcg`), switches mount namespace to
  init (`switch_mnt_ns(1)`) on API 29+; SELinux checks that the su context
  allows `untrusted_app` to bind/transfer binder (exit code 10 on failure).
- Sets `CLASSPATH` = manager APK, computes lib path
  `<apkdir>/lib/<abi>`, runs `/system/bin/app_process
  -Djava.class.path=<apk> -Dshizuku.library.path=<apkdir>/lib/<abi> /system/bin
  --nice-name=shizuku_server rikka.shizuku.server.ShizukuService`.
- Exit codes: 3 (classpath), 4 (fork), 5 (app_process), 6 (uid), 7 (manager
  apk path), 9 (kill), 10 (SELinux/root).

### 5.3 Wireless debugging — current manager internals [A6]

- The manager embeds its own ADB stack: `moe.shizuku.manager.adb.{AdbClient,
  AdbKey, AdbMdns, AdbPairingClient, PreferenceAdbKeyStore}` plus a TLS pair
  flow; `StarterActivity` receives `EXTRA_HOST`/`EXTRA_PORT` from wireless
  debug settings and runs `AdbClient(host, port, key)` →
  `shellCommand(Starter.internalCommand)`.
- Error mapping in StarterActivity: `AdbKeyException` (key store),
  `NotRootedException` (start_with_root_failed), `ConnectException`
  (cannot_connect_port), `SSLProtocolException` (adb_pair_required) —
  useful troubleshooting strings.
- **Auto-start on boot (Android 13+/API 33+, adb mode)**: `BootCompleteReceiver`
  (verified) — after boot, if last launch mode was `ADB` and the app holds
  `android.permission.WRITE_SECURE_SETTINGS`, it sets
  `Settings.Global.adb_wifi_enabled`/`ADB_ENABLED` and uses an mDNS-announced
  local TLS connection to `127.0.0.1:<port>` to run `Starter.internalCommand`
  ("trusted WLAN" case; matches release note "Support auto start without root
  on Android13+ when connected to a trusted WLAN"). Root mode: also starts on
  boot directly. `[DEVICE]`. The white-listed-WLAN behavior itself is
  Android's wireless-debugging feature (`[version-sensitive]`: the code gates
  on `Build.VERSION_CODES.TIRAMISU`, 33).

## 6. Permission Model

Verified from [A6][A8] and against tags [A7]:

- Name: **`moe.shizuku.manager.permission.API_V23`** (`ServerConstants.PERMISSION`).
  Declared in the manager manifest as **dangerous**, in permission group
  `moe.shizuku.manager.permission-group.API`. Present in source at every tag
  checked (v11.0.0 … v13.6.0); so current docs should use this exact name.
- Pre-v11 used a different scheme; per the Shizuku-API migration guide,
  "Self-implemented permission is used from v11" and pre-v11 was dropped
  (still show "not supported"). The manager retains legacy pieces, e.g. the
  `REQUEST_AUTHORIZATION` activity guarded by the old
  `moe.shizuku.manager.permission.API` [A6]; the pre-v11 runtime detail is
  history only — do not document as current.
- Server-side enforcement (`server-shared/Service.java`, verified — server
  overrides in `ShizukuService.java`): each API method calls
  `enforceCallingPermission`; accepted callers are (a) the server itself
  (same uid/pid), (b) the manager app (`checkCallerPermission`:
  `appId(callingUid) == managerAppId`), (c) *any* caller that already holds
  the API_V23 runtime permission (checked directly even before
  attach/registration), or (d) an *attached client* whose recorded `allowed`
  flag is true; otherwise `SecurityException` "not an attached client" /
  "requires permission". Manager-only operations additionally use
  `enforceManagerPermission`.
- Grant flow: server → shows a permission confirmation (via the manager's
  `REQUEST_PERMISSION` activity) → user grants always or one-time → server
  records flags (`ConfigManager.FLAG_ALLOWED/FLAG_DENIED`, MASK_PERMISSION)
  and grants/revokes the runtime permission for every matching package.
  One-time grants are not persisted; "deny and don't ask again" is honored
  (`shouldShowRequestPermissionRationale` reflects denied entries).
- Successful attach (`attachApplication`) requires the calling package to
  belong to the calling uid; the reply bundle carries server version/uid/
  secontext/permission-granted/rationale flags, and grants `WRITE_SECURE_SETTINGS`
  to the **manager** itself on attach.
- Application integration (for the Bible's "how apps use it"): a client app
  adds `dev.rikka.shizuku:api` and `dev.rikka.shizuku:provider`, declares
  `<provider android:name="rikka.shizuku.ShizukuProvider"
  android:authorities="${applicationId}.shizuku"
  android:permission="android.permission.INTERACT_ACROSS_USERS_FULL"/>` and
  `<uses-permission android:name="moe.shizuku.manager.permission.API_V23"/>`,
  then requests runtime permission. Apps that declare the permission receive
  the binder automatically when the server starts. (Multi-process apps must
  call `ShizukuProvider.enableMultiProcessSupport()`.)
- **ADB vs ROOT privileges** (document explicitly per AGENTS.md §10):
  - The **adb `shell` uid's Android permission set** is whatever AOSP grants to
    Shell — authoritative list in AOSP `frameworks/base/packages/Shell/AndroidManifest.xml`
    [A9] (fetched: large; includes e.g. `WRITE_SECURE_SETTINGS`,
    `PACKAGE_USAGE_STATS`, `MANAGE_APP_OPS_MODES`, `READ_LOGS`, `DUMP`,
    `WRITE_APN_SETTINGS`, `CHANGE_COMPONENT_ENABLED_STATE`, `FORCE_STOP_PACKAGES`,
    `INTERACT_ACROSS_USERS`, `INJECT_EVENTS`, `SET_DEBUG_APP`, `DELETE_PACKAGES`,
    `REBOOT`, network settings, many `MODIFY_*`, etc.). **[version-sensitive]**:
    this list changes across Android versions; cross-check the version matrix
    at drafting.
  - Linux-level limits always apply: e.g. shell cannot read other apps' private
    data under `/data/user/0/<package>`; filesystem/capabilities/SELinux
    limit what adb uid 2000 can do even with the Android permission granted.
  - Root (uid 0) is not limited that way — hence the chapter must always say
    *which* identity Shizuku currently runs as.
- Hidden-API caveat from repo README: from Android 9, normal apps' use of
  hidden APIs is restricted (apps often add hidden-API bypass libraries);
  relevant because Shizuku-based apps frequently call hidden APIs.

## 7. Command-Line Use (rish) and Termux Interaction

Full rish research is in `../rish/00-rish-research.md`. Shizuku-side facts that
belong in the Shizuku chapter:

- The manager provides rish: home card **"Use Shizuku in terminal apps"**
  opens a tutorial that exports two files from the manager APK assets:
  **`rish`** (shell script) and **`rish_shizuku.dex`**; export uses SAF, and
  existing same-named files in the chosen folder are deleted first [A6].
- Tutorial step 2 literally demonstrates editing `rish` for **Termux**:
  replace the `PKG` placeholder with `com.termux` (string
  `terminal_tutorial_2_description` mentions "Termux" and "com.termux").
  In general, replace `PKG` with the terminal app's application id, or set
  `RISH_APPLICATION_ID` (rish script: `[ -z "$RISH_APPLICATION_ID" ] &&
  export RISH_APPLICATION_ID="PKG"`).
- Step 3: move files somewhere the terminal app can access; grant execute to
  `rish` and add to `PATH` to call it directly.
- Android 14+ (API 34) restriction: `app_process` refuses to load a
  **writable** dex; rish script attempts `chmod 400` and otherwise instructs
  copying into the terminal app's private directory (`/data/data/<package>`).
  Corresponding release note v13.5.2: "On Android 14+ ... place rish files in
  /sdcard will not work, users need to copy rish files to terminal apps' data
  folder." **[version-sensitive]**.
- MIUI/SAF caveat in tutorial string: SAF export may be broken on MIUI;
  fallback is extracting the files from the APK or downloading from GitHub [A6].
- rish requires server version ≥ 12 (`Shell.java` checks
  `Shizuku.getVersion() < 12` and prints "Rish requires server 12 (running
  <n>)"); the interactive shells spawned by rish inherit the server's
  identity (adb uid 2000 or root).

## 8. Version / Android-Reliability Summary [A5][A7]

| Version | Date | Notes |
|---------|------|-------|
| ≤ v10.x | pre-2021 | pre-v11 permission scheme (now unsupported) |
| v11.0.0 | 2021-01-18 | `API_V23` runtime permission present; library rename to `rikka.shizuku` API + `ShizukuService`→`Shizuku` (pre-v11 migration guide) |
| v11.2.0 | 2021-02-21 | start.sh adb-command era ("Command for Shizuku v11.2.0+"; rish does NOT ship here — see below) |
| v12.x | first release v12.4.3 (2021-08-19) | no v12.0.0/v12.1.0 GitHub releases exist; Shizuku-API **v12.0.0** added UserService daemon mode + `peekUserService`; **`rish` asset + `ShizukuShellLoader`/`Shell` runtime ship from v12.4.3**; rish requires server ≥ 12 |
| Shizuku-API v12.1.0 | library changelog | `ShizukuProvider` auto-initializes Sui (`disableAutomaticSuiInitialization()` opt-out) |
| v13.0.0 … v13.5.4 | 2023-02-01 … 2024-03-10 | API v13; v13.5.1 "potentially fixed several issues of rish"; v13.5.2 Android 14 writable-dex rish note + ColorOS Android 14; v13.5.3 "(should) work on Android 14 QPR2" (author-untested); v13.5.4 Android 14 QPR3 beta 2 |
| v13.6.0 | 2025-05-25 | native `libshizuku.so` direct start command; start.sh removed; auto-start (rootless) on Android 13+ trusted WLAN; Android 16 QPR1 |

Current state checked at audit (2026-09-22): **v13.6.0 is still the latest
GitHub release**. Master HEAD is `b844bc49` (2025-06-18); only 5 commits sit
on master after v13.6.0 (license/LTO/AGP/fa-strings), none of which touch the
starter, rish, server, or shell code paths — so master == v13.6.0 for every
code-level claim in these notes (verified via `GitHub compare v13.6.0...master`).

The website user manual (setup page) still shows the `start.sh` command and
predates v13.6.0 — **conflict to flag** (AGENTS.md §15 style: the Bible site
should cite the version headline and mark the website as stale-for-v13.6.0).

## 9. Limitations and Troubleshooting (FAQ topics from [A3])

- Service stops at reboot (non-root); must be restarted after every boot.
- Some OEM systems break startup: MIUI — enable "USB debugging (Security
  options)"; ColorOS/OnePlus — disable "Permission monitoring"; Flyme —
  disable "Flyme payment protection". **Background restrictions** are the most
  common cause of failure/random stops: allow Shizuku to run in background,
  keep USB debugging / Developer options enabled, pick "Charge only" USB mode,
  enable "Disable adb authorization timeout" (Android 11+), etc. `[OEM]`
  untestable here.
- GrapheneOS: "Secure app spawning" may need to be disabled (per user manual
  note, with source reference).
- Wireless-debugging issues: "Searching for pairing service" loop → allow
  background/network; pairing prompt on MIUI → switch notification style to
  "Android"; `[DEVICE]`.
- Diagnosing success: StarterActivity success line is
  `"info: shizuku_starter exit with 0"`.

## 10. Unresolved / Needs Verification

- Exact on-screen string of the v13.6.0 start command on a real device
  (path includes installation dir) — `[DEVICE]`; can be derived from
  `Starter.userCommand` at runtime.
- Wireless-debugging pairing flow behavior on a device — `[DEVICE]`.
- Auto-start on trusted WLAN across OEM power-management policies — `[DEVICE][OEM]`.
- Pre-v11 permission name and exact v10.x behavior (history only; not
  re-derived from old-tag source in this phase).
- Whether rish client works against Porter's Shizuku compatibility (Porter is
  a maintained Shizuku fork keeping the binder protocol on the wire) — defer
  to Phase 6; see `../rish/00-rish-research.md`.
- No official Termux package exists for Shizuku (checked full termux-packages
  index, 4000+ package names, 2026-09-22); rish-in-Termux is the manual
  export/edit flow above.