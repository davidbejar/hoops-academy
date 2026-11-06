# Local stack (compose)

Services: `postgres` (17, db `hoops` + db `keycloak`), `keycloak` (26.8.1, `start-dev --import-realm`),
`mailhog` (SMTP 1025, UI 8025), `nginx` (:8080, the only public entry point), `redpanda` (event broker, WP66, Kafka API
`localhost:19092`, admin API `localhost:19644`, no auth). Container names: `hoops-<service>`.

```
cp .env.example .env     # then replace every change-me-* value (git-ignored)
source scripts/env.sh && just up      # waits for healthchecks (first run pulls images)
just seed-users                       # dev users, idempotent
just down                             # stop; add `-v` via podman compose to also drop the pgdata volume
```

## Files
- `compose.yaml` – stack definition. Reads secrets from `.env` (`--env-file .env`); missing vars fail fast.
- `nginx.conf` – `/auth/`→Keycloak, `/api/{core,game,athlete}/`→host ports 8081/8082/8083 via
  `host.containers.internal`, `/internal/`→403, `/`→`web-placeholder/` (until the Flutter app, WP11).
- `redpanda-bootstrap.yaml` – cluster properties at the broker's first start (no topic auto-creation, no metrics reporter).
- `redpanda-topics.sh` – the seven event topics (`just events-topics`, run by `just up`; idempotent). ADR-0036,
  `docs/runbooks/events.md`.
- `postgres-keycloak-init.sh` – compose-only: creates db/role `keycloak` (kept out of `infra/db/init`, which is
  shared with Testcontainers/CNPG).
- `../db/init/*` – roles, schemas, RLS helpers, passwords (see `infra/db/README.md`).
- `../keycloak/realm-academy.json` – realm import; client secrets via `${..._CLIENT_SECRET}` env substitution.
- `../keycloak/seed-users.sh` – dev users via `kcadm.sh` in the container.

## Modes
- **Host mode (default dev):** run Quarkus services with `quarkus:dev` on 8081/8082/8083; nginx reaches them at
  `host.containers.internal`. Services use issuer `http://localhost:8080/auth/realms/academy` (JWKS fetched through nginx).
- **In-compose mode (later):** services become compose services; they reach Keycloak at `http://nginx:8080/auth/...`
  so the issuer stays identical.

## Notes
- Ports bind to 127.0.0.1 only. Postgres is on `localhost:5432` (db `hoops`).
- Keycloak runs `start-dev` (dev only!). Health is on the management port 9000 (`/auth/health/ready`), not published.
- MailHog is amd64-only and runs under emulation on Apple Silicon; if it misbehaves swap in `axllent/mailpit`
  (same ports 1025/8025).
- The realm is imported only when it does not exist yet. After editing `realm-academy.json`, drop Keycloak state:
  `just down` then `podman volume rm hoops_pgdata` (this wipes all local data).
