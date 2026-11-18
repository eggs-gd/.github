---
name: sonar
description: Read and answer the SonarQube analysis, and pass its local gate. Use when a commit is stopped by the pre-commit hook, after opening or pushing to a pull request, when the quality gate is red, or when asked about a SonarQube finding.
---

# SonarQube (the maintainer's server)

The server is on the maintainer's LAN. The analysis runs in the repository's SonarQube workflow, on
the self-hosted runner next to the server, once a commit is on GitHub; a commit is checked before
that by the pre-commit hook. `SONAR_HOST_URL` and `SONAR_TOKEN` (the environment or a git-ignored
`.env`; a worktree uses the main checkout's) are only needed for `make sonar` by hand and for the
hook's secrets scan. **Without them, skip those**: the workflow still analyses the pull request.

The standard: <https://github.com/eggs-gd/.github/blob/main/docs/sonarqube.md>.

## The flow

1. **Commit.** The pre-commit hook is the local gate. It runs the secrets scan of the staged files
   when the `sonar` CLI is installed, and the repository's own checks around it. In a repository
   with Go modules it also runs golangci-lint on the lines a commit changes in the modules with
   staged files, with `gocognit` at SonarQube's complexity threshold. Without Go there is no local
   lint: the rules (complexity included) are checked by the server only. A finding stops the
   commit. Fix it there: it is what the gate would have turned down.
2. **Push.** The SonarQube workflow runs on a pull request and on a push to the default branch
   (and a milestone branch, where there is one); a change to the docs alone is skipped. A branch
   push without a pull request runs nothing. On a pull request: the tests with coverage, the lint
   report where there is one, the scan of the pull request against its base, and the quality gate.
   A red gate fails the job, and the server's comment and check land on the pull request. The push
   to the default branch is the analysis the next pull requests are compared against.
3. **Read the result** on the pull request: the job, and the server's comment with the gate and the
   counts. A red gate is fixed or answered (below), committed, pushed: the workflow runs again.
4. **By hand, to see the findings before a push**, when `SONAR_HOST_URL` and `SONAR_TOKEN` are set:
   `make sonar` (the scope comes from `scripts/sonar-scope`), or `make sonar SONAR_GATE=false` to
   send the report without waiting for the gate.

## Reading what it found

`sonar list issues -p <projectKey> --format table`, the key being `sonar.projectKey` in
`sonar-project.properties`. The pull request's comment on GitHub has the gate and the counts.

## Answering a finding

- Fix it. A complexity or duplication finding is fixed by splitting the code, not by
  silencing the rule.
- A finding that is wrong for that line is answered **on the line**, with the reason:
  `// NOSONAR <why>` (put on the flagged line itself), or `//nolint:<linter> // <why>` for
  golangci-lint in Go.
- A rule that is wrong for a whole class of files is scoped in `sonar-project.properties`
  (`sonar.issue.ignore.multicriteria`), with the reason in a comment next to it.
- The pull request's description says what the gate showed and how each remaining
  finding was answered.

## Never, unless the maintainer asks

- Print, log, commit, read aloud or ask for the value of `SONAR_TOKEN`: only check that it is set.
- Change the server's settings or quality profiles, or close an issue or mark it a
  false positive on the server.
- Run `sonar integrate` (it downloads a binary and can overwrite the hooks).
- Run `sonar-scanner` directly: without the arguments from `scripts/sonar-scope` a
  feature branch is published as the main branch. Use `make sonar`.
- Commit with `--no-verify`. If it is asked for, say so in the message.
