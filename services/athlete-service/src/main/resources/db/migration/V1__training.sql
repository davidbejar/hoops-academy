-- athlete-service V1: training schedules, sessions, planned absences, attendance (WP8).
-- Every tenant table is protected by RLS via app.enable_tenant_rls (ADR-0006). Child tables use tenant-scoped
-- composite foreign keys so a row can never point at another tenant's parent.

-- Global (no RLS, no tenant_id column on purpose): the tenants this service has seen, with their time zone.
-- Lets the nightly job iterate tenants without a platform datasource. Holds no tenant content.
create table athlete.tenant_registry (
  id          uuid primary key,
  timezone    text not null,
  updated_at  timestamptz not null default now()
);

create table athlete.training_schedule (
  id            uuid primary key,
  tenant_id     uuid not null,
  team_id       uuid not null,
  weekday       smallint not null check (weekday between 1 and 7),   -- ISO: 1 = Monday
  start_time    time not null,                                       -- wall clock in the tenant time zone
  duration_min  integer not null check (duration_min between 15 and 480),
  location      text,
  valid_from    date not null,
  valid_to      date,                                                -- inclusive, null = open-ended
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  check (valid_to is null or valid_to >= valid_from),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('athlete.training_schedule');
create index training_schedule_team_idx on athlete.training_schedule (tenant_id, team_id) where active;

create table athlete.training_session (
  id             uuid primary key,
  tenant_id      uuid not null,
  team_id        uuid not null,
  schedule_id    uuid,
  starts_at      timestamptz not null,
  ends_at        timestamptz not null,
  location       text,
  plan_id        uuid,                                               -- plans arrive with WP9
  status         text not null default 'PLANNED' check (status in ('PLANNED', 'DONE', 'CANCELLED')),
  notes          text,
  cancel_reason  text,
  manually_edited boolean not null default false,                    -- set when staff patched a materialised session
  created_at     timestamptz not null default now(),
  check (ends_at > starts_at),
  unique (tenant_id, id),
  foreign key (tenant_id, schedule_id) references athlete.training_schedule (tenant_id, id)
);
select app.enable_tenant_rls('athlete.training_session');
-- Idempotent materialisation: a (schedule, start) pair exists at most once, cancelled rows included.
create unique index training_session_schedule_start_uq
  on athlete.training_session (schedule_id, starts_at) where schedule_id is not null;
create index training_session_team_start_idx on athlete.training_session (tenant_id, team_id, starts_at);

create table athlete.planned_absence (
  id                       uuid primary key,
  tenant_id                uuid not null,
  player_id                uuid not null,
  from_date                date not null,
  to_date                  date not null,
  reason                   text,
  created_by_person_id     uuid not null,
  created_by_name          text not null,
  created_at               timestamptz not null default now(),
  check (to_date >= from_date),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('athlete.planned_absence');
create index planned_absence_player_idx on athlete.planned_absence (tenant_id, player_id, from_date, to_date);

create table athlete.attendance (
  tenant_id              uuid not null,
  session_id             uuid not null,
  player_id              uuid not null,
  status                 text not null check (status in ('PRESENT', 'LATE', 'ABSENT', 'EXCUSED')),
  minutes_late           integer check (minutes_late between 1 and 480),
  note                   text,
  recorded_by_person_id  uuid not null,
  recorded_by_name       text not null,
  recorded_at            timestamptz not null default now(),
  primary key (session_id, player_id),
  check ((status = 'LATE') = (minutes_late is not null)),
  foreign key (tenant_id, session_id) references athlete.training_session (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('athlete.attendance');
