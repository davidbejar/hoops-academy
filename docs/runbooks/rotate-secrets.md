# Runbook: rotate secrets

Policy (ADR-0012, CLAUDE.md rule 6): secrets never live in git; `.env` is git-ignored; charts only reference Secrets by
name. Rotate on a schedule, when someone leaves, and after any suspected leak (`gitleaks` hit, shared log).

Verification status: the kind-side mechanism is documented in `docs/runbooks/kind.md` ("Secrets") and exercised in
`docs/wp/WP16-kind-helm-tilt.md`. The compose and Keycloak steps below were assembled from the scripts and the realm
file and have **not been executed end to end**. Items marked (design) do not exist yet.

## Inventory
| Secret | Where it lives | Consumers |
|---|---|---|
| `POSTGRES_SUPERUSER_PASSWORD`, `*_MIGRATOR_PASSWORD`, `*_APP_PASSWORD`, `CORE_PLATFORM_PASSWORD` | `.env`; kind Secrets `hoops-db-<role>` | Postgres roles; services (app role), Flyway (migrator) |
| `KC_DB_PASSWORD` | `.env`; Secret `keycloak-db-app` | Keycloak database role |
| `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD` | `.env`; Secret `keycloak-admin` | Keycloak bootstrap admin, seed script, e2e |
| `CORE_/GAME_/ATHLETE_SERVICE_CLIENT_SECRET` | `.env`; Secrets `hoops-oidc-<service>` (key `client-secret`) | realm import (`${..._CLIENT_SECRET}`) and each service's client credentials |
| `DEV_USER_PASSWORD` | `.env`; Secret `hoops-dev-users` | seeded dev users (local only) |
| `RATELIMIT_REDIS_PASSWORD` | `.env`; Secrets `hoops/hoops-ratelimit-redis` (key `password`) and `envoy-gateway-system/envoy-ratelimit-redis-auth` (key `auth` = `ratelimit:<password>`) | Redis ACL user of `ratelimit-redis` (read at Redis start); Envoy Gateway's `envoy-ratelimit` pods (`REDIS_AUTH`, ADR-0033 amendment) |

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
deploy/kind/secrets.sh | kubectl apply -f -          # 15 Secrets rendered from .env, values never on argv or disk
kubectl -n hoops rollout restart deploy               # services read env at start (ratelimit-redis rewrites its ACL file)
kubectl -n envoy-gateway-system rollout restart deploy/envoy-ratelimit   # after RATELIMIT_REDIS_PASSWORD changed
```
`secrets.sh` fails fast if `.env` or a key is missing. Tilt applies the same output from memory.
`RATELIMIT_REDIS_PASSWORD`: until both Redis and `envoy-ratelimit` restarted, the rate limit service gets `WRONGPASS`
and the gateway fails open (no 429, ADR-0033), so restart both together and re-run `deploy/kind/ratelimit-check.sh token`.
Caveats from `kind.md`: Keycloak admin and client secrets apply only on the first import; for an existing DB change them
in Keycloak too, or delete the `keycloak-db` Cluster (`kubectl -n hoops delete cluster keycloak-db`) to re-import.

## D. CloudNativePG managed roles
The `databases` chart declares 7 `managed.roles`, each with `passwordSecret` (a `kubernetes.io/basic-auth` Secret whose
`username` equals the role name). Update the Secret (section C) and CNPG re-applies the password: it reports the role as
`reconciled` (`kubectl -n hoops get cluster hoops-db -o jsonpath='{.status.managedRolesStatus}'`). Restart the consumers
afterwards. Changed passwords of an already-bootstrapped `keycloak-db` (`initdb.secret`) are only used at bootstrap: use
`ALTER ROLE` there (design).

## E. Beyond local (design)
External Secrets Operator with one `ExternalSecret` per Secret above, same names/keys/types, `refreshInterval` as the
rotation clock; a rollout trigger (Reloader or a checksum annotation) is still to be chosen (ADR-0012). Enable encryption at
rest for Secrets and restrict `get secrets` RBAC. Not built: no non-local environment exists.

## After any leak
Rotate everything in the inventory, then run `gitleaks detect --source . --redact` and `deploy/helm/tests/run.sh`
(renders the chart and pipes it through gitleaks).
