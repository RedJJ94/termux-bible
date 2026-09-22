# File Transfer

Moving files between host and device:

```
adb push <local> <remote>     # copy FROM host TO device
adb pull <remote> <local>     # copy FROM device TO host
adb forward <hostport> <deviceport>   # tunnel a port host→device
```

## `adb push` / `adb pull`

- Work on **arbitrary files and directories** (the official docs give
  `adb push foo.txt /sdcard/foo.txt` and `adb pull /sdcard/foo.txt`).
- This is different from `adb install`, which treats the file as an APK and
  installs it without you choosing a path — see
  [Android Package Management](../03-android/03-package-management.md).
- Both host and device paths support relative paths against their **own**
  current directory, so a command's meaning can differ depending on where the
  host shell is:

```
adb push ./build/app.apk /sdcard/        # host cwd is host; /sdcard is device
adb pull /sdcard/file.txt .              # '.' is the host cwd
```

## Where files can (and cannot) go

The shell user (uid 2000) can write:

- **Shared/external storage** (`/sdcard`, real path typically
  `/storage/emulated/0`), which is what push/pull targets in everyday use.
- **`/data/local/tmp`** — the shell's writable temp directory and the natural
  scratch space for the ADB shell.

Restricted paths:

- **App-private storage** under `/data/data/<package>` is generally **not**
  writable/readable by push/pull from the shell for non-debuggable apps. This
  is a property of the Android data model (app sandboxes), not of adb.
  **[DEVICE] — verify on the target device/version before relying on any
  specific exception]**
- Files like the ART profile dump `/data/misc/profman/...` need **root
  filesystem access** (the official docs flag this; usually only on
  debuggable/root contexts).

When a transfer is refused, re-read who you are (see
[ADB Shell](04-adb-shell.md)): the shell user is neither the app nor root.

## `adb forward` (port tunneling)

`adb forward` binds a port on the **host** to a port on the **device**:

```
adb forward tcp:6100 tcp:7100     # host:6100 → device:7100
```

- Useful to reach services the device listens on (e.g. a local web server in
  Termux, a debugging port in an app) so the host can use `localhost:6100`.
- The device-side endpoint can be a named **local** socket rather than a TCP
  port. The official docs give the `logd` socket as the example:

  ```
  adb forward tcp:6100 local:logd    # host tcp:6100 → device local socket 'logd'
  ```

  Data sent there is written to the system logging daemon and appears in the
  device logs — useful for seeing what an app sends to a given port. Mapping
  forms are version-dependent. **[version-sensitive]**

## Raw transfer with `exec-out` / binary safety

For byte-exact output (screenshots, media, dumps): `adb exec-out` writes the
command's raw stdout without the text handling `adb shell` applies:

```
adb exec-out screencap -p > screen.png
```

Full capture recipes: [Capture Workflows](06-capture-workflows.md).

## Transfer-speed notes

- Burst mode (experimental, adb 36+): `ADB_BURST_MODE=1` enables pipelined
  transfers; disabled by default (see [ADB Basics](01-adb-basics.md)).
- The legacy `adb tcpip` transport has no confidentiality — see
  [Wireless Debugging](03-wireless-debugging.md) before transferring sensitive
  data (or anything at all) over it.

## Cross-references

- The device-side state you're pushing to: [ADB Shell](04-adb-shell.md)
- APK-specific transfer vs. install: [Android Package Management](../03-android/03-package-management.md)
- On-device storage layout: [Storage and Permissions](../00-foundations/04-storage-and-permissions.md)

## References

- Official adb reference: developer.android.com/tools/adb (`start-server`,
  `push`, `pull`, `forward`, `exec-out`).
- Phase 4 research notes: `research/adb/00-adb-research.md` (§10, §13),
  `research/adb/01-android-command-ecosystem-research.md` (§13).