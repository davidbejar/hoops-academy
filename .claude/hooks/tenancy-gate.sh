#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash (.claude/settings.json), ADR-0078. For every command Claude runs:
#   git commit -> tenant isolation check: academy A logs in, cannot read academy B (scripts/hooks/isolation-check.sh)
#   git push   -> database role check: no service connects as owner/superuser/BYPASSRLS (scripts/hooks/db-role-check.sh)
# Each check runs in the checkout the git command acts on: the call's working directory, moved by a `cd` / `pushd`
# before it and by `git -C`. When that cannot be told (a variable, `cd -`, --git-dir / --work-tree, a wrapper the
# parser cannot read) the command is blocked: run it as a plain command. A failing check blocks (exit 2); its failures
# reach Claude on stderr.
# A destructive command (the table below) gets the answer "ask": the owner approves it at the prompt, an agent alone
# cannot (decision 127). Every other command passes at once, silently.
# Each gate and ask decision appends one line to claude-gate.log in the git common directory (shared by every worktree):
# time, agent, checkout, what, result, detail. Never the command's text.
# Without jq the hook cannot read the command, so it blocks every command (exit 2).
#
# ASK_RULES (one case per rule in scripts/hooks/tenancy-gate.test.sh; the test reads this table):
#   podman-volume-rm  podman volume rm | remove | prune
#   podman-system-prune  podman system prune | reset
#   podman-machine  podman machine stop | rm | remove | reset
#   compose-down-volumes  podman compose … down -v | --volumes, podman-compose down -v, just down -v
#   kind-delete-cluster  kind delete cluster(s), just kind-down, deploy/kind/down.sh
#   git-force-push  git push --force | -f | --force-with-lease | --mirror | --prune | +<refspec>
#   git-push-main  git push to or deleting main (a refspec onto main, --all, a plain push or HEAD while on main)
#   git-reset-hard-main  git reset --hard while on main (or in a checkout that cannot be told)
#   git-main-ref  git branch -d | -D | -f | -m | -M … main, git checkout -B main, git switch -C main, git update-ref … main
#   gh-repo-settings  gh repo edit | rename | archive | unarchive | deploy-key, gh secret | variable set, gh workflow enable | disable
#   gh-delete  gh <anything> delete | delete-asset | remove | rm
#   gh-api-write  gh api with a method other than GET / HEAD, or with fields or --input and no -X GET
#   gh-merge-admin  gh pr merge --admin (bypasses required checks)
#   pg-copies-remove  scripts/pg-major-move.sh --clean-up --remove (the old volume and the dump, P-14)
# shellcheck disable=SC1003 # the backslash in '\\' is meant literally
set -uo pipefail

# Encodings inside the literal words: whitespace that was quoted, and a mark for text the shell expands at run time.
SP=$'\x1f' TB=$'\x1d' NL=$'\x1c' DYN=$'\x1e'
log_dir="" agent="-"

block() { echo "Blocked: $*" >&2; exit 2; }

log() { # log <checkout> <what> <result> [detail]: one line in the shared git directory, never the command text
  [ -n "$log_dir" ] || return 0
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$agent" "$1" "$2" "$3" "${4:-}" \
    >>"$log_dir/claude-gate.log" 2>/dev/null || true
}

find_log_dir() { # find_log_dir <dir…>: the git common directory of the first of them inside a repository
  local d
  for d in "$@"; do
    [ -n "$d" ] || continue
    d=$(git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && { log_dir=$d; return 0; }
  done
  return 0
}

if ! command -v jq >/dev/null 2>&1; then
  find_log_dir "${CLAUDE_PROJECT_DIR:-}" "$PWD"
  log "-" hook blocked jq-missing
  block "jq is missing, so .claude/hooks/tenancy-gate.sh cannot read the command and lets none run. Install jq (brew install jq); \`just doctor\` checks for it."
fi
input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) ||
  block "the hook input is not JSON that .claude/hooks/tenancy-gate.sh can read, so the command did not run."
[ -n "$command" ] || exit 0
session_dir=$(jq -r '.cwd // empty' <<<"$input")
agent=$(jq -r '.agent_id // .session_id // "-"' <<<"$input")
base=${session_dir:-${CLAUDE_PROJECT_DIR:-$PWD}}

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

decode() { # decode <literal word>: the text the shell would pass, run-time expansions left as written
  local s=${1//$SP/ }
  s=${s//$TB/$'\t'}
  s=${s//$NL/$'\n'}
  printf '%s' "${s//$DYN/}"
}

resolve_dir() { # resolve_dir <base> <literal word>: the absolute directory, or ? when it cannot be told
  local base=$1 p=$2
  case "$p" in *"$DYN"*) echo "?"; return ;; esac
  p=$(decode "$p")
  # shellcheck disable=SC2088 # the quoted tilde is the text to replace
  case "$p" in
    '~') p=$HOME ;;
    '~/'*) p=$HOME/${p#'~/'} ;;
    '~'*) echo "?"; return ;;
  esac
  case "$p" in
    /*) echo "$p" ;;
    *) if [ "$base" = "?" ]; then echo "?"; else echo "${base%/}${p:+/$p}"; fi ;;
  esac
}

# Result lists: "commit<TAB>dir" / "push<TAB>dir" lines, and the ask rules, each once.
targets="" asks=""
add_target() { # add_target <commit|push> <dir>
  case $'\n'"$targets" in *$'\n'"$1"$'\t'"$2"$'\n'*) ;; *) targets+="$1"$'\t'"$2"$'\n' ;; esac
}
add_ask() { case $'\n'"$asks" in *$'\n'"$1"$'\n'*) ;; *) asks+="$1"$'\n' ;; esac; }
count_targets() { local nl=$'\n' t; t=${targets//[!$nl]/}; echo "${#t}"; }

has_word() { # has_word <word> <words…>
  local want=$1 w
  shift
  for w in "$@"; do [ "$w" = "$want" ] && return 0; done
  return 1
}
has_pair() { # has_pair <first> <"alternatives"> <words…>: first directly followed by one of the alternatives
  local first=$1 alts=" $2 " prev="" w
  shift 2
  for w in "$@"; do
    [ "$prev" = "$first" ] && case "$alts" in *" $w "*) return 0 ;; esac
    prev=$w
  done
  return 1
}
positionals() { # positionals <words…>: sets pos to the words that are not options
  pos=()
  local w
  for w in "$@"; do case "$w" in -*) ;; *) pos+=("$w") ;; esac; done
}

# git_where <literal words…>: sets g_dir (the checkout the first git command in them acts on, or ?) and g_i (index
# of its subcommand, -1 when there is none).
git_where() {
  local -a a=("$@")
  local n=$# i=0
  g_dir=$dir g_i=-1
  while [ "$i" -lt "$n" ]; do case "${a[i]}" in git | */git) break ;; esac; i=$((i + 1)); done
  [ "$i" -lt "$n" ] || { g_dir="?"; return 0; }
  i=$((i + 1))
  while [ "$i" -lt "$n" ]; do
    case "${a[i]}" in
      -C) [ $((i + 1)) -lt "$n" ] || { g_dir="?"; return 0; }
          g_dir=$(resolve_dir "$g_dir" "${a[i + 1]}"); i=$((i + 2)) ;;
      --git-dir | --work-tree | --git-dir=* | --work-tree=*) g_dir="?"; i=$((i + 1)) ;;
      -c | --namespace | --exec-path | --super-prefix | --config-env) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      *) g_i=$i; return 0 ;;
    esac
  done
}

on_main() { # on_main: the checkout g_dir is on branch main, or cannot be told
  [ "$g_dir" != "?" ] || return 0
  [ "$(git -C "$g_dir" symbolic-ref --short -q HEAD 2>/dev/null)" = main ]
}

ask_push() { # ask_push <words after push>
  local w skip=0 remote="" force=0 tomain=0 n=0 dst
  for w in "$@"; do
    if [ "$skip" -eq 1 ]; then skip=0; continue; fi
    case "$w" in
      -o | --push-option | --repo | --receive-pack | --exec) skip=1 ;;
      --force | --force-with-lease* | --force-if-includes | --mirror | --prune) force=1 ;;
      --all | --branches) tomain=1 ;;
      --*) ;;
      -*f*) force=1 ;;
      -*) ;;
      *) if [ -z "$remote" ]; then remote=$w; continue; fi
         n=$((n + 1))
         case "$w" in +*) force=1 ;; esac
         w=${w#+}
         dst=${w##*:}
         case "$dst" in *"$DYN"*) on_main && tomain=1 ;; esac # "$(git branch --show-current)": the current branch
         if [ "$dst" = HEAD ] && [ "$w" = HEAD ]; then on_main && tomain=1; fi
         [ "${dst#refs/heads/}" = main ] && tomain=1 ;;
    esac
  done
  [ "$n" -gt 0 ] || [ "$tomain" -eq 1 ] || ! on_main || tomain=1
  [ "$force" -eq 0 ] || add_ask git-force-push
  [ "$tomain" -eq 0 ] || add_ask git-push-main
}

ask_git() { # ask_git <literal words>
  local -a a=("$@") r=()
  local w sub moves=0
  git_where "$@"
  [ "$g_i" -ge 0 ] || return 0
  sub=${a[g_i]}
  r=("${a[@]:g_i+1}")
  [ "${#r[@]}" -gt 0 ] || r=("")
  case "$sub" in
    push) ask_push "${r[@]}" ;;
    reset) if has_word --hard "${r[@]}" && on_main; then add_ask git-reset-hard-main; fi ;;
    branch)
      has_word main "${r[@]}" || has_word refs/heads/main "${r[@]}" || return 0
      for w in "${r[@]}"; do case "$w" in --delete | --force | --move | -[!-]*[dDfmM]* | -[dDfmM]) moves=1 ;; esac; done
      [ "$moves" -eq 0 ] || add_ask git-main-ref ;;
    checkout) if has_pair -B main "${r[@]}"; then add_ask git-main-ref; fi ;;
    switch) if has_pair -C main "${r[@]}" || has_pair --force-create main "${r[@]}"; then add_ask git-main-ref; fi ;;
    update-ref) if has_word main "${r[@]}" || has_word refs/heads/main "${r[@]}"; then add_ask git-main-ref; fi ;;
  esac
}

ask_gh() { # ask_gh <words after gh>
  local w skip=0 method="" fields=0
  local -a rest=()
  for w in "$@"; do # -R / --repo take a value that is not a subcommand
    if [ "$skip" -eq 1 ]; then skip=0; continue; fi
    case "$w" in -R | --repo) skip=1 ;; *) rest+=("$w") ;; esac
  done
  [ "${#rest[@]}" -gt 0 ] || return 0
  positionals "${rest[@]}"
  [ "${#pos[@]}" -gt 0 ] || return 0
  case " ${pos[*]:1:2} " in *" delete "* | *" delete-asset "* | *" remove "* | *" rm "*) add_ask gh-delete; return 0 ;; esac
  case "${pos[0]} ${pos[1]:-}" in
    "repo edit" | "repo rename" | "repo archive" | "repo unarchive" | "repo deploy-key" | "secret set" | "variable set" | \
      "workflow enable" | "workflow disable") add_ask gh-repo-settings ;;
    "pr merge") if has_word --admin "$@"; then add_ask gh-merge-admin; fi ;;
    api*)
      skip=0
      for w in "$@"; do
        if [ "$skip" -eq 1 ]; then method=$w; skip=0; continue; fi
        case "$w" in
          -X | --method) skip=1 ;;
          --method=*) method=${w#--method=} ;;
          -X*) method=${w#-X} ;;
          -f | -F | --field | --raw-field | --input | -f* | -F* | --field=* | --raw-field=* | --input=*) fields=1 ;;
        esac
      done
      method=$(tr '[:lower:]' '[:upper:]' <<<"$method")
      case "$method" in
        GET | HEAD) ;;
        "") [ "$fields" -eq 0 ] || add_ask gh-api-write ;;
        *) add_ask gh-api-write ;;
      esac ;;
  esac
}

ask_rules() { # ask_rules <literal words of one simple command>: adds the destructive rules they match
  local -a a=("$@")
  local n=$# i=0 prog="" w
  while [ "$i" -lt "$n" ]; do
    w=${a[i]}
    case "${w##*/}" in
      podman | podman-compose | kind | git | gh | just | pg-major-move.sh) prog=${w##*/}; break ;;
      down.sh) case "$w" in *kind/down.sh) prog=kind-down; break ;; esac ;;
    esac
    i=$((i + 1))
  done
  [ -n "$prog" ] || return 0
  local -a args=("${a[@]:i+1}")
  [ "${#args[@]}" -gt 0 ] || args=("")
  positionals "${args[@]}"
  [ "${#pos[@]}" -gt 0 ] || pos=("")
  case "$prog" in
    podman | podman-compose)
      if has_pair volume "rm remove prune" "${pos[@]}"; then add_ask podman-volume-rm; fi
      if has_pair system "prune reset" "${pos[@]}"; then add_ask podman-system-prune; fi
      if has_pair machine "stop rm remove reset" "${pos[@]}"; then add_ask podman-machine; fi
      if { [ "$prog" = podman-compose ] || has_word compose "${pos[@]}"; } && has_word down "${pos[@]}" &&
        { has_word -v "${args[@]}" || has_word --volumes "${args[@]}"; }; then add_ask compose-down-volumes; fi ;;
    kind) if has_pair delete "cluster clusters" "${pos[@]}"; then add_ask kind-delete-cluster; fi ;;
    kind-down) add_ask kind-delete-cluster ;;
    just)
      [ "${pos[0]}" != kind-down ] || add_ask kind-delete-cluster
      if [ "${pos[0]}" = down ] && { has_word -v "${args[@]}" || has_word --volumes "${args[@]}"; }; then
        add_ask compose-down-volumes
      fi ;;
    git) ask_git "${a[@]:i}" ;;
    gh) ask_gh "${args[@]}" ;;
    pg-major-move.sh) if has_word --remove "${args[@]}"; then add_ask pg-copies-remove; fi ;;
  esac
}

# loose_asks <text>: the ask rules over text the parser could not read (an unbalanced quote): quotes dropped, split on
# separators and newlines.
loose_asks() {
  local t=${1//[\'\"]/ } line
  local -a w
  t=${t//[;&|()\`]/$'\n'}
  while IFS= read -r line; do
    read -r -a w <<<"$line"
    [ "${#w[@]}" -eq 0 ] || ask_rules "${w[@]}"
  done <<<"$t"
}

# change_dir <literal words>: follows cd / pushd / popd for the commands after it
change_dir() {
  local -a a=("$@")
  local n=$# i=0 arg=""
  while [ "$i" -lt "$n" ] && is_prefix_word "${a[i]}"; do i=$((i + 1)); done
  [ "$i" -lt "$n" ] || return 0
  case "${a[i]}" in
    cd | pushd) ;;
    popd) dir="?"; return 0 ;;
    *) return 0 ;;
  esac
  i=$((i + 1))
  while [ "$i" -lt "$n" ]; do
    case "${a[i]}" in
      -) dir="?"; return 0 ;;
      -* | *'>'* | *'<'*) ;;
      *) arg=${a[i]}; break ;;
    esac
    i=$((i + 1))
  done
  if [ -z "$arg" ]; then dir=$HOME; else dir=$(resolve_dir "$dir" "$arg"); fi
}

# classify_simple <stripped> <raw> <literal> <depth>: ONE simple command. <stripped> has quoted strings replaced by Q;
# <raw> keeps them as written; <literal> has the words as the shell passes them (quoted whitespace encoded).
classify_simple() {
  local -a w lw
  local i=0 n word sub found_c=0 found_p=0 before script saved j
  read -r -a w <<<"$1"
  read -r -a lw <<<"$3"
  [ "${#lw[@]}" -eq 0 ] || { change_dir "${lw[@]}"; ask_rules "${lw[@]}"; }
  n=${#w[@]}
  [ "$n" -gt 0 ] || return 0
  while [ "$i" -lt "$n" ] && { is_prefix_word "${w[i]}" || { [ "$i" -gt 0 ] && [ "${w[i]:0:1}" = - ] && [ "${w[i - 1]:-}" = env ]; }; }; do i=$((i + 1)); done
  [ "$i" -lt "$n" ] || return 0
  word=${w[i]}
  case "$word" in
    git | */git)
      i=$((i + 1))
      while [ "$i" -lt "$n" ]; do # git global options up to the subcommand
        case "${w[i]}" in
          -C | -c | --git-dir | --work-tree | --namespace | --exec-path | --super-prefix | --config-env) i=$((i + 2)) ;;
          -*) i=$((i + 1)) ;;
          commit) found_c=1; break ;;
          push) found_p=1; break ;;
          *) break ;;
        esac
      done ;;
    bash | sh | zsh | dash | ksh | eval | xargs | */bash | */sh | */zsh | ssh | watch | su)
      # A shell's -c script and eval's words are read like a command line (in a child: its cd stays inside);
      # anything else the hook cannot follow: the loose matcher, and the checkout cannot be told.
      script="" j=0
      if [ "${word##*/}" = eval ]; then
        script=$(decode "${lw[*]:1}")
      else
        while [ "$j" -lt "${#lw[@]}" ]; do
          case "${lw[j]}" in -c | -[!-]*c*) [ $((j + 1)) -lt "${#lw[@]}" ] && script=$(decode "${lw[j + 1]}"); break ;; esac
          j=$((j + 1))
        done
      fi
      before=$(count_targets)
      if [ -n "$script" ] && [ "$4" -lt 4 ]; then
        saved=$dir
        classify_command "$script" $(($4 + 1))
        dir=$saved
      fi
      if [ "$(count_targets)" -eq "$before" ]; then
        loose_git commit "$2" && add_target commit "?"
        loose_git push "$2" && add_target push "?"
      fi
      return 0 ;;
    Q | \$*)
      # A quoted or variable command word ("$GIT" commit): unknown program, so any commit/push word counts.
      for sub in "${w[@]:i+1}"; do
        [ "$sub" = commit ] && add_target commit "?"
        [ "$sub" = push ] && add_target push "?"
      done
      return 0 ;;
  esac
  # Belt: a wrapper the strict parser does not know (timeout, nice, env -u X, caffeinate, a redirection first) still
  # runs git. Quoted text is already gone from the stripped text, so a mention inside quotes stays a non-match.
  [ "$found_c" -eq 1 ] || ! loose_git commit "$1" || found_c=1
  [ "$found_p" -eq 1 ] || ! loose_git push "$1" || found_p=1
  [ "$found_c" -eq 1 ] || [ "$found_p" -eq 1 ] || return 0
  git_where "${lw[@]}"
  [ "$found_c" -eq 0 ] || add_target commit "$g_dir"
  [ "$found_p" -eq 0 ] || add_target push "$g_dir"
}

# classify_command <text> <depth>: splits the text into simple commands on ; & | ( ) newline, $( ) and backticks,
# drops comments, follows cd into subshells and back out. Unreadable text (an unbalanced quote) wants both gates in
# the directory known so far and gets the ask rules loosely.
classify_command() {
  local text=$1 depth=$2 ch next cur="" raw="" lit="" q="" len=${#1} i=0 word_start=1 loose=0
  local -a dirs=()
  flush() {
    local before=$targets added
    classify_simple "$cur" "$raw" "$lit" "$depth"
    if [ "$loose" -eq 1 ]; then # a git command inside a substitution in quotes, unless it is this command itself
      added=${targets#"$before"}
      case "$added" in commit$'\t'* | *$'\n'commit$'\t'*) ;; *) loose_git commit "$raw" && add_target commit "?" ;; esac
      case "$added" in push$'\t'* | *$'\n'push$'\t'*) ;; *) loose_git push "$raw" && add_target push "?" ;; esac
    fi
    cur="" raw="" lit="" loose=0 word_start=1
  }
  enc() { case "$1" in ' ') lit+=$SP ;; $'\t') lit+=$TB ;; $'\n') lit+=$NL ;; *) lit+=$1 ;; esac; }
  while [ "$i" -lt "$len" ]; do
    ch=${text:i:1}
    next=${text:i+1:1}
    if [ -n "$q" ]; then
      raw+=$ch
      if [ "$q" = "'" ]; then
        if [ "$ch" = "'" ]; then q=""; else enc "$ch"; fi
      elif [ "$ch" = '\' ]; then
        raw+=$next
        case "$next" in '$' | '`' | '"' | '\') lit+=$next ;; $'\n') ;; *) lit+='\'; enc "$next" ;; esac
        i=$((i + 1))
      elif [ "$ch" = '"' ]; then
        q=""
      elif [ "$ch" = '`' ] || { [ "$ch" = '$' ] && [ "$next" = '(' ]; }; then
        loose=1 lit+="$DYN$ch" # command substitution inside double quotes runs
      elif [ "$ch" = '$' ]; then
        lit+="$DYN$ch"
      else
        enc "$ch"
      fi
      i=$((i + 1))
      continue
    fi
    case "$ch" in
      "'" | '"') q=$ch; raw+=$ch; [ "$word_start" -eq 0 ] || cur+="Q"; word_start=0 ;;
      '\') if [ "$next" = $'\n' ]; then cur+=" "; raw+=" "; lit+=" "; word_start=1 # a line continuation joins the lines
            else cur+="${ch}${next}"; raw+="${ch}${next}"; enc "$next"; word_start=0; fi
            i=$((i + 1)) ;;
      '#') if [ "$word_start" -eq 1 ]; then
             while [ "$i" -lt "$len" ] && [ "${text:i:1}" != $'\n' ]; do i=$((i + 1)); done
             continue
           fi
           cur+=$ch; raw+=$ch; lit+=$ch ;;
      '(') flush; dirs+=("$dir") ;;
      ')') flush
           if [ "${#dirs[@]}" -gt 0 ]; then dir=${dirs[${#dirs[@]} - 1]}; unset 'dirs[${#dirs[@]}-1]'; fi ;;
      ';' | '&' | '|' | $'\n' | '`') flush ;;
      '$') if [ "$next" = '(' ]; then flush; dirs+=("$dir"); i=$((i + 1))
           else cur+=$ch; raw+=$ch; lit+="$DYN$ch"; word_start=0; fi ;;
      ' ' | $'\t') cur+=" "; raw+=" "; lit+=" "; word_start=1 ;;
      *) cur+=$ch; raw+=$ch; lit+=$ch; word_start=0 ;;
    esac
    i=$((i + 1))
  done
  if [ -n "$q" ]; then # unbalanced quote: unsure, so gate, and look for destructive words loosely
    add_target commit "$dir"
    add_target push "$dir"
    loose_asks "$text"
    return 0
  fi
  flush
}

dir=$base
classify_command "$command" 0

case "${TENANCY_GATE_CLASSIFY_ONLY:-}" in # for scripts/hooks/tenancy-gate.test.sh
  "") ;;
  plan)
    printf '%s' "$targets" | tr '\t' ' '
    printf '%s' "$asks" | sed 's/^/ask /'
    exit 0 ;;
  *)
    out=""
    case "$targets" in commit$'\t'* | *$'\n'commit$'\t'*) out="commit" ;; esac
    case "$targets" in push$'\t'* | *$'\n'push$'\t'*) out="${out:+$out }push" ;; esac
    echo "${out:-none}"
    exit 0 ;;
esac
[ -n "$targets$asks" ] || exit 0
find_log_dir "$base" "${CLAUDE_PROJECT_DIR:-}"

gated=""
gate_at() { # gate_at <commit|push> <dir>
  local what=$1 d=$2 script label name top head start
  case "$what" in
    commit) script=scripts/hooks/isolation-check.sh label="the tenant isolation check" name=isolation-check ;;
    *) script=scripts/hooks/db-role-check.sh label="the database role check" name=db-role-check ;;
  esac
  if [ "$d" = "?" ]; then
    log "?" "$what" blocked unknown-checkout
    block "cannot tell which checkout this git $what acts on (a variable, \`cd -\`, --git-dir / --work-tree, or a wrapper the hook cannot read), so it did not run. Run it as a plain \`git $what\`, after \`cd <dir> &&\` or as \`git -C <dir> $what\`."
  fi
  top=$(cd "$d" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null && :) || {
    log "$d" "$what" blocked not-a-repository
    block "$d is not inside a git repository, so this git $what did not run."
  }
  top=$(cd "$top" && pwd -P)
  case $'\n'"$gated" in *$'\n'"$what $top"$'\n'*) return 0 ;; esac
  gated+="$what $top"$'\n'
  if [ ! -x "$top/$script" ]; then
    log "$top" "$what" blocked no-gate-script
    block "$top has no $script, so $label cannot run there and this git $what did not run."
  fi
  head="$(git -C "$top" rev-parse --abbrev-ref HEAD 2>/dev/null)@$(git -C "$top" rev-parse --short HEAD 2>/dev/null)"
  start=$SECONDS
  if (cd "$top" && "./$script") </dev/null >&2; then
    log "$top" "$what" passed "$head $((SECONDS - start)) s"
    echo "tenancy-gate: $name PASSED in $((SECONDS - start)) s, checkout $top" >&2
  else
    log "$top" "$what" blocked "$head $name failed"
    echo "Blocked: $label failed in $top, so this git $what did not run. Fix the cause above; do not bypass this hook." >&2
    exit 2
  fi
}

while IFS=$'\t' read -r what d; do
  [ -n "$what" ] && gate_at "$what" "$d"
done <<<"$targets"

if [ -n "$asks" ]; then
  rules=$(printf '%s' "$asks" | paste -sd ',' -)
  log "$base" "ask $(printf '%s' "$asks" | paste -sd ' ' -)" asked
  jq -nc --arg r "Destructive command ($rules): only the owner approves it here, an agent alone cannot (decision 127, ADR-0078). Approve only what you asked for." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
fi
exit 0
