# Relationship to Privileged Services and Permissions

This is the "who is who" chapter. ADB, root, Shizuku, Sui, rish, and Porter are
**separate privileged-access systems** (AGENTS.md §10); this chapter states
where rish sits among them and what permission checks protect the server.

## How the systems relate to rish

| System | Role | Relationship to rish |
|--------|------|---------------------|
| **Shizuku** | a server daemon (uid 2000 or 0) that apps can call | the **primary rish backend**; rish connects to its daemon |
| **Sui** | RikkaApps **Magisk module** (root required) | the **other documented rish backend** |
| **ADB** | the debug bridge from a computer | not a backend; rish does not use the adb transport. Shizuku *started through* ADB runs as the shell identity, which is what rish then inherits |
| **Root** | uid 0 via `su`/Magisk | not "rish" — Shizuku started with root gives rish root identity |
| **Porter** | separate maintained Shizuku-like project (Phase 6 topic) | **not a documented rish backend**; compatibility unverified |
| **Termux** | the normal-app environment you type in | rish is run *from* Termux but is not a Termux tool and does not run as Termux |

The identity rish commands get is always the **daemon's** identity:
- Shizuku started via wireless/ADB on an unrooted device → **uid 2000**
  (adb `shell` permission set; see
  [Permissions](../05-shizuku/04-permissions.md)).
- Shizuku (or Sui) started with root → **uid 0**.

## rish and Porter — the open question [phase boundary]

Porter (`d4rken-org/porter`) is described by its authors as "a minimal,
maintained fork of Shizuku" that gives apps ADB access with optional root
support, and its API (`porter-api`) is described as "keeping the Shizuku Binder
protocol on the wire", with a Shizuku-compatibility companion and a porting of
the permission layout.

- **The stock `rish` client's documented backends are Shizuku and Sui.** The
  rish source contains no Porter-specific code.
- Whether the stock rish client — which specifically asks **the
  `moe.shizuku.privileged.api` manager** for the binder and loads that exact
  package's classes — can talk to a Porter server is **NOT verified** in this
  phase. **Do not assume "rish works with Porter".** This is a Phase 6
  research question to be answered against Porter's official documentation and
  source before any claim is written.

## Permission checks on the server side

The server gates every rish operation with the same
`enforceCallingPermission` used across the Shizuku API. A caller is accepted
when any of these holds (details in
[Shizuku Permissions](../05-shizuku/04-permissions.md)):

- the **server itself**;
- the **manager app**;
- a caller that **already holds the `API_V23` runtime permission**;
- an **attached client** whose stored `allowed` flag is true.

The rish session additionally runs the normal app-level permission flow:
`Shell` requests the Shizuku permission and refuses to start if it was denied
(printing "Permission denied" and exiting 1 if a "don't ask again" denial is
in effect — grant it inside the Shizuku app first).

## Version boundaries [version-sensitive]

- **Server major version ≥ 12** is required; else: "Rish requires server 12
  (running <n>)". Current Shizuku servers are **13.x**.
- The loader prints "Make sure you have Shizuku v12.0.0 or above installed" if
  the manager's `Shell` class cannot be loaded (e.g. an old Shizuku).
- Relative version model used by the daemon and the client:
  `SERVER_VERSION = 13`, `SERVER_PATCH_VERSION = 6` on the current API
  (Shizuku-API master, 2026-09-22).

## What this means in practice

- On an **unrooted** phone, rish gives you the **adb shell permission set**
  (uid 2000): powerful Android permission list, but plain-Linux limits remain
  (cannot read most other apps' data under `/data/user/0/`, no full
  filesystem access). See
  [Shizuku Permissions](../05-shizuku/04-permissions.md).
- On a **rooted** phone you can instead have rish run as **uid 0** (via
  root-started Shizuku or the Sui backend).
- The distinction "rish = root" is incorrect; "rish = the daemon's identity" is
  accurate.

## References

- Shizuku-API rish README and source (`Shell.java`, `RishConfig.java`).
- Server source: `Service.java` (binder routing + enforcement).
- Porter identity docs: `d4rken-org/porter`, `d4rken-org/porter-api` READMEs
  (Phase 6 research will use these as the authoritative source).
- Phase 5 research notes: `research/rish/00-rish-research.md` (§7, §8, §11).