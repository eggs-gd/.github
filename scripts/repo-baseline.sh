#!/usr/bin/env bash
# Applies the eggs-gd baseline to one PUBLIC repository. Safe to run again: it updates
# what exists. What it sets is described in docs/repo-baseline.md.
#
#   scripts/repo-baseline.sh <repo> [--check "<status check name>"] [--no-strict] [--security] [--dry-run]
#
#   <repo>      name in the eggs-gd organization, or owner/name
#   --check     a status check that must pass before merge, e.g. "build" or "build / build".
#               Leave it out for a repository whose CI only runs on some paths: a required
#               check that does not run on a pull request blocks that pull request.
#   --no-strict do not require the branch to be up to date with main before merging
#   --security  also turn on Dependabot alerts and CodeQL (default setup). For a repository the
#               organization's code security configuration does not cover: one of a personal
#               account. A repository of the organization gets them from org-baseline.sh.
#   --dry-run   print what would be done and the ruleset, change nothing
#
# Needs: gh (logged in with the "repo" scope). Private repositories on a free plan cannot
# have rulesets, so this is for public ones.
set -euo pipefail

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

[ $# -ge 1 ] || usage
repo="$1"; shift
check=""; strict=true; dry=false; security=false
while [ $# -gt 0 ]; do
  case "$1" in
    --check) check="${2:?--check needs a name}"; shift 2 ;;
    --no-strict) strict=false; shift ;;
    --security) security=true; shift ;;
    --dry-run) dry=true; shift ;;
    *) usage ;;
  esac
done
case "$repo" in */*) ;; *) repo="eggs-gd/$repo" ;; esac

name="main: PR, squash only"

checks_rule=""
if [ -n "$check" ]; then
  checks_rule=$(cat <<JSON
,
    {"type": "required_status_checks", "parameters": {
      "strict_required_status_checks_policy": $strict,
      "do_not_enforce_on_create": false,
      "required_status_checks": [{"context": "$check"}]}}
JSON
)
fi

body=$(cat <<JSON
{
  "name": "$name",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "bypass_actors": [{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "pull_request"}],
  "rules": [
    {"type": "pull_request", "parameters": {
      "required_approving_review_count": 0,
      "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_review_thread_resolution": true,
      "allowed_merge_methods": ["squash"]}},
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "required_linear_history"}$checks_rule
  ]
}
JSON
)

echo "== $repo"
echo "settings: delete branch on merge, update-branch button, secret scanning + push protection, private vulnerability reporting"
echo "ruleset:  \"$name\"${check:+, required check \"$check\" (strict=$strict)}"
$security && echo "security: Dependabot alerts, CodeQL default setup"

if $dry; then
  echo "$body"
  echo "(dry run: nothing changed)"
  exit 0
fi

gh repo edit "$repo" --delete-branch-on-merge --allow-update-branch \
  --enable-secret-scanning --enable-secret-scanning-push-protection >/dev/null
gh api -X PUT "repos/$repo/private-vulnerability-reporting" >/dev/null
if $security; then
  gh api -X PUT "repos/$repo/vulnerability-alerts" >/dev/null
  gh api -X PATCH "repos/$repo/code-scanning/default-setup" -f state=configured >/dev/null
fi

id=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$name\") | .id")
if [ -n "$id" ]; then
  echo "$body" | gh api -X PUT "repos/$repo/rulesets/$id" --input - --jq '"ruleset \(.id) updated"'
else
  echo "$body" | gh api -X POST "repos/$repo/rulesets" --input - --jq '"ruleset \(.id) created"'
fi
