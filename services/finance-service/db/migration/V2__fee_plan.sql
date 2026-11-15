-- finance-service V2 (WP118, ADR-0056): fee plans. Runs as finance_migrator.
-- A plan charges every player of one team, or of every team of one age category, of one season, an amount per period
-- of its cadence (decision 93): MONTHLY (period "YYYY-MM"), QUARTERLY ("YYYY-Qn", calendar quarters) or SEASON (one
-- period, "SEASON"). first_period / last_period bound the periods (null for SEASON; last_period null = to the end of
-- the season). Immutable after creation: season, target and cadence (create another plan instead).
create table finance.fee_plan (
  tenant_id        uuid not null,
  id               uuid not null,
  name             text not null check (char_length(name) between 1 and 80),
  season_id        uuid not null,
  team_id          uuid,
  age_category_id  uuid,
  amount_minor     bigint not null check (amount_minor between 1 and 100000000000),
  cadence          text not null check (cadence in ('MONTHLY', 'QUARTERLY', 'SEASON')),
  first_period     text,
  last_period      text,
  auto_generate    boolean not null,
  archived         boolean not null default false,
  created_at       timestamptz not null,
  updated_at       timestamptz not null,
  version          integer not null default 0,
  primary key (tenant_id, id),
  constraint fee_plan_one_target check ((team_id is null) <> (age_category_id is null)),
  constraint fee_plan_periods check (
    (cadence = 'SEASON' and first_period is null and last_period is null)
    or (cadence = 'MONTHLY' and first_period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'
        and (last_period is null or (last_period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$' and last_period >= first_period)))
    or (cadence = 'QUARTERLY' and first_period ~ '^[0-9]{4}-Q[1-4]$'
        and (last_period is null or (last_period ~ '^[0-9]{4}-Q[1-4]$' and last_period >= first_period))))
);
select app.enable_tenant_rls('finance.fee_plan');
create index fee_plan_season_idx on finance.fee_plan (tenant_id, season_id, archived);
create index fee_plan_team_idx on finance.fee_plan (tenant_id, team_id) where team_id is not null;
