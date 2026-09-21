# Pipes, Redirection, and Shell Built-ins

Everything that makes the command-line tools composable — pipelines,
redirection, command substitution, and the built-in commands that run inside
the shell process itself. This chapter is the practical companion to
[Shell and Environment](../00-foundations/05-shell-and-environment.md); it
assumes bash (the default interactive shell in Termux).

Key Termux-specific facts used throughout:

- `sh` is **not** bash — it is `dash`. `#!/bin/sh` scripts run under dash.
- The shipped `~/.bashrc`/`bash.bashrc` set `HISTCONTROL`, `PROMPT_DIRTRIM`,
  `PS1`, a command-not-found handler, and source bash-completion. They do
  **not** set a coloured `ls` alias or a restrictive `umask` (the shipped
  default is `0022`).
- Process substitution (`<( )`) works in bash 5.3 on Termux (Termux builds
  bash with `/dev/fd` support enabled). [version-sensitive]
- `$PREFIX/bin/env` and the `#!/data/data/com.termux/files/usr/bin/env`
  shebang are used by all Termux Python/perl/node scripts.

## Pipelines

```sh
cmd1 | cmd2 | cmd3        # stdout of cmd1 -> stdin of cmd2 -> ...
grep error app.log | head -n 20
ps aux | grep ssh         # (prefer pgrep in scripts — see Processes)
tar -cf - dir/ | xz -9 > dir.tar.xz
```

- The pipeline exits with the **last** command's status (`PIPESTATUS` array
  holds each stage's status in bash).
- A pipeline runs each stage in its own subshell by default (variables set in
  a later stage do not reach the parent).

## Redirection

```sh
cmd > file          # stdout -> file (overwrites)
cmd >> file         # stdout -> file (appends)
cmd 2> err.log      # stderr -> file
cmd > out.log 2>&1  # stdout and stderr -> file (order matters)
cmd &> all.log      # bash shorthand for both
cmd < input.txt     # stdin from file
cmd2 |& grep err    # pipe both stdout and stderr (bash 4+)
```

- **Order matters:** `cmd 2>&1 > file` redirects stderr to the *current*
  stdout (the terminal) then stdout to `file` — the classic footgun.
  `cmd > file 2>&1` is the safe order.
- `/dev/null`:
  `cmd > /dev/null 2>&1` discards all output.
- Heredoc and here-string:

```sh
cat <<EOF > config.txt
key=value
EOF

grep foo <<< "test foo bar"        # here-string feeds one line
```

- `<<EOF` is the heredoc (until a line exactly `EOF`); `<<-EOF` strips
  leading tabs; `<<<` is a here-string. Expanding variables inside heredocs
  uses the same `$var` rules as double quotes.

## Command substitution

```sh
today=$(date +%F)            # capture stdout as a string
files=$(ls | wc -l)
echo "I have $(ls | wc -l) files"
```

- `$(...)` is the modern form; backticks `` `...` `` are legacy — prefer
  `$(...)` (nesting and quoting are saner).
- Works inside double quotes, so the result is word-split and glob-expanded
  unless you quote the use or use arrays (`mapfile`/`readarray`) when you
  need exact lines.

## Process substitution

```sh
diff <(sort a.txt) <(sort b.txt)    # diff the sorted versions without temp files
comm -12 <(sort setA) <(sort setB)
```

- Feeds a command's output as a "file" to another command.
- Works because Termux's bash is built so that `/dev/fd` is available
  (`bash_cv_dev_fd=whacky`). [version-sensitive: needs the Termux bash build]

## Globbing and quoting

```sh
*.txt         # glob: matches filenames
?             # one character
[abc]         # character class
~             # home directory
"$HOME"       # double quotes: no word-splitting, allows $ expansion
'$HOME'       # single quotes: literal
```

- Bash does not word-split the result of *globs* by default; quoted
  variables (`"$var"`) are the safest pattern. See
  [Shell and Environment](../00-foundations/05-shell-and-environment.md).

## Exit status

```sh
cmd; echo $?          # 0 = success, non-zero = failure
```

- `&&` runs next only on success; `||` on failure:
  `mkdir -p out && cp file out/ || echo "failed"`.
- A command that ran but returned non-zero (e.g. `grep` with no match)
  is treated as failure in `&&`/`||` chains — use `|| true` or `set +e` where
  intentional.

## Built-ins

Verify provenance with `type -a`:

```sh
type -a echo        # echo is a bash builtin (coreutils echo is also on PATH)
type -a kill        # bash kill builtin, and coreutils kill
type -a pwd         # bash builtin and coreutils
```

| Built-in | Purpose |
|----------|---------|
| `cd`, `pwd`, `dirs`/`pushd`/`popd` | directory navigation (see Filesystem) |
| `echo`, `printf` | output |
| `test` / `[` | conditionals (`[ -f file ]`) |
| `kill`, `jobs`, `fg`, `bg`, `wait` | job control (see Processes) |
| `read`, `mapfile`/`readarray` | read stdin into variables/arrays |
| `export`, `source`/`.`, `alias`, `unset`, `set`, `shift`, `local` | shell state |
| `trap`, `exec`, `return`, `exit` | control flow |
| `umask`, `ulimit` | process attributes (see Permissions) |
| `type`, `command`, `hash` | find how a command resolves (`which` is an external, optional) |

Common built-in usage:

```sh
echo "hello"                # prints with trailing newline
printf '%s-%s\n' a b        # formatted output, no weird escaping
[ -f "$HOME/.bashrc" ] && echo "bashrc exists"
command -v pkg              # prints path if pkg is on PATH
read -p "name: " name       # prompt and read a line
mapfile -t lines < file.txt # read file lines into $lines array
trap 'echo interrupted' INT # handle Ctrl-C
exec bash                   # replace the current shell with a new bash
```

- `echo` vs `printf`: `printf` is the reliable, portable choice; `echo`
  behaviour varies (with/without `-e`/`-n`).

### `fc` / history

- `fc -l` lists history; `fc -s pattern` re-runs a matching command; `!!`,
  `!$`, `!string` are history expansion (on by default interactively).

## `sh` vs `bash` vs `dash`

- `$PREFIX/bin/sh` is a symlink to **dash** in the Termux bootstrap.
  `#!/bin/sh` scripts get dash semantics (POSIX only — no arrays, no
  `[[ ... ]]`), so an interactive bash user writing scripts must remember
  the shebang defines the grammar. See
  [Shell and Environment](../00-foundations/05-shell-and-environment.md).
- Two common shebang choices for your own scripts:
  `#!/data/data/com.termux/files/usr/bin/bash` is the explicit, absolute
  Termux path; `#!/usr/bin/env bash` is portable across environments but
  resolves to the *first* `bash` in `$PATH`.

## Shebang and `termux-exec`

`termux-exec` is installed by default and preloaded via `LD_PRELOAD` into
Termux programs; it hooks `exec` to make `/bin/sh`-style shebangs work and to
handle the app-sandbox execute (W^X) restrictions on app data. `termux-fix-shebang`
(also installed) rewrites shebangs in a file explicitly. See
[Termux Utilities](../01-termux/06-utilities.md). For your own scripts the
reliable choice is the real Termux interpreter path:

```sh
#!/data/data/com.termux/files/usr/bin/bash
```

## Working with `/dev/null`, `/dev/fd`, and `/proc`-ish files

- `/dev/null`, `/dev/fd/N`, and a few others are the only "virtual" devices
  normally available; the rest of `/dev` is shallow on unrooted Android.
- `/proc`/`/sys` are mostly unreadable without root; the procps tools instead
  read mock statistics (see [Processes and Job Control](04-processes-and-jobs.md)).

## Native Termux vs. proot

Everything in this chapter (bash built-ins, pipelines, redirection,
substitution) behaves identically inside a proot guest — shells come from the
guest, so `sh` is the guest's dash (or the guest's own config), paths in
`$PREFIX` do not exist in the guest, and `#!` lines must point at guest
interpreters. See [Android Sandboxing and Execution Environments](../00-foundations/02-android-sandboxing.md).

## Cross-references

- Finding where commands come from: [section introduction](00-intro.md)
- Text processing pipelines: [Text Processing and Searching](03-text-processing-and-searching.md)
- Job control built-ins: [Processes and Job Control](04-processes-and-jobs.md)
- Writing scripts: [Shell and Environment](../00-foundations/05-shell-and-environment.md)

## References

- Phase 3 research notes §4.9 (pipelines/redirection/built-ins), §5.4–5.6
  (bash/dash/env), §14 (audit log):
  `research/commands/00-shell-command-bible-research.md`.
- Bash manual: <https://www.gnu.org/software/bash/manual/>