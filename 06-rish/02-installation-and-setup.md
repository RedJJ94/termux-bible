# Installation and Setup

Setting up rish is a **file export plus a one-line edit** — there is no
Termux package to install (no `rish`/`shizuku`/`sui` package exists in the
termux-packages repository; verified against the full index, 2026-09-22
**[version-sensitive]**). The two files come from the Shizuku app (or Sui,
for the Sui backend).

## The two files

You need both, **in the same directory**:

| File | Role |
|------|------|
| **`rish`** | a small `/system/bin/sh` script (25 lines in the shipped version) |
| **`rish_shizuku.dex`** | the loader dex (Shizuku API + shell glue) |

For the Shizuku backend they are exported from the manager app.

## Exporting from the Shizuku app

1. Open the manager and tap the home card **"Use Shizuku in terminal apps"**.
2. **Export files** (uses the SAF file picker).
   - Existing **same-named files in the chosen folder are deleted first**.
   - MIUI caveat **[OEM]**: SAF export can be broken on MIUI; the fallback is
     extracting the files from the APK or downloading them from the GitHub
     release.
3. **Edit `rish`**: the script line that sets the app id to the `PKG`
   placeholder must point to your terminal app. The shipped script guards the
   export, so **only the placeholder value changes**:
   ```
   [ -z "$RISH_APPLICATION_ID" ] && export RISH_APPLICATION_ID="PKG"
   ```
   The tutorial's concrete example is **Termux / `com.termux`**. Either edit
   that value (`sed -i 's/PKG/com.termux/' rish`), or skip the edit and export
   the variable before each use — the guard leaves an already-set value alone:
   ```
   export RISH_APPLICATION_ID=com.termux
   ```
   Exporting is the tidier approach when you update the Shizuku app and
   re-export the files.
4. **Move the files** to a directory the terminal app can access, **grant
   execute** on `rish`, and add the directory to `PATH`.

## Termux placement

A concrete Termux recipe (`~/rish` is one example location consistent with the
tutorial's guidance — put the files somewhere the terminal app can reach,
ideally in its app-private tree):

```
mkdir -p ~/rish
mv rish rish_shizuku.dex ~/rish/
chmod +x ~/rish/rish
PATH="$HOME/rish:$PATH"
export PATH
```

- Putting rish under `$HOME` (inside `/data/data/com.termux/files/home`) keeps
  it in Termux's **app-private** tree — important on Android 14+ (below).
- **Do not place the files under `~/storage` for everyday use**: shared storage
  is `noexec` for Termux (scripts there cannot execute directly — see
  [Storage Setup](../01-termux/04-storage-setup.md)) and, on Android 14+, a
  writable dex anywhere breaks the loader.

## Android 14+ writable-dex rule [version-sensitive]

- On Android 14+, `app_process` will **not load a writable dex**.
- The `rish` script handles this: it runs `chmod 400 rish_shizuku.dex`; if the
  file is still writable (e.g. on `/sdcard`), it prints guidance — put the
  files in the terminal app's private directory (`/data/data/<package>`), where
  removing write permission is possible — and exits 1.
- Shizuku v13.5.2 release note states the same: "On Android 14+ ... place rish
  files in /sdcard will not work, users need to copy rish files to terminal
  apps' data folder."
- In Termux, `~/rish` (or any `$HOME` directory) satisfies this.

## Verifying the setup

```
rish -c 'id'
```

Expected: it prints the daemon identity (e.g. `uid=2000(shell)` when started
under ADB, or `uid=0(root)` when started with root). If it fails, the common
causes are in
[Limitations and Troubleshooting](05-limitations-and-troubleshooting.md).

## References

- Shizuku manager `manager/src/main/assets/rish` (the shipped script);
  tutorial sources `ShellTutorialActivity.kt`, `strings.xml`.
- Shizuku-API rish README (files and backends).
- Phase 5 research notes: `research/rish/00-rish-research.md` (§4, §9),
  `research/shizuku/00-shizuku-research.md` (§7).