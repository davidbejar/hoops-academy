-- finance-service V10 (WP119, ADR-0037 rules, ADR-0056): the rest of core's roster the dues need, from the topics
-- core.player, core.team, core.team-player, core.team-staff and core.guardian-link. Runs as finance_migrator.
-- Same rules as V5: tenant tables keyed by (tenant_id, id), each row with the occurred_at and event_id that wrote it (an
-- older event never overwrites a newer one), soft removals that keep no state (every state column null), no foreign
-- keys between the replica tables (the topics are independent: an assignment may arrive before its player).
-- Data minimisation (P-10): a player keeps its person, display name (for the lists) and status, never a birth date or
-- a gender; a team its season's dates and age category, not its name; an assignment its dates and whether it is
-- valid; a staff entry its team, person and role; a guardian link its two ends.

create table finance.player_ref (
  tenant_id     uuid not null,
  id            uuid not null,
  person_id     uuid,
  display_name  text,
  status        text,                     -- PENDING_APPROVAL | ACTIVE | ORPHAN | WITHDRAWN | REJECTED
  removed       boolean not null default false,
  occurred_at   timestamptz not null,
  event_id      uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.player_ref');
create index player_ref_person_idx on finance.player_ref (tenant_id, person_id) where not removed;

create table finance.team_ref (
  tenant_id        uuid not null,
  id               uuid not null,
  season_id        uuid,
  season_start     date,
  season_end       date,
  age_category_id  uuid,
  removed          boolean not null default false,
  occurred_at      timestamptz not null,
  event_id         uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.team_ref');
create index team_ref_season_idx on finance.team_ref (tenant_id, season_id, age_category_id) where not removed;

create table finance.team_player_ref (
  tenant_id       uuid not null,
  id              uuid not null,
  team_id         uuid,
  player_id       uuid,
  joined_on       date,
  left_on         date,                   -- the last day on the team; null while open
  invalid_reason  text,                   -- an eligibility rule invalidated it; null when valid
  removed         boolean not null default false,
  occurred_at     timestamptz not null,
  event_id        uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.team_player_ref');
create index team_player_ref_team_idx on finance.team_player_ref (tenant_id, team_id) where not removed;

create table finance.team_staff_ref (
  tenant_id    uuid not null,
  id           uuid not null,             -- core's derived id (name-based UUID of team and person)
  team_id      uuid,
  person_id    uuid,
  role         text,                      -- COACH | ASSISTANT_COACH
  removed      boolean not null default false,
  occurred_at  timestamptz not null,
  event_id     uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.team_staff_ref');
create index team_staff_ref_person_idx on finance.team_staff_ref (tenant_id, person_id) where not removed;

create table finance.guardian_link_ref (
  tenant_id           uuid not null,
  id                  uuid not null,
  guardian_person_id  uuid,
  player_id           uuid,
  removed             boolean not null default false,
  occurred_at         timestamptz not null,
  event_id            uuid not null,
  primary key (tenant_id, id)
);
select app.enable_tenant_rls('finance.guardian_link_ref');
create index guardian_link_ref_guardian_idx on finance.guardian_link_ref (tenant_id, guardian_person_id)
  where not removed;
