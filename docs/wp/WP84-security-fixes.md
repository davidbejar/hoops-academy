# WP84 — Security fixes: every SAST/DAST finding of WP83 fixed or accepted, review file updated

Model: Opus. Wave 5 (2026-11-06, fifth round): last, alone (fixes may touch every module and the web app). You own
everything the findings point at (`services/**`, `libs/**`, `apps/web/**`, `infra/**`, `deploy/**`), the acceptance
files of WP83 (`.zap/*.conf`, `spotbugs-exclude.xml`, `.semgrep/**` baseline, CodeQL dismissals documented),
`docs/security/review-2026-11.md` (the "Round 5 SAST/DAST findings" section: status per finding) and
`docs/security/sast-dast.md`. Depends on: WP83 (handover: the findings list by priority), ADR-0045, every ADR the
fixes touch. Skills: owasp-security, systematic-debugging, test-driven-development, verification-before-completion.
Worktree: `~/code/hoops-wt/wp84-security-fixes`, branch `wp84-security-fixes`.

Decision 55 of 2026-11-06 (continued): the second round of testing: fix every High/Medium finding, fix or accept
(justification + expiry) every Low, re-run every tool clean.

## Scope
1. Walk the WP83 findings list by priority; for each: reproduce (a red test where the finding is a real defect),
   fix, or accept with a justification and an expiry in the tool's acceptance file; never weaken a gate.
2. Re-run every tool locally as the workflows do (CodeQL via the CLI in a container if feasible, Semgrep, SpotBugs in
   `verify`, ZAP API scans on compose, the full scan on kind if WP83 ran it there): all clean / all accepted.
3. Review file: every finding row gets a status (Fixed <commit> / Accepted until <date> / False positive <why>);
   totals line; ASVS rows touched by the fixes updated.

## Acceptance
- [ ] Red tests for real defects committed first; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals; SpotBugs included); `flutter analyze`, `just web-format-check`, `just web-test` green if the
      web changed
- [ ] Every tool clean locally (summaries in the handover); `just e2e` 23/23 on compose; chart tests green if
      `deploy/**` changed
- [ ] Review file complete; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
