# SonarQube

How the repositories of the organization are analysed with the maintainer's SonarQube. The server is
on a LAN, where GitHub's runners cannot reach it; a self-hosted runner next to it can (The runner).
The analysis runs in a repository's workflow, on that runner, once a commit is on GitHub. A commit
is checked before that, locally, by the pre-commit hook.
The files that must be identical in every repository are in [`sonarqube/`](../sonarqube/);
[`scripts/check-sonar.sh <checkout>`](../scripts/check-sonar.sh) says whether a repository's copy is.

## What a repository has

| | |
|---|---|
| a workflow calling [`sonarqube.yml`](../.github/workflows/sonarqube.yml) | the analysis: on a pull request, and on a push to the default branch (and a milestone branch, where there is one). It skips a change to the docs alone. Below. |
| `sonar-project.properties` | the project, its sources and tests, the report paths; **no host, no token**. [Template](../sonarqube/templates/sonar-project.properties). The key is a stable name of the project (it does not change with the repository's name, so the history does not break). |
| `make sonar` | tests with coverage, golangci-lint's report, the scan, the quality gate: what the workflow runs, and what runs by hand on a checkout to see the findings before a push. [Template](../sonarqube/templates/Makefile.sonar). Red gate: non-zero exit. `SONAR_GATE=false` sends the report without waiting for the gate. `SONAR_SCOPE` on the command line is what the analysis is of (the workflow sets it from the event); without it, `scripts/sonar-scope` says it for the checkout. |
| `scripts/sonar-scope` | says what a checkout is: the main branch, the pull request (when `gh` finds an open one), or the branch. **Canonical**: [`sonarqube/scripts/sonar-scope`](../sonarqube/scripts/sonar-scope). `SONAR_BRANCH_ONLY` (default `develop`) names a branch that is never read as a pull request. |
| `.golangci.yml` | golangci-lint v2; the same core everywhere ([template](../sonarqube/templates/golangci.yml)), the project's own exclusions below it, each with its reason. The core has `gocognit` at SonarQube's threshold, so a function too complex for `go:S3776` stops the commit. |
| `.githooks/pre-commit` | the local gate, below. The part between the `sonar:` markers is **canonical**: [`pre-commit`](../sonarqube/hooks/pre-commit). A repository with its own checks keeps them around it. |
| `.agents/skills/sonar/SKILL.md` | the agents' procedure. **Canonical**: [`sonarqube/skills/sonar`](../sonarqube/skills/sonar/SKILL.md), with a pointer in each adapter folder the repository uses ([adapters](../sonarqube/skills/sonar/adapters)). |
| `.gitignore` | `.scannerwork/`, `coverage.out`, `golangci-lint.xml`, `.env` ([template](../sonarqube/templates/gitignore)). |
| `CONTRIBUTING.md` | a "SonarQube (optional)" section: what to install for the local gate and for `make sonar` by hand. |
| `AGENTS.md` | a short pointer to the `sonar` skill. The rules themselves are in the skill. |

Enable the hooks per checkout: `git config core.hooksPath .githooks`.

## The gate: two steps

- **On a commit, locally.** The pre-commit hook runs golangci-lint on every Go module that has a
  staged `.go` file, on the lines changed since `HEAD` (what the commit brings, not what was there),
  and the secrets scan of the staged files (`sonar hook git-pre-commit`, when the SonarQube CLI is
  installed and `SONAR_HOST_URL` and `SONAR_TOKEN` are set). A finding stops the commit. Nothing goes
  to the server. A repository adds its own checks of the same kind around the canonical block: the
  linters of its other languages, with the rules SonarQube applies to them.
- **On GitHub, the server's.** The repository's workflow calls
  [`sonarqube.yml`](../.github/workflows/sonarqube.yml) on a pull request and on a push to the
  default branch. It runs on the runner: the toolchains, `make sonar` with the scope the event gives
  (the pull request with its base, the default branch, or another branch), and the quality gate. A
  red gate fails the job, and the server's check and comment land on the pull request: the commit
  is on GitHub by then.

The workflow needs the organization's secret `SONAR_TOKEN` and its variable `SONAR_HOST_URL`, the
server's address as the runner sees it (`http://sonarqube:9000`, on the compose network).

A repository calls it like this; `go-version-file` and `node-dir` say which toolchains to set up:

```yaml
name: SonarQube
on:
  pull_request:
    paths-ignore: ['**/*.md']
  push:
    branches: [main]
    paths-ignore: ['**/*.md']
jobs:
  sonarqube:
    uses: eggs-gd/.github/.github/workflows/sonarqube.yml@main
    with:
      go-version-file: go.mod
    secrets: inherit
```

## The runner

A self-hosted GitHub Actions runner in the server's compose project,
[`sonarqube/runner`](../sonarqube/runner/README.md). It connects out to GitHub and waits for jobs, so
nothing reaches in. It is registered on the organization, for its private repositories; the workflow
asks for it with `runs-on: [self-hosted, sonar]`. When it is down, the analysis waits in the queue;
the job is not a required check, so nothing waits on it to merge. A repository of a personal account
cannot use it: it needs a runner of its own (the runner's README).

## The pull request comment

The comments are written by the community branch plugin, with icons it serves from the server. On a
LAN GitHub cannot load them, so they show as broken images. The icons are in
[`sonarqube/images`](../sonarqube/images/NOTICE.md), and the server's setting **Administration →
Configuration → General → Pull Request → Images base URL** is
`https://raw.githubusercontent.com/eggs-gd/.github/main/sonarqube/images`. The comment's own links
(to the dashboard) still point at the LAN address: they open for whoever is on it.

## Answering a finding

On the line, with the reason: `// NOSONAR <why>`, or `//nolint:<linter> // <why>`. A rule wrong for a
class of files is scoped in `sonar-project.properties`, with the reason beside it. Never by closing
the issue on the server. Cognitive complexity of a `*_test.go` is not measured (`go:S3776`): a table
of cases reads as one function. The pull request's description says what the gate showed and how each
remaining finding was answered.

## Security

- Secret scanning, push protection, Dependabot alerts, CodeQL and private vulnerability reporting come
  from the organization's configuration for every public repository of `eggs-gd`
  ([repo-baseline](repo-baseline.md)). A repository of a personal account has none of that from the
  organization: `scripts/repo-baseline.sh` applies the repository's part to it.
- The token is never printed, logged or committed (`.env` is ignored, mode 600).
