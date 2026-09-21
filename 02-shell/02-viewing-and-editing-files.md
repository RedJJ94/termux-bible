# Viewing and Editing Files

Reading and modifying files is the next most common shell task. This chapter
covers pagers, plain-output tools, and editors that exist in a fresh install,
plus the common `vim`. It assumes native Termux; file operations differ from
the shared-storage-fat caveats in
[Filesystem and Navigation](01-filesystem-and-navigation.md).

In a fresh install available immediately: `cat`, `less`, `head`, `tail`,
`nano`, `ed`, `od`, `hexdump`, `more`. `vim` and `file` require a
`pkg install` (see the install table in the
[section introduction](00-intro.md)).

## `cat` — concatenate and print

`cat` is GNU coreutils.

```sh
cat file.txt          # print the file to the terminal
cat a.txt b.txt       # print both, in order
cat > new.txt         # type input, Ctrl-D ends (overwrites!)
cat >> log.txt        # append input instead
cat -n file.txt       # number the lines
cat -s file.txt       # squeeze repeated blank lines
```

> **Warning:** `cat > file` **overwrites** the file immediately. Use `cat >> file` to append.

`cat` alone with a large file dumps the whole output to the screen;
use `less` for paging.

## `less` — pager

`less` is the standard pager (in the fresh install).

```sh
less bigfile.log      # open and page
ls -lR $HOME | less   # page through another command's output
```

Navigation inside `less`:

| Key | Action |
|-----|--------|
| `Space` / `f` | next page |
| `b` | previous page |
| `g` / `G` | first / last line |
| `/pattern` | forward search |
| `?pattern` | backward search |
| `q` | quit |

- `less` is compiled with terminal interaction support for Termux; on a soft
  keyboard emulator you may need to scroll rather than page.
- For paging compressed files, see
  [Archives and Compression](06-archives-and-compression.md) (gunzip/zcat
  first, or pipe through `gunzip`).

`more` (util-linux, in the fresh install) is a simpler pager; `less` is the
better default for interactive use.

## `head` / `tail` — first / last lines

```sh
head -n 5 file.log       # first 5 lines
tail -n 5 file.log       # last 5 lines
tail -f file.log         # follow (watch appended output) live
tail -F file.log         # follow across log rotation
```

- `-f`/`-F` are the usual way to watch a growing log; Ctrl-C to stop.
- Also useful combined with pipelines, e.g. `grep foo | tail -n 10`.

## `nano` — the default interactive editor

`nano` is **in the fresh install**. Modern GNU nano shows its key hints at the
bottom of the screen; the essentials do not change:

| Key | Action |
|-----|--------|
| `Ctrl+O` | write/save (prompts for filename) |
| `Ctrl+X` | exit (prompts to save if modified) |
| `Ctrl+G` | help |
| `Ctrl+W` | search |
| `Ctrl+K` / `Ctrl+U` | kill/cut line / uncut paste |

```sh
nano ~/.bashrc            # open (create if missing) for editing
nano +12 file.txt        # start at line 12
```

Nano is the recommended first editor on Termux because it needs no extra
setup and no separate install.

## `vim` — powerful editor (install)

`vim` is **not** in the fresh install.

```sh
pkg install vim
vim file.txt
```

- Start in normal mode; `i` enters insert mode, `Esc` returns to normal mode,
  `:w` saves, `:q` quits, `:wq` saves and quits, `:q!` quits discarding
  changes.
- Configuration lives in `~/.vimrc`; a minimal one is created on first run.
- There is **no separate "vim-python" package** in the Termux repo; the
  `vim` package is the main build. `neovim` and `emacs` are separate packages.

For terminal editing, a Vim-style choice in Termux is `nano` (default), `vim`,
or `neovim`.

## `ed` — line-oriented editor

`ed` is the standard line editor and is part of the fresh install. It is
useful for scripted edits but awkward interactively:

```sh
ed file.txt
# prints line count of the file
1           # print line 1
s/foo/bar/  # substitute on the current line
w           # write
q           # quit
```

## `od` / `hexdump` — view binary data

```sh
od -c file.bin        # show bytes as escaped characters
od -An -t x1 file     # hex without a left address column
hexdump -C file.bin   # canonical hex+ASCII view (util-linux)
```

- `od` is GNU coreutils; `hexdump` is util-linux with a canonical hex+ASCII
  view. Both are in the fresh install.

## `patch` — apply diffs

`patch` is in the fresh install; it applies `diff`-produced patches:

```sh
patch -p1 < changes.patch     # from the top of the source tree
patch -p0 < changes.patch     # when the patch includes paths relative to cwd
```

A `.patch`/`.diff` file is text; view it before applying
(`head`/`less`/`cat` work).

## Native Termux vs. proot

Inside proot-distro (Ubuntu etc.), `less`, `nano`, `vim` come from that
distro's packages and may differ in defaults; `ed` may not be installed by
default. The nano config location also differs (`/etc/nanorc` in the guest vs
`$PREFIX/etc/nanorc` in native Termux).

## Cross-references

- Command existence/provenance: [section introduction](00-intro.md)
- Text tools for transforming file content:
  [Text Processing and Searching](03-text-processing-and-searching.md)
- Editing across the filesystem; shared storage caveats:
  [Filesystem and Navigation](01-filesystem-and-navigation.md)

## References

- Phase 3 research notes §4.2 (viewing/editing),
  §7 (version-sensitive), §8 (install list):
  `research/commands/00-shell-command-bible-research.md`.
- GNU coreutils manual (cat, head, tail, od):
  <https://www.gnu.org/software/coreutils/manual/>