# Installation

Shizuku is installed as an **Android application** — the manager app, package
**`moe.shizuku.privileged.api`**. There is no Termux equivalent and nothing to
`pkg install` on the Termux side.

## Runtime requirement

- **Android 6.0 (API 23)+** for both Shizuku and Sui. **[version-sensitive]**

## Official sources

The app is distributed from:

- **Google Play** — search for "Shizuku".
- **GitHub Releases** — `github.com/RikkaApps/Shizuku/releases` (the APK
  asset; current release v13.6.0 as of 2026-09-22).
- **Coolapk** — Chinese app store.
- **IzzyOnDroid** — a F-Droid-style repository.

Use these sources only. A privileged-access server is a high-value target:
do not install Shizuku from random mirrors or websites.

## No Termux package exists

The Termux package repository has **no** `shizuku`, `rish`, or `sui` package
(verified against the full termux-packages index of 4000+ package names,
2026-09-22). **[version-sensitive]** — this is a fact about the repository,
not a statement that the packages could never be added.

Consequences for a Termux user:

- `pkg install shizuku` and `pkg install rish` do **not** exist. Do not look
  for them.
- The command-line side is set up by **exporting the `rish` files from the
  manager app** followed by a small edit; see
  [Command-Line Use and Termux](05-command-line-and-termux.md) and the
  [rish section](../06-rish/00-intro.md).
- Third-party helper repositories exist in the community (for example
  `AlexeiCrystal/termux-shizuku-tools`, `merbah3266/rish_installer`) but they
  are **community projects**, not part of Shizuku or Termux, and are not
  documented as authoritative here.

## After installing

Once the manager is installed you normally need to **start the server** before
anything can use Shizuku — installation alone gives you nothing. Proceed to
[Activation and Startup](03-activation-and-startup.md).

## Security notes

- Verify the package you install belongs to the real Shizuku (check the
  package name and the source you downloaded from).
- A Shizuku-enabled app that is granted the permission runs as the server's
  identity. Audit which apps you grant `API_V23` to (see
  [Permissions](04-permissions.md)).

## References

- Download page: `shizuku.rikka.app/download.html` (Play, GitHub, Coolapk,
  IzzyOnDroid).
- Release asset check and termux-packages index check recorded in
  `research/shizuku/00-shizuku-research.md` (§2 A5/B1, §10).