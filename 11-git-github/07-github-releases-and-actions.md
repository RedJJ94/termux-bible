# Releases and GitHub Actions

Two GitHub workflows you can drive entirely from Termux: publishing
**releases** and **triggering/monitoring Actions**. Both build on the Git
setup from earlier chapters; releases build on tags, and Actions are driven
through the GitHub CLI.

## Releases via `gh`

A GitHub release attaches a tagged state of the repository to downloadable
assets and release notes. The one-command path is `gh release create`:

```sh
# From a repository that has a pushed tag (see Tags below):
gh release create v1.0.0 --title "1.0.0" --generate-notes
gh release create v1.0.0 --title "1.0.0" ./build/app.apk   # with an asset

gh release list                        # published releases
gh release view v1.0.0                 # details
gh release upload v1.0.0 artifact.zip  # add assets later
gh release download v1.0.0             # download assets
```

- Releases are created from **pushed tags**; if the tag does not exist yet,
  `gh release create` can create and push it first (gh handles this when you
  give it a new tag name).
- Assets such as a freshly built APK can be attached in the same command.
  **[DEVICE]**

### Tags (the Git side)

Tags are Git objects; releases point at them. From
[The Basic Workflow](02-basic-workflow.md):

```sh
git tag -a v1.0.0 -m "1.0.0"    # annotated tag with a message (preferred)
git push origin v1.0.0          # the tag must be pushed for a release
```

Annotated tags are recommended for releases because they carry a message,
tagger identity, and can be signed (see
[Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md)).
`gh release create` requires the tag to exist on the remote or supplies one.

### Releases via plain `git` (no gh)

If you do not use the GitHub CLI, publishing is still just tags + GitHub UI:
push an annotated tag, then create the release on the GitHub website from that
tag, uploading assets there. GitHub also supports a **tag push trigger** — see
below.

## GitHub Actions

The Actions engine runs on **GitHub's servers**, not on your device. From
Termux `gh` is the remote control — you trigger, list, and watch workflows
defined in the `.github/workflows/` directory of a repository:

```sh
gh workflow list                        # workflows in this repository
gh workflow run test.yml                # trigger a workflow (its on: works as usual)
gh run list --limit 5                   # recent runs
gh run watch                            # follow the newest run to completion
gh run view 1234567890 --log           # full logs of a run
gh run view 1234567890 --log-failed     # just the failed steps
```

- Workflows are **defined by YAML files committed to the repository**; `gh
  workflow run` respects the workflow's normal `on:` triggers but lets you
  start it manually with any declared inputs.
- Workflows commonly run on pushes, tag pushes, and PRs — so the commit/tag/push
  flow in [The Basic Workflow](02-basic-workflow.md) and this chapter's release
  steps are what actually **start** most builds.
- **Self-hosted runners on the phone** (running Actions jobs on the device
  itself) are out of scope for Phase 7 research `[needs verification]`; `gh`
  usage here assumes GitHub-hosted runners.

## Native Termux vs. proot

Releases and Actions have no on-device component beyond `git`/`gh`, both of
which are native Termux packages here. Inside proot-distro you would be using
the guest's `gh` and guest Git config — the workflows themselves still run on
GitHub.

## Security notes

- `gh release upload`/`gh workflow run` act with the authenticated account's
  authority — double-check the repository and tag names when releasing, since
  a release is a public, permanent artifact on public repositories.
- Pushing tags to a remote you do not own, or running `gh workflow run` on an
  untrusted branch, can trigger builds you do not control. Review what a
  workflow actually executes.

## Cross-references

- `gh` setup and authentication: [GitHub CLI](06-github-cli.md)
- Tag and branch mechanics: [The Basic Workflow](02-basic-workflow.md)
- Signing the tags you release: [Commit Signing and Verified Commits](05-commit-signing-and-verified-commits.md)

## References

- Phase 7 research notes §7 (gh release/workflow commands):
  `research/development/00-git-github-research.md`.
- gh manual (`gh release`, `gh run`, `gh workflow`) and git-scm tag docs,
  fetched 2026-09-22.