# Java, Kotlin, and Android Build Tooling

Termux can install real JDKs, the Kotlin compiler, and the JVM build tools —
and even the Android asset-packaging and APK-signing tools, which makes
building small Android packages on-device possible without a desktop. Versions
below are from the 2026-09-22 `termux-main` aarch64 index **[version-sensitive]**.

## JDKs

| Package | Version (2026-09-22) | Notes |
|---------|----------------------|-------|
| `openjdk-17` | 17.0.20 | JRE + JDK 17 |
| `openjdk-21` | 21.0.12 | JRE + JDK 21 |
| `openjdk-25` | 25.0.4 | JRE + JDK 25 |

```sh
pkg install openjdk-21       # pick the line your toolchain needs
java -version
javac -version
```

- How `java`/`javac` resolve when **several** OpenJDK packages are installed at
  once is an open question in the research: each package installs
  `java`/`javac` under `$PREFIX/bin`, and which one wins depends on the
  packaging (alternatives or last-installed-wins). **[DEVICE]**
  `[needs verification]` — install only the JDK line your tools require.

## Kotlin

- `kotlin` 2.4.20 **depends on `openjdk-21`**, installs to `$PREFIX/opt/kotlin`,
  with `$PREFIX/bin` symlinks (`kotlin`, `kotlinc`, …).

```sh
pkg install kotlin            # pulls openjdk-21
kotlinc -version
cat > Hello.kt <<'EOF'
fun main() { println("hello kotlin on termux") }
EOF
kotlinc Hello.kt -include-runtime -d hello.jar
kotlin hello.jar
```

## JVM build tools

| Tool | Version (2026-09-22) | Notes |
|------|----------------------|-------|
| `gradle` | 9.7.1 | DEPENDS `openjdk-21 \| openjdk-25 \| openjdk-17` |
| `maven` | 3.9.16 | DEPENDS `openjdk-21`, `libjansi` |
| `ant` | 1.10.18 | DEPENDS `openjdk-21` |

```sh
pkg install gradle maven ant
gradle -v && mvn -v && ant -version
```

## Building Tiny Android packages on device

Two Android packaging tools exist in `termux-main`:

- **`aapt`** (16.0.0.4) — Android Asset Packaging Tool (DEPENDS `fmt, libc++,
  libexpat, libpng, libzopfli, zlib`).
- **`apksigner`** (37.0.0) — APK signing tool (DEPENDS `openjdk-21`).

These let you compile, package, and sign minimal APKs **on the phone** without
Android Studio, using the command-line tools above ([DEVICE]); a full
`android.jar`/SDK/emulator workflow is a separate, largely unverified topic
`[needs verification]` and is not claimed here.

## Native Termux vs. proot

Inside proot-distro, JVMs and Kotlin come from the guest's repositories
(`apt install openjdk-17 kotlin`) with a glibc runtime — a different Java
installation from the Termux one. Build output you ship should be version- and
environment-consistent.

## Security notes

- `gradle`/`maven` download dependencies from remote repositories and execute
  build plugins from them. A project's build scripts run with your user's
  privileges; only build projects you trust, and be careful with plugins pulled
  from arbitrary repositories.

## Cross-references

- The Android commands you could drive from Java code: [Android](../03-android/00-intro.md)
- On-device signing overlaps with Android packaging tools in
  [ADB and Android Debugging](../04-adb/00-intro.md)
- Rust/Go toolchain links: [Rust](08-rust.md), [Go](09-go.md)

## References

- Phase 7 research notes §6:
  `research/development/02-programming-languages-runtimes-research.md`.
- Versions/deps verified against the `termux-main` (aarch64) index and the
  `termux/termux-packages` master build.sh files for
  openjdk/kotlin/maven/ant/gradle/aapt/apksigner, fetched 2026-09-22.