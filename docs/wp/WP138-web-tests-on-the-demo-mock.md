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
