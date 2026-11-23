# WP129 — Web: lists read every page (`fetchAll`, one `Pager`), live match stops polling, dead keys

Model: Opus · high. Wave 1 (2026-11-23, ninth round): runs alongside WP126 (game), WP127 (athlete), WP128 (core). You
own `apps/web/**` except `apps/web/packages/**` (generated, nobody touches it); nobody else touches the app. Depends
on: ADR-0030, WP13. Skills: work-package, flutter-feature, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp129-web-lists-whole-live-match-dispose`, branch
`wp129-web-lists-whole-live-match-dispose`.

Decision 105 of 2026-11-23: lists a screen needs whole load every page through one shared `fetchAll`; open-ended lists
use one shared `Pager` widget in place of the four copies. No contract change. ADR-0061 is reserved for you (write
it).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `apps-web.md`
(WEB-01, WEB-03, WEB-13), verification `verify-apps-web.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Lists (WEB-03, bug)**: 20 list calls read only the first page (50, 100 or 200) and show it as the whole list; the
   server refuses pages above 200. Failing tests first (the guardian login button for the 101st member; members,
   players, upcoming absences, fee plans, family dues). One `fetchAll` in `core` that loops over pages with a safety
   bound; one `Pager` widget replacing the four copies and their duplicate l10n keys. The demo mock must page like the
   server, or the tests prove nothing.
2. **Live match (WEB-01, bug)**: `liveMatchProvider` is never disposed: `autoDispose` plus an `unwatch(matchId)` that
   only stops the match it was given; a fake-time widget test shows the polls stop after leaving, for staff and
   non-staff.
3. **Dead content (WEB-13)**: `ModulePlaceholder`, 14 unused keys in the three ARB files, `cupertino_icons`; extend
   `l10n_keys_test` so unused keys fail.
4. **Docs**: ADR-0061; the paging rule in the `flutter-feature` skill.

Not yours: every other WEB finding (WP135, WP138). Golden files: re-record only what your change moves.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] no list call left that reads one page and shows it as all (the grep you used, in the handover)
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
- **Built**
  - **Lists (WEB-03).** `core/api/fetch_all.dart`: `fetchAll` reads pages of 200 until the server's last (or an empty)
    page, at most 50 pages, then `ListTooLongError` (never a silent cut). All 20 first-page-only reads go through it:
    players, teams (×2), approvals, cases, members, guardian links, training plans, assignments, completions, sessions,
    planned absences, injuries, test results, matches, tenants, tenant admins, academy requests, fee plans, a player's
    dues. `FinanceRepository.feePlans` / `playerDues` return lists now (the family tab and `playerDuesProvider` with
    them). One kit `Pager` (`core/ui/pager.dart`, keys `<prefix>-previous/-next`, l10n `pageOf` / `pagePrevious` /
    `pageNext`) replaces the dues, expenses, activity log and platform users copies and the `finance*` / `audit*`
    duplicate keys; `AuditQueryNotifier.goToPage` replaces next/previous, `AuditPage.hasPrevious/hasNext` (unused) gone.
    The activity log no longer shows "Página 1 de 1" on a single page, like the other three.
  - **Mock.** `MockQuery.page` pages like the services (size 1..200, default 50, else 400; negative page 400); the core
    mock's seven fixed one-page lists and the game mock's match list go through it (part of WEB-15).
  - **Live match (WEB-01).** `liveMatchProvider` is `autoDispose`; `SyncWorker.unwatch(matchId)` stops only that match
    (internal `_stopWatching` for `watch` and `dispose`).
  - **Dead content (WEB-13).** `ModulePlaceholder`, 14 keys × 3 ARBs (`placeholderModule` + the 13 of the verification),
    `cupertino_icons` (pubspec + lock). `l10n_keys_test` fails on a key no Dart file in `lib/` refers to.
- **Verified** (fresh, 2026-11-23): `flutter analyze` no issues; `just web-format-check` 513 files, 0 changed;
  `just web-test` **1861 passed, 0 failed** (baseline before the WP 1801). Red first, then green: `fetch_all_test`,
  `lists_read_every_page_test` (18 cases over `ServerPagesAdapter`, 450 items, pages 0/1/2 of 200),
  `finance_lists_every_page_test`, the guardian dialog's "101st guardian" test, `mock_paging_test` (25 list paths),
  `pager_test`, the two "leaving the live match" widget tests (COACH: worker pull stops; PARENT: worker pull and
  box-score poll stop, no feed or box-score call after 2 × 15 s of fake timers) and the guarded-unwatch test in
  `sync_worker_test`, `l10n_keys_test`. Goldens: the three `audit_activity_*` re-recorded (the single-page pager row is
  gone); new `kit/pager_light.png` / `pager_dark.png`; nothing else moved.
  - Grep for the acceptance item: `rg -n "data!\.items" lib` → nothing; `rg -n "\.list[A-Z]\w+\(" lib` → every paged
    operation is inside `fetchAll` except dues, expenses, the two audit trails, platform users (screens with `Pager`) and
    exercises (catalogue "load more"); the rest are unpaged arrays or the match feed (cursor).
- **Decisions/ADRs**: ADR-0061 (lists whole through `fetchAll` or paged with `Pager`; mock pages like the services);
  ADR-0040 amendment (WP129): `ModulePlaceholder` deleted, `Pager` in the kit. Skill `flutter-feature`: paging rule and
  provider-lifetime rule.
- **Open points**
  - `exerciseSearchProvider` (quick-add picker) still shows the first 50 matches of a typed search: a search's top
    results, documented as "the first page"; left as is.
  - FOLLOW-UPS l.582 "the family tab lists the first 50 dues (no paging)" is fixed by this WP (orchestrator: mark it).
  - WEB-15's other parts (`_problem` copies, the game mock's hand-parsed `clear`) stay for WP135/WP138.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| WEB-01 | Done | `liveMatchProvider` auto-dispose + `SyncWorker.unwatch(matchId)` guarded; widget tests for staff and non-staff |
| WEB-03 | Done | 20 reads through `fetchAll`; one kit `Pager` and one key set; the demo mock pages like the services (ADR-0061) |
| WEB-13 | Done | `ModulePlaceholder`, 14 keys × 3 ARBs and `cupertino_icons` deleted; `l10n_keys_test` fails on unused keys |
