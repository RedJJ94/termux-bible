# Permissions and Identities

What Porter's code can actually do is decided by the **identity of the running
server**. This chapter covers the runtime permissions behind access, how
approvals and the master switch work, and the privilege boundary between ADB
and root.

## The runtime permissions [source-verified]

| Permission | Protection | Notes |
|-----------|-----------|-------|
| `eu.darken.porter.permission.API` | dangerous | **Porter wire** — what the manager and Porter-supporting apps request |
| `eu.darken.porter.permission.MANAGER` | signature | used by the manager itself; granted by the OS to the manager package because it is signed with the manager's key |
| `moe.shizuku.manager.permission.API_V23` | dangerous | the **legacy Shizuku permission** — requested by Shizuku-only apps; only relevant when a trusted compatibility companion is installed |

The **server** is the delegate of all grant/revoke operations: the manager's
attached server record makes `checkPermission` and
`requestPermission` behave "like `u0_aXXX` is their caller". So the manager
does not interact with the user itself for a first-time app request; the
**server** dispatches the permission-request activity
(`eu.darken.porter.intent.action.REQUEST_PERMISSION`, delivered to the
manager) in the current foreground Android user.

## Grant flow

1. A client app attaches: a Porter-aware app through its own app provider,
   a Shizuku-only app through the companion's forwarding — see
   [Shizuku Compatibility](06-shizuku-compatibility.md).
2. On its first request the server creates an access record with state
   **Pending**, then dispatches a confirmation **activity** in the current
   foreground user: the manager's request screen with **Deny** and **Allow all
   the time** buttons. (The server also supports one-time grants; see step 5.)
   Denying **permanently** stores a "permission denied" record in Porter's own
   configuration and keeps the request failing; the denial is Porter's
   record, not an Android permission state that the OS enforces.
3. After the user grants:
   - a **runtime permission** record is created, and the runtime permission is
     **granted** to the app (grant via the UI, not via `requestPermissions`).
4. Denying a request **revokes, and `forceStops` the app**, because the
   Shizuku-style workflow expects a "deny = app must die" semantics.
5. One-time grants are possible: the confirmation dialog can be answered for
   **only this time** (the access record stays *pending*, so the next request
   asks again; the permission record is **not** persisted).

## Approvals and the master switch

- Each app that requests access appears in that **app's own** Android
  permission screen (**Settings → Apps → `<the app>` → Permissions → "Allow
  app access"**). At the OS level the runtime grant belongs to the **client
  app**, not to Porter.
- Porter additionally surfaces per-app access **records** with **Yes / No**
  and a one-time grant option, on its own settings screen.
- The **"Allow app access"** master switch at the top of Porter's
  **Applications** screen is Porter's global pause, stored as
  `isAccessPaused` in its own configuration: while off, every client is
  treated as not allowed and each new request is answered with a
  `SecurityException`. Individual approvals are preserved and resume when the
  switch is turned back on. The server itself keeps running; it does not
  record these refusals as denials.
- **Already-started shell commands (porsh) may continue running while access
  is paused** (the official guide says exactly this). New requests — including
  starting a new porsh session — are refused while it is off.

## Identity: uid 2000 (ADB) vs uid 0 (root)

The server runs as the uid of whatever started it:

| Startup method | uid | Identity and what that means |
|----------------|-----|------------------------------|
| Wireless debugging / computer | **2000** | the **adb `shell`** identity — the same permission set that `adb shell` and rish-over-Shizuku use; cannot read other apps' private data, cannot write system partitions, cannot bypass MAC |
| Root | **0** | root — can read/write anything, subject to SELinux (root SELinux context handling is by the underlying `su`) |

`connection.uid` exposes the actual value so apps can show the difference.
What the shell identity can and cannot do is the same as
[Android's built-in shell user](../04-adb/04-adb-shell.md): define and query
system properties, use AM/PackageManager, `pm`/`dumpsys`/`settings`/`wm` (with
`WRITE_SECURE_SETTINGS`-style privileges where granted), run `sh` — but not
read `/data/user/0/<other-app>` without root.

**Never assume one identity because of how you started it once.** The same
device can run Porter as both, depending on the startup method chosen last.

## Root-manager identity checks

- Starter (root start) requires caller uid **0** **or** **2000** (code 6).
- SELinux: root start verifies the `su` context allows app→su Binder (code 10).
- The **server always exposes exactly the identity that started it** — it does
  not escalate on its own.

## Signature checks

- The manager APK itself is signature-checked; the server only accepts the
  manager with the matching signature (via `verifyPackage`) and the manager
  only accepts builds whose v2 signature (and the embedded companion's
  signature) matches. The **Porter Compatibility** companion must be signed
  with **Porter's key** to be trusted (a differently-signed fake gets
  *readOwnerPermissions = false*).
- The OS enforces signature-level grants automatically at install time
  (first install: `MANAGER` granted).

## Security considerations

- **Whoever the server acts as, that is what approves the app's request
  runs as.** A compromised app approved for access can do anything the ADB
  shell (or root) can do — modify system settings, control `pm` grants,
  change system properties.
- Approve only apps you trust. After granting, access can be revoked in
  Porter → **Applications** (or in the client app's own Android permission
  screen).
- A permanent denial is recorded in Porter's own configuration, next to the
  app in its app list; lift it there (Porter → Applications) before that app
  can request access again. See
  [Troubleshooting](10-limitations-and-troubleshooting.md).

## References

- Phase 6 research notes: `research/porter/00-porter-research.md` (§5.4, §6.3,
  §11.3).
- Cross-reference: what uid 2000 can do —
  [ADB Shell](../04-adb/04-adb-shell.md);
  the same model in Shizuku — [Shizuku Permissions](../05-shizuku/04-permissions.md).