# Programming Languages & Runtimes — Research Notes (Phase 7)

Status: research notes supporting Phase 7 (PLAN.md §2 "cover development
tools", §12 "programming languages" incl. Python, Node.js, Java, Kotlin, Rust,
Go, C/C++, and §14 development environments). Not polished documentation;
kept separate from Bible chapters per AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Anything
needing a live device is tagged **[DEVICE]**; version-dependent behavior is
tagged **[version-sensitive]**; unresolved claims `[needs verification]`.

Audit note: every package name, version, and dependency line below was verified
against the **`termux-main` repository index (binary-aarch64, fetched
2026-09-22)** and/or the matching **`termux/termux-packages` master build.sh**
(fetched 2026-09-22). No package is listed that is not present in
`termux-main`. Nothing here comes from memory-only recollection.

Cross-reference: the C/C++ toolchain, build systems, and editors are in
`research/development/03-build-dev-tools-editors-databases-research.md`;
Termux/Android execution constraints are in
`research/development/05-termux-android-dev-constraints-research.md`; `git`/
`gh`/SSH workflows are in `00-`/`01-`.

---

## 1. Scope

Version + packaging facts for the language runtimes/compilers available in
`termux-main`, plus the Termux-specific facts that matter when using them
(where the toolchain lives, what the environment sets, what a package depends
on, known caveats). This is the research base for future "install & use
Python / Node / Java / Rust / Go / C" chapters.

## 2. Source Inventory and Reliability Ranking

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `termux-main` index `binary-aarch64/Packages` (all versions) | A | packages.termux.dev |
| A2 | `termux/termux-packages` `packages/python/build.sh` | A | raw.githubusercontent.com |
| A3 | `termux/termux-packages` `packages/nodejs/build.sh` and `packages/nodejs-lts/build.sh` | A | raw.githubusercontent.com |
| A4 | `termux/termux-packages` `packages/npm/build.sh` | A | raw.githubusercontent.com |
| A5 | `termux/termux-packages` `packages/golang/build.sh` | A | raw.githubusercontent.com |
| A6 | `termux/termux-packages` `packages/rust/build.sh` | A | raw.githubusercontent.com |
| A7 | `termux/termux-packages` `packages/{kotlin,maven,ant,gradle,openjdk-17,openjdk-21,openjdk-25,apksigner,aapt}/build.sh` | A | raw.githubusercontent.com |
| A8 | `termux/termux-packages` `packages/{swift,zig,dart,ghc,elixir,erlang,php,ruby,perl,lua54,luarocks,wasi-libc}/build.sh` | A | raw.githubusercontent.com |

Note: openjdk build.sh files were fetched but not fully analyzed in this
session (dependencies marked `[needs verification]` where not personally
read; versions are from [A1]).

## 3. Summary Table (termux-main, aarch64, 2026-09-22)

| Package | Version | Key deps / notes |
|---|---|---|
| `python` | 3.14.6-1 | provides `python3` alias; RECOMMENDS `python-ensurepip-wheels`, `python-pip` |
| `python-pip` / `python-ensurepip-wheels` | (see index) | RECOMMENDED by python |
| `nodejs` | 26.4.0-1 | RECOMMENDS `npm`; no bundled npm since v25.3.0-1 |
| `nodejs-lts` | 24.18.0-1 | LTS line; same npm policy |
| `npm` | 11.20.0 | separate package; DEPENDS `nodejs \| nodejs-lts` |
| `openjdk-17` | 17.0.20 | JRE+JDK 17 |
| `openjdk-21` | 21.0.12 | JRE+JDK 21 (used by kotlin/maven/ant/apksigner) |
| `openjdk-25` | 25.0.4 | JRE+JDK 25 |
| `kotlin` | 2.4.20 | DEPENDS `openjdk-21`; installed to `$PREFIX/opt/kotlin`, bin symlinks |
| `rust` | 1.98.1 | DEPENDS `clang, libandroid-execinfo, libc++, libllvm, lld, openssl, zlib`; SUGGESTS `rust-analyzer`; ships cargo |
| `rust-analyzer` | (index) | language server |
| `golang` | 3:1.27.1 | DEPENDS `clang`; GOROOT `$PREFIX/lib/go` |
| `swift` | 6.3.3-1 | DEPENDS clang + many android libs + `swift-sdk-${arch}` |
| `zig` | 0.16.0 | DEPENDS `resolv-conf` |
| `dart` | 3.13.4 | EXCLUDED_ARCHES `i686` |
| `ghc` | 9.12.2-5 | PROVIDES `ghc-libs`, `ghc-libs-static` |
| `elixir` | 1.20.4 | DEPENDS `dash, erlang`; SUGGESTS `clang, make` (NIFs) |
| `erlang` | 29.1.1 | DEPENDS `libc++, openssl, ncurses, zlib` |
| `php` | 8.5.1 | many deps (inc. `libicu, libxml2, libzip, openssl, pcre2, readline, tidy, zlib`); CONFLICTS `php-mysql, php-dev` |
| `ruby` | 4.0.6 | DEPENDS `libandroid-execinfo, libandroid-support, libffi, libgmp, libyaml, readline, openssl, zlib`; RECOMMENDS `clang, make, pkg-config, resolv-conf` |
| `perl` | 5.42.2 | DEPENDS `libandroid-utimes`; includes CPAN support |
| `lua54` | 5.4.8-10 | standalone interpreter + libs |
| `luarocks` | 3.13.0-1 | DEPENDS `curl, lua54` |
| `wasi-libc` | 34+really33 | WASI sysroot for WebAssembly targets |
| `wasm-component-ld` | (index) | RECOMMENDED by wasi-libc |

## 4. Python

Verified [A1][A2].

- `python` 3.14.6 provides `python` and `python3` (the latter is an alias —
  `TERMUX_PKG_PROVIDES="python3"`).
- The package RECOMMENDS `python-ensurepip-wheels` and `python-pip`, i.e.
  `pkg install python` pulls them unless explicitly excluded. The postinst
  also prints a reminder to `pkg install python-pip` if pip is missing.
- `pip` installs into the user/system site-packages under
  `$PREFIX/lib/python3.14/site-packages`, not Android's `/usr` — packages
  compiled via `pip` need the Termux C/C++ toolchain (`clang`, `make`,
  `pkg-config`) for many wheels with C extensions `[needs verification]` for
  per-package quirks.
- postinst has cleanup logic for leftover `python3.11/3.12` site-packages
  [A2] — historical artifact, `[version-sensitive]`.
- `python-ensurepip-wheels`: ships `ensurepip` wheels so `python -m ensurepip`
  / `pip` bootstrap works offline (RECOMMENDED by python).

## 5. Node.js, npm

Verified [A1][A3][A4].

- `nodejs` 26.4.0 and `nodejs-lts` 24.18.0 both exist; install whichever line
  you track. Both RECOMMEND `npm`.
- **npm is a separate package since nodejs v25.3.0-1**: nodejs no longer
  bundles it (`npm` package CONFLICTS with `nodejs <= 25.3.0` and `nodejs-lts
  <= 24.13.0`; `nodejs` postinst prints a hint to `pkg install npm`).
  `npm` 11.20.0 installs to `$PREFIX/lib/node_modules/npm`, with `npm`/`npx`
  symlinks in `$PREFIX/bin` and bash completion in
  `$PREFIX/etc/bash_completion.d/npm`.
- nodejs build uses **shared OpenSSL, ICU (host-built), c-ares, SQLite, FFI,
  zlib** (`--shared-*`), but **does not use shared libuv** (Termux comment:
  Android linker does not resolve symbols of linked shared libraries when
  used transitively). Headers install to `$PREFIX/include/node`.
- nodejs DEPENDS `libc++, openssl, c-ares, libicu, libsqlite, zlib, libffi`;
  its npm-related SUGGESTS are `clang, make, pkg-config, python` — i.e.
  node-gyp/native-module builds need the Termux C/C++ toolchain.
- npm postinst: earlier bundled npm forced `foreground-scripts true`; the new
  npm does not. Users who set it may want
  `npm config delete foreground-scripts` [A4] (integration with
  `patchelf`/android build steps; the config was set to help with
  `@mapbox/node-pre-gyp`-style postinstalls in the old bundled era
  `[needs verification]` on details).

## 6. Java / Kotlin / Android-build tooling

Verified [A1][A7].

- Three JDKs coexist: `openjdk-17` (17.0.20), `openjdk-21` (21.0.12),
  `openjdk-25` (25.0.4). They conflict/co-install via alternatives or PATH
  management? — **`[needs verification]`** how `java` resolves when several
  are installed (typical Termux layout: each package installs `java`/`javac`
  under `$PREFIX/bin` and the last installed wins, or a selector script).
- `kotlin` 2.4.20 depends on `openjdk-21`; installs to `$PREFIX/opt/kotlin`
  with `$PREFIX/bin/*` symlinks (kotlin, kotlinc, etc.).
- Build tools: `gradle` 9.7.1 (DEPENDS `openjdk-21 | openjdk-25 |
  openjdk-17`), `maven` 3.9.16 (DEPENDS `openjdk-21`, `libjansi`),
  `ant` 1.10.18 (DEPENDS `openjdk-21`).
- Android packaging tools present in termux-main: `aapt` 16.0.0.4 (Android
  asset packaging tool; DEPENDS `fmt, libc++, libexpat, libpng, libzopfli,
  zlib`) and `apksigner` 37.0.0 (DEPENDS `openjdk-21`) — usable for
  signing/packaging APKs on device without Android Studio `[DEVICE]`.
- Note: full `android.jar` / SDK emulators are **not** the focus here; on-device
  Android SDK development is a separate workflow `[needs verification]` if it
  becomes a chapter topic.

## 7. Rust

Verified [A1][A6].

- `rust` 1.98.1 ships `rustc`, `cargo`, `rustdoc`, etc. Depends on `clang,
  libandroid-execinfo, libc++, libllvm (<< next major), lld, openssl, zlib`.
  SUGGESTS `rust-analyzer`.
- The build ensures `rustc`/`cargo` resolve the right toolchain: `rustup`
  is not the mechanism in Termux (no `rustup` packaged); the system `rust`
  package puts the toolchain under `$PREFIX/lib/rustlib/<target>` with
  `rust-std-<target>` as an additional dependency.
- Linking: Termux sets `rpath` to `$PREFIX/lib` and uses local `clang` (via
  `*_CC`/`RUSTFLAGS`) so binaries link against `libc++_shared.so`,
  `libandroid-execinfo`, etc., found in `$PREFIX/lib` [A6].
- `wasm32-wasip1`/`wasm32-unknown-unknown` targets: `wasi-libc` provides the
  WASI sysroot (linked via `share/wasi-sysroot`) for WebAssembly targets
  [A6][A8]; `rustup target add` equivalents are handled through the packaged
  `rust-std` components.
- `cargo install` builds from source using `clang`/`lld` — native code with
  build scripts needs the toolchain (see 03).

## 8. Go

Verified [A1][A5].

- `golang` 3:1.27.1. Depends on `clang` (cgo default CC is the Termux clang
  wrapper, obviating a bundled gcc). GOROOT is `$PREFIX/lib/go`;
  `$PREFIX/bin/go` and `$PREFIX/bin/gofmt` are symlinks into it.
- The build sets GO_LDSO to `/system/bin/linker64` (or `linker` on 32-bit),
  `-extldflags=-pie`, and disables hardcoded PKG_CONFIG pathing [A5] —
  meaning cgo builds locate pkg-config at runtime via PATH.
- GOPATH default (`$HOME/go`) applies; `go mod` proxy works normally
  (`GOPROXY` default is `https://proxy.golang.org,direct` standard).
  On-device network reaches proxy `[DEVICE] [needs verification]` if offline
  builds documented.
- Also note `golang` has `TERMUX_PKG_RECOMMENDS="resolv-conf"` — DNS
  resolution library for Go binaries `[needs verification]` on practical need.

## 9. C/C++ and other compilers

- There is **no `gcc` package** in `termux-main` (only historical build
  files; the current C/C++ compiler is `clang` — see
  `research/development/03-build-dev-tools-editors-databases-research.md`).
- Swift (`swift` 6.3.3), Zig (`zig` 0.16.0), DART (`dart` 3.13.4), Haskell
  (`ghc` 9.12.2), Erlang (`erlang` 29.1.1), Elixir (`elixir` 1.20.4), PHP
  (`php` 8.5.1), Ruby (`ruby` 4.0.6), Perl (`perl` 5.42.2), Lua (`lua54`
  5.4.8 + `luarocks` 3.13.0) are all present [A1]. Their DEPENDS are listed in
  §3; the practical takeaway is that nearly all of them either need the
  `clang`/`make`/`pkg-config` toolchain for native extensions or ship a
  self-contained runtime.

## 10. Unresolved / Device-Verified Items

- JDK coexistence/`java` resolution when multiple openjdk packages are
  installed `[DEVICE] [needs verification]`.
- openjdk build.sh details (not fully read this session) `[needs verification]`.
- npm/`foreground-scripts` practical impact on Android build steps
  `[needs verification]`.
- pip wheel build/install behavior for C extensions on device `[DEVICE]`.
- `resolv-conf` practical role for Go binaries `[needs verification]`.
- Whether `cargo` needs `rustup`-style target additions for common targets
  (documented as packaged `rust-std`) `[needs verification]`.