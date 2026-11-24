# Runbook: a new PostgreSQL major (17 to 19)

The repository runs PostgreSQL 19 since WP144 (ADR-0073). A database created on an older major does not start on the new
one: the data directory is major-specific. This page says how a stack that already holds data moves, and how it goes
back. A fresh stack (`just up` on no volume, a new kind cluster) needs none of it.

## Compose (the local stack)
The new compose file mounts a new volume, `hoops_pgdata-19`, at `/var/lib/postgresql` (from 18 the official image keeps
its cluster in `/var/lib/postgresql/<major>/docker`). The 17 data stays in `hoops_pgdata`, which compose no longer names:
neither `just up` nor `just down` touches it. Decision 115: the data is not restored into 19; the stack starts fresh and
is reseeded. The dump is a safety copy.

From the main checkout, with the stack running on 17 (`hoops-postgres`) and `.env` in place:

```bash
scripts/pg-major-move.sh --out "$HOME/hoops-pg17-dump"            # 1. dry run: the checks, and what --apply runs
scripts/pg-major-move.sh --out "$HOME/hoops-pg17-dump" --apply    # 2. dump, just down, just up on hoops_pgdata-19
just seed-users                                                   # 3. the dev users (the realm was imported fresh)
just services-up                                                  # 4. core, game, athlete (as usual)
just seed-academy                                                 # 5. the test academy and its demo data
just finance-up                                                   # 6. finance-service (and the roles' passwords)
just events-backfill force                                        # 7. the replicas from core's rows (ADR-0036)
just events-drift                                                 # 8. core and the replicas agree (exit 0)
```

Check on the real database that it is 19 and that the roles are as the bootstrap leaves them:
`podman exec hoops-postgres psql -XAt -U postgres -d hoops -c 'show server_version' -c "select rolname, rolsuper,
rolbypassrls from pg_roles where rolname ~ '_(app|migrator|platform)$'"` (nine rows, `f|f`). `just isolation-check`
and `just db-role-check` start their own Testcontainers database from the pinned image: they prove the code on 19,
not this stack.

What step 2 does: it refuses unless `hoops-postgres` runs on `hoops_pgdata`, on an older major than compose names, with
`standard_conforming_strings` on (a dump made with it off does not load into 19), and `hoops_pgdata-19` does not exist
yet. Then `pg_dumpall` with the old server's own tools inside its container (the local socket: no password), written
under `umask 077` to `--out` (0700, outside the repository: the dump holds the roles' password verifiers), checked for
its last line and hashed (`.sha256` beside it). Only then `just down` (keeps every volume) and `just up` (PostgreSQL 19
runs the bootstrap of `infra/db/init` on the empty volume, Keycloak imports `realm-academy.json`). It prints the size and
hash of the dump, never its content or a password. `--dump-only` stops after the dump. If `just up` fails after
`just down`, the script stops and says so; a second run refuses (the old container is gone): fix the cause and run
`just up` by hand, or take the way back.

The Redpanda volume (`hoops_redpanda-data`) is kept; step 7 republishes the roster from the new database.

### The way back
1. `git checkout <commit before WP144> -- infra/compose/compose.yaml` (image `postgres:17`, volume `pgdata` mounted at
   `/var/lib/postgresql/data`), or revert the WP144 merge.
2. `just down && just up`: PostgreSQL 17 starts on `hoops_pgdata` with the data of the moment of the move (the services
   on 17 still match their migrations: WP144 changed no migration).
3. `just events-backfill force`.

The dump is a second copy: into an empty 17 volume, `podman exec -i hoops-postgres psql -U postgres -d postgres <
<dump>.sql` (one error, "role postgres already exists", is expected). Remove `hoops_pgdata` by hand
(`podman volume rm hoops_pgdata`) only once PostgreSQL 19 has proven itself; nothing in the repository removes it.

## CloudNativePG (kind, the cloud VM)
A new cluster starts on `19.0-minimal-trixie` from the chart. Today only throwaway kind clusters exist (`just kind-down`,
`deploy/kind/up.sh --deploy`) and the cloud VM was never applied, so there is nothing to move.

For a cluster that holds data, do **not** change `imageName` from `postgresql:17` to the 19 tag: CloudNativePG's offline
in-place upgrade (`pg_upgrade --link` in a Job, triggered by a higher major in `imageName`) only works between images of
the same Debian distribution, and the old `postgresql:17` tag is the deprecated bullseye build, for which no 19 image
exists (CloudNativePG docs, "Postgres upgrades", release-1.30). The path is CloudNativePG's offline import ("Importing
Postgres databases", release-1.30): a new Cluster bootstraps from `pg_dump -Fd` of the old one over the network. What
that means for this chart (two Clusters, one database each, `enableSuperuserAccess: false`):

1. Stop writes (scale the services to 0) and back up. The import is a consistent snapshot; writes after it are lost.
2. Give the import a superuser on each old Cluster: `enableSuperuserAccess: true` (CloudNativePG then writes
   `<cluster>-superuser`). A non-superuser dump of `hoops` is not possible: every tenant table has `FORCE ROW LEVEL
   SECURITY`, and `pg_dump` refuses to dump rows a policy would hide.
3. Create the new Clusters by hand (the chart has no `import` or `externalClusters` stanza; a values switch for it is a
   follow-up), on `19.0-minimal-trixie`, under new names, each with `externalClusters` pointing at the old Cluster's
   `-rw` service with that superuser Secret:
   - `hoops-db`: `bootstrap.initdb.import` type `monolith`, `databases: [hoops]`, `roles:` the nine service roles of
     `infra/db/init/01_roles_schemas.sql` (the database owner `app` is created by the destination). Monolith keeps owners
     and imports roles without `SUPERUSER`; it does not run `postImportApplicationSQL`. Afterwards run the idempotent
     bootstrap once more as superuser in `hoops` (`kubectl exec <new>-1 -c postgres -- psql -U postgres -d hoops
     < infra/db/init/01_roles_schemas.sql`) for the database-level grants and the roles' `search_path`; the managed
     roles of the chart then set the passwords from the same Secrets.
   - `keycloak-db`: type `microservice`, `databases: [keycloak]`, `initdb.database: keycloak`, `initdb.owner: keycloak`,
     `secret: keycloak-db-app` (microservice imports no roles; the owner comes from `initdb`).
4. Switch the services to the new `-rw` services (or rename: delete the old Clusters only after the switch, then
   recreate under the old names by a second import), scale up, run `deploy/kind/smoke.sh core game athlete` and
   `just events-drift --kind`. Set `enableSuperuserAccess: false` again.
5. Way back: the old Clusters are untouched until they are deleted by hand; switch the services back to them.

Alternative without a write window: logical replication into the new Clusters (CloudNativePG `Publication` /
`Subscription`), then switch over. Within one Debian base (from now on: trixie), a later major can use the in-place
upgrade: set `imageName` to the new major's `MM.mm-minimal-trixie` after a backup; a failed upgrade is rolled back by
setting the old image again.
