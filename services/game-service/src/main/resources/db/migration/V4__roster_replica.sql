-- game-service WP68 (ADR-0037): local replica of core's roster, fed by the core.* events (WP67 contracts), read by
-- RosterPort and the authorisation context when hoops.roster.source=replica. Runs as game_migrator.
-- Every replica table is a tenant table with primary key (tenant_id, id), so upserts never meet another tenant's row.
-- Each row keeps the occurred_at and event_id of the event that wrote it: an older event never overwrites a newer one.
-- No foreign keys between the tables: the topics are independent, reads join and skip what has not arrived yet.
-- Values are stored as text: the contracts (JSON Schema, validated before apply) carry the limits.

create table game.tenant_ref (
  tenant_id    uuid primary key,
  status       text not null,          -- ACTIVE | SUSPENDED | WITHDRAWN
  timezone     text not null,          -- IANA zone of the academy
  occurred_at  timestamptz not null,
  event_id     uuid not null
);
select app.enable_tenant_rls('game.tenant_ref');

create table game.person_ref (
  tenant_id     uuid not null,
  id            uuid not null,
  display_name  text not null,
  subject       text,                  -- Keycloak sub of the login, null while the member has none
  roles         text[] not null,
  active        boolean not null,
  occurred_at   timestamptz not null,
  event_id      uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('game.person_ref');
create index person_ref_subject_idx on game.person_ref (tenant_id, subject) where active;

create table game.player_ref (
  tenant_id     uuid not null,
  id            uuid not null,
  person_id     uuid not null,
  display_name  text not null,
  status        text not null,
  birth_date    date,
  gender        text,
  occurred_at   timestamptz not null,
  event_id      uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('game.player_ref');
create index player_ref_person_idx on game.player_ref (tenant_id, person_id);

create table game.team_ref (
  tenant_id        uuid not null,
  id               uuid not null,
  season_id        uuid not null,
  season_end_date  date not null,
  name             text not null,
  occurred_at      timestamptz not null,
  event_id         uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('game.team_ref');

-- Open = left_on is null; valid = open and invalid_reason is null (core.team_player).
create table game.team_player_ref (
  tenant_id       uuid not null,
  id              uuid not null,
  team_id         uuid not null,
  player_id       uuid not null,
  jersey_number   text,
  joined_on       date not null,
  left_on         date,
  invalid_reason  text,
  occurred_at     timestamptz not null,
  event_id        uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('game.team_player_ref');
create index team_player_ref_team_idx on game.team_player_ref (tenant_id, team_id)
  where left_on is null and invalid_reason is null;
create index team_player_ref_player_idx on game.team_player_ref (tenant_id, player_id)
  where left_on is null and invalid_reason is null;

-- Removals are soft (removed = true): a late older .changed cannot bring the entry back. role is null when removed.
create table game.team_staff_ref (
  tenant_id    uuid not null,
  id           uuid not null,          -- UUID v3 of team-staff:<teamId>:<personId> (the contract's aggregate id)
  team_id      uuid not null,
  person_id    uuid not null,
  role         text,
  removed      boolean not null,
  occurred_at  timestamptz not null,
  event_id     uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('game.team_staff_ref');
create index team_staff_ref_person_idx on game.team_staff_ref (tenant_id, person_id) where not removed;

create table game.guardian_link_ref (
  tenant_id           uuid not null,
  id                  uuid not null,
  guardian_person_id  uuid not null,
  player_id           uuid not null,
  removed             boolean not null,
  occurred_at         timestamptz not null,
  event_id            uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('game.guardian_link_ref');
create index guardian_link_ref_guardian_idx on game.guardian_link_ref (tenant_id, guardian_person_id) where not removed;

-- Idempotency: one row per applied event id; a redelivered event finds its id and changes nothing.
create table game.applied_event (
  tenant_id   uuid not null,
  event_id    uuid not null,
  topic       text not null,
  applied_at  timestamptz not null default now(),
  primary key (tenant_id, event_id)
);
select app.enable_tenant_rls('game.applied_event');

-- Records that failed validation (schema, key). Global: a broken record may name no tenant. game_app may only insert
-- (no select, update or delete), so no tenant can read what another tenant's record said; operators read it as the
-- owner. The record value is not kept (it is in the topic at that offset).
create table game.parked_event (
  id               bigint generated always as identity primary key,
  topic            text not null,
  kafka_partition  integer not null,
  kafka_offset     bigint not null,
  record_key       text,
  event_id         uuid,
  reason           text not null,
  parked_at        timestamptz not null default now()
);
revoke select, update, delete, truncate, references, trigger on game.parked_event from game_app;
