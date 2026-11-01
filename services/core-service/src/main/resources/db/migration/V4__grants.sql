-- ============================================================================
-- WP3 / V4 — explicit grants for core_platform (infra/db/init gives it schema usage only for core;
-- billing tables get select/insert/update through default privileges).
-- core_platform may touch: core.tenant, core.usage_snapshot, core.outbox (append only), billing.*.
-- It never receives privileges on person/membership/player/guardian/settings/logo/app_user/index.
-- ============================================================================
grant select, insert, update on core.tenant to core_platform;
-- delete exists only for the CreateTenant compensation; the FK from tenant_settings makes it impossible
-- for any tenant that finished provisioning.
grant delete on core.tenant to core_platform;
grant select, insert on core.usage_snapshot to core_platform;
grant insert on core.outbox to core_platform;
grant delete on billing.tenant_subscription to core_platform;
