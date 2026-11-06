# WP62 — Athlete: remaining fitness-norm placeholders

Model: Opus. Wave 3 (2026-11-06, fourth round): starts after WP61 is merged (same module); runs alongside WP54
(web) and WP66 (Redpanda infra). You own `services/athlete-service` norm data (the repeatable migration that seeds
norms, or Flyway `V5`, reserved for you), `docs/domain/norms.md`, the norm tests. Depends on: WP10b, WP27 (their
handovers: what is cited, what is a placeholder and why), decision 15 (FitBack / 20 cm = toes stay). Skills:
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp62-norms`, branch
`wp62-norms`.

Decision 44 of 2026-11-06: another research pass on the 260 uncited rows; every row is cited or marked as a
placeholder with its source gap stated.

## Scope
1. Read `docs/domain/norms.md` and the WP27 handover (`docs/wp/WP27-*.md`): Cooper 8–12 (no youth table found so
   far), T-test and vertical jump outside 14–15 (lead: Moreno-Gonzalez et al. 2026, BMC Pediatr,
   doi:10.1186/s12887-026-07796-1), edge ages repeating the nearest cited age, the girls' T-test placeholders ~1.2 s
   too fast, Cooper figures not traced to the 1968 paper, Catley PDF vs the BMJ copy.
2. Research with WebSearch/WebFetch (and PubMed tools if available): peer-reviewed or national-survey percentile
   tables for ages 6–18 by sex; record source, year, population, n, and the exact table used, per row group, in
   `norms.md`. Convert units and percentiles consistently with the existing bands (document the mapping).
3. Replace placeholders with cited values where found; where not, keep the placeholder but mark it in the data
   (`source = 'PLACEHOLDER'` or the existing convention) and in the doc, with what was searched.
4. Tests: the norm-band tests stay green (if a cited value changes a band, update the test with the citation in
   the assertion message); a test that counts placeholders so the number is visible (`PLACEHOLDER` rows ≤ the
   recorded count).

## Acceptance
- [ ] `norms.md` lists every table with its citation; before/after count of cited rows (630 total)
- [ ] `./mvnw -B -ntp -pl services/athlete-service -am verify -Dquarkus.http.test-port=0` green (totals)
- [ ] `just mutation athlete-service` at or above baseline; handover appended with the sources table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->

### Acceptance checklist
- [x] `norms.md` lists every table with its citation (per-test table, one section per source with year, population, n, protocol
      and exact table; "References" adds the sources read and not used); cited rows **370 -> 475** of 630, placeholders 260 -> 155.
- [x] Fresh `./mvnw -B -ntp -pl services/athlete-service -am verify -Dquarkus.http.test-port=0`: BUILD SUCCESS; athlete-service
      679 tests, 0 failures (common-quarkus 186 + 156), all coverage checks met; the repeatable seed applied on Testcontainers
      Postgres 17.
- [x] `just mutation athlete-service`: 471 mutations, 471 killed (100 %, baseline 100).
- [x] Handover with the sources table (below).

### Built
| Rows | Before | After (WP62) | Source (year, population, n, exact table) |
|---|---|---|---|
| COOPER_12MIN 8-12 (50) | synthetic placeholder | cited | Balague et al., Apunts 1982;19(74):109-112, **Tabla I** (printed P20-P80, groups 7-8 / 9-10 / 11-12); 1,272 Barcelona schoolchildren 7-14, n 50-376 per group (Tabla II) |
| AGILITY_T_TEST 12-13 (20) | synthetic placeholder | cited | Lesinski et al., PLoS One 2020;15(8):e0237423, **Table 3** (printed P20-P80, performance-oriented); 703 German elite young athletes, n 34-75 per cell |
| VERTICAL_JUMP 12-13, 16, boys 17 (35) | synthetic placeholder | cited | Leone et al., J Funct Morphol Kinesiol 2025;10(1):46, **Table 5** (LMS, CMJ with arm swing, photocells); 1,862 Quebec adolescents 12-17, n 92-218 per cell |
| AGILITY_T_TEST 16-18 (30) | synthetic, ~1.2 s too fast (girls) | placeholder repeating cited age 15 (Mascherini) | - |
| VERTICAL_JUMP girls 17, 18 (15) | synthetic | placeholder repeating girls 16 / boys 17 (Leone) | Leone girls-17 row is a copy of the boys-12 row |
| unchanged placeholders | | SIT_AND_REACH 8, 18 (20); SPRINT_20M 18 (10); T-test and jump 8-11 (80) | gaps and searches in norms.md |

Ids reused (in-place upsert of `R__physical_test_norms.sql`, no V5 needed); the VERTICAL_JUMP type description now says "with
arm swing". Every value came from a script over the downloaded source (Europe PMC XML for Leone and Lesinski) except Balague,
a scanned table read from a 400 dpi rendering and cross-checked against its own mean + z * SD (boys within 1 m). Tests:
`NormSeedTest` +3 (Balague edges, Lesinski/Leone edges and repeats, `placeholderRowsDoNotExceedTheRecordedCount`: <= 155
placeholders, >= 475 cited), per-test pinned counts updated; `PhysicalTestApiTest`'s placeholder example moved to a boy of 18.

### Decisions
- Rejected although readable, reasons in norms.md: Martakis 2023 (DONALD, jump 6-18: higher and narrower than both school surveys,
  10 cm band jumps), Dardouri 2023 (T-test 10-11: age means below the pooled mean), Ramos 2021 (boys basketball, ~1.5 s faster than
  every source), Bos 2014 (sprint 17/18: Z-values, flying start), Zhang 2021 (sit-and-reach zero unknown), DAFIS (back-saver test).
- A misprinted cell (Balague girls 9-10 P60) is replaced by the table's own normal model and the row's `source` says so.
- Commit trailer as the brief asks (Fable line) plus the session line.

### Open points
- Moreno-Gonzalez 2026 (BMC Pediatr, jump 6-17) still behind a Springer bot challenge, not in PMC: best lead for jump 8-11.
- Cooper teenage table still not traced to a primary source; Catley PDF vs BMJ copy still unchecked (BMJ 403, no PMC).
- Docs pass: `docs/conformance.md` (S-43, S-44, item 4) and `docs/roadmap.md` line 81 still say 370 of 630.
