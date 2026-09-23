# HTTPS Authentication and Credentials

Git over HTTPS on Termux works out of the box for **anonymous pulls**
(`git clone https://…`). Pushing — or pulling a private repository — needs
authentication. This chapter is about the *HTTPS* path (credentials/tokens);
if you prefer keys, [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)
is the recommended alternative.

## The rules that matter

- **GitHub does not accept account passwords for Git operations.** You
  authenticate with a **personal access token** (fine-grained or classic PAT),
  an SSH key, or GitHub CLI's device-flow login.
  `[needs verification]` on the exact 2026 policy wording.
- **Termux has no OS keyring by default.** Git's default behavior is to prompt
  on the terminal for a username/password **once per command**; what you type
  there is *not stored*. That keeps secrets out of disk but is annoying for
  anything beyond a one-off push.

```sh
git clone https://github.com/user/private-repo.git   # prompts per operation
git push https://github.com/user/repo.git            # prompts again
```

## Option A: Git's `store` helper (simple, plaintext — careful)

```sh
git config --global credential.helper store
# next push stores credentials under $HOME/.git-credentials in PLAIN TEXT
```

- The token is written in clear text into the Termux **app-private** data dir
  (`$HOME/.git-credentials`). App-private data is not visible to other apps,
  but any process running under your UID can read it — and a backup of `$HOME`
  carries the token along.
- Prefer `store` only for throwaway tokens, and revoke them later.

## Option B: Git's `cache` helper (memory only, temporary)

```sh
git config --global credential.helper cache
git config --global credential.helper "cache --timeout=3600"
```

- Holds credentials in memory for the timeout (default 900 seconds); nothing
  hits disk and re-prompts happen after it expires.

## Option C: `gh` as the credential helper (recommended)

The GitHub CLI can act as Git's credential helper. Log in once with `gh`, then
make Git route HTTPS credentials through it:

```sh
pkg install git gh               # gh needs git; install both
gh auth login --git-protocol https   # device/browser flow, see GitHub CLI
gh auth setup-git                # configures credential.helper to use gh for github.com
git push                         # uses the stored gh token, no per-command prompt
```

See [GitHub CLI](06-github-cli.md) for how `gh` stores the token (first the
system credential store; on Termux typically a plain-text `hosts.yml` under
`$HOME/.config/gh`, unless `--insecure-storage` forces it).

## More about `credential.helper`

- Multiple helpers may be defined; helpers may be full paths or `!`-prefixed
  shell commands (git 2.55.0 semantics per `git-config(1)`).
- Conventional custom helper paths look like a program name found on `PATH`.
- Whatever you set, remember: a helper is a program that Git hands credentials
  to when it needs them — on Termux choose one whose storage you accept, and
  know how to revoke the token remotely on GitHub if the device is
  compromised.

## Typical recommended setup

For most Termux users, either:

1. **All-SSH:** convert the remote to an SSH URL
   (`git remote set-url origin git@github.com:user/repo.git`) and never deal
   with HTTPS credentials — see
   [SSH Authentication and Keys](04-ssh-authentication-and-keys.md); or
2. **`gh` managed:** `gh auth login` + `gh auth setup-git` (Option C).

Leave `store`/`cache` for quick throwaway work with tokens you can revoke.

## Security notes

- Treat any token stored on the device as sensitive: it grants what the token
  scopes allow. Prefer **fine-grained** PATs limited to the repos you use, and
  revoke obsolete ones.
- Never type tokens into files that get uploaded or shared; the examples in
  this Bible use placeholders.
- If a device with a stored token is lost, revoke the token from GitHub
  settings immediately.

## Cross-references

- Keys instead of tokens: [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)
- `gh auth setup-git` and token storage: [GitHub CLI](06-github-cli.md)
- The `libcurl`-based HTTPS transport: [Git Installation and Setup](01-git-installation-and-setup.md)
- `git-credential-manager` as an alternative helper:
  [Repository Maintenance and the Git Ecosystem](08-repository-maintenance-and-git-ecosystem.md)

## References

- Phase 7 research notes §6:
  `research/development/00-git-github-research.md`.
- git `git-config(1)` man page (git 2.55.0) for `credential.helper`;
  GitHub/gh docs for token and policy statements, fetched 2026-09-22.