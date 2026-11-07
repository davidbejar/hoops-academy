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
- Built (statuses and evidence per finding in `docs/security/review-2026-11.md`, "Round 5 SAST/DAST findings"):
  - **SD-02** (4f2fdbe, 099524e, 1c08ba0; red 58e7a3c): once in common-quarkus. `UnsafeUriGuard` (Vert.x route before the
    body limit): a C0 control or DEL in path or query, literal or `%XX`, is a 400 `bad-request` Problem
    `INVALID_CHARACTERS`; `SafeTextJackson` (`ObjectMapperCustomizer`): NUL in a JSON string (`SafeStringDeserializer`)
    or anywhere in a `JsonNode` tree (`SafeTreeDeserializer`, the PATCH bodies) is a 400 `validation` Problem naming
    the field; backstop in `ProblemExceptionMappers.unexpected`: SQLSTATE 22021/22P05 in the cause chain is a 400.
    Pure rules in `UnsafeText` / `ProblemMapping` (PIT scope); `RouteProblems` shared with `RequestBodyLimit`.
  - **SD-01** (a02be78; red 58e7a3c, 7917f99): `common.paging.PageOffset.of(page, size)` in all nine sites (CodeQL saw
    five; core `PageRequest`, game `JpaMatchRepository`, seven athlete repositories): offsets past
    `Integer.MAX_VALUE - 200` are clamped, so the page is empty instead of a 500 or a wrapped page.
  - **SD-04, SD-06, SD-08** (5078d40): compose nginx forwards no `Upgrade`/`Connection`, sends `localhost:8080` as
    `Host`/`X-Forwarded-Host`; `Permissions-Policy`, COOP, CORP on the deny pages and every Keycloak answer (compose
    and the chart's Keycloak HTTPRoutes); e2e step 54. **SD-07** (d49f279): Dependabot `cooldown` 7 days.
    **SD-05** (070e1b7): `AuditEventSource` enum instead of String SQL fragments. **SD-03**: accepted until 2027-05-07
    (3b49f93, `.zap/baseline.conf`), after checking every cookie-backed Keycloak path cross-origin.
  - Acceptances: 4 Semgrep and 5 CodeQL entries removed (STALE); ZAP 40038 full-scan false positive accepted. Docs:
    ASVS 2.2.1, V3 headers/CORS, V15, new V13 (edge proxy) rows; `sast-dast.md` re-run notes (CodeQL command needed
    `mkdir -p /src/target`); `mutation.md` scope and scores.
- Verified (2026-11-07, rebased on main b520476):
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: BUILD SUCCESS in 5:53, again (fresh, same totals, 6:00) at
    b2ce7b0 after the last code change; common 392, contracts 279, core 914,
    game 468, athlete 994, e2e module 32 (26 journeys skipped without a stack); SpotBugs `BugInstance size is 0` × 4
    (the first run caught two SpotBugs findings in my `SafeTreeDeserializer`, fixed in 099524e); coverage gates met.
  - `just e2e` on compose: JourneyTest **26/26** (25 + the new step 54). Chart: `deploy/helm/tests/run.sh` ALL CHART
    TESTS PASSED (4 snapshots re-recorded, kubeconform 254/254 valid).
  - Semgrep 1.183.0: 327 rules / 1403 files, 21 results (ERROR 20 all accepted, WARNING 1 false positive), gate green;
    `semgrep --test` 10/10; gate scripts 20 unit tests OK. CodeQL 2.27.4 (linux-arm64 bundle, checksum verified, JDK
    container, 179 s): High 2, both accepted, gate green. ZAP API scans: core Low 1/Info 2, game High 1 (accepted)/Low
    1/Info 2, athlete Low 1/Info 2, all gates green, no Server Error. ZAP baseline (as `ci.yml`): Medium 5 (accepted),
    gate green. ZAP full scan (compose, 263 s): High 1 / Medium 6 / Low 3 / Info 8, triage gate green.
  - By hand through nginx: `q=%00` → 400 Problem; NUL in a PATCH → 400 naming `name`; `Upgrade: h2c` → 401 (plain);
    `Host: evil.example` → `Location: http://localhost:8080/...`.
  - PIT: common-quarkus 312/313 (99.7 %, baseline 99; four equivalent survivors in my first `UnsafeText` removed by
    1c08ba0; the survivor is the old `CoreRosterClient` one), core 777/778, game 548/550, athlete 687/687: all at or
    above their baselines.
- Decisions/ADRs: no new ADR (fixes inside ADR-0045's process). Bodies refuse only NUL; other control characters stay
  storable text (an offline event batch must not be poisoned by a stray character). Pages past the last row are empty
  rather than a 400 (no contract change). COEP not set (not applicable). SD-03 accepted, not filtered at the edge (the
  5173 dev server is a legitimate CORS client).
- Open points / follow-ups:
  - The chart's Keycloak `ResponseHeaderModifier` is validated by the chart tests only, not proven on kind (no kind run).
  - The chart pins `Host` only when `gateway.hostname` is set; kind accepts any host (local only).
  - Two duplicate `X-Content-Type-Options: nosniff` on some Keycloak answers (Keycloak's and the proxy's; harmless).
