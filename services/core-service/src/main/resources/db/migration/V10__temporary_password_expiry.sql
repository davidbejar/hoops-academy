-- ============================================================================
-- WP32 / V10 — temporary password expiry (ADR-0028): when a login's temporary password was issued and when the sweep
-- expired it (disabled the Keycloak login). core.app_user stays global and without RLS (V2): no tenant data, looked
-- up by subject or id only; core_app already has select/insert/update on it through default privileges, and
-- core_platform still gets nothing on it (V4).
-- ============================================================================
alter table core.app_user
  add column temporary_password_issued_at  timestamptz,
  add column temporary_password_expired_at timestamptz;

comment on column core.app_user.temporary_password_issued_at is
  'When the outstanding temporary password was issued; null once the person chose their own password (ADR-0028)';
comment on column core.app_user.temporary_password_expired_at is
  'When the sweep expired the unused temporary password and disabled the login; cleared by a new issue (ADR-0028)';

-- The sweep looks for issued, not yet expired passwords older than the TTL.
create index app_user_temporary_password_due_idx on core.app_user (temporary_password_issued_at)
  where temporary_password_issued_at is not null and temporary_password_expired_at is null;
