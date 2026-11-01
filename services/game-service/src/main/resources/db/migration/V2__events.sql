-- game-service WP7: append-only match events and their projections (box score, score, period scores).
-- Runs as game_migrator; every tenant table is protected by RLS via app.enable_tenant_rls.

create table game.match_event (
  id                        uuid primary key,              -- client-generated UUIDv7 (idempotency key)
  tenant_id                 uuid not null,
  match_id                  uuid not null,
  server_seq                bigserial not null unique,     -- arrival order; feed cursor
  device_id                 varchar(64) not null,
  client_seq                bigint not null check (client_seq >= 1),
  type                      varchar(20) not null check (type in ('PERIOD_START', 'PERIOD_END', 'SUB_IN', 'SUB_OUT',
                              'SHOT', 'ASSIST', 'REBOUND', 'TURNOVER', 'STEAL', 'BLOCK', 'FOUL', 'OPPONENT_SCORE',
                              'TIMEOUT', 'VOID', 'NOTE')),
  player_id                 uuid,
  period                    integer not null check (period between 1 and 12),
  clock_seconds_remaining   integer not null check (clock_seconds_remaining between 0 and 3600),
  payload                   jsonb not null default '{}'::jsonb,
  recorded_by_person_id     uuid not null,
  recorded_by_display_name  varchar(200) not null,
  recorded_at_client        timestamptz not null,
  received_at               timestamptz not null default now(),
  voided_by                 uuid,                          -- id of the VOID event (set by the projection)
  unique (match_id, device_id, client_seq),
  foreign key (tenant_id, match_id) references game.match (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('game.match_event');
create index match_event_match_seq_idx on game.match_event (match_id, server_seq);
create index match_event_tenant_received_idx on game.match_event (tenant_id, received_at);

-- One row per roster player, rewritten on every re-projection of the match.
create table game.match_player_stats (
  match_id                uuid not null,
  tenant_id               uuid not null,
  player_id               uuid not null,
  pts                     integer not null default 0,
  fgm1                    integer not null default 0,
  fga1                    integer not null default 0,
  fgm2                    integer not null default 0,
  fga2                    integer not null default 0,
  fgm3                    integer not null default 0,
  fga3                    integer not null default 0,
  ast                     integer not null default 0,
  oreb                    integer not null default 0,
  dreb                    integer not null default 0,
  tov                     integer not null default 0,
  stl                     integer not null default 0,
  blk                     integer not null default 0,
  pf                      integer not null default 0,   -- all fouls
  technical_fouls         integer not null default 0,   -- also counted in pf
  unsportsmanlike_fouls   integer not null default 0,   -- also counted in pf
  seconds_played          integer not null default 0,
  was_starter             boolean not null default false,
  warnings                jsonb not null default '[]'::jsonb,
  primary key (match_id, player_id),
  foreign key (tenant_id, match_id) references game.match (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('game.match_player_stats');
create index match_player_stats_player_idx on game.match_player_stats (tenant_id, player_id);

create table game.match_summary (
  match_id         uuid primary key,
  tenant_id        uuid not null,
  our_score        integer not null default 0,
  opp_score        integer not null default 0,
  period_scores    jsonb not null default '[]'::jsonb,
  warnings         jsonb not null default '[]'::jsonb,  -- match-level projection warnings
  last_server_seq  bigint not null default 0,
  updated_at       timestamptz not null default now(),
  foreign key (tenant_id, match_id) references game.match (tenant_id, id) on delete cascade
);
select app.enable_tenant_rls('game.match_summary');
