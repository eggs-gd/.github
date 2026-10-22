#!/usr/bin/env bash
# Applies the eggs-gd organization baseline. Safe to run again. Described in
# docs/repo-baseline.md.
#
#   scripts/org-baseline.sh [<org>] [--dry-run]       (org defaults to eggs-gd)
#
# Sets:
#   - the default GITHUB_TOKEN of Actions workflows to read-only, and Actions may not approve PRs;
#   - the "eggs-gd baseline" code security configuration (secret scanning with push protection,
#     Dependabot alerts, dependency graph, CodeQL default setup, private vulnerability
#     reporting), attached to every PUBLIC repository and made the default for new public ones.
#     Private repositories are left alone: these features cost money there.
#
# Needs: gh with the admin:org scope:  gh auth refresh -h github.com -s admin:org
set -euo pipefail

org="eggs-gd"; dry=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry=true ;;
    -*) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
    *) org="$arg" ;;
  esac
done

config_name="eggs-gd baseline"
config='{"name":"eggs-gd baseline","description":"Secret scanning with push protection, Dependabot alerts, dependency graph, CodeQL default setup and private vulnerability reporting.","advanced_security":"enabled","secret_scanning":"enabled","secret_scanning_push_protection":"enabled","dependabot_alerts":"enabled","dependabot_security_updates":"disabled","dependency_graph":"enabled","code_scanning_default_setup":"enabled","private_vulnerability_reporting":"enabled","enforcement":"enforced"}'

echo "== $org"
echo "actions: default token read-only, workflows may not approve pull requests"
echo "security configuration: \"$config_name\" -> all public repositories and new public ones"
if $dry; then echo "$config"; echo "(dry run: nothing changed)"; exit 0; fi

gh api -X PUT "orgs/$org/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false >/dev/null

id=$(gh api "orgs/$org/code-security/configurations" --jq ".[] | select(.name == \"$config_name\") | .id")
if [ -z "$id" ]; then
  id=$(echo "$config" | gh api -X POST "orgs/$org/code-security/configurations" --input - --jq .id)
  echo "configuration $id created"
else
  echo "$config" | gh api -X PATCH "orgs/$org/code-security/configurations/$id" --input - >/dev/null
  echo "configuration $id updated"
fi
gh api -X POST "orgs/$org/code-security/configurations/$id/attach" -f scope=public >/dev/null
gh api -X PUT "orgs/$org/code-security/configurations/$id/defaults" -f default_for_new_repos=public >/dev/null
echo "attached to public repositories; default for new public repositories"
