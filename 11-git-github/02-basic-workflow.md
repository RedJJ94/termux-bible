# The Basic Workflow

This chapter assumes [Git Installation and Setup](01-git-installation-and-setup.md)
is done: `git`, a `user.name`/`user.email`, and a `core.editor`. All commands
here are standard Git behavior (git 2.55.0 semantics per the `git-config(1)`
man page); the Termux-specific bits are the pager/editor defaults and the
`$HOME` path context.

## Start: initialize or clone

```sh
git init                                    # new repository in the current dir
git clone https://github.com/user/repo.git  # copy an existing repository
git clone git@github.com:user/repo.git      # same over SSH
```

- `git init -b main` creates the repository with `main` as the default branch
  (or set `init.defaultBranch`).
- Cloning creates a remote named `origin` and a local `main`/`master` tracking
  the remote branch.

## The daily loop

```sh
git status                       # what is changed/staged
git add file.txt                 # stage a file
git add -p                       # stage hunks interactively (needs perl)
git commit -m "message"          # commit staged changes
git log --oneline -10            # recent history
git diff                         # unstaged changes
git diff --staged                # staged changes
```

- `git commit` with no `-m` opens `core.editor`; without the editor/pager
  setup on a fresh install it fails (see
  [Git Installation and Setup](01-git-installation-and-setup.md#the-editor-and-pager-quirk-read-this)).
- `git add -p`'s interactive hunk editing is one of the features that need the
  SUGGESTED `perl` package.

## Branches and switching

```sh
git branch                          # list branches
git branch feature-x                # create a branch
git switch feature-x                # switch to it  (git checkout feature-x still works)
git switch -c fix/y                 # create + switch
git branch -d feature-x             # delete a (merged) branch
```

`git switch` (the modern command) and `git checkout` both work; `switch`
cannot do the detached-HEAD side-effect of `checkout`, which makes it safer
for day-to-day branch moves.

## Merging and rebasing

```sh
git switch main && git merge feature-x     # merge feature-x into main
git switch feature-x && git rebase main    # replay feature-x on top of main
```

- **`git merge`** combines histories and creates a merge commit (or
  fast-forwards when possible). Conflicts are marked in files; resolve, then
  `git add` the resolved files and `git commit`.
- **`git rebase`** replays your commits onto another base and rewrites your
  branch's commit chain; `rebase` is linear and clean for feature branches,
  prefers `--interactive` (`git rebase -i`) for reordering/squashing.
- Rebase history is your local branch's; do **not** rebase shared branches that
  others pull from. When in doubt, keep published branches merged, private
  ones rebased.
- A diverging `git pull` may ask you to choose: `git pull --rebase` (linear)
  vs `git pull` (merge).

## Remotes and syncing

```sh
git remote -v                     # show remotes
git remote add origin https://... # add a remote
git remote set-url origin git@github.com:user/repo.git   # change the URL / protocol
git fetch origin                  # download remote refs (no merge)
git pull                          # fetch + merge the tracking branch
git push origin main              # upload your commits
git push -u origin feature-x      # push upstream and set tracking
```

- `git push`/`git fetch` over HTTPS require credentials
  ([HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md));
  over SSH they use your key
  ([SSH Authentication and Keys](04-ssh-authentication-and-keys.md)).
- `git pull --rebase` is often the smoothest habit for personal branches.

## Tags

```sh
git tag v1.0.0              # lightweight tag
git tag -a v1.0.0 -m "1.0"  # annotated tag (recommended for releases)
git push origin v1.0.0      # push a tag
git push --tags             # push all tags
git tag -l                  # list tags
```

Annotated tags are the ones meant for shipping releases; see
[Releases and GitHub Actions](07-github-releases-and-actions.md).

## Pull requests

Pull requests are a **GitHub** concept on top of Git: push a branch, then open
the PR. The fastest path from Termux uses the GitHub CLI:

```sh
git switch -c feature-x
git add . && git commit -m "Add feature"
git push -u origin feature-x
gh pr create --title "Add feature" --body "…"   # opens the PR, prints its URL
gh pr list && gh pr merge --merge               # list / merge PRs
```

See [GitHub CLI](06-github-cli.md) for `gh` setup and the full command set.

## A note on output

- `git log`/`git diff` page through `core.pager` (set `less` in the setup
  chapter). Inside Termux's terminal, colored output works normally; over SSH
  it follows the SSH client's terminal.
- For an alternative diff presentation, `git-delta` can be configured as the
  pager (see
  [Repository Maintenance and the Git Ecosystem](08-repository-maintenance-and-git-ecosystem.md)).

## Cross-references

- Credentials you will need before the first `push`:
  [HTTPS Authentication and Credentials](03-https-authentication-and-credentials.md)
- Keys for SSH remotes: [SSH Authentication and Keys](04-ssh-authentication-and-keys.md)
- Marking commits: [Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md)
- Repository health: [Repository Maintenance and the Git Ecosystem](08-repository-maintenance-and-git-ecosystem.md)

## References

- Phase 7 research notes §3–§6:
  `research/development/00-git-github-research.md`.
- git `git-config(1)` man page for git 2.55.0 (git-scm.com), fetched
  2026-09-22.