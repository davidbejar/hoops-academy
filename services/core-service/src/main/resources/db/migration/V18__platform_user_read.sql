-- ============================================================================
-- WP91 / V18 — the super admin's Users area: GET /platform/users (decision 71, ADR-0029 amendment)
-- core_platform reads every login and, of persons WITH a login, the name, roles and active flag, through its own
-- SELECT policies and column grants, the mechanism it already uses for the registry, the audit trail (V11) and the
-- outbox backlog (V14): no BYPASSRLS, no security definer, nothing new for core_app. Its transaction binds the nil
-- tenant (as GET /me does for the membership index), so the standard tenant_isolation policy matches nothing and does
-- not raise. Still invisible to it: persons without a login (young players), every other person column (e-mail, phone,
-- birth date, gender, locale, invitation), the login's subject and locale, and every other content table (player,
-- guardian_link, team, …). It writes none of these tables.
-- ============================================================================
grant select (id, email, created_at) on core.app_user to core_platform;

create policy person_platform_read on core.person for select to core_platform using (user_id is not null);
grant select (id, tenant_id, user_id, given_name, family_name, active) on core.person to core_platform;

-- Roles of the persons core_platform can see (the subquery runs under its own policy on core.person).
create policy membership_role_platform_read on core.membership_role for select to core_platform
  using (exists (select 1 from core.person p where p.id = membership_role.person_id));
grant select (tenant_id, person_id, role) on core.membership_role to core_platform;

-- The Users list joins each login of a page to its persons (the unique (tenant_id, user_id) cannot serve that).
create index person_user_idx on core.person (user_id) where user_id is not null;
