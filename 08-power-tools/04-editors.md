# Editors

All of the major terminal editors are available as Termux packages. They behave
like their desktop counterparts; the only Termux-specific facts are where their
configuration resolves (`$HOME` is the Termux data home) and that some
color/fullscreen features depend on the terminal emulator.

| Editor | Version (2026-09-22) | Termux packaging facts | Config location |
|--------|----------------------|------------------------|-----------------|
| `vim` | 9.2.1100 | DEPENDS `libiconv, libsodium, ncurses`; RECOMMENDS `diffutils, xxd`; SUGGESTS `luajit, perl, python, ruby, tcl`; PROVIDES `vim-python`; CONFLICTS `vim-gtk` | `~/.vimrc` |
| `neovim` | 0.12.5-1 | uses `lua` internally | `~/.config/nvim` |
| `emacs` | 31.1-3 | | `~/.emacs.d/` |
| `nano` | 9.2-1 | lightweight; good default for beginners | `~/.nanorc` |
| `micro` | 2.0.15-2 | single-binary editor | `~/.config/micro` |
| `helix` | 25.07.1-2 | modal editor written in Rust | `~/.config/helix` |

Versions and dependency lines are **[version-sensitive]**; they were verified
against the 2026-09-22 `termux-main` aarch64 index.

## Install

```sh
pkg install vim          # or: neovim, emacs, nano, micro, helix
```

- Only one editor is strictly needed to make Git happy after install; see
  [The Git editor and pager](../11-git-github/01-git-installation-and-setup.md)
  — the Termux `git` package is compiled to fall back to commands named
  `editor`/`pager` that no package ships, so set `core.editor` explicitly.
- All six editors work in a normal Termux terminal session and over SSH; there
  is no GUI component involved.

## Practical notes

- **`nano`** is the least intimidating starting point:
  `nano file.txt`, `^O` save, `^X` exit; `~/.nanorc` for preferences.
- **`vim`** and **`neovim`** are the mainstream full editors; both are
  terminal-native and have `vimtutor`-style help (`vim` ships tutorial
  material; `:help` inside either). Termux's Android keyboard works, but many
  users enable a hardware keyboard or the Termux app's built-in extra-keys row
  for comfort.
- **`micro`** is a single binary with familiar key bindings (Ctrl-S / Ctrl-Q)
  and a menu; config in `~/.config/micro`.
- **`helix`** is a modal editor in the spirit of vim with built-in LSP
  integration; config in `~/.config/helix`.
- **`emacs`** runs fully in the terminal on Termux; config in `~/.emacs.d/`.
- XDG config dirs (`~/.config/...`) resolve **inside the Termux data home**
  (`/data/data/com.termux/files/home`), not `/root` or `/storage`. Back up
  these directories with the rest of your Termux home
  ([Backup, Restore, and Reset](../01-termux/08-backup-restore-reset.md)).

## Environment and terminal behavior

- `$TERM` is set by the Termux app in a normal session. Color/fullscreen
  rendering of the editors depends on the terminal emulator and its settings
  **[DEVICE]**. `bat`/`fzf`-style color output (see
  [Networking and Developer Utilities](11-networking-and-developer-utilities.md))
  has the same requirement.
- Over SSH from a computer, the editors render according to *that* terminal;
  `TERM` there is whatever your SSH client sets.

## Native Termux vs. proot

Inside proot-distro, install the distro's editor packages (`apt install vim`
in a Debian/Ubuntu guest). Config paths then live inside the guest filesystem
and do not affect the Termux-native editors.

## Cross-references

- Making Git use an editor: [Git Installation and Setup](../11-git-github/01-git-installation-and-setup.md)
- Viewing files without an editor: [Viewing and Editing Files](../02-shell/02-viewing-and-editing-files.md)
- Where `$HOME` resolves: [The Filesystem](../00-foundations/03-filesystem.md)
- Color-dependent terminal tools: [Networking and Developer Utilities](11-networking-and-developer-utilities.md)

## References

- Phase 7 research notes §7:
  `research/development/03-build-dev-tools-editors-databases-research.md`.
- Versions verified against the `termux-main` (aarch64) index, fetched
  2026-09-22.