# eggs-gd/.github

The organization's home repository. GitHub uses the community health files here as the
default for every repository in the organization that does not have its own; and this is
where the high-level material lives: how the repositories are set up and how we work.

| What | Where |
|---|---|
| How to report a vulnerability | [SECURITY.md](SECURITY.md) |
| How a change goes in | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Default pull request template | [PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md) |
| Basic working rules (flow, agents, code and docs, analytics and consent) | [docs/working-rules.md](docs/working-rules.md) |
| What the repository and organization baseline is, and the checklist for a new repository | [docs/repo-baseline.md](docs/repo-baseline.md) |
| Apply the baseline to a repository | [scripts/repo-baseline.sh](scripts/repo-baseline.sh) |
| Apply the baseline to the organization | [scripts/org-baseline.sh](scripts/org-baseline.sh) |

## Applying the baseline

Both scripts need [`gh`](https://cli.github.com) and can be run again at any time: they
update what exists. `--dry-run` shows what would be sent and changes nothing.

```bash
scripts/repo-baseline.sh diary --check "build / build"
scripts/repo-baseline.sh some-repo                # no required check
scripts/org-baseline.sh                           # needs: gh auth refresh -s admin:org
```

## Changing this repository

It follows its own rules: a branch and a pull request, squash merge. Anything that
changes what the scripts do changes [docs/repo-baseline.md](docs/repo-baseline.md) in
the same pull request.
