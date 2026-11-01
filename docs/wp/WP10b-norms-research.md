# WP10b - Replace placeholder norms with published values

## Brief
Follow-up to WP10. Replace the placeholder youth fitness reference norms in
`services/athlete-service/src/main/resources/db/migration/R__physical_test_norms.sql` with cited, published values for ages 8-18 by
sex, using web research (FITNESSGRAM Healthy Fitness Zone, ALPHA-Fit / Eurofit / HELENA, Tomkinson et al., Cooper tables, peer-reviewed
sprint/jump/agility studies); percentiles are converted to the five bands by one documented rule; `source` per block; `reference_pending`
honest; docs in `docs/domain/norms.md`; verification `NormSeedTest, BandResolverTest, PhysicalTestApiTest`. Only that seed, the athlete-service
tests (if needed), `docs/domain/norms.md` and this file may change; no git; be honest if the web yields no usable table.

## Handover

### What changed
Seed rows (per gender and single year, 5 bands each; total 628 global rows):

| Test | Sex / ages | Before | After |
|---|---|---|---|
| COOPER_12MIN | boys, girls 13-19 | sourced ("from memory") | sourced; values cross-checked against two web reproductions (same figures); source text no longer says "from memory" but says the 1968 paper itself was not obtained and the table is not traceable to it |
| COOPER_12MIN | 8-12 | placeholder | placeholder (no youth table found) |
| BEEP_TEST | boys, girls 9-17 | placeholder | **sourced**: Zhang et al. 2020 JSSM Table 2, P20/P40/P60/P80 |
| BEEP_TEST | boys, girls 8 and 18 | placeholder | placeholder, extrapolated from Zhang (source text says how) |
| SIT_AND_REACH | boys, girls 8-18 | placeholder (linear model) | placeholder, **AVERAGE lower edge = FITNESSGRAM HFZ minimum** (boys 20.3 cm; girls 22.9 / 25.4 / 30.5 cm by age), other edges synthetic |
| SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST | all | placeholder | unchanged placeholder |

Counts (norm rows): sourced 30 -> 120; placeholder 598 -> 508 (BEEP_TEST: 0 -> 90 sourced; the other 90 BEEP rows and all SIT_AND_REACH rows stay pending).
The seed ids were reused (same natural key), so the upsert replaces values in place. Header comment of the seed and `docs/domain/norms.md`
(per-test source tables, percentile-to-band rule, mapping notes, how to verify, references) were updated. No test code changed.

### Decisions
- Band rule: P20/P40/P60/P80 are the edges (below P20 POOR ... P80+ EXCELLENT). Single-pass-mark criteria (FITNESSGRAM HFZ) never produce
  `reference_pending=false` and anchor only one edge.
- BEEP_TEST `level` = completed stages/minutes (decimal), the metric of Zhang Table 2; PACER laps are not mapped to levels (different
  protocol), no VO2max conversion used. Laps tables exist in the source but are not stored.
- Zhang 2020 (Chinese school children, general population) was used because Tomkinson et al. 2017 (international, preferred) could not be
  read (publisher 403, not in PMC/Europe PMC). It was marked sourced because the published centiles are exactly the band edges; the
  population caveat is in `source` and the docs. No athlete-sample norms were used anywhere.
- Ages outside a source's range are placeholders (never silently sourced).
- Cooper: kept `reference_pending=false` (needed by `NormSeedTest`'s Cooper check and figures match two reproductions), but the docs now state it is not primary-verified.

### How verified
`source scripts/env.sh && ./mvnw -pl services/athlete-service verify -Dtest='NormSeedTest,BandResolverTest,PhysicalTestApiTest' -Dsurefire.failIfNoSpecifiedTests=false`:
BUILD SUCCESS, 37 tests (NormSeedTest 5, BandResolverTest 16, PhysicalTestApiTest 16), 0 failures; the jacoco check also passed with the reduced selection.
`NormSeedTest` covers five contiguous ordered bands for every (test, gender, age 8-18), placeholders == flagged pending, and idempotent reruns with FORCE restored.

### Open points
- Replace BEEP_TEST 9-17 with Tomkinson et al. 2017 (BJSM 51:1545) P20/40/60/80 once the tables can be read; obtain Cooper 1968 / a primary age-sex table.
- SPRINT_20M, AGILITY_T_TEST, VERTICAL_JUMP: nothing usable obtained. Leads: FUPRECOL vertical jump (Ramirez-Velez 2017; percentiles P10/25/75/90, would need another band rule; its 50th percentiles ~24-38 cm boys, ~22-27 cm girls suggest the placeholder is too high at 14-18), Healthcare 2022;10(12):2486 (T-test, ages 14-15), Erciyes 7-14 Turkish study (20 m sprint), HELENA 4x10 m (different test).
- SIT_AND_REACH: needs a five-band source (e.g. ALPHA-Fit/HELENA centiles); check the current Cooper Institute HFZ manual (the 2014 district chart was used). The cm scale assumes the back-saver box (toes ~23 cm).
- The `level` convention (decimal completed stage) needs UI/entry guidance for coaches who record "level.shuttle".
- Web access was limited (several publishers returned 403); all numbers above were read from the Zhang PDF and the HFZ PDF text, not from memory.
