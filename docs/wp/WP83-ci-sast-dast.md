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
- Built:
  - **SpotBugs 4.10.5 + find-sec-bugs 1.14.0** bound to `verify` in every module (root `pom.xml`: effort Max,
    threshold Medium, `failOnError`, XML + SARIF reports, `-Dspotbugs.skip` for inner loops only);
    `spotbugs-exclude.xml` with a justification per `<Match>` (EI_EXPOSE_REP/REP2 global, the rest per class).
  - **CodeQL** `.github/workflows/codeql.yml` (push to main, PRs, weekly; Java, `security-extended`, manual build of the
    main code only with `-Dmaven.test.skip=true`), gate `scripts/sarif-gate.py --fail-on high` with
    `.github/codeql/accepted.json`.
  - **Semgrep** `.github/workflows/semgrep.yml` (pinned `semgrep/semgrep:1.183.0@sha256:…`; `p/java`,
    `p/owasp-top-ten`, 10 repository rules in `.semgrep/rules` for tenancy/authz/SQL (Java) and the Flutter app (Dart),
    fixtures in `.semgrep/tests`; `.semgrepignore`), gate `--fail-on error` with `.semgrep/accepted.json`, SARIF to code
    scanning; the job also runs the gate scripts' unit tests (`scripts/tests`, 20 tests).
  - **SARIF gate** `scripts/sarif-gate.py`: entries = rule + path + line-text fingerprint + reason + expiry (mandatory),
    STALE / EXPIRED reporting, `--suggest`. **ZAP gate** `scripts/zap-gate.py`: `[expires=]` tag, exit 2 on an IGNORE
    without justification or with a bad date.
  - **ZAP API scan** `scripts/zap-api-scan.sh <svc>` (PKCE sign-in as the super admin by `scripts/zap-login.py`; hook
    `.zap/hooks/bearer_refresh.py` refreshes the 5-min token at start and every 4 min; API policy, no rule switched
    off; acceptances `.zap/api-{core,game,athlete}.conf`), in `e2e.yml` after the journeys (timeout 40 → 100 min,
    reports as artifact). ZAP image pinned by digest there and in `ci.yml` `zap-baseline` (was `:stable`).
  - Docs: ADR-0045 (indexed), `docs/security/sast-dast.md` (tools, gates, local runs with Podman, triage, first-run
    results and the full-scan findings), review section "Round 5 SAST/DAST findings" (SD-01 … SD-08).
- Verified:
  - `python3 -m unittest discover -s scripts/tests`: 20 OK (red first: 3 zap-gate + 11 sarif-gate failures, and the
    CodeQL `extensions` case). `semgrep --test`: 10/10 rules. `actionlint`: clean; 0 `uses:` without a 40-hex SHA
    and version comment (new: `github/codeql-action/{init,analyze,upload-sarif}@33d7b85… # v4.39.3`, the commit
    behind the annotated tag); `shellcheck scripts/zap-api-scan.sh` clean.
  - SpotBugs: 388 raw findings → 0 after exclusions, `BugInstance size is 0` in all 4 modules; a planted
    string-concatenated JDBC query failed the build (SQL_INJECTION_JDBC, SQL_NONCONSTANT_STRING_PASSED_TO_EXECUTE).
    Cost: `spotbugs:check` alone 13–18 s per module incl. ~4 s Maven start-up (core on the critical path, ~45 s CPU
    for all). Full `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: before 457 s, after (`clean verify`)
    659 s, both under other agents' load, so the wall-clock delta is noise; the SpotBugs share is the ~15 s above.
    Tests: common-quarkus 186, contracts 223, core 871, game 411, e2e 27 (23 journeys skipped without a stack), all
    green; **athlete 773 not green**: before SpotBugs 1 error (`ReplicaAuthzRulesTest`, Redpanda Testcontainer), after
    the same error plus 1 failure (`ScheduleApiTest`, run on a Friday evening in Madrid), both outside WP83 (open
    points); athlete's SpotBugs check passed in the standalone `compile spotbugs:check` run (0 in all 4 modules).
  - CodeQL 2.27.4 (the bundle codeql-action v4.39.3 uses, linux-arm64, checksum verified) in a JDK container: 7 High
    → gate green with 7 acceptances. Semgrep: 26 results → gate green (20 ERROR accepted).
  - ZAP API scans on compose through nginx (super admin, no 401 after the hook fix): core 587 s Low 3 / Info 2,
    game 278 s High 1 (rate-limit false positive, accepted) / Low 2 / Info 2, athlete 343 s Low 2 / Info 2; all three
    gates exit 0. ZAP full scan on compose (kind held by WP87): 710 s, High 1, Medium 6, Low 6, Info 8 (triaged).
    Stack wiped afterwards (`down -v`, `just up`, `just seed-users`), as agreed with the orchestrator.
  - Not run: the workflows themselves (no push); the orchestrator watches CI after the merge.
- Decisions/ADRs: ADR-0045 (gates, what fails the build, acceptances with reason + expiry, no inline suppressions,
  API scan as the super admin). Deviations from the brief: CodeQL builds with `-Dmaven.test.skip=true` (not
  `-DskipTests`) so test code is not analysed; "new High/Critical" = not in `accepted.json` (works the same locally,
  independent of GitHub's alert state); the API scan does not pass `-c` to ZAP because ZAP would switch IGNOREd rules
  off in the active scan; acceptances are applied by `zap-gate.py` after it.
- Open points / follow-ups:
  - **WP84, in this order:** SD-02 (NUL byte → 500, `q=%00` on `/platform/tenants`; fix once in common-quarkus),
    SD-01 (`page * size` int overflow, 5 sites; its acceptance expires 2026-12-15), SD-04 (nginx forwards `Upgrade`
    on `/api/game/`), SD-06 (client `Host` forwarded), SD-08 (Permissions-Policy / CORP on nginx 403 and Keycloak),
    SD-07 (Dependabot cooldown), SD-03 (Keycloak CORS reflection on public endpoints: confirm and accept), SD-05
    (typed SQL fragments in `AuditEventQueryRepository`). No High/Critical true positive was found by any tool.
  - **athlete tests (not WP83's code, nothing in `services/**` changed):** `ScheduleApiTest.
    endingAScheduleRemovesFutureSessionsButKeepsThoseWithAttendance` fails on Fridays from 19:00 to 24:00
    Europe/Madrid (today's FRIDAY 19:00 session is then past and kept: expected 1, was 2; reproduced alone at 19:52
    Madrid). `ReplicaAuthzRulesTest` errored in both full runs (Redpanda Testcontainer: `localhost:2375 failed to
    respond` under load) and passes alone (10/10). Owner: the athlete WP / FOLLOW-UPS.
  - The API scan's super admin is in no academy, so tenant endpoints stop at 404/400: a member token with
    `X-Tenant-Id` (e.g. an e2e-created admin) would reach the academy logic; worth a later round.
  - The repo `.env` exposes the Keycloak admin console locally (`HOOPS_EXPOSE_KC_ADMIN=true`), which adds master-realm
    CSP alerts to local ZAP runs (as WP57 noted).
  - `docs/security/asvs-checklist.md` not touched (not in my files): a V15 line "SAST/DAST in CI (ADR-0045)" fits.
  - Registry rulesets (`p/java`, `p/owasp-top-ten`) are fetched at run time and drift; the weekly runs will surface new
    results on old code. Semgrep reports 9 partial-parse warnings (workflow `run:` blocks, a Dart mock, a shell file).
  - The Semgrep/CodeQL SARIF uploads need code scanning enabled on the repository (public repo: on by default).

