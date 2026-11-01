# Database bootstrap

`init/01_roles_schemas.sql` creates roles, schemas, default privileges and the RLS helpers
(`app.current_tenant()`, `app.enable_tenant_rls(regclass)`). `init/02_passwords.sh` sets passwords from env.
Both are mounted into `/docker-entrypoint-initdb.d/` by compose and by the Testcontainers resource in
`libs/common-quarkus`; the SQL is also the CloudNativePG `postInitApplicationSQL`. Database name: `hoops`.

| Role | Purpose | Owns | Can bypass RLS |
|---|---|---|---|
| `core_migrator` / `game_migrator` / `athlete_migrator` | Flyway | their schema | no (owner is exempt from RLS only without FORCE; we always FORCE) |
| `core_app` / `game_app` / `athlete_app` | service runtime | nothing | no |
| `core_platform` | super-admin datasource | nothing | no (explicit grants only) |

Verify locally: `podman exec -it hoops-postgres psql -U core_app -d hoops -c "select app.current_tenant()"` → error 42501.
