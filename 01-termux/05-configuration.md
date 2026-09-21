# Configuration

Termux's shell/app behaviour is configured through one file:
`~/.termux/termux.properties` (that is, `$HOME/.termux/termux.properties`).

## The configuration file

- **Format:** Java `.properties` — `key=value` lines; `#` starts a comment;
  any line may be commented out.
- **Location:** `$HOME/.termux/termux.properties`.
- The shipped template has most properties commented out (safe to edit — just
  uncomment and set the value).

## Applying changes

- Run `termux-reload-settings` after editing, or fully restart the app.
- Some properties need a complete app-process restart to take effect (the
  reload command handles most; if a change does not apply, restart Termux).
- `termux-reload-settings` is part of `termux-tools` (always installed).

## Properties

The properties below are documented in the current template/development

source. **Version-sensitive:** keys and defaults change across app versions —
check `termux-info`/your installed template for the definitive list.

| Property | What it does |
|----------|--------------|
| `allow-external-apps` | Allow external apps to run commands in Termux |
| `default-working-directory` | Working directory for new sessions |
| `disable-terminal-session-change-toast` | Hide the toast shown on session switch |
| `hide-soft-keyboard-on-startup` | Do not show the soft keyboard at startup |
| `soft-keyboard-toggle-behaviour` | Toggle shortcut behaviour for soft keyboard |
| `terminal-transcript-rows` | Scrollback buffer rows (max 50000) |
| `volume-keys` | Control mapping of the volume keys |
| `fullscreen` | Start full screen |
| `use-fullscreen-workaround` | Fullscreen workaround for some devices/ROMs |
| `terminal-cursor-blink-rate` | Cursor blink interval |
| `terminal-cursor-style` | Cursor style (e.g. block/underline/bar) |
| `extra-keys-style` | Style of the extra (function) keys row |
| `extra-keys-text-all-caps` | Render extra keys all-caps |
| `extra-keys` | Customise extra keys, including popup/macro syntax |
| `use-black-ui` | Black UI background |
| `disable-hardware-keyboard-shortcuts` | Turn off hardware keyboard shortcuts |
| `shortcut.create-session` | Keyboard shortcut to create a session |
| `shortcut.next-session` | Keyboard shortcut to switch to next session |
| `shortcut.previous-session` | Keyboard shortcut to switch to previous session |
| `shortcut.rename-session` | Keyboard shortcut to rename the session |
| `bell-character` | Terminal bell action (`vibrate`, `beep`, or `ignore`) |
| `back-key` | Back-key behaviour (`back` or `escape`) |
| `enforce-char-based-input` | Force character-based input handling |
| `ctrl-space-workaround` | Ctrl+Space workaround on some keyboards |
| `terminal-margin-horizontal` | Horizontal terminal margin |
| `terminal-margin-vertical` | Vertical terminal margin |

### Session shortcuts

Session behaviour ties into
[Processes and Sessions](../00-foundations/06-processes-and-sessions.md).
Example values from the template use `ctrl + t` (create), `ctrl + 2` (next),
`ctrl + 1` (previous), `ctrl + n` (rename). Interpret them per your install's
`extra-keys`/keyboard handling.

## Colours and fonts

Colour schemes and fonts are normally managed by the **Termux:Styling** add-on
(see [Add-ons](07-add-ons.md)). The traditional files are
`~/.termux/colors.properties` and `~/.termux/font.ttf`. Prefer the add-on for
switching; restarts or `termux-reload-settings` apply changes.

## Example

```properties
# ~/.termux/termux.properties
terminal-transcript-rows = 10000
volume-keys = volume
bell-character = ignore
shortcut.create-session = ctrl + t
```

Then run `termux-reload-settings`.

## References

- templated `termux.properties` in termux-tools
  (`https://github.com/termux/termux-tools`).
- Termux wiki "Terminal settings" pages.
- Research notes §3.9, §3.10 and §5: `research/termux/00-foundations-research.md`.