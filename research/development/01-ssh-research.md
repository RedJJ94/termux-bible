# SSH (client, sshd, agents, keys, signing) — Research Notes (Phase 7)

Status: research notes supporting Phase 7 (PLAN.md §12 "SSH", §14 SSH
servers/remote access, §15 SSH authentication/keys/commit signing/verified
commits). Not polished documentation; kept separate from Bible chapters per
AGENTS.md §17 / PLAN.md §21.

Compiled: 2026-09-22. Environment note: research performed from a proot
(Ubuntu) container with **no physical Android device or emulator**. Items
needing a live device/internet/boot are tagged **[DEVICE]**; Android and
OpenSSH-version-dependent behavior is tagged **[version-sensitive]**; OEM
behavior **[OEM]**; unresolved items `[needs verification]`.

Audit note: all Termux `openssh` packaging facts were verified against the
`termux/termux-packages` master `packages/openssh/` build files (build.sh and
patches) and the `termux-auth` build.sh, fetched 2026-09-22. ssh-keygen
defaults were verified against the current OpenSSH man page (fetched
2026-09-22; the man page adds `mldsa44-ed25519`, i.e. OpenSSH 9.9+). GitHub
signing/verification semantics were verified against official GitHub docs.

Cross-reference: git commit signing with SSH keys is configured via git config
(`research/development/00-git-github-research.md` §4); this file adds the SSH
key/signing mechanics.

---

## 1. Scope

PLAN.md §15 SSH items and related Phase 7 topics: the Termux `openssh`
package (client + daemon), default port, config locations, runit services for
`sshd` and `ssh-agent`, password authentication via `termux-auth`, generating
and using SSH keys (`ssh-keygen` defaults), connecting to GitHub/GitLab over
SSH, SSH-based commit signing and GitHub verification, and helper tools
(`ssh-copy-id`, `ssha`/`scpa`/`sftpa` wrappers, `opkssh`, `mosh`, `tmate`).
Environment delineation per AGENTS.md §6/§10: Termux sshd is a normal
user-space daemon (not ADB/rish/Shizuku/Porter/root).

## 2. Source Inventory and Reliability Ranking

| Ref | Source | Kind | Fetched via |
|-----|--------|------|-------------|
| A1 | `termux/termux-packages` `packages/openssh/build.sh` | A | raw.githubusercontent.com |
| A2 | `termux/termux-packages` `packages/openssh/*.patch`: `sshd_config.patch`, `ssh_config.patch`, `servconf.c.patch`, `defines.h.patch`, `auth-passwd.c.patch`, `pathnames.h.patch` | A | raw.githubusercontent.com |
| A3 | `termux/termux-packages` `packages/openssh/sv/sshd.run.in`, `sv/ssh-agent.run.in`, `source-ssh-agent.sh`, `wrap-ssh-agent.sh` | A | raw.githubusercontent.com |
| A4 | `termux/termux-packages` `packages/termux-auth/build.sh` | A | raw.githubusercontent.com |
| A5 | OpenSSH `ssh-keygen(1)` man page (current, OpenSSH 9.9+/10.x: default key type, `-A`, RSA default bits, key formats) | A | man.openbsd.org |
| A6 | GitHub docs "About SSH" and "About commit signature verification" | A | docs.github.com |
| A7 | OpenSSH 8.2 release notes (SHA-1 `ssh-rsa` deprecation; rsa-sha2-512 default) | A | openbsd.org |
| A8 | termux-packages issues: #27653 (ssh-agent docs mismatch), #20758 (password auth regression), termux-app #2366 (cross-ref, phantom process) | B | GitHub |
| A9 | `termux/termux-packages` `packages/opkssh/build.sh`, `packages/mosh/build.sh`, `packages/tmate/build.sh`, `packages/gnupg/build.sh` | A | raw.githubusercontent.com |
| A10 | `termux-main` index (versions: openssh 10.5p1, gnupg 2.5.17, opkssh 0.16.0, mosh 1.4.0, tmate 2.4.0-3) | A | packages.termux.dev |

## 3. openssh Package (client + server)

Verified from [A1][A2][A10].

- Package: `openssh`, version 10.5p1. DEPENDS: `krb5, ldns, libandroid-support,
  libedit, openssh-sftp-server, openssl, termux-auth, zlib`. SUGGESTS:
  `termux-services`. CONFLICTS: `dropbear` (both provide an sshd).
- Config lives in `$PREFIX/etc/ssh` (`--sysconfdir=$PREFIX/etc/ssh`);
  `etc/ssh/ssh_config` and `etc/ssh/sshd_config` are registered conffiles.
  Pid dir `$PREFIX/var/run`; privilege-separation dir `$PREFIX/var/empty`;
  default PATH `$PREFIX/bin`; xauth `$PREFIX/bin/xauth`; `PATH_PASSWD_PROG =
  $PREFIX/bin/passwd`.
- **Default port is 8022, compiled in**: `servconf.c.patch` replaces
  `SSH_DEFAULT_PORT` (22) with `8022` in the config parser defaults. The
  shipped `sshd_config` shows `#Port 8022`. This is why Termux sshd does not
  need root to bind.
- Drop-in include dirs: build creates `$PREFIX/etc/ssh/ssh_config.d/` and
  `$PREFIX/etc/ssh/sshd_config.d/`. The packaged config files contain
  `Include /etc/ssh/sshd_config.d/*.conf` and
  `Include /etc/ssh/ssh_config.d/*.conf` (added by [A2]); note the literal
  `/etc/ssh` path — on Android these directories normally do not exist and are
  not writable without root, so the Include is expected to be inert unless the
  device provides `/etc/ssh`. **Recommend documenting that user drop-ins go in
  `$PREFIX/etc/ssh/*.d/`** `[needs verification]` `[OEM]`.
- Host keys: postinst generates `$PREFIX/etc/ssh/ssh_host_{rsa,ecdsa,ed25519}_key`
  (empty passphrase) if missing, using `ssh-keygen -N '' -t $a -f $KEYFILE`.
  `sshd` is installed with `install-nokeys` target; keys are only from postinst.
- Also installed: `$PREFIX/bin/ssh-copy-id` (built from contrib script,
  `SANE_SH` patched to `$PREFIX/bin/bash`), `sftp-server` (subpackage
  `openssh-sftp-server`), `moduli` file.
- `ssha`/`scpa`/`sftpa` are symlinks to `$PREFIX/libexec/wrap-ssh-agent.sh`:
  these run `ssh`/`scp`/`sftp` under an automatically-started ssh-agent
  (`source-ssh-agent.sh`), intended for use when no persistent agent is
  running [A3].

## 4. Password Authentication and termux-auth

Verified from [A1][A2][A4][A8].

- Termux sshd implements password auth through **termux-auth**, not PAM
  (the openssh build does not configure PAM; the packaged `sshd_config`
  removes the `UsePAM` comments). `auth-passwd.c.patch` adds a
  `#ifdef __TERMUX__` branch to `sys_auth_passwd()` that `#include`s
  `<termux-auth.h>` and calls `termux_auth(user, password)` directly —
  i.e. password verification is delegated to the termux-auth library rather
  than the external `passwd` program's PAM path. The patch also guards: if the
  recorded user's uid is 0 but the account name is not `root`, login is
  refused.
- The `passwd` command comes from the `termux-auth` package (1.5.0; DEPENDS
  `openssl`; defines `TERMUX_HOME` and `TERMUX_PREFIX` at build).
- Community reports: `~/.termux_authinfo` stores the password hash
  [B-level, needs verification on device] [DEVICE]. Password auth had a
  known regression in some 2021–2022 versions (issue #20758) fixed in later
  releases `[version-sensitive]`.
- Enabling password logins on the device: set a password with `passwd`, then
  in `$PREFIX/etc/ssh/sshd_config` set `PasswordAuthentication yes`
  [standard openssh semantics; exact Termux requirement `[needs verification]`].

## 5. Running sshd and ssh-agent under termux-services (runit)

Verified from [A3][A1].

- `termux-services` (separate package, SUGGESTED by openssh) provides runit.
  `openssh` postinst prepares services under `$PREFIX/var/service/`:
  - `sshd/run`: `exec sshd -D -e 2>&1`.
  - `ssh-agent/run`: exports
    `SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-$PREFIX/var/run}/ssh-agent.socket`, unlinks
    a stale socket (workaround for "Address already in use" after reboot or
    force-stop), then `exec ssh-agent -D -a "$sock"`. Start behavior can be
    overridden by creating `$PREFIX/etc/ssh/start_agent.sh` defining
    `service_agent()`.
  - Services are created with a `down` file; enable with
    `sv-enable sshd` and `sv-enable ssh-agent` (as the openssh postinst text
    instructs).
- Using the agent service: after
  `sv-enable ssh-agent`, export
  `SSH_AUTH_SOCK="$PREFIX/var/run/ssh-agent.socket"` in the shell config, then
  `ssh-add` keys once; the agent persists across sessions.
- Starting sshd manually (no termux-services): `sshd` (after host keys
  exist). Reboot persistence requires the service manager; Android may kill
  background daemons — see `research/development/05-termux-android-dev-constraints-research.md`
  and `research/termux/00-foundations-research.md` (phantom process killer,
  Android 12+).

## 6. SSH Keys (generation and defaults)

Verified from [A5][A7].

- `ssh-keygen` with **no `-t` option generates an Ed25519 key** ("If invoked
  without any arguments, ssh-keygen will generate an Ed25519 key"). The `-t`
  option accepts `ecdsa, ecdsa-sk, ed25519 (the default), ed25519-sk,
  mldsa44-ed25519, rsa`. RSA default size is 3072 bits (min 1024).
  `[version-sensitive]`: default changed over time (older versions defaulted to
  RSA).
- Host keys: `ssh-keygen -A` generates host keys of all default types
  (`rsa, ecdsa, mldsa44-ed25519, ed25519`) if absent.
- Key files: modern private keys are written in OpenSSH's native format by
  default; PEM via `-m`. Comment defaults to `user@host`; set with `-C`.
- The SHA-1-based `ssh-rsa` signature algorithm is deprecated in OpenSSH
  (8.2+, [A7]); RSA signing falls back to `rsa-sha2-256/512`. Practical note:
  GitHub accepts modern ed25519 and rsa-sha2 keys.
- Recommended GitHub flow (via [A6], GitHub docs): `ssh-keygen -t ed25519 -C
  "comment"` → add the `.pub` key to GitHub account → test
  `ssh -T git@github.com`. host key fingerprint verification `[needs verification]` for
  exact GitHub current fingerprints.
- `ssh-keyscan`/`ssh-add`/`ssh-keysign` standard semantics apply. Agent:
  `ssh -o AddKeysToAgent=yes` or the runit service (§5) or `ssha`.

## 7. Using SSH for Git (GitHub/GitLab)

- Standard pattern: host alias block in `$HOME/.ssh/config` with
  `Host github.com / HostName github.com / User git / IdentityFile
  ~/.ssh/id_ed25519`. Then `git remote add origin git@github.com:user/repo`
  works. Termux-specific factor: `$HOME` is the Termux data home
  (`~/storage` is NOT `$HOME`; AGENTS.md §7) and `$PREFIX/var/run` holds the
  agent socket (§5).
- Git passes ssh config transparently; openssh is a hard RECOMMEND of `git`
  (see `00-git-github-research.md` §3).

## 8. Commit Signing with SSH Keys and GitHub Verification

Verified from [A5][A6] plus [A10] git-config facts.

- Git supports signing with GPG/PGP, X.509 (S/MIME), or **SSH keys**
  (`gpg.format = ssh`). SSH is the simplest for individuals since no separate
  GPG identity is created; GitHub verifies commits signed with an SSH key
  whose public key is added to the account (signing keys). SSH signing
  requires **Git 2.34+** [A6]; Termux git 2.55.0 satisfies this.
- Git config for SSH signing (git 2.55.0 semantics, `00-git-github-research.md`
  §4):
  - `git config --global gpg.format ssh`
  - `git config --global user.signingkey ~/.ssh/id_ed25519.pub` (path to the
    public key that corresponds to the private key that does the signing), or
    `key::ssh-ed25519 AAAA... identifier` directly. If unset, git calls
    `gpg.ssh.defaultKeyCommand` (e.g. `ssh-add -L`) and uses the first key.
    A raw value starting `ssh-` is treated as `key::ssh-...` but that form is
    deprecated.
  - `git config --global commit.gpgsign true` (spelled `commit.gpgSign`);
    `tag.gpgsign true` similarly. `git commit -S`, `git tag -s` per-command.
  - `gpg.ssh.program` defaults to `ssh-keygen` (no separate tool needed);
    `gpg.ssh.allowedSignersFile` lists trusted public keys for verification
    (format per ssh-keygen(1) ALLOWED SIGNERS; trust level `fully` when the
    key is in the file, otherwise verification fails with
    `git verify-commit`/`verify-tag`).
- GitHub verification statuses: a commit is shown as **"Verified"** when its
  signature is good and the key is a registered signing key on the account;
  "Partially verified" may appear for subordinate states; **Vigilant mode**
  makes unverified commits more obvious. GPG, SSH, and S/MIME are the
  supported signing methods [A6]. Exact GitHub UI wording `[needs verification]`.
- Termux note: nothing device-specific is required for signing; keys live in
  `~/.ssh`, optional passphrase via agent.

## 9. GPG (alternative signing)

- Package `gnupg` 2.5.17 [A10][A9]. Signing as in §8 with
  `gpg.format = openpgp` (default) and `user.signingKey` = GPG key id; GitHub
  requires the public key uploaded to the account's GPG keys. GPG is heavier
  than SSH signing (key pairs, pinentry). `pinentry` package exists
  (`pinentry`/`pinentry-termux`? — only the main `pinentry` was verified;
  terminal pinentry availability `[needs verification]`).

## 10. Opkssh, Mosh, Tmate

Verified [A1][A9][A10].

- `opkssh` 0.16.0 (OpenPubkey SSH): authenticates SSH via OpenID Connect
  (Google account etc.) by using a public-key certificate bound to an OIDC
  token; intended for `sshd`'s `AuthorizedKeysCommand`. Niche/experimental;
  document with caution and current-version caveats.
- `mosh` 1.4.0: mobile shell over SSH (DEPENDS `abseil-cpp, libandroid-support,
  libc++, libprotobuf, ncurses, openssl, openssh | dropbear`; SUGGESTS
  `mosh-perl`). The server side (`mosh-server`) must run on the target, and
  mosh bootstraps over SSH, so an sshd must be reachable first; after the
  handshake mosh switches to its own protocol over UDP, so the relevant UDP
  ports must be open `[DEVICE]`.
- `tmate` 2.4.0-3: terminal sharing (tmux-based); DEPENDS
  `libandroid-support, libevent, libmsgpack, libssh, ncurses`. Session
  sharing handshake details and web-view clients `[needs verification]` `[DEVICE]`.

## 11. Unresolved / Device-Verified Items

- Literal `/etc/ssh` Include behavior on Android devices `[OEM]` `[DEVICE]`
  `[needs verification]`.
- `~/.termux_authinfo` layout and `passwd` interaction `[DEVICE]`.
- Exact GitHub allowed-signers / signing-key enrollment flow wording `[needs verification]`.
- sshd stability under Android background limits and Battery restrictions
  `[DEVICE]` (see constraints file §05).
- `pinentry` terminal behavior on device `[DEVICE]`.
- GitHub host key fingerprints for `known_hosts` practice `[needs verification]`.