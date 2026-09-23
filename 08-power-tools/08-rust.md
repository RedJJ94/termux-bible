# Rust

The `rust` package in `termux-main` ships the Rust toolchain compiled for
Android, including `cargo`, `rustdoc`, and the standard library for the
Termux target. Termux does **not** use `rustup`; the packaged toolchain is the
supported path. Version: **1.98.1** as of the 2026-09-22 `termux-main`
aarch64 index **[version-sensitive]**.

## Install

```sh
pkg install rust
rustc --version && cargo --version
```

- DEPENDS: `clang, libandroid-execinfo, libc++, libllvm (<< next major), lld,
  openssl, zlib`. SUGGESTS: `rust-analyzer` (the language server).
- The toolchain lives under `$PREFIX/lib/rustlib/<target>/`, with
  `rust-std-<target>` as an additional dependency; `rustup`-style target
  additions are handled through the packaged `rust-std` components
  `[needs verification]` on which extra targets are packaged.
- **Linking uses the Termux `clang` and `lld`**: the build wires up
  `*_CC`/`RUSTFLAGS` so binaries link against `libc++_shared.so`,
  `libandroid-execinfo`, and the rest of `$PREFIX/lib`, with `rpath` set to
  `$PREFIX/lib`. This is what makes Rust binaries run inside Termux.

## A first crate

```sh
cargo new hello && cd hello
cargo build
cargo run            # prints "Hello, world!"
```

## `cargo install`

- `cargo install` builds the crate **from source** using `clang`/`lld`. Crates
  with build scripts or native code need the toolchain installed as above
  (`build-essential` covers `clang` + `make`); heavy builds are subject to the
  Android background limits described in
  [Development Environment and Constraints](01-development-environment-and-constraints.md#background-execution-and-process-limits).

## WebAssembly

- `wasi-libc` provides the WASI sysroot for WebAssembly targets, and
  `wasm-component-ld` is recommended alongside it. Target support via the
  packaged `rust-std` components is how you add e.g. `wasm32-wasip1` /
  `wasm32-unknown-unknown` (`[needs verification]` on the exact per-target
  packaging).

## Native Termux vs. proot

Inside proot-distro, Rust typically comes from `rustup` or the guest's package
manager with a glibc toolchain; its binaries run in the guest, not in Termux.
Choose the environment that matches what you are building for.

## Security notes

- `cargo` executes build scripts and procedural macros from every dependency
  at build time — `cargo install`/`cargo build` of untrusted crates is running
  untrusted code. Check what you add to a project, and note that `cargo install
  --locked`/registry mirrors are your responsibility.

## Cross-references

- The clang/lld toolchain Rust links against:
  [C/C++ Toolchain and Build Systems](03-c-cpp-toolchain-and-build-systems.md)
- Go's similar setup: [Go](09-go.md)
- The execution sandbox for built binaries:
  [Development Environment and Constraints](01-development-environment-and-constraints.md)

## References

- Phase 7 research notes §7:
  `research/development/02-programming-languages-runtimes-research.md`.
- Version/deps verified against the `termux-main` (aarch64) index and
  `termux/termux-packages` master `packages/rust/build.sh`, fetched 2026-09-22.