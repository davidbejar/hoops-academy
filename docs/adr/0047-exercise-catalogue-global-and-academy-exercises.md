# ADR-0047: An exercise catalogue of global and academy exercises; plan items copy an exercise and keep a reference to it

- Status: Accepted (WP92, athlete 3.0.0)
- Date: 2026-11-10
- Related: decisions 54 and 72, ADR-0041 (sessions reference plans, item search, quick-add), ADR-0039 (localized
  template texts), ADR-0032 (`clear` lists), ADR-0027 (contracts without allOf), ADR-0006 (RLS), ADR-0016 §6 (global
  rows with a null owner), `libs/contracts/openapi/athlete.yaml`,
  `services/athlete-service/src/main/resources/db/migration/V10__exercise_catalogue.sql`,
  `R__exercise_catalogue.sql`, `R__plan_templates.sql`

## Context
Until 3.0.0 an exercise existed only as the item of a plan: the ten seeded templates held 59 items, an academy wrote its
own items in its plans, and WP78 (ADR-0041) made items findable by title and copyable into a session or a plan. The
owner decided (decision 72, closing decision 54) that exercises become their own entity: global, localised exercises
plus the ones an academy defines; the seeded templates' distinct items become catalogue exercises in es / en / id, the
Cooper test is added, templates reference exercises, and tenant plan and session items keep their own text and gain an
optional exercise reference, so nothing a coach wrote changes.

## Decision
1. **One table, the template pattern.** `athlete.exercise` holds both kinds: a global exercise has a null
   `owner_tenant_id`, a stable `name_key` and `i18n` translations (ADR-0039: own texts in `title` / `description`,
   language `locale`, the other languages in `{"es": {"title", "description"}, "id": {...}}`, never the own language);
   an academy's exercise has its owner and neither key nor translations (checks). RLS is the one of `training_plan`
   and `physical_test_type`: enabled, forced, one policy per command (select: global or own; insert / update / delete:
   own only), so global exercises are immutable for the app role. The table is declared in
   `AthleteRlsSchemaMetaTest.nullableTenantTables()` and proved by `ExerciseRlsIsolationTest`; the generic suite skips
   nullable-owner tables by design. A global exercise is never archived (check).
2. **Content and lifecycle.** An exercise has the content of a plan item (title 1–120, description, duration 1–480,
   sets 1–100, repetitions 1–1000, video URL; the limits are shared code). Whoever manages plans (ADMIN, COACH,
   ASSISTANT_COACH, any team) creates, edits and archives the academy's exercises; every member with a role reads the
   catalogue; global ones are read-only (403 `EXERCISE_IS_GLOBAL`); another academy's exercise is 404. Exercises are
   archived, never deleted: an archived one leaves the list (`includeArchived` brings it back), stays readable by id
   and cannot be added (422 `EXERCISE_ARCHIVED`), so every item keeps a readable source.
3. **Items copy, then reference.** `plan_item.exercise_id` (nullable, FK) names the exercise an item came from. Adding
   an exercise to a plan or a session copies its text, in the caller's language for a global one, into a new item and
   sets the reference; every later copy (quick-add of an item, plan copy, a session's copy on write) keeps it, and
   editing the item keeps it too. Editing or archiving the exercise never changes an item, and editing an item never
   changes the exercise. The reference is set only by the service from an exercise read under RLS: a foreign-key check
   bypasses RLS, so the database alone would not stop an id of another academy (`ExerciseQuickAddApiTest` proves the
   404).
4. **Templates are curated lists of catalogue exercises.** `R__exercise_catalogue.sql` (repeatable, runs before
   `R__plan_templates.sql`) upserts the 60 global exercises: one per distinct template item (59, ids uuid5 of the name
   key, the English text, duration and es / id translations of the item) plus `cooper-test`. `R__plan_templates.sql`
   now inserts each template item from its exercise (same item ids, the exercise's texts, the template's own
   duration) with `exercise_id` set; the catalogue seed ends by refreshing template item texts from their exercises,
   so either seed can change alone. Global exercises are only ever upserted, never deleted.
5. **The migration leaves tenant rows alone.** V10 adds the table and the nullable column (FK added `NOT VALID`, as in
   V7: validation would scan `plan_item` under forced RLS without a tenant; the column is null everywhere). Items an
   academy wrote, including copies of template items made before 3.0.0, keep their text and get no reference: no
   backfill by title, because a matching title is not proof of origin and the decision says nothing a coach wrote
   changes. `ExerciseCatalogueMigrationTest` migrates a V9 database (with the template seed of that time) holding an
   academy's plan, items, a session with its own plan and a session on a template, then migrates to the current
   version and compares every academy row.
6. **Search.** `GET /exercises?q=` matches the shown title (global ones in the negotiated language), case-insensitive,
   with `scope` (`GLOBAL`, `TENANT`, absent = both), `includeArchived` and paging, ordered by shown title then id. The
   2.3.0 plan search is **kept**: `q` on `listTrainingPlans` still finds plans by an item title and lists the matches,
   which now carry `exerciseId`. It is the only way to find items an academy wrote by hand (not in the catalogue) and to
   see which plan contains an exercise; the catalogue search replaces it as the main quick-add source in the web.

## Breaking points (athlete 3.0.0)
- `PlanItemRef` is replaced by `PlanItemSource` in `CopyPlanItemsRequest.items` (`copyItemsToPlan`,
  `copyItemsToSession`): `planId` and `itemId` are no longer required, `exerciseId` is new, and an entry must name
  exactly one source (`exerciseId`, or `planId` + `itemId`), else 400. Generated clients lose the `PlanItemRef` class
  and get `PlanItemSource` with optional fields. A 2.x request body (`{planId, itemId}` entries) stays valid on the wire.
- `copyItemsToPlan` and `copyItemsToSession` may answer 422 `EXERCISE_ARCHIVED` (new status for both operations).
- Responses gain fields: `PlanItem.exerciseId` (set on every template item and on copies of them), `PlanItemMatch
  .exerciseId`; strict clients that reject unknown properties must update. Template item texts are now the catalogue's
  (identical to 2.4.0's).
- New operations under `/api/athlete/exercises` (tag `Exercises`): `listExercises`, `createExercise`, `getExercise`,
  `updateExercise` (ADR-0032 `clear` list), `archiveExercise`, `unarchiveExercise`. `Accept-Language` also localises
  global exercises.

## Consequences
- "cooper" now finds the Cooper test on a real stack (ADR-0041 noted the seeded templates had none). It is in the
  catalogue only, not in a template.
- A catalogue exercise and the items copied from it drift apart by design; a client shows the item's own text and may
  link to the exercise by `exerciseId`.
- Translations of the catalogue are seed content: adding a language is a seed change (as for templates).
- The item search remains an `EXISTS` without a trigram index (ADR-0041 §5); so is the catalogue search (60 global rows
  plus an academy's own).

## Alternatives considered
- **Two tables, a global catalogue (global table) and a tenant table through `app.enable_tenant_rls`.** The helper
  needs `tenant_id not null`, which a global row cannot have, so globals would need their own table with revoked write
  grants; `plan_item.exercise_id` would need two nullable columns (or no foreign key), and the list with one paging and
  one ordering across both scopes would be a `UNION`. The single nullable-owner table is the proven pattern of templates
  and test types, with one foreign key and one query.
- **Templates point at exercises without their own item rows** (items resolved from the catalogue at read time): every
  read path (plan detail, search, copy, completion progress) would join the catalogue, and a template could not give an
  exercise its own duration. The item rows stay, their texts copied from the catalogue by the seed.
- **Backfill references on tenant items by title**: would change rows coaches wrote and guess an origin from a text
  match; rejected by decision 72.
- **Replace the plan search by the exercise search**: hand-written items would become unfindable; kept both.
