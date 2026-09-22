# Activity Manager (`am`)

`am` talks to the **Activity Manager**, the Android system service that starts
activities, services, and broadcasts, and controls running app processes. It
is the tool for "make this app do something" from the command line.

On recent Android, `am` is a thin script that delegates to `cmd activity` —
**except** `am instrument`, which execs `app_process` with `am.jar` directly.
See [The `cmd` Dispatcher](04-command-dispatcher.md).

## Basic usage

```
adb shell am <command> [options]
adb shell am start -a android.intent.action.VIEW -d https://example.com
adb shell am force-stop com.example.app
```

- `start` starts an activity; `force-stop` stops an app's processes.
- `am` must be run **on the device** (usually through
  [ADB shell](../04-adb/04-adb-shell.md)); it is not a Termux tool, and inside
  Termux there is no `am` unless you add the `termux-am` package's `am`
  wrapper (see [Termux Utilities](../01-termux/06-utilities.md)).

## Documented `am` command set

The following table is from the official adb page's Activity Manager table and
is **[version-sensitive]** — new subcommands and options appear in newer
releases, and the entries marked below are recent additions:

| Command | Purpose |
|---------|---------|
| `am start [opts] <intent>` | start an activity |
| `am startservice [opts] <intent>` | start a service |
| `am broadcast <intent>` | send a broadcast |
| `am force-stop <package>` | stop every process of a package |
| `am kill [--user <id>] <package>` / `am kill-all` | kill background processes |
| `am instrument [-w] ...` | run instrumentation (tests) |
| `am profile start/stop <process> <file>` | start/stop profiling |
| `am dumpheap [-b] [-n] <process> <file>` | dump the heap; `-b` (bitmaps) is API 35+ |
| `am dumpbitmaps <process>` | dump allocations bitmap (API 36+) |
| `am set-debug-app` / `am clear-debug-app` | mark/clear an app to wait for a debugger |
| `am monitor [--gdb]` | monitor crashes / anr |
| `am display-size [reset\|WIDTHxHEIGHT]` | override/native display size |
| `am display-density <dpi>` | override display density |
| `am to-uri` / `am to-intent-uri` | print the intent as a URI |
| `am memory-limiter ...` | recent subcommands; Android 17+ ([version-sensitive]) |

- `am start` options include `-D` (debug), `-W` (wait), `-S`,
  `--start-profiler`, `-P`, `-R`, `--user <id>`, `--opengl-trace`, and (newer)
  `--debug-link`. **[version-sensitive]**

## Intent arguments

Intents are specified with the standard flag letters:

```
-a <action>       -d <data-uri>     -t <mime-type>     -c <category>
-n <component>    -f <flags>        --user <user-id>
```

plus typed extras:

```
-e / --es <key> <string>    --ez <key> <boolean>     --ei <key> <int>
--el <key> <long>           --ef <key> <float>       --eu <key> <uri>
--ecn <key> <component>     --eia <key> <int[]>      --grant-read-uri-permission ...
```

Example — start the browser view action on a URL:

```
adb shell am start -a android.intent.action.VIEW -d "https://example.com"
```

## Process control and caution

- `am force-stop <package>` and `am kill` terminate app processes. `force-stop`
  also prevents the app from being restarted by broadcasts until relaunched —
  it is the Android mechanism apps themselves use to "quit".
- `am instrument` runs test harnesses (`-w` waits for completion); this
  requires the target app to be instrumentable (debuggable/test APK).
- `am` operations are **not reversible by undoing a file** — an activity start
  or force-stop changes live device state. Only these commands are needed in
  normal workflows; treat the rest as developer tooling.

## Cross-references

- The dispatcher behind `am`: [The `cmd` Dispatcher](04-command-dispatcher.md)
- Installing the app you want to start: [Android Package Management](03-package-management.md)
- Inspecting activity/window state: [dumpsys](08-dumpsys.md)

## References

- Official adb page Activity Manager table (developer.android.com/tools/adb).
- AOSP `frameworks/base/cmds/am/am.sh` (current-main front-end).
- Phase 4 research notes: `research/adb/01-android-command-ecosystem-research.md` (§4).