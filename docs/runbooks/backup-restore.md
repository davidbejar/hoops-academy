# Runbook: backup and restore (DESIGN, not executed)

Status: **design only.** No backup or restore has been run on this project, no object store is configured, and the kind
cluster has no backup section. Every command here is a plan to be verified when a non-local environment exists. What is
established fact is the layout: one PostgreSQL 17 database `hoops` (schemas `core`, `billing`, `game`, `athlete`), a
separate database `keycloak`, and on Kubernetes two CloudNativePG clusters (`hoops-db`, `keycloak-db`).

## What must be backed up
| Data | Where | Notes |
|---|---|---|
| Academy data (all tenants) | database `hoops` | includes logos (`core.tenant_logo`, bytea, ADR-0009) and the append-only `core.audit_event` |
| Identities, passwords, sessions | database `keycloak` | without it nobody can log in; restore it together with `hoops` (tenant roles reference Keycloak `sub`) |
| Realm definition | `infra/keycloak/realm-academy.json` (git) | recreates clients and roles, not users |
| Secrets | secret manager / `.env` | see `rotate-secrets.md` |
| Offline plays not yet synced | users' browsers | not recoverable server-side; tell scorers to sync before an incident |

Recovery targets (proposal, to be agreed): RPO <= 5 min (continuous WAL archiving), RTO <= 1 h.

## Option 1: CloudNativePG continuous backup (barman), recommended on Kubernetes
Design: configure an object store (S3-compatible bucket, credentials in a Secret named per ADR-0012) on each Cluster, with
WAL archiving plus scheduled base backups, and a retention policy. In CloudNativePG 1.30 the barman-cloud integration is
the Barman Cloud plugin; the in-tree `barmanObjectStore` field is deprecated upstream. Check the CNPG documentation for the
exact CRDs of the pinned version before implementing. Outline:
1. Create the bucket and a Secret holding its credentials.
2. Define an `ObjectStore` and reference it from the `hoops-db` and `keycloak-db` Clusters (`plugins:` with
   `barman-cloud.cloudnative-pg.io`, `isWALArchiver: true`).
3. Add a `ScheduledBackup` (for example daily) per cluster; keep 14 to 30 days.
4. Monitor: backup age, WAL archive lag, last successful base backup.
Restore (point in time): create a **new** Cluster with `bootstrap.recovery` from the object store and a `recoveryTarget`
(`targetTime`), start it, verify (section "Verify"), then switch the services' `hoops-db-rw` target or rename.
The init SQL (`infra/db/init`) and managed roles come from the chart, so a recovered cluster keeps the role model; the
role Secrets must exist before the Cluster starts.

## Option 2: logical dump with pg_dump (compose, small installs, migrations between versions)
Dump as the Postgres **superuser**, not as an application or migrator role: every tenant table has `FORCE ROW LEVEL
SECURITY`, so a non-superuser dump would see no rows or fail on the policy. Design:
```bash
# dump (compose container name hoops-postgres; custom format, compressed)
podman exec -e PGPASSWORD="$POSTGRES_SUPERUSER_PASSWORD" hoops-postgres \
  pg_dump -U postgres -d hoops -Fc -f /tmp/hoops.dump
podman cp hoops-postgres:/tmp/hoops.dump ./hoops-$(date +%F).dump
# same for -d keycloak
```
Encrypt the file at rest and
copy it off the machine. Restore into an **empty** volume so that `infra/db/init` creates the roles and schemas first:
```bash
just down && podman volume rm hoops_pgdata && just up
podman cp ./hoops-YYYY-MM-DD.dump hoops-postgres:/tmp/hoops.dump
podman exec -e PGPASSWORD="$POSTGRES_SUPERUSER_PASSWORD" hoops-postgres \
  pg_restore -U postgres -d hoops --clean --if-exists --no-owner /tmp/hoops.dump
```
`--no-owner` is a guess to be validated: ownership by `*_migrator` and the grants must survive; if they do not, restore with
owners and run Flyway afterwards. Treat the exact flags as unverified.

## Per-tenant restore
Not supported by design: tenants share tables. Options when one academy needs rollback: restore a PITR copy next to
production and copy that tenant's rows with a superuser script (`where tenant_id = ...`, FK order), or export before a risky
operation. A tenant export/import feature is not planned (`docs/roadmap.md`).

## Verify a restore
1. `select count(*) from core.tenant;` and row counts per schema match expectations.
2. Services start and Flyway reports no pending or failed migration (`flyway_schema_history` per schema).
3. Run the checks in `local-stack.md` (RLS bootstrap must still fail with 42501 for `app.current_tenant()` with no tenant).
4. Run the e2e journey (`e2e.md`) against the restored stack.
5. Log in as a real user through Keycloak; `GET /api/core/me` returns the memberships.

## Rehearsal
Do a quarterly restore drill into a scratch environment and record time taken against RTO.
