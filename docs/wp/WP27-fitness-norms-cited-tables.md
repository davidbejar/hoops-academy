# WP27 — Fitness norms: replace placeholder bands with cited tables

Model: Opus. Depends on: WP10b (what exists). Skills: verification-before-completion, quarkus-hexagonal-service (only
the migration rules), tenant-isolation-testing (global rows). Worktree: `~/code/hoops-wt/wp27-norms`, branch
`wp27-norms`.

`services/athlete-service/src/main/resources/db/migration/R__physical_test_norms.sql` (repeatable; ids are uuid5 of
the natural key) seeds six global test types and their five-band norms per age and sex. Only COOPER_12MIN ages 13–19
and BEEP_TEST ages 9–17 (Zhang et al. 2020) are cited (`reference_pending = false`); the rest are synthetic
placeholders. `docs/domain/norms.md` documents the tables and sources. The product owner wants the missing tables
sourced now.

## Scope
- For SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST, SIT_AND_REACH, the Cooper ages outside 13–19 and the beep test
  outside 9–17: find published normative tables for children and adolescents by age and sex (candidates named in
  FOLLOW-UPS: Tomkinson 2017 for the shuttle run, ALPHA-Fit / HELENA for sit-and-reach, published sprint / T-test /
  countermovement-jump centiles; a primary Cooper table). Use web search in extended mode; prefer peer-reviewed
  sources with centiles (P20/P40/P60/P80 or equivalent) that map onto the five bands the schema uses.
- Replace placeholder rows with values from the source, `reference_pending = false`, `source` naming author, year
  and table; keep the uuid5 ids stable (same natural key ⇒ same id) so the upsert replaces rows.
- Where no defensible source exists for a test / age / sex, leave the placeholder and say why in `norms.md`.
  Never invent numbers; a placeholder that says so is better than a fake citation.
- Update `docs/domain/norms.md`: one section per test with the source, the population it describes, how the
  centiles were mapped to bands, and the remaining gaps (count of placeholder rows).
- Athlete tests that read the norms (search `reference_pending`, `physical_test_norm`, `bandStatus`) keep passing;
  if a test asserts the old count of placeholders, update it with the new count.

## Acceptance
- [ ] `R__physical_test_norms.sql` has cited rows for every test where a source was found; placeholders only where
      `norms.md` explains the gap
- [ ] `norms.md` lists every source with a resolvable reference (DOI or journal citation)
- [ ] Migration applies on a fresh database: `./mvnw -pl services/athlete-service -am verify` green (fresh run)
- [ ] Handover: number of cited rows before/after, sources used, gaps left

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees and share the Podman machine; retry a container start once
  before calling it a failure.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md (WP26 owns them); notes go in this file's Handover.
- Finish per the `work-package` skill: fresh full verification, checklist with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and numbers), left out and why,
  anything another WP must know.

## Handover

### Acceptance checklist
- [x] `R__physical_test_norms.sql` cites a source wherever one was found and could be read; placeholders only where
      `docs/domain/norms.md` explains the gap (per-test table "Per test: sources and status", section "Open leads").
- [x] `norms.md` lists every source with a DOI or journal citation (section "References"), plus the population, protocol and
      centile-to-band mapping per test.
- [x] Fresh run `./mvnw -pl services/athlete-service -am clean verify`: BUILD SUCCESS; athlete-service 586 tests, 0 failures
      (common-quarkus 172 + 120), coverage checks met; the migration applied on a fresh Testcontainers Postgres 17.
- [x] Handover (this section).

### Built
| Test | Before (WP10b) | After (WP27) | Source |
|---|---|---|---|
| BEEP_TEST | cited 9-17 (Zhang 2020), 8 and 18 placeholder | cited 8-18 | Ortega et al. 2023 (FitBack), BJSM 57:299, Table 1, printed P20/40/60/80 |
| SIT_AND_REACH | placeholder 8-18 (HFZ-anchored) | cited 9-17, placeholder 8 and 18 (repeat 9 / 17) | Catley & Tomkinson 2013, BJSM 47:98, corrected Table 10, printed P20/40/60/80 |
| SPRINT_20M | placeholder 8-18 | cited 8-17, placeholder 18 (repeats 17) | Cossio-Bolaños et al. 2026, J Pediatr (Rio J) 102(6):101596, Table 4, centiles computed from the published LMS |
| AGILITY_T_TEST, VERTICAL_JUMP | placeholder 8-18 | cited 14-15, rest unchanged synthetic placeholders | Mascherini et al. 2022, Healthcare 10(12):2486, Tables 2-5, P20-P80 interpolated between P10/25/50/75/90 |
| COOPER_12MIN | cited 13-19, placeholder 8-12 | unchanged | no youth table under 13 found |

Rows (630 global): cited 120 -> 370, placeholder 510 -> 260 (COOPER 50, SIT 20, SPRINT 10, VJ 90, T-test 90). All ids reused
(same natural key), so the repeatable seed upserts in place. The SIT_AND_REACH test-type description now states the scale
(20 cm = fingertips at the toes, Catley's convention). Tests: `NormSeedTest` +5 (one per source with sample band edges taken
from the printed tables, and a pinned placeholder count per test); `PhysicalTestApiTest`'s placeholder example moved from
SPRINT_20M (now cited at 16) to VERTICAL_JUMP.

### Decisions
- BEEP_TEST 9-17 moved from Zhang 2020 to FitBack 2023, which is outside the strict scope. The reason is that one source
  now covers 8-18 without a jump at the source boundary, and FitBack is the international reference the follow-ups asked for.
  Zhang stays documented as a tenant-override option.
- Two new ways to get the band edges, both documented in norms.md "Percentile to band rule": exact centiles from published
  LMS parameters (checked: they reproduce the 264 printed centiles within rounding), and linear interpolation when only
  P10/25/50/75/90 are printed. Rows built either way are flagged cited, and the method is named in each row's `source`.
- Every numeric value was extracted with a script from the downloaded article (PMC HTML or PDF text), not typed by hand.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5` (the model that did the work) instead of the brief's Fable line.

### Open points
- VERTICAL_JUMP: Moreno-Gonzalez et al., BMC Pediatr 2026 (doi:10.1186/s12887-026-07796-1; sport-participating 6-17, CMJ),
  is open access but could not be fetched (bot challenge, no PMC copy yet). It is the best candidate to replace the remaining
  90 rows.
- AGILITY_T_TEST 8-13/16-18: no readable youth table. The synthetic girls' placeholders are about 1.2 s too fast next to the
  Florentine data, so they should be re-modelled or overridden.
- COOPER_12MIN 8-12: no published centile table found.
- The Catley PDF was a third-party copy of the publisher version. Check it against the BMJ copy.
- The sit-and-reach scale changed from the back-saver box (toes at 22.9 cm) to toes at 20 cm, and the web UI should show the
  unit hint.
- WP26 (docs) should update `docs/conformance.md` S-44 and `docs/roadmap.md` line 71, which still describe the WP10b sourcing.
  This WP did not edit them, to avoid conflicts.
