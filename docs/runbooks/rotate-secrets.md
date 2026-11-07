# Runbook: rotate secrets

Policy (ADR-0012, CLAUDE.md rule 6): secrets never live in git; `.env` is git-ignored; charts only reference Secrets by
name. Rotate on a schedule, when someone leaves, and after any suspected leak (`gitleaks` hit, shared log).

Verification status: the kind-side mechanism is documented in `docs/runbooks/kind.md` ("Secrets") and exercised in
`docs/wp/WP16-kind-helm-tilt.md`; the ESO path (section E) in `docs/wp/WP65-external-secrets-operator.md`, the automatic restarts (Reloader) in
`docs/wp/WP87-chart-reloader-kind-proofs.md` (chart render and controller install) and, on kind,
`docs/wp/WP86-otel-collector.md` (rotation of `GAME_APP_PASSWORD` and `REDPANDA_GAME_SERVICE_PASSWORD` through ESO:
Reloader restarted game-service in the second the Secret changed; the database half needed the `cnpg.io/reload` label, D). The compose and Keycloak steps below were assembled from the scripts and the realm
file and have **not been executed end to end**. Items marked (design) do not exist yet.

## Inventory
Every Secret the chart and `deploy/kind/secrets.sh` reference (WP65). Source: the `.env` key, which is also the property
of the remote secret `hoops` when the chart runs with `externalSecrets.enabled=true` (ESO, section E).

| Kubernetes Secret (namespace `hoops` unless noted) | Type, keys | `.env` key / ESO property | Consumers |
|---|---|---|---|
| `hoops-db-core-migrator`, `hoops-db-game-migrator`, `hoops-db-athlete-migrator` | basic-auth, `username` = role, `password` | `<SVC>_MIGRATOR_PASSWORD` | CNPG managed roles of `hoops-db`; each service's Flyway (env `<SVC>_MIGRATOR_PASSWORD`) |
| `hoops-db-core-app`, `hoops-db-game-app`, `hoops-db-athlete-app` | basic-auth, `username` = role, `password` | `<SVC>_APP_PASSWORD` | CNPG managed roles; each service's datasource (env `<SVC>_APP_PASSWORD`) |
| `hoops-db-core-platform` | basic-auth, `username` = `core_platform`, `password` | `CORE_PLATFORM_PASSWORD` | CNPG managed role; core-service platform datasource |
| `keycloak-db-app` | basic-auth, `username` = `keycloak`, `password` | `KC_DB_PASSWORD` | CNPG `keycloak-db` `bootstrap.initdb.secret` (first bootstrap only); Keycloak `KC_DB_USERNAME`/`KC_DB_PASSWORD` |
| `keycloak-admin` | `username`, `password` | `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD` | Keycloak bootstrap admin (first start only); `seed-users.sh` and e2e read `.env` |
| `hoops-oidc-core-service`, `hoops-oidc-game-service`, `hoops-oidc-athlete-service` | `client-secret` | `<SVC>_SERVICE_CLIENT_SECRET` | Keycloak realm import (`${..._CLIENT_SECRET}`, first import only); each service's client credentials |
| `hoops-ratelimit-redis` | `password` | `RATELIMIT_REDIS_PASSWORD` | `ratelimit-redis` init container (hashes it into the ACL file at pod start) |
| `envoy-gateway-system/envoy-ratelimit-redis-auth` | `auth` = `ratelimit:<password>` | `RATELIMIT_REDIS_PASSWORD` | Envoy Gateway's `envoy-ratelimit` pods (`REDIS_AUTH`, ADR-0033 amendment) |
| `hoops-redpanda-admin` | basic-auth, `username` = `admin`, `password` | `REDPANDA_ADMIN_PASSWORD` | Redpanda superuser: `RP_BOOTSTRAP_USER` of `redpanda-0` (first bootstrap only), the `redpanda-bootstrap` Job, operators' `rpk` (ADR-0036) |
| `hoops-redpanda-core-service`, `hoops-redpanda-game-service`, `hoops-redpanda-athlete-service` | basic-auth, `username` = broker user, `password` | `REDPANDA_<SVC>_SERVICE_PASSWORD` | the `redpanda-bootstrap` Job (sets the SCRAM password on every install/upgrade); the services from WP67-WP69 |
| `hoops-dev-users` | `password` | `DEV_USER_PASSWORD` | nothing in the cluster: `seed-users.sh` and `smoke.sh` read `.env` (rendered by `secrets.sh` only, not by ESO) |
| `hoops-gateway-tls` | kubernetes.io/tls | none: self-signed by `up.sh` (kind), cert-manager elsewhere | Gateway `hoops` HTTPS listener (`gateway.tls.certificateRefs`) |

Compose only: `POSTGRES_SUPERUSER_PASSWORD` (`.env`; the compose Postgres, never in kind, where CNPG keeps superuser access
off). SMTP: none; the realm's `smtpServer` is the unauthenticated Mailpit sink `mailhog:1025` (kind, compose), so a real
SMTP relay with credentials would add a realm change and a Secret (not built).

## A. Compose (`.env`)
1. Edit `.env` with new random values (for example `openssl rand -base64 24`). Never paste them into a shell history
   line, ticket or chat.
2. Database role passwords: `infra/db/init/02_passwords.sh` runs only on an empty volume. Either
   - reset: `just down && podman volume rm hoops_pgdata && just up && just seed-users` (loses all local data), or
   - rotate in place (design, not executed): `ALTER ROLE core_app PASSWORD '...'` as the superuser for each role
     (psql inside `hoops-postgres`), then restart the services.
3. Keycloak client secrets and admin password are applied at the first realm import / first bootstrap only. With data to
   keep, change them in Keycloak (Admin console `http://localhost:8080/auth/admin/` needs `HOOPS_EXPOSE_KC_ADMIN=true`;
   client > Credentials > Regenerate, then put the same value in `.env`). Otherwise reset the volume as above.
4. Restart the Quarkus services so they read the new environment (`just services-down && just services-up`).
5. Check: `just seed-users` works and the service token call in `docs/runbooks/local-stack.md` ("Checks") returns a token.

## B. Keycloak client secrets (any environment)
The realm file references `${CORE_SERVICE_CLIENT_SECRET}` etc.; Keycloak imports a realm only if it does not exist.
So a changed env var alone changes nothing on an existing Keycloak.
1. Regenerate the secret in Keycloak (client `core-service` > Credentials) or set it with `kcadm.sh update clients/<id> -s secret=...` (design, not executed).
2. Update the Secret/`.env` with the same value.
3. Roll the services; the `ServiceTokenClientFilter` fetches a new token on its next refresh.
4. Verify with the client-credentials call (token must contain realm role `service`).

## C. kind (Kubernetes Secrets)
```bash
# edit .env first
deploy/kind/secrets.sh | kubectl apply -f -          # 19 Secrets rendered from .env, values never on argv or disk
```
Restarts are automatic (WP87, ADR-0012 amendment): Stakater Reloader (installed by `up.sh`) rolls every Deployment/
StatefulSet annotated with `secret.reloader.stakater.com/auto` whose Secret changed: the three services, keycloak,
ratelimit-redis (rewrites its ACL file at start), redpanda and, in `envoy-gateway-system`, envoy-ratelimit. Watch it:
`kubectl -n hoops-reloader logs deploy/reloader-reloader`. A cluster without Reloader (or one created before WP87:
re-run `up.sh`) needs `kubectl -n hoops rollout restart deploy` and, after `RATELIMIT_REDIS_PASSWORD`,
`kubectl -n envoy-gateway-system rollout restart deploy/envoy-ratelimit`.
`REDPANDA_<SVC>_SERVICE_PASSWORD` (WP66): the broker keeps its own SCRAM credentials; the `redpanda-bootstrap` Job copies
the Secret's password to the broker on every `helm upgrade` (with Tilt: when the Job is re-applied). Reloader restarts the
service as soon as the Secret changes; its new pod logs in once the Job ran. `REDPANDA_ADMIN_PASSWORD` is used by the broker only at its first bootstrap: change the
broker first, then the Secret (`docs/runbooks/events.md`, "Rotate the superuser"), otherwise the Job can no longer log in.
`secrets.sh` fails fast if `.env` or a key is missing. Tilt applies the same output from memory.
`RATELIMIT_REDIS_PASSWORD`: until both Redis and `envoy-ratelimit` restarted, the rate limit service gets `WRONGPASS`
and the gateway fails open (no 429, ADR-0033); Reloader restarts both, then re-run `deploy/kind/ratelimit-check.sh acl`.
Caveats from `kind.md`: Keycloak admin and client secrets apply only on the first import; for an existing DB change them
in Keycloak too, or delete the `keycloak-db` Cluster (`kubectl -n hoops delete cluster keycloak-db`) to re-import.

## D. CloudNativePG managed roles
The `databases` chart declares 7 `managed.roles`, each with `passwordSecret` (a `kubernetes.io/basic-auth` Secret whose
`username` equals the role name). Update the Secret (section C) and CNPG re-applies the password: it reports the role as
`reconciled` (`kubectl -n hoops get cluster hoops-db -o jsonpath='{.status.managedRolesStatus}'`). CNPG watches only Secrets
labelled `cnpg.io/reload: "true"` (WP86): `secrets.sh` (`db_role`) and the chart's ExternalSecrets (`labels` of the
`hoops-db-*` / `keycloak-db-app` entries) set it. Without it the role kept its old password and the restarted service never
got Ready (WP86 on kind); with it CNPG applied the new password within 18 s and the new pod was Ready after 61 s. Reloader restarts
the consumers when the Secret changes, possibly before CNPG applied the password: the new pod then fails its start and
retries until the role has it (the old pod keeps serving meanwhile). Changed passwords of an already-bootstrapped `keycloak-db` (`initdb.secret`) are only used at bootstrap: use
`ALTER ROLE` there (design).

## E. External Secrets Operator (`externalSecrets.enabled=true`)
The source of truth is the secret manager behind the `ClusterSecretStore` (`externalSecrets.storeRef`); the Secrets are
ESO's copies (ADR-0012 amendment). Never edit them with `kubectl`: ESO overwrites them at the next refresh.
1. Change the value at the source: the property named in the inventory, of remote secret `hoops`
   (`externalSecrets.remoteKey`). On kind (`up.sh --eso`) the source is Secret `hoops-secret-store/hoops`:
   ```bash
   # new value from a file descriptor, never on a command line (here: a random one for GAME_APP_PASSWORD)
   kubectl -n hoops-secret-store patch secret hoops --type merge --patch-file <(
     printf '{"data":{"GAME_APP_PASSWORD":"%s"}}' "$(openssl rand -hex 24 | tr -d '\n' | base64)")
   ```
   The kind scripts read only `KEYCLOAK_ADMIN*` and `DEV_USER_PASSWORD` from `.env`: when rotating the admin login,
   write the same value to `.env` and to the source.
2. ESO refreshes within `refreshInterval` (1 h default, 1 m on kind). Force it now:
   `kubectl -n hoops annotate externalsecret <name> force-sync=$(date +%s) --overwrite`; check
   `kubectl -n hoops get externalsecret` (`SecretSynced`, `READY True`) and the Secret's `resourceVersion`.
3. The pods restart by themselves (WP87): Reloader rolls every annotated workload that reads the changed Secret
   (`global.reloader.enabled`, `kubectl -n hoops-reloader logs deploy/reloader-reloader`). What is left is the server
   side of some credentials:

   | Changed property | Restarted by Reloader | Still manual |
   |---|---|---|
   | `*_MIGRATOR_PASSWORD`, `*_APP_PASSWORD`, `CORE_PLATFORM_PASSWORD` | the service of that role | nothing: CNPG sets the role password on its next reconcile (`managedRolesStatus.passwordStatus.<role>.resourceVersion` = the Secret's); a pod that starts before it retries until then |
   | `KC_DB_PASSWORD` | `deploy/keycloak` | `ALTER ROLE keycloak PASSWORD ...` in `keycloak-db` **before** the source change (section D; `initdb.secret` is read at bootstrap only) |
   | `KEYCLOAK_ADMIN*`, `*_SERVICE_CLIENT_SECRET` | keycloak, the service of the client | change them in Keycloak **first** (section B): Keycloak applies them on the first start/import only |
   | `RATELIMIT_REDIS_PASSWORD` | `deploy/ratelimit-redis` and `envoy-gateway-system/deploy/envoy-ratelimit` (both Secrets change together) | nothing; until both restarted the gateway fails open (section C) |
   | `REDPANDA_<SVC>_SERVICE_PASSWORD` | the service of that user | `helm upgrade` (or trigger `redpanda-bootstrap` in Tilt) so the Job sets the new password on the broker; the new pod logs in after it |
   | `REDPANDA_ADMIN_PASSWORD` | `redpanda-0` | change the broker's `admin` password **first** (`events.md`), then the source |
4. Check: `deploy/kind/smoke.sh core game athlete` (kind) or the deploy checks of `release.md`.

Migrating an install from pre-created Secrets to ESO: create the store and the source values first, then
`helm upgrade ... --set externalSecrets.enabled=true`; ESO takes the existing Secrets over (`creationPolicy: Owner`). On
kind, pick the mode when the cluster is created (`just kind-down`, then `up.sh --eso`). Enable encryption at rest for
Secrets and restrict `get secrets` and `create externalsecrets` RBAC in real clusters.

## After any leak
Rotate everything in the inventory, then run `gitleaks detect --source . --redact` and `deploy/helm/tests/run.sh`
(renders the chart and pipes it through gitleaks).
