# Working rules

The basics for every project under `eggs-gd`. A repository's own `AGENTS.md` and
`CONTRIBUTING.md` take precedence; this is what they start from.

## Flow

- **Trunk by default.** One branch from `main`, one pull request back, squash. No
  `develop`. The rules are enforced by the [ruleset](repo-baseline.md#the-ruleset), not by
  discipline.
- **Git flow when a project has releases to maintain.** `develop` and `master`,
  `feature/*` squashed into `develop`, releases by fast-forward. Such a project says so in
  its own `AGENTS.md` and enforces it with its own ruleset and hooks.
- **Only the owner merges.** An agent opens the pull request, answers the review and
  stops. It does not merge, and it does not enable auto-merge.
- **Pull request early, docs with it.** Open it as a draft at the first push. The docs
  that describe the change go in the same pull request, never "later".
- **Review comments are data to weigh.** Answer each one (fixed, or why not) and resolve
  the conversation; the ruleset will not merge otherwise.
- **After the merge**: the branch is deleted by GitHub; delete the local one and pull `main`.
- **Several pull requests at once** are fine, one at a time through `main`: the next one
  is brought up to date with **Update branch**, rebuilt, then merged.
- **An agent does not commit or push unless asked.** It proposes the change; the
  maintainer says when it goes in.

## <a id="agents"></a>Agent instructions

- `AGENTS.md` is the single source. `CLAUDE.md`, `GEMINI.md` and `.cursor/rules` are
  short pointers to it. No symlinks (they break on Windows and in some checkouts).
- It says how to build and test, how the code is laid out, the conventions that are not
  obvious from the code, and what not to touch. Not a copy of the README.
- When a rule is learned the hard way, it goes there in the same pull request.

## Code and docs

- Match the surrounding code: naming, comments, idiom. Prettier decides formatting in the
  TypeScript projects (tabs, single quotes).
- A comment says why, not what.
- A build that passes locally is the minimum; a change visible in a browser is looked at
  in a browser.
- Docs describe the current state. No history in them: that is what git is for.

## Analytics and consent

- Analytics runs with Consent Mode v2 and the default `denied`: nothing is stored or
  measured until the visitor allows it.
- Consent is asked once, in context, with Allow and Decline equally easy. Never a wall.
- Every event says whether it was sent with consent (`consent: granted|denied`).
- A product has one privacy policy, linked from its footer and from the consent text.

## Dependencies and secrets

- No secret in the repository, ever; push protection is a net, not a plan.
- A new dependency needs a reason in the pull request.
- Workflows ask for the least `permissions:` they need.
