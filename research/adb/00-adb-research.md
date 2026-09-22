# ADB — Research Notes (Phase 4)

Status: research notes supporting Phase 4 "ADB and Android Debugging" (PLAN.md
§32) and PLAN.md §8 (ADB, wireless debugging, screenshots, screen recording,
file transfer). Not polished documentation. Distinguished from Bible chapters
per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Everything
that needs a real device/network to confirm is tagged **[DEVICE]**;
Android/adb-version-dependent items are tagged **[version-sensitive]**.

Audit note: the primary ADB reference is the official developer.android.com
/tools/adb page, fetched 2026-09-22 via `r.jina.ai` and read in full (631 lines,
saved to `/root/.local/share/opencode/tool-output/tool_0cac7801f001Rss83nsBAcwe7H`).
Wireless-debugging internals cross-checked against AOSP `adb_wifi.md`.
Screen-record constants verified from AOSP `frameworks/av` `screenrecord.cpp`.

---

## 1. Scope

Phase 4 ADB topics (PLAN.md §8/§32): ADB; wireless debugging; file transfer;
screenshots; screen recording; Android shell access via ADB; and the
privileged-access boundary used to keep `adb`/root/Shizuku/Porter/rish
distinct (AGENTS.md §6/§10; detail deferred to Phases 5/6).

## 2. Source Inventory and Reliability Ranking

Ranking per AGENTS.md §3.2 (A = official project docs/source).

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | developer.android.com/tools/adb (full official reference) | A | r.jina.ai (saved file) |
| A2 | AOSP `packages/modules/adb/docs/dev/adb_wifi.md` | A | googlesource |
| A3 | AOSP `frameworks/av/cmds/screenrecord/screenrecord.cpp` (main) | A | googlesource `?format=TEXT` |
| A4 | AOSP `packages/modules/adb/daemon/restart_service.cpp` (main) | A | googlesource `?format=TEXT` |
| A5 | termux-packages `packages/android-tools/build.sh` | A | raw.githubusercontent.com |
| A6 | nmeum/android-tools `CMakeLists.txt`, `vendor/CMakeLists.txt` | A | raw.githubusercontent.com |
| A7 | termux-tools `src/cmd.c`, `scripts/Makefile.am` (cmd wrapper / wrappers) | A | raw.githubusercontent.com |
| A8 | Shizuku official user manual (shizuku.rikka.app/guide/setup) | A | r.jina.ai |

## 3. ADB Architecture, Install Sources

Verified from [A1]:

- Three components: **client** (runs command lines, on the development
  machine), **daemon adbd** (runs commands on the device, background process),
  **server** (manages client↔daemon communication, background process on the
  development machine).
- Server binds to local TCP port **5037**; all clients use it.
- Server locates devices: scans odd ports **5555–5585** for emulators (first
  16 emulators; e.g. Emulator 1 console 5554 / adb 5555).
- Positioned as part of Android SDK Platform Tools (`android_sdk/platform-tools/`);
  standalone download available from developer.android.com Studio releases.

**Termux option (native):** `pkg install android-tools` installs the ADB/fastboot
reimplementation used by Termux, which is `nmeum/android-tools` + android-vendored
sources, **v37.0.0** with `TERMUX_PKG_AUTO_UPDATE=true` [A5][A6]. Version note:
this is the *Termux build* of adb; behavior is documented as close to platform-tools
but the package removes `bin/mkbootimg` (conflicts with the `mkbootimg` package)
[A5]. Depends: abseil-cpp, brotli, fmt, libc++, liblz4, libprotobuf, pcre2,
zlib, zstd [A5].

MDNS note for `android-tools` — **RESOLVED at audit (2026-09-22)**: the
upstream build option `ANDROID_TOOLS_ADB_ENABLE_MDNS` defaults **OFF** and the
Termux `packages/android-tools/build.sh` (master, 2026-09-22) passes only
`-DANDROID_TOOLS_USE_BUNDLED_LIBUSB=ON` (bundled-libusb USB backend) with no
mDNS flag — so **mDNS is OFF in the current Termux adb build** (`adb mdns` /
Wi-Fi 2.0 auto-discovery are unavailable there). **[version-sensitive]**
because `TERMUX_PKG_AUTO_UPDATE=true` repackages upstream adb regularly;
re-check at drafting. USB/legacy flows are unaffected.

## 4. Enabling Debugging (USB path)

Verified from [A1]:

- Enable **USB debugging** under Developer options.
- Developer options hidden by default since Android 4.2 (API 17); reveal by
  tapping Build number (per studio dev-options guide).
- Since Android 4.2.2 (API 17), an RSA-key authorization dialog appears on
  first connect ("Allow USB debugging"); commands cannot run without accepting
  it while the device is unlocked.
- Verify connection with `adb devices`.

## 5. Wireless Debugging (Android 11+)

Verified from [A1]:

- Wireless debugging exists on **Android 11 (API 30)+** for phones; **Android
  13 (API 33)+** required for **TV and Wear OS**. Same wireless network as the
  host required.
- Pairing is a one-time step (QR or pairing code) — stays paired until you
  forget the workstation or revoke authorizations; devices reconnect
  automatically on the same network.
- "Pairing code" flow: device shows IP:port + pairing code → host runs
  `adb pair ipaddr:port` → enter code when prompted → then verify with `adb
  devices`; device appears as `ipaddr:port` (e.g. wireless entries like
  `0.0.0.0:6520`).
- Marking a network "always allow on this network" in the wireless-debugging
  prompt makes it a **trusted wireless debugging network**.
- Unpair: device → Wireless debugging → Paired devices → Forget; or **Revoke
  adb debugging authorizations** (removes all workstations).
- Quick toggle exists via Quick settings developer tiles (Wireless debugging
  tile).
- QR pairing is an **Android Studio / device-camera flow**: the QR encodes the
  pairing secret (as a `WIFI:T:ADB;...` string) plus a requested pairing
  service-instance name. The `adb pair ipaddr:port` CLI itself prompts for the
  numeric 6-digit code [A2]; devices expose a `Pair device with QR code` path
  for Studio.

### 5.1 Pairing internals [A2]

Verified from AOSP `adb_wifi.md` (docs source; markup summarized):

- Pairing uses an **RSA-2048 x509** key exchange; trust is bootstrapped by a
  shared secret: a 6-digit pairing code or a 10-digit QR-code payload.
- Two transport classes: **TLS (`A_STLS`)** vs legacy **`A_AUTH`** (non-TLS
  handshake). The legacy `adb tcpip` mDNS service and the new TLS pair/connect
  services are separate mDNS types:
  - `_adb._tcp` — legacy `adb tcpip <port>` service (A_AUTH);
  - `_adb-tls-pairing._tcp` — pairing advertising;
  - `_adb-tls-connect._tcp` — paired/connectable advertising (A_STLS).
- The TLS/pairing servers bind to a **random port**, not a fixed 5555.
- Host public keys authorized by pairing are stored at
  **`/data/misc/adb/adb_keys`** (also `/adb_keys` in recovery/root contexts).
- After pairing, the host auto-connects; the device advertises itself and
  reconnects to previously paired hosts on the same network.

## 6. Wireless Troubleshooting, mDNS and "ADB Wi-Fi 2.0"

Verified from [A1] ("Resolve wireless connection issues"):

- `adb server-status` should show `version: "37.0.0"` (or higher) and
  `mdns_enabled: true`; if mdns disabled, set `ADB_MDNS=1` and restart via
  `adb kill-server` + any adb command (start-server). It also shows
  `mdns_backend` (see §8).
- `adb mdns track-services --proto-text` on the workstation lists mDNS
  services; a TLs service with `_adb-tls-connect._tcp`, device IP:port,
  `mdns_service_version`, etc. confirms network mDNS + paired device.
- **ADB Wi-Fi 2.0** is introduced on **Android 17 together with adb 37.0.0**
  [A1]: the device automatically connects to the workstation when the device
  connects to a *trusted wireless debugging network*. Support is Android
  17+; check device via `adb mdns track-services --proto-text` → output must
  contain `mdns_service_version: "2.0"` or higher.
- Pairing a device once = device appears automatically when on a trusted
  network; revoke via device UI.

## 7. Legacy Wi-Fi (Android 10 and lower)

Verified from [A1]:

- Workflow (per official docs, framed for Android 10/API 29 and lower, also
  applicable to Android 11+ with an initial USB step):
  1. Device and host on a common Wi-Fi network (firewall-friendly AP needed);
  2. connect USB; run `adb tcpip 5555`;
  3. disconnect USB; note device IP;
  4. `adb connect device_ip_address:5555`;
  5. `adb devices` shows `device_ip_address:5555 device`.
- Reconnect after lost connection: ensure same network, run `adb connect`
  again; if that fails `adb kill-server` then start over. `adb tcpip` opens a
  **legacy, non-TLS TCP listening service on 5555**. It is NOT "unauthenticated":
  connections still perform the legacy RSA **`A_AUTH`** handshake and a new
  host still requires RSA authorization [A2]; the real caveat is that
  **traffic is unencrypted plaintext** (in-transit eavesdropping/MITM).
  Security note: only use on trusted networks (AGENTS.md §11).

## 8. ADB Transport Backends (version lock)

Verified from [A1]:

- **USB backends**: native OS backend or libusb; `ADB_LIBUSB` env selects;
  since **ADB v34** libusb is default on all OS except Windows (native).
  `attach`/`detach`/USB-speed detection need libusb.
- **mDNS backends**: since ADB v37 the server ships `libadbmdns` and
  `openscreen`; **`libadbmdns` is default and recommended**; `ADB_MDNS_OPENSCREEN`
  env =1/0 switches (openscreen macOS support since v35; Win/Linux since v34).
- **Burst Mode** (experimental, adb 36.0.0+): enables pipelined transfers
  (`ADB_BURST_MODE=1` or Android Studio debugger setting). Disabled by default.

## 9. Device Selection and States

Verified from [A1]:

- `adb devices` / `adb devices -l`; per-device info: serial,
  state (`offline`, `device`, `no device`), and with `-l` description
  (product/model/device).
- `device` state does not imply boot completed; device registers with adb
  during boot.
- Serial formats seen in docs: `emulator-5554`; USB serials (`0a388e93`);
  wireless `ipaddr:port` (e.g. `0.0.0.0:6520`).
- Target a device: `-s serial`, `-d` (single hardware device), `-e` (single
  emulator), or `$ANDROID_SERIAL` env var (`-s` overrides env). Ambiguous
  multi-device → error "adb: more than one device/emulator".

## 10. Common ADB Commands (verified examples)

From [A1] (all official):

- `adb install path_to_apk`; `-t` required for test APKs (Gradle/monkey);
  `adb install-multiple` for split APKs.
- `adb forward tcp:6100 tcp:7100` (host→device); also `localhost:logd`.
- `adb push local remote` / `adb pull remote local` (arbitrary dirs/files;
  contrast with `install` which is APK-specific).
- `adb kill-server` stops server; any adb command restarts it.
- `adb shell shell_command` (single command) / `adb shell` (interactive; exit
  with Ctrl+D or `exit`).
- `adb shell ls /system/bin` lists device tools.
- **Arg quoting**: since Platform Tools 23, adb handles arguments the way
  `ssh(1)` does; metacharacters require **double quoting** (once for local
  shell, once for remote), e.g. `adb shell setprop key "'two words'"`.
- `adb exec-out` for raw binary output, e.g.
  `adb exec-out screencap -p > screen.png` (see §13).
- `adb root`/`adb unroot` — debuggable-build-only (§12).
- Lookup: `adb help` / `adb --help`.
- Also documented: `cmd package dump-profiles`, `cmd testharness enable`
  (device reset path, Android 10+), `sqlite3` remoting, `am`/`pm`/`dpm` — see
  `research/adb/01-android-command-ecosystem-research.md`.

## 11. Security / Authorization Model

Combining [A1] and [A2]:

- USB: RSA authorization dialog since Android 4.2.2; keys stored on-device.
- Wireless: pairing code (6-digit) or QR (10-digit payload) → RSA-2048 x509;
  host keys in `/data/misc/adb/adb_keys`; TLS (A_STLS) preferred; legacy
  A_AUTH only for legacy `adb tcpip`.
- "Disable adb authorization timeout" option exists on Android 11+ (per
  Shizuku setup FAQ, which recommends it to keep adb sessions alive). [A8]
- Security warnings to include in Bible (AGENTS.md §11): legacy `adb tcpip`
  carries **unencrypted plaintext** traffic over the network — connections are
  still RSA-authenticated via the legacy `A_AUTH` handshake, but data is not
  encrypted, so restrict it to trusted networks; USB debugging must be revoked
  on lost/lent devices; pairing codes are short-lived secrets.

## 12. ADB Privilege Boundary (kept distinct per AGENTS.md §10)

- `adb shell` runs as **uid 2000 shell user**, SELinux domain `shell` (see
  `research/android/00-android-shell-research.md` §5–§7).
- `adb root`/`adb unroot` restart adbd as root **only on debuggable builds**;
  on production builds adbd answers "adbd cannot run as root in production
  builds" [A4].
- Shizuku/Porter start their server via `adb shell` + `app_process` and expose
  a shell interface (rish / porsh); they **do not require or grant root**. See
  the phase-boundary note in `research/android/00-android-shell-research.md`
  §11 and Phase 5/6 research (to come). Do not document "Shizuku = root".

## 13. Screenshot and Screen Recording

Verified from [A1] plus AOSP constants [A3].

### 13.1 `screencap`

- `adb shell screencap /sdcard/screen.png`; interactive session example from
  docs; `adb pull /sdcard/screen.png`.
- Omitting filename writes PNG to stdout; the one-liner is
  `adb exec-out screencap -p > screen.png` ("use 'exec-out' instead of 'shell'
  to get raw data"). `-p` = PNG.
- `screencap` example calls it a shell utility "for taking a screenshot of a
  device display".

### 13.2 `screenrecord`

Verified docs [A1]:

- Device shell utility for **Android 4.4 (API 19)+**.
- Usage `screenrecord [options] filename`; e.g.
  `adb shell screenrecord /sdcard/demo.mp4`.
- Records MPEG-4; press Ctrl+C to stop, else auto-stops at **3 minutes** or
  `--time-limit`. Default/native resolution; retained aspect; default max
  length 3 min.
- Limitations (docs): **audio is not recorded**; not available on **Wear
  OS**; some devices can't record at native resolution (try lower); **screen
  rotation during recording not supported**.
- Options table (docs): `--size widthxheight` (e.g. 1280x720; default native,
  fallback 1280x720), `--bit-rate rate` (default 20Mbps), `--time-limit time`
  (default & max 180s), `--rotate` (experimental), `--verbose`; `--help`.

Verified constants from AOSP `screenrecord.cpp` main [A3]
**[version-sensitive]**: `kMaxBitRate = 200 * 1000000` (200 Mbps — hard cap),
`kMaxTimeLimitSec = 180`, `gTimeLimitSec` default 180, and
`gTimeLimitSec = (timeLimitSec == 0) ? UINT32_MAX : timeLimitSec` — i.e. a
**time limit of 0 means unlimited** in current AOSP. The docs table still
states "default and maximum 180"; the discrepancy is version-sensitive
(drag-history) and must be tagged.

## 14. Version-Sensitive / Device-Dependent Items (must carry a tag in the Bible)

- Wireless debugging availability: Android 11+ (phone), Android 13+ (TV/Wear
  OS). ADB Wi-Fi 2.0 mirroring/trusted-network auto-connect: Android 17 +
  platform-tools 37.0.0. §5/§6
- mDNS/USB backends & Burst Mode: ADB v34/v35/v36/v37 gates. §8
- RSA dialog behavior: Android 4.2.2+. §11
- `adb root`: debuggable builds only. §12
- `screenrecord` limits and "limit 0 = unlimited": AOSP-main vs released
  versions; check device `--help`. §13
- `android-tools` Termux package: v37.0.0 as of compile date; auto-updated;
  mDNS default-OFF upstream **and not enabled in the Termux build** (verified
  2026-09-22). §3

## 15. Unresolved / Missing Research

1. **RESOLVED 2026-09-22 (audit):** Termux `android-tools` does not enable
   mDNS — `build.sh` passes only `-DANDROID_TOOLS_USE_BUNDLED_LIBUSB=ON`, and
   the upstream `ANDROID_TOOLS_ADB_ENABLE_MDNS` defaults OFF (see §3). Re-check
   at drafting because the package is auto-updated.
2. `adb pair` exact CLI surface across adb versions (pairing command syntax
   variants, QR-only in Studio) — covered by docs; device-side steps vary by
   OEM GUI.
3. `screenrecord --time-limit 0` support per released Android version (docs
   still say "default and maximum 180"; AOSP main allows 0=unlimited).
4. Behavior of wireless debugging behind restrictive APs (client-isolation
   / mDNS) — **[DEVICE]** testing only.
5. **RESOLVED 2026-09-22 (audit):** `adb tcpip` remains documented on the
   official page as the ≤Android 10 path (still applicable to Android 11+ with
   an initial USB step). Wi-Fi 2.0 (Android 17 + adb 37) adds automated
   trusted-network reconnection but does not remove `adb tcpip`.
6. adb server "log_absolute_path" and `ADB_TRACE=all` debugging flow — noted
   in docs; not exercised.

## 16. Source URL List

- https://developer.android.com/tools/adb
- https://android.googlesource.com/platform/packages/modules/adb/+/HEAD/docs/dev/adb_wifi.md
- https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/cmds/screenrecord/screenrecord.cpp
- https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/daemon/restart_service.cpp
- https://raw.githubusercontent.com/termux/termux-packages/master/packages/android-tools/build.sh
- https://raw.githubusercontent.com/nmeum/android-tools/master/CMakeLists.txt
- https://raw.githubusercontent.com/nmeum/android-tools/master/vendor/CMakeLists.txt
- https://shizuku.rikka.app/guide/setup

## 17. Research Audit Log

- 2026-09-22 Initial compile. ADB reference read in full from the saved
  official-page capture; wireless internals cross-checked against AOSP.
  Outstanding before drafting: re-verify provision 15.1 (Termux mDNS),
  15.3/15.5 with the exact released adb/Android versions to be documented;
  confirm adb "Wi-Fi 2.0" wording matches the current official page at
  drafting time.
- 2026-09-22 Phase 4 RESEARCH AUDIT: resolved §15.1 (Termux mDNS OFF — verified
  build.sh passes no mDNS flag) and §15.5 (`adb tcpip` retained); corrected the
  "unauthenticated TCP" claim in §7/§11 (legacy `adb tcpip` is non-TLS but
  still RSA `A_AUTH`-authenticated; the caveat is unencrypted traffic);
  fixed §5.1 QR/`adb pair` wording; added `/adb_keys`; noted the bundled-libusb
  build flag. Remaining: §15.3 (`--time-limit 0` per released versions) —
  confirm against the exact released adb/Android version documented at
  drafting.