# ADR-0032: Update requests name the fields to clear in a `clear` list

- Status: Accepted
- Date: 2026-11-06
- Related: ADR-0027 (contracts without allOf, strict validator), WP35 (missing operations), WP39, decision 17 of the
  2026-11-06 interview

## Context
The services read a `PATCH` body as a JSON merge patch: an absent property is unchanged, an explicit `null` clears
it (athlete's `PatchBody`, core's `MergePatch`). The contracts only say `nullable: true` on those properties. The web
app cannot use the `null` half: the generated dart-dio / built_value clients omit every property whose value is null,
so "the user emptied the location" and "the user did not touch the location" produce the same body. WP35 had to ship
edit dialogs that can change a session's plan, an absence reason or a measurement but never remove them.

A tri-state in the client (absent / null / value) would need hand-written serialisers or a wrapper type per property
in generated code that is never edited, and every new client generator would bring the problem back.

## Decision
1. **Every `Update*Request` with optional, nullable-in-storage properties carries `clear`**: an array of property
   names, `uniqueItems`, whose items are an `enum` of exactly those properties of that request. The strict validator
   (ADR-0027) therefore rejects a typo, a required property or a property that cannot be null (400).
2. **Semantics.** A property absent from the body, or sent as `null`, is unchanged. A property named in `clear` is set
   to null (a reference such as `planId` is detached). A property both named in `clear` and given a value is a
   contradiction and answers 400 (`CLEAR_CONFLICT`); the service never guesses which one wins. `clear` alone is a
   valid body (`minProperties: 1` counts it); an empty `clear` with nothing else is an empty patch (400).
3. **Required fields are never clearable**, and neither are properties whose stored column is `not null`
   (`startsAt`, `name`, `measuredOn`, ...). Domain rules still apply after clearing (a body measurement needs a
   height or a weight: clearing both is 422).
4. **Services validate the list themselves too** (unknown or non-clearable name: 400 `INVALID_VALUE` on `clear`), so a
   client that skips contract validation gets the same answer.
5. `UpdateRequestClearListContractTest` (libs/contracts) enforces 1 for every spec listed as adopted.

## Adoption
- **athlete 2.1.0 (WP39):** the nine update requests (`UpdateTrainingSessionRequest`, `UpdatePlannedAbsenceRequest`,
  `UpdateBodyMeasurementRequest`, `UpdatePhysicalTestResultRequest`, `UpdateInjuryRequest`,
  `UpdateTrainingPlanRequest`, `UpdatePlanItemRequest`, `UpdateTrainingScheduleRequest`,
  `UpdatePhysicalTestTypeRequest`).
- **core 2.7.0 (WP44):** `UpdateTenantProfileRequest` (contactEmail, websiteUrl), `UpdateMemberRequest` (email, phone,
  birthDate, gender), `UpdateAgeCategoryRequest` (maxAge), `UpdateTeamRequest` (alias), `UpdateTeamPlayerRequest`
  (jerseyNumber, no longer required; `minProperties: 1`). `UpdateTenantAdminRequest`, `UpdateTenantRequest`,
  `UpdateMeRequest` and `UpdateSeasonRequest` have nothing nullable and get no `clear`. Core's `MergePatch` became
  `PatchBody` (a member is nullable exactly when the resource declares it clearable; violations are still collected
  into one 400, `CLEAR_CONFLICT` and `INVALID_VALUE` as violation codes).
- **game 2.2.0 (WP45):** `UpdateMatchRequest` (`venue` is its only clearable property). game-service reads a `null` as
  unchanged, answers 400 `CLEAR_CONFLICT` for a value that is also in `clear`, and the web repository's `update` names
  an emptied venue in `clear`.

## Alternatives rejected
- **Explicit `null` as the clear signal** (keep merge patch): correct on the wire, unusable from the generated Dart
  clients (absent and null serialise the same), and invisible in the contract beyond `nullable: true`.
- **Sentinel values** (`""`, `0`, a nil UUID): type-specific, collide with real values, and the validator cannot tell
  them apart from data.
- **`PUT` of the whole resource**: forces clients to resend fields they did not load (and audit fields), and makes
  concurrent edits of different fields overwrite each other.

## Consequences
- A minor contract bump: `clear` is a new optional request property. The service's reading of an explicit `null`
  changes from "clear" to "unchanged"; the contract never documented the former, the generated client never sent it,
  and only athlete's own tests relied on it (rewritten to use `clear`).
- One generated enum per request in the Dart package (`Update<X>RequestClearEnum`). The web edit dialogs send the
  whole form and name every optional field it leaves empty (`clearList`, `apps/web/lib/core/api/clear_list.dart`);
  naming a field that is already null is harmless.
