-- athlete-service V9 (WP82, ADR-0037 amendment WP82): replica housekeeping, as game's V6. Runs as athlete_migrator.

-- 1. Soft removal of every aggregate. core publishes <aggregate>.removed for persons, players, teams, team assignments
-- and tenants (WP81, empty payload): the row stays with removed = true, its occurred_at and event_id, and nothing else
-- (the state columns become null, so a removed person keeps no name or login), so a late older .changed cannot bring
-- it back. A newer .changed (the aggregate came back) sets removed = false and the whole state again. Reads leave
-- removed rows out; a removed tenant's rows stay in place, unreadable through it (every read needs an ACTIVE tenant).
alter table athlete.tenant_ref
  add column removed boolean not null default false,
  alter column status drop not null,
  alter column timezone drop not null;

alter table athlete.person_ref
  add column removed boolean not null default false,
  alter column display_name drop not null,
  alter column roles drop not null,
  alter column active drop not null;

alter table athlete.player_ref
  add column removed boolean not null default false,
  alter column person_id drop not null,
  alter column display_name drop not null,
  alter column status drop not null;

alter table athlete.team_ref
  add column removed boolean not null default false,
  alter column season_id drop not null,
  alter column season_end_date drop not null,
  alter column name drop not null;

alter table athlete.team_player_ref
  add column removed boolean not null default false,
  alter column team_id drop not null,
  alter column player_id drop not null,
  alter column joined_on drop not null;
drop index athlete.team_player_ref_team_idx;
drop index athlete.team_player_ref_player_idx;
create index team_player_ref_team_idx on athlete.team_player_ref (tenant_id, team_id)
  where left_on is null and invalid_reason is null and not removed;
create index team_player_ref_player_idx on athlete.team_player_ref (tenant_id, player_id)
  where left_on is null and not removed;

-- 2. Retention of applied_event (ReplicaRetentionJob): rows older than hoops.roster.replica.retention.applied-events
-- (never below the topics' 7-day tombstone retention) are deleted per tenant in batches.
create index applied_event_applied_at_idx on athlete.applied_event (tenant_id, applied_at);

-- The tenants the replica holds rows of, so the job can enter each one (applied_event is a tenant table: RLS shows
-- only the bound tenant). Global like tenant_registry: tenant ids only, no tenant content. Written with every applied
-- event (insert ... on conflict do nothing); athlete_app may read and insert, nothing else.
create table athlete.replica_tenant (
  id             uuid primary key,          -- the tenant id
  first_seen_at  timestamptz not null default now()
);
revoke update, delete, truncate, references, trigger on athlete.replica_tenant from athlete_app;

-- 3. Retention of parked_event: an operator marks a row inspected (as athlete_migrator: update ... set inspected_at =
-- now()); the job deletes rows inspected longer than hoops.roster.replica.retention.parked-events ago. Uninspected
-- rows stay. athlete_app may now delete, and read only the columns the job filters on and logs (never record_key,
-- event_id, reason).
alter table athlete.parked_event add column inspected_at timestamptz;
create index parked_event_inspected_at_idx on athlete.parked_event (inspected_at) where inspected_at is not null;
grant select (topic, partition, kafka_offset, parked_at, inspected_at), delete on athlete.parked_event to athlete_app;
