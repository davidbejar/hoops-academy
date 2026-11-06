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

## Handover
- Outcome: **not migrated, by decision.** The orchestrator chose option B on 2026-11-06: stay on
  `com.networknt:json-schema-validator` 2.0.8. Dependabot now ignores its semver-major updates
  (`.github/dependabot.yml`, maven block, with the reason as a comment). PR #3 was not touched. It stays open until
  someone closes it (the ignore rule only stops new major PRs).
- Root cause (systematic-debugging): every red job on PR #3 (backend, dependency-check, trivy-fs, zap-baseline,
  journeys) fails at the same `testCompile` of `MatchEventJsonSchemaTest`. 3.0.0 (changelog: "Upgrade to Jackson 3 and
  JDK 17", #1219) keeps the package and class names (`SchemaRegistry`, `Schema`, `Error`, `SpecificationVersion`).
  Its tree arguments are now `tools.jackson.databind.JsonNode` (Jackson 3) instead of `com.fasterxml…JsonNode`. 3.0.8
  pulls `tools.jackson.core:jackson-databind` 3.2.1 and `jackson-dataformat-yaml` 3.2.1.
- Blocker: the strict OpenAPI validator `com.atlassian.oai:openapi-request-validator-core` 3.0.0 (ADR-0027) depends
  on networknt 2.0.1. It calls `SchemaRegistry.getSchema(com.fasterxml JsonNode)` and
  `Schema.validate(com.fasterxml JsonNode)` (checked with `javap`). 3.0.0 is still its newest release on Maven
  Central (checked 2026-11-06, `lastUpdated` 2026-05-13). Both lines use the same class names, so they cannot share a
  classpath. With 3.0.8, `./mvnw -pl libs/contracts verify` gave 152 tests with 5 errors, all
  `NoSuchMethodError: 'com.networknt.schema.Schema com.networknt.schema.SchemaRegistry.getSchema(com.fasterxml.jackson.databind.JsonNode)'`:
  three in `StrictValidatorCompatibilityTest` (`aFeedOfEveryEventTypePassesTheStrictValidator`,
  `theStrictValidatorRejectsAPayloadThatDoesNotMatchTheType`, `theStrictValidatorRejectsAnUndeclaredEventProperty`)
  and two in `UpdateRequestClearListContractTest`. The game-service `Contract` filter would fail the same way.
  Managing the version in the root pom would also break core, athlete and e2e, because they get the validator
  transitively.
- Migration ready for our own three usages: pass the JSON text instead of a Jackson 2 tree. Both 2.0.8 and 3.0.8 have
  `SchemaRegistry.getSchema(String, InputFormat)` / `getSchema(InputStream)` and
  `Schema.validate(String, InputFormat)`:
  - `MatchEventJsonSchemaTest`: `registry.getSchema(schemaDocument.toString(), InputFormat.JSON)`, plus a helper
    `validate(Schema s, JsonNode n) { return s.validate(n.toString(), InputFormat.JSON); }` used for the meta-schema
    and every event. With 3.0.8 it was green: 25 tests, including the Draft 2020-12 meta-schema check and the
    `$ref`/`$defs`/if-then dispatch. No schema edit was needed. `MatchEventSchemaConsistencyTest` was green too (5).
  - `MatchEventDecoder`: `schema.validate(json.toString(), InputFormat.JSON)` and
    `getSchema(in, InputFormat.JSON)` (the stream directly, no `mapper.readTree`). `EventSchema` (test support):
    the same. `Error.getInstanceLocation()` / `getMessage()` are unchanged, so the `results[].message` mapping stays.
  - One version in the root `pom.xml` (property plus `dependencyManagement`) replaces the two module properties, once
    the strict validator moves to networknt 3.x.
- Built (kept): `MatchEventDecoderTest.schemaViolationMessagesKeepTheirWording` (commit 5e958e8) pins the exact
  `results[].message` of six violations on 2.0.8. A later bump that changes the wording turns it red. The 3.x
  wording was never measured in game-service, because its test classpath needs the strict validator.
- Verified (2.0.8, fresh, 2026-11-06):
  - `./mvnw -B -ntp -pl libs/contracts verify`: 152 tests, 0 failures, BUILD SUCCESS.
  - `./mvnw -B -ntp -pl services/game-service -am verify -Dquarkus.http.test-port=0`: common-quarkus 186,
    contracts 152, game-service 256, BUILD SUCCESS.
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: common 186, contracts 152, game 256, athlete 653,
    core 773, e2e 25 (21 journeys skipped without a stack, as usual). 2045 tests, 0 failures, coverage gates
    passed, BUILD SUCCESS.
  - `just mutation game-service`: 401 mutations, 399 killed (99.5 %), test strength 99 %. This equals the baseline
    in `docs/quality/mutation.md` (threshold 95).
  - The `.github/dependabot.yml` change parses as valid YAML (Ruby `YAML.load_file`). The maven `ignore` entry is
    `{dependency-name: com.networknt:json-schema-validator, update-types: [version-update:semver-major]}`.
- Decisions/ADRs: no new ADR. Option B keeps ADR-0027 as it is. Option A, a shaded module that relocates networknt
  3.x, was rejected as too much build complexity for a test-only gain.
- Open points: (1) once swagger-request-validator ships on networknt 3.x, remove the Dependabot ignore entry and
  apply the migration above (this needs a FOLLOW-UPS entry, which I may not write). (2) PR #3 is still open: it can
  be closed by hand, or with `@dependabot ignore this major version`, which matches the new rule.
