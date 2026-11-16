# Database bootstrap

`init/01_roles_schemas.sql` creates roles, schemas, default privileges and the RLS helpers
(`app.current_tenant()`, `app.enable_tenant_rls(regclass)`). `init/02_passwords.sh` sets passwords from env.
Both are mounted into `/docker-entrypoint-initdb.d/` by compose and by the Testcontainers resource in
`libs/common-quarkus`; the SQL is also the CloudNativePG `postInitApplicationSQL`. Database name: `hoops`.

| Role | Purpose | Owns | Can bypass RLS |
|---|---|---|---|
| `core_migrator` / `game_migrator` / `athlete_migrator` / `finance_migrator` | Flyway (finance: the Go runner, ADR-0055) | their schema | no (owner is exempt from RLS only without FORCE; we always FORCE) |
| `core_app` / `game_app` / `athlete_app` / `finance_app` | service runtime | nothing | no |
| `core_platform` | super-admin datasource | nothing | no (explicit grants only) |

Verify locally: `podman exec -it hoops-postgres psql -U core_app -d hoops -c "select app.current_tenant()"` → error 42501.

`finance_migrator` / `finance_app` (WP118): `02_passwords.sh` sets their passwords only when `FINANCE_*_PASSWORD` are
given, so a test resource or `.env` from before finance keeps working. A compose database created earlier gets the roles
with `just finance-up` (`infra/compose/finance-db.sh` re-applies `01_roles_schemas.sql`, which is idempotent).
