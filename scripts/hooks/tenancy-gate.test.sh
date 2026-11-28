#!/usr/bin/env bash
# Tests of .claude/hooks/tenancy-gate.sh (run: just test-hooks). The matcher: TENANCY_GATE_CLASSIFY_ONLY=1 prints which
# gates the command needs (commit, push, "commit push" or none); =plan prints each gate with its checkout and each ask
# rule (WP154, ADR-0078). When the parser is unsure the gate must run: false positives cost time, false negatives skip
# the isolation check. Then end to end with stub gates in throwaway repositories, the gate log, and the hook without jq.
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
expect 'commit push' 'sh -c "git push" && git commit' # the wrapper's script is read like a command line (WP154)
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
check() { # check <label> <actual> <expected glob>: a trailing * instead of `cut -c` (GNU cut counts bytes, so a cut
  # through a multi-byte character such as ✗ differed between Linux and macOS: WP146)
  total=$((total + 1))
  # shellcheck disable=SC2053 # $3 may hold a glob
  [[ "$2" == $3 ]] && return 0
  fail=$((fail + 1))
  printf 'FAIL %s: got [%s] expected [%s]\n' "$1" "$2" "$3"
}
check "passing gate" "$(run_gate 0 'git commit -m x')" "0|tenancy-gate: isolation-check PASSED in [0-9]* s, checkout *"
check "failing gate blocks" "$(run_gate 1 'git commit -m x')" "2|Blocked: the tenant isolation*"
check "unrelated command skips the gate" "$(run_gate 1 'git status')" "0|"

# --- AG-01 (WP154, ADR-0078): the gate runs in the checkout the git command acts on. The plan mode prints one line per
# gate ("commit <dir>", "push <dir>"; "?" = cannot tell, which blocks) and per destructive rule ("ask <rule>").
plan() { # plan <command text> [cwd]: the plan, lines joined by ";"
  jq -nc --arg d "${2:-/s}" --arg c "$1" '{cwd: $d, tool_input: {command: $c}}' |
    env -u CLAUDE_PROJECT_DIR HOME=/home/u TENANCY_GATE_CLASSIFY_ONLY=plan "$hook" 2>&1 | paste -sd ';' -
}
expect_plan() { # expect_plan <expected plan> <command text> [cwd] [only the lines that start with this]
  local got
  total=$((total + 1))
  got=$(plan "$2" "${3:-/s}" | tr ';' '\n' | grep -E "^${4:-}" | paste -sd ';' -)
  [ "$got" = "$1" ] && return 0
  fail=$((fail + 1))
  printf 'FAIL plan expected [%s] got [%s] for: %s\n' "$1" "$got" "$2"
}
expect_plan 'commit /s' 'git commit -m x'
expect_plan 'commit /w' 'cd /w && git commit -m x'
expect_plan 'commit /s/wt' 'cd wt && git commit -m x'
expect_plan 'commit /home/u/code/wt' 'cd ~/code/wt && git commit -m x'
expect_plan 'commit /home/u' 'cd && git commit -m x'
expect_plan 'commit /w' 'git -C /w commit -m x'
expect_plan 'commit /w/sub' 'cd /w && git -C sub commit -m x'
expect_plan 'commit /my dir' 'git -C "/my dir" commit -m x'
expect_plan 'commit /w' 'cd /w; gitleaks protect --staged && git commit -m "a; cd /x"'
expect_plan 'commit /w;push /s' '(cd /w; git commit -m x) && git push origin b'
expect_plan 'commit /w;push /x' 'cd /w && git commit -m x; cd /x && git push origin b'
expect_plan 'commit /w' 'timeout 600 git -C /w commit -m x'
expect_plan 'commit /w' "bash -c 'cd /w && git commit -m x'"
expect_plan 'commit /s' 'x=$(cd /w && pwd) && git commit -m x'
expect_plan 'commit ?' 'cd "$WT" && git commit -m x'
expect_plan 'commit ?' 'cd - && git commit -m x'
expect_plan 'commit ?' 'git --work-tree=/w commit -m x'
expect_plan 'commit ?' 'git --git-dir /w/.git commit -m x'
expect_plan 'commit ?' '"$GIT" commit -m x'
expect_plan 'commit /s' 'echo "$(git commit -m x)"' # inside quotes: loose, in the directory known so far
# a message or body in a quoted substitution that mentions git: an extra gate at most, never a block
expect_plan 'commit /w;push /w' $'cd /w && git commit -m "$(cat <<\'EOF\'\ndocs: say when git push asks\nEOF\n)"'
expect_plan 'commit /w;push /w' $'cd /w && gh pr create --body "$(cat <<\'EOF\'\ngit commit, then git push\nEOF\n)"'
# an unquoted substitution inside a command: its text is read, the outer command keeps its words
expect_plan 'commit ?' 'git -C $(pwd) commit -m x'
expect_plan 'commit ?' 'cd $(git rev-parse --show-toplevel) && git commit -m x'
expect_plan 'commit ?' 'git -C `pwd` commit -m x'
expect_plan 'commit /s' 'echo $(git commit -m x)'
expect_plan 'commit /w' 'echo $(cd /w && git commit -m x)'
expect_plan 'commit /s' 'x=$(cd /w; pwd) && git commit -m x'
expect_plan 'push ?;ask git-force-push' 'git -C $(pwd) push --force origin wp-x'
expect_plan 'ask podman-volume-rm' 'podman volume rm $(podman volume ls -q)'
expect_plan 'commit /w' $'cd /w && git commit -m "$(cat <<\'EOF\'\nfeat: it\'s done\n\nCo-Authored-By: x\nEOF\n)"'
expect_plan '' 'cd /w && git status'

# --- AG-07 (decision 127): destructive commands ask the owner. One case per rule of ASK_RULES in the hook, then near
# misses that must pass untouched. A repository on branch main and one on a feature branch for the branch-aware rules.
repos=$(mktemp -d)
git -C "$repos" init -q -b main on-main
git -C "$repos" init -q -b wp-x on-feature
m=$repos/on-main f=$repos/on-feature
asked=""
expect_ask() { # expect_ask <rule> <command text> [cwd]
  asked+=" $1 "
  expect_plan "ask $1" "$2" "${3:-$f}" ask # a push also gets its push gate: only the ask lines count here
}
expect_ask podman-volume-rm 'podman volume rm hoops_pgdata'
expect_ask podman-volume-rm 'podman volume prune -f'
expect_ask podman-volume-rm 'echo x | xargs podman volume remove'
expect_ask podman-volume-rm "bash -c 'podman volume rm hoops_pgdata-19'"
expect_ask podman-volume-rm 'sudo podman --connection m volume rm x'
expect_ask podman-system-prune 'podman system prune -a --volumes'
expect_ask podman-system-prune 'podman system reset --force'
expect_ask podman-machine 'podman machine stop'
expect_ask podman-machine 'podman machine rm -f'
expect_ask podman-machine 'podman machine reset'
expect_ask compose-down-volumes 'podman compose -f infra/compose/compose.yaml down -v'
expect_ask compose-down-volumes 'podman-compose down --volumes'
expect_ask compose-down-volumes 'just down -v'
expect_ask kind-delete-cluster 'kind delete cluster --name hoops'
expect_ask kind-delete-cluster 'timeout 60 kind delete clusters --all'
expect_ask kind-delete-cluster 'just kind-down'
expect_ask kind-delete-cluster 'deploy/kind/down.sh'
expect_ask git-force-push 'git push --force origin wp-x'
expect_ask git-force-push 'git push -f'
expect_ask git-force-push 'git push origin +wp-x'
expect_ask git-force-push 'git push --force-with-lease origin wp-x'
expect_ask git-force-push 'git push --mirror origin'
expect_ask git-push-main 'git push origin main'
expect_ask git-push-main 'git push origin wp-x:main'
expect_ask git-push-main 'git push origin HEAD:refs/heads/main'
expect_ask git-push-main 'git push origin --delete main'
expect_ask git-push-main 'git push origin :main'
expect_ask git-push-main 'git push --all origin'
expect_ask git-push-main 'git push' "$m"
expect_ask git-push-main 'git push origin HEAD' "$m"
expect_ask git-push-main 'git push origin "$(git branch --show-current)"' "$m"
expect_ask git-reset-hard-main 'git reset --hard origin/main' "$m"
expect_ask git-reset-hard-main "cd $m && git reset --hard HEAD~1"
expect_ask git-main-ref 'git branch -D main'
expect_ask git-main-ref 'git branch -f main HEAD~1'
expect_ask git-main-ref 'git branch -M wp-x main'
expect_ask git-main-ref 'git checkout -B main'
expect_ask git-main-ref 'git switch -C main origin/main'
expect_ask git-main-ref 'git update-ref refs/heads/main 0123abc'
expect_ask git-no-verify 'git commit --no-verify -m x'
expect_ask git-no-verify 'git commit -nm x'
expect_ask git-no-verify 'git -C /w commit -a -n -m x'
expect_ask git-no-verify 'git push --no-verify origin wp-x'
expect_ask git-no-verify 'git -c core.hooksPath=/dev/null commit -m x'
expect_ask git-no-verify 'git config core.hooksPath /dev/null'
expect_ask podman-volume-rm 'docker volume rm hoops_pgdata' # the podman-docker shim
expect_ask compose-down-volumes 'docker compose down -v'
expect_ask gh-repo-settings 'gh repo edit --visibility private'
expect_ask gh-repo-settings 'gh repo rename other'
expect_ask gh-repo-settings 'gh secret set X --body y'
expect_ask gh-repo-settings 'gh variable set IMAGE_REGISTRY --body y'
expect_ask gh-repo-settings 'gh workflow disable ci.yml'
expect_ask gh-delete 'gh repo delete o/r --yes'
expect_ask gh-delete 'gh release delete v1 -y'
expect_ask gh-delete 'gh secret delete X'
expect_ask gh-delete 'gh -R o/r run delete 5'
expect_ask gh-api-write 'gh api -X DELETE repos/o/r/git/refs/heads/x'
expect_ask gh-api-write 'gh api --method=PUT repos/o/r/rulesets/1'
expect_ask gh-api-write 'gh api repos/o/r/rulesets --input ruleset.json'
expect_ask gh-api-write 'gh api repos/o/r/issues -f title=x'
expect_ask gh-merge-admin 'gh pr merge 12 --rebase --admin'
expect_ask pg-copies-remove 'scripts/pg-major-move.sh --clean-up --out /x --remove'
expect_plan "commit $f;push $f;ask podman-volume-rm" 'echo "it is unbalanced; podman volume rm x' "$f" # unreadable: loose
expect_plan 'commit /w;push /w;ask git-force-push' 'cd /w && git commit -m x && git push --force origin wp-x' "$f"
while read -r rule; do # every rule of the table has a case above
  total=$((total + 1))
  case "$asked" in *" $rule "*) ;; *) fail=$((fail + 1)); echo "FAIL ask rule without a test: $rule" ;; esac
done < <(sed -n 's/^#   \([a-z-]*\)  .*/\1/p' "$hook")
total=$((total + 1))
[ -n "$(sed -n 's/^#   \([a-z-]*\)  .*/\1/p' "$hook")" ] || { fail=$((fail + 1)); echo "FAIL no ASK_RULES table in $hook"; }
# near misses: ordinary commands pass untouched
for cmd in 'podman volume ls' 'podman volume inspect hoops_pgdata' 'podman machine start' 'podman machine ssh "date +%s"' \
  'podman compose -f c.yaml down' 'podman compose up -d --wait' 'podman rm -f throwaway' 'podman system df' 'just down' \
  'just up' 'kind get clusters' 'kind create cluster --name x' 'git push origin wp-x' 'git push -u origin wp-x' \
  'git push origin --delete wp-x' 'git push origin HEAD' 'git commit -m "no --no-verify here"' 'git commit --amend -m x' 'git reset --hard origin/wp-x' 'git branch -d wp-x' \
  'git branch -D wp-x' 'git branch feature main' 'git checkout -b feature main' 'git worktree remove --force ../wt' \
  'git stash push' 'gh pr create --base main --head wp-x' 'gh pr merge 12 --rebase --match-head-commit abc' \
  'gh run watch 5 --exit-status' 'gh api repos/o/r/branches/main' 'gh api -X GET repos/o/r/pulls -f state=open' \
  'gh pr checks 12 --watch' 'git config --get core.hooksPath' 'docker ps' 'gh secret list' 'grep -n "podman volume rm" docs/x.md' 'echo "git push --force"' \
  "git log --grep 'kind delete cluster'" 'scripts/pg-major-move.sh --clean-up --out /x' 'git push origin main:refs/heads/x'; do
  expect_plan '' "$cmd" "$f" ask
done
expect_plan "commit $f" 'git commit -m "podman volume rm hoops_pgdata"' "$f" # a commit message mentioning it
expect_plan '' 'git reset --hard HEAD~1' "$f"

# --- end to end in real repositories: a main checkout and a worktree of it, stub gate scripts in each
e2e() { # e2e <session exit> <worktree exit> <command, WT = the worktree> [jq input filter]; prints "<rc>|<stderr+stdout>"
  local base out rc
  base=$(mktemp -d)
  git -C "$base" init -q -b main main
  git -C "$base/main" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  git -C "$base/main" worktree add -q -b wp-x "$base/wt"
  git -C "$base" init -q other # a repository without the gate scripts
  for t in main:$1 wt:$2; do
    mkdir -p "$base/${t%%:*}/scripts/hooks"
    printf '#!/bin/sh\nexit %s\n' "${t#*:}" >"$base/${t%%:*}/scripts/hooks/isolation-check.sh"
    printf '#!/bin/sh\nexit %s\n' "${t#*:}" >"$base/${t%%:*}/scripts/hooks/db-role-check.sh"
    chmod +x "$base/${t%%:*}/scripts/hooks/"*.sh
  done
  out=$(jq -nc --arg d "$base/main" --arg c "$(sed -e "s#OTHER#$base/other#g" -e "s#WT#$base/wt#g" <<<"$3")" '{cwd: $d, session_id: "s1", tool_input: {command: $c}}' |
    env -u CLAUDE_PROJECT_DIR "$hook" 2>&1)
  rc=$?
  E2E_LOG=$(cat "$base/main/.git/claude-gate.log" 2>/dev/null)
  rm -rf "$base"
  echo "$rc|$out"
}
check "a commit in a worktree runs the worktree's gate" "$(e2e 1 0 'cd WT && git commit -m x')" "0|*PASSED*checkout */wt"
check "the worktree's failing gate blocks" "$(e2e 0 1 'cd WT && git commit -m x')" "2|Blocked: the tenant isolation*/wt*"
check "git -C picks the worktree" "$(e2e 1 0 'git -C WT commit -m x')" "0|*PASSED*"
check "the session checkout is still gated" "$(e2e 1 0 'git commit -m x')" "2|Blocked: the tenant isolation*"
check "a push in the worktree runs the role check there" "$(e2e 1 0 'cd WT && git push origin wp-x')" "0|*db-role-check PASSED*"
check "an unknown checkout blocks" "$(e2e 0 0 'cd "$TARGET_DIR" && git commit -m x')" "2|Blocked: cannot tell which checkout*"
check "a checkout without the gate script blocks" "$(e2e 0 0 'cd OTHER && git commit -m x')" \
  "2|Blocked: */other has no scripts/hooks/isolation-check.sh*"
# AG-10: one log line per decision in the shared git directory, without the command's text
e2e 1 0 'cd WT && git commit -m s3cr3t-in-message' >/dev/null
check "the gate log has the decision" "$E2E_LOG" $'*commit\tpassed*'
check "the gate log names the worktree" "$E2E_LOG" $'*/wt\tcommit*'
check "the gate log names the session" "$E2E_LOG" $'*\ts1\t*'
total=$((total + 1))
case "$E2E_LOG" in *s3cr3t*) fail=$((fail + 1)); echo "FAIL the gate log holds the command text" ;; esac
e2e 0 1 'cd WT && git commit -m x' >/dev/null
check "a blocked gate is logged" "$E2E_LOG" $'*commit\tblocked*'
e2e 0 0 'podman volume rm hoops_pgdata' >"$repos.out" # not in $( ): E2E_LOG must reach this shell
out=$(cat "$repos.out") && rm -f "$repos.out"
check "a destructive command answers ask" "$out" '0|{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"*podman-volume-rm*"}}'
check "an ask is logged" "$E2E_LOG" $'*ask podman-volume-rm\tasked*'
check "an ordinary command prints nothing and logs nothing" "$(e2e 1 1 'ls -la'; echo "[$E2E_LOG]")" "0|"$'\n'"[]"
rm -rf "$repos"

# --- AG-14: without jq the hook cannot read the command, so it blocks; unreadable input blocks too
nojq=$(mktemp -d)
for tool in cat git date grep env sed paste; do ln -s "$(command -v "$tool")" "$nojq/$tool"; done
out=$(cd "$nojq" && echo '{"tool_input":{"command":"git commit -m x"}}' |
  PATH=$nojq "$(command -v bash)" "$OLDPWD/$hook" 2>&1) # outside any repository: nothing logged here
check "no jq blocks" "$?|$out" "2|Blocked: jq is missing*"
rm -rf "$nojq"
out=$(echo 'not json' | "$hook" 2>&1)
check "unreadable hook input blocks" "$?|$out" "2|Blocked: *"

# --- the gates cover every service with tenant data, the Go finance-service too (WP118, ADR-0055)
covers() { # covers <gate script> <text the script must contain>
  total=$((total + 1))
  grep -qF -- "$2" "scripts/hooks/$1" && return 0
  fail=$((fail + 1))
  printf 'FAIL %s does not run: %s\n' "$1" "$2"
}
covers isolation-check.sh "run_go_tests services/finance-service CrossTenant ./..."
covers db-role-check.sh "run_go_tests services/finance-service DatabaseRole ./internal/adapters/out/persistence/"

# run_go_tests: quiet on success, fails when a test fails or the -run filter matched nothing (stub go on PATH)
go_gate() { # go_gate <stub go output> <stub go exit code>; prints "<rc>|<last line>"
  local dir out rc root=$PWD
  dir=$(mktemp -d)
  mkdir -p "$dir/bin" "$dir/repo/services/finance-service"
  printf '#!/bin/sh\nprintf "%%b" "%s"\nexit %s\n' "$1" "$2" >"$dir/bin/go"
  chmod +x "$dir/bin/go"
  out=$(cd "$dir/repo" && PATH="$dir/bin:$PATH" HOOK_LABEL=check bash -c \
    "source '$root/scripts/hooks/_common.sh' --functions-only; run_go_tests services/finance-service X ./..." 2>&1)
  rc=$?
  rm -rf "$dir"
  echo "$rc|$(tail -1 <<<"$out")"
}
check "go tests pass" "$(go_gate '--- PASS: TestA (0.1s)\\n--- PASS: TestB (0.1s)\\nok\\n' 0)" "0|✓ check (finance-service): 2 Go tests passed in * s"
check "go filter matched nothing" "$(go_gate 'ok  x 0.1s [no tests to run]\\n' 0)" "1|✗ check (finance-service) ran no Go tests*"
check "go test fails" "$(go_gate '--- FAIL: TestA (0.1s)\\n' 1)" "1|✗ check (finance-service) FAILED*"

# maven_offline_first: offline first; online again only when offline lacked an artifact (stub ./mvnw, calls logged)
mvn_gate() { # mvn_gate <stub output when offline> <stub exit code when offline>; prints "<rc>|<calls, one per line>"
  local dir rc root=$PWD
  dir=$(mktemp -d)
  printf '#!/bin/sh\necho "$*" >>calls\ncase " $* " in *" -o "*) printf "%%s\\n" "%s"; exit %s ;; esac\nexit 0\n' \
    "$1" "$2" >"$dir/mvnw"
  chmod +x "$dir/mvnw"
  (cd "$dir" && bash -c "source '$root/scripts/hooks/_common.sh' --functions-only; maven_offline_first log verify -q")
  rc=$?
  echo "$rc|$(cat "$dir/calls")"
  rm -rf "$dir"
}
check "maven offline passes: no online run" "$(mvn_gate 'BUILD SUCCESS' 0)" "0|-o -B -ntp verify -q"
check "maven offline lacks an artifact: online retry" \
  "$(mvn_gate '[ERROR] Cannot access central in offline mode and the artifact x has not been downloaded' 1)" \
  $'0|-o -B -ntp verify -q\n-B -ntp verify -q'
check "maven artifact never downloaded from that repo: online retry" \
  "$(mvn_gate '[ERROR] x was cached from a remote repository, but has not been downloaded from it before.' 1)" \
  $'0|-o -B -ntp verify -q\n-B -ntp verify -q'
check "maven test failure offline: no online retry" "$(mvn_gate '[ERROR] Tests run: 3, Failures: 1' 1)" \
  "1|-o -B -ntp verify -q"

echo "tenancy-gate matcher: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]
