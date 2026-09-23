# porsh — Command Line and Termux

`porsh` is Porter's own `rish`-equivalent: a thin client that talks to a
running Porter server and gives you a `/system/bin/sh` prompt **as the
server's uid** — **2000 (ADB shell)** or **0 (root)**. It exists because
the stock `rish` client is not compatible with Porter
([rish and porsh](07-rish-and-porsh.md)).

This chapter covers exporting the files, placing them in Termux, and the
environment handling you need to understand.

## Export the porsh files

Inside Porter (manager app):

- **Export porsh** creates and saves two files (with a save dialog; Android's
  scoped storage / SAF applies):
  - **`porsh.dex`** — the compiled shell client (the `eu.darken.porter.shell`
    module classes).
  - **`porsh`** — a shell script that runs the dex via `/system/bin/app_process`.
- The script sets per-uid file-grant flags, builds the parameter list
  (`--nice-name=porsh`, class `eu.darken.porter.shell.PorterShellLoader`,
  arguments suffix `--update=false`), and derives the manager package. Two
  substitutions happen at export time: the placeholder **`MANAGER_PKG`** is
  replaced with **`eu.darken.porter`**, and **`PKG`** stays a **literal
  placeholder** (each client fills in its own package name at runtime — the
  export is generic, not per-app).
- Exporting again overwrites the files; **after updating Porter, re-export**.
- Note on OEM software: on **MIUI (older versions)**, the SAF copy filter may
  "break the binary", so the tutorial suggests moving the files via a file
  manager instead of the save dialog. **[OEM] [needs verification]**

## Place the files and run

The generated script explains that, on **Android 14+**, a dex file in a
**non-app-specific** directory is not readable — you must put the two files in
an **app-private** directory and use `chmod 400`:

```
mv porsh porsh.dex ${FILES_DIR}
chmod 400 ${FILES_DIR}/porsh.dex
sh ${FILES_DIR}/porsh
```

Where `${FILES_DIR}` is something like `~/storage/...` in Termux, or better
an app-private path (e.g. `~/.porsh`). If you see a **"Could not read the
porsh.dex file"** error, that is the storage/directory problem above.

Even from Termux the shell session comes from the same machinery: the script
launches `/system/bin/app_process` with `porsh.dex` as its classpath and the
**PorterShellLoader** as the entry point. You get an interactive PTY terminal;
on the server side the native host fixes the shell's **`argv[0]` to
`/system/bin/sh`** and forwards the client's arguments to it verbatim. It is a
**pure terminal application**; it is not mirroring Termux's
`Environ.termuxExecEnviron` — it starts `/system/bin/sh` from the device with
the daemon's environ.[source-verified]

## Recommended Termux recipe

Requires: Porter started (wireless/computer/root — see
[Activation and Startup](04-activation-and-startup.md)) and the two exported
files reachable by Termux (Termux storage setup:
[Termux Setup](../01-termux/04-storage-setup.md)).

```
mkdir -p ~/.porsh
mv ~/storage/downloads/porsh ~/.porsh/porsh
mv ~/storage/downloads/porsh.dex ~/.porsh/porsh.dex
chmod 400 ~/.porsh/porsh.dex
chmod +x ~/.porsh/porsh
~/.porsh/porsh
```

At the prompt, verify who you are:

```
id
```

- Started via **wireless/computer**: `uid=2000(shell)` — the adb `shell`
  identity.
- Started via **root**: `uid=0(root)`.

The very first command triggers the app's **permission request** (see
[Permissions and Identities](05-permissions-and-identities.md)). Deny it
permanently and the server responds with **"Permission denied"**; there is no
second chance until you lift the stored denial in **Porter → Applications**
(see [Troubleshooting](10-limitations-and-troubleshooting.md)).

## One-shot commands

As with rish, you can pass a command directly. `porsh -c 'id'` appends
`-c id` as the arguments to `/system/bin/sh` (the arguments are passed to the
loader, which runs `sh` with them):

```
porsh -c 'id'
porsh -c 'getprop ro.build.version.release; id'
```

Everything that follows `porsh -c` is `sh` code, not porsh flags — the client
takes the remaining arguments verbatim as the shell command line.

## Environment handling (important)

The environment you get in porsh is **not** Termux's environment. By default
the server drops the client's environment when running as uid 2000, and keeps
it when running as uid 0 (for the complete rule and the `1`/`0` toggles, see
[Environment filtering in rish and porsh](07-rish-and-porsh.md)). With an
ADB-started server, to make Termux's exported variables available inside the
porsh shell:

```
export PORSH_PRESERVE_ENV=1
~/.porsh/porsh
```

Then `echo "$HOME"` reflects Termux values rather than the daemon's minimal
set. Toggling the variables off returns to the default filtering.

## Security warnings

- A porsh session **is the server's identity**: everything you type runs with
  uid 2000 or root. A root porsh is equivalent to an interactive root shell.
- The exported script is meant to be readable; **do not put `porsh.dex` in
  world-readable paths on Android 14+** (and in general keep the files in your
  own private directory).
- Approving the permission request grants **Porter the runtime permission for
  this client package** (see [Permissions and Identities](05-permissions-and-identities.md)).

## References

- Official docs: `porter.darken.eu/docs/sc/` (porsh / shell export).
- Phase 6 research notes: `research/porter/00-porter-research.md` (§6.1–§6.4,
  §11.2).