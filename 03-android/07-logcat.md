# `logcat`

`logcat` reads Android's central log, collected by the `logd` daemon. It is
the first stop for diagnosing why something on the device failed, and it is a
pure device-side tool — there is no "android log" down in the Termux or proot
filesystem. The Termux `logcat` command is a `termux-tools` wrapper that
`exec`s the device's `/system/bin/logcat`
(see [Termux Utilities](../01-termux/06-utilities.md)).

## Basic usage

```
adb shell logcat                      # stream the log (default filters)
adb logcat                            # same thing from the computer's adb client
adb logcat -d                         # dump the log to screen and exit
adb logcat -s MyTag                   # show only MyTag messages
adb logcat -b crash                   # read the crash buffer
adb logcat -c                         # clear the log
adb logcat -g                         # print the size of each buffer
```

- `adb logcat` == `adb shell logcat`: the adb client forwards
  `adb shell logcat [<option>] ... [<filter-spec>]` to the device.
- `-d` dumps (prints everything buffered) then exits — useful for a
  point-in-time snapshot or for `grep`-ing a slice: `adb logcat -d | grep
  something`.
- Both streaming and `-d` print entries in chronological order. Streaming
  starts at the current tail of the log and keeps printing new entries as they
  arrive; `-d` prints everything buffered and then exits (handy for a
  point-in-time snapshot or a `grep` pipeline).

## Buffers (`-b`)

The daemon keeps several rotating in-memory buffers:

| Buffer | Contents |
|--------|----------|
| `main` | normal application logs |
| `system` | system/framework logs (historically separate) |
| `crash` | crash dumps for apps |
| `radio` | radio/telephony logs |
| `events` | binary event-log records |

- `-b main`, `-b system`, `-b crash`, `-b radio`, `-b events`. Multiple `-b`
  flags are supported on current Android (also comma-separated:
  `logcat -b main,radio,events`), but buffer availability and access can
  differ per Android version and per build; some buffers are restricted on
  user builds. **[version-sensitive]**
- Buffer sizes are version-dependent; use `-g`/`-g <buffer>` to see the
  current sizes instead of assuming a number. **[version-sensitive]**

## Filtering

Filter expressions are `TAG:PRIORITY` pairs. A `filter-spec` of
`tag:priority tag2:priority2` shows messages matching either rule; `TAG:*`
matches all priorities for that tag; `*:S` silences everything else (the
"allowlist" form).

```
adb logcat ActivityManager:I MyApp:D *:S   # runtime: allowlist example from the
                                           # official documentation
```

Priorities: `V` (Verbose), `D` (Debug), `I` (Info), `W` (Warning), `E`
(Error), `F` (Fatal), `S` (Silent).

- The `-s` option sets the default filter to **silent** (the equivalent of `*:S`
  in the filter-spec), so `logcat -s <tag>` shows only messages for that tag.
  The allowlist form in the examples works the same way with `*:S` written
  explicitly.
- Environment variable: `ANDROID_LOG_TAGS` sets default filter constraints
  when no filter is given.
- Runtime overrides: the `log.tag.*` system properties change priorities
  per-tag without restarting, e.g. `setprop log.tag.View VERBOSE`
  (see [Android Properties](02-android-properties.md)).

## Output format (`-v`)

```
adb logcat -v thread                # show thread, priority, and tags
adb logcat -v brief                 # one-line format (default on early versions)
```

Format keywords (from the official logcat and adb tool pages):

- `brief` — priority, tag, and PID of the process issuing the message.
- `long` — all metadata fields, separate messages with blank lines.
- `process` — PID only.
- `raw` — raw log message, no metadata fields.
- `tag` — priority and tag only.
- `thread` — legacy format; priority, PID, and TID.
- `threadtime` — **default** on Android; date, time, priority, tag, PID, and TID.
- `time` — date, time, priority, tag, and PID.

Modifiers: `color`, `descriptive`, `epoch`, `monotonic`, `printable`, `uid`,
`usec`, `UTC`, `year`, `zone` (Combine with `-v`, e.g. `-v threadtime,usec`;
modifiers are matched exactly, case-sensitively, so it is `usec`, not `useC`).

> **Note:** log output differs across Android versions — new `-v` modifiers,
> buffer rule changes, and format tweaks appear over time. Exact options for
> your version come from `adb logcat --help` (or `adb shell logcat --help`)
> on the device. **[version-sensitive]**

## Writing logs (app side)

Apps log with `android.util.Log` (tag limit historically 23 characters, a
normal runtime constraint), and log priority can be influenced with
`log.tag.*` properties. This Bible does not document app-side logging further;
`logcat` is the reading side.

## Cross-references

- Termux's own `logcat` wrapper and `which`/`type` details:
  [Termux Utilities](../01-termux/06-utilities.md)
- Log messages drive nothing in the shell, but heap/activity state reads come
  from: [dumpsys](08-dumpsys.md)
- Set property runtime log filters: [Android Properties](02-android-properties.md)

## References

- Official adb page: logcat section (man-form `[adb] shell logcat`).
- AOSP `system/logging/logcat/` — the `logcat`/`adb logcat` implementation.
- Phase 4 research notes: `research/adb/01-android-command-ecosystem-research.md` (§7).