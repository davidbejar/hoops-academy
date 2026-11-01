-- ============================================================================
-- WP3 / V2 — identity & membership: app_user (global), person, membership_role, player, guardian_link,
-- user_membership_index (cross-tenant read path of GET /api/core/me)
-- ============================================================================

-- Platform-wide login identity. Deliberately minimal (no names, no tenant data) and WITHOUT RLS: it is looked up
-- by the caller's own sub or through a person row of the bound tenant, and is never listed by any endpoint.
create table core.app_user (
  id           uuid primary key,
  keycloak_sub text not null unique check (char_length(keycloak_sub) between 1 and 255),
  email        text check (char_length(email) <= 254),
  locale       text check (locale in ('es', 'en', 'id')),
  created_at   timestamptz not null default now()
);

create table core.person (
  id                uuid primary key,
  tenant_id         uuid not null,
  user_id           uuid references core.app_user (id),
  given_name        text not null check (char_length(given_name) between 1 and 80),
  family_name       text not null check (char_length(family_name) between 1 and 80),
  email             text check (char_length(email) <= 254),
  phone             text check (char_length(phone) <= 32),
  birth_date        date,
  gender            text check (gender in ('MALE', 'FEMALE')),
  locale            text check (locale in ('es', 'en', 'id')),
  active            boolean not null default true,
  invitation_status text not null default 'NONE' check (invitation_status in ('NONE', 'PENDING', 'ACCEPTED')),
  created_at        timestamptz not null default now(),
  deactivated_at    timestamptz,
  unique (tenant_id, id),
  unique (tenant_id, user_id)
);
create unique index person_tenant_email_uq on core.person (tenant_id, lower(email)) where email is not null;
select app.enable_tenant_rls('core.person');

create table core.membership_role (
  tenant_id  uuid not null,
  person_id  uuid not null,
  role       text not null check (role in ('ADMIN', 'COACH', 'ASSISTANT_COACH', 'PARENT', 'PLAYER')),
  granted_at timestamptz not null default now(),
  primary key (person_id, role),
  foreign key (tenant_id, person_id) references core.person (tenant_id, id)
);
create index membership_role_tenant_role_idx on core.membership_role (tenant_id, role);
select app.enable_tenant_rls('core.membership_role');

-- Created here because inviting a member with the PLAYER role creates it; roster columns arrive with WP4.
create table core.player (
  id         uuid primary key,
  tenant_id  uuid not null,
  person_id  uuid not null,
  status     text not null default 'ACTIVE'
             check (status in ('PENDING_APPROVAL', 'ACTIVE', 'ORPHAN', 'WITHDRAWN')),
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (person_id),
  foreign key (tenant_id, person_id) references core.person (tenant_id, id)
);
select app.enable_tenant_rls('core.player');

create table core.guardian_link (
  id                 uuid primary key,
  tenant_id          uuid not null,
  guardian_person_id uuid not null,
  player_id          uuid not null,
  created_at         timestamptz not null default now(),
  unique (tenant_id, guardian_person_id, player_id),
  foreign key (tenant_id, guardian_person_id) references core.person (tenant_id, id),
  foreign key (tenant_id, player_id) references core.player (tenant_id, id)
);
create index guardian_link_player_idx on core.guardian_link (tenant_id, player_id);
select app.enable_tenant_rls('core.guardian_link');

-- Which tenants a login belongs to: one row per ACTIVE person that has a login. Written inside the tenant's own
-- transaction (standard tenant policy). GET /me reads it across tenants through a second, SELECT-only policy that
-- matches the caller's subject: the use case binds the nil tenant (so the standard policy matches nothing and
-- does not raise) and app.subject = its own sub. Without app.subject nothing matches (fail closed).
create table core.user_membership_index (
  tenant_id    uuid not null,
  keycloak_sub text not null,
  person_id    uuid not null,
  primary key (tenant_id, keycloak_sub),
  foreign key (tenant_id, person_id) references core.person (tenant_id, id)
);
create index user_membership_index_sub_idx on core.user_membership_index (keycloak_sub);
select app.enable_tenant_rls('core.user_membership_index');
create policy own_memberships on core.user_membership_index for select to core_app
  using (keycloak_sub = current_setting('app.subject', true));
