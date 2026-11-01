# WP10 — athlete-service: injuries, body measurements, physical tests + norms

Model: Sonnet. Depends on: WP8. Lane ATHLETE. Plan §2 "Health & fitness". Skills: as WP8; docs/domain/norms.md must cite sources.

## Scope
- Flyway: `injury`, `body_measurement` (unique player+measured_on), `physical_test_type` (code pk, name, unit,
  higher_is_better, global flag, tenant_id null), `physical_test_result`, `physical_test_norm` (tenant_id null = global;
  test_type, gender, age_min, age_max, band, min_value, max_value).
- Seeds: test types COOPER_12MIN (m), SPRINT_20M (s), VERTICAL_JUMP (cm), AGILITY_T_TEST (s), SIT_AND_REACH (cm),
  BEEP_TEST (level); norms for ages 8–18 by gender from published sources (cite in docs/domain/norms.md; values
  without a source are flagged `reference_pending=true` and shown as such by the UI).
- Use cases: injuries CRUD (staff; parent for linked; player read self) with availability flag exposed via
  `GET /players/{id}/availability`; measurements CRUD (staff, parent linked; player read) + history; test types list
  (+ tenant custom types); results CRUD (staff) returning `expectedBand` computed from norms (tenant override > global;
  age at measurement, gender from RosterPort); norms admin CRUD (tenant overrides).

## Acceptance
- [x] band resolution tests: override precedence, age edges, higher/lower-is-better, missing norm → null band + flag (`BandResolverTest` 16, `PhysicalTestApiTest` 16)
- [x] invariants: expected_return ≥ occurred_on; unique measurement per day; permissions matrix (`HealthDomainTest` 14, `InjuryApiTest` 9, `BodyMeasurementApiTest` 7, `HealthRoleMatrixTest` 148)
- [x] norms seed cites a source per (test, gender) block (sourced = Cooper 13-19 only, the rest is flagged placeholder); RLS suites; contract validation; verify green (`NormSeedTest` 5, `HealthRlsIsolationTest` 7, generic suite 9, `clean verify` BUILD SUCCESS, 566 tests)

## Handover

### Built
Everything in `services/athlete-service`, `docs/domain/norms.md` (new) and this file. No other module touched, no git commands.
- **Flyway `V3__health.sql`**: `injury` (checks: expected/actual return >= occurred_on, RECOVERED needs actual_return_on; `version`),
  `body_measurement` (unique tenant+player+day, height numeric(5,1), weight numeric(5,2), at least one), `physical_test_result`,
  `physical_test_type` and `physical_test_norm` (global rows + tenant rows). Tenant tables use `app.enable_tenant_rls`; the two
  global/tenant tables use the WP9 pattern (`owner_tenant_id`, forced RLS, separate select/insert/update/delete policies).
  **`R__physical_test_norms.sql`**: 6 global types and 630 global norm rows (ages 8-18, both genders, five bands, one row per
  single year except the sourced Cooper blocks), uuid5 ids, `NO FORCE` / upsert / `FORCE` inside one transaction like WP9.
- **domain**: `Injury` (invariants, `blocksAvailability(today)`), `PlayerAvailability`, `BodyMeasurement`, `PhysicalTestType`,
  `PhysicalTestResult`, `PhysicalTestNorm`, `BandResolver` (pure: effective norms, band lookup, ordering check), `AgeAt`, enums
  `Gender`, `NormBand`, `InjurySeverity`, `InjuryStatus`, ids.
- **application**: `HealthAccess` (the health authz rules), `ManageInjuries` (+ availability), `ManageMeasurements`, `ManageTestTypes`,
  `ManageTestResults` (batch-resolves players, types, norms per page and computes the band), `ManageNorms`; ports `InjuryRepository`,
  `MeasurementRepository`, `TestTypeRepository`, `TestResultRepository`, `NormRepository`; `PlayerBrief` now carries `birthDate`
  and `gender` (read from core's `players:batch`); `ReportUsage` adds `injuries`, `bodyMeasurements`, `physicalTestResults`.
- **adapters**: `InjuryResource`, `PlayerAvailabilityResource`, `BodyMeasurementResource`, `PhysicalTestTypeResource`,
  `PhysicalTestResultResource`, `PhysicalTestNormResource`, `HealthDtos`; JPA repositories/entities (type and norm entities without
  `@TenantId`, like plans). Contract operations implemented: all of `Injuries`, `BodyMeasurements`, `PhysicalTests` (types list/create/get/patch,
  results list/create/get/patch/delete, norms list/create/replace/delete).
- Problem codes: `INJURY_RETURN_BEFORE_OCCURRENCE`, `RECOVERY_DATE_REQUIRED`, `INVALID_INJURY` (422); `MEASUREMENT_EMPTY`,
  `MEASUREMENT_OUT_OF_RANGE` (422), `MEASUREMENT_EXISTS_FOR_DATE` (409); `TEST_TYPE_IS_GLOBAL` (403), `TEST_TYPE_CODE_EXISTS` (409),
  `INVALID_TEST_TYPE` (422); `RESULT_VALUE_NEGATIVE`, `RESULT_OUT_OF_RANGE` (422); `NORM_IS_GLOBAL` (403), `NORM_RANGE_OVERLAP` (409),
  `NORM_INVALID_AGE_RANGE`, `NORM_INVALID_VALUE_RANGE` (422).

### How verified (fresh `source scripts/env.sh && ./mvnw -pl services/athlete-service clean verify`, 2026-11-02)
**BUILD SUCCESS, 566 tests (was 341), 0 failures/errors/skipped. JaCoCo lines 96.8 % (2336/2413), branches 87.1 % (712/817);
`domain` 95.8 %, `application` 98.4 %; gate 80 % passed.** All REST calls (except availability) go through `ApiSupport`, i.e. request and
response are validated against `athlete.yaml`.
| Area | Tests |
|---|---|
| `BandResolverTest` (16) | tenant override precedence, no fallback when the override leaves the value uncovered, overrides for other gender/ages leave global rows, effective set, [min,max) value edges, inclusive age edges, wrong gender, missing gender/birth date -> `MISSING_PLAYER_DATA`, no norms -> `NO_NORM`, `reference_pending` propagated, ordering check for higher- and lower-is-better, age in full years, norm invariants |
| `HealthDomainTest` (14) | injury invariants, recovery rules, availability around `today` (overdue, no estimate, recovered, OPEN with actual return and expected day = today / yesterday), latest expected return of several injuries, measurement and type invariants |
| `InjuryApiTest` (9), `BodyMeasurementApiTest` (7), `PhysicalTestApiTest` (16) | CRUD, filters/paging, parent/player/staff scoping, 422/409/400/404, cross-tenant 404, expected band from global/sourced/placeholder norms, age at measurement date, tenant override and its removal, scope filter, overlap |
| `HealthRoleMatrixTest` (148 parameterised) | injuries, measurements, results, availability, history, types, norms for every role and the unions (COACH of other team + PARENT, ADMIN + PLAYER, member without role) |
| RLS: `HealthRlsIsolationTest` (7), `AthleteGenericRlsIsolationTest` (now 9: injury, body_measurement, physical_test_result added with fixture overrides), `AthleteRlsSchemaMetaTest` (global allow-list with reasons for the two new tables), `NormSeedTest` (5) | tenant A cannot update/delete/insert global rows nor see/modify B's overrides, cannot make its row global or hand it over, no tenant -> error, exactly four per-command policies and no FOR ALL policy; seed: 6 types, every (test, gender, age 8-18) has 5 contiguous ordered bands, placeholders == flagged pending, Cooper blocks cite Cooper 1968, rerun changes nothing and FORCE is restored |
| `UsageAndInternalApiTest` | `injuries`, `bodyMeasurements`, `physicalTestResults` counters |

### TDD log (first failing test per feature)
| Feature | First failing test and why |
|---|---|
| Domain (norm lookup, injury, availability, measurement, types) | `BandResolverTest`, `HealthDomainTest`, `NormSeedTest`: compilation failure (`BandResolver`, `Injury`, ... did not exist), seen red before any domain code |
| Migration / RLS | **Honest deviation:** the RLS tests were red only at compile level (they use the new domain classes); `V3__health.sql` and the seed were then written in the same pass and the first real run of the suites failed on a test-side bug (lower-case generated `code` violating the code check), not on a missing table. The policy-per-command assertion (no FOR ALL) is written down from the WP9 lesson and was green at first run |
| Injuries, measurements, tests, role matrix | `InjuryApiTest`, `BodyMeasurementApiTest`, `PhysicalTestApiTest`, `HealthRoleMatrixTest`, `UsageAndInternalApiTest`: 184 tests run, 139 failures + 39 errors (404 everywhere, no resources) before the application and adapter code existed |
| After green | two test-side data-accumulation fixes (measurement history and availability used players shared with other tests: now a date range and a dedicated player) |
Written after the code, not seen red: nothing else of note (the `PlayerBrief` adapter change is covered by the API tests that need birth date and gender).

### Decisions
- **Contract wins over the brief**: bands are `POOR, BELOW_AVERAGE, AVERAGE, ABOVE_AVERAGE, EXCELLENT` (brief said `GOOD`); test types have a `uuid id`
  (path `{testTypeId}`) with `code` as a unique business key (brief: code pk); results/norms reference `test_type_id`; norms have `PUT` (no PATCH);
  tenant type/norm column is `owner_tenant_id` (as WP9), not `tenant_id`; injury/measurement/result audit = `recordedBy {personId, displayName}` + `recordedAt`
  (columns `*_by_person_id`, `*_by_name`, `created_at`).
- **Health data is team-scoped** (matrix says "team staff"): ADMIN, or COACH/ASSISTANT_COACH with a team the player is in (via `RosterPort.teamRoster`), write; PARENT linked
  writes injuries and measurements and deletes measurements (not injuries, contract: delete = ADMIN/staff); PLAYER reads self. Lists for staff are limited to the players of
  their teams (unlike training data, which WP8/9 made readable for all staff). Single resource not readable by the caller -> 404, readable but no write right -> 403, naming
  an unreadable player in a body or filter -> 403 (as planned absences), member without role -> 403.
- **Availability rule** (`Injury.blocksAvailability`): OPEN and (no `actual_return_on` or `expected_return_on >= today`). So an OPEN injury past its expected date without an
  actual return still blocks (nobody confirmed recovery). "Today" is the tenant's day (`TenantClock`); the pure function takes `today` so tests need no clock override.
  Result: `{playerId, available, expectedReturnOn (latest of the blocking), injuries[ids]}`.
- **Band lookup**: `effective(norms)` = tenant rows + global rows with no overlapping tenant row of the same test and gender; then gender/age/value select the row
  (value range [min, max), ages inclusive). `bandStatus` (`MATCHED | NO_NORM | MISSING_PLAYER_DATA`) is the "flag" of the brief; it is an **addition** to the contract's
  `PhysicalTestResult` (the validator ignores extra properties). When the birth date is unknown `ageAtMeasurement` is 0 (the contract field is required).
  Bands are computed at read time, so overriding or deleting a norm changes existing results (documented in norms.md).
- Tenant norm `referencePending` = no source given. Overlap rule is the contract's: same test, gender and band with overlapping ages -> 409 (value ranges across bands are not cross-checked).
- Test type code must be unique across global and visible tenant types (use case check, so another tenant's codes are never revealed); DB uniqueness is per layer only.
- `physical_test_result.test_type_id` is a plain FK (RI checks bypass RLS); the use cases only resolve types visible under RLS, so a tenant cannot reference another tenant's type through the API.
- Placeholder norms are one row per year of age; sourced Cooper blocks are 2-3 year ranges (13-14, 15-16, 17-19; the 19 is outside 8-18 but harmless).

### Norm blocks: sourced vs placeholder
- **Sourced** (`reference_pending=false`): COOPER_12MIN, boys and girls, ages 13-14, 15-16, 17-19 - Cooper KH, JAMA 1968;203(3):201-204. **Transcribed from memory** of the widely reproduced
  table, not checked against the paper: verify before trusting.
- **Placeholder** (`reference_pending=true`, source starts "placeholder"): COOPER_12MIN ages 8-12; SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST, SIT_AND_REACH, BEEP_TEST for all ages and both genders.
  Generated by a documented linear model (see `docs/domain/norms.md`), monotone and contiguous, not from any publication. Candidate sources are listed there (not used, not verified).

### Open points
- **Contract gaps (libs/contracts owner)**: `GET /api/athlete/players/{playerId}/availability` (implemented as `{playerId, available, expectedReturnOn?, injuries[]}`, not validated against the
  contract because the path is not in it), `bandStatus` on `PhysicalTestResult`, and a note that health lists for team staff are limited to their teams.
- Replace placeholders with cited tables (FITNESSGRAM/Cooper Institute, Eurofit/ALPHA-Fit, Tomkinson 2018 for the 20 m shuttle, ...) and verify the Cooper figures; this is data work, the schema and UI flag are ready.
- Race on `MEASUREMENT_EXISTS_FOR_DATE`: the use case checks first; two simultaneous inserts would hit the unique constraint as a 500 (single-writer in practice).
- Results of a deleted/unknown-to-core player show age 0 and `MISSING_PLAYER_DATA`.
- Staff list scoping calls one cached roster per staff team per request (30 s cache); fine for an academy, revisit with the roster replica (ADR-0008 v2).
- Common-quarkus candidate (already noted in WP9): a hook for tables with a nullable tenant column; this package added two more such tables to the allow-list.
