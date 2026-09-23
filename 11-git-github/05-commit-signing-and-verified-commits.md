# Commit Signing and Verified Commits

Git can sign commits and tags cryptographically, and GitHub shows signing on
the website with a **"Verified"** badge. Git supports signing with **GPG/PGP**,
**X.509 (S/MIME)**, or **SSH keys**. SSH-key signing is the simplest for most
individual users — it reuses the key you already enrolled with GitHub and
needs no separate GPG identity.

- SSH signing requires **Git 2.34+**; the Termux `git` (2.55.0) satisfies
  this. **[version-sensitive]**
- Git's `gpg.format` defaults to `openpgp` (GPG); `commit.gpgSign` and
  `tag.gpgSign` are opt-in booleans. `git commit -S` / `git tag -s` do it
  per-command.
- GitHub changes which signatures it accepts over time as policy evolves;
  exact verification-status wording is `[needs verification]` for the 2026
  UI, so treat the UI labels below as representative.

## Signing commits with an SSH key

```sh
git config --global gpg.format ssh                     # sign with SSH keys
git config --global commit.gpgsign true               # sign commits by default
git config --global tag.gpgsign true                  # and tags
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git commit -m "signed commit"                          # a signed commit
```

What each line means (git 2.55.0 semantics):

- `gpg.format ssh` selects SSH keys as the signing format.
- `commit.gpgsign true` / `tag.gpgsign true` turn signing on by default;
  `-S` / `-s` do it for a single command.
- `user.signingkey` is the **public** key that corresponds to the **private**
  key doing the signing (`~/.ssh/id_ed25519.pub`). If it is unset, Git calls
  `gpg.ssh.defaultKeyCommand` (for example `ssh-add -L`) and uses the first
  listed key. You can also write `key::ssh-ed25519 AAAA… identifier`
  directly; a bare value starting `ssh-` is treated as `key::ssh-…` but that
  shorthand is deprecated.
- `gpg.ssh.program` defaults to `ssh-keygen`, so no separate tool is needed
  for SSH signing.

## Verifying locally

```sh
git verify-commit HEAD          # verify a commit signature
git verify-tag v1.0.0           # verify a tag signature
git log --show-signature -1     # show signature info in the log
```

- Local SSH verification consults `gpg.ssh.allowedSignersFile`: a file of
  trusted public keys in `ssh-keygen(1)` ALLOWED SIGNERS format. A key that is
  in the file with trust level `fully` verifies; otherwise verification fails
  (`[needs verification]` on the exact wording of failure output across Git
  versions).

## Enrolling the signing key with GitHub

For GitHub to show **"Verified"**, the commit's signature must be good **and**
the public key must be registered as a **Signing key** on the account:

- GitHub → Settings → SSH and GPG keys → New SSH key, and add
  `~/.ssh/id_ed25519.pub` again, this time as a *Signing key*.
- You may have the same key listed as both an authentication key and a signing
  key. See [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)
  for the enrollment flow.
- GitHub's badge states include "Verified" (signature good + registered
  signing key), "Partially verified" for subordinate states, and — with
  **vigilant mode** enabled — makes unverified commits stand out. GPG, SSH,
  and S/MIME are the supported signing methods. **[needs verification]** on
  exact current UI wording.

## Signing with GPG instead (heavier alternative)

```sh
pkg install gnupg                                   # gnupg 2.5.17, verified in termux-main
gpg --full-generate-key                             # create a key pair
gpg --armor --export your@example.com | termux-clipboard-set   # export public key
```

- Switch Git to `gpg.format = openpgp` (the default) and set
  `user.signingKey` to the GPG key id; upload the armored public key to the
  account's GPG keys for verification.
- GPG signing needs a way to enter your passphrase (`pinentry`); terminal
  pinentry behavior on device is **[DEVICE]** `[needs verification]`.
  SSH signing sidesteps all of this, which is why this chapter recommends it.

## Security notes

- A signature proves the commit came from whoever holds the **private key** —
  protect it (passphrase + agent, see
  [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)).
- GitHub badges are a UI convenience; local verification happens with
  `git verify-commit`. Trust the badge only as strong as you trust the key
  enrollment, and fingerprints in `~/.ssh/known_hosts`.

## Cross-references

- Creating and enrolling the key: [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)
- GPG's passphrase tooling: [SSH and Remote Access](../08-power-tools/02-ssh-and-remote-access.md)
- `user.signingKey` vs `user.name`/`user.email`:
  [Git Installation and Setup](01-git-installation-and-setup.md)

## References

- Phase 7 research notes:
  `research/development/01-ssh-research.md` (§8–§9),
  `research/development/00-git-github-research.md` (§4).
- git `git-config(1)` man page (git 2.55.0) for `gpg.format`,
  `gpg.ssh.program`, `gpg.ssh.allowedSignersFile`, `user.signingKey`,
  `commit.gpgSign`, `tag.gpgSign`; GitHub docs "About commit signature
  verification", fetched 2026-09-22.