# SSH Authentication and Keys

SSH is the recommended authentication method for Git remotes on Termux: once
your public key is enrolled with GitHub, no tokens need to be typed or stored,
and `git push`/`fetch`/`clone` over SSH is automatic. The `openssh` toolset's
general behavior is documented in
[SSH and Remote Access](../08-power-tools/02-ssh-and-remote-access.md); this
chapter is the GitHub/Git angle.

## 1. Generate a key (if you do not have one)

```sh
pkg install openssh
ssh-keygen -t ed25519 -C "comment"      # -t ed25519 is the DEFAULT in current OpenSSH
```

- With **no `-t`, OpenSSH generates an Ed25519 key** (`~/.ssh/id_ed25519` +
  `~/.ssh/id_ed25519.pub`). **[version-sensitive]** — older OpenSSH defaulted
  to RSA; the default changed over time.
- The **public key** (`~/.ssh/id_ed25519.pub`) is the part you give to GitHub;
  the private key (`~/.ssh/id_ed25519`) never leaves the device.
- The old SHA-1 `ssh-rsa` signature algorithm is deprecated (OpenSSH 8.2+),
  falling back to `rsa-sha2-256/512`. GitHub accepts modern ed25519 and
  rsa-sha2 keys.

## 2. Enroll the public key with GitHub

Copy the contents of `~/.ssh/id_ed25519.pub` (the whole line — type, base64,
comment) and add it under **GitHub → Settings → SSH and GPG keys → New SSH
key**. The same key can also be registered as a **Signing key**; that role is
covered in [Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md).

For convenient copying from Termux:

```sh
cat ~/.ssh/id_ed25519.pub        # select and copy the line
# or with the clipboard helper (Termux:API): termux-clipboard-set < ~/.ssh/id_ed25519.pub
```

## 3. Test the connection

```sh
ssh -T git@github.com
# Hi <username>! You've successfully authenticated, but GitHub does not
# provide shell access.
```

- This first connection asks you to trust GitHub's host key fingerprint.
  Verify it against GitHub's documented fingerprints — the exact current
  fingerprints are a `[needs verification]` item in the research — and add it
  to `~/.ssh/known_hosts` when the fingerprint matches.

## 4. Point Git at SSH

Add a host alias so `git` knows which key and user to use:

```sh
# $HOME/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
```

Then use SSH remote URLs:

```sh
git remote add origin git@github.com:user/repo.git    # SSH URL form
git remote set-url origin git@github.com:user/repo.git   # switch an HTTPS remote
git clone git@github.com:termux/termux-app.git
git push -u origin main
```

- Git passes SSH configuration through transparently (the `openssh` package is
  a declared `RECOMMENDS` of `git`; see
  [Git Installation and Setup](01-git-installation-and-setup.md)).
- The `git@github.com:user/repo.git` form is the SSH URL; `https://github.com/…`
  is HTTPS. A single repository can switch between them with
  `git remote set-url`, which is how you migrate off HTTPS credential prompts.

## 5. Using the agent (so you are not asked for a passphrase each time)

If your key has a passphrase, an agent avoids re-prompting. Termux's
`openssh` ships a runit agent service:

```sh
pkg install termux-services
sv-enable ssh-agent
export SSH_AUTH_SOCK="$PREFIX/var/run/ssh-agent.socket"   # put this in ~/.bashrc
ssh-add ~/.ssh/id_ed25519                                 # one-time unlock
```

or use the per-invocation `ssha` wrapper, or `ssh -o AddKeysToAgent=yes`.
Full details are in [SSH and Remote Access](../08-power-tools/02-ssh-and-remote-access.md#the-agent-ssh-agent-and-ssha).

## Path caveat

- `$HOME` on Termux is `/data/data/com.termux/files/home`; your keys live at
  `$HOME/.ssh`. `~/storage` (`/storage/emulated/0`) is **not** where keys go —
  keep private keys in app-private storage, not shared storage (AGENTS.md §7).

## Security notes

- The **private key** must never be shared, committed, or copied to
  `~/storage`/shared storage. If a private key is exposed, remove it from the
  device, delete the public entry from GitHub, and generate a new pair.
- Use a passphrase on the private key and let the agent hold it, so a stolen
  file is not directly usable.
- `known_hosts` checking protects you from man-in-the-middle servers; verify
  GitHub's host key fingerprint before the first connection.

## Cross-references

- The full SSH toolset (sshd, agent, `ssh-keygen` defaults):
  [SSH and Remote Access](../08-power-tools/02-ssh-and-remote-access.md)
- Token-based alternative over HTTPS:
  [HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md)
- Signing commits with this same key:
  [Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md)

## References

- Phase 7 research notes:
  `research/development/01-ssh-research.md` (§6–§7),
  `research/development/00-git-github-research.md` (§7, cross-ref).
- OpenSSH `ssh-keygen(1)` man page and GitHub docs "About SSH", fetched
  2026-09-22.