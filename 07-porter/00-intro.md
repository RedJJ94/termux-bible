# Porter

Porter is **"ADB access for your apps"** — a minimal, maintained fork of
[Shizuku](../05-shizuku/00-intro.md) that gives Android apps ADB access
through the Shizuku APIs, with optional root support. It is an **independent,
actively maintained continuation** of the Shizuku idea: normal apps can call
system APIs with the ADB `shell` identity (or root), without the app being
system-signed and without per-command `su` prompts.

Porter is *not* root by itself, *not* a Termux tool, *not* Shizuku, and *not*
ADB. What commands run through it can do depends entirely on **who started
its server**: the ADB `shell` user (uid 2000) or root (uid 0).

This section is dedicated to Porter and its own shell client **porsh**:

- **[What Porter Is](01-what-is-porter.md)** — the project, the manager app,
  the `porter_server` process, and how Porter relates to Shizuku, Sui, rish,
  ADB, and root.
- **[Installation and Updates](02-installation.md)** — where the APK comes
  from, the Android version requirement, and why there is **no** Termux
  package to install.
- **[Architecture](03-architecture.md)** — the two Binder wires (Porter and
  Shizuku) over one shared core, and the process/packaging model.
- **[Activation and Startup](04-activation-and-startup.md)** — the three
  startup methods (wireless debugging, a computer, root), the native starter,
  and start-on-boot.
- **[Permissions and Identities](05-permissions-and-identities.md)** — the
  runtime permissions, per-app approvals, and the ADB-vs-root privilege
  boundary.
- **[Shizuku Compatibility and the Companion](06-shizuku-compatibility.md)** —
  how Shizuku-only apps find Porter, and the compatibility companion's
  identity.
- **[rish and porsh](07-rish-and-porsh.md)** — why the stock `rish` client is
  not a Porter client, and how Porter's own `porsh` differs from rish.
- **[porsh — Command Line and Termux](08-porsh-command-line-and-termux.md)** —
  exporting the files, placing them in Termux, and environment handling.
- **[App Integration and the SDK](09-app-integration-and-sdk.md)** — how
  Android apps integrate, and the `porter-api` SDK for developers.
- **[Limitations and Troubleshooting](10-limitations-and-troubleshooting.md)**
  — what Porter cannot do, common failure modes, and fixes.

## Environment distinction to keep in mind

Porter adds a **server process** to the device that is separate from every
other execution environment this Bible covers:

| Layer | What it is |
|-------|-----------|
| Native Termux | the app; `$PREFIX` binary environment, normal app UID |
| Android shell | `/system/bin/sh` (mksh) on the device |
| ADB shell | the same `/system/bin/sh` reached from a computer, uid 2000 |
| Shizuku | a privileged **server daemon** (`shizuku_server`), uid 2000 or 0 |
| Porter | a privileged **server daemon** (`porter_server`), uid 2000 or 0 |
| rish | a shell *client* that connects to a Shizuku/Sui daemon |
| porsh | a shell *client* that connects to a **Porter** daemon |

Commands run through Porter execute **with the identity of its server**, not
with the identity of the requesting app. General environment rules are in
[Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Prerequisites and security at a glance

- **Android 7.0 (API 24)** or newer is required. **[version-sensitive]**
- Porter is a young, actively developed project: the current release is
  **v0.1.1-beta1** (2026-09-08), published as a GitHub **pre-release**.
  **[version-sensitive]** — behavior may change between beta releases.
- On an **unrooted** device, starting with debugging access (wireless or a
  computer) runs the server as **uid 2000 (shell)**; the optional start-on-boot
  mode still needs Android to make debugging access available again after a
  reboot.
- Root startup is only meaningful on a **rooted** device; installing Porter
  does not root anything.
- Porter grants apps the ability to act **as that identity**. Only approve
  apps you trust, and how approval works is covered in
  [Permissions and Identities](05-permissions-and-identities.md).

## Factual baseline

This section is based on the audited Phase 6 research in
[`research/porter/00-porter-research.md`](../research/porter/00-porter-research.md)
and [`research/rish/00-rish-research.md`](../research/rish/00-rish-research.md),
verified against the official `d4rken-org/porter` and `d4rken-org/porter-api`
repositories and the official documentation at `porter.darken.eu` (fetched
2026-09-22). Behavior that needs a real device to confirm is tagged
**[DEVICE]** or **[needs verification]**; Android/version-dependent behavior
is tagged **[version-sensitive]**; OEM-specific behavior is tagged **[OEM]**.

## Cross-references

- The privilege layer Porter forked from: [Shizuku](../05-shizuku/00-intro.md)
- The shell client that connects to Shizuku/Sui: [rish](../06-rish/00-intro.md)
- The shell identity Porter usually runs as: [ADB Shell](../04-adb/04-adb-shell.md)
- Enabling the prerequisites: [USB Debugging](../04-adb/02-usb-debugging.md),
  [Wireless Debugging](../04-adb/03-wireless-debugging.md)
- The `app_process` mechanism: [The Android Shell](../03-android/01-android-shell.md)
- Environment rules: [Android Sandboxing](../00-foundations/02-android-sandboxing.md)
- Porter vs Shizuku vs Sui vs rish vs ADB vs root: distinct privileged-access
  systems, not interchangeable (AGENTS.md §10).