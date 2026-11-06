-- athlete-service V6: local replica of core's roster, fed by core's events (WP69, decision 48, ADR-0036/0037).
-- Read by the replica RosterPort adapter and the replica tenant-filter resolver when hoops.roster.source=replica.
-- Every *_ref row is the latest state of one core aggregate (state transfer), keyed (tenant_id, id) like the topic key
-- `<tenant>:<aggregate>`; occurred_at / event_id are those of the event the row came from, so an older event never
-- overwrites a newer one. No foreign keys and no enum checks: rows arrive in any order across topics and every event is
-- validated against libs/contracts/events before it is applied. Every table but parked_event is a tenant table.

create table athlete.tenant_ref (
  tenant_id    uuid primary key,
  status       text not null,                    -- ACTIVE | SUSPENDED | WITHDRAWN
  timezone     text not null,                    -- IANA zone id
  occurred_at  timestamptz not null,
  event_id     uuid not null,
  updated_at   timestamptz not null default now()
);
select app.enable_tenant_rls('athlete.tenant_ref');

create table athlete.person_ref (
  tenant_id     uuid not null,
  id            uuid not null,
  display_name  text not null,
  subject       text,                            -- Keycloak sub of the linked login, null without a login
  roles         text[] not null,                 -- tenant roles (ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER)
  active        boolean not null,
  occurred_at   timestamptz not null,
  event_id      uuid not null,
  updated_at    timestamptz not null default now(),
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('athlete.person_ref');
create index person_ref_subject_idx on athlete.person_ref (tenant_id, subject) where active;

create table athlete.player_ref (
  tenant_id     uuid not null,
  id            uuid not null,
  person_id     uuid not null,
  display_name  text not null,
  status        text not null,                   -- PENDING_APPROVAL | ACTIVE | ORPHAN | WITHDRAWN | REJECTED
  birth_date    date,
  gender        text,                            -- MALE | FEMALE
  occurred_at   timestamptz not null,
  event_id      uuid not null,
  updated_at    timestamptz not null default now(),
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('athlete.player_ref');
create index player_ref_person_idx on athlete.player_ref (tenant_id, person_id);

create table athlete.team_ref (
  tenant_id        uuid not null,
  id               uuid not null,
  season_id        uuid not null,
  season_end_date  date not null,
  name             text not null,
  occurred_at      timestamptz not null,
  event_id         uuid not null,
  updated_at       timestamptz not null default now(),
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('athlete.team_ref');

-- A team assignment (core.team_player): open while left_on is null, valid while invalid_reason is null.
create table athlete.team_player_ref (
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
  updated_at      timestamptz not null default now(),
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('athlete.team_player_ref');
create index team_player_ref_team_idx on athlete.team_player_ref (tenant_id, team_id)
  where left_on is null and invalid_reason is null;
create index team_player_ref_player_idx on athlete.team_player_ref (tenant_id, player_id) where left_on is null;

-- team-staff and guardian-link are the two aggregates core removes: a removal keeps the row with removed = true (and
-- its occurred_at), so a late older `.changed` cannot bring it back.
create table athlete.team_staff_ref (
  tenant_id    uuid not null,
  id           uuid not null,                    -- UUID v3 of team-staff:<teamId>:<personId> (core)
  team_id      uuid not null,
  person_id    uuid not null,
  role         text,                             -- COACH | ASSISTANT_COACH; null on a removal without a known row
  since        date,
  removed      boolean not null,
  occurred_at  timestamptz not null,
  event_id     uuid not null,
  updated_at   timestamptz not null default now(),
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('athlete.team_staff_ref');
create index team_staff_ref_team_idx on athlete.team_staff_ref (tenant_id, team_id) where not removed;
create index team_staff_ref_person_idx on athlete.team_staff_ref (tenant_id, person_id) where not removed;

create table athlete.guardian_link_ref (
  tenant_id           uuid not null,
  id                  uuid not null,
  guardian_person_id  uuid not null,
  player_id           uuid not null,
  removed             boolean not null,
  occurred_at         timestamptz not null,
  event_id            uuid not null,
  updated_at          timestamptz not null default now(),
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('athlete.guardian_link_ref');
create index guardian_link_ref_guardian_idx on athlete.guardian_link_ref (tenant_id, guardian_person_id)
  where not removed;

-- Idempotency: every event applied (or found stale) once; a redelivered eventId is ignored. Inserted in the same
-- transaction as the row it changed.
create table athlete.applied_event (
  tenant_id     uuid not null,
  event_id      uuid not null,
  topic         text not null,
  aggregate_id  uuid not null,
  occurred_at   timestamptz not null,
  applied_at    timestamptz not null default now(),
  primary key (tenant_id, event_id)
);
select app.enable_tenant_rls('athlete.applied_event');

-- Global (no RLS): records the consumer could not apply because they violate the contract (schema, envelope, key).
-- Only the record's coordinates and the validation messages, never its value; the record itself stays in the
-- compacted topic (`rpk topic consume <topic> -o <offset> -n 1`) until a newer event of its key replaces it. A broken
-- record may name no tenant, so the table has none: the app role may only insert (a replay parks the same offset
-- again, which is a no-op), operators read it as athlete_migrator.
create table athlete.parked_event (
  topic         text not null,
  partition     integer not null,
  kafka_offset  bigint not null,
  record_key    text,
  event_id      uuid,
  reason        text not null,
  parked_at     timestamptz not null default now(),
  primary key (topic, partition, kafka_offset)
);
revoke select, update, delete, truncate, references, trigger on athlete.parked_event from athlete_app;
