# WP83 — CI: SAST (CodeQL, Semgrep, find-sec-bugs) and DAST (ZAP API scan, full scan on kind), findings triaged

Model: Opus. Wave 1 (2026-11-06, fifth round): runs alongside WP72 (web), WP78 (athlete), WP81 (core), WP87 (chart +
kind: it owns kind this wave, so your ZAP full scan on kind runs at the END of your WP, after you ask the
orchestrator whether kind is free, or on the compose stack through nginx if not). You own `.github/workflows/**`
(new `codeql.yml`, `semgrep.yml` or jobs in `ci.yml`; the ZAP jobs of `ci.yml` / `e2e.yml`), `.zap/**`,
`scripts/zap-gate.py`, `.semgrep/**`, the root `pom.xml` plugin section for SpotBugs/find-sec-bugs (+ a
`spotbugs-exclude.xml`), `docs/security/sast-dast.md` (new), `docs/security/review-2026-11.md` (new findings
section only). You do NOT fix findings in `services/**`, `libs/**` or `apps/web/**` (WP84, last and alone, does;
you may suppress obvious false positives with a justification). Depends on: WP50 (actions pinned to SHAs: pin every
new action), WP55/WP57 (ZAP baseline, `zap-gate.py`), ADR-0038. ADR-0045 reserved for you. Skills: owasp-security,
verification-before-completion, systematic-debugging. Worktree: `~/code/hoops-wt/wp83-ci-sast-dast`, branch
`wp83-ci-sast-dast`.

Decision 55 of 2026-11-06: all of them: CodeQL (Java, security-extended), Semgrep (Java and Dart rulesets, in a
container), SpotBugs/find-sec-bugs in `verify`, a ZAP API scan per service driven by the OpenAPI contracts with a
logged-in token in CI, a ZAP full scan against nginx/Keycloak on kind by hand once; findings fixed in WP84.

## Scope
1. **CodeQL**: `codeql.yml` (Java, `security-extended`, build with `./mvnw -DskipTests`), on push to main and PRs,
   SARIF to code scanning; gate = fail on new High/Critical (document how a finding is dismissed with a reason).
2. **Semgrep**: pinned container image, `p/java`, `p/owasp-top-ten`, the Dart/Flutter rules available, plus a few
   repo rules in `.semgrep/` (e.g. no `@PermitAll` on `/api` resources, no raw SQL string concat, no
   `skipTenantCheck`); SARIF upload; gate on ERROR severity; baseline file for accepted findings with expiry.
3. **SpotBugs + find-sec-bugs** bound to `verify` in the root pom (effort max, threshold medium, `spotbugs-exclude.xml`
   with justifications), so `just test` runs it; keep build time reasonable (report the delta).
4. **ZAP API scan**: per service, driven by the OpenAPI contract (`libs/contracts/openapi/<svc>.yaml`) against the
   compose stack with a super-admin token (login via `browser_login_check.py` or the password grant used by the e2e
   tests), `zap-api-scan.py`, active rules for APIs; accepted findings in `.zap/api-<svc>.conf` with justification;
   gate through `zap-gate.py`; in `e2e.yml` after the journey (the stack is up). Report the findings.
5. **ZAP full scan** (active) against nginx + Keycloak + web on kind (or compose if kind is busy): once, by hand;
   output in `docs/security/sast-dast.md` with the findings list.
6. **Docs**: ADR-0045 (the gates, what fails the build, how acceptances expire), `docs/security/sast-dast.md`
   (tools, how to run each locally with Podman, how to triage), the review file gains a "Round 5 SAST/DAST findings"
   section with every finding (tool, rule, location, severity, proposed fix) for WP84. `actionlint` clean.

## Acceptance
- [ ] All new workflows green on your branch's tree (run them: push is not allowed, so run the tools locally in
      containers as the workflows do, and paste the summaries; the orchestrator watches CI after the merge)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green with SpotBugs bound (fresh; totals and the time
      delta); `actionlint` clean; every action pinned to a commit SHA with a version comment
- [ ] Findings list complete in the review file; ADR-0045 indexed (append at the end of `docs/adr/README.md`)
- [ ] Handover appended: counts per tool and severity, what WP84 must fix first

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
