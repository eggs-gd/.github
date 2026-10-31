# SonarQube

How the repositories of the organization (and the maintainer's own) are analysed with the
maintainer's SonarQube. The server is on a LAN, so there is **no analysis in CI**: it runs on the
maintainer's machine, and everywhere without `SONAR_HOST_URL` and `SONAR_TOKEN` it does nothing.
The files that must be identical in every repository are in [`sonarqube/`](../sonarqube/);
[`scripts/check-sonar.sh <checkout>`](../scripts/check-sonar.sh) says whether a repository's copy is.

## What a repository has

| | |
|---|---|
| `sonar-project.properties` | the project, its sources and tests, the report paths; **no host, no token**. [Template](../sonarqube/templates/sonar-project.properties). The key is a stable name of the project (it does not change with the repository's name, so the history does not break). |
| `make sonar` | tests with coverage, golangci-lint's report, the scan of the checkout, the quality gate. [Template](../sonarqube/templates/Makefile.sonar). Red gate: non-zero exit. `make sonar SONAR_GATE=false` sends the report without waiting for the gate. It leaves `.scannerwork/reports-head` (the commit its reports are of) for the next row. |
| `make sonar-publish` | the scan again on those reports, **after the push has finished**: no tests, no lint, no gate. It refuses when the reports are not of this commit or the commit is not on the remote. |
| `scripts/sonar-scope` | says what the checkout is: the main branch, the pull request (when `gh` finds an open one), or the branch. **Canonical**: [`sonarqube/scripts/sonar-scope`](../sonarqube/scripts/sonar-scope). `SONAR_BRANCH_ONLY` (default `develop`) names a branch that is never read as a pull request. |
| `.golangci.yml` | golangci-lint v2; the same core everywhere ([template](../sonarqube/templates/golangci.yml)), the project's own exclusions below it, each with its reason. |
| `.githooks/pre-commit`, `.githooks/pre-push` | the gate, below. The part between the `sonar:` markers is **canonical**: [`pre-commit`](../sonarqube/hooks/pre-commit), [`pre-push`](../sonarqube/hooks/pre-push). A repository with its own checks keeps them around it. |
| `.agents/skills/sonar/SKILL.md` | the agents' procedure. **Canonical**: [`sonarqube/skills/sonar`](../sonarqube/skills/sonar/SKILL.md), with a pointer in each adapter folder the repository uses ([adapters](../sonarqube/skills/sonar/adapters)). |
| `.gitignore` | `.scannerwork/`, `coverage.out`, `golangci-lint.xml`, `.env` ([template](../sonarqube/templates/gitignore)). |
| `CONTRIBUTING.md` | a "SonarQube (optional)" section: what to install, the two variables, the commands. |
| `AGENTS.md` | a short pointer to the `sonar` skill. The rules themselves are in the skill. |

Enable the hooks per checkout: `git config core.hooksPath .githooks`.

## The gate: two steps

- **On a commit, locally.** The pre-commit hook runs golangci-lint on every Go module that has a
  staged `.go` file, and the secrets scan of the staged files (`sonar hook git-pre-commit`, when the
  SonarQube CLI is installed). A finding stops the commit. Nothing goes to the server: a commit has
  no hash yet, and a report of an uncommitted tree belongs to no commit.
- **On a push, the server's.** The pre-push hook runs `make sonar` when code the analysis covers
  changed (`COVERED` in the hook): the analysis of the pushed commit goes to the server, and a red
  quality gate stops the push. The report is on the server whatever the gate says, so the findings
  can be read and answered.
- **After every push, `make sonar-publish`.** The push's analysis is made while the commit is not on
  GitHub yet, so the pull request's check cannot land on it: GitHub does not know the commit, and the
  plugin does not report the failure (the analysis succeeds). Sending the scan again, once GitHub has
  the commit, makes the check appear. The same second analysis is also the one made with the pull
  request's number after it is opened; before that it was of the branch. `make sonar-publish` reuses
  the reports of the first, so it costs the scanner, not the tests.
- A report that has to reach the server whatever the gate says: `make sonar SONAR_GATE=false`.

The pre-push hook cannot do the last step itself: git has no post-push hook, and at pre-push the commit is not on GitHub. It says so when it succeeds.

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
