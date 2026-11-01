-- athlete-service V3: injuries, body measurements, physical test types / results / norms (WP10).
--
-- injury, body_measurement and physical_test_result are ordinary tenant tables (app.enable_tenant_rls).
-- physical_test_type and physical_test_norm also hold GLOBAL rows (owner_tenant_id is null, seeded by
-- R__physical_test_norms.sql) next to tenant-defined types and tenant norm overrides. As for training_plan (V2) the
-- owner column is deliberately NOT called tenant_id and is nullable, the table is declared a special table in
-- AthleteRlsSchemaMetaTest and has one policy per command (a FOR ALL policy would let tenants DELETE global rows):
--   read  : global rows + the caller's own tenant
--   write : own tenant only, so global rows are immutable for the app role.

create table athlete.injury (
  id                      uuid primary key,
  tenant_id               uuid not null,
  player_id               uuid not null,
  occurred_on             date not null,
  body_part               text not null check (length(body_part) between 1 and 80),
  description             text check (length(description) <= 2000),
  severity                text not null check (severity in ('MINOR', 'MODERATE', 'SEVERE')),
  expected_return_on      date,
  actual_return_on        date,
  status                  text not null default 'OPEN' check (status in ('OPEN', 'RECOVERED')),
  reported_by_person_id   uuid not null,
  reported_by_name        text not null,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  version                 bigint not null default 0,
  check (expected_return_on is null or expected_return_on >= occurred_on),
  check (actual_return_on is null or actual_return_on >= occurred_on),
  check (status <> 'RECOVERED' or actual_return_on is not null),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('athlete.injury');
create index injury_player_idx on athlete.injury (tenant_id, player_id, occurred_on desc);
create index injury_open_idx on athlete.injury (tenant_id, player_id) where status = 'OPEN';

create table athlete.body_measurement (
  id                     uuid primary key,
  tenant_id              uuid not null,
  player_id              uuid not null,
  measured_on            date not null,
  height_cm              numeric(5,1) check (height_cm between 50 and 250),
  weight_kg              numeric(5,2) check (weight_kg between 10 and 250),
  recorded_by_person_id  uuid not null,
  recorded_by_name       text not null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (height_cm is not null or weight_kg is not null),
  unique (tenant_id, player_id, measured_on),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('athlete.body_measurement');

create table athlete.physical_test_type (
  id                uuid primary key,
  owner_tenant_id   uuid,                                              -- null = global (platform) type
  code              text not null check (code ~ '^[A-Z0-9_]{2,32}$'),
  name              text not null check (length(name) between 1 and 120),
  unit              text not null check (length(unit) between 1 and 16),
  higher_is_better  boolean not null,
  description       text check (length(description) <= 2000),
  created_at        timestamptz not null default now()
);
-- code is unique within the global layer and within each tenant; uniqueness ACROSS layers is checked by the use case
-- (a database constraint would reveal other tenants' codes).
create unique index physical_test_type_global_code_idx on athlete.physical_test_type (code) where owner_tenant_id is null;
create unique index physical_test_type_tenant_code_idx on athlete.physical_test_type (owner_tenant_id, code) where owner_tenant_id is not null;
alter table athlete.physical_test_type enable row level security;
alter table athlete.physical_test_type force row level security;
create policy test_type_select on athlete.physical_test_type for select
  using (owner_tenant_id is null or owner_tenant_id = app.current_tenant());
create policy test_type_insert on athlete.physical_test_type for insert with check (owner_tenant_id = app.current_tenant());
create policy test_type_update on athlete.physical_test_type for update
  using (owner_tenant_id = app.current_tenant()) with check (owner_tenant_id = app.current_tenant());
create policy test_type_delete on athlete.physical_test_type for delete using (owner_tenant_id = app.current_tenant());

-- test_type_id is not tenant-scoped (types may be global); the use cases only resolve types visible under RLS.
create table athlete.physical_test_result (
  id                     uuid primary key,
  tenant_id              uuid not null,
  player_id              uuid not null,
  test_type_id           uuid not null references athlete.physical_test_type (id),
  measured_on            date not null,
  value                  numeric(12,3) not null check (value >= 0),
  notes                  text check (length(notes) <= 1000),
  recorded_by_person_id  uuid not null,
  recorded_by_name       text not null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('athlete.physical_test_result');
create index physical_test_result_player_idx on athlete.physical_test_result (tenant_id, player_id, measured_on desc);
create index physical_test_result_type_idx on athlete.physical_test_result (tenant_id, test_type_id);

create table athlete.physical_test_norm (
  id                 uuid primary key,
  owner_tenant_id    uuid,                                              -- null = global reference table
  test_type_id       uuid not null references athlete.physical_test_type (id) on delete cascade,
  gender             text not null check (gender in ('MALE', 'FEMALE')),
  min_age            smallint not null check (min_age between 3 and 99),
  max_age            smallint not null check (max_age between 3 and 99),   -- inclusive
  band               text not null check (band in ('POOR', 'BELOW_AVERAGE', 'AVERAGE', 'ABOVE_AVERAGE', 'EXCELLENT')),
  min_value          numeric(12,3),                                     -- inclusive, null = open
  max_value          numeric(12,3),                                     -- exclusive, null = open
  reference_pending  boolean not null,
  source             text check (length(source) <= 500),
  created_at         timestamptz not null default now(),
  check (min_age <= max_age),
  check (min_value is null or max_value is null or min_value < max_value),
  -- a norm without a citation must be flagged: only reference_pending rows may lack a source
  check (reference_pending or length(trim(coalesce(source, ''))) > 0)
);
alter table athlete.physical_test_norm enable row level security;
alter table athlete.physical_test_norm force row level security;
create policy test_norm_select on athlete.physical_test_norm for select
  using (owner_tenant_id is null or owner_tenant_id = app.current_tenant());
create policy test_norm_insert on athlete.physical_test_norm for insert with check (owner_tenant_id = app.current_tenant());
create policy test_norm_update on athlete.physical_test_norm for update
  using (owner_tenant_id = app.current_tenant()) with check (owner_tenant_id = app.current_tenant());
create policy test_norm_delete on athlete.physical_test_norm for delete using (owner_tenant_id = app.current_tenant());
create index physical_test_norm_lookup_idx on athlete.physical_test_norm (test_type_id, gender, owner_tenant_id);
