# eggs-gd/.github

The organization's home repository: default community health files, the scripts that
apply the repository and organization baseline, and the docs for how we work.
See `README.md` for the map.

- `scripts/*.sh` are bash + `gh`, idempotent, with `--dry-run`. Test a change with
  `--dry-run` and then on a real repository; the second run must change nothing.
- `docs/repo-baseline.md` is the spec of what the scripts apply. Change both in one pull request.
- The default files (`SECURITY.md`, `CONTRIBUTING.md`, `PULL_REQUEST_TEMPLATE.md`) apply
  to every repository without its own. Keep them short and true for all of them.
- Don't commit or push unless asked. Only the owner merges.
