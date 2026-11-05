#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash (.claude/settings.json). Gates Claude's own git commands:
#   git commit -> tenant isolation check: academy A logs in, cannot read academy B (scripts/hooks/isolation-check.sh)
#   git push   -> database role check: no service connects as owner/superuser/BYPASSRLS (scripts/hooks/db-role-check.sh)
# A failing check blocks the command (exit 2); its failures reach Claude on stderr. Every other command passes at once.
# The checks test the working tree of the repository the command runs in (a worktree included).
set -uo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$command" ] || exit 0

# `git`, optional global options (-C dir, -c key=value, --flag[=value]), then the subcommand as a whole word.
runs_git() {
  grep -qE "(^|[;&|({[:space:]])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+|[[:space:]]+--[a-z][a-z-]*(=[^[:space:]]+)?)*[[:space:]]+$1([[:space:];&|)]|\$)" <<<"$command"
}

gate() { # gate <script> <what> <action>
  if ! "$1" >&2; then
    echo "Blocked: $2 failed, so this git $3 did not run. Fix the cause above; do not bypass this hook." >&2
    exit 2
  fi
}

runs_git commit || runs_git push || exit 0

cwd=$(jq -r '.cwd // empty' <<<"$input")
cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || cd "${CLAUDE_PROJECT_DIR:-.}" || exit 2
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Blocked: $PWD is not inside a git repository." >&2; exit 2; }
cd "$root" || exit 2

if runs_git commit; then gate scripts/hooks/isolation-check.sh "the tenant isolation check" commit; fi
if runs_git push; then gate scripts/hooks/db-role-check.sh "the database role check" push; fi
exit 0
