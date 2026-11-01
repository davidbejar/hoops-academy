-- athlete-service V2: training plans, items, assignments, completions (WP9).
--
-- training_plan / plan_item also hold GLOBAL TEMPLATES (owner_tenant_id is null, seeded by R__plan_templates.sql).
-- The owner column is deliberately NOT called tenant_id and is nullable: the generic RLS suites assume
-- "tenant_id => uuid not null + standard policy". These two tables use a custom policy instead (declared as
-- special tables in AthleteRlsSchemaMetaTest, proved by TemplateRlsIsolationTest):
--   read  : templates + the caller's own tenant
--   write : own tenant only (separate insert/update/delete policies), so templates are immutable for the app role.
-- plan_assignment and plan_completion are ordinary tenant tables (app.enable_tenant_rls).

create table athlete.training_plan (
  id                 uuid primary key,
  owner_tenant_id    uuid,                                              -- null = global template
  name               text not null check (length(name) between 1 and 120),
  description        text,
  author_person_id   uuid,
  author_name        text,
  is_template        boolean not null default false,
  locale             text not null default 'en',
  archived           boolean not null default false,
  source_plan_id     uuid,                                              -- template/plan this one was copied from
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  version            bigint not null default 0,
  check (is_template = (owner_tenant_id is null)),
  unique (id, owner_tenant_id)
);
alter table athlete.training_plan enable row level security;
alter table athlete.training_plan force row level security;
-- One policy per command: DELETE only evaluates USING, so a single FOR ALL policy would let tenants delete templates.
create policy plan_select on athlete.training_plan for select
  using (owner_tenant_id is null or owner_tenant_id = app.current_tenant());
create policy plan_insert on athlete.training_plan for insert with check (owner_tenant_id = app.current_tenant());
create policy plan_update on athlete.training_plan for update
  using (owner_tenant_id = app.current_tenant()) with check (owner_tenant_id = app.current_tenant());
create policy plan_delete on athlete.training_plan for delete using (owner_tenant_id = app.current_tenant());
create index training_plan_owner_idx on athlete.training_plan (owner_tenant_id, archived, name);

create table athlete.plan_item (
  id               uuid primary key,
  plan_id          uuid not null,
  owner_tenant_id  uuid,                                                -- mirrors the plan
  position         integer not null check (position >= 0),
  title            text not null check (length(title) between 1 and 120),
  description      text,
  duration_min     integer check (duration_min between 1 and 480),
  sets             integer check (sets between 1 and 100),
  repetitions      integer check (repetitions between 1 and 1000),
  video_url        text,
  -- an item always belongs to a plan of the same owner (also blocks pointing at another tenant's plan)
  foreign key (plan_id, owner_tenant_id) references athlete.training_plan (id, owner_tenant_id) on delete cascade
);
alter table athlete.plan_item enable row level security;
alter table athlete.plan_item force row level security;
create policy plan_item_select on athlete.plan_item for select
  using (owner_tenant_id is null or owner_tenant_id = app.current_tenant());
create policy plan_item_insert on athlete.plan_item for insert with check (owner_tenant_id = app.current_tenant());
create policy plan_item_update on athlete.plan_item for update
  using (owner_tenant_id = app.current_tenant()) with check (owner_tenant_id = app.current_tenant());
create policy plan_item_delete on athlete.plan_item for delete using (owner_tenant_id = app.current_tenant());
create index plan_item_plan_idx on athlete.plan_item (plan_id, position);

create table athlete.plan_assignment (
  id                      uuid primary key,
  tenant_id               uuid not null,
  plan_id                 uuid not null,
  team_id                 uuid,
  player_id               uuid,
  due_on                  date not null,
  notes                   text,
  assigned_by_person_id   uuid not null,
  assigned_by_name        text not null,
  created_at              timestamptz not null default now(),
  check ((team_id is null) <> (player_id is null)),                     -- exactly one target
  unique (tenant_id, id),
  foreign key (plan_id, tenant_id) references athlete.training_plan (id, owner_tenant_id)
);
select app.enable_tenant_rls('athlete.plan_assignment');
create index plan_assignment_plan_idx on athlete.plan_assignment (tenant_id, plan_id);
create index plan_assignment_team_idx on athlete.plan_assignment (tenant_id, team_id, due_on) where team_id is not null;
create index plan_assignment_player_idx on athlete.plan_assignment (tenant_id, player_id, due_on) where player_id is not null;

create table athlete.plan_completion (
  id                    uuid not null unique,
  tenant_id             uuid not null,
  assignment_id         uuid not null,
  player_id             uuid not null,
  status                text not null check (status in ('DONE', 'PARTIAL', 'NOT_DONE')),
  note                  text,
  marked_at             timestamptz not null default now(),
  marked_by_person_id   uuid not null,
  marked_by_name        text not null,
  primary key (assignment_id, player_id),
  foreign key (tenant_id, assignment_id) references athlete.plan_assignment (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('athlete.plan_completion');

-- Sessions may point at a plan; NOT VALID because V1 never checked existing values. Deleting a plan detaches it.
alter table athlete.training_session
  add constraint training_session_plan_fk foreign key (plan_id) references athlete.training_plan (id)
  on delete set null not valid;
