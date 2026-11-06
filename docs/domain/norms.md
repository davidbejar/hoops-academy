# Physical test norms: sources, placeholders and tenant overrides

Reference norms turn a physical test result into an **expected band** (`POOR`, `BELOW_AVERAGE`, `AVERAGE`,
`ABOVE_AVERAGE`, `EXCELLENT`) for the player's gender and age on the day of the test. They live in
`athlete.physical_test_norm` and are seeded by `services/athlete-service/src/main/resources/db/migration/R__physical_test_norms.sql`.

**Honesty rule.** Only values that could be cited are presented as sourced. Everything else is a *placeholder*:
synthetic, monotone bands that keep the product usable until a cited table is entered. Placeholders have
`reference_pending = true` and a `source` that starts with "placeholder"; the API returns `referencePending: true` for
a result whose band came from such a row and the UI shows a "reference pending" flag. The database refuses a norm
without a source unless it is flagged pending (`check (reference_pending or source is not null)`).

> WP27 (2026-11-05) replaced most placeholders with published values; WP62 (2026-11-06) did another research pass on the
> 260 remaining placeholders: **475 of the 630 global rows are now cited (WP27: 370, WP10b: 120), 155 remain placeholders**
> (WP27: 260, WP10b: 510), each with its source gap stated below. Every cited table describes **one country or region** (Europe,
> Australia, Chile, Florence, Quebec, Barcelona, Germany, the 1960s USA); all are general school populations except the
> T-test at 12-13 (German elite young athletes, Lesinski 2020). Academies should still override norms with their own table
> (tenant override) before using bands for selection decisions.

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

## Percentile to band rule

The five bands are cut at the **P20 / P40 / P60 / P80** of the reference population: below P20 = `POOR`, P20 to below P40 =
`BELOW_AVERAGE`, P40 to below P60 = `AVERAGE`, P60 to below P80 = `ABOVE_AVERAGE`, P80 and above = `EXCELLENT`. For a
lower-is-better test (sprint, T-test) the direction is mirrored: the fastest 20 % (time below the time-P20) is `EXCELLENT`;
bands stay [min, max). Catley & Tomkinson 2013 propose exactly this quintile classification ("very low" to "very high").

How the four edges are obtained, per kind of source (the `source` text of every row says which one applies):

1. **Printed P20/P40/P60/P80** (FitBack 2023, Catley 2013, Balague 1982, Lesinski 2020): the printed values are the edges.
   Lesinski 2020 prints *performance* centiles for the T-test (its "P80" is the fastest time), so its P80/P60/P40/P20 columns
   are the time-P20/P40/P60/P80. Balague 1982 has one misprinted cell (girls 9-10, P60 printed 2134 m, above the printed P70
   2123 m); its table is evidently the normal model mean + z * SD (it reproduces every other cell of the girls 9-10 and all
   boys rows within 1 m), so that one edge is mean 1952 + 0.2533 * SD 328 = 2035 m, and the row's `source` says so.
2. **Published LMS parameters** (Cossio-Bolanos 2026, Leone 2025): the edges are the centiles of the published LMS distribution,
   `value = M * (1 + L*S*z)^(1/L)` with z = -0.8416, -0.2533, +0.2533, +0.8416 (the standard-normal quantiles of 0.2, 0.4,
   0.6, 0.8), rounded to 0.01 s. These parameters reproduce the paper's own printed centiles (264 printed values, all within
   rounding: 258 exact at one decimal, 6 differ by 0.1 on a rounding boundary), which is how the reading of the table was checked.
   Leone 2025 (vertical jump, rounded to 0.1 cm): the LMS reproduce all 84 printed centiles of Table 5 within 0.08 cm.
3. **Printed P10/P25/P50/P75/P90 only** (Mascherini 2022): P20, P40, P60, P80 are **linearly interpolated** between the
   neighbouring published centiles: P20 = P10 + (P25 - P10) * 10/15, P40 = P25 + (P50 - P25) * 15/25, P60 = P50 +
   (P75 - P50) * 10/25, P80 = P75 + (P90 - P75) * 5/15. This is an approximation of the empirical distribution between
   printed points, not a printed value; it is accepted as "cited" because every input is printed and the rule is fixed.
4. **A printed rating table** with five categories (Cooper): the category limits are the edges.

Criterion-referenced single pass marks (FITNESSGRAM Healthy Fitness Zone) do not give five bands and are no longer used.
Ages outside a source's range are never silently sourced: they are placeholders whose `source` says which cited age was
repeated (SIT_AND_REACH 8 and 18, SPRINT_20M 18, AGILITY_T_TEST 16-18, VERTICAL_JUMP boys 18 and girls 17-18) or that they
are synthetic (AGILITY_T_TEST and VERTICAL_JUMP 8-11).

## Per test: sources and status (ages 8 to 18, both genders)

Rows are per gender, single year of age (Cooper 13-19 in three age blocks) and band. 630 global rows in total.

| Test | Cited (`reference_pending=false`) | Source | Placeholder rows | Why the rest is placeholder |
|---|---|---|---|---|
| BEEP_TEST | ages 8-18 (110 rows) | Ortega et al. 2023 (FitBack), Table 1 | 0 | - |
| COOPER_12MIN | ages 8-19 (80) | 8-12: Balague et al. 1982, Tabla I (WP62); 13-19: Cooper table (secondary reproductions) | 0 | - |
| SIT_AND_REACH | ages 9-17 (90) | Catley & Tomkinson 2013, Table 10 | 20 (ages 8, 18) | source covers 9-17; 8 repeats 9, 18 repeats 17; no same-protocol table for 8 or 18 found |
| SPRINT_20M | ages 8-17 (100) | Cossio-Bolanos et al. 2026, Table 4 (LMS) | 10 (age 18) | source covers 6-17; 18 repeats 17; no comparable 20 m table at 18 found |
| AGILITY_T_TEST | ages 12-15 (40) | 12-13: Lesinski et al. 2020, Table 3 (WP62); 14-15: Mascherini et al. 2022, Tables 2-5 | 70 (8-11, 16-18) | no readable, internally consistent table by age and sex; 8-11 synthetic, 16-18 repeat 15 |
| VERTICAL_JUMP | ages 12-16, boys 17 (55) | 12-13, 16, boys 17: Leone et al. 2025, Table 5 (LMS, WP62); 14-15: Mascherini et al. 2022 | 55 (8-11, girls 17, 18) | Leone covers 12-17 (its girls-17 row is a copy error); 8-11 synthetic, 17-18 repeat the nearest cited age |

Totals: 475 cited rows, 155 placeholder rows (WP27: 370 / 260). `NormSeedTest.placeholderRowsAreOnlyTheDocumentedGaps` pins
the count per test and `placeholderRowsDoNotExceedTheRecordedCount` the total (at most 155 placeholders, at least 475 cited).

### COOPER_12MIN

* **Ages 13-19 (boys and girls): cited**, `reference_pending = false`. Cooper's age/sex ratings of the 12-minute run distance
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
  WP62 searched again for the primary source: the JAMA 1968 paper (PubMed record without abstract) is a field-versus-treadmill
  validation, and Wikipedia cites Cooper's book *Aerobics* (1968) only for the origin of the test, not for the table; neither the
  paper nor the books (*Aerobics*, *The New Aerobics* 1970, *The Aerobics Way* 1977) could be read, so no page or table number can
  be given. The attribution stays "conventional, not verified".
* **Ages 8-12: cited (WP62).** Balague N, Estruch A, Galilea J, Serra JR, Ventura JL. *Estudio de los resultados obtenidos en el
  test de Cooper por una muestra de la poblacion escolar y su correlacion con un test simple de autoevaluacion.* Apunts
  (Educacio Fisica i Medicina Esportiva) 1982;19(74):109-112 (paper presented at the 3rd Council of Europe seminar on fitness
  assessment, Athens, May 1982). Open PDF: https://www.apunts.org/en-download-pdf-X0213371782047749 (no DOI). **Tabla I**
  (p. 111): 12-minute run in metres, P99, P90, P80 ... P10, P1 by sex and two-year age group (7-8, 9-10, 11-12, 13-14);
  means and SDs in Fig. 3 (p. 110), n per group in Tabla II (p. 112). The table is a scanned image: the values were read from a
  400 dpi rendering and checked against the normal model mean + z * SD, which the table follows (see rule 1 for the one misprint).
* **Population:** 1,272 schoolchildren aged 7-14 from 9 schools (Centro de Investigacion Medico-Deportiva, INEF Barcelona); n per
  group boys / girls: 7-8 93 / 50, 9-10 275 / 101, 11-12 376 / 101, 13-14 208 / 68. Run on an athletics track in groups of at
  most 10, elapsed time called every 3 minutes, younger children told to pace themselves. A general school population of the
  early 1980s, so distances are probably higher than today's children run. **Mapping:** age 8 uses the 7-8 group, 9 and 10 the
  9-10 group, 11 and 12 the 11-12 group (the seed keeps single-year rows with the group's values).

  | Group | P20 / P40 / P60 / P80 (m) | mean +- SD (m) |
  |---|---|---|
  | boys 7-8 (age 8) | 1772 / 1985 / 2168 / 2381 | 2077 +- 362 |
  | girls 7-8 (age 8) | 1581 / 1745 / 1886 / 2050 | 1815 +- 304 |
  | boys 9-10 | 1910 / 2124 / 2307 / 2521 | 2216 +- 363 |
  | girls 9-10 | 1675 / 1869 / **2035** (printed 2134) / 2228 | 1952 +- 328 |
  | boys 11-12 | 2056 / 2283 / 2478 / 2705 | 2381 +- 385 |
  | girls 11-12 | 1807 / 1999 / 2164 / 2356 | 2082 +- 326 |

  At the 12/13 boundary the boys' bands join the Cooper teenage table closely (P80 2705 m vs Cooper "excellent" from 2700 m at
  13-14); the girls' Cooper table is lower (girls 13 are "excellent" from 2000 m, Balague girls 11-12 P80 is 2356 m), so a girl
  of 12 is judged more strictly than one of 13. The 13-14 group of Balague (boys P20/P40/P60/P80 2228 / 2456 / 2651 / 2879 m) is
  not used: the Cooper rows for 13+ are unchanged.

### BEEP_TEST (20 m shuttle run)

* **Ages 8-18, boys and girls: cited.** Ortega FB, Leskošek B, Blagus R, et al. *European fitness landscape for children and
  adolescents: updated reference values, fitness maps and country rankings based on nearly 8 million test results from 34
  countries gathered by the FitBack network.* Br J Sports Med 2023;57(5):299-310. doi:10.1136/bjsports-2022-106176 (open
  access, PMC9985767). **Table 1**: 20 m shuttle run in *completed stages as a decimal*, P1-P99 by sex and one-year age group
  (6.0-6.9 ... 18.0-18.9), GAMLSS-smoothed, weighted by country population. Age group N.0-N.9 = age N in full years.
* **Population:** 1,026,077 European children and adolescents (general school population, many national surveillance
  systems); all 20 m shuttle-run protocols were converted to completed stages of the original Léger protocol by the authors.
* **Why it replaced Zhang 2020** (WP10b's source for 9-17): one table now covers every age 8-18 (Zhang stops at 17, so ages 8
  and 18 were extrapolated placeholders and the bands jumped at the source boundary), it is the international reference
  named in the follow-ups (Ortega/Tomkinson group; Tomkinson 2017 itself was not read), and its metric is the same
  decimal completed-stage value. Zhang et al. 2020 (Chinese school children, J Sports Sci Med 19(3):478-488, Table 2) remains a
  valid alternative an academy can enter as a tenant override.
* **Unit mapping.** `level` = the *completed stage / minute value* of the Léger 20 m multistage test, a decimal: stage 1 is the
  first minute (8.5 km/h), each further stage adds 0.5 km/h; a partial stage counts fractionally. A coach who records only the
  "level.shuttle" notation of a beep-test sheet (e.g. 6.4) must convert to completed stages first; the integer part alone
  under-scores. PACER laps (FITNESSGRAM) are a different protocol and are not mapped here. VO2max conversions are not used.

  | Age | boys P20 / P40 / P60 / P80 (stages) | girls P20 / P40 / P60 / P80 (stages) |
  |---|---|---|
  | 8 | 1.7 / 2.5 / 3.5 / 4.8 | 1.5 / 2.1 / 2.8 / 3.7 |
  | 9 | 2.0 / 3.1 / 4.2 / 5.7 | 1.7 / 2.5 / 3.3 / 4.4 |
  | 10 | 2.4 / 3.6 / 4.8 / 6.4 | 2.0 / 2.8 / 3.7 / 4.9 |
  | 11 | 2.7 / 4.0 / 5.3 / 6.8 | 2.2 / 3.1 / 4.1 / 5.3 |
  | 12 | 3.1 / 4.4 / 5.7 / 7.3 | 2.4 / 3.4 / 4.3 / 5.6 |
  | 13 | 3.5 / 4.9 / 6.2 / 7.8 | 2.5 / 3.4 / 4.4 / 5.6 |
  | 14 | 3.9 / 5.4 / 6.8 / 8.4 | 2.5 / 3.5 / 4.4 / 5.6 |
  | 15 | 4.3 / 5.8 / 7.2 / 8.8 | 2.5 / 3.5 / 4.4 / 5.6 |
  | 16 | 4.4 / 6.0 / 7.3 / 8.9 | 2.5 / 3.5 / 4.4 / 5.6 |
  | 17 | 4.5 / 6.0 / 7.3 / 8.8 | 2.5 / 3.4 / 4.3 / 5.5 |
  | 18 | 4.4 / 5.9 / 7.2 / 8.6 | 2.4 / 3.3 / 4.2 / 5.4 |

### SIT_AND_REACH

* **Ages 9-17, boys and girls: cited.** Catley MJ, Tomkinson GR. *Normative health-related fitness values for children:
  analysis of 85347 test results on 9-17-year-old Australians since 1985.* Br J Sports Med 2013;47:98-108.
  doi:10.1136/bjsports-2011-090218 (PMID 22021354). **Table 10 (the corrected table**: the article carries a correction notice
  saying the Online First Table 10 was wrong and was replaced; the values here are from the corrected version), sit-and-reach in
  cm, P5-P95 and LMS by sex and age, LMS-smoothed. The PDF read was a third-party copy of the publisher's version
  (https://sex-matters.org/wp-content/uploads/2023/01/Catley-Normative_health-related_fitness_values_for_children-analysis_of_85347_test_results_on_917-year-old_Australians_since_1985.pdf);
  check it against the journal copy (BMJ, subscription) when convenient.
* **Population:** 9,124 sit-and-reach results of Australian school children collected 1985-2000 (general population).
* **Scale (important):** the table's note says *"a score of 20 cm corresponds to the participant reaching their toes"*. The
  seed and the test-type description therefore use a box where **20 cm = fingertips level with the toes**. A result taken on
  another box must be shifted to this zero first (e.g. FITNESSGRAM back-saver box, toes at 9 in = 22.9 cm: subtract 2.9 cm;
  a box with the zero at the toes: add 20 cm). WP10b's FITNESSGRAM-anchored placeholders used the back-saver scale and are gone.
* **Ages 8 and 18: placeholder** (age 8 repeats the age-9 centiles, age 18 the age-17 centiles; source text says so). WP62
  searched for a classic (two-leg) sit-and-reach centile table that covers 8 or 18: FitBack 2023 has no flexibility test (ALPHA
  battery); Tomkinson et al. 2018 (Eurofit, BJSM 52:1445) covers 9-17 only; Zhang et al. 2021 (Chinese national reference, Sci
  Rep 11:4991, Table 2, ages 7-18) does not state where its scale zero is and its values (boys 18 P50 39.8 cm) imply a different
  zero, so it cannot be converted to the 20 cm = toes scale; the DAFIS project (Galicia, Front Psychol 2021, PMC7932997, ages
  6-18, printed P20-P80) uses the one-leg *back-saver* sit-and-reach, a different test; Castro-Pinero et al. (Eur J Sport Sci,
  doi:10.1080/17461391.2011.606833, 6-17) and the Latvian Eurofit norms (Sauka et al. 2011) could not be read.

  | Age | boys P20 / P40 / P60 / P80 (cm) | girls P20 / P40 / P60 / P80 (cm) |
  |---|---|---|
  | 9 | 15.7 / 19.4 / 22.4 / 25.8 | 18.9 / 22.9 / 26.2 / 29.9 |
  | 10 | 15.3 / 19.0 / 22.1 / 25.5 | 18.8 / 22.7 / 26.0 / 29.7 |
  | 11 | 15.0 / 18.7 / 21.9 / 25.4 | 19.0 / 23.0 / 26.4 / 30.1 |
  | 12 | 14.8 / 18.7 / 21.9 / 25.6 | 19.9 / 24.1 / 27.5 / 31.3 |
  | 13 | 15.1 / 19.1 / 22.5 / 26.4 | 21.6 / 25.9 / 29.5 / 33.6 |
  | 14 | 15.7 / 20.0 / 23.6 / 27.8 | 23.1 / 27.6 / 31.3 / 35.4 |
  | 15 | 16.6 / 21.2 / 25.1 / 29.5 | 23.7 / 28.1 / 31.8 / 35.9 |
  | 16 | 17.6 / 22.3 / 26.5 / 31.3 | 23.5 / 27.9 / 31.4 / 35.3 |
  | 17 | 18.5 / 23.5 / 27.9 / 33.0 | 23.2 / 27.4 / 30.7 / 34.4 |

### SPRINT_20M

* **Ages 8-17, boys and girls: cited.** Cossio-Bolaños M, Vidal-Espinoza R, de Freitas MCM, Urra-Albornoz C, Alvear-Vasquez F,
  de Campos LFCC, Sulla-Torres J, Gomez-Campos R. *Applicability of anthropometric indices for assessing speed and agility in
  children and adolescents: proposed reference values by age and sex.* J Pediatr (Rio J) 2026;102(6):101596.
  doi:10.1016/j.jped.2026.101596 (open access, PMC13571986). **Table 4**: "Distribution of percentiles (LMS) for velocity and
  agility tests", 20 m sprint time in s, L, M, S and P3-P97 by sex and age 6-17. The paper's percentile columns are
  *performance* centiles (its "P97" is the fastest time), so its LMS describe the time distribution: the seed uses the time
  centiles 20/40/60/80 computed from L, M, S (rule 2 above).
* **Protocol:** standing ("high") start, hand-held stopwatch (1/100 s), best of two trials, on a hard court; the runner continues
  to a 25 m cone. Electronic timing typically gives slower times than hand timing; academies timing with gates should expect
  their players to look slightly worse against these bands.
* **Population:** 1,573 schoolchildren (873 boys, 697 girls) aged 6-17 from eight municipal urban schools of the Maule region,
  Chile, tested April-June 2023; non-probabilistic sample, 39-99 per age and sex. Small next to the other sources, but it is the
  only open 20 m sprint table by single year of age and sex found. Its 5 x 10 m agility test is a different test (not the T-test).
* **Age 18: placeholder** (repeats the age-17 centiles; source text says so). WP62 found one table with an 18-year column:
  Bos K, Schlenker L, Roth A, Seidel I. *Normwerttabellen 20m-Sprint mit Lichtschrankenmessung* (FoSS Karlsruhe, 2014, norms of
  the NRW motor test, 1,478 children 6-18 timed both by hand and with light gates, https://land.nrw/media/21404/download). It is
  not used: it (and the hand-timed NRW table it was converted from) prints Z-values (mean 100, SD 10) for a combined 17/18 group,
  not centiles, so centiles would rest on an assumed normal distribution; and its light-gate protocol (start line 1 m behind the
  first gate, no reaction time) gives times about 0.6 s faster than the standing-start, hand-timed Chilean table (boys 17/18
  Z100 = 3.12 s vs Cossio-Bolanos boys 17 M = 3.78 s), so using it at 18 would make the bands jump. Castro-Pinero et al. 2010 (Res Q Exerc Sport 81(2):143, Spanish 6-17.9) stops
  before 18 and was not readable; Zhang et al. 2021 has a 50 m sprint, not 20 m.

  | Age | boys L, M, S | boys P20 / P40 / P60 / P80 (s) | girls L, M, S | girls P20 / P40 / P60 / P80 (s) |
  |---|---|---|---|---|
  | 8 | -1.759, 5.016, 0.125 | 4.55 / 4.86 / 5.18 / 5.63 | -1.436, 5.135, 0.121 | 4.67 / 4.98 / 5.30 / 5.73 |
  | 9 | -1.816, 4.717, 0.123 | 4.29 / 4.58 / 4.87 / 5.29 | -1.464, 4.954, 0.122 | 4.50 / 4.81 / 5.11 / 5.54 |
  | 10 | -1.965, 4.439, 0.12 | 4.05 / 4.31 / 4.58 / 4.97 | -1.419, 4.806, 0.124 | 4.36 / 4.66 / 4.96 / 5.38 |
  | 11 | -2.186, 4.193, 0.115 | 3.84 / 4.08 / 4.32 / 4.67 | -1.319, 4.687, 0.126 | 4.24 / 4.54 / 4.84 / 5.25 |
  | 12 | -2.382, 3.997, 0.11 | 3.68 / 3.89 / 4.11 / 4.44 | -1.176, 4.57, 0.129 | 4.13 / 4.43 / 4.72 / 5.13 |
  | 13 | -2.474, 3.867, 0.106 | 3.57 / 3.77 / 3.98 / 4.28 | -1.003, 4.482, 0.133 | 4.03 / 4.34 / 4.64 / 5.05 |
  | 14 | -2.441, 3.793, 0.103 | 3.51 / 3.70 / 3.90 / 4.18 | -0.828, 4.461, 0.138 | 3.99 / 4.31 / 4.62 / 5.04 |
  | 15 | -2.319, 3.791, 0.102 | 3.51 / 3.70 / 3.89 / 4.17 | -0.683, 4.508, 0.143 | 4.02 / 4.35 / 4.68 / 5.11 |
  | 16 | -2.151, 3.799, 0.101 | 3.51 / 3.71 / 3.90 / 4.17 | -0.582, 4.574, 0.147 | 4.06 / 4.41 / 4.75 / 5.20 |
  | 17 | -1.956, 3.782, 0.1 | 3.50 / 3.69 / 3.88 / 4.15 | -0.523, 4.641, 0.152 | 4.10 / 4.47 / 4.83 / 5.30 |

### AGILITY_T_TEST and VERTICAL_JUMP

* **Ages 14 and 15, boys and girls: cited.** Mascherini G, Buglione N, Ciani V, Tirinnanzi F, Bini V, Levi Micheli M.
  *Florentine normative values for physical fitness in adolescents aged 14-15 years.* Healthcare 2022;10(12):2486.
  doi:10.3390/healthcare10122486 (open access, PMC9778116). **Tables 2-5**: percentiles P3-P97 per sex for the first and second
  high-school class (Table 2 boys / Table 3 girls of the first class = age 14; Table 4 boys / Table 5 girls of the second class =
  age 15; inclusion was age within six months of the class mean, mean ages 14.3 and 15.3). P20/P40/P60/P80 are interpolated
  (rule 3 above).
* **Population:** 1,915 adolescents of six high schools in Florence, Italy, tested October 2021 - March 2022 (general school
  population).
* **Protocols:** T-agility test = forward, side shuffles without crossing the feet, backpedal, time in s (the classic T-test,
  compared by the authors with Pauole et al.). Vertical jump = **chalk jump-and-reach with arm swing** (standing reach mark
  subtracted from the jump mark), in cm.

  | T-agility (s): group (table, n) | published P10 / P25 / P50 / P75 / P90 | seeded P20 / P40 / P60 / P80 |
  |---|---|---|
  | boys 14 (Table 2, n=310) | 10.2 / 10.7 / 11.4 / 12.3 / 13.2 | 10.53 / 11.12 / 11.76 / 12.60 |
  | girls 14 (Table 3, n=453) | 11.5 / 12.2 / 12.8 / 13.6 / 14.5 | 11.97 / 12.56 / 13.12 / 13.90 |
  | boys 15 (Table 4, n=318) | 9.9 / 10.3 / 11 / 11.8 / 12.9 | 10.17 / 10.72 / 11.32 / 12.17 |
  | girls 15 (Table 5, n=399) | 11.2 / 11.7 / 12.5 / 13.4 / 14.4 | 11.53 / 12.18 / 12.86 / 13.73 |

  | Vertical jump (cm): group (table, n) | published P10 / P25 / P50 / P75 / P90 | seeded P20 / P40 / P60 / P80 |
  |---|---|---|
  | boys 14 (Table 2, n=454) | 26 / 31 / 37 / 43 / 50 | 29.3 / 34.6 / 39.4 / 45.3 |
  | girls 14 (Table 3, n=536) | 20 / 24 / 30 / 35 / 39 | 22.7 / 27.6 / 32.0 / 36.3 |
  | boys 15 (Table 4, n=408) | 27 / 34 / 40 / 46 / 52 | 31.7 / 37.6 / 42.4 / 48.0 |
  | girls 15 (Table 5, n=462) | 22 / 27 / 32 / 37 / 41 | 25.3 / 30.0 / 34.0 / 38.3 |

#### AGILITY_T_TEST 12-13: Lesinski et al. 2020 (WP62)

* **Cited.** Lesinski M, Schmelcher A, Herz M, Puta C, Gabriel H, Arampatzis A, Laube G, Busch D, Granacher U. *Maturation-,
  age-, and sex-specific anthropometric and physical fitness percentiles of German elite young athletes.* PLoS One
  2020;15(8):e0237423. doi:10.1371/journal.pone.0237423 (open access, PMC7425964). **Table 3**: printed P20 / P40 / P50 / P60 / P80
  by sex and chronological age; cells with fewer than 30 athletes are empty, so only ages 12-15 exist (14-15 stay Mascherini).
* **Population:** 703 German elite young athletes (420 boys, 283 girls) aged 8-18 from elite sport schools, 18 sports (39
  basketball players), at least 10 h of training a week. **Athletes, not a general population**: their bands are stricter than
  the Florentine school bands at 14 (girls 13 AVERAGE is 11.66-12.10 s, Florentine girls 14 AVERAGE 12.56-13.12 s).
* **Protocol:** classic T-test (forward, side steps, backward, four cones), double light gates (Microgate WITTY), start without
  signal, best of two.

  | Group (n) | printed P20 / P40 / P60 / P80 (s, performance) | seeded EXCELLENT below / ABOVE_AVERAGE / AVERAGE / BELOW_AVERAGE / POOR from |
  |---|---|---|
  | boys 12 (34) | 12.28 / 11.99 / 11.66 / 10.71 | 10.71 / 10.71-11.66 / 11.66-11.99 / 11.99-12.28 / 12.28 |
  | boys 13 (75) | 11.96 / 11.21 / 10.76 / 10.30 | 10.30 / 10.30-10.76 / 10.76-11.21 / 11.21-11.96 / 11.96 |
  | girls 12 (42) | 12.79 / 12.47 / 12.04 / 11.46 | 11.46 / 11.46-12.04 / 12.04-12.47 / 12.47-12.79 / 12.79 |
  | girls 13 (52) | 12.41 / 12.10 / 11.66 / 10.76 | 10.76 / 10.76-11.66 / 11.66-12.10 / 12.10-12.41 / 12.41 |

#### VERTICAL_JUMP 12-17: Leone et al. 2025 (WP62)

* **Cited:** ages 12, 13 and 16 (boys and girls) and boys 17. Leone M, Thibault I, Bui HT, Kalinova E, Lemoyne J, Gagnon D,
  Lariviere G, Allisse M. *The protective role of physical fitness level against obesity and body dissatisfaction in
  French-Canadian youth.* J Funct Morphol Kinesiol 2025;10(1):46. doi:10.3390/jfmk10010046 (open access, PMC11843886).
  **Table 5**: "Smoothed percentile standards for the vertical jump (cm)", n, L, M, S and P3-P97 by sex and age 12-17; the edges
  are the LMS centiles (rule 2).
* **Population:** 1,862 adolescents (1,008 boys, 854 girls) aged 12-17 of 12 randomly selected French-language high schools in
  four Quebec cities, tested 2014-2017 (general school population; 1,778 vertical-jump results).
* **Protocol:** countermovement jump **with arm swing** between photoelectric cells (height from flight time), best of three,
  the same arm-swing family as the Florentine jump-and-reach. The two sources agree where they overlap (14: Leone boys
  P20/P80 27.9/45.5 cm vs Mascherini 29.3/45.3; girls 23.1/37.7 vs 22.7/36.3), so the bands are continuous from 12 to 17.
* **Not used: girls 17.** Its row (n=70) prints exactly the L, M, S and P3-P97 of the boys-12 row (1.00, 28.9, 0.353, 9.7 ...
  48.1), an apparent copy error in the published table. Girls 17 and 18 repeat girls 16, boys 18 repeats boys 17 (placeholders,
  `source` says so).

  | Group (n) | L, M, S | seeded P20 / P40 / P60 / P80 (cm) |
  |---|---|---|
  | boys 12 (124) | 1.00, 28.9, 0.353 | 20.3 / 26.3 / 31.5 / 37.5 |
  | boys 13 (218) | 0.99, 31.0, 0.274 | 23.9 / 28.8 / 33.2 / 38.2 |
  | boys 16 (156) | 1.00, 42.3, 0.253 | 33.3 / 39.6 / 45.0 / 51.3 |
  | boys 17 (92) | 1.01, 41.6, 0.305 | 30.9 / 38.4 / 44.8 / 52.3 |
  | girls 12 (151) | 1.00, 23.8, 0.419 | 15.4 / 21.3 / 26.3 / 32.2 |
  | girls 13 (199) | 1.00, 25.3, 0.349 | 17.9 / 23.1 / 27.5 / 32.7 |
  | girls 16 (129) | 0.99, 31.4, 0.302 | 23.4 / 29.0 / 33.8 / 39.4 |

#### Remaining placeholders and what was searched (WP62)

* **AGILITY_T_TEST 8-11 (synthetic) and 16-18 (repeat the Florentine age 15).** The 16-18 rows used to be synthetic and were
  about 1.2 s (girls) and 0.6 s (boys) faster than the Florentine 15-year-olds; they now repeat age 15, so a 16-year-old is no
  longer judged against a stricter band than a 15-year-old. The synthetic 8-11 rows meet the cited age 12 closely (synthetic
  AVERAGE centre at 12: boys 11.72 s, girls 12.36 s; Lesinski P50 boys 11.86 s, girls 12.32 s). Found and not used:
  * Dardouri W, Khanfir MA, Mrayeh M, Alardan S, Zouch M. *Normative data of agility T-test as a measure of change of direction
    speed in children aged 10-11.* Int J Adv Appl Sci 2023;10(5):109-114, doi:10.21833/ijaas.2023.05.013 (read via
    science-gate.com; Table 5 prints P10-P90 for Tunisian boys and girls aged 10 and 11). Not used because the table is
    internally inconsistent: both age means (girls 13.19 and 12.45 s, boys 12.51 and 11.60 s) are below the overall means of the
    same children in Tables 2-3 (girls 13.49 s, boys 12.66 s), which is impossible for a split of one sample, and the girls-11
    SD (0.30 s) is far below the pooled SD (0.79 s).
  * Ramos SA, Massuca LM, Volossovitch A, Ferreira AP, Fragoso I. *Morphological and fitness attributes of young male Portuguese
    basketball players: normative values according to chronological age and years from peak height velocity.* Front Sports Act
    Living 2021;3:629453, doi:10.3389/fspor.2021.629453 (Table 4, boys 12-16, P10-P90). Not used: boys only, regional selection
    players, n = 12-97 per age (27 at 16), cone distances not stated, and times about 1.5 s faster than every other source at
    the same age.
  * Not the T-test, so not used: the modified agility T-test (MATT; Tunisian basketball players, Children 2024, PMC11593227, means
    only), 4 x 10 m and 10 x 5 m shuttle runs (DAFIS, Eurofit), the star run (Golle 2015), Illinois test.
  * Searches with no further table: PubMed "agility T-test normative percentiles children adolescents" (0 hits), web searches for
    T-test norms by age and sex for school children, for adolescent (basketball) players 16-18, Spanish "test T valores de
    referencia", population-based LMS T-test curves.
* **VERTICAL_JUMP 8-11 (synthetic), girls 17-18 and boys 18 (repeat the nearest cited age).** The synthetic 8-11 rows meet Leone
  at 12 (synthetic AVERAGE centre at 12: boys 32 cm, girls 25.4 cm; Leone M boys 28.9, girls 23.8 cm). Found and not used:
  * Martakis K, Alexy U, Stark C, Hahn A, Rawer R, Duran I, Schonau E. *Jumping mechanography: reference centiles in childhood and
    introduction of the Nerve-Muscle Index to quantify motor efficiency.* J Clin Med 2023;12(18):5984, doi:10.3390/jcm12185984
    (PMC10531761; supplement Tables S3/S4: LMS of jump height for the single two-leg jump with free arms on a force plate, German
    DONALD cohort, 882 children, ages 6-18). Readable, LMS checked (reproduce the printed centiles within 0.03 cm), but not used:
    its distribution is much higher and narrower than the two school surveys (girls 13 P20 30.9 cm vs Leone 17.9 cm, Mascherini
    girls 14 22.7 cm; boys 11 P20 30.1 cm vs Leone boys 12 20.3 cm), so filling 8-11 and 18 from it would make the bands jump by
    10 cm at the source boundaries. An academy that measures on a force plate can enter it as a tenant override.
  * Moreno-Gonzalez L, Manzano-Carrasco S, Felipe JL, Gallardo L, Garcia-Unanue J, Alonso-Callejo A. *Normative reference values
    for the vertical jump test in sport-participating children and adolescents in Spain.* BMC Pediatr 2026 (published
    2026-10-08), doi:10.1186/s12887-026-07796-1: still unreadable on 2026-11-06 (Springer answers every route, HTML and PDF, with a
    "Client Challenge" page; Crossref lists only that link; not in PMC or Europe PMC). **Still the best lead for 8-11 (6-17,
    athletes, CMJ).**
  * Lesinski et al. 2020, Table 3 (CMJ 12-15, elite athletes, optoelectronic, n 42-86): only ages already cited; Gabel et al.
    2016 (J Musculoskelet Neuronal Interact 16(4):283, PMC5259569, Canadian 9-21, hands-on-waist mechanography, Table 7): a
    no-arm-swing protocol with lower heights; Correia et al. 2024 (Front Pediatr 12:1207609) and Baptista et al. 2025 (J Strength
    Cond Res 39(8):e974) give jump power, not height; Dardouri 2023 gives CMJ means only. Ramirez-Velez et al. 2017 (FUPRECOL,
    Colombian 9-17.9, J Strength Cond Res 31(4):990, doi:10.1519/JSC.0000000000001550; repository.urosario.edu.co refused the
    connection), Taylor et al. 2010 (English 10-15, J Sports Sci 28(8):867) and the Canadian Health Measures Survey mechanography
    reference (Li et al., Osteoporos Int 2025;36(12):2541) are subscription-only and were not read.
* **Placeholder model** (for the remaining synthetic rows, so they can be recognised): the central value of AVERAGE is linear in
  age, `mid(age) = v8 + (v18 - v8) * (age - 8) / 10`, and the four band cut points are `mid + offset`. Only ages 8-11 still use it.

  | Test | Gender | mid at 8 | mid at 18 | offsets (cut points around mid) |
  |---|---|---|---|---|
  | VERTICAL_JUMP (cm) | boys | 20 | 50 | -9, -4, +4, +9 |
  | VERTICAL_JUMP (cm) | girls | 19 | 35 | -8, -3, +3, +8 |
  | AGILITY_T_TEST (s) | boys | 13.0 | 9.8 | -0.8, -0.3, +0.3, +0.8 |
  | AGILITY_T_TEST (s) | girls | 13.4 | 10.8 | -0.8, -0.3, +0.3, +0.8 |

  For higher-is-better tests the cut points ascend POOR to EXCELLENT; for lower-is-better tests EXCELLENT is below the first
  cut point and POOR above the last. (The COOPER_12MIN 8-12 synthetic model of WP10b is gone: those rows are cited.)

## How to verify the sources

Every cited table is open access except Catley 2013 (third-party PDF copy, URL above; the BMJ copy answered 403 and there is
no PMC copy, checked 2026-11-06, so the comparison is still open) and the Cooper teenage table.

1. FitBack (BEEP_TEST): https://pmc.ncbi.nlm.nih.gov/articles/PMC9985767/ Table 1; e.g. boys 18.0-18.9: P20 4.4, P40 5.9,
   P60 7.2, P80 8.6 = the lower bounds of BELOW_AVERAGE ... EXCELLENT for BEEP_TEST, MALE, age 18.
2. Catley 2013 (SIT_AND_REACH): Table 10 of the corrected article; e.g. girls 14: P20 23.1, P40 27.6, P60 31.3, P80 35.4.
3. Cossio-Bolaños 2026 (SPRINT_20M): https://pmc.ncbi.nlm.nih.gov/articles/PMC13571986/ Table 4; e.g. boys 12: L -2.382,
   M 3.997, S 0.110 gives P20 = 3.997 * (1 + (-2.382)(0.110)(-0.8416))^(1/-2.382) = 3.68 s (EXCELLENT below 3.68 s) and
   P80 = 4.44 s (POOR from 4.44 s); the paper's printed "P75" (performance) for boys 12 is 3.7 s = the time-P25, consistent.
4. Mascherini 2022 (AGILITY_T_TEST, VERTICAL_JUMP): https://pmc.ncbi.nlm.nih.gov/articles/PMC9778116/ Tables 2-5 and rule 3.
5. Cooper table: the two reproductions above; try to obtain the paper (https://pubmed.ncbi.nlm.nih.gov/5694044/) and Cooper's
   later books for the age/sex table before treating it as primary.
6. Balague 1982 (COOPER_12MIN 8-12): https://www.apunts.org/en-download-pdf-X0213371782047749, Tabla I p. 111; e.g. boys 11-12
   P80 2705 m = lower bound of EXCELLENT for COOPER_12MIN, MALE, ages 11 and 12; Fig. 3 p. 110 for the means and SDs.
7. Lesinski 2020 (AGILITY_T_TEST 12-13): https://pmc.ncbi.nlm.nih.gov/articles/PMC7425964/ Table 3, "T-test [s]"; e.g. boys 13
   P80 10.30 s = upper bound of EXCELLENT.
8. Leone 2025 (VERTICAL_JUMP 12-17): https://pmc.ncbi.nlm.nih.gov/articles/PMC11843886/ Table 5; e.g. boys 16: L 1.00, M 42.3,
   S 0.253 gives P20 = 42.3 * (1 + 0.253 * (-0.8416)) = 33.3 cm (BELOW_AVERAGE from 33.3 cm).

In SQL: `select min_age, band, min_value, max_value, reference_pending from athlete.physical_test_norm n join athlete.physical_test_type t on t.id = n.test_type_id where t.code = 'BEEP_TEST' and n.owner_tenant_id is null and gender = 'MALE' order by min_age, min_value nulls first;`

## Open leads for the remaining placeholders

* VERTICAL_JUMP 8-11: Moreno-Gonzalez et al. BMC Pediatr 2026 (above) as soon as its tables can be read (try again when it
  reaches PMC); FUPRECOL (Ramirez-Velez 2017) and Taylor 2010 with library access.
* AGILITY_T_TEST 8-11 and 16-18: no table found. A corrected Dardouri 2023 table (10-11) would fill two ages.
* SIT_AND_REACH 8 and 18: Castro-Pinero et al. (Spanish 6-17, covers 8) with library access.
* SPRINT_20M 18: no standing-start 20 m centile table at 18 found.
* COOPER_12MIN: the primary source of the teenage table (Cooper's books) for the attribution; "The general endurance of children
  aged 8-12 years in the 12 min run test" (J Sports Med Phys Fitness 1989, PMID 2628636, not accessible) as a modern alternative
  to the 1982 Barcelona table; PeerJ 2023;11:e15271 publishes raw 12-minute-run data of 9,477 North-Italian 11-14-year-olds but no
  centile table.
* BEEP_TEST: Tomkinson et al. 2017 (BJSM 51:1545-1554) was not read (WP10b: publisher 403); FitBack covers ages 8-18.

## References

* Ortega FB, Leskošek B, Blagus R, Gil-Cosano JJ, Mäestu J, Tomkinson GR, Ruiz JR, Mäestu E, et al. European fitness landscape for children and adolescents: updated reference values, fitness maps and country rankings based on nearly 8 million test results from 34 countries gathered by the FitBack network. Br J Sports Med 2023;57(5):299-310. doi:10.1136/bjsports-2022-106176 (used: BEEP_TEST)
* Catley MJ, Tomkinson GR. Normative health-related fitness values for children: analysis of 85347 test results on 9-17-year-old Australians since 1985. Br J Sports Med 2013;47:98-108. doi:10.1136/bjsports-2011-090218 (used: SIT_AND_REACH)
* Cossio-Bolaños M, Vidal-Espinoza R, de Freitas MCM, Urra-Albornoz C, Alvear-Vasquez F, de Campos LFCC, Sulla-Torres J, Gomez-Campos R. Applicability of anthropometric indices for assessing speed and agility in children and adolescents: proposed reference values by age and sex. J Pediatr (Rio J) 2026;102(6):101596. doi:10.1016/j.jped.2026.101596 (used: SPRINT_20M)
* Mascherini G, Buglione N, Ciani V, Tirinnanzi F, Bini V, Levi Micheli M. Florentine normative values for physical fitness in adolescents aged 14-15 years. Healthcare (Basel) 2022;10(12):2486. doi:10.3390/healthcare10122486 (used: AGILITY_T_TEST, VERTICAL_JUMP)
* Balague N, Estruch A, Galilea J, Serra JR, Ventura JL. Estudio de los resultados obtenidos en el test de Cooper por una muestra de la poblacion escolar y su correlacion con un test simple de autoevaluacion. Apunts Educ Fis Med Esport 1982;19(74):109-112. https://www.apunts.org/en-download-pdf-X0213371782047749 (used: COOPER_12MIN 8-12)
* Lesinski M, Schmelcher A, Herz M, Puta C, Gabriel H, Arampatzis A, Laube G, Busch D, Granacher U. Maturation-, age-, and sex-specific anthropometric and physical fitness percentiles of German elite young athletes. PLoS One 2020;15(8):e0237423. doi:10.1371/journal.pone.0237423 (used: AGILITY_T_TEST 12-13)
* Leone M, Thibault I, Bui HT, Kalinova E, Lemoyne J, Gagnon D, Lariviere G, Allisse M. The protective role of physical fitness level against obesity and body dissatisfaction in French-Canadian youth. J Funct Morphol Kinesiol 2025;10(1):46. doi:10.3390/jfmk10010046 (used: VERTICAL_JUMP 12-13, 16, boys 17)
* Cooper KH. A means of assessing maximal oxygen intake: correlation between field and treadmill testing. JAMA 1968;203(3):201-204. https://pubmed.ncbi.nlm.nih.gov/5694044/ (used: COOPER_12MIN 13-19, as reproduced in secondary sources)
* Zhang F, Yin X, Bi C, et al. Normative reference values and international comparisons for the 20-metre shuttle run test: analysis of 69,960 test results among Chinese children and youth. J Sports Sci Med 2020;19(3):478-488 (WP10b source for BEEP_TEST 9-17, replaced by FitBack; usable as a tenant override)
* Tomkinson GR, Lang JJ, Tremblay MS, et al. International normative 20 m shuttle run values from 1 142 026 children and youth representing 50 countries. Br J Sports Med 2017;51(21):1545-1554. doi:10.1136/bjsports-2016-095987 (not accessed)
* Léger LA, Mercier D, Gadoury C, Lambert J. The multistage 20 metre shuttle run test for aerobic fitness. J Sports Sci 1988;6(2):93-101 (protocol)
* Moreno-Gonzalez L, Manzano-Carrasco S, Felipe JL, Gallardo L, Garcia-Unanue J, Alonso-Callejo A. Normative reference values for the vertical jump test in sport-participating children and adolescents in Spain. BMC Pediatr 2026. doi:10.1186/s12887-026-07796-1 (not readable yet, lead)
* Ramirez-Velez R, et al. Vertical jump and leg power normative data for Colombian schoolchildren aged 9-17.9 years: the FUPRECOL study. J Strength Cond Res 2017;31(4). doi:10.1519/JSC.0000000000001550 (abstract only, not used)
* Taylor MJD, Cohen D, Voss C, Sandercock GRH. Vertical jumping and leg power normative data for English school children aged 10-15 years. J Sports Sci 2010;28(8):867-872. doi:10.1080/02640411003770212 (not read, not used)
* Martakis K, Alexy U, Stark C, Hahn A, Rawer R, Duran I, Schonau E. Jumping mechanography: reference centiles in childhood and introduction of the Nerve-Muscle Index to quantify motor efficiency. J Clin Med 2023;12(18):5984. doi:10.3390/jcm12185984 (read, not used: inconsistent with the school surveys, see VERTICAL_JUMP)
* Dardouri W, Khanfir MA, Mrayeh M, Alardan S, Zouch M. Normative data of agility T-test as a measure of change of direction speed in children aged 10-11. Int J Adv Appl Sci 2023;10(5):109-114. doi:10.21833/ijaas.2023.05.013 (read, not used: internally inconsistent)
* Ramos SA, Massuca LM, Volossovitch A, Ferreira AP, Fragoso I. Morphological and fitness attributes of young male Portuguese basketball players: normative values according to chronological age and years from peak height velocity. Front Sports Act Living 2021;3:629453. doi:10.3389/fspor.2021.629453 (read, not used)
* Bos K, Schlenker L, Roth A, Seidel I. Normwerttabellen 20m-Sprint mit Lichtschrankenmessung. FoSS Karlsruhe, 2014. https://land.nrw/media/21404/download (read, not used: Z-values, flying start)
* Zhang F, et al. Physical fitness reference standards for Chinese children and adolescents. Sci Rep 2021;11:4991. doi:10.1038/s41598-021-84634-7 (read, not used: sit-and-reach scale zero not stated)

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

There is no generator in the repository: write the sourced rows directly into `R__physical_test_norms.sql` with
`reference_pending = false` and the citation in `source` (at most 500 characters; it must not contain the word
"placeholder"), keeping each row's `id` (ids are `uuid5` of (test, gender, ages, band) and were reused unchanged by WP10b,
WP27 and WP62, so the upsert replaces values in place). Flyway re-runs the repeatable migration when its checksum changes.
`NormSeedTest` checks that every (test, gender, age 8-18) has five contiguous, correctly ordered bands, that placeholders
are exactly the rows flagged pending, which ages each source covers, sample band edges per source, and the number of
placeholder rows per test (update that count and this document together).
