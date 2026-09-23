# C/C++ Toolchain and Build Systems

Termux's C/C++ toolchain is **`clang`**, built from LLVM for Android. There is
**no `gcc` package** in `termux-main`; the `gcc`/`g++` names on the PATH are
clang symlinks. This chapter covers the compiler, the `build-essential`
metapackage, the build systems, configuration tools, compiler caches, and the
debuggers available on device.

## Install the stack

```sh
pkg install build-essential      # clang + make + pkg-config, plus RECOMMENDS
```

- `build-essential` (4.1, "build tools for Termux") DEPENDS on
  `clang, make, pkg-config` and RECOMMENDS `autoconf, automake, bc, bison,
  cmake, flex, gperf, libtool, m4`. SUGGESTS: `git, golang, nodejs, patchelf,
  proot, python, ruby, rust, subversion`.
- Practical meaning: one install gives you a working C/C++/autotools stack and
  suggests the rest. `patchelf` (a SUGGEST) patches ELF interpreters/rpaths of
  prebuilt binaries for Termux. `meson` is **not packaged** — do not rely on
  it.

## The `clang` package

- `clang` (21.1.8-3 as of the 2026-09-22 index) is a **subpackage of
  `libllvm`**. Installing it pulls `libcompiler-rt`, `lld`, `llvm`,
  `ndk-sysroot`, and the matching `libllvm` itself. **[version-sensitive]**
- It installs `$PREFIX/bin/clang` plus symlinks `cc`, `c++`, `gcc`, `g++`, and
  `*-linux-android*-gcc/g++` wrappers. So `gcc` in a Termux script runs clang.
- `ndk-sysroot` supplies the Android platform sysroot/headers used to compile
  against the Android API level Termux packages target. The exact default API
  level of the current `ndk-sysroot` is `[needs verification]`.
- C/C++ language support follows upstream LLVM/Clang 21 behavior.

```sh
cc --version                 # clang version … (Target: aarch64-unknown-linux-android…)
cat > hello.c <<'EOF'
#include <stdio.h>
int main(void){ puts("hello termux"); return 0; }
EOF
cc -o hello hello.c          # cc -> clang
./hello
```

## Build systems and configuration tools

| Tool | Version (2026-09-22) | Notes |
|------|----------------------|-------|
| `make` | 4.4.1-1 | GNU make; BSD make is not packaged |
| `cmake` | 4.4.3 | RECOMMENDS `clang, make`; targets Android natively on Termux |
| `ninja` | 1.13.2 | `ninja` build system |
| `pkg-config` | 0.29.2-3 | looks in `$PREFIX/lib/pkgconfig`, `$PREFIX/share/pkgconfig` |
| `autoconf` | 2.73 | |
| `automake` | 1.18.1 | writes `aclocal.m4` + `Makefile.in` |
| `libtool` | 2.6.2 | |
| `bison` | 3.8.2-4 | |
| `flex` | 2.6.4-5 | |
| `m4` | 1.4.21 | |
| `ccache` | 4.14 | compiler cache |
| `distcc` | 3.4-4 | distributed compilation |
| `sccache` | 0.18.0 | compiler cache, Rust/CC support |
| `patchelf` | (SUGGEST of build-essential) | patch ELF interpreters/rpaths |

- Native builds on device: set `CC=clang`/`CXX=clang++` or just rely on
  `build-essential`; the clang symlinks already provide `cc`/`c++`.
- **cmake on Termux targets Android natively.** Pointing cmake at the Termux
  sysroot for a custom project is a `[needs verification]` item in the research
  (the NDK toolchain-file used by `termux-packages` builds comes from the
  package build scripts, not from the `cmake` package). A typical small build:

```sh
pkg install cmake ninja
mkdir build && cd build
cmake -GNinja ..
ninja
```

- For building **npm/node-gyp** C extensions, `clang, make, pkg-config,
  python` cover the toolchain (see [Node.js and npm](06-nodejs-and-npm.md)).

## Debuggers and tracing

- `gdb` 16.3-4 — fully usable on device. DEPENDS include `python` and
  `readline`. For debugging under proot-distro, prefer a
  `gdb-server`-style remote setup `[needs verification]` **[DEVICE]**.
- `lldb` 21.1.8-3 — a **separate package** (not part of `llvm`). Installs
  `$PREFIX/bin/lldb` plus `lldb-server`, `lldb-dap`, `lldb-argdumper`.
- `strace` 7.2 (DEPENDS `libdw`). Tracing *your own* processes works without
  root; tracing *other* apps needs root or the same uid. **[DEVICE]**
  `[needs verification]` on the exact ptrace-scope restriction per Android
  version.

```sh
pkg install gdb strace         # optionally: lldb
gdb ./hello
strace ./hello
```

## Native Termux vs. proot

- Native Termux: `clang` + `ndk-sysroot`, links against `$PREFIX/lib` shared
  libraries (Android ABI, `libc++_shared.so`). Binaries run **inside Termux**.
- proot-distro guests: the distro's own `gcc`/`clang` and glibc-style
  toolchain; binaries from one do not run in the other. See
  [Development Environment and Constraints](01-development-environment-and-constraints.md#compiling-which-toolchain-is-which).

## Security notes

- `./hello` executes a freshly compiled binary in your app-data directory.
  Compiling and running **untrusted source** is executing untrusted code;
  build in an obviously-labelled directory and review what you run.
- `patchelf` can rewrite ELF headers — modifying binaries changes their
  behavior; only use it on files whose provenance you trust.

## Cross-references

- The execution sandbox and W^X: [Development Environment and Constraints](01-development-environment-and-constraints.md)
- Toolchain needed by pip wheels: [Python](05-python.md)
- Toolchain needed by native npm modules: [Node.js and npm](06-nodejs-and-npm.md)
- Rust linking via clang/lld: [Rust](08-rust.md)
- Go and cgo: [Go](09-go.md)
- Debuggers against Android `logcat`/tombstones: [The Android Shell](../03-android/01-android-shell.md),
  [The `cmd` Dispatcher](../03-android/04-command-dispatcher.md)

## References

- Phase 7 research notes §3–§6:
  `research/development/03-build-dev-tools-editors-databases-research.md`.
- Versions/deps verified against the `termux-main` (aarch64) index and
  `termux/termux-packages` master `build.sh` files, fetched 2026-09-22.