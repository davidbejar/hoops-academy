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
