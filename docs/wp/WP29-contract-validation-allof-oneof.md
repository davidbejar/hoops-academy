# WP29 — Contracts: make every real response validatable (allOf + additionalProperties, MatchEvent oneOf)

Model: Opus. Depends on: WP2c, WP18b. Skills: test-driven-development, verification-before-completion,
quarkus-hexagonal-service (contract-first rules). Worktree: `~/code/hoops-wt/wp29-contract-validation`, branch
`wp29-contract-validation`.

Two validator gaps let real responses escape the contract check (`libs/contracts/README.md` documents the quirks):
- Schemas composed as `allOf: [X, {id}]` where a member has `additionalProperties: false` (e.g. `AgeCategory =
  allOf[AgeCategoryInput, {id}]`) cannot validate any real response; the service tests and the e2e journey *mute*
  those validation errors.
- `MatchEvent` oneOf/discriminator is not resolvable by the atlassian validator for feed responses; e2e reads the
  feed unvalidated.

Goal: no muted validation anywhere; every response in tests and e2e is validated against the contract.

## Scope
- Find every mute: search the services' test code, `libs/common-quarkus` test support and `e2e/` for the ignore /
  whitelist of validation messages (names like `additionalProperties`, `allOf`, `oneOf`, `discriminator`,
  `ValidationErrorsWhitelist`, `ignore`). List them in the handover.
- Fix the schemas, not the validator: drop `additionalProperties: false` from composed members (or restructure the
  composition so the response schema is a plain object), keep request strictness where it matters; give `MatchEvent`
  a shape the validator resolves (e.g. explicit `discriminator.mapping`, or a flattened object with a `type` enum and
  nullable variant fields, whichever keeps the generated Dart client usable). Version bumps follow the contract
  README's rules (patch if the wire format is unchanged).
- Remove the mutes; run the suites; fix whatever real mismatch the validator then finds (a response field missing
  from the contract is a contract bug: add it, with a test).
- `just gen-api` if a schema changed shape; the Dart packages are generated, never hand-edited. `apps/web` must still
  compile and `just web-test` stay green; do not change app code beyond what the regenerated models force (note any
  forced change in the handover, WP35 may touch the same screens).
- e2e: enable feed validation; run the journey on the compose stack if you can (`docs/runbooks/e2e.md`; only one
  compose stack can run on this machine, check `podman ps` first and skip with a note if it is in use).

## Acceptance
- [x] No validation whitelist / ignore left in services, common-quarkus test support or e2e (grep evidence; only deliberate test modes remain, see Handover)
- [x] `./mvnw -B -ntp -T 1C verify` green (fresh; module totals in the handover)
- [x] `just web-test` green if packages were regenerated (after the rebase onto main with the golden fix: 541 passed)
- [x] `libs/contracts/README.md` quirk section updated (what is gone, what remains)
- [x] Handover appended

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
  anything another WP must know (especially contract versions and regenerated packages).

## Handover
- Built:
  - Root cause: swagger-request-validator (default config) injects `additionalProperties: false` into every object
    schema with `properties`; no schema had an explicit `false`. So each `allOf` part rejected the other parts' fields,
    and the `MatchEvent` variants (each `allOf[MatchEventBase, {type}, …]`) never matched (`discriminator.oneOf.no_match_found`).
  - Contracts (ADR-0027): the 33 composed schemas are plain objects (core 7: `*WithPassword`, `InviteMemberRequest`,
    `Season`, `AgeCategory`; athlete 11; game: the 15 `<Type>Event`s). Each names its bases in `x-extends`; field groups
    that are not wire types (`PersonalData`, `AuditInfo`, `MatchEventBase`, `PlayerAttribution`) moved to
    `components.x-mixins` (openapi-generator's strict validate rejects unused schemas). `MatchEvent` keeps
    oneOf + discriminator mapping; the default validator resolves it once the variants are plain.
    Versions (patch, wire unchanged): **core 2.3.1, game 2.0.1, athlete 2.0.1** (common unchanged).
  - `StrictValidatorCompatibilityTest` (contracts, 14 tests): no multi-part `allOf` in any spec; every `x-extends` copy
    identical to its base (mutation-checked: changing `Injury.recordedAt` fails it); no unused mixin; every variant
    extends `MatchEventBase`; a feed with one example event of every type passes the default validator, an
    undeclared event property and a SHOT with a rebound payload fail it. Contracts now test-depend on
    `openapi-request-validator-core`.
  - Mutes removed (were): athlete `ApiSupport.ALLOF_FRIENDLY` (request + response `additionalProperties` IGNORE, also in
    `RESPONSE_ONLY`); core `Contract` (`withResolveCombinators(true)` on all filters, request `additionalProperties`
    IGNORE in `CORE` and `FAILURES`); game `Contract` (`EVENTS`/`BATCH`/`FEED` with `withResolveCombinators` against a
    regex-rewritten copy of game.yaml, plus `security.missing/invalid` IGNORE: the filter now sends `Bearer test`);
    e2e `Contracts` (`isAllOfArtifact` filter, `response.body.missing` WARN, `validation.request` IGNORE) and
    `JourneyTest` reading the feed and two polling calls with `getUnvalidated` (removed with `postUnvalidated`).
    e2e now validates requests too. core's 502 tests use the strict `CORE` filter (502 is declared).
  - Remaining level overrides (grep below), all deliberate test modes: `validation.request` IGNORE in the
    response-only filters (athlete `lenient`, core/game `RESPONSES_ONLY`) and core `UNEXPECTED_FAILURE`
    (`response.status.unknown`, 2 fault-injection tests that provoke an undeclared 500). Audit: with request
    validation forced on for every response-only call, the 44 failing tests (22 core, 22 athlete) are all deliberate
    invalid-input steps (required/enum/minimum/pattern/format/missing param/forbidden field such as `phone`).
  - Dart: `just gen-api` regenerated core/game/athlete (`$Foo` interface classes and `MatchEventBase`/
    `PlayerAttribution`/`AuditInfo`/`PersonalData` gone). Forced app changes: `api.$XInput(...)` → `api.XInput(...)` in
    6 lib files (age categories, seasons, health providers, fitness screens, training providers, plans screen) and
    test support (`$Member`, `$Tenant`, `$TenantAdmin`, `$ApprovalRequest`, `$TrainingPlanSummary`; nested
    `approvalRequest`/`plan` now `.replace(...)`). Generated files were run through the repo's trailing-whitespace /
    end-of-file hooks like the earlier committed generation.
  - Docs: libs/contracts README (convention, validation section, quirks: allOf/discriminator gone, colons remain),
    ADR-0027, docs/runbooks/e2e.md.
- Verified:
  - `./mvnw -B -ntp -T 1C verify` (fresh): BUILD SUCCESS; common-quarkus 172, contracts 134, core 691, game 196,
    athlete 581 tests, 0 failures; all coverage checks met; openapi-generator strict validate of the 3 specs OK.
  - `just e2e` on compose (stack was free; brought down afterwards): run 2 **21 tests, 0 failures** (68 s) with
    request + response validation and the feed validated. Run 1 had one failure unrelated to validation: step 60,
    `GET /api/core/me` answered a server-side 404 right after suspending tenant A (expected 200); not reproduced.
  - `flutter analyze`: no issues. `just web-test`: 537 passed, 1 failed: golden `week calendar, ADMIN, 360x780` —
    the "today" highlight comes from `DateTime.now()` (training_screen.dart:182) while the fixture week is fixed at
    2026-11-02, so the golden fails on any other day; pre-existing, not touched (app code, WP28/WP35 territory).
  - Grep evidence (`Level.(IGNORE|WARN|INFO)|withResolveCombinators|additionalProperties|Whitelist|isAllOfArtifact|Unvalidated`
    over services/*/src/test, libs/common-quarkus/src, e2e/src): only the 4 deliberate lines listed above.
- Decisions/ADRs: ADR-0027 (no allOf composition, `x-extends`/`x-mixins`, default strict validator; supersedes the
  derived-copy sentence of ADR-0016 §2).
- Open points / follow-ups:
  - ~100 response-only call sites (athlete `lenient`, core `RESPONSES_ONLY`) send valid requests and could use the
    strict filter; left as is (no contract gap hidden, response still validated).
  - The date-dependent training-week golden (above); the one-off e2e `/me` 404 after suspension (above).
  - WP27 (norms) edits athlete.yaml in parallel: on merge, keep `PhysicalTestNorm` flat (`x-extends:
    [PhysicalTestNormInput]`, copy any new input field) and re-bump athlete; regenerate the Dart package.
  - My `./mvnw -pl libs/contracts install` put this branch's contracts jar into the shared `~/.m2` once; builds that
    do not use the reactor (`-am`) pick it up until someone installs again.
- Rebase onto main (WP26/27/28/30/31 + week-golden fix), no textual conflicts. ADR renamed 0025 → **ADR-0027**
  (0025 is WP26's, 0026 WP31's; note: the WP32 brief also announces an "ADR-0027" and will need the next free number)
  and indexed in docs/adr/README.md (the index has no 0026 row yet). WP31's new `Contract.FAILURES` call (502) now
  uses `Contract.CORE`; core/game service READMEs describe the strict filters. athlete.yaml was not changed by WP27,
  so athlete 2.0.1 stands; core 2.3.1 includes WP31's description change; `just gen-api` re-run (only
  `platform_api.dart` doc comment changed). Fresh: `./mvnw -B -ntp -T 1C verify` BUILD SUCCESS (common 172,
  contracts 134, core 701, game 196, athlete 586, coverage met); `flutter analyze` clean; `flutter test` 541 passed.
