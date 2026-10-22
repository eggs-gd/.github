# Contributing

Issues and pull requests are welcome. The projects are small and opinionated, so for
anything larger than a fix, open an issue first.

## How a change goes in

- One change, one branch, one pull request. A refactor is not mixed with new behaviour.
- `main` is protected: it changes only through a pull request, merged with **squash**.
- The build has to pass, and the branch has to be up to date with `main`. Merge pull
  requests one at a time; when `main` moved, use **Update branch**.
- Conversations on the pull request are resolved before it is merged.
- The docs that describe the change are updated in the same pull request.

A repository's own `CONTRIBUTING.md` and `AGENTS.md` take precedence over this file.
