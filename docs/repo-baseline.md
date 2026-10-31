# Repository and organization baseline

What every public repository in `eggs-gd` has, and why. [`scripts/repo-baseline.sh`](../scripts/repo-baseline.sh)
and [`scripts/org-baseline.sh`](../scripts/org-baseline.sh) apply it; this file is the
spec, so when one changes the other changes in the same pull request.

Private repositories are outside the baseline: rulesets and code security are paid
features there. When a private repository goes public, run the scripts on it.
A repository that has no branches, pull requests or merges needs none of it.

## Repository

Per repository, by `repo-baseline.sh`:

| Setting | Value | Why |
|---|---|---|
| Ruleset `main: PR, squash only`, on the default branch | see below | `main` is never pushed to directly, history stays linear |
| Automatically delete head branches | on | merged branches do not pile up |
| Allow updating the branch | on | the **Update branch** button, needed by strict checks |
| Secret scanning and push protection | on | a pushed key is caught before it is public |
| Private vulnerability reporting | on | [SECURITY.md](../SECURITY.md) points to it |

### The ruleset

- Changes go through a pull request. No approvals are required (there is one maintainer),
  but **review conversations must be resolved**, and only **squash** merge is allowed.
- Linear history; the branch cannot be deleted or force-pushed.
- Optional required status check, `--check "<name>"`, with the branch required to be up
  to date before merging (**strict**, on by default). Strict is what makes parallel pull
  requests safe: the second one cannot merge until it has been rebuilt on top of the first.
  `--no-strict` turns it off.
- `--security` also turns on Dependabot alerts and CodeQL for a repository the organization's
  configuration does not cover (one of a personal account).
- The repository admin role can bypass, **only through a pull request** (`bypass_mode: pull_request`),
  so a stuck pull request can be merged by the owner but a direct push is still refused.

The check name is the one GitHub lists on a pull request: `build` for a plain job, `build / build` when the
job comes from a called workflow (copy it from the checks list). A required check that
does not run on a pull request blocks that pull request forever, so a repository whose CI
only runs for some paths has no required check.

## Organization

By `org-baseline.sh`, which needs `gh auth refresh -h github.com -s admin:org`:

- **Actions**: the default `GITHUB_TOKEN` is read-only, and workflows cannot approve pull
  requests. A workflow that needs more asks for it in its own `permissions:` block.
- **Code security configuration `eggs-gd baseline`**: secret scanning with push protection,
  Dependabot alerts, dependency graph, CodeQL (default setup), private vulnerability
  reporting. Attached to every public repository and the default for new public ones.
  CodeQL also watches the repositories we are not actively working on; for the active ones
  it stays quiet. Dependabot security updates are left off.

## New public repository

1. Create it in the organization with a `README`, a licence and a `.gitignore`.
2. Give it an `AGENTS.md` (see [working rules](working-rules.md#agents)).
3. Add a CI workflow that builds on pull requests, run it once, and note the job's name.
4. `scripts/repo-baseline.sh <repo> --check "<job name>"`.
5. The organization's security configuration and the default community files apply by themselves.
