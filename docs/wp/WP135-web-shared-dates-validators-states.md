# WP135 — Web: one home for dates, validators, export buttons, error messages, section states

Model: Sonnet · high. Wave 3 (2026-11-23, ninth round): starts after wave 2 is merged; runs alongside WP134 (library
and services), WP136 (chart, kind). You own `apps/web/**` except `apps/web/packages/**`; nobody else touches the app.
Depends on: WP129; ADR-0030, ADR-0032, ADR-0040, ADR-0042. Skills: work-package, flutter-feature,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp135-web-shared-dates-validators-states`, branch `wp135-web-shared-dates-validators-states`.

Decision 104 of 2026-11-23: everything confirmed in the web app is fixed. ADR-0067 is reserved for you if a decision
is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `apps-web.md`
(WEB-04..WEB-17 except WEB-13), verification `verify-apps-web.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Dates (WEB-04)**: one `core/time/dates.dart`, the dead helpers deleted; goldens re-recorded only where the text
   really changes, each listed in the handover.
2. **Forms (WEB-07)**: `core/ui/validators.dart` (email, decimal, blank-to-null) and one `formatMeasure`; the
   0/1/2-decimal disagreement in health is a bug: failing test first.
3. **Exports (WEB-06)**: one `ServerExportButton` for the CSV and PDF buttons with one handling of `EXPORT_TOO_LARGE`
   and 503.
4. **Errors and states (WEB-08, WEB-05)**: one code-to-message table; one section loading / error / empty widget in
   place of the seven variants.
5. **Providers (WEB-09, as corrected)**: low impact: `autoDispose` where it is plainly right; `auditQueryProvider` and
   `playerNameProvider` stay as they are.
6. **The rest**: every other WEB finding of your scope, including the copied test set-up and the Python browser-test
   helpers under `apps/web/tool`.

Not yours: WEB-02 (WP138). `apps/web/lib/l10n/*.arb`: keys next to the related feature's keys, never at the end.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] golden files re-recorded: the list and the reason for each
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
