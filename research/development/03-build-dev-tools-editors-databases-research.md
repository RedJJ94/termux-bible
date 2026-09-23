# Build Tools, Editors, Databases — Research Notes (Phase 7)

Status: research notes supporting Phase 7 (PLAN.md §12: code editors,
compilers, build systems, databases; §14 development environments; §15
repository maintenance tooling). Not polished documentation; kept separate
from Bible chapters per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Items
needing a live device are tagged **[DEVICE]**; version-dependent behavior is
tagged **[version-sensitive]**; unresolved claims `[needs verification]`.

Audit note: all package names, versions, and dependency/install facts below
were verified against the `termux-main` index (`binary-aarch64/Packages`,
fetched 2026-09-22) and the `termux/termux-packages` master build.sh files
(fetched 2026-09-22). The C/C++ toolchain is the `libllvm` family's `clang`
package; there is no `gcc` and no `meson` package in `termux-main`.

Cross-reference: languages/runtimes in
`research/development/02-programming-languages-runtimes-research.md`;
Termux/Android constraints in
`research/development/05-termux-android-dev-constraints-research.md`.

---

## 1. Scope

What a developer actually needs to compile, build, edit, and run services on
Termux: the C toolchain and its packaging (`clang`), the `build-essential`
metapackage, build systems (`make`, `cmake`, `ninja`), tooling
(`pkg-config`, autotools, `ccache`, `distcc`/`sccache`), debuggers
(`gdb`, `lldb`, `strace`), editors (`vim`, `neovim`, `emacs`, `nano`, `micro`,
`helix`), databases (`mariadb`, `postgresql`, `redis`), and the
`termux-services` (runit) mechanism for running persistent dev services.

## 2. Source Inventory and Reliability Ranking

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `termux-main` index `binary-aarch64/Packages` (all versions) | A | packages.termux.dev |
| A2 | `termux/termux-packages` `packages/libllvm/clang.subpackage.sh` | A | raw.githubusercontent.com |
| A3 | `termux/termux-packages` `packages/build-essential/build.sh` | A | raw.githubusercontent.com |
| A4 | `termux/termux-packages` `build.sh` for make, cmake, ninja, pkg-config, autoconf, automake, libtool, bison, flex, m4, ccache, distcc, sccache, gdb, strace | A | raw.githubusercontent.com |
| A5 | `termux/termux-packages` `build.sh` for vim, neovim, emacs, nano, micro, helix | A | raw.githubusercontent.com |
| A6 | `termux/termux-packages` `build.sh` for mariadb, postgresql, redis | A | raw.githubusercontent.com |
| A7 | `termux/termux-packages` `packages/termux-services/build.sh` | A | raw.githubusercontent.com |

## 3. C/C++ Toolchain: clang (from libllvm)

Verified [A1][A2].

- The compiler package is `clang` 21.1.8-3, a **subpackage of `libllvm`**
  (`packages/libllvm/clang.subpackage.sh`). Installing `clang` pulls
  `libcompiler-rt`, `lld`, `llvm`, `ndk-sysroot`, plus the matching
  `libllvm` itself.
- It ships `bin/clang` plus symlinks `bin/cc`, `bin/c++`, `bin/gcc`,
  `bin/g++`, and `*-linux-android*-gcc/g++` wrappers — i.e. on Termux a user
  typing `gcc` runs clang. There is no real `gcc` package.
- `TERMUX_SUBPKG_GROUPS="base-devel"`: clang is part of the base developer
  group.
- `ndk-sysroot` provides the Android platform sysroot/headers used to compile
  against the Android (API) level the packages target. API-level details are
  `[version-sensitive]`; mark `[needs verification]` for the exact default
  API level in the current ndk-sysroot.
- C/C++ version support follows upstream LLVM/Clang 21 behavior.

## 4. build-essential Metapackage

Verified [A3].

- `build-essential` 4.1 — "build tools for Termux". DEPENDS: `clang, make,
  pkg-config`. RECOMMENDS: `autoconf, automake, bc, bison, cmake, flex, gperf,
  libtool, m4`. SUGGESTS: `git, golang, nodejs, patchelf, proot, python, ruby,
  rust, subversion`.
- Practical meaning: `pkg install build-essential` gives a working
  C/C++/autotools build stack and suggests the rest. `patchelf` in SUGGESTS is
  notable — used to patch rpaths/interpreters of prebuilt binaries for Termux.

## 5. Build Systems and Configuration Tools

Verified [A1][A4].

| Tool | Version | Notes |
|---|---|---|
| `make` | 4.4.1-1 | GNU make (default `make`). Note BSD make not packaged. |
| `cmake` | 4.4.3 | RECOMMENDS `clang, make`; cross-toolchain via the clang wrapper symlinks. The Android/NDK toolchain-file used by package builds is supplied by the termux-packages build scripts, not shipped inside the cmake package itself; how an end-user points cmake at the Termux sysroot is `[needs verification]` |
| `ninja` | 1.13.2 | `ninja` build system |
| `pkg-config` | 0.29.2-3 | Standard `.pc` lookup under `$PREFIX/lib/pkgconfig`, `$PREFIX/share/pkgconfig` |
| `autoconf` | 2.73 | |
| `automake` | 1.18.1 | (writes aclocal.m4 + Makefile.in) |
| `libtool` | 2.6.2 | |
| `bison` | 3.8.2-4 | |
| `flex` | 2.6.4-5 | |
| `m4` | 1.4.21 | |
| `gperf` | (suggested) | vim-ish tool; present as RECOMMEND of build-essential |
| `patchelf` | (suggested) | patching ELF interpreters/rpaths for Termux prebuilt binaries |
| `ccache` | 4.14 | compiler cache |
| `distcc` | 3.4-4 | distributed compilation |
| `sccache` | 0.18.0 | compiler cache, Rust/CC support |
| `meson` | — | **not packaged** (do not document as available) |
| `gdb` | 16.3-4 | deps include `python, readline, ...` |
| `lldb` | via `llvm` 21.1.8-3 | debugger |
| `strace` | 7.2 | DEPENDS `libdw` |

- Native builds on device: set `CC=clang`/`CXX=clang++` or rely on
  `build-essential`. For node-gyp/`npm`-driven C builds, `clang, make,
  pkg-config, python` cover the toolchain (see 02 §5).
- `cmake` in Termux targets Android natively; for projects expecting
  `-DDCMAKE_TOOLCHAIN_FILE` for the Play-Store/SDK toolchain see
  `05-termux-android-dev-constraints-research.md`.

## 6. Debuggers and Tracing

Verified [A1][A4].

- `gdb` 16.3-4 fully usable on device (DEPENDS include `python`, `guile`,
  `readline`, etc.); prefer `gdb-server`-style remote when debugging under
  proot/proot-distro `[needs verification]` [DEVICE].
- `lldb` 21.1.8-3 is a **separate package** (DEPENDS `clang, libandroid-spawn,
  libc++, libedit, libxml2, python, ncurses-ui-libs, libllvm`), not part of
  `llvm`. Installs `$PREFIX/bin/lldb` plus `lldb-server`, `lldb-dap`,
  `lldb-argdumper`.
- `strace` 7.2 (DEPENDS `libdw`; needs no root on Android for the calling
  process's own children? — `strace` of other apps needs root or the same
  uid; document restriction `[needs verification]` [DEVICE]).
- Note Android's own `debuggerd`/`tombstone` context; on-device crash
  debugging via `logcat` is documented in the Android debugging material
  (cross-ref `research/adb/`).

## 7. Editors

Verified [A1][A5].

| Editor | Version | Termux packaging facts |
|---|---|---|
| `vim` | 9.2.1100 | DEPENDS `libiconv, libsodium, ncurses`; RECOMMENDS `diffutils, xxd`; SUGGESTS `luajit, perl, python, ruby, tcl`; PROVIDES `vim-python`; CONFLICTS `vim-gtk`; config in `~/.vimrc` (standard) |
| `neovim` | 0.12.5-1 | config `~/.config/nvim` (standard XDG under `$HOME`); uses `lua` internally |
| `emacs` | 31.1-3 | config `~/.emacs.d/` (standard) |
| `nano` | 9.2-1 | lightweight; `~/.nanorc` |
| `micro` | 2.0.15-2 | single-binary editor; config `~/.config/micro` |
| `helix` | 25.07.1-2 | modal editor in Rust; config `~/.config/helix` |

- On-device use of editors is standard; the only Termux-specific fact is that
  `$HOME` and config XDG dirs resolve inside the Termux data directory
  (not `/root`). Terminal type on Android sessions is `$TERM` set by the
  Termux app `[DEVICE]` — mark in chapters that color/fullscreen features can
  depend on terminal emulator settings.

## 8. Databases

Verified [A1][A6].

### MariaDB
- `mariadb` 2:13.0.2. Data dir `$PREFIX/var/lib/mysql`; socket
  `$PREFIX/var/run/mysqld.sock`; config dir `$PREFIX/etc` (with `my.cnf.d`);
  tmp `$PREFIX/tmp`. postinst creates the data dir via
  `mariadb-install-db --user=root --auth-root-authentication-method=normal`
  if missing.
- Run as a service: `termux-services` runit script
  `mysqld` → `exec mysqld --basedir=$PREFIX --datadir=$PREFIX/var/lib/mysql`.
  Enable with `sv-enable mysqld` (needs `termux-services` installed).
- DEPENDS: `libandroid-support, libbz2, libc++, libcrypt, libedit, liblz4,
  libxml2, liblzma, ncurses, openssl, pcre2, zlib, zstd`.

### PostgreSQL
- `postgresql` 18.2-1. DEPENDS include `libicu, libpq, libuuid, libxml2,
  openssl, readline, zlib` plus android shim libs (`libandroid-execinfo`,
  `libandroid-shmem`).
- Data dir: the runit script (`postgres`) prefers `~/.postgres` if a
  `postgresql.conf` exists there, otherwise `$PREFIX/var/lib/postgresql`;
  runs `exec postgres -D $DATADIR`. Init with `initdb -D ...` before starting
  `[needs verification]` for the exact service-init sequence on device
  `[DEVICE]`.
- Note in build comments: `initdb` failures can come from missing symbols;
  keep `libandroid-shmem`/`libandroid-execinfo` installed (they are hard
  dependencies).

### Redis
- `redis` 1:8.10.2. Installs `redis.conf` to `$PREFIX/etc/redis.conf`
  (mode 600). DEPENDS `libandroid-execinfo, libandroid-glob`. There is no
  default runit service script shipped with the package
  (`termux-services` users create one) `[needs verification]` on whether a
  later release added one.

## 9. termux-services (runit) for Development Services

Verified [A7][A1] (cross-ref `01-ssh-research.md` §5 for sshd/ssh-agent).

- `termux-services` provides runit on Termux: services live under
  `$PREFIX/var/service/`, controlled by `sv-enable`, `sv-disable`, `sv`,
  `sv status`. Logging via `svlogger`.
- Development-relevant services sourced from packages include `sshd`,
  `ssh-agent`, `mysqld`, `postgres`; `redis` needs a custom service file.
- Background persistence on Android is limited (battery optimization, phantom
  process killer on Android 12+) — see
  `research/development/05-termux-android-dev-constraints-research.md` and
  `research/termux/00-foundations-research.md`.

## 10. Unresolved / Device-Verified Items

- Default NDK API level for the current `ndk-sysroot` in termux-main
  `[needs verification]`.
- Rather than reproducing Google's Play-Store toolchain file, confirm how
  cmake finds the Android sysroot on device `[DEVICE]`.
- `strace`/`gdb` on non-root apps (ptrace scope) `[DEVICE]`.
- PostgreSQL `initdb` + service start sequence on a fresh device `[DEVICE]`.
- Redis custom runit service recipe `[needs verification]`.