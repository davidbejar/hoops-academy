# WP137 — Library, services, build: Problem exceptions, paging, language, clock, shared properties, poms, test support, vectors

Model: Opus · high. Wave 4 (2026-11-23, ninth round): starts after wave 3 is merged; runs alongside WP138 (web). You
own `libs/**`, `services/core-service/**`, `services/game-service/**`, `services/athlete-service/**`, the root
`pom.xml`, `e2e/pom.xml`, and in the web app only `apps/web/test/fixtures/vectors/**` with the one test that reads it
(WP138 does not touch those). Depends on: WP130, WP134; ADR-0032, ADR-0053. Skills: work-package,
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp137-common-plumbing-properties-poms-test-support`, branch
`wp137-common-plumbing-properties-poms-test-support`.

Decision 104 of 2026-11-23: generic plumbing that exists per service moves to `common-quarkus`; domain code stays per
service. ADR-0069 is reserved for you (write it: what is shared, what stays per service and why; it amends ADR-0053
where needed).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `libs.md`
(LIB-02..LIB-13 except LIB-09), `cross-cutting.md` (X-04, X-06, X-07, X-09, X-10, X-12, X-13), verification
`verify-cross-cutting-libs.md` (its section "Overlaps between files" lists the per-service IDs of each: CORE-07,
CORE-08, CORE-15, CORE-18, CORET-07, GAME-07, GAME-09..12, ATH-06, ATH-08, ATH-09, ATH-13, ATH-17), all under
`~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Problem plumbing (LIB-03)**: one `InvalidRequestException`, `ProblemType` gains 415 and 502, the unreadable-JSON
   mapper for all three, no hand-built URN; answers validated against the contracts.
2. **Small shared types**: Accept-Language negotiation and the es/en/id enum (X-07), paging result / `PageMeta`
   (LIB-04), the `Clock` producer (X-12), the two pdf-service clients' keys and checks (X-06).
3. **Properties (X-04)**: the 25 keys identical in the three `application.properties` move to the library's file;
   restated defaults and the stale comment go; show with a test that each service still sees them.
4. **Poms (LIB-10)**: assertj, wiremock, json-schema-validator and the surefire / jacoco / `keycloak-it` boilerplate
   managed once in the root pom; athlete's 90 % domain rule (WP127) stays.
5. **Test support (LIB-05, X-10)**: contract filters, LogCapture, WireMock resources, core-event fixtures,
   tenant-bound JDBC into the test-jar; core gets the built-in-credentials test it lacks.
6. **Dead and tripled**: LIB-06 (`TenantHeaderPropagationFilter` with its tests and PIT entries), LIB-02 (projection
   vectors: one copy in `libs/contracts/vectors`, game and the web read it or a generated copy; the two sync tests and
   the script go if nothing is left to sync).
7. **The rest**: LIB-07, LIB-08, LIB-12, LIB-13 and whatever else of your scope is confirmed.
8. **Added at merge time of wave 1 (2026-11-24)**: WP127 and WP128 each wrote a paged-query builder
   (`PagedQuery` in athlete's and in core's `adapters/out/persistence`, two different APIs). One builder in the
   library, used by both; the semgrep acceptances for the two classes in `.semgrep/accepted.json` move to the one
   place (run the scan as `semgrep.yml` does, with the pinned image under Podman, and `scripts/sarif-gate.py`). A
   new call of core's `SessionSettingsRepository.set` / `.with` is flagged by `hoops-tenant-setting-rebound-by-hand`:
   do not add one.
9. **Added at merge time of WP131 (2026-11-24)**: `finance.yaml` declares no 413 and no 415 on its JSON-body
   operations although the service answers them (WP131 made the Go contract guard strict and found it). Add both
   responses (bump `info.version`, regenerate only `apps/web/packages/finance` with `scripts/gen-api.sh finance`), then
   remove the two `outside` marks in `TestInvalidRequestsAreProblemsNamingFieldsNeverValues` of
   `services/finance-service` (the one finance file you may touch) and run `just test-go`.

Not yours: X-08 / CORE-06 (`PatchBody` copies: FOLLOW-UPS and ADR-0053): leave. The realm variables (X-05) are WP139:
do not rename them while moving properties.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just web-test` green if the vectors moved
- [ ] `just mutation` for common-quarkus and the three services at or above baseline
- [ ] `just isolation-check` and `just db-role-check` run by hand
- [ ] contract versions bumped only if an answer really changed (say which)
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
- **Built** (commits `442767a5`..`dddc01ab` plus this docs commit; behaviour changes after their red tests):
  - **Dead filter (LIB-06)**: `TenantHeaderPropagationFilter`, its test, the wiring assertion and its PIT entries gone.
  - **Properties (X-04, LIB-11, CORE-08, CORE-15, GAME-12, ATH-13)**: the 25 lines identical in the three
    `application.properties` live in common's `microprofile-config.properties` (Dev Services topics, broker defaults,
    db-kind, schema handling, OIDC role path, early tokens, OTel build keys, the test profile's OIDC / JaCoCo /
    require-sub); `hoops.core.url`, the core health keys, `/q/health` and `/q/openapi` (defaults) are no longer
    restated; the stale Kafka comment is fixed. `LibraryDefaultsContract` (test-jar, red first: game and athlete
    restated `hoops.core.url`) shows each service sees the shared values and restates none. The `@ConfigProperty`
    `defaultValue`s that repeated a property went (11 keys in core, roster/replica/retention keys, overtime, horizon,
    zone); `hoops.keycloak.realm` stays (verification). athlete's calendar window reads `hoops.athlete.horizon-weeks`.
    game and athlete check that the channel subscribes to every `RosterTopic`. With the OTel keys common's own tests
    run like the services: its `/platform` probe got its own resource path (route template `//platform/...`).
  - **Poms (LIB-10, CORET-07, GAME-11, ATH-17, CI-13)**: assertj, wiremock-standalone, json-schema-validator managed
    in the root pom (were in 6, 3, 4 poms); surefire groups, the JaCoCo agent settings, the 90 % rule for
    `com.hoopsacademy.*.domain*` (athlete's WP127 rule kept) and `keycloak-it` in the root; the services no longer
    redeclare common's extensions; the dead failsafe management, `failsafe-plugin.version` and `skipITs` went.
  - **Problem plumbing (LIB-03, X-09, CORE-18, ATH-06, GAME-10 part)**: `common.problem.InvalidRequestException`
    (all violations) and its mapper replace three copies; `ProblemType.UNSUPPORTED_MEDIA_TYPE` (415) and
    `IDENTITY_PROVIDER_UNAVAILABLE` (502, core.yaml's slug) end core's hand-built URN; the wrong-type body mapper moved
    from athlete to common, so core and game now answer it with a `validation` Problem naming the field (was
    `about:blank` 400); athlete's `JsonParseException` mapper was dead (Quarkus wraps the parse error first; malformed
    JSON stays `about:blank` 400 in all three, test pins it); athlete's `TrainingRuleViolation` /
    `TrainingStateConflict` replaced by common's types. pdf-service's guard (`problem.rs`) keeps only
    `method-not-allowed` as its own slug.
  - **Small shared types (LIB-04, X-13, X-07, GAME-09, ATH-09 part, X-12, X-06)**: `common.paging` `PageRequest`,
    `PageResult`, `PageMeta`; `common.i18n` `AppLanguage` + `AcceptLanguage` (core's `AppLocale` and athlete's
    `ContentLocale` map from it, game uses it directly); `common.time.ClockProducer` (`@DefaultBean`, UTC);
    `common.client.PdfServiceClients` (client building, `%PDF-` check; core now refuses a non-PDF answer, red first,
    and reads `hoops.pdf.*` like game; time-outs stay per service).
  - **Paged-query builder (scope 8)**: core's `PagedQuery` + `QueryConditions` moved to `common.persistence` and
    serve athlete's five searches (athlete's builder gone); the three semgrep acceptances became one on the library
    class (fingerprint `2406cf1d3bc267a0`).
  - **Test support (LIB-05, X-10)**: `ContractFilters`, `LogCapture`, `RlsTestDatabase.bindTenant` (17 hand-written
    `set_config` in tests gone), `NoBuiltInCredentialsContract` (core now runs it; exemption `quarkus.mailer.password`,
    ADR-0044 §9).
  - **Vectors (LIB-02, GAME-07)**: one copy in `libs/contracts/vectors`; game's and the web's copies, the two
    byte-equality tests and `apps/web/tool/sync_vectors.sh` gone (-6,500 lines).
  - **finance contract (scope 9)**: `finance.yaml` 1.1.0 declares 413 / 415 on its ten JSON-body operations; the two
    `outside` marks in `TestInvalidRequestsAreProblemsNamingFieldsNeverValues` are gone; `apps/web/packages/finance`
    regenerated with openapi-generator 7.27.0 (the pom's version; only README and pubspec changed after the
    whitespace hooks) and `apps/web/pubspec.lock` follows it.
  - **Rest (LIB-08, LIB-12)**: `pdf.yaml`'s unused `JerseyNumber` removed (no answer changed, stays 1.0.0); the four
    exact spec-version pins are lower bounds through `OpenApiSpecs.version` / `release`.
  - Docs: ADR-0069 (amends ADR-0053, ADR-0014), model pages, `docs/quality/mutation.md` scope rows, game README,
    contracts vectors README.
- **Verified** (2026-11-24, fresh, on `dddc01ab`):
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 13:21 min, all coverage, SpotBugs, PMD and
    CPD gates met. Tests: contracts 346, common-quarkus 576 (was 492), core 1259, game 527, athlete 1025, e2e 38 (32
    skipped); 0 failures, 0 errors. (Fewer service tests: the Accept-Language, query-builder and credentials tests now
    run once in common.)
  - The inherited domain rule bites for athlete: `jacoco:check@check -Djacoco.domain.line.minimum=1.01` on
    athlete reports `Rule violated for package com.hoopsacademy.athlete.domain`, BUILD FAILURE.
  - `just mutation`: common-quarkus 486/487 (99.8 %, threshold 99), core 920/921 (99.9 %, 99), game 505/507 (99.6 %,
    99), athlete 620/620 (100 %, 100).
  - `just web-test`: 1920 tests, all passed (vectors read from `libs/contracts/vectors`). `just test-rust` (after
    `problem.rs` and `pdf.yaml`): 105 tests, coverage 95.72 % / 99.80 %, cargo deny ok. `just test-go` (after
    finance.yaml 1.1.0 and the test change): green, coverage 88.66 % / 98.84 %, govulncheck clean.
  - `python3 -I -m unittest discover -s scripts/tests`: 71 tests OK (1 skipped) after the root pom change.
  - Semgrep as `semgrep.yml` runs it (pinned image under Podman): rule tests 11/11; scan + `scripts/sarif-gate.py
    --fail-on error`: 26 ERROR findings, 26 accepted, gate passed.
  - `just isolation-check` (by hand, worktree, via the root `keycloak-it` profile): 6 tests + 4 finance Go tests
    passed. `just db-role-check`: 13 tests + 2 finance Go tests passed.
  - `scripts/model-diagrams.sh` regenerated `athlete-model.md` and `game-model.md`, then `--check`: up to date.
    `just docs-build` (strict): no issues.
  - Contract versions: finance.yaml 1.0.0 -> 1.1.0 (413 / 415 declared). No other spec changed version (`pdf.yaml`
    lost an unused schema only).
- **Decisions/ADRs**: ADR-0069 (what is shared, what stays per service and why), indexed; amendments appended to
  ADR-0053 and ADR-0014.
- **Open points / for the orchestrator**:
  - Root files changed: `pom.xml`, `.semgrep/accepted.json` (three PagedQuery entries became one), `docs/adr/README.md`,
    `docs/quality/mutation.md` (scope rows of common and athlete).
  - Web (WP138's area, not edited): `apps/web/README.md:186` still names `tool/sync_vectors.sh`; `apps/web/pubspec.lock`
    changed one line (hoops_finance_api 1.1.0); a merge with WP138 may need `flutter pub get`.
  - finance (not mine): `internal/adapters/in/rest/api_test.go:105-106` still says 413/415 are not declared yet.
  - Client-visible changes to note in the release: core and game answer a wrong-type body value with a `validation`
    Problem (`violations[0].code` `INVALID_VALUE`); core refuses a pdf-service answer that is not a PDF (503).
  - `kafka.sasl.jaas.config` carries `password="${KAFKA_SASL_PASSWORD:}"` in all three services; the credentials
    check does not see it (not a `*.password` key); left as it was (PLAINTEXT default needs no password).
  - Commit `c13c3bdd` was staged from a verified snapshot of the tree (`git --work-tree=<copy> add`) and committed
    without a path list, to keep it apart from the test-support changes made meanwhile; the hook ran as usual.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| LIB-02 | Done | One copy in `libs/contracts/vectors`; copies, sync script and byte checks gone |
| LIB-03 | Done | `InvalidRequestException`, 415/502 `ProblemType`s, wrong-type body mapper in common; the parse-error mapper was dead |
| LIB-04 | Done | `PageRequest`, `PageResult`, `PageMeta` in `common.paging` |
| LIB-05 | Done (part) | Contract filters, LogCapture, tenant binding in the test-jar; the core-event builders stay per service (ATH-08) |
| LIB-06 | Done | Filter, tests, PIT entries deleted |
| LIB-07 | Skipped | Moving components into `common.yaml` renames generated Dart types while WP138 changes the web app, for no answer that changes; for a contract round |
| LIB-08 | Done | `JerseyNumber` removed from `pdf.yaml` |
| LIB-10 | Done | Versions and build blocks in the root pom; redeclared extensions dropped |
| LIB-11 | Done | require-sub and `hoops.core.url` once; stale comment fixed |
| LIB-12 | Done | Lower bounds through `OpenApiSpecs.version` |
| LIB-13 | Skipped | Verification: not worth doing on its own (every consumer's schema loading, Go embeds copies); the test guards the copies |
| X-04 | Done | 25 shared keys in the library, `LibraryDefaultsContract` |
| X-06 | Done (as corrected) | `PdfServiceClients`, one key family, PDF check in core; time-outs stay per service |
| X-07 | Done | `AppLanguage` + `AcceptLanguage` in common |
| X-09 | Done | As LIB-03; athlete's exception pair replaced |
| X-10 | Done (part) | LogCapture, credentials check (core too), contract filters; WireMock resources, `TokenAudienceKeycloakTest`, `HealthEndpointsTest` left: different keys / stubs, Keycloak-only, small gain |
| X-12 | Done | `ClockProducer` in common |
| X-13 | Done | As LIB-04 |
| CORE-07 | Done (part) | `PageMeta` shared; the 12 page/size parameter pairs and per-resource page records stay (one record per contract schema) |
| CORE-08 | Done | As X-04 |
| CORE-15 | Done (as corrected) | `defaultValue`s dropped; `hoops.keycloak.realm` kept (verification); the withdrawn retention stays read as a `String` and parsed to a calendar `Period`, which the code needs |
| CORE-18 | Done | As LIB-03 |
| CORET-07 | Done | As LIB-10 |
| GAME-07 | Done | As LIB-02 |
| GAME-09 | Done | As X-07 |
| GAME-10 | Done | Clock, InvalidRequest, LogCapture, Contract; WireMock resource stays |
| GAME-11 | Done | As LIB-10 |
| GAME-12 | Done | Restated defaults gone; topics test against `RosterTopic` |
| ATH-06 | Done | `DomainRuleViolation` / `ConflictException` |
| ATH-08 | Skipped | Verification PARTLY: two builder APIs over two replicas, test-only, low impact |
| ATH-09 | Done (part) | Accept-Language, InvalidRequest, Jackson mapper, PageResult; `PatchBody` excluded (X-08) |
| ATH-13 | Done | Defaults, topics, horizon injected |
| ATH-17 | Done | As LIB-10 |
| CI-13 | Done | Dead failsafe management removed (root pom) |
| Scope 8 | Done | One `PagedQuery` in common; semgrep acceptances moved |
| Scope 9 | Done | finance.yaml 1.1.0, outside marks gone, package regenerated |
