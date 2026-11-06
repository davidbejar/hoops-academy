# WP88 — Mutation round: wider PIT scope, baselines raised, Dart mutation tool for the web rule code

Model: Opus. Wave 4 (2026-11-06, fifth round): starts after wave 3 is merged; the only agent on the backend (refactors
touch the three services and `libs/common-quarkus`); WP77 runs on `apps/web/lib/features/landing` at the same time:
in `apps/web` you own ONLY `apps/web/tool/mutation/**` (new), `apps/web/test/mutation/**` (new) and the test files
you add for killed mutants under `apps/web/test/core/**` and `test/features/{match,training,roster,health}/**`
(tests only, no `lib/` edits unless a mutant reveals a real bug: then the fix, one commit, named in the handover).
You own the root `pom.xml` PIT section, every `services/*` and `libs/common-quarkus` main and test code,
`docs/quality/mutation.md`, `justfile` mutation recipes, `.github/workflows/mutation.yml`. Depends on: WP37
(PIT), `docs/quality/mutation.md` (scopes and baselines), WP67–WP69/WP82 (new rule code). Skills:
test-driven-development, clean-code, quarkus-hexagonal-service, verification-before-completion. Worktree:
`~/code/hoops-wt/wp88-mutation-round`, branch `wp88-mutation-round`.

Decision 56 of 2026-11-06: extract pure rules so PIT covers use cases and container-only code; baselines raised to
the current scores (core 99.6, game 99.5, athlete 100); a Dart mutation tool (no Node) for the web rule code with
its own baseline; survivors killed.

## Scope
1. **Scope widening** (per service): list the rule-bearing classes outside PIT's scope today (use cases, `TenantScope`,
   `ProblemExceptionMappers`, the athlete replica apply rules, the WP78 search/copy rules, WP80 season rules, WP81
   backfill ordering, WP82 retention); extract pure decision logic into framework-free classes where it is not yet
   (hexagonal: domain or application without CDI), add them to `pit.targetClasses` with unit tests; ArchUnit stays
   green. Record each extraction (class, from, to) in `mutation.md`.
2. **Baselines**: `mutation.md` table and `justfile` thresholds raised to the current scores; equivalent mutants
   listed with justification; survivors killed with tests (red first for real gaps).
3. **Dart mutation tool** (`apps/web/tool/mutation/`): a Dart script (no Node) that applies a small operator set
   (negate condition, swap comparison, remove statement, boundary ±1, boolean literal flip) to the web rule files
   listed in a manifest (offline sync/outbox merge, match clock and score rules, eligibility views, usage counters,
   locale negotiation, cache scoping), runs the matching `flutter test` subsets per mutant with a time cap, reports
   killed/survived/timeouts, and enforces a baseline; `just web-mutation` recipe; documented in `mutation.md`; the
   first run's score becomes the baseline after survivors are killed or justified. Runtime target under 30 min.
4. **CI**: `mutation.yml` (manual + monthly) gains the Dart job.

## Acceptance
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals; ArchUnit green after the
      extractions)
- [ ] `just mutation` for the three services at or above the new baselines (scores and mutant counts recorded)
- [ ] `just web-mutation` runs end to end with its baseline recorded; `flutter analyze` and `just web-format-check`
      clean; `just web-test` green (fresh; totals)
- [ ] `docs/quality/mutation.md` updated; handover appended (extractions, equivalents, runtime)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
