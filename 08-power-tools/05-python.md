# Python

Python is installed like any other Termux package and integrates normally with
the `$PREFIX` environment. The version resolved from the 2026-09-22
`termux-main` index is **Python 3.14.6** **[version-sensitive]**.

## Install

```sh
pkg install python
```

- The `python` package provides both `python` and `python3` (the latter is an
  alias — the package declares `TERMUX_PKG_PROVIDES="python3"`).
- It **recommends** `python-ensurepip-wheels` and `python-pip`, so `pkg install
  python` also pulls `pip`. If pip is somehow missing, the postinst prints a
  reminder to `pkg install python-pip`.
- `python-ensurepip-wheels` ships the `ensurepip` wheels so
  `python -m ensurepip` / the pip bootstrap works without network access.

## Using pip

```
python -m pip install --upgrade pip      # upgrade pip itself
python -m pip install requests           # install a pure-Python package
python -c 'import requests; print(requests.__version__)'
```

- pip installs into `$PREFIX/lib/python3.14/site-packages` — **Termux's own
  prefix, not Android's `/usr`**. Uninstall with `python -m pip uninstall`.
- Many packages with C extensions need a compiler at install time. For those,
  have the Termux C/C++ toolchain available
  ([C/C++ Toolchain and Build Systems](03-c-cpp-toolchain-and-build-systems.md)):
  `pkg install build-essential` (clang, make, pkg-config). Per-package build
  quirks are `[needs verification]` and cannot be listed exhaustively.
- Whether a particular wheel has a **prebuilt Termux binary** or must be built
  on device from source varies by package and by Python version **[DEVICE]**.

## Running scripts

```sh
cat > hello.py <<'EOF'
#!/usr/bin/env python3
print("hello from termux")
EOF
chmod +x hello.py
./hello.py                 # executable script (termux-exec handles the shebang)

# or:
python hello.py
python3 -c 'print(1+1)'
```

The `#!/usr/bin/env python3` shebang is portable; the `termux-exec` interposer
handles interpreter-path rewriting inside Termux (see
[Development Environment and Constraints](01-development-environment-and-constraints.md)).

## Historical note [version-sensitive]

The `python` postinst contains cleanup logic for leftover `python3.11`/`3.12`
site-packages from earlier major versions — a maintenance artifact, not config
you need to manage yourself.

## Native Termux vs. proot

Inside proot-distro, `apt install python3` gives the distro's Python with a
glibc toolchain and its own `sys.prefix`; its packages and paths are unrelated
to the Termux-native Python. Do not mix `pip` targets across the two
environments.

## Cross-references

- The compiler pip needs for C extensions:
  [C/C++ Toolchain and Build Systems](03-c-cpp-toolchain-and-build-systems.md)
- Node's sibling native-build stack: [Node.js and npm](06-nodejs-and-npm.md)
- `python` is also a dependency of several tools (`gdb`, `lldb`, editor
  options, `httpie`): see the relevant chapters.
- Running finished programs as scripts:
  [Development Environment and Constraints](01-development-environment-and-constraints.md#executing-files-wx-and-the-android-10-app-data-restriction)

## References

- Phase 7 research notes §4:
  `research/development/02-programming-languages-runtimes-research.md`.
- Version/deps verified against the `termux-main` (aarch64) index and
  `termux/termux-packages` `packages/python/build.sh`, fetched 2026-09-22.