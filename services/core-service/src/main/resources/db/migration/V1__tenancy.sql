-- ============================================================================
-- WP3 / V1 — tenancy: tenant registry, tenant settings, tenant logo (ADR-0006, ADR-0009)
-- ============================================================================

-- The tenant registry. It has no tenant_id (it IS the tenant) and is declared global in CoreRlsSchemaMetaTest,
-- but it is still protected by its own policies:
--   * core_app      : only the bound tenant's row (id = app.current_tenant()), may edit profile columns only;
--   * core_platform : every row (super-admin lifecycle); never sees tenant content tables;
--   * core_migrator : owner, needs an explicit policy because RLS is FORCEd (data migrations, test fixtures).
create table core.tenant (
  id             uuid primary key,
  slug           text not null unique check (slug ~ '^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$'),
  name           text not null check (char_length(name) between 1 and 120),
  status         text not null default 'ACTIVE' check (status in ('ACTIVE', 'SUSPENDED', 'WITHDRAWN')),
  status_reason  text check (char_length(status_reason) <= 500),
  timezone       text not null check (char_length(timezone) <= 64),
  default_locale text not null check (default_locale in ('es', 'en', 'id')),
  contact_email  text check (char_length(contact_email) <= 254),
  website_url    text check (char_length(website_url) <= 2048),
  created_at     timestamptz not null default now(),
  suspended_at   timestamptz,
  withdrawn_at   timestamptz,
  retain_until   date
);
create index tenant_status_idx on core.tenant (status);

alter table core.tenant enable row level security;
alter table core.tenant force row level security;
create policy tenant_self on core.tenant to core_app
  using (id = app.current_tenant()) with check (id = app.current_tenant());
create policy tenant_platform on core.tenant to core_platform
  using (true) with check (true);
create policy tenant_migrator on core.tenant to core_migrator
  using (true) with check (true);

-- core_app received full DML through default privileges; narrow it: read own row, edit profile columns only.
revoke insert, update, delete, truncate on core.tenant from core_app;
grant update (name, timezone, default_locale, contact_email, website_url) on core.tenant to core_app;

-- Roster rules and defaults: tenant content (not visible to the platform role).
-- The FK to the registry also guards the CreateTenant compensation: a tenant row that already has settings
-- (i.e. a fully provisioned tenant) can never be deleted by core_platform.
create table core.tenant_settings (
  tenant_id                         uuid primary key references core.tenant (id),
  age_rule                          text not null default 'BIRTH_YEAR' check (age_rule in ('BIRTH_YEAR', 'BIRTHDAY')),
  max_play_up_levels                integer check (max_play_up_levels >= 0),
  attendance_late_threshold_minutes integer not null default 10
                                    check (attendance_late_threshold_minutes between 0 and 120),
  updated_at                        timestamptz not null default now()
);
select app.enable_tenant_rls('core.tenant_settings');

-- Academy logo (ADR-0009): at most 512 KB, PNG/JPEG/WebP detected from magic bytes, strong ETag = sha256.
create table core.tenant_logo (
  tenant_id    uuid primary key,
  content_type text not null check (content_type in ('image/png', 'image/jpeg', 'image/webp')),
  bytes        bytea not null,
  size_bytes   integer not null check (size_bytes between 1 and 524288),
  etag         text not null,
  updated_at   timestamptz not null default now()
);
select app.enable_tenant_rls('core.tenant_logo');
