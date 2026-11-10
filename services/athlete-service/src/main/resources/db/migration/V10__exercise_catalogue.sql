-- athlete-service V10: the exercise catalogue (WP92, decision 72, ADR-0047).
--
-- athlete.exercise holds the GLOBAL exercises (owner_tenant_id is null, seeded by R__exercise_catalogue.sql) next to
-- the exercises an academy defines. It follows the pattern of training_plan (V2) and physical_test_type (V3) exactly:
-- the owner column is NOT called tenant_id and is nullable, so app.enable_tenant_rls cannot be used; instead one
-- policy per command (a FOR ALL policy would let tenants DELETE global rows):
--   read  : global rows + the caller's own tenant
--   write : own tenant only, so global exercises are immutable for the app role.
-- Declared in AthleteRlsSchemaMetaTest.nullableTenantTables(), proved by ExerciseRlsIsolationTest. As for templates
-- (V4, ADR-0039), a global exercise keeps its own texts in title / description (language: locale) and the other
-- languages in i18n {"es": {"title": ..., "description": ...}, "id": {...}}, plus a stable name_key; the checks keep
-- both off the academies' rows.
--
-- plan_item.exercise_id: the exercise an item was copied from. Every item of a global template references one
-- (R__plan_templates.sql); the items academies wrote before this migration keep their text and get null: nothing an
-- academy wrote changes. The service sets it only from an exercise it read under RLS (a global one or the academy's
-- own); a foreign key check bypasses RLS, so the database alone would not stop a reference to another academy's id.

create table athlete.exercise (
  id                 uuid primary key,
  owner_tenant_id    uuid,                                              -- null = global exercise
  name_key           text,
  title              text not null check (length(title) between 1 and 120),
  description        text check (length(description) <= 4000),
  duration_min       integer check (duration_min between 1 and 480),
  sets               integer check (sets between 1 and 100),
  repetitions        integer check (repetitions between 1 and 1000),
  video_url          text check (length(video_url) <= 2000),
  locale             text not null default 'en',
  i18n               jsonb,
  archived           boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  version            bigint not null default 0,
  constraint exercise_texts_global_only check ((name_key is null and i18n is null) or owner_tenant_id is null),
  constraint exercise_global_has_key check (owner_tenant_id is not null or name_key is not null),
  constraint exercise_global_never_archived check (owner_tenant_id is not null or not archived),
  constraint exercise_i18n_object check (i18n is null or jsonb_typeof(i18n) = 'object'),
  -- the own language lives in title / description only, so "translation, else en, else own" is a plain coalesce
  constraint exercise_i18n_not_own_language check (i18n is null or (i18n -> locale) is null)
);
alter table athlete.exercise enable row level security;
alter table athlete.exercise force row level security;
create policy exercise_select on athlete.exercise for select
  using (owner_tenant_id is null or owner_tenant_id = app.current_tenant());
create policy exercise_insert on athlete.exercise for insert with check (owner_tenant_id = app.current_tenant());
create policy exercise_update on athlete.exercise for update
  using (owner_tenant_id = app.current_tenant()) with check (owner_tenant_id = app.current_tenant());
create policy exercise_delete on athlete.exercise for delete using (owner_tenant_id = app.current_tenant());
create unique index exercise_name_key_uq on athlete.exercise (name_key) where name_key is not null;
create index exercise_owner_idx on athlete.exercise (owner_tenant_id, archived);

alter table athlete.plan_item
  add column exercise_id uuid,
  -- NOT VALID: validating would scan plan_item under its forced RLS without a tenant (as in V7); the new column is null
  -- in every existing row, and new or changed rows are checked as usual. Exercises are archived, never deleted.
  add constraint plan_item_exercise_fk foreign key (exercise_id) references athlete.exercise (id) not valid;
create index plan_item_exercise_idx on athlete.plan_item (exercise_id) where exercise_id is not null;
