# Installation and Updates

The official distribution is a **Download Porter from GitHub Releases** flow:
there is no Termux package (see below) and the installation is a normal APK
install. Everything here is verified against the official docs
(`porter.darken.eu/setup`) and the release assets.

## Where the APK comes from

1. Download the Porter APK from the **Assets** section of
   `github.com/d4rken-org/porter/releases`. Source-code ZIP and TAR files on
   that page are *not* Android apps.
2. Open the APK on the device. If Android asks, allow the browser or file
   manager to install apps from this source.
3. Open Porter.

The current release as of drafting is **v0.1.1-beta1** (2026-09-08). Its
Assets section contains:

| Asset | Purpose |
|-------|---------|
| `porter-v0.1.1-beta1-release.apk` | the manager app (the FOSS build) |
| `porter-compat-v0.1.1-beta1-release.apk` | the standalone **Porter Compatibility** companion |
| `SHA256SUMS` / `verification.txt` | checksum / verification files published alongside the APKs (not audited in detail here) |
| `build-info.json` | build metadata |

**[version-sensitive]** — asset names and versions change with every release;
**only install the APK from the official GitHub Releases page of
`d4rken-org/porter`.** The companion is optional and only needed for Shizuku-only
apps ([Shizuku Compatibility and the Companion](06-shizuku-compatibility.md)).

## Requirements

- **Android 7.0 (API 24) or newer.** The docs and the code agree:
  `minSdk = 24`. **[version-sensitive]**
- For wireless debugging startup: **Android 11+** and a Wi-Fi connection.
- For root startup: **working root access** on the device.

## Flavors and the embedded companion

- Porter builds two flavors: **foss** (the free/open-source build, which
  **embeds the signed Porter Compatibility APK** inside the manager APK) and
  **gplay** (a build for Play constraints, companion *not* embedded).
- The published `porter-v0.1.1-beta1-release.apk` is the **FOSS** build
  (verified from source and the release assets), so the companion is available
  inside the manager under **Shizuku compatibility** without a separate
  download. A standalone companion APK is also published for manual installs.

## Updating Porter

- Install the newer APK **over** the existing app, then start Porter again.
- Android requires **matching signatures** for an update; if the install
  refuses, the most common cause is a differently-signed APK (see
  [Limitations](10-limitations-and-troubleshooting.md)).
- After updating: **re-export the porsh files** and **get a fresh "start with
  a computer" command** — the startup-command path can change between
  installations (see [Activation and Startup](04-activation-and-startup.md)).
- If you use the companion, update **it** from the same release.

## Why there is no Termux package

There is **no `porter` or `porsh` package** in the termux-packages repository
(the Phase 5 audit verified the index for `shizuku`/`rish`/`sui`; a Phase 6
index re-check for `porter`/`porsh` is still pending in the research notes —
**`[needs verification]`**). Command-line use is the manual export flow
described in [porsh — Command Line and Termux](08-porsh-command-line-and-termux.md),
exactly as with rish.

## Security notes

- Install only from the official GitHub Releases page. The release ships
  `SHA256SUMS` (checksums) and `verification.txt` (verification material) —
  treat any APK distributed elsewhere as untrusted.
- Porter does **not** root your device. (See also the
  [security considerations in Permissions and Identities](05-permissions-and-identities.md).)

## References

- Official setup guide: `porter.darken.eu/setup`.
- Release data: `api.github.com/repos/d4rken-org/porter/releases`.
- Phase 6 research notes: `research/porter/00-porter-research.md` (§2, §3, §5.1).