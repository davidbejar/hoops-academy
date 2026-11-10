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

**Realm changes.** Keycloak imports `infra/keycloak/realm-academy.json` only into an empty database, so an existing stack
keeps the realm it was first started with. After a realm change re-import it:
`just down && podman volume rm hoops_pgdata && just up && just seed-users` (this also drops the services' data).
`just seed-users` brings an old realm partly up to date without the reset (login theme, e-mail as username, and since
WP56 the token audiences and refresh-token rotation of ADR-0034); anything else in the realm file needs the re-import.
Symptom of a realm from before WP56: every API call of the signed-in app answers 401 (`aud` lacks the service).

## Podman machine (API service without idle exit)
`podman.service` (the Docker-compatible API, a user unit in the VM) exits after 5 s idle by default; the next request
restarts it and Testcontainers or compose see "localhost:2375 failed to respond". The fix is a drop-in with
`--time=0`, `~core/.config/systemd/user/podman.service.d/no-timeout.conf`.
- New machine: `podman machine init --playbook "$PWD/infra/podman/machine-playbook.yml"` writes the drop-in at first boot
  (owner `core`). Dry run inside an existing VM: copy the file in and run
  `ansible-playbook -i localhost, -c local --check --diff <file>` (it reports `changed=0` when the drop-in exists).
- Existing machine: `just doctor` reads the unit with one `podman machine ssh`, writes the drop-in and reloads systemd
  when `--time=0` is missing, and restarts the service only when no container runs; otherwise it prints that a restart
  is pending (run `podman machine ssh 'systemctl --user restart podman.service'` in a quiet moment). It prints the
  effective `ExecStart`.

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
# service token (should contain realm role `service` and `aud` game-service + athlete-service, never core-service)
curl -s localhost:8080/auth/realms/academy/protocol/openid-connect/token -d grant_type=client_credentials \
  -d client_id=core-service -d client_secret=$CORE_SERVICE_CLIENT_SECRET
```

## Test academy
`just seed-academy` (script `infra/keycloak/seed-academy.sh`, decision 74) creates the academy "Test Academy" (slug
`test-academy`, Europe/Madrid, `es`) through the real API, so the outbox publishes and game/athlete get their roster
replicas: admins `testadmin1`, `testadmin2`; coach `testcoach1` (coach of the team); players `testplayer1` ..
`testplayer10` (each with a PLAYER login, U14, jerseys 4-13); parents `testparentplayer1` .. `testparentplayer10`
(parent N is the guardian of player N only); season "Test Season", team "Test Team". Logins are
`<name>@hoops-academy.com`, first name "Test". All are active and need no verification or password change.
- Needs: stack up (`just up`, `just seed-users`), the three services running (`just services-up`) and in `.env`
  `TEST_ACADEMY_PASSWORD` (>= 12 characters; the realm policy applies) next to the Keycloak and `DEV_USER_PASSWORD`
  values. Core issues temporary passwords; the script then sets the shared password with `kcadm set-password` (not
  temporary), clears required actions, marks the e-mail verified and signs in once as each login (which accepts the
  invitation). Secrets only travel in the environment of `podman exec` and on stdin; nothing is printed.
- Idempotent: it looks things up by slug, e-mail and name; a second run reports "nothing to create" and only resets
  the passwords; an interrupted run is completed by the next one. A run takes about 70 s (the gateway limits `/auth`
  to 60 requests/min; the script waits out a 429).
- At the end it adds `TEST_ACADEMY_USERS=<logins>` to `.env` once (other lines untouched) and prints the logins.
- Local only: it refuses a base URL (`SEED_ACADEMY_BASE_URL`, default `http://localhost:8080`) that is not
  `localhost` / `127.0.0.1` unless `SEED_ACADEMY_ALLOW_REMOTE=1`.
- Remove: sign in as `superadmin@hoops-academy.com` and `POST /platform/tenants/{id}/withdraw` with
  `{"reason": "..."}` (Platform > academy > Withdraw in the app). The slug stays taken afterwards, and the script
  refuses a non-ACTIVE academy; the Keycloak logins remain (delete them in the admin console if needed).

## Troubleshooting
- `Cannot connect to Podman` / compose fails: `podman machine start`, then `source scripts/env.sh`.
- `required variable ... set in .env`: copy `.env.example` to `.env` and fill it.
- Keycloak unhealthy for > 2 min: `just logs keycloak`; usual causes are a bad realm JSON or missing client-secret env.
- Changed a DB role password in `.env` after first start: init scripts only run on an empty volume; reset the volume.
- nginx returns 502 on `/api/*`: the host service is not running on its port (8081/8082/8083).
- Issuer mismatch in a service: it must use exactly `http://localhost:8080/auth/realms/academy`.
