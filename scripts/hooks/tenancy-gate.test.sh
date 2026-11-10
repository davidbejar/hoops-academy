#!/usr/bin/env bash
# Tests of the command matcher in .claude/hooks/tenancy-gate.sh (run: just test-hooks). The hook is asked only to
# classify (TENANCY_GATE_CLASSIFY_ONLY=1); it prints which gates the command needs: commit, push, "commit push" or none.
# When the parser is unsure the gate must run: false positives cost time, false negatives skip the isolation check.
# shellcheck disable=SC2016 # the test commands are literal text, not expansions
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
hook=.claude/hooks/tenancy-gate.sh
fail=0 total=0

classify() { # classify <command text>
  jq -nc --arg c "$1" '{tool_input: {command: $c}}' | TENANCY_GATE_CLASSIFY_ONLY=1 "$hook" 2>&1
}

expect() { # expect <expected> <command text>
  local want="$1" cmd="$2" got
  total=$((total + 1))
  got=$(classify "$cmd")
  if [ "$got" = "$want" ]; then return 0; fi
  fail=$((fail + 1))
  printf 'FAIL expected [%s] got [%s] for: %s\n' "$want" "$got" "$cmd"
}

# --- commit
expect none '-x foo' # a first word starting with a dash must not index before the array (bash 3.2)
expect commit 'timeout 600 git commit -m x'
expect commit 'env -u FOO git commit'
expect commit '2>/dev/null git commit'
expect commit $'git \\\n  commit -m x'
expect push 'nice -n 5 git push'
expect push 'caffeinate -i git push origin main'
expect none 'timeout 5 git log --grep "git commit"'
expect commit 'git commit -m x'
expect commit 'git -C dir commit -m x'
expect commit 'git -c user.name=a commit'
expect commit 'git --no-pager commit'
expect commit 'git --git-dir /x/.git commit'
expect commit 'cd x && git commit --no-verify -m "a; b"'
expect commit 'gitleaks protect --staged && git commit -m x'
expect commit 'FOO=1 git commit'
expect commit 'env FOO=1 git commit'
expect commit '(cd x; git commit -m x)'
expect commit 'echo $(git commit -m x)'
expect commit 'ls | git commit -F -'
expect commit '{ git commit -m x; }'
expect commit 'git -C "my dir" commit'
expect commit $'echo hi\ngit commit -m x'
expect commit 'git commit -m "x" # comment'
# --- push
expect push 'git push'
expect push 'git push origin a:main'
expect push 'git -C d push'
expect push 'env FOO=1 git push'
expect push 'git add f && git push -u origin b'
# --- both
expect 'commit push' 'git commit -m x && git push'
# --- none
expect none 'echo "=== git commit times"; git log'
expect none "git log --grep 'git push'"
expect none $'# git commit\ngit status'
expect none 'grep -n "git commit" file'
expect none 'git commit-tree HEAD^{tree}'
expect none 'git show-ref'
expect none 'git stash push'
expect none 'git status'
expect none 'ls -la'
expect commit 'echo git commit' # unquoted mention: the belt gates it (safe side; quote the text to avoid it)
expect none 'echo "git push" | cat'
# --- unsure: the gate must run
expect 'commit push' 'echo "unbalanced; git commit'
expect commit "bash -c 'git commit -m x'"
expect commit 'sh -c "git push" && git commit'
expect commit 'echo "$(git commit -m x)"'
expect commit '"$GIT" commit -m x'
expect 'commit push' 'echo "unbalanced; git push'

# --- end to end with stub gate scripts in a throwaway repository: pass, block, and the one result line
run_gate() { # run_gate <stub exit code> <command text>; prints "<rc>|<stderr>"
  local repo out rc
  repo=$(mktemp -d)
  git -C "$repo" init -q
  mkdir -p "$repo/scripts/hooks"
  printf '#!/bin/sh\nexit %s\n' "$1" >"$repo/scripts/hooks/isolation-check.sh"
  chmod +x "$repo/scripts/hooks/isolation-check.sh"
  out=$(jq -nc --arg d "$repo" --arg c "$2" '{cwd: $d, tool_input: {command: $c}}' | "$hook" 2>&1)
  rc=$?
  rm -rf "$repo"
  echo "$rc|$out"
}
check() { # check <label> <actual> <expected>
  total=$((total + 1))
  # shellcheck disable=SC2053 # $3 may hold a glob
  [[ "$2" == $3 ]] && return 0
  fail=$((fail + 1))
  printf 'FAIL %s: got [%s] expected [%s]\n' "$1" "$2" "$3"
}
check "passing gate" "$(run_gate 0 'git commit -m x')" "0|tenancy-gate: isolation-check PASSED in [0-9]* s"
check "failing gate blocks" "$(run_gate 1 'git commit -m x' | cut -c1-31)" "2|Blocked: the tenant isolation"
check "unrelated command skips the gate" "$(run_gate 1 'git status')" "0|"

echo "tenancy-gate matcher: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]
