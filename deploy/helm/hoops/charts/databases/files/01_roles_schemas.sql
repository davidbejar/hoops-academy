-- ============================================================================
-- Hoops Academy — database bootstrap (roles, schemas, RLS helpers)
--
-- Runs once as the Postgres superuser against the application database (`hoops`):
--   * compose / Testcontainers: /docker-entrypoint-initdb.d/01_roles_schemas.sql
--   * CloudNativePG:            postInitApplicationSQL
-- Passwords are NOT set here (see 02_passwords.sh / CNPG managed roles / test resources).
-- Idempotent: safe to re-run.
--
-- Principles (ADR-0006):
--   * <svc>_migrator owns the service schema and runs Flyway.
--   * <svc>_app is a NON-owner, NOBYPASSRLS login role with DML only → RLS always applies.
--   * core_platform is the super-admin datasource role: limited, explicit grants in migrations.
--   * app.current_tenant() RAISES when the transaction-local setting is missing (loud failure).
-- ============================================================================

-- ---------- roles -----------------------------------------------------------
do $$
declare r text;
begin
  foreach r in array array[
    'core_migrator','core_app','core_platform',
    'game_migrator','game_app',
    'athlete_migrator','athlete_app'] loop
    if not exists (select 1 from pg_roles where rolname = r) then
      execute format('create role %I login nosuperuser nocreatedb nocreaterole noinherit nobypassrls', r);
    else
      execute format('alter role %I login nosuperuser nocreatedb nocreaterole nobypassrls', r);
    end if;
  end loop;
end $$;

-- Reasonable connection limits for app roles (overridable per environment).
alter role core_app    connection limit 50;
alter role game_app    connection limit 50;
alter role athlete_app connection limit 50;
alter role core_platform connection limit 10;

-- ---------- lock down public -----------------------------------------------
revoke create on schema public from public;
revoke all on database hoops from public;
grant connect on database hoops to core_migrator, core_app, core_platform,
                                 game_migrator, game_app,
                                 athlete_migrator, athlete_app;

-- ---------- shared helper schema -------------------------------------------
create schema if not exists app;
grant usage on schema app to core_migrator, core_app, core_platform,
                            game_migrator, game_app,
                            athlete_migrator, athlete_app;

-- Returns the tenant bound to the current transaction (set via
--   select set_config('app.tenant_id', '<uuid>', true);
-- ). Raises 42501 when unset so a forgotten tenant never yields "all rows" or "no rows" silently.
create or replace function app.current_tenant() returns uuid
language plpgsql stable parallel safe as $$
declare v text := current_setting('app.tenant_id', true);
begin
  if v is null or v = '' then
    raise exception 'app.tenant_id is not set for this transaction' using errcode = '42501';
  end if;
  return v::uuid;
end $$;

-- Enables + forces RLS on a tenant table and (re)creates the standard isolation policy.
-- Runs with the privileges of the caller (the migrator that owns the table).
create or replace function app.enable_tenant_rls(tbl regclass) returns void
language plpgsql as $$
begin
  execute format('alter table %s enable row level security', tbl);
  execute format('alter table %s force row level security', tbl);
  execute format('drop policy if exists tenant_isolation on %s', tbl);
  execute format(
    'create policy tenant_isolation on %s using (tenant_id = app.current_tenant()) with check (tenant_id = app.current_tenant())',
    tbl);
end $$;

grant execute on function app.current_tenant() to public;
grant execute on function app.enable_tenant_rls(regclass) to core_migrator, game_migrator, athlete_migrator;

-- ---------- service schemas --------------------------------------------------
-- One block per (schema, migrator, app role). Default privileges make every table/sequence the
-- migrator creates usable by the app role without per-table grants in migrations.
do $$
declare s record;
begin
  for s in select * from (values
      ('core',    'core_migrator',    'core_app'),
      ('billing', 'core_migrator',    'core_app'),
      ('game',    'game_migrator',    'game_app'),
      ('athlete', 'athlete_migrator', 'athlete_app')
    ) as t(schema_name, migrator, app_role) loop
    execute format('create schema if not exists %I authorization %I', s.schema_name, s.migrator);
    execute format('grant usage on schema %I to %I', s.schema_name, s.app_role);
    execute format('alter default privileges for role %I in schema %I grant select, insert, update, delete on tables to %I',
                   s.migrator, s.schema_name, s.app_role);
    execute format('alter default privileges for role %I in schema %I grant usage, select on sequences to %I',
                   s.migrator, s.schema_name, s.app_role);
    execute format('alter default privileges for role %I in schema %I grant execute on functions to %I',
                   s.migrator, s.schema_name, s.app_role);
  end loop;
end $$;

-- core_platform: schema access only; table-level grants are explicit in core migrations
-- (tenant, usage_snapshot, billing.*). It never gets access to person/player data.
grant usage on schema core, billing to core_platform;
alter default privileges for role core_migrator in schema billing grant select, insert, update on tables to core_platform;
alter default privileges for role core_migrator in schema billing grant usage, select on sequences to core_platform;

-- Search path hygiene: each role sees its own schema first.
alter role core_migrator    set search_path = core, billing, app, public;
alter role core_app         set search_path = core, billing, app, public;
alter role core_platform    set search_path = core, billing, app, public;
alter role game_migrator    set search_path = game, app, public;
alter role game_app         set search_path = game, app, public;
alter role athlete_migrator set search_path = athlete, app, public;
alter role athlete_app      set search_path = athlete, app, public;
