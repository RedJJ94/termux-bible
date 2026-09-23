# Shizuku Compatibility and the Companion

Porter inherits the Shizuku **API** and keeps the shizuku-compat surface for
apps. This chapter separates the two kinds of "Shizuku compatibility" so they
are never confused:

- **Shizuku API compatibility** — apps that were written against the Shizuku
  SDK can reach Porter. This works.
- **Terminal/rish compatibility** — the stock `rish` command-line client
  connecting to Porter. This does **not** work (see
  [rish and porsh](07-rish-and-porsh.md)).

Factual baseline: the companion module source and the official "App
compatibility" documentation, audited in the [Phase 6 research
notes](../research/porter/00-porter-research.md) (§5.2, §7).

## Two compatibility layers in the manager

1. **"Shizuku support"** in the Porter settings: lets the manager itself and
   other **Porter-aware** apps talk to Porter through the native
   `moe.shizuku` surface. Porter's SDK also has a **Shizuku backend** so
   apps can work with either daemon (see
   [App Integration and the SDK](09-app-integration-and-sdk.md)).
2. **"Shizuku compatibility"** in the Porter home/settings: the **Porter
   Compatibility** companion APK, which is what actually makes **Shizuku-only**
   apps (apps that hard-decode the `moe.shizuku` identity and don't support
   Porter directly) find Porter at all.

## The Porter Compatibility companion

- **Identity:** it is published under **Shizuku's own package identity**
  (`applicationId = moe.shizuku.privileged.api`), with Porter's project
  namespace (`eu.darken.porter.compat`) and signed with **Porter's key**.
  This identity is why the OS treats it like Shizuku.
- **Purpose:** a thin bridge that forwards binder requests from Shizuku-only
  apps to the real Porter server:
  - `BinderRequestReceiver` receives the **`rikka.shizuku.intent.action.REQUEST_BINDER`**
    broadcast that Shizuku-only clients send to `moe.shizuku.privileged.api`,
    and forwards it to **`eu.darken.porter.intent.action.REQUEST_BINDER`**.
  - It also opens Porter for **`moe.shizuku.manager.intent.action.REQUEST_PERMISSION`**
    and **`moe.shizuku.privileged.api.intent.action.REQUEST_PERMISSION`**
    intents, which is how the permission confirmation dialog reaches the
    right target.
- **What it does not contain:** the companion is deliberately **empty of all
  Porter runtime logic** — no server classes, no porsh/shell dex, no
  Shizuku-style daemon — so it cannot "do" anything itself. It is a routing
  shim only.

## Installation and coexistence

- The official documentation explicitly warns that **if the genuine Shizuku
  app is installed, uninstall Shizuku before installing the companion**.
  The companion is an Android package that **competing installation** with
  Shizuku (and with other apps using the `moe.shizuku.privileged.api`
  identity, i.e. "Shizuku forks").
- The FOSS build **embeds the signed companion** inside the Porter APK
  (verified from source). In the manager, **Shizuku compatibility → Replace**:
  stops any running Shizuku service, **uninstalls Shizuku**, installs the
  embedded companion, and **imports eligible access decisions** by checking
  currently installed apps. **Porter decisions take precedence** over imported
  ones. Shizuku's app settings and **pairing configuration are not imported**;
  if the access database cannot be read, you approve apps again.[source-verified]
- Two other options exist on that screen: **Install automatically** (installs
  the embedded APK only) and **Manual** (keeps the companion out of the
  manager and suggests a separate manual install of the standalone
  `porter-compat-v0.1.1-beta1-release.apk`).
- Imported access decisions are counted but do **not** include Shizuku's IDs
  settings or pairing configuration.
- While the standalone companion is present, the manager's own **Shizuku
  support** interacts with it only via the compatibility paths; removing the
  companion prevents older (Shizuku-only) clients from using Porter, per the
  official troubleshooting guide.[source-verified]

## What Shizuku-only apps experience

- Shizuku-only apps resolve their service binder exactly as with a real
  Shizuku: through their **own** `${applicationId}.shizuku` provider (their
  `ShizukuProvider`, or Porter's SDK's `PorterShizukuApiProvider`), or via
  the **`rikka.shizuku.intent.action.REQUEST_BINDER`** broadcast that the
  companion forwards to Porter. Either way the server that answers is
  **Porter's**, on the legacy **Shizuku wire** (protocol v13/v6). An old app's
  settings may therefore still say "Shizuku" while Porter serves it — that is
  expected and harmless.[source-verified]

## When the companion is NOT needed

- Porter-aware apps (those using the `porter-api` SDK, or the manager's own
  "Shizuku support") do not need the companion at all — they use the Porter
  wire with the `eu.darken.porter` identity.
- You do not need it if no fine-grained **Shizuku-only** app is installed;
  the companion exists *so they can work*, not because Porter depends on it.

## References

- Official docs: `porter.darken.eu/docs/sc/` ("Porter vs Shizuku",
  "Shizuku compatibility", "App compatibility").
- Phase 6 research notes: `research/porter/00-porter-research.md` (§5.2, §7).
- Source: `eu.darken.porter.compat` companion module, `PorterShizukuCompatibility`
  and the replacement/import logic in the manager (HEAD `585aae5`).