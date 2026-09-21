# Text Processing and Searching

Shell workflow leans heavily on text tools. This chapter covers the GNU tools
that are in a fresh install (`grep`, `sed`, `awk`/`gawk`, `cut`, `sort`,
`uniq`, `tr`, `wc`, `diff`, `dos2unix`), plus frequently-installed
alternatives (`jq`, `ripgrep`, `bat`, `fd`, `fzf`).

All commands in the "in fresh install" group work on native Termux and behave
like their GNU counterparts; the key Termux-specific differences are noted.

## `grep` — search text

`grep` is GNU grep 3.12 (in the fresh install), built with PCRE2 support.

```sh
grep foo file.txt             # lines containing 'foo'
grep -i foo file.txt          # case-insensitive
grep -r foo src/              # recursive into directories
grep -v foo file.txt          # invert: lines NOT matching
grep -l foo *.txt             # print filenames only
grep -c foo file.txt          # count matching lines
grep -n foo file.txt          # show line numbers
grep -P '\d{4}-\d{2}-\d{2}' file.txt   # PCRE2 (Perl-compatible) regex
grep -E 'foo|bar' file.txt    # extended regex (alternation)
```

- `grep` in a pipeline is the standard way to filter command output:
  `ps aux | grep termux` (but see [Processes and Job Control](04-processes-and-jobs.md)
  for why `pgrep` is preferable in scripts).
- `-P` uses the PCRE2 library — useful for `\d`, `\s`, lookahead etc.

## `sed` — stream editor / in-place edit

`sed` is GNU sed (in the fresh install).

```sh
sed 's/foo/bar/' file.txt      # print with first 'foo' per line replaced
sed 's/foo/bar/g' file.txt     # replace every occurrence per line
sed -n '10,20p' file.txt       # print lines 10-20 only
sed -i 's/foo/bar/g' file.txt  # edit file in place (modifies file!)
sed -i.bak 's/foo/bar/' f.txt  # keep a backup f.txt.bak
```

> **Warning:** `sed -i` modifies the file with no undo. Keep `-i.bak` or run
> without `-i` first to review the output.

`sed -i` on shared storage is fine for content (unlike permission/ownership
writes), since a rewrite is just a normal write.

## `awk` — field/text processing

`awk` is **gawk** (GNU awk) in Termux; the `awk` name is a symlink to gawk
(in the fresh install). Notable GNU/gawk extensions available include
`match()`, `gensub()`, and `strftime()`.

```sh
awk '{print $1}' file.txt         # first whitespace-separated field
awk '{print $NF}' file.txt        # last field
echo 'one:two:three' | awk -F: '{print $2}'   # split on ':'
awk '$1 > 100 {print $2}' data    # numeric filter
ps aux | awk '/termux/ {print $2}'   # classic pipeline usage
```

- `-F` sets the field separator; `-v var=val` passes a shell variable.
- Default field separator is whitespace.

## `cut` / `sort` / `uniq` / `tr` / `wc` — core text utilities

All GNU coreutils (in the fresh install).

```sh
echo 'a:b:c:d' | cut -d: -f2       # fields split by ':' (prints 'b')
echo 'hello world' | cut -c1-5     # characters 1..5
sort file.txt                      # lexicographic
sort -n file.txt                   # numeric
sort -rn file.txt                  # numeric descending
sort -u file.txt                   # sort and deduplicate
uniq file.txt                      # collapse adjacent duplicates
uniq -c file.txt                   # prefix with occurrence counts
tr 'a-z' 'A-Z' < file.txt          # lowercase -> uppercase
tr -d '\r' < windows.txt > unix.txt  # strip CR (DOS line endings)
wc file.txt                        # lines words bytes
wc -l file.txt                     # lines only
wc -c -m file.txt                  # bytes and characters
```

- `sort | uniq -c | sort -rn` is the classic "histogram by frequency":
  `cut -d' ' -f1 log.txt | sort | uniq -c | sort -rn`.
- `tr` operates on stdin/stdout; it cannot edit files in place.

Other coreutils text utilities, all in a fresh install:

```sh
nl file.txt             # number the lines (like cat -n)
paste a.txt b.txt       # join files side by side, by line
comm a.txt b.txt        # lines unique to A (-1), B (-2), or shared (-3)
join k.txt p.txt        # relational join on a common first field
expand file.txt         # expand tabs to spaces (unexpand reverses)
fold -w 40 file.txt     # wrap lines at 40 columns
```

## `dos2unix` / `unix2dos` — line-ending conversion

`dos2unix` is in the fresh install (with `unix2dos`, `dos2unix`'s aliases for
converting back):

```sh
dos2unix file.txt         # convert CRLF -> LF in place
dos2unix -n in.txt out.txt  # write to a new file, leaving in.txt
unix2dos file.txt         # LF -> CRLF (Windows line endings)
```

This prevents the classic `^M` at line ends when editing files shared with
Windows tools.

## `diff` / `cmp` — compare files

`diff` and `cmp` are from diffutils (in the fresh install).

```sh
diff -u old.txt new.txt     # unified diff (readable, patchable)
diff -r dirA dirB           # compare directory trees
cmp a b                     # report first difference byte
```

Unified diff output can be fed to `patch`
([Viewing and Editing Files](02-viewing-and-editing-files.md)).

## `jq` — JSON processing (install)

`jq` is **not** in the fresh install.

```sh
pkg install jq
curl -s https://api.github.com/repos/termux/termux-packages | jq '.stargazers_count'
echo '{"a":{"b":1}}' | jq .a.b
```

`jq` handles the JSON that `curl`-driven APIs return; structured output also
comes via `python` or `node`, but `jq` is the lightest-dependency choice.

## Modern replacements (install)

These are common quality-of-life tools that are **not** in the fresh install:

| Package | Tool | Purpose |
|---------|------|---------|
| `ripgrep` | `rg` | fast recursive grep; gitignore-aware |
| `bat` | `bat` | `cat` with syntax highlighting and paging |
| `fd` | `fd` | simpler/faster `find` replacement |
| `fzf` | `fzf` | fuzzy finder, works great with pipelines |

```sh
pkg install ripgrep fzf
rg 'error' src/ 
fzf                      # fuzzy-select from stdin or the current dir
```

## Native Termux vs. proot

In a proot-distro Ubuntu environment the same GNU tools are present, but
`grep` there may lack `-P` (no PCRE2 build) unless `grep-pcre` is installed in
that distro. `awk` may be `mawk` instead of `gawk` (mawk lacks some gawk
extensions). Check `grep --version` and `awk --version` in the guest if a
feature behaves differently.

## Cross-references

- Viewing raw file content: [Viewing and Editing Files](02-viewing-and-editing-files.md)
- Piping between commands: [Pipes, Redirection, and Shell Built-ins](09-pipes-redirection-and-builtins.md)
- Processing command output for monitoring:
  [System Information and Utilities](08-system-information.md)

## References

- Phase 3 research notes §4.3 (text processing/searching), §4.4 (processes),
  §7 (version-sensitive), §8 (install list):
  `research/commands/00-shell-command-bible-research.md`.
- GNU grep manual: <https://www.gnu.org/software/grep/manual/>
- GNU sed manual: <https://www.gnu.org/software/sed/manual/>
- Gawk manual: <https://www.gnu.org/software/gawk/manual/>