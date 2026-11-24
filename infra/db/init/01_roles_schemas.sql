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

-- ---------- lock down public -----------------------------------------------
revoke create on schema public from public;
revoke all on database hoops from public;

-- ---------- shared helper schema -------------------------------------------
create schema if not exists app;

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

-- ---------- roles -----------------------------------------------------------
-- The one list of the service roles (INF-03). Everything about a role below comes from its row; 02_passwords.sh sets
-- <ROLE>_PASSWORD for every role marked here; infra/db/roles.sh, the Java and Go test harnesses read the rows; the
-- lists that must stay literal (compose, .env.example, the chart's CNPG roles and Secrets, kind) are checked against
-- them (scripts/tests/test_db_roles.py). A new service adds its rows here and its schema row below.
-- Columns: role, the schemas it sees first (search_path, then app, public), connection limit (-1: none), migrator (owns
-- its schemas, runs the migrations, may call app.enable_tenant_rls).
do $$
declare r record;
begin
  for r in select * from (values
-- roles: begin
      ('core_migrator',    'core, billing', -1, true),
      ('core_app',         'core, billing', 50, false),
      ('core_platform',    'core, billing', 10, false),
      ('game_migrator',    'game',          -1, true),
      ('game_app',         'game',          50, false),
      ('athlete_migrator', 'athlete',       -1, true),
      ('athlete_app',      'athlete',       50, false),
      ('finance_migrator', 'finance',       -1, true),   -- finance-service (Go, ADR-0051 §2, ADR-0055)
      ('finance_app',      'finance',       50, false)
-- roles: end
    ) as t(name, schemas, connection_limit, migrator) loop
    if not exists (select 1 from pg_roles where rolname = r.name) then
      execute format('create role %I login nosuperuser nocreatedb nocreaterole noinherit nobypassrls', r.name);
    else
      execute format('alter role %I login nosuperuser nocreatedb nocreaterole nobypassrls', r.name);
    end if;
    execute format('comment on role %I is %L', r.name, 'hoops service role');
    execute format('alter role %I connection limit %s', r.name, r.connection_limit);
    execute format('grant connect on database hoops to %I', r.name);
    execute format('grant usage on schema app to %I', r.name);
    if r.migrator then
      execute format('grant execute on function app.enable_tenant_rls(regclass) to %I', r.name);
    end if;
    execute format('alter role %I set search_path = %s, app, public', r.name, r.schemas);
  end loop;
end $$;

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
      ('athlete', 'athlete_migrator', 'athlete_app'),
      ('finance', 'finance_migrator', 'finance_app')    -- finance-service (Go, ADR-0051 §2, ADR-0055)
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
