# Permissions and Application Integration

Shizuku's permission model decides **which apps may call system APIs through
the server**, and the server's **launch identity** decides **with what
privileges** those calls actually run. This chapter covers both.

## The runtime permission: `API_V23`

The permission name is:

```
moe.shizuku.manager.permission.API_V23
```

- Declared in the manager manifest as a **dangerous** runtime permission, in
  permission group `moe.shizuku.manager.permission-group.API`.
- It has existed under this name in the manager source at every version checked
  (v11.0.0 … v13.6.0). Use this exact name; older documentation that used a
  different (pre-v11) scheme is **historical** and unsupported.

## How a grant happens (the flow)

1. An app that is "Shizuku-enabled" requests access at runtime with
   `Shizuku.requestPermission(...)`.
2. The server shows a confirmation dialog (via the manager's
   `REQUEST_PERMISSION` activity). The user grants **always** or **one-time**
   (or denies).
3. The server records the decision. Grants are stored; **one-time grants are
   not persisted** and revert on process death. "Deny and don't ask again" is
   honored — `shouldShowRequestPermissionRationale` reflects denied entries.
4. For the granted package the server **also grants/revokes the corresponding
   Android runtime permission** for every matching package.

## Who is allowed to call the server (enforcement)

Verified from the server source (`Service.enforceCallingPermission`): a caller
is accepted if any of these holds:

- (**a**) it is the **server itself** (same uid/pid);
- (**b**) it is the **manager app** — operations the manager performs on
  attached clients;
- (**c**) it **already holds the `API_V23` runtime permission** — checked
  directly, even before a client is attached/registered;
- (**d**) it is an **attached client** whose recorded `allowed` flag is true.

Otherwise the call is rejected with a `SecurityException` ("not an attached
client" / "requires permission"). Certain manager-only operations additionally
require the manager identity (`enforceManagerPermission`).

This matters to users as a *security boundary*: granting the app the
`API_V23` permission is what makes the app able to act as the Shizuku server
identity. Revoke grants in the Shizuku app when an app no longer needs them.

## What the server's identity can do — the ADB-vs-root boundary

The server runs as **uid 0** (root launch) or **uid 2000** (adb/shell
launch). The privileges available are those of that identity, not "everything":

- **ADB/shell launch (wireless or computer)**: the process gets the Android
  permission set that AOSP grants to the Shell app — this is a long,
  **version-sensitive** list from
  `frameworks/base/packages/Shell/AndroidManifest.xml`, including e.g.
  `WRITE_SECURE_SETTINGS`, `PACKAGE_USAGE_STATS`, `MANAGE_APP_OPS_MODES`,
  `READ_LOGS`, `DUMP`, `FORCE_STOP_PACKAGES`, `INJECT_EVENTS`,
  `DELETE_PACKAGES`, `REBOOT`, network settings, and many `MODIFY_*`
  permissions. **[version-sensitive]** — this list changes across Android
  versions; do not treat a specific permission as present on every device.
- **Linux-level limits still apply to the 2000 identity**: even with an
  Android permission granted, uid 2000 cannot read other apps' private data
  under `/data/user/0/<package>`, and filesystem/capabilities/SELinux restrict
  what it can do.
- **Root launch (uid 0)** is not limited that way — hence **always determine
  which identity a given Shizuku is running as** before assuming capabilities.
  Use `Shizuku.getUid()` (in an app) or check how the server was started.

### AOSP Shell permission list — keep version-sensitive

The authoritative list for the adb identity is AOSP's Shell manifest. When
documenting or relying on a *specific* shell permission (for example
`WRITE_SECURE_SETTINGS`), state it as version-sensitive and point at the
manifest, rather than asserting it as universal.

## Application integration (for developers)

An app adds Shizuku support with the two libraries:

```
dev.rikka.shizuku:api
dev.rikka.shizuku:provider
```

Then in its manifest it declares:

- `<uses-permission android:name="moe.shizuku.manager.permission.API_V23"/>`
- a provider:
  ```
  <provider
      android:name="rikka.shizuku.ShizukuProvider"
      android:authorities="${applicationId}.shizuku"
      android:permission="android.permission.INTERACT_ACROSS_USERS_FULL"/>
  ```

Apps that declare this permission receive the server binder **automatically
when the server starts** (delivered through the provider via `sendBinder`; the
recipient is added to the power-save temporary whitelist for 30 s so the
process can initialize). There is **no `Shizuku.bind()`** in the current API —
binder acquisition is automatic via `ShizukuProvider`. Multi-process apps must
call `ShizukuProvider.enableMultiProcessSupport()`.

Client API surface (current): `addBinderReceivedListener` (and sticky variant),
`addBinderDeadListener`, `addRequestPermissionResultListener`,
`onBinderReceived`, `pingBinder`, `transactRemote`, `getUid`, `getVersion`,
`getServerPatchVersion`, `getSELinuxContext`, `requestPermission`,
`checkSelfPermission`, `shouldShowRequestPermissionRationale`,
`checkRemotePermission`, and the `UserServiceArgs` +
`bindUserService`/`unbindUserService`/`peekUserService` family.
**[version-sensitive]** — verify against the library version you build with.

Hidden-API note: from Android 9, normal apps cannot call hidden Android APIs.
Shizuku-based apps frequently want such APIs and often add hidden-API bypass
libraries. That is an app-level concern, not something Shizuku itself solves.

## Security summary

- The `API_V23` grant is the on/off switch for "this app acts as Shizuku".
- The *power* of a grant equals the *launch identity* of the server. On an
  unrooted device that is the adb `shell` set; with root startup that is root.
- Grant deliberately, review in the Shizuku app, and revoke when done.
- Do not conflate a Shizuku **grant** with root, nor with ADB itself.

## References

- Source: `server-shared/.../Service.java`, `ShizukuService.java`,
  `ConfigManager` (`FLAG_ALLOWED`/`FLAG_DENIED`), the manager manifest
  (permission + `REQUEST_PERMISSION` activity), AOSP
  `frameworks/base/packages/Shell/AndroidManifest.xml`, Shizuku-API
  `Shizuku.java`/`ShizukuProvider`.
- Phase 4 (shell identity) context: [The Android Shell](../03-android/01-android-shell.md).
- Phase 5 research notes: `research/shizuku/00-shizuku-research.md` (§6, §7).