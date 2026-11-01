-- ============================================================================
-- WP4 / V5 — roster & eligibility: season, age_category, team, team_staff, team_player, eligibility_case
-- (plan §2 "Roster & eligibility", ADR-0010, ADR-0014). Every table is a standard RLS tenant table.
-- ============================================================================

create table core.season (
  id             uuid primary key,
  tenant_id      uuid not null,
  name           text not null check (char_length(name) between 1 and 60),
  start_date     date not null,
  end_date       date not null,
  reference_year integer not null check (reference_year between 2000 and 2100),
  created_at     timestamptz not null default now(),
  check (end_date >= start_date),
  unique (tenant_id, id)
);
create index season_tenant_dates_idx on core.season (tenant_id, start_date);
select app.enable_tenant_rls('core.season');

-- Seasons of a tenant must not overlap. An exclusion constraint would need btree_gist for the uuid equality,
-- which core_migrator cannot install (no CREATE on the database, ADR-0014). This trigger is the database-level
-- guarantee instead: a per-tenant transaction-scoped advisory lock serialises concurrent writers, then any
-- overlapping row of the same tenant raises SQLSTATE 23P01 (exclusion_violation). It runs as the invoker, so RLS
-- limits the lookup to the bound tenant — the same scope the tenant_id predicate states explicitly.
create function core.season_no_overlap() returns trigger
language plpgsql as $$
begin
  perform pg_advisory_xact_lock(hashtextextended('core.season:' || new.tenant_id::text, 0));
  if exists (select 1 from core.season s
              where s.tenant_id = new.tenant_id and s.id <> new.id
                and daterange(s.start_date, s.end_date, '[]') && daterange(new.start_date, new.end_date, '[]')) then
    raise exception 'season % overlaps another season of the tenant', new.id
      using errcode = '23P01', constraint = 'season_no_overlap';
  end if;
  return new;
end $$;
create trigger season_no_overlap before insert or update of start_date, end_date, tenant_id on core.season
  for each row execute function core.season_no_overlap();

create table core.age_category (
  id         uuid primary key,
  tenant_id  uuid not null,
  code       text not null check (code ~ '^[A-Z0-9_]{1,16}$'),
  name       text not null check (char_length(name) between 1 and 60),
  max_age    integer check (max_age between 3 and 99),
  sort_rank  integer not null check (sort_rank >= 0),
  unique (tenant_id, code),
  unique (tenant_id, sort_rank),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('core.age_category');

create table core.team (
  id              uuid primary key,
  tenant_id       uuid not null,
  season_id       uuid not null,
  name            text not null check (char_length(name) between 1 and 80),
  alias           text check (char_length(alias) between 1 and 40),
  age_category_id uuid not null,
  gender_policy   text not null check (gender_policy in ('MALE', 'FEMALE', 'MIXED')),
  created_at      timestamptz not null default now(),
  unique (tenant_id, season_id, name),
  unique (tenant_id, id),
  foreign key (tenant_id, season_id) references core.season (tenant_id, id),
  foreign key (tenant_id, age_category_id) references core.age_category (tenant_id, id)
);
create index team_category_idx on core.team (tenant_id, age_category_id);
select app.enable_tenant_rls('core.team');

-- "Coach trains N categories" is derived from these rows (single source of truth for staffTeamIds).
create table core.team_staff (
  tenant_id uuid not null,
  team_id   uuid not null,
  person_id uuid not null,
  role      text not null check (role in ('COACH', 'ASSISTANT_COACH')),
  since     date not null,
  primary key (team_id, person_id),
  foreign key (tenant_id, team_id) references core.team (tenant_id, id),
  foreign key (tenant_id, person_id) references core.person (tenant_id, id)
);
create index team_staff_person_idx on core.team_staff (tenant_id, person_id);
select app.enable_tenant_rls('core.team_staff');

-- A player may be on several teams. Open = left_on is null; valid = open and not invalidated. The evaluator never
-- deletes: it sets invalidated_at + invalid_reason and opens an eligibility_case.
create table core.team_player (
  id             uuid primary key,
  tenant_id      uuid not null,
  team_id        uuid not null,
  player_id      uuid not null,
  jersey_number  text check (jersey_number ~ '^[0-9]{1,2}$'),
  joined_on      date not null,
  left_on        date,
  play_up_levels integer not null default 0 check (play_up_levels >= 0),
  invalidated_at timestamptz,
  invalid_reason text check (invalid_reason in ('CATEGORY_TOO_LOW', 'PLAY_UP_LIMIT_EXCEEDED', 'GENDER_POLICY',
                                                'MISSING_BIRTH_DATE', 'MISSING_GENDER', 'PLAYER_NOT_ACTIVE')),
  check ((invalidated_at is null) = (invalid_reason is null)),
  check (left_on is null or left_on >= joined_on),
  unique (tenant_id, id),
  foreign key (tenant_id, team_id) references core.team (tenant_id, id),
  foreign key (tenant_id, player_id) references core.player (tenant_id, id)
);
create unique index team_player_open_uq on core.team_player (team_id, player_id) where left_on is null;
create unique index team_player_jersey_uq on core.team_player (team_id, jersey_number)
  where left_on is null and jersey_number is not null;
create index team_player_player_open_idx on core.team_player (tenant_id, player_id) where left_on is null;
select app.enable_tenant_rls('core.team_player');

create table core.eligibility_case (
  id                    uuid primary key,
  tenant_id             uuid not null,
  player_id             uuid not null,
  team_player_id        uuid not null,
  reason                text not null check (reason in ('CATEGORY_TOO_LOW', 'PLAY_UP_LIMIT_EXCEEDED', 'GENDER_POLICY',
                                                        'MISSING_BIRTH_DATE', 'MISSING_GENDER', 'PLAYER_NOT_ACTIVE')),
  status                text not null default 'OPEN' check (status in ('OPEN', 'RESOLVED')),
  resolution            text check (resolution in ('REASSIGNED', 'REMOVED_FROM_TEAM', 'DISMISSED')),
  resolution_note       text check (char_length(resolution_note) <= 500),
  resolved_by_person_id uuid,
  created_at            timestamptz not null default now(),
  resolved_at           timestamptz,
  check ((status = 'RESOLVED') = (resolution is not null and resolved_at is not null)),
  foreign key (tenant_id, player_id) references core.player (tenant_id, id),
  foreign key (tenant_id, team_player_id) references core.team_player (tenant_id, id),
  foreign key (tenant_id, resolved_by_person_id) references core.person (tenant_id, id)
);
-- one OPEN case per invalidated assignment (the nightly job is idempotent)
create unique index eligibility_case_open_uq on core.eligibility_case (team_player_id) where status = 'OPEN';
create index eligibility_case_status_idx on core.eligibility_case (tenant_id, status, created_at);
select app.enable_tenant_rls('core.eligibility_case');
