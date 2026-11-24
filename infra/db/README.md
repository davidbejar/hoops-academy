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

One list (INF-03, WP139): the `-- roles: begin` / `-- roles: end` rows of `01_roles_schemas.sql` name every role with
its schemas, connection limit and whether it migrates; the grants and search paths come from the rows. `02_passwords.sh`
sets the password of every role the SQL marked (comment `hoops service role`) from `<ROLE>_PASSWORD`, each one
required. `roles.sh` prints the list for scripts and workflows; the Java (`BootstrapRoles`) and Go (`pgtest`) test
harnesses read it from the SQL; `scripts/tests/test_db_roles.py` checks the lists that stay literal (compose,
`.env.example`, the chart's CNPG roles and Secrets, kind's `secrets.sh` and `env-keys.sh`). A new service adds its rows
here, its schema row, and the names in those lists.
In Kubernetes CloudNativePG runs the same SQL (`postInitApplicationSQL`) and then manages the roles' passwords from
Secrets; its role reconciler clears the `hoops service role` comment, which only `02_passwords.sh` reads (kind proof of
WP139: roles, privileges and role settings otherwise equal to compose's).

A compose database created before a role existed gets it with `just finance-up` or `e2e/bin/services-up.sh`
(`infra/compose/db-roles.sh` re-applies `01_roles_schemas.sql`, which is idempotent, and runs `02_passwords.sh`).
