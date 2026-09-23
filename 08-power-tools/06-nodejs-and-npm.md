# Node.js and npm

Node.js is available in Termux in two lines — the current release and the
long-term-support line — and, since a specific version boundary, **npm is a
separate package** rather than bundled with `node`. Versions below are from the
2026-09-22 `termux-main` aarch64 index **[version-sensitive]**.

## Which package

| Package | Version (2026-09-22) | Notes |
|---------|----------------------|-------|
| `nodejs` | 26.4.0-1 | current line; RECOMMENDS `npm` |
| `nodejs-lts` | 24.18.0-1 | LTS line; RECOMMENDS `npm` |
| `npm` | 11.20.0 | separate package; DEPENDS `nodejs \| nodejs-lts` |

Install whichever line you track:

```sh
pkg install nodejs npm        # current line + npm
# or, for the LTS line:
# pkg install nodejs-lts npm
```

- **npm is not bundled** with `nodejs` since `nodejs` 25.3.0-1 (and
  `nodejs-lts` 24.13.0). The npm package CONFLICTS with older `nodejs` /
  `nodejs-lts` versions, and the `nodejs` postinst prints a hint to
  `pkg install npm`. **[version-sensitive]**
- `npm` installs to `$PREFIX/lib/node_modules/npm`, with `npm`/`npx` symlinks
  in `$PREFIX/bin` and bash completion in `$PREFIX/etc/bash_completion.d/npm`.

## How the Node.js build differs from desktop builds

- The Termux `nodejs` is built against **shared OpenSSL, ICU
  (host-built), c-ares, SQLite, FFI, and zlib** (`--shared-*`), but does **not**
  use a shared libuv (Android's linker cannot resolve symbols of linked shared
  libraries when used transitively — a Termux packaging comment).
- Headers install to `$PREFIX/include/node`.
- DEPENDS: `libc++, openssl, c-ares, libicu, libsqlite, zlib, libffi`.
  SUGGESTS for native modules: `clang, make, pkg-config, python` — i.e.
  **node-gyp native-module builds use the Termux C toolchain**:

```sh
pkg install build-essential python     # for native (node-gyp) dependencies
```

## Using npm

```sh
node -v && npm -v
npm init -y                 # create package.json
npm install                 # install dependencies from package.json
npm install --save express  # install + record a dependency
npx prettier --check .      # run a one-off tool via npx
npm start                   # run the "start" script
```

- Default registry access is normal HTTPS; `npm` configuration lives under
  `~/.npmrc` like everywhere else.
- Historical note: the old bundled npm forced package `foreground-scripts true`
  to cooperate with Android build steps in the pre-separate-npm era. The new
  `npm` package does not. If you inherited that setting and hit background-job
  confusion, `npm config delete foreground-scripts` returns you to standard
  behavior. `[needs verification]` on the exact historical rationale.

## Running a Node script

```sh
cat > hello.js <<'EOF'
console.log('hello from node', process.version);
EOF
node hello.js
```

## Native Termux vs. proot

Inside proot-distro, Node comes from the guest's package manager (for example
`apt install nodejs npm` in a Debian/Ubuntu guest) with the guest's toolchain
for native addons. The Termux-native `node` and the guest's `node` are separate
installations — do not treat them as interchangeable.

## Security notes

- `npm install` runs package install scripts from the registry by default;
  installing arbitrary packages means executing their postinstall code as your
  normal user. Review packages before installing, and prefer pinned
  dependencies for anything you rely on.

## Cross-references

- The toolchain required for native modules:
  [C/C++ Toolchain and Build Systems](03-c-cpp-toolchain-and-build-systems.md)
- Python's similar wheel situation: [Python](05-python.md)
- HTTP clients for testing what you build:
  [Networking and Developer Utilities](11-networking-and-developer-utilities.md)

## References

- Phase 7 research notes §5:
  `research/development/02-programming-languages-runtimes-research.md`.
- Version/deps verified against the `termux-main` (aarch64) index and
  `termux/termux-packages` master `packages/nodejs/build.sh`,
  `packages/nodejs-lts/build.sh`, and `packages/npm/build.sh`, fetched
  2026-09-22.