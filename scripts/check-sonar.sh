#!/usr/bin/env bash
# Checks that a repository's SonarQube setup is the organization's: the canonical files
# are identical to the ones in sonarqube/, and the repo's own files have what the standard
# needs (docs/sonarqube.md). Prints one line per check; the exit status is non-zero when
# one fails.
#
#   scripts/check-sonar.sh <path to a checkout>
set -uo pipefail

[ $# -eq 1 ] && [ -d "$1" ] || { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
repo=$1
here=$(cd "$(dirname "$0")/.." && pwd)/sonarqube
fail=0

ok() { printf 'ok    %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; fail=1; }

same() { # <canonical file> <file in the repo>
	if [ ! -f "$repo/$2" ]; then bad "$2 is missing"
	elif cmp -s "$here/$1" "$repo/$2"; then ok "$2 is the canonical copy"
	else bad "$2 differs from sonarqube/$1"; fi
}

block() { sed -n '/# --- sonar:begin/,/# --- sonar:end/p' "$1"; }

same scripts/sonar-scope scripts/sonar-scope
same skills/sonar/SKILL.md .agents/skills/sonar/SKILL.md

for hook in pre-commit pre-push; do
	f=$repo/.githooks/$hook
	if [ ! -f "$f" ]; then bad ".githooks/$hook is missing"
	elif [ "$(block "$f")" = "$(block "$here/hooks/$hook")" ] && [ -n "$(block "$f")" ]; then
		ok ".githooks/$hook has the canonical sonar block"
	else bad ".githooks/$hook: the sonar block differs from sonarqube/hooks/$hook"; fi
done

[ -f "$repo/.claude/skills/sonar/SKILL.md" ] && ok ".claude/skills/sonar points at the skill" || bad ".claude/skills/sonar/SKILL.md is missing"

for line in '.scannerwork/' 'coverage.out' 'golangci-lint.xml' '.env'; do
	# a path in a subdirectory (server/coverage.out) counts: the report is written there
	pattern="(^|/)$(printf '%s' "$line" | sed 's/\./\\./g')\$"
	grep -qE "$pattern" "$repo/.gitignore" 2>/dev/null && ok ".gitignore has $line" || bad ".gitignore lacks $line"
done

props=$repo/sonar-project.properties
grep -q '^sonar.projectKey=' "$props" 2>/dev/null && ok "sonar-project.properties has a project key" || bad "sonar-project.properties has no project key"
grep -q 'sonar.go.golangci-lint.reportPaths' "$props" 2>/dev/null && ok "the golangci-lint report is imported" || bad "sonar-project.properties does not import the golangci-lint report"
grep -q 'ruleKey=go:S3776' "$props" 2>/dev/null && ok "go:S3776 is scoped for tests" || bad "go:S3776 is not scoped for tests"

grep -q 'env=\./\.env' "$repo/Makefile" 2>/dev/null && ok "the Makefile sources ./.env (a bare .env is looked up in PATH by sh)" || bad "the Makefile does not source ./.env"
grep -q '^sonar-publish:' "$repo/Makefile" 2>/dev/null && grep -q 'reports-head' "$repo/Makefile" 2>/dev/null && ok "make sonar-publish is there" || bad "the Makefile has no sonar-publish"
grep -q '^SONAR_GATE ?= true' "$repo/Makefile" 2>/dev/null && ok "make sonar takes SONAR_GATE" || bad "Makefile has no SONAR_GATE"
grep -q 'sonar.qualitygate.wait=$(SONAR_GATE)' "$repo/Makefile" 2>/dev/null && ok "make sonar passes SONAR_GATE to the scanner" || bad "the scanner does not get SONAR_GATE"

exit $fail
