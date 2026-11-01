# WP1 — Local infrastructure (compose, Postgres init, Keycloak realm, nginx)

Model: Sonnet. Depends on: WP0. Parallel with WP2a, WP2b. ADRs: 0005, 0006, 0007.

## Scope
- `infra/db/init/01_roles_schemas.sql` (idempotent): schemas `core`, `billing`, `game`, `athlete`, `app`; roles
  `core_migrator`, `core_app`, `core_platform`, `game_migrator`, `game_app`, `athlete_migrator`, `athlete_app`
  (passwords from env via `psql -v` substitution in an entrypoint wrapper, never hardcoded); default privileges so
  tables created by `<svc>_migrator` are readable/writable by `<svc>_app`; `app.current_tenant()` function that
  RAISES (errcode 42501) when `app.tenant_id` is unset; helper `app.enable_tenant_rls(regclass)` that enables +
  forces RLS and creates the `tenant_isolation` policy. `core_platform` gets SELECT on `core.tenant`,
  `core.usage_snapshot`, `billing.*` only. App roles: `NOBYPASSRLS`, not owners. Same file is reused by
  Testcontainers (WP2a) and CNPG (WP16) — keep it pure SQL + `\gexec`-free (use DO blocks).
- `infra/compose/compose.yaml`: `postgres:17` (init dir mounted, healthcheck), Keycloak 26 (`start-dev
  --import-realm`, `KC_HTTP_RELATIVE_PATH=/auth`, `KC_HOSTNAME=http://localhost:8080/auth`, `KC_PROXY_HEADERS=xforwarded`,
  Postgres-backed), nginx on `:8080` routing `/auth/`→keycloak, `/api/core/`→core:8081, `/api/game/`→game:8082,
  `/api/athlete/`→athlete:8083, `/internal/` → 403, `/`→web (static placeholder until WP11), MailHog (smtp 1025,
  ui 8025). Services run on the host during dev (`host.containers.internal`) — document both modes.
- `infra/keycloak/realm-academy.json`: realm `academy`, clients `web` (public, PKCE S256, redirect URIs
  `http://localhost:8080/*`, web origins `http://localhost:8080`), `core-service`, `game-service`, `athlete-service`
  (confidential, service accounts, secret placeholders `${CORE_SERVICE_CLIENT_SECRET}` via Keycloak env substitution),
  realm roles `super_admin`, `service`; token lifespan 5 min, SSO idle 4 h, brute-force detection on, SMTP → mailhog.
  NO user credentials in the export.
- `infra/keycloak/seed-users.sh`: uses `kcadm.sh` inside the container to create dev users
  (superadmin, admin1, coach1, assistant1, parent1, player1; password `$DEV_USER_PASSWORD`), assigns `super_admin`
  to superadmin. Idempotent.
- `infra/compose/README.md` + `docs/runbooks/local-stack.md`.

## Acceptance
- [ ] `just up` → all services healthy; `curl :8080/auth/realms/academy/.well-known/openid-configuration` returns issuer `http://localhost:8080/auth/realms/academy`
- [ ] `podman exec` psql as `core_app` cannot `select` from `game.*` (permission denied) and `select app.current_tenant()` raises 42501 without the setting
- [ ] `just seed-users` idempotent; password grant for `web` client disabled, PKCE works (checked by `curl` to the auth endpoint returning login page)
- [ ] `gitleaks detect` clean; no secret literal in realm JSON or compose

## Handover

### Built
- `infra/compose/compose.yaml` (postgres:17, keycloak 26.8.1 start-dev --import-realm, mailhog, nginx 1.27-alpine; named volume `hoops_pgdata`; healthchecks on all four; `--wait` works), `nginx.conf`, `web-placeholder/index.html`, `postgres-keycloak-init.sh` (compose-only creation of db/role `keycloak`), `README.md`.
- `infra/keycloak/realm-academy.json` (realm `academy`; clients web/core-service/game-service/athlete-service; roles super_admin, service; service-account users carry `service`; token 300 s, SSO idle 4 h / max 12 h; brute force; `length(12)`; SMTP to mailhog; no human users; secrets as `${..._CLIENT_SECRET}`), `seed-users.sh`.
- `docs/runbooks/local-stack.md`; `justfile`: `up`/`down`/`logs` now pass `--env-file .env`.
- `infra/db/init/*` reused unchanged; no bugs found.

### Verified (commands run, all passed)
- `source scripts/env.sh && just up`: postgres, keycloak, mailhog, nginx all `healthy` (~40 s warm images).
- OIDC discovery issuer = `http://localhost:8080/auth/realms/academy`; `/` 200, `/internal/x` 403, `/api/core/x` 502 (no host service running, expected).
- `just seed-users` twice: first "created" x6, second "exists" x6, exit 0; superadmin has `super_admin`, emailVerified true.
- psql as core_app: `select * from game.anything` -> permission denied for schema game; `select app.current_tenant()` -> `42501: app.tenant_id is not set`; app roles NOBYPASSRLS, non-super.
- PKCE auth URL (web client, S256) -> 200 text/html "Sign in to Hoops Academy" with password field; without code_challenge -> `invalid_request` (PKCE enforced); password grant -> `unauthorized_client` (disabled).
- client_credentials for core/game/athlete-service: issuer correct, `realm_access.roles == ['service']`, lifetime 300 s.
- `gitleaks detect --source . --redact`: no leaks. `just down`: clean.

### Decisions
- Keycloak 26.8.1 (latest 26 tag). Keycloak uses its own db `keycloak` in the same Postgres (created by a compose-only script so the shared `infra/db/init` stays untouched).
- nginx uses static `proxy_pass` (host.containers.internal resolves via /etc/hosts at start), so no resolver needed; 502 when host services are down.
- Ports bound to 127.0.0.1. MailHog kept; it is amd64 and runs emulated on this arm64 machine (works; mailpit is the fallback).
- Service-account users in the realm JSON are not human users and carry no credentials.
- Realm import runs only once; JSON changes need a volume reset (documented).

### Open points / follow-ups
- Keycloak runs `start-dev` (dev only); production Helm/WP16 needs `start` with hardening.
- The realm has no `verifyEmail`/invitation flow yet; user provisioning via Admin API belongs to core-service work.
- `libs/common-quarkus` has uncommitted changes from another WP in the working tree (not mine).
- `.env` (random values) exists locally for testing; it is git-ignored.
