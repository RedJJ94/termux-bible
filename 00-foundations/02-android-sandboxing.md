# Android Sandboxing and Execution Environments

Termux runs inside the Android application sandbox, and it can interoperate
with several other distinct execution environments. Keeping these separate
matters: a command that works in one environment does not necessarily work in
another.

## The Android application sandbox

Every Android app, Termux included, runs as its own Unix user (for Termux, a
UID such as `u0_a369`), under SELinux policy, with access to its own private
data directory on `/data`. Consequences for Termux:

- **Single user.** The running user's name is derived from the Termux app UID
  and cannot be changed.
- **Private data.** Everything under `/data/data/com.termux/` is owned by
  Termux and normally readable only by Termux.
- **No root by default.** Termux is not rooted; `pkg` refuses to run as root
  when it detects uid 0 (for example when Termux is launched from a root
  shell). Root must be obtained separately (e.g. via `su` from a rooted
  device) and is unrelated to Termux itself.
- **Android controls process life.** Android kills processes when they are
  backgrounded, under memory pressure, or when too many "phantom" processes
  exist. On Android 12+ the system kills processes in excess of 32 phantom
  processes (across all apps) and CPU-heavy processes; a common symptom in
  Termux is `[Process completed (signal 9)]`. **Version-sensitive.**
  Mitigation: a developer option exists on Android 12L/13 to disable the
  phantom process limit. See termux-app issue #2366.

## Why environment distinctions matter

The Termux shell you normally open is one environment. But the same screen can
be reached from several very different places depending on who is executing
what:

- **Normal Termux** — the app; everything described throughout this Bible as
  "Termux".
- **Termux packages** — software installed with `pkg`/`apt` inside `$PREFIX`;
  compiled for Android/Bionic, non-FHS.
- **The Android shell** — `/system/bin/sh` on the device, outside the Termux
  environment.
- **ADB shell** — a shell over USB/Wi-Fi from a computer via `adb shell`,
  running as the `shell` user. See the ADB section.
- **Root shell** — `su` from a rooted device or via ADB root.
- **Shizuku / rish / Porter** — separate privileged-access systems; not
  Termux, and not interchangeable with root or with each other.
- **proot / proot-distro** — a user-space re-implementation of
  `chroot`-like isolation. proot-distro installs complete Linux distributions
  (Debian, Ubuntu, Alpine, Arch, Fedora, and others) into **separate root
  filesystems** under `$PREFIX/var/lib/proot-distro/`.
- **A Linux distribution running inside proot** — e.g. Ubuntu inside
  proot-distro: this is *not* native Termux (full FHS layout, its own package
  manager, and its own package repositories).

A command must always be understood *in the environment where it runs* and
with *its own* package manager, roots, and libraries. This Bible states the
intended environment for commands when it matters.

## Native Termux vs. a Linux distribution inside proot

### Package management is not shared

**Native Termux** installs packages from Termux repositories with `pkg`/`apt`.
These packages are `.deb` archives compiled for Android (Bionic), and they
follow the native Termux (FHS-free) layout under `$PREFIX`. They must not be
copied from Debian/Ubuntu. The native package manager, repositories, keys
(`termux-keyring`), mirror selection (`termux-change-repo`), and the
single-architecture/no-downgrade rules apply **only to native Termux**.

**A distribution inside proot-distro** keeps the distribution's *own* package
manager and repositories, on its *own* root filesystem: Ubuntu/Debian use
`apt`/`dpkg`, Alpine uses `apk`, Arch uses `pacman`, Fedora uses `dnf`, SUSE
uses `zypper`. Running `apt-get` *inside* Ubuntu on proot-distro operates on
that container's `/etc/apt/` and dpkg database — it is **not** Termux's
package manager. FHS paths (`/usr`, `/etc`, `/var`) inside the container exist
and are writable, unlike native Termux.

Therefore native-Termux rules such as "no FHS", "single architecture", "no
downgrades", `termux-change-repo`, or `termux-keyring` do **not** transfer to
a distro inside proot.

### Directory and runtime model

proot-distro keeps containers under
`$TERMUX__PREFIX/var/lib/proot-distro/containers/<name>/rootfs/`
(`$TERMUX__PREFIX` defaults to `/data/data/com.termux/files/usr`). Older
proot-distro versions used an `installed-rootfs/<name>/` layout; that is
**historical** and is auto-migrated on first login. Full proot-distro
documentation (install, login, backup, and guest package management) belongs to
the later Advanced Termux section; here it is enough to know that guest
packages are managed with the *guest distribution's* tools, not with `pkg`.

### Installer notes

`proot-distro` itself is installed as a native Termux package (`pkg install
proot-distro`). Its defaults inside a container differ from Termux: by default
you log in as `root` inside the container, and the guest environment is not
inherited from the host (a clean environment is built; `$PREFIX/bin` is
appended to the guest `PATH`, and for normal containers the Termux `$PREFIX`
is bind-mounted into the guest). None of that changes how packages are managed
inside the guest.

## Permission model summary

Access to shared storage requires an explicit Android permission that is not
granted by default and is not requested at startup. See
[Storage and Permissions](04-storage-and-permissions.md) for the permission
matrix by Android version.

## References

- termux-app README and issue tracker: <https://github.com/termux/termux-app>
- proot-distro (official): <https://github.com/termux/proot-distro>
- Termux wiki "Differences from Linux" and development wiki pages.
- Termux research notes in `research/termux/00-foundations-research.md`,
  sections on sandboxing and §3.12 "Native Termux vs proot-distro package
  management" (this chapter's source).