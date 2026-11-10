#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash (.claude/settings.json). Gates Claude's own git commands:
#   git commit -> tenant isolation check: academy A logs in, cannot read academy B (scripts/hooks/isolation-check.sh)
#   git push   -> database role check: no service connects as owner/superuser/BYPASSRLS (scripts/hooks/db-role-check.sh)
# A failing check blocks the command (exit 2); its failures reach Claude on stderr. Every other command passes at once.
# The checks test the working tree of the repository the command runs in (a worktree included).
# shellcheck disable=SC1003 # the backslash in '\\' is meant literally
set -uo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$command" ] || exit 0

# Old, loose matcher: `git`, optional global options, then the subcommand as a whole word, anywhere in the text.
# Used only where the strict parser cannot see inside (a shell wrapper's quoted script, a substitution in quotes).
loose_git() {
  local before="(^|[;&|({\"'[:space:]])" opts="([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+|[[:space:]]+--[a-z][a-z-]*(=[^[:space:]]+)?)*"
  grep -qE "${before}git${opts}[[:space:]]+$1([[:space:];&|)]|\$)" <<<"$2"
}

# Words that may precede the command word of a simple command without changing what runs.
is_prefix_word() { # is_prefix_word <word>
  case "$1" in
    '{' | '!' | if | then | else | elif | do | while | until | time | command | exec | env | nohup | sudo) return 0 ;;
    [A-Za-z_]*=*) return 0 ;; # FOO=1
    *) return 1 ;;
  esac
}

# classify_simple <stripped> <raw>: sets want_commit / want_push for ONE simple command. <stripped> has quoted strings
# replaced by Q; <raw> keeps them (only the shell-wrapper fallback reads it).
classify_simple() {
  local -a w
  local i=0 n word sub
  read -r -a w <<<"$1"
  n=${#w[@]}
  [ "$n" -gt 0 ] || return 0
  while [ "$i" -lt "$n" ] && { is_prefix_word "${w[i]}" || { [ "${w[i]:0:1}" = - ] && [ "${w[i - 1]:-}" = env ]; }; }; do i=$((i + 1)); done
  [ "$i" -lt "$n" ] || return 0
  word=${w[i]}
  case "$word" in
    git | */git) ;;
    bash | sh | zsh | dash | ksh | eval | xargs | */bash | */sh | */zsh | ssh | watch | su)
      # The script is a quoted string the strict parser dropped: look inside it, loosely.
      loose_git commit "$2" && want_commit=1
      loose_git push "$2" && want_push=1
      return 0 ;;
    Q | \$*)
      # A quoted or variable command word ("$GIT" commit): unknown program, so any commit/push word counts.
      for sub in "${w[@]:i+1}"; do
        [ "$sub" = commit ] && want_commit=1
        [ "$sub" = push ] && want_push=1
      done
      return 0 ;;
    *) return 0 ;;
  esac
  i=$((i + 1))
  while [ "$i" -lt "$n" ]; do # git global options up to the subcommand
    case "${w[i]}" in
      -C | -c | --git-dir | --work-tree | --namespace | --exec-path | --super-prefix | --config-env) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      commit) want_commit=1; return 0 ;;
      push) want_push=1; return 0 ;;
      *) return 0 ;;
    esac
  done
}

# classify_command <text>: sets want_commit / want_push. Splits the text into simple commands on ; & | ( ) newline,
# $( ) and backticks, drops comments and quoted strings. Unreadable text (unbalanced quotes) wants both gates.
classify_command() {
  local text=$1 ch next cur="" raw="" q="" len=${#1} i=0 word_start=1 loose=0
  want_commit=0 want_push=0
  flush() {
    if [ "$loose" -eq 1 ]; then
      loose_git commit "$raw" && want_commit=1
      loose_git push "$raw" && want_push=1
    fi
    classify_simple "$cur" "$raw"
    # Belt: a wrapper the strict parser does not know (timeout, nice, env -u X, caffeinate, a redirection first) still
    # runs git. Quoted text is already gone from $cur, so a mention inside quotes stays a non-match.
    loose_git commit "$cur" && want_commit=1
    loose_git push "$cur" && want_push=1
    cur="" raw="" loose=0 word_start=1
  }
  while [ "$i" -lt "$len" ]; do
    ch=${text:i:1}
    next=${text:i+1:1}
    if [ -n "$q" ]; then
      raw+=$ch
      if [ "$q" = "'" ]; then
        [ "$ch" = "'" ] && q=""
      elif [ "$ch" = '\' ]; then
        raw+=$next; i=$((i + 1))
      elif [ "$ch" = '"' ]; then
        q=""
      elif [ "$ch" = '`' ] || { [ "$ch" = '$' ] && [ "$next" = '(' ]; }; then
        loose=1 # command substitution inside double quotes runs
      fi
      i=$((i + 1))
      continue
    fi
    case "$ch" in
      "'" | '"') q=$ch; raw+=$ch; [ "$word_start" -eq 0 ] || cur+="Q"; word_start=0 ;;
      '\') if [ "$next" = $'\n' ]; then cur+=" "; raw+=" "; word_start=1 # a line continuation joins the lines
            else cur+="${ch}${next}"; raw+="${ch}${next}"; word_start=0; fi
            i=$((i + 1)) ;;
      '#') if [ "$word_start" -eq 1 ]; then
             while [ "$i" -lt "$len" ] && [ "${text:i:1}" != $'\n' ]; do i=$((i + 1)); done
             continue
           fi
           cur+=$ch; raw+=$ch ;;
      ';' | '&' | '|' | '(' | ')' | $'\n' | '`') flush ;;
      '$') if [ "$next" = '(' ]; then flush; i=$((i + 1)); else cur+=$ch; raw+=$ch; word_start=0; fi ;;
      ' ' | $'\t') cur+=" "; raw+=" "; word_start=1 ;;
      *) cur+=$ch; raw+=$ch; word_start=0 ;;
    esac
    i=$((i + 1))
  done
  if [ -n "$q" ]; then want_commit=1 want_push=1; return 0; fi # unbalanced quote: unsure, so gate
  flush
}

gate() { # gate <script> <what> <action> <name>
  local start=$SECONDS
  if "$1" >&2; then
    echo "tenancy-gate: $4 PASSED in $((SECONDS - start)) s" >&2
  else
    echo "Blocked: $2 failed, so this git $3 did not run. Fix the cause above; do not bypass this hook." >&2
    exit 2
  fi
}

classify_command "$command"
if [ -n "${TENANCY_GATE_CLASSIFY_ONLY:-}" ]; then # for scripts/hooks/tenancy-gate.test.sh
  out=""
  [ "$want_commit" -eq 1 ] && out="commit"
  [ "$want_push" -eq 1 ] && out="${out:+$out }push"
  echo "${out:-none}"
  exit 0
fi
[ "$want_commit" -eq 1 ] || [ "$want_push" -eq 1 ] || exit 0

cwd=$(jq -r '.cwd // empty' <<<"$input")
cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || cd "${CLAUDE_PROJECT_DIR:-.}" || exit 2
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Blocked: $PWD is not inside a git repository." >&2; exit 2; }
cd "$root" || exit 2

if [ "$want_commit" -eq 1 ]; then gate scripts/hooks/isolation-check.sh "the tenant isolation check" commit isolation-check; fi
if [ "$want_push" -eq 1 ]; then gate scripts/hooks/db-role-check.sh "the database role check" push db-role-check; fi
exit 0
