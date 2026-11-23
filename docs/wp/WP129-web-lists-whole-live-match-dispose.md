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
