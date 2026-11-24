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
just isolation-check && just db-role-check                        # 8. the tenancy gates on the new database
```

What step 2 does: it refuses unless `hoops-postgres` runs on `hoops_pgdata`, on an older major than compose names, with
`standard_conforming_strings` on (a dump made with it off does not load into 19), and `hoops_pgdata-19` does not exist
yet. Then `pg_dumpall` with the old server's own tools inside its container (the local socket: no password), written
under `umask 077` to `--out` (0700, outside the repository: the dump holds the roles' password verifiers), checked for
its last line and hashed (`.sha256` beside it). Only then `just down` (keeps every volume) and `just up` (PostgreSQL 19
runs the bootstrap of `infra/db/init` on the empty volume, Keycloak imports `realm-academy.json`). It prints the size and
hash of the dump, never its content or a password. `--dump-only` stops after the dump.

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
exists (CloudNativePG docs, "Postgres upgrades", release-1.30). The path, per CloudNativePG's "Importing Postgres
databases":

1. Back up (barman plugin or `pg_dumpall` from the primary pod) and keep the old Cluster running.
2. Create a new Cluster on `19.0-minimal-trixie` with `bootstrap.initdb.import` (type `monolith`, databases `hoops` and
   `keycloak`, roles imported or recreated by the chart's managed roles) whose `externalClusters` entry points at the
   old cluster's `-rw` service with a superuser Secret. The import is a logical dump/restore: a downtime window for
   writes.
3. Point the services at the new cluster (the chart's `hoops-db-rw` name: rename the old one or switch the values), run
   the smoke (`deploy/kind/smoke.sh`), then delete the old Cluster and its PVCs by hand.
4. Way back: the old Cluster is untouched until step 3 ends; switch the services back.

Alternative without a write window: logical replication into the new cluster (CloudNativePG `Publication` /
`Subscription`), then switch over. Within one Debian base (from now on: trixie), a later major can use the in-place
upgrade: set `imageName` to the new major's `MM.mm-minimal-trixie` after a backup; a failed upgrade is rolled back by
setting the old image again.
