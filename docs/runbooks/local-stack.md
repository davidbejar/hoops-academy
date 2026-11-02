# Runbook: local stack

## Start / stop
```
cp .env.example .env            # first time; replace all change-me-* with random values
source scripts/env.sh
just up                         # postgres, keycloak, mailhog, nginx; --wait until healthy
just seed-users                 # e-mail logins <name>@hoops-academy.com: superadmin, admin1, coach1, assistant1, parent1, player1 (password $DEV_USER_PASSWORD)
just logs keycloak              # follow logs
just down                       # stop (data kept in volume hoops_pgdata)
```
Reset everything: `just down && podman volume rm hoops_pgdata` (needed after changing the realm JSON or DB init scripts).

## Entry points
| What | URL |
|---|---|
| App / placeholder | http://localhost:8080/ |
| OIDC discovery | http://localhost:8080/auth/realms/academy/.well-known/openid-configuration |
| Keycloak admin | http://localhost:8080/auth/admin/ (`KEYCLOAK_ADMIN` / `KEYCLOAK_ADMIN_PASSWORD`) |
| MailHog UI | http://localhost:8025 |
| Postgres | `localhost:5432`, db `hoops` |

## Checks
```
podman ps --format '{{.Names}} {{.Status}}'
curl -s localhost:8080/auth/realms/academy/.well-known/openid-configuration | jq -r .issuer
# RLS bootstrap: must fail with 42501
podman exec -e PGPASSWORD=$CORE_APP_PASSWORD hoops-postgres psql -h 127.0.0.1 -U core_app -d hoops -c "select app.current_tenant()"
# service token (should contain realm role `service`)
curl -s localhost:8080/auth/realms/academy/protocol/openid-connect/token -d grant_type=client_credentials \
  -d client_id=core-service -d client_secret=$CORE_SERVICE_CLIENT_SECRET
```

## Troubleshooting
- `Cannot connect to Podman` / compose fails: `podman machine start`, then `source scripts/env.sh`.
- `required variable ... set in .env`: copy `.env.example` to `.env` and fill it.
- Keycloak unhealthy for > 2 min: `just logs keycloak`; usual causes are a bad realm JSON or missing client-secret env.
- Changed a DB role password in `.env` after first start: init scripts only run on an empty volume; reset the volume.
- nginx returns 502 on `/api/*`: the host service is not running on its port (8081/8082/8083).
- Issuer mismatch in a service: it must use exactly `http://localhost:8080/auth/realms/academy`.
