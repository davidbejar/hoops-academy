# WP43 — json-schema-validator 3.x (Dependabot #3)

Model: Opus. Wave 1 (2026-11-06, third round): runs alongside WP46 (deploy/), WP48 (apps/web health) and WP50
(.github/workflows); you own `libs/contracts/pom.xml`, `libs/contracts/src/test`, `services/game-service` and the root
`pom.xml` dependency management. Depends on: WP29 (ADR-0027, strict validator). Skills: quarkus-hexagonal-service,
systematic-debugging, test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp43-schema-validator`, branch `wp43-schema-validator`.

Decision 24 of 2026-11-06: Dependabot PR #3 (`com.networknt:json-schema-validator` 2.0.8 → 3.0.8) is red because the
3.x API differs; migrate instead of ignoring the major. After this merges, Dependabot closes #3 by itself (the version
is then current); do not touch the PR.

## Scope
1. Read PR #3's failing jobs (`gh pr checks 3`, `gh run view --log-failed`) and the three usages:
   `libs/contracts/src/test/java/com/hoopsacademy/contracts/MatchEventJsonSchemaTest.java`,
   `services/game-service/src/test/java/com/hoopsacademy/game/support/EventSchema.java` and the production class
   `services/game-service/src/main/java/com/hoopsacademy/game/adapters/in/rest/MatchEventDecoder.java` (validates
   incoming match events against the JSON Schema; its errors become Problem+JSON).
2. Bump the version where it is declared (root or module pom; one place) and migrate the three classes to the 3.x
   API (factory, spec version detection, `ValidationMessage` accessors, `OutputUnit` if the old message list is
   gone). Behaviour must not change: the existing decoder tests and the game contract tests fix the Problem
   `detail`/`errors` shape; if a message text changes, prefer keeping the old wording in the mapping to changing the
   tests, and say so in the handover. Test first where a behaviour could drift (an invalid event's problem body).
3. `MatchEventSchemaConsistencyTest` (schema mirrored in `game.yaml`) must stay green.
4. Check the 3.x changelog for the Draft 2020-12 / `$ref` handling the schema relies on; note anything that needed a
   schema edit (none expected).

## Acceptance
- [ ] `./mvnw -B -ntp -pl libs/contracts verify` green; `./mvnw -B -ntp -pl services/game-service -am verify
      -Dquarkus.http.test-port=0` green (totals)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation game-service` still at or above its baseline (the decoder is an adapter, so unchanged; record
      the score)
- [ ] Handover appended: API differences met, any wording kept by hand

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits (`build(deps): …`, `test(game): …`). A Claude Code hook runs a ~40 s tenant-isolation test
  before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it. End every
  commit message with the line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
