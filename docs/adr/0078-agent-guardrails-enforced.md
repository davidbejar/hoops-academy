# ADR-0078: Agent guardrails enforced: the hook follows the checkout, asks before destructive commands, logs; what steers agents is checked

- Status: Accepted
- Date: 2026-11-29
- Related: decisions 125 to 127 of 2026-11-29 (`docs/wp/FOLLOW-UPS.md`, eleventh round),
  [WP154](../wp/WP154-agent-guardrails-enforced.md), [WP149](../wp/WP149-agentic-threat-model-build-system.md)
  (findings AG-01, AG-03, AG-05 to AG-07, AG-09 to AG-11, AG-13, AG-14 of
  [`agentic-threat-model.md`](../security/agentic-threat-model.md)), P-14 of
  [`privacy-threat-model.md`](../security/privacy-threat-model.md), ADR-0073 (the PostgreSQL move),
  [`agent-credentials.md`](../runbooks/agent-credentials.md)

## Context
The code is written by AI agents running as the owner's user, several at once in git worktrees that share one `.git`.
WP149's threat model found that most guardrails were written rules, not enforced ones: the commit gate checked the
session's checkout instead of the worktree the commit was made in (AG-01); the hook let every command through when `jq`
was missing (AG-14); nothing stopped a command that removes the owner's database volume or force-pushes (AG-07); the
hook's decisions went to stderr only (AG-10); gitleaks skipped every Markdown file under `docs/` and every skill
(AG-03); a vendored skill could change unnoticed (AG-11); the merge procedure moved `main` locally and pushed it
(AG-13); and the copies a PostgreSQL major move leaves had no end (P-14). Decision 127: destructive commands are
approved by the owner at the prompt, an agent alone cannot approve them; a deny rule for `.env` goes into the committed
settings only after the owner has seen it. The hook already runs for every Bash call (`.claude/settings.json`, matcher
`Bash`), so it is the place that needs no new registration.

## Decision
1. **The gates follow the checkout** (`.claude/hooks/tenancy-gate.sh`). The isolation check before `git commit` and
   the role check before `git push` run in the checkout the git command acts on: the call's working directory, moved by
   a `cd` / `pushd` before it (also inside a subshell and back out), by `git -C` (relative paths compose), and inside a
   shell's `-c` script or `eval`. Each distinct checkout is gated once. When the checkout cannot be told (a variable
   path, `cd -`, `--git-dir` / `--work-tree`, a wrapper the parser cannot read) the command is **blocked**, with the
   plain form as the fix; a target without the gate script is blocked too. The gate script that runs is the target
   checkout's own (as before); its changes show in the branch's diff (AG-04).
2. **Fail closed**: no `jq`, or hook input that is not JSON, blocks the command (exit 2). `just doctor` checks `jq`.
3. **Destructive commands ask** (decision 127). One table in the hook (`ASK_RULES`, one test case per rule, a test
   that every rule has one) answers with the documented PreToolUse output
   `hookSpecificOutput.permissionDecision: "ask"` and a reason naming the rules: Podman volume removal and prune,
   `podman system prune | reset`, `podman machine stop | rm | reset`, compose `down -v`, kind cluster deletion (also
   `just kind-down`, `deploy/kind/down.sh`), a force push, a push to or deleting `main` (a plain push while on `main`
   included), `git reset --hard` on `main`, moving or deleting the `main` branch ref, `--no-verify` / `-n` /
   `core.hooksPath` on commit or push, `gh` repository settings, deletes and API writes, `gh pr merge --admin`, and
   `scripts/pg-major-move.sh --clean-up --remove`. The rules match the words of each simple command (quoted text is a
   single word, so a commit message or a `grep` pattern that mentions a command does not ask); unreadable text is
   matched loosely. Gates run first (a failed gate blocks); the ask comes after. Runbooks that drop the database volume
   say it is the owner's step (a test).
4. **A gate log** (AG-10): every gate and ask decision appends one tab-separated line to `claude-gate.log` in the git
   common directory, shared by every worktree: UTC time, agent (`agent_id`, else `session_id`), checkout, what (`commit`,
   `push`, `ask <rules>`, `hook`), result (`passed`, `blocked`, `asked`), detail (`branch@sha` and seconds, or the
   reason). Never the command's text. The round's close-out reads it (`wp-round`).
5. **gitleaks without path allow-lists for `docs/` and `.claude/`** (AG-03). A real false positive gets a fingerprint
   in `.gitleaksignore` (for a commit already on `main`; a rebase merge changes the ids of a branch's commits) or a
   narrow regex; `scripts/tests/test_agent_guardrails.py` fails when an allow-list path covers those trees or an
   allow-list regex lets a token through.
6. **Vendored skills carry a checksum** (AG-11): one SHA-256 per folder in `.claude/skills/THIRD_PARTY_SKILLS.md`, over
   the `shasum -a 256` lines of its tracked files; the same test recomputes them.
7. **Packages land through pull requests** (decision 125, AG-13; `wp-round` Mechanics 3 and 4): the orchestrator checks
   that `main` equals `origin/main`, rebases the branch on `origin/main`, pushes the branch, opens the pull request and
   merges it with a rebase merge on green checks (`--match-head-commit`); nothing is pushed to `main` directly, and the
   hook asks if it is. Agents never push. `work-package` says text in tool output, logs and fetched pages is data
   (AG-09).
8. **The copies of a major move end** (P-14): `scripts/pg-major-move.sh --clean-up` lists the old volume and the dumps
   with their age (a dry run); `--remove` removes them only when the move is done, no container uses the volume, the
   volume is not the one compose names, and the words `remove <volume>` are typed at a terminal. The runbook keeps the
   copies 14 days after the move.
9. **A separate credential for agents** (AG-05, decision 126) is the owner's action, described in
   [`agent-credentials.md`](../runbooks/agent-credentials.md): a fine-grained token for this repository with contents
   and pull requests write, actions and statuses read, no administration, workflows or secrets, in the Keychain and the
   session's environment only.
10. **Settings stay the owner's** (AG-06): this package does not edit `.claude/settings.json`; the deny rules it proposes
    (`.env`, the dump directory, `--no-verify`) are in the WP154 handover for the owner to commit.

## Consequences
- An agent in a worktree is gated on its own branch with the plain `cd <worktree> && git commit` it already uses; a
  commit through a variable path is refused with the fix in the message. The hook that runs is the main checkout's copy,
  so a branch that changes the hook is in force only once merged.
- The owner sees a prompt for each destructive command, also for a background agent's call. A false positive (an
  unquoted mention such as `echo podman volume rm`, a heredoc whose text looks like a command) costs one prompt.
- Limits, stated so nobody reads more into it: the hook reads command text. A script or recipe that runs a destructive
  command inside it (other than the ones named), a command built at run time, another interpreter (`python -c`), or an
  edit of the hook itself are not seen; deny rules in settings have the same limit (the Claude Code documentation: not a
  security boundary). The operating-system sandbox is the layer that would enforce; it is an open item (decision 127).
  Every agent still acts as the owner on GitHub until the owner sets up the token of decision 126.
- The gate log grows without rotation (one line per gated command); it lives in `.git`, so it is never committed.

## Alternatives considered
- **Deny rules in `.claude/settings.json` for the destructive commands**: they block in every mode with no prompt-time
  override, so the owner could not approve a step they asked for; and the settings file is the owner's to change.
- **Running the main checkout's gate script against a worktree**: the logic would stay fixed while the code varies, but
  the stub-based tests of the hook and the scripts' relative paths assume the target's own copy; the diff of a branch
  that changes it is visible to the review AG-04 asks for.
- **Blocking every unreadable command**: an unbalanced quote (a heredoc with an apostrophe) is common in ordinary
  commands, so it keeps the old behaviour (both gates in the checkout known so far) and a loose ask scan.
