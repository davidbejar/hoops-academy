# Physical test norms: sources, placeholders and tenant overrides

Reference norms turn a physical test result into an **expected band** (`POOR`, `BELOW_AVERAGE`, `AVERAGE`,
`ABOVE_AVERAGE`, `EXCELLENT`) for the player's gender and age on the day of the test. They live in
`athlete.physical_test_norm` and are seeded by `services/athlete-service/src/main/resources/db/migration/R__physical_test_norms.sql`.

**Honesty rule.** Only values that could be cited are presented as sourced. Everything else is a *placeholder*:
synthetic, monotone bands that keep the product usable until a cited table is entered. Placeholders have
`reference_pending = true` and a `source` that starts with "placeholder"; the API returns `referencePending: true` for
a result whose band came from such a row and the UI shows a "reference pending" flag. The database refuses a norm
without a source unless it is flagged pending (`check (reference_pending or source is not null)`).

> WP10b (2026-11-02) replaced part of the placeholders with published values (see "Per test" below). Only **BEEP_TEST
> ages 9-17** (a Chinese school sample, not an international or athlete one) and **COOPER_12MIN ages 13-19** (a table that
> circulates in secondary sources and could not be traced to the 1968 paper itself) are flagged as sourced. Everything else is
> still placeholder. Academies should override norms with their own table (tenant override) before using bands for decisions.

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

## Percentile to band rule (WP10b)

For every source that publishes centiles the five bands are cut at **P20 / P40 / P60 / P80**: below P20 = `POOR`,
P20 to below P40 = `BELOW_AVERAGE`, P40 to below P60 = `AVERAGE`, P60 to below P80 = `ABOVE_AVERAGE`, P80 and above =
`EXCELLENT` (for a lower-is-better test the direction is mirrored; bands stay [min, max)). Criterion-referenced sources with a
single pass mark (FITNESSGRAM Healthy Fitness Zone) do **not** give five bands: they are used only to anchor one band edge of a
placeholder, and such rows stay `reference_pending = true`. `reference_pending = false` is used only where the published
cut-offs (centiles or the printed rating table) are the band edges. Ages are interpolated only inside a source's range; outside
it (age 8 and 18 for BEEP_TEST) the rows are placeholders that say how they were extended.

## Per test: sources and status (ages 8 to 18, both genders)

Summary (rows are per gender and single year or age block):

| Test | Sourced (`reference_pending=false`) | Still placeholder | Anchor used for placeholders |
|---|---|---|---|
| COOPER_12MIN | boys and girls 13-14, 15-16, 17-19 (Cooper table, secondary reproductions) | ages 8-12 | none found |
| BEEP_TEST | boys and girls 9-17 (Zhang 2020, Chinese general school population) | ages 8 and 18 (extrapolated from Zhang) | Zhang 2020 |
| SIT_AND_REACH | none | ages 8-18 | AVERAGE lower edge = FITNESSGRAM HFZ minimum |
| SPRINT_20M | none | ages 8-18 | none found |
| VERTICAL_JUMP | none | ages 8-18 | none verified |
| AGILITY_T_TEST | none | ages 8-18 | none found |

### COOPER_12MIN

* **Ages 13-19 (boys and girls): sourced**, `reference_pending = false`. Cooper's age/sex ratings of the 12-minute run distance
  (poor, below average, average, above average, excellent; they map one to one onto the five bands). The same figures appear in
  two web reproductions (checked 2026-11-02): https://sportscienceinsider.com/cooper-test/ and
  https://en.wikipedia.org/wiki/Cooper_test. **Neither traces the table to a page of Cooper's 1968 paper and the paper
  (https://pubmed.ncbi.nlm.nih.gov/5694044/) was not obtained**, so the attribution to "Cooper 1968" is the conventional one, not
  verified. It is a general (US, 1960s) population table, not an athlete one. Distances in metres, lower bound of each band:

  | Group | BELOW_AVERAGE from (POOR below) | AVERAGE from | ABOVE_AVERAGE from | EXCELLENT from |
  |---|---|---|---|---|
  | boys 13-14 | 2100 | 2200 | 2400 | 2700 |
  | girls 13-14 | 1500 | 1600 | 1900 | 2000 |
  | boys 15-16 | 2200 | 2300 | 2500 | 2800 |
  | girls 15-16 | 1600 | 1700 | 2000 | 2100 |
  | boys 17-19 | 2300 | 2500 | 2700 | 3000 |
  | girls 17-19 | 1700 | 1800 | 2100 | 2300 |

  (The tables' boundaries are inclusive at both ends, the seed uses [min, max) with the next band's lower bound as upper bound,
  which only differs for a value exactly on a boundary.)
* **Ages 8-12: placeholder.** No youth Cooper table under 13 could be found (searches returned only the 13+ table, adult norms
  and non-normative studies). Placeholder model below.

### BEEP_TEST (20 m shuttle run)

* **Ages 9-17, boys and girls: sourced**, `reference_pending = false`. Zhang F, Yin X, Bi C, et al. *Normative reference values and
  international comparisons for the 20-metre shuttle run test: analysis of 69,960 test results among Chinese children and youth.*
  J Sports Sci Med 2020;19(3):478-488, **Table 2 (completed stages / minutes)**, centiles P5-P95 by sex and age at last birthday,
  LMS-smoothed. The seed uses P20, P40, P60, P80 (rule above). **Population: Chinese school children (general population,
  not athletes)**; Zhang et al. report that Chinese values differ from the international ones of Tomkinson et al. 2017 (Chinese
  boys are faster at 9-12, Chinese girls slower from 11; their Table 5). The Tomkinson 2017 tables (BJSM 51:1545-1554,
  1,142,026 youth, 50 countries, ages 9-17, laps/stages/VO2) are the preferred reference but the full text and tables were
  **not accessible** from this environment (publisher 403, not in PMC); replacing these rows with Tomkinson's P20/40/60/80 is the
  open improvement.
* **Unit mapping.** `level` = the *completed stage / minute value* of the Leger 20 m multistage test, a decimal: stage 1 is the
  first minute (7 laps at 8.5 km/h), each further stage adds 0.5 km/h; a partial stage counts fractionally (e.g. 4.25 =
  a quarter of the way through stage 5). This is the metric of Zhang's Table 2 and Tomkinson's "stages/minutes". A coach who
  records only the "level.shuttle" notation of the beep-test sheet (e.g. 6.4) must convert to completed minutes first; the
  integer part alone under-scores. Laps (Zhang Table 1, e.g. boys age 13: P20 = 26, P50 = 39, P80 = 56 laps) are not stored.
  The PACER (FITNESSGRAM) is the same 20 m run with a different speed protocol (starts 8.5 km/h, +0.5 km/h per minute; lap
  counts per minute differ from the 20 m multistage), so PACER laps are not mapped to levels here.
* **Ages 8 and 18: placeholder** (outside Zhang's 9-17): age 8 = the 9-year centile minus the 9-to-10 step, age 18 = the
  17-year centiles. Flagged pending, source text says "placeholder".
* VO2max conversions are **not** used.

  | Group (P20 / P40 / P60 / P80, stages) | 9 | 12 | 15 | 17 |
  |---|---|---|---|---|
  | boys | 2.26 / 2.88 / 3.48 / 4.25 | 3.16 / 4.02 / 4.85 / 5.90 | 4.04 / 5.11 / 6.13 / 7.43 | 4.36 / 5.48 / 6.56 / 7.93 |
  | girls | 2.21 / 2.76 / 3.29 / 4.00 | 2.81 / 3.49 / 4.16 / 5.03 | 3.16 / 3.89 / 4.61 / 5.54 | 3.25 / 3.99 / 4.71 / 5.65 |

### SIT_AND_REACH

* **All ages: placeholder, but anchored.** FITNESSGRAM Healthy Fitness Zone (HFZ), The Cooper Institute, as printed in the
  California Physical Fitness Test HFZ tables 2014 (back-saver sit-and-reach, minimum to be in the zone): boys 8 in (20.3 cm) at
  all ages; girls 9 in (22.9 cm) at 9-10, 10 in (25.4 cm) at 11-14, 12 in (30.5 cm) at 15-17+. The table starts at age 9, age 8
  uses the 9-year value. An HFZ is a single criterion-referenced minimum, not a percentile table, so only the **AVERAGE lower
  edge** is set to the HFZ minimum; the other edges stay synthetic (-5, +6, +11 cm around it). The scale is the FITNESSGRAM
  back-saver box scale (toes at about 23 cm); a test performed with another zero point needs a tenant override.
  URL: https://rhs.rocklinusd.org/subsites/PE/documents/Fitness%20Testing%20Tables/2014%20All%20Tests%20HFZ%20Tables.pdf
  (2014 edition via a school district; the current Cooper Institute manual should be checked for newer values).

### SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST

* **All ages, both genders: still placeholder.** What the search found and why it was not used:
  * 20 m sprint: no open youth percentile table by sex and age 8-18 found (searches returned only shuttle-run norms). A Turkish
    study of 7,223 children aged 7-14 (Erciyes University, "Normative values for education and measures of physical fitness
    among children and adolescents aged 7-14") reports a 20 m sprint but the table was not read; no athlete sample used.
  * Vertical jump: the FUPRECOL study (Ramirez-Velez R et al. J Strength Cond Res 2017;31(7), doi 10.1519/JSC.0000000000001550;
    Colombian schoolchildren 9-17.9 years, LMS percentiles P3/10/25/50/75/90/97, boys' 50th percentile about 24 to 38 cm, girls about
    22 to 27 cm according to the abstract) is the only vertical-jump source found; its tables were behind a repository that
    could not be reached, and its percentiles (no P20/P80) would need a different rule. The placeholder (boys 20 to 50 cm, girls
    19 to 35 cm) is higher than those medians at older ages: treat as too generous. Not changed, because the abstract figures are
    second-hand.
  * T-test: no youth normative study with age/sex tables found. A 2022 Italian study (Healthcare 10(12):2486, ages 14-15,
    Florence) reports T-test percentiles but covers two ages only and its table was not accessible. The 4x10 m shuttle (HELENA,
    Ortega et al., BJSM 2011;45:20-29, ages 12.5-17.5) is a different test and was not used.
  * Standing long jump sources were ignored on purpose (not vertical jump).
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
  | COOPER_12MIN (m), ages 8-12 only | boys | 1700 (age 8) | 2300 (age 13) | -350, -150, +150, +350 |
  | COOPER_12MIN (m), ages 8-12 only | girls | 1400 (age 8) | 1750 (age 13) | -300, -130, +130, +300 |

  (SIT_AND_REACH and BEEP_TEST placeholders are no longer produced by this model; see their sections.)
  For higher-is-better tests the cut points ascend POOR to EXCELLENT; for lower-is-better tests EXCELLENT is below the
  first cut point and POOR above the last. One row per single year of age (8 to 18).

## How to verify the sources

1. Zhang 2020 (BEEP_TEST): open https://www.jssm.org/jssm-19-478.xml-abst (PDF https://jssm.org/19-3-478.p_d_f), Table 2, find
   sex and age, compare columns P20/P40/P60/P80 with the rows of `R__physical_test_norms.sql` for BEEP_TEST (e.g. boys 13:
   3.50 / 4.44 / 5.34 / 6.50). In SQL: `select min_age, band, min_value, max_value from athlete.physical_test_norm n join athlete.physical_test_type t on t.id = n.test_type_id where t.code = 'BEEP_TEST' and n.owner_tenant_id is null and gender = 'MALE' order by min_age, min_value nulls first;`
2. FITNESSGRAM HFZ (SIT_AND_REACH anchor): the PDF URL above, columns "Sit & Reach (inches)" of the male/female tables; multiply by 2.54.
3. Cooper table: the two reproductions above; try to obtain the paper (https://pubmed.ncbi.nlm.nih.gov/5694044/) and Cooper's
   later books for the age/sex table before treating it as primary.
4. Tomkinson 2017 (planned replacement for BEEP_TEST): https://bjsm.bmj.com/content/51/21/1545 (doi 10.1136/bjsports-2016-095987).

## References

* Cooper KH. A means of assessing maximal oxygen intake: correlation between field and treadmill testing. JAMA 1968;203(3):201-204. https://pubmed.ncbi.nlm.nih.gov/5694044/
* Zhang F, Yin X, Bi C, Li Y, Sun Y, Zhang T, Yang X, Li M, Liu Y, Cao J, Yang T, Guo Y, Song G. Normative reference values and international comparisons for the 20-metre shuttle run test: analysis of 69,960 test results among Chinese children and youth. J Sports Sci Med 2020;19(3):478-488. https://www.jssm.org/jssm-19-478.xml-abst
* Tomkinson GR, Lang JJ, Tremblay MS, Dale M, LeBlanc AG, Belanger K, Ortega FB, Leger L. International normative 20 m shuttle run values from 1 142 026 children and youth representing 50 countries. Br J Sports Med 2017;51(21):1545-1554. doi:10.1136/bjsports-2016-095987 (not accessed, listed as the preferred replacement)
* Leger LA, Mercier D, Gadoury C, Lambert J. The multistage 20 metre shuttle run test for aerobic fitness. J Sports Sci 1988;6(2):93-101.
* The Cooper Institute. FITNESSGRAM/ACTIVITYGRAM Test Administration Manual; Healthy Fitness Zone standards (as printed in the California Physical Fitness Test Healthy Fitness Zones 2014).
* Ramirez-Velez R, et al. Vertical jump and leg power normative data for Colombian schoolchildren aged 9-17.9 years: the FUPRECOL study. J Strength Cond Res 2017. doi:10.1519/JSC.0000000000001550 (abstract only, not used)
* Ortega FB, et al. Physical fitness levels among European adolescents: the HELENA study. Br J Sports Med 2011;45:20-29 (not accessed, not used)

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
