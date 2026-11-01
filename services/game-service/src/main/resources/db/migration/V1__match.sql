-- game-service: matches, match rosters and the offline-sync receipt placeholder (filled by WP7).
-- Runs as game_migrator; every tenant table is protected by RLS via app.enable_tenant_rls.

create table game.match (
  id                    uuid primary key,
  tenant_id             uuid not null,
  team_id               uuid not null,
  season_id             uuid not null,
  opponent_name         varchar(120) not null,
  home_away             varchar(8) not null check (home_away in ('HOME', 'AWAY')),
  scheduled_at          timestamptz not null,
  venue                 varchar(200),
  status                varchar(16) not null check (status in ('SCHEDULED', 'LIVE', 'FINISHED', 'CANCELLED')),
  period_count          integer not null default 4 check (period_count between 1 and 8),
  period_minutes        integer not null default 10 check (period_minutes between 1 and 60),
  started_at            timestamptz,
  finished_at           timestamptz,
  cancelled_at          timestamptz,
  cancel_reason         varchar(500),
  created_by_person_id  uuid not null,
  version               bigint not null default 0,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique (tenant_id, id)
);
select app.enable_tenant_rls('game.match');
create index match_tenant_team_scheduled_idx on game.match (tenant_id, team_id, scheduled_at desc);
create index match_tenant_season_idx on game.match (tenant_id, season_id);

create table game.match_roster (
  match_id       uuid not null,
  tenant_id      uuid not null,
  player_id      uuid not null,
  display_name   varchar(200) not null,
  jersey_number  varchar(2),
  is_starter     boolean not null,
  primary key (match_id, player_id),
  foreign key (tenant_id, match_id) references game.match (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('game.match_roster');

-- Placeholder for WP7 (offline event sync): last accepted client sequence per device and match.
create table game.sync_receipt (
  match_id         uuid not null,
  tenant_id        uuid not null,
  device_id        varchar(100) not null,
  last_client_seq  bigint not null default 0,
  updated_at       timestamptz not null default now(),
  primary key (match_id, device_id),
  foreign key (tenant_id, match_id) references game.match (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('game.sync_receipt');
