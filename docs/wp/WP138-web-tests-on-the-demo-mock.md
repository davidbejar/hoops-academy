# WP138 — Web: the tests run against the demo mock; the separate test fakes go

Model: Opus · high. Wave 4 (2026-11-23, ninth round): starts after wave 3 is merged; runs alongside WP137 (library,
services, build). You own `apps/web/**` except `apps/web/packages/**` and `apps/web/test/fixtures/vectors/**` with its
test (WP137 owns those); nobody else touches the app. Depends on: WP129, WP135; ADR-0030. Skills: work-package,
flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp138-web-tests-on-the-demo-mock`, branch `wp138-web-tests-on-the-demo-mock`.

Decision 108 of 2026-11-23: the widget tests run against the demo mock, seeded per test; the separate test fakes are
deleted feature by feature. ADR-0070 is reserved for you (write it; it amends ADR-0030).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `apps-web.md`
(WEB-02), verification `verify-apps-web.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Seeding**: the demo mock gets a small seeding API for tests (empty tenant, one of each, failure injection for the
   error paths the fakes covered) without demo data leaking into tests or test hooks into the release build
   (`build_web.sh` already refuses mock mode for releases: keep that true and add a test or check for it).
2. **Migrate feature by feature**: one commit per feature: tests move to the mock, the feature's fake is deleted. A
   test that only a fake could express (a server error the mock cannot produce) gets failure injection, not a second
   fake. A difference between mock and fake is a finding: decide which was right against the contract and list it in
   the handover.
3. **Stop when it stops paying**: if a feature's fake cannot go without making its tests worse, keep it, say why, and
   state how many of the 3,580 fake lines are left.

Not yours: generated clients; goldens change only if the seeded data must differ (list them).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] test count before and after (no test silently lost: explain every removed test)
- [ ] lines of test fakes before and after
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
- **Built** (all under `apps/web`; ADR-0070)
  - **Seeding (scope 1).** `MockApiAdapter` takes `demo` (false: both academies and the platform start empty;
    `MockAcademy.empty` makes the core, athlete and game mocks skip their seed), `tenantAId` (the test academy's id)
    and `latency` (zero in tests). The mocks expose the collections the tests seed as `@visibleForTesting` (core:
    `auditEvents`; platform: `tenants`, `admins`, `auditEvents`, `academyRequests`, `usageOf`, `historyOf`,
    `logins`; the adapter: `academy(id)`, `platform`). `apiAdapterProvider` (`core/http/dio_provider.dart`) is the
    one seam the app's Dio sends through. `test/support/mock_backend.dart`: `MockBackend`, the empty mock with
    failure injection (`fail` status/code/once, `hang` released on demand, `networkDown`, `heal`), a request log
    (`requestsTo`, `lastQuery`, `lastBody`) and the mock's answers (`lastAnswer`); `coreJson` turns generated models
    into seeds. The `Harness` installs a `MockBackend` (roles, super admin and academy of the test user) behind every
    repository it does not fake. Seed helpers: `audit_seed.dart`, `platform_seed.dart` (the former fixture builders).
  - **Release (scope 1).** `tool/verify_no_mock.dart` (run by `build_web.sh` after the build) fails when
    `main.dart.js` or a deferred part holds a string only the mock API has; `verify_no_mock_test.dart`. Checked on
    real builds: the release build passes, a `HOOPS_MOCK_API=true` build fails on both markers.
  - **Migrated (scope 2), one commit each, fake deleted:** activity log (`fake_audit.dart`, 3 test files), academy
    requests (`fake_academy_requests.dart`, 5 files), platform console (`fake_platform.dart`, 11 files incl.
    `platform_test.dart`, users, goldens, a provider unit test). Failures the mock can produce are produced by it
    (taken slug, request decided meanwhile, invitation accepted meanwhile, last administrator removed meanwhile).
  - **Mock and fake differed (decided against `core.yaml`, red test first, the fake was right each time, mock fixed):**
    1. the academy trail ignored `action` / `from` / `to` (`listAuditEvents`): now filtered, 400 when `from` ≥ `to`;
    2. an e-mail that already signs in still got a temporary password (`createTenant`, `addTenantAdmin`): now none,
       invitation ACCEPTED; 3. the last administrator could be removed: now 409 `LAST_ADMIN` (`removeTenantAdmin`).
- **Verified** (fresh, 2026-11-24): `flutter analyze` no issues; `just web-format-check` 527 files, 0 changed;
  `just web-test` **1939 passed, 0 failed, 0 skipped** (baseline at the start 1921 passed). +18 tests, none removed: 1 trail filter, 3
  administrator rules, 7 `mock_backend_test`, 7 `verify_no_mock_test`; every migrated file has the same test count as
  before (audit 30, requests 63, platform files unchanged; whole suite 1939 after each feature commit, run on a copy
  of the tree). Goldens re-recorded: the three `temporary_password_*` only (the dialog shows the mock's password,
  which wraps on one line fewer); every other golden of the migrated screens passes as recorded.
  - Fake lines (the seven files of the verification): 3,565 at the start (3,580 in the audit, `fake_finance.dart`
    has shrunk since) → **2,937** left (`fake_repos` 825, `fake_athlete` 1,529, `fake_game` 326, `fake_finance`
    257). Added: `mock_backend.dart` 237, `audit_seed.dart` 69, `platform_seed.dart` 162 (about 100 of them the
    moved builders), `problems.dart` 19.
- **Decisions/ADRs**: ADR-0070 (amends ADR-0030), appended to `docs/adr/README.md`.
- **Open points / not done**
  - **Core, athlete, game, finance keep their fakes** (2,937 lines): not done for time, in this order next. Core
    first: the athlete and game mocks take authz (staff rows, guardian links, the own player) and rosters from the
    core mock, so they need a `seedMembership` that makes the core mock's authz match the test membership
    (`staffTeamIds`, `linkedPlayerIds`, `ownPlayerId`) before their tests can move; then roster/admin screens
    (`fake_repos.dart`, 47 files), game (12), athlete (20). Finance: `FakeFinanceRepository` already wraps the real
    repository over the mock (no second imitation of the rules), but over the *demo* seed; moving it means explicit
    finance seeds in an empty academy.
  - `MockAuthService` is compiled into the release bundle (unreachable: the guard refuses mock mode); the new check
    covers the mock API only. Making it drop out needs a const guard that the tests' `appConfigProvider` override
    would no longer reach (owner's call).
  - The platform mock answers 409 `ALREADY_ADMIN` (not in the contract) for an e-mail that is already an
    administrator; no test needs it, left as is.
  - FOLLOW-UPS l.519 (mock 409 vs service 404 for the season balance) belongs to the finance move, still open.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| WEB-02 | Done (part) | Tests on the seeded demo mock (ADR-0070); audit, academy-request and platform fakes deleted (628 lines); 3 mock/contract differences fixed; core, athlete, game and finance fakes (2,937 lines) left for follow-up WPs |
