# Physical test norms: sources, placeholders and tenant overrides

Reference norms turn a physical test result into an **expected band** (`POOR`, `BELOW_AVERAGE`, `AVERAGE`,
`ABOVE_AVERAGE`, `EXCELLENT`) for the player's gender and age on the day of the test. They live in
`athlete.physical_test_norm` and are seeded by `services/athlete-service/src/main/resources/db/migration/R__physical_test_norms.sql`.

**Honesty rule.** Only values that could be cited are presented as sourced. Everything else is a *placeholder*:
synthetic, monotone bands that keep the product usable until a cited table is entered. Placeholders have
`reference_pending = true` and a `source` that starts with "placeholder"; the API returns `referencePending: true` for
a result whose band came from such a row and the UI shows a "reference pending" flag. The database refuses a norm
without a source unless it is flagged pending (`check (reference_pending or source is not null)`).

> The seed was prepared without access to the original publications. The Cooper (1968) values below were
> transcribed **from memory** of the widely reproduced age/sex table and must be verified against the original paper (or
> replaced by the academy's own table through a tenant override) before anyone relies on them for decisions.

## Band semantics

* Row = (test type, gender, `min_age`..`max_age` inclusive, band, `min_value`, `max_value`).
* The value range of a band is **[min_value, max_value)**: minimum included, maximum excluded; a missing bound is open.
* Age is the player's age in **full years on `measured_on`**, from the birth date in core-service.
* "Higher is better" (`higher_is_better` on the test type) does not take part in the lookup, the ranges already say which
  end is good. It orders a table for sanity checks (`BandResolver.bandsAreOrdered`, used by `NormSeedTest`): for a
  higher-is-better test the lower bounds rise from POOR to EXCELLENT, for a lower-is-better test (sprint, T-test) the
  upper bounds fall from POOR to EXCELLENT.
* Tenant norms replace the global rows of the same test and gender **whose age range they overlap** (all of such global
  rows, not just the overlapping ages). If the tenant rows cover the player's age but not the value there is no
  fallback to the global rows: the result has no band (`bandStatus: NO_NORM`).
* No band is computed, and the API says why in `bandStatus`, when the birth date or gender is unknown
  (`MISSING_PLAYER_DATA`) or no row matches (`NO_NORM`).

## Test types

| Code | Name | Unit | Better |
|---|---|---|---|
| `COOPER_12MIN` | Cooper 12-minute run | m | higher |
| `SPRINT_20M` | 20 m sprint | s | lower |
| `VERTICAL_JUMP` | Vertical jump | cm | higher |
| `AGILITY_T_TEST` | T-test | s | lower |
| `SIT_AND_REACH` | Sit and reach | cm | higher |
| `BEEP_TEST` | 20 m shuttle run (beep test) | level | higher |

## Per test: sources and status (ages 8 to 18, both genders)

### COOPER_12MIN

* **Ages 13-19 (boys and girls): sourced**, `reference_pending = false`. Cooper KH. *A means of assessing maximal oxygen intake.*
  JAMA 1968;203(3):201-204. Age/sex ratings of the 12-minute run distance (very poor, poor, fair, good, excellent in the
  paper; mapped to POOR, BELOW_AVERAGE, AVERAGE, ABOVE_AVERAGE, EXCELLENT). Transcribed from memory, secondary
  reproductions agree on these figures; verify before use. Distances in metres, lower bound of each band:

  | Group | BELOW_AVERAGE from (POOR below) | AVERAGE from | ABOVE_AVERAGE from | EXCELLENT from |
  |---|---|---|---|---|
  | boys 13-14 | 2100 | 2200 | 2400 | 2700 |
  | girls 13-14 | 1500 | 1600 | 1900 | 2000 |
  | boys 15-16 | 2200 | 2300 | 2500 | 2800 |
  | girls 15-16 | 1600 | 1700 | 2000 | 2100 |
  | boys 17-19 | 2300 | 2500 | 2700 | 3000 |
  | girls 17-19 | 1700 | 1800 | 2100 | 2300 |

  (The paper's range boundaries are inclusive at both ends, the seed uses [min, max) with the next band's lower bound as
  upper bound, which only differs for a value exactly on a boundary.)
* **Ages 8-12: placeholder.** Cooper's table does not cover children under 13.

### SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST, SIT_AND_REACH, BEEP_TEST

* **All ages, both genders: placeholder.** No table for these tests could be cited with confidence. Candidates to
  replace them (not used, not verified):
  * 20 m sprint and 20 m shuttle run: Eurofit / ALPHA-Fit health-related fitness test battery reference percentiles for
    European youth (Ortega FB et al., *Int J Obes* 2008 and the ALPHA-FIT test battery manual, 2009); Tomkinson GR et al.,
    *Br J Sports Med* 2018 (international normative 20 m shuttle run values for 9-17 year olds); Leger LA et al.,
    *J Sports Sci* 1988;6:93-101 (the beep test protocol).
  * Sit and reach: FITNESSGRAM / Cooper Institute Healthy Fitness Zone standards (a single minimum per age and sex, so
    not a five-band table).
  * T-test: Semenick D. *Tests and measurements: the T-test.* NSCA Journal 1990;12(1):36-37 (adult athletes only, not
    youth) and Pauole K et al. *J Strength Cond Res* 2000;14(4):443-450 (college students).
  * Vertical jump: published youth countermovement-jump normative studies (not identified).
* **Placeholder model** (so a generated table can be recognised and regenerated): for each test and gender the central
  value of AVERAGE is linear in age, `mid(age) = v8 + (v18 - v8) * (age - 8) / 10`, and the four band cut points are
  `mid + offset`.

  | Test | Gender | mid at 8 | mid at 18 | offsets (cut points around mid) |
  |---|---|---|---|---|
  | SPRINT_20M (s) | boys | 4.60 | 3.20 | -0.30, -0.10, +0.10, +0.30 |
  | SPRINT_20M (s) | girls | 4.80 | 3.65 | -0.30, -0.10, +0.10, +0.30 |
  | VERTICAL_JUMP (cm) | boys | 20 | 50 | -9, -4, +4, +9 |
  | VERTICAL_JUMP (cm) | girls | 19 | 35 | -8, -3, +3, +8 |
  | AGILITY_T_TEST (s) | boys | 13.0 | 9.8 | -0.8, -0.3, +0.3, +0.8 |
  | AGILITY_T_TEST (s) | girls | 13.4 | 10.8 | -0.8, -0.3, +0.3, +0.8 |
  | SIT_AND_REACH (cm) | boys | 22 | 26 | -8, -3, +3, +8 |
  | SIT_AND_REACH (cm) | girls | 25 | 30 | -8, -3, +3, +8 |
  | BEEP_TEST (level) | boys | 3.5 | 10.5 | -1.5, -0.5, +0.5, +1.5 |
  | BEEP_TEST (level) | girls | 3.0 | 7.5 | -1.5, -0.5, +0.5, +1.5 |
  | COOPER_12MIN (m), ages 8-12 only | boys | 1700 (age 8) | 2300 (age 13) | -350, -150, +150, +350 |
  | COOPER_12MIN (m), ages 8-12 only | girls | 1400 (age 8) | 1750 (age 13) | -300, -130, +130, +300 |

  For higher-is-better tests the cut points ascend POOR to EXCELLENT; for lower-is-better tests EXCELLENT is below the
  first cut point and POOR above the last. One row per single year of age (8 to 18).

## How an academy overrides norms

Global rows are read-only for every tenant (row level security: tenants can read them, only the migrator can write
them). An ADMIN replaces them for the academy by adding tenant rows:

1. `GET /api/athlete/physical-test-types` to find the test type id, `GET /api/athlete/physical-test-norms?scope=GLOBAL&testTypeId=...`
   to see the rows being replaced.
2. `POST /api/athlete/physical-test-norms` once per band with `testTypeId`, `gender`, `minAge`, `maxAge`, `band`,
   `minValue`, `maxValue` and the `source` of the table. A row with a non-blank `source` is not "reference pending".
   Enter all five bands for an age range, otherwise values outside the entered bands get no band (no fallback).
3. The tenant rows now replace the global rows of the same test and gender whose age range they overlap
   (`scope=EFFECTIVE`, the default, shows what is in force; `scope=TENANT` shows only the academy's rows).
4. `PUT` replaces and `DELETE` removes a tenant row (global ones answer 403 `NORM_IS_GLOBAL`). Deleting the tenant rows
   makes the global ones apply again. Results always show the band computed with the norms in force now, so an override
   applies retroactively.
5. The same band of the same test and gender cannot be entered twice for overlapping ages (409 `NORM_RANGE_OVERLAP`).

Tenant-specific test types (`POST /api/athlete/physical-test-types`, ADMIN) have no global norms: add tenant norms for
them the same way, otherwise their results have no band (`bandStatus: NO_NORM`).

## Replacing placeholders with sourced values (platform maintainers)

Edit the tables in the generator that produced the seed (documented above), or write the sourced rows directly into
`R__physical_test_norms.sql` with `reference_pending = false` and the citation in `source`; Flyway re-runs the repeatable
migration when its checksum changes. Ids are `uuid5` of (test, gender, ages, band), so reruns upsert rather than duplicate.
`NormSeedTest` checks every (test, gender, age 8-18) has five contiguous, correctly ordered bands and that
placeholders are exactly the rows flagged pending.
