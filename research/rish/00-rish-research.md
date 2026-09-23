# rish — Research Notes (Phase 5)

Status: research notes supporting Phase 5 "Shizuku and rish" (PLAN.md §32) and
PLAN.md §10 (rish section topics). Not polished documentation. Distinguished
from Bible chapters per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Everything
that needs a real device to confirm is tagged **[DEVICE]**; Android/version/
backend-dependent items are tagged **[version-sensitive]**.

Audit note: all claims below were verified against official source of
`RikkaApps/Shizuku` and `RikkaApps/Shizuku-API` (master and tags) fetched
2026-09-22, plus official project READMEs and the Shizuku manager tutorial
strings. Files saved during the session; URL list in the source inventory.

Re-audited 2026-09-22 (Phase 5 audit): shipping-version claim for the `rish`
asset corrected to v12.4.3 (was "v11.2.0"), env-drop mechanism reworded per
`rikka_rish_RishHost.cpp` (inherits daemon env, not empty), source-inventory
paths aligned to the trees. See §3/§6.

---

## 1. Scope

Phase 5 rish topics (PLAN.md §10/§32): what rish is; installation/setup;
shell usage; relationship to privileged Android services; interaction with
Shizuku; interaction with Porter; command execution; permissions;
troubleshooting; limitations.

Deep Porter documentation belongs to Phase 6; here only the rish↔Porter
relationship is recorded, and open questions are explicitly deferred.

## 2. Source Inventory and Reliability Ranking

Ranking per AGENTS.md §3.2 (A = official project docs/source).

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `RikkaApps/Shizuku-API` rish module `README.md` ("RISH") | A | raw.githubusercontent.com |
| A2 | `RikkaApps/Shizuku` `manager/src/main/assets/rish` script (v13.6.0 == master) | A | raw.githubusercontent.com |
| A3 | `RikkaApps/Shizuku` `shell/src/main/java/rikka/shizuku/shell/ShizukuShellLoader.java` | A | raw.githubusercontent.com |
| A4 | `RikkaApps/Shizuku` `manager/src/main/java/moe/shizuku/manager/shell/Shell.java` | A | raw.githubusercontent.com |
| A5 | `RikkaApps/Shizuku` manager tutorial sources: `ShellTutorialActivity.kt`, `manager/.../strings.xml` | A | raw.githubusercontent.com |
| A6 | `RikkaApps/Shizuku-API`: `rish/src/main/java/rikka/rish/{Rish,RishConfig,RishConstants,RishTerminal,RishService,RishHost,FileDescriptors}.java`, `rish/src/main/cpp/{main.cpp,rikka_rish_RishHost.cpp}` | A | raw.githubusercontent.com |
| A7 | `RikkaApps/Shizuku` `server-shared/src/main/java/rikka/shizuku/server/Service.java` (binder routing, rish transaction codes) | A | raw.githubusercontent.com |
| A8 | `RikkaApps/Shizuku-API` `shared/.../ShizukuApiConstants.java`, `api/.../Shizuku.java`, `api/.../Sui.java` | A | raw.githubusercontent.com |
| A9 | Porter identity docs: `d4rken-org/porter` and `d4rken-org/porter-api` READMEs | A | raw.githubusercontent.com |
| B1 | termux-packages package index (no shizuku/rish package) | A | api.github.com |

## 3. What rish Is

Verified from [A1][A2]:

- Official description: "`rish` is an Android program for interacting with a
  shell that runs on a high-privileged daemon process."
- **Backends**: currently **Shizuku and Sui** ([A1] lists both; Sui being the
  RikkaApps Magisk module). "Follow the guide from Shizuku or Sui to create
  the files of rish."
- Historical name **`bsh`** — renamed to rish by commit `70bb1e570c`
  ("Rename bsh to rish since BeanShell uses this name", 2021-07-23 on
  master). **Shipping correction (audited)**: the `rish` asset plus the
  `ShizukuShellLoader`/`Shell` runtime first appear in the **v12.4.3** tree
  (2021-08-19); tags v11.0.0–v11.2.2 have no rish/bsh asset, and v11.3.0+ had
  a differently-named predecessor asset (`shizuku`). No v12.0.0/v12.1.0
  GitHub releases exist. Consistent with this, the `rish` client requires a
  server of major version ≥ 12 (Shell.java check). The rename commit itself is
  history of the repo's master branch, not of any released v11.2.0.
- It is **not** itself root; its privileges are those of the daemon it
  connects to (adb uid `2000` or root). It is a shell *client*: command
  arguments are passed through to a remote shell (`/system/bin/sh ` by
  default) **forked as a child process of the daemon**, using a **PTY** for
  interaction.

### Relationship to the broader Android context
- rish is the command-line bridge that lets terminal apps (including Termux)
  reach the privileged daemon. It is not the same layer as ADB, root,
  Shizuku, Porter, or Sui; it *rides on top of* a Shizuku/Sui-compatible
  server. Keep these distinct in the chapter (AGENTS.md §6/§10).

## 4. Files and Setup (Shizuku backend) [A2][A5]

Two files are needed next to each other:

- **`rish`** — a `/system/bin/sh` script (manager asset). Behavior (verified
  in full, 25 lines):
  - `BASEDIR=$(dirname "$0")`, `DEX="$BASEDIR"/rish_shizuku.dex`.
  - If dex missing → prints "Cannot find $DEX, please check the tutorial in
    Shizuku app", exit 1.
  - **Android 14+ (SDK ≥ 34)**: `app_process` cannot load a *writable* dex;
    the script runs `chmod 400 $DEX`, and if it is still writable, prints the
    guidance "You can copy the file to terminal app's private directory
    (/data/data/<package>, so that remove write permission is possible)" and
    exits 1. Place rish files under the terminal app's data directory (e.g.
    `~/rish` inside Termux) rather than `/sdcard`.
  - `[ -z "$RISH_APPLICATION_ID" ] && export RISH_APPLICATION_ID="PKG"` —
    the placeholders line says: "Replace `PKG` with the application id of your
    terminal app".
  - Executes:
    `/system/bin/app_process -Djava.class.path="$DEX" /system/bin --nice-name=rish rikka.shizuku.shell.ShizukuShellLoader "$@"`.
- **`rish_shizuku.dex`** — the loader dex (Shizuku API + shell glue).
- Export flow in Shizuku app ("Use Shizuku in terminal apps"):
  1. *Export files* (SAF) → writes both files; existing same-named files are
     deleted first. MIUI note: SAF may be broken, fallback = extract from APK
     or download from GitHub [A5].
  2. Edit `rish`, replacing `PKG` with the terminal app's package name — the
     tutorial used **Termux / `com.termux`** as the concrete example [A5].
  3. Move files to a terminal-accessible location; `chmod +x rish`, add the
     folder to `PATH` (or run via `sh rish`).
- Alternative to editing the file: set the environment variable
  `RISH_APPLICATION_ID=<package>` when invoking.

## 5. How Command Execution Works (verified from source)

### 5.1 Client side
- `ShizukuShellLoader.main` [A3]:
  - Derives the calling package from uid (`getPackagesForUidNoThrow(Os.getuid())`);
    if more than one package is mapped, falls back to `RISH_APPLICATION_ID`
    (error if unset or literally `"PKG"`).
  - Requests the daemon binder from the manager via broadcast
    **`rikka.shizuku.intent.action.REQUEST_BINDER`** (package
    `moe.shizuku.privileged.api`, extra `data` carrying a receiver binder).
  - Android 8.0/8.1: `broadcastIntent` fails for this app → falls back to
    launching a chooser activity ("Request binder from Shizuku").
  - **5 s timeout**: if no binder arrives, prints "Request timeout. The
    connection between the current app (...) and Shizuku app may be blocked by
    your system. Please disable all battery optimization features for both
    current app (...) and Shizuku app."
  - On binder received: builds a `BaseDexClassLoader` from the *manager APK*
    sourceDir + lib path, loads `moe.shizuku.manager.shell.Shell` and invokes
    its `main(args, packageName, binder, handler)`. Class-not-found → "Make
    sure you have Shizuku v12.0.0 or above installed".
- `Shell` [A4]: extends `rikka.rish.Rish`; `RishConfig.init(binder,
  BINDER_DESCRIPTOR="moe.shizuku.server.IShizukuService", 30000)`; checks
  `Shizuku.getVersion() >= 12` (else "Rish requires server 12 (running N)");
  permission request flow (granted → run; rationale → "Permission denied",
  exit 1; else request code 0 and re-run on grant, else "Permission denied").
- `RishTerminal` (client I/O) [A6]: creates pipes for stdin/stdout/stderr,
  serializes the **entire client environment** and the working directory, and
  transacts to the server: transaction codes are
  `transactionCodeStart + {0 createHost, 1 setWindowSize, 2 getExitCode}` with
  `transactionCodeStart = 30000` (`RishConfig.init(..., 30000)`), i.e.
  **30000 / 30001 / 30002** on the daemon binder. Window-size resizes are sent
  over the same channel (PTY `TIOCSWINSZ`).
- `FileDescriptors` [A6]: native fd plumbing (`getFd`, detach/close).

### 5.2 Server side (in `shizuku_server`)
- `Service.onTransact` routes the rish codes to `RishService` [A7]; all rish
  methods go through `enforceCallingPermission`.
- `RishService` [A6]:
  - `static boolean IS_ROOT = Os.getuid() == 0`.
  - `createHost`: enforces permission; reads tty flags + stdin/stdout/stderr
    file descriptors + args + env + cwd; applies the **RISH_PRESERVE_ENV
    rule** (see §6); forks a `RishHost` per calling pid.
  - Environment rule from source comments: "Termux app set PATH and LD_PRELOAD
    to Termux's internal path. Adb does not have sufficient permissions to
    access such places. Under adb, users need to set RISH_PRESERVE_ENV=1 to
    preserve env. Under root, keep env unless RISH_PRESERVE_ENV=0 is set."
  - `RishHost` (native `rikka_rish_RishHost.cpp`): fork/exec of the requested
    command with a PTY (`ptmx`), fd passing, `TIOCSWINSZ`, exit-code capture.

## 6. rish Usage Reference [A1]

- Basic rule: "replace `sh` with `rish`" — arguments pass through:
  `rish -c 'ls'` → remote executes `/system/bin/sh -c 'ls'`.
- Other remote shell: `rish exec /path/to/other/shell`.
- Options are provided via environment variable, because arguments pass
  through:
  - `RISH_PRESERVE_ENV=0` — do not change remote environment.
  - `RISH_PRESERVE_ENV=1` — replace remote environment with the local one.
  - Default if unset: **adb backend → treated as `0`**; **root backend →
    treated as `1`**.
- Practical consequence for Termux users: out of the box under a Shizuku-adb
  backend the env array is **dropped** (`RishService.createHost` sets it to
  null), and the forked `/system/bin/sh` then **inherits the daemon's own
  environment** (the adb-shell/`app_process`-launched one, PATH containing
  `/system/bin` etc. but not Termux's paths). The client never runs with
  Termux's `$HOME`-based tooling unless `RISH_PRESERVE_ENV=1` (root) is used
  or the tool is placed on the Android shell PATH. Under a root backend, the
  client env is kept if unchanged (`RISH_PRESERVE_ENV` unset ⇒ `1`).
- Interactive vs one-shot: interactive sessions use the PTY; `-c` runs a
  single command and returns its exit status.

## 7. Permissions and Privileges

- The **server** (hence the remote shell) runs as the identity that started
  Shizuku: uid `2000` (adb) or `0` (root) [A6][A7]. rish creates one host
  process per calling pid; host execution is gated by the same
  `enforceCallingPermission` used for the rest of the API (attached client
  with per-app grant or the manager/same-uid bypass).
- A rish session from a non-root, non-adb Shizuku server is impossible — the
  server requires root or shell uid up front.
- rish is NOT a root shell by default; "running under root" means the daemon
  was started as root.
- Emptying/limiting the environment is a deliberate mitigation: when the
  backend is adb, untrusted env variables (e.g. Termux paths) are dropped to
  keep commands runnable on Android's own shell environment.

## 8. rish ↔ Porter (boundary note for Phase 6)

Verified identity [A9] (Porter = `d4rken-org/porter`, "a minimal, maintained
fork of Shizuku" giving apps ADB access with optional root support; Porter API
`d4rken-org/porter-api` "keeps the Shizuku Binder protocol on the wire", so an
app can support both; there is a "Shizuku compatibility" companion and a
porting of the permission layout).

- rish's own documented backends are Shizuku and Sui — **Porter is not one of
  them** and rish source contains no Porter-specific code.
- Because Porter keeps the Shizuku binder protocol and permission layout,
  whether the stock `rish` client (which targets the manager
  `moe.shizuku.privileged.api` request-binder broadcast and loads manager
  classes from that exact package) can connect to Porter's server is **NOT
  verified** here and must be researched in Phase 6 against Porter's official
  docs/source before any claim is written.
- Do not state "rish works with Porter" unless Phase 6 verification supports it
  (AGENTS.md §19).

## 9. Termux Integration (verified, authoritative source) [A5]

- The Shizuku manager's tutorial explicitly targets Termux: replace `PKG`
  with **`com.termux`**; move the exported `rish` + `rish_shizuku.dex` into a
  Termux-accessible directory (e.g. `~/rish`), `chmod +x rish`, add to
  `PATH`, then call `rish`.
- Android 14+: ensure `rish_shizuku.dex` is not writable (chmod 400 handled by
  the script); in Termux the recommended place is the app-private directory
  tree so the permission sticks.
- Env caveat (§6) applies inside Termux: prefer `RISH_PRESERVE_ENV=1` under a
  root daemon; under adb daemon remember Termux's PATH/LD_PRELOAD are not
  visible to `/system/bin/sh` unless preserved.
- There is **no official Termux package** named `shizuku`/`rish`/`sui`
  (full termux-packages index checked, 4000+ names, 2026-09-22) — setup is
  the manual export/edit flow. Third-party helper repos exist
  (e.g. `AlexeiCrystal/termux-shizuku-tools`, `merbah3266/rish_installer`)
  but are community projects (B-level sources), not authoritative.

## 10. Limitations and Troubleshooting (rish-specific)

- **Server ≥ 12 required**; older server → "Rish requires server 12".
- **Request timeout (5s)**: manager or terminal app is background-restricted /
  battery optimized; disable battery optimization for both; also Shizuku may
  simply not be running.
- **Dex writable (Android 14+)**: move rish files out of `/sdcard` into the
  terminal app's data folder; ensure `chmod 400` succeeds.
- **`RISH_APPLICATION_ID` not set / equals `PKG`**: set it to the terminal
  app's id (or edit the script).
- **Permission denied** printed by Shell when the permission was previously
  denied-and-don't-ask-again: grant inside Shizuku app first.
- Add env caveats: commands the user expects (e.g. Termux-only binaries) may
  be "not found" because the remote shell is Android's `/system/bin/sh`, not a
  Termux shell.
- All of the above device-dependent failures are `[DEVICE]`.

## 11. Unresolved / Needs Verification

- End-to-end interactive rish session on a real device with Termux —
  `[DEVICE]`.
- rish ↔ Porter compatibility (defer to Phase 6; see §8).
- Sui backend details (Magisk module install; not exercised here).
- Whether transaction codes 30000/30001/30002 are stable across server
  versions ≥ 12 (codes come from `RishConfig` init value `30000`; the client
  and server must agree — assumed stable, verify against Sui server if needed).