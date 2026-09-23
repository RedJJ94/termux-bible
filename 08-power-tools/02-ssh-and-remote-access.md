# SSH and Remote Access

SSH is the standard way to reach another machine's command line securely, and
on Termux it also gives you a way into your own phone from a computer. The
Termux `openssh` package ships both the **client** and the **server** (`sshd`),
plus key tools, built for Android. This chapter documents the toolset itself;
using SSH keys for GitHub authentication and for Git commit signing is covered
in [Git and GitHub](../11-git-github/00-intro.md).

Everything here is **native Termux**. This is a normal user-space daemon — it
is **not** related to ADB, rish, Shizuku, or Porter (AGENTS.md §6/§10).

## Install

```sh
pkg install openssh
```

- Package `openssh` (10.5p1 as of the 2026-09-22 `termux-main` aarch64 index)
  **[version-sensitive]**. DEPENDS include `libandroid-support, libedit,
  openssh-sftp-server, openssl, termux-auth, zlib`; SUGGESTS
  `termux-services`; CONFLICTS with `dropbear` (both provide an sshd).
- The package installs `ssh`, `sshd`, `ssh-keygen`, `ssh-copy-id`, `scp`,
  `sftp` (via `openssh-sftp-server`), `ssh-add`, and the `ssha`/`scpa`/`sftpa`
  agent-wrapper symlinks.

## Configuration locations

- Config dir: **`$PREFIX/etc/ssh`** — `ssh_config` and `sshd_config` live
  there (both are registered conffiles).
- The packaged configs contain `Include /etc/ssh/sshd_config.d/*.conf` and
  `Include /etc/ssh/ssh_config.d/*.conf`. On Android `/etc/ssh` normally does
  not exist and is not writable without root, so those Include lines are
  expected to be **inert on most devices**; put your own drop-ins under
  `$PREFIX/etc/ssh/` instead. **[OEM]** **[DEVICE]** `[needs verification]`
- User config for the client: `$HOME/.ssh/config` (standard OpenSSH).
- Pid directory `$PREFIX/var/run`; privilege-separation directory
  `$PREFIX/var/empty`; default `PATH` for sshd sessions is `$PREFIX/bin`.

## The SSH client

```sh
pkg install openssh
ssh user@example.com                    # connect (port 22)
ssh -p 8022 user@192.168.1.20           # connect on a custom port
ssh-keygen -t ed25519 -C "comment"      # generate a key pair, see below
ssh-copy-id user@example.com            # install your public key on a host
scp file user@example.com:/dest/        # copy over SSH
sftp user@example.com                   # interactive file transfer
```

- `ssh-copy-id` is built into `$PREFIX/bin` (its `SANE_SH` is patched to
  `$PREFIX/bin/bash`).
- Per-host options belong in `$HOME/.ssh/config` (host alias, `IdentityFile`,
  port, user); SSH and Git both read it transparently.

## Keys: `ssh-keygen` defaults

OpenSSH default semantics apply on Termux. The current defaults are:

- With **no `-t` option, `ssh-keygen` generates an Ed25519 key**
  (`~/.ssh/id_ed25519` + `.pub`). **[version-sensitive]** — older OpenSSH
  versions defaulted to RSA; the default changed over time.
- Explicit key types accepted by `-t`: `ecdsa`, `ecdsa-sk`, `ed25519`
  (the default), `ed25519-sk`, `mldsa44-ed25519`, `rsa`. RSA default size is
  3072 bits (minimum 1024).
- Host keys for a server: `ssh-keygen -A` generates all default host key types
  (`rsa`, `ecdsa`, `mldsa44-ed25519`, `ed25519`) that are absent; the
  `openssh` postinst already does this for the server (`ssh_host_{rsa,ecdsa,ed25519}_key`
  under `$PREFIX/etc/ssh`, empty passphrase).
- Private keys are written in OpenSSH's native format by default; use
  `-m PEM` to force PEM. The comment defaults to `user@host`; set it with `-C`.
- The old SHA-1 `ssh-rsa` signature algorithm is deprecated (OpenSSH 8.2+);
  RSA signing falls back to `rsa-sha2-256/512`. Modern ed25519 and `rsa-sha2`
  keys are what you should enroll with services such as GitHub.

```sh
ssh-keygen -t ed25519 -C "my phone"     # ed25519 key pair
ls ~/.ssh/                              # id_ed25519  id_ed25519.pub
cat ~/.ssh/id_ed25519.pub               # the public key you upload to services
```

## The agent: `ssh-agent` and `ssha`

The `openssh` package prepares a runit service script for `ssh-agent` under
`$PREFIX/var/service/`. With [termux-services](10-databases.md) (runit)
installed:

```sh
pkg install termux-services
sv-enable ssh-agent
```

- The service exports
  `SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-$PREFIX/var/run}/ssh-agent.socket"`,
  unlinks a stale socket (a workaround for "Address already in use" after a
  reboot or force-stop), then runs `ssh-agent -D -a "$sock"`.
- After enabling, export `SSH_AUTH_SOCK="$PREFIX/var/run/ssh-agent.socket"` in
  your shell config, then `ssh-add` your key(s) once; the agent persists across
  sessions. Start behavior can be overridden by creating
  `$PREFIX/etc/ssh/start_agent.sh` defining `service_agent()`.
- Alternative helpers that start an agent per-invocation without any persistent
  service: `ssha`, `scpa`, and `sftpa` — symlinks to
  `$PREFIX/libexec/wrap-ssh-agent.sh` that run `ssh`/`scp`/`sftp` under an
  automatically-started agent.
- You can also use `ssh -o AddKeysToAgent=yes` with a running agent.

## Running an SSH server on the phone

Termux's `sshd` runs as your normal unprivileged user and listens on the
compiled-in default port **8022** (the packaged `sshd_config` shows
`#Port 8022`). Binding a privileged port would be impossible without root, so
the Termux build moves the default.

```sh
# one-off start (after host keys exist from the postinst)
sshd

# or, as a persistent service under termux-services:
pkg install termux-services
sv-enable sshd            # starts `sshd -D -e` via runit
```

- **Host keys** are generated by the `openssh` postinst if missing
  (`ssh-keygen -N '' -t <type> -f $PREFIX/etc/ssh/ssh_host_<type>_key` for
  rsa/ecdsa/ed25519).
- **Password logins** are handled by **`termux-auth`**, not PAM. Set a
  password with `passwd` (from the `termux-auth` package), then enable
  `PasswordAuthentication yes` in `$PREFIX/etc/ssh/sshd_config`.
  `[needs verification]` for the exact requirement wording; the `termux-auth`
  library validates the password directly. The community-reported password
  hash file is `~/.termux_authinfo`. **[DEVICE]** — passwords over the network
  are discouraged; prefer keys whenever possible.
- Reboot persistence requires the service manager (`sv-enable sshd`), and even
  then Android may stop the daemon — see
  [Development Environment and Constraints](01-development-environment-and-constraints.md#background-execution-and-process-limits).
- From a computer: `ssh -p 8022 user@phone-ip`, where `user` is your Termux
  **app user** (see `whoami`), and the phone is reachable on the LAN.

> Inside a proot-distro guest, `sshd` would be the *guest's* sshd with the
> guest's config and paths — a different environment entirely (see the
> constraints chapter). Remote access to the *phone* normally means Termux's
> own `sshd` on port 8022.

## Security notes

- Prefer **key authentication** over passwords; if you enable passwords, use a
  strong `passwd`.
- Verify host key fingerprints when you first connect (fetching them for
  GitHub is a `[needs verification]` item in the research).
- `sshd` on your phone exposes a shell — only enable it on networks you trust,
  or restrict it with `~/.ssh/authorized_keys` for the specific computers you
  allow.
- Background daemons are subject to Android's battery and process limits
  **[DEVICE]**.

## Related tools

- **`mosh`** (1.4.0): mobile shell over SSH for flaky networks. It bootstraps
  over SSH, so a reachable `sshd` on the target is required first, then it
  switches to its own protocol over UDP — the relevant UDP ports must be open.
  **[DEVICE]**
- **`tmate`** (2.4.0-3): tmux-based terminal sharing for pair sessions. Exact
  web-client/pairing handshake details `[needs verification]` **[DEVICE]**.
- **`opkssh`** (0.16.0, OpenPubkey SSH): authenticate SSH with an OpenID
  Connect identity (e.g. a Google account) using a certificate bound to an
  OIDC token; intended for `sshd`'s `AuthorizedKeysCommand`. Niche and
  experimental — document with version caveats.
- **`pinentry`** (for GPG passphrases): package exists; on-terminal behavior
  **[DEVICE]** `[needs verification]`.

## Cross-references

- Git over SSH, GitHub key enrollment, SSH commit signing:
  [Git and GitHub](../11-git-github/00-intro.md)
- `ssh`/`scp`/`sftp` install notes from the shell Bible:
  [Networking](../02-shell/07-networking.md)
- The `~/.ssh` path and `$PREFIX/var/run` context:
  [The Filesystem](../00-foundations/03-filesystem.md)
- Keeping daemons alive: [Processes and Sessions](../00-foundations/06-processes-and-sessions.md),
  [Development Environment and Constraints](01-development-environment-and-constraints.md#background-execution-and-process-limits)

## References

- Phase 7 research notes: `research/development/01-ssh-research.md`
  (§3–§10: openssh packaging, termux-auth, runit services, keygen defaults,
  opkssh/mosh/tmate).
- OpenSSH `ssh-keygen(1)` man page (confidence on defaults),
  GitHub docs "About SSH" and "About commit signature verification".
- Termux packaging facts verified against `termux/termux-packages` master
  `packages/openssh/` and `packages/termux-auth/build.sh`, and the
  `termux-main` index, fetched 2026-09-22.