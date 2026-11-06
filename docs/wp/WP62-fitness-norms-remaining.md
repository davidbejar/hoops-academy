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
