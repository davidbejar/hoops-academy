# WP139 — Infra, chart, services, scripts: one name for the realm URL everywhere; one login helper for the scripts; database roles from one list

Model: Opus · high. Wave 5 (2026-11-23, ninth round): starts after wave 4 is merged and runs alone: you may touch any
area. You own `infra/**`, `.env.example`, `start.sh`, `stop.sh`, `config/**`, and for the rename the
`application.properties` of the services, `deploy/**`, the `Tiltfile`, `scripts/**`, `.github/**`, `e2e/**`,
`apps/web/tool/**`, the finance and pdf services' configuration and the docs that name the variables. Depends on:
WP136, WP137. Skills: work-package, podman-dev-env, owasp-security, systematic-debugging, test-driven-development,
clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp139-realm-url-one-name-login-helper-db-roles`, branch
`wp139-realm-url-one-name-login-helper-db-roles`.

Decision 110 of 2026-11-23: one variable for the realm URL and one for the admin base URL in every service, compose,
the chart, kind, Tilt, the scripts and `.env.example`, with working defaults; the stale `localhost:8180` goes.
ADR-0071 is reserved for you (write it: the two names, their meaning, the defaults). Do not read or edit the owner's
`.env`: list in the handover exactly which keys the orchestrator must rename or add there.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `infra.md`
(INF-01..12), verification `verify-deploy-infra-ci.md`; X-05 in `cross-cutting.md`, verification
`verify-cross-cutting-libs.md`; DEP-07 in `deploy.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Realm variables (X-05, INF-01, DEP-07)**: first a test or script check that fails while any old name or `8180` is
   left in the tree; then the rename everywhere in one commit per area. `quarkus:dev` of each service starts against
   `just up` with no variable set.
2. **Login helper (INF-02)**: the browser-less PKCE login copied into at least five scripts becomes one sourced shell
   library (and one Python helper if `zap-login.py` needs it); the Java test class stays.
3. **Database roles (INF-03)**: role names listed by hand in about eight places: one list drives the SQL, the password
   scripts and the checks; `just db-role-check` stays green; no password value in git.
4. **Compose**: `mailhog` pinned (not `latest`); INF-04 (dev users once for compose and kind), INF-05 (nginx header
   blocks), INF-06 (hardening and OTel blocks through anchors or `extends`).
5. **The rest**: every other INF finding of your scope.
6. **Added at merge time of WP136 (2026-11-24)**: WP136's kind proof did not reach Ready (the Podman VM was
   overloaded by parallel builds; the chart renders are proven unchanged by the snapshots). You run alone: your
   `deploy/kind/up.sh --deploy`, `deploy/kind/seed-users.sh` and `deploy/kind/smoke.sh core game athlete` are also the
   proof of chart 0.14.0, the library chart `hoops-lib` and the one pins file of WP136 (read its Handover and
   ADR-0068). If it fails for a reason that is WP136's, fix it and say so. Also correct the comment in
   `.github/dependabot.yml` that still names `up.sh` for the kind pins.

Not yours: DEP-04 (the chart's copies of `infra/` files stay; run `scripts/sync-chart-files.sh` after changing a
source and bump the chart version if a rendered value changes).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just test-go` and `just test-rust` green if their configuration changed
- [ ] `just down && just up`, then `just isolation-check`, `just db-role-check` green on a fresh stack
- [ ] `deploy/helm/tests/run.sh` green (snapshots updated only for the renamed variables: show the diff summary);
      `deploy/kind/up.sh --deploy` and `smoke.sh` green
- [ ] the e2e journey on compose: run it, or say exactly why it could not run so the orchestrator does
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
- **Built** (red tests committed before each change; ADR-0071, amendments to ADR-0006 and ADR-0055):
  - **Realm variables (X-05, INF-01, DEP-07; decision 110)**: `OIDC_AUTH_SERVER_URL` = the realm (default
    `http://localhost:8080/auth/realms/academy`), `KEYCLOAK_ADMIN_URL` = the Keycloak base of the Admin API (default
    `http://localhost:8080/auth`). The two Quarkus realm keys live once in common-quarkus' `microprofile-config.properties`
    (no service sets them; game's and athlete's `localhost:8180` default is gone); core's admin client and the e2e
    suite's `KeycloakAdmin` read `KEYCLOAK_ADMIN_URL` (was `KEYCLOAK_URL` / `E2E_KEYCLOAK_ADMIN_URL`).
    `services-up.sh` exports neither (the defaults fit compose); `.env.example` documents both, commented. Chart 0.15.0:
    `global.quarkusEnv` carries the CORS allow-list and the in-cluster realm URL once for core, game and athlete
    (DEP-07; merged before each service's `env` by the `hoops-service` ConfigMap); core's env has `KEYCLOAK_ADMIN_URL`.
    compose sets the in-network realm URL once for pdf and finance (`x-service-env`). Guards:
    `scripts/tests/test_realm_variables.py` (no old name or `8180` in a tracked file outside ADRs and WP records),
    `LibraryDefaultsContract` (default, the variable followed, the old name ignored), core's `KeycloakAdminUrlTest`.
  - **Login helper (INF-02)**: `scripts/lib/oidc-login.sh` (`oidc_login ISSUER REDIRECT USER PASSWORD_VARIABLE [SCOPE]`,
    returns 1 / 2 on refusal / 429, sets `OIDC_ACCESS_TOKEN` and `OIDC_REFRESH_TOKEN`), sourced by `events-backfill.sh`,
    `seed-academy.sh`, `deploy/kind/smoke.sh` and `apps/web/tool/keycloak_login_check.sh`; each keeps its scopes. Bugs
    fixed on the way: events-backfill and smoke sent the password unencoded in the form body (a `&` or `+` broke the
    login), keycloak_login_check put it on curl's command line; all four now check the returned `state`. Tested against
    a stub Keycloak (`test_oidc_login.py`). `zap-login.py` is the only Python copy and the Java classes stay (brief).
  - **Database roles (INF-03)**: the rows between `-- roles: begin` / `-- roles: end` of `01_roles_schemas.sql` (role,
    search-path schemas, connection limit, migrator) drive one `do` block (attributes, limit, connect, `app` usage,
    `enable_tenant_rls` for migrators, search path, marker comment `hoops service role`). `02_passwords.sh` sets
    `<ROLE>_PASSWORD` for every marked role, all required, values on psql's stdin; `infra/compose/finance-db.sh` became
    `infra/compose/db-roles.sh` (re-applies the SQL, runs `02_passwords.sh` in the container; `just finance-up`,
    `services-up.sh`); `infra/db/roles.sh` prints the list (images workflow's finance check); `TestRolePasswords`
    (via new `BootstrapRoles`) and Go `pgtest.BootstrapRoles` read the SQL; compose requires finance's passwords;
    `test_db_roles.py` checks the literal lists (compose, `.env.example`, chart CNPG roles + limits and Secrets, kind).
  - **Compose / nginx (INF-05, INF-06, INF-09, mailhog)**: `x-hardened` and `x-service-env` anchors; mailhog
    `v1.0.1@sha256:8d76a3d4…` (the digest `latest` pointed at; amd64-only, as before); `nginx/common-headers.conf` with
    the four shared headers; `upstream core|game|athlete|finance`; the two core export regexes merged. `run.sh` reads the
    hardening from the anchor.
  - **Keycloak (INF-04, INF-07)**: `infra/keycloak/dev-users.sh` (the six dev users, run inside the container) for
    compose's and kind's `seed-users.sh`, secrets on stdin for both; the retrofit keeps its steps but reads the realm
    file through one `realm_file PART` helper and one `client_id_of`.
  - **Scripts (INF-12)**: `scripts/lib/stack.sh` (`WEB_PORT`, `service_port`, `JAVA_SERVICES`, `machine_running`) for
    `start.sh`, `stop.sh`, `doctor.sh`, `services-up.sh`. `.github/dependabot.yml` names `deploy/lib/platform.sh` and
    `kind-config.yaml` for the pins (scope 6).
- **Verified**:
  - Fresh database: old and new bootstrap in two throwaway `postgres:17` containers (`.env.example`-like passwords, one
    with `'`, `"` and `\`): roles, attributes, limits, role settings, database / schema / function ACLs and default
    privileges identical (43 rows); every role logs in; a re-run changes nothing; a missing variable stops
    `02_passwords.sh`. compose `config` (all profiles, `.env.example`) identical before/after except the mailhog image.
    nginx: old and new config in throwaway `nginx:1.30-alpine` containers (stub Keycloak on a private network): `nginx -t`
    ok, response headers of `/`, `/redirect.html`, `/internal/x`, `/auth/admin/`, `/auth/realms/master/x`, three
    Keycloak and seven API paths identical.
  - **Kind proof (also WP136's chart 0.14.0 → 0.15.0, `hoops-lib`, `deploy/lib/platform.sh`)**: `deploy/kind/up.sh --deploy
    --from-host` created the cluster, installed Reloader, Envoy Gateway v1.10.0 / Gateway API v1.6.1, CNPG 1.30.1, built
    and loaded all six images; `helm --wait` then failed on Keycloak's progress deadline (Podman VM load 31 on 2 CPUs:
    Keycloak's first start re-augments for 150 s and the probes restarted it twice, not a chart fault). Once it was Ready
    the same `helm upgrade --install` completed (revision 2, `deployed`, the redpanda-bootstrap hook ran).
    `deploy/kind/seed-users.sh` (the shared `dev-users.sh`) created the six users; `deploy/kind/smoke.sh core game
    athlete`: **SMOKE PASSED, 57 checks** (gateway, issuer, deny routes, broker SASL/ACLs, token audiences, superadmin,
    admin1 and coach1 PKCE logins through the helper, events into both replicas, finance isolation and `finance_app`
    role, pdf-service). Its first run failed one check: my refactor had dropped smoke's `user_token`; fixed after a red
    test. The CNPG database has the same roles, privileges and settings as compose's (owner `app`; CNPG clears the role
    comment). Cluster deleted.
  - `quarkus:dev` with no variable: the fast-jars of core, game and athlete (prod profile; no `%dev` realm key exists,
    so dev mode resolves the same default) started with no `OIDC_AUTH_SERVER_URL` / `KEYCLOAK_*` set, against a
    throwaway database and the running compose Keycloak: each answered a forged token with 401 after asking
    `http://localhost:8080/auth/realms/academy` (introspection of the unknown key), i.e. the default reached the realm.
    `mvn quarkus:dev -pl <svc>` itself could not be started from this worktree (the reactor's common-quarkus test-jar is
    not in `~/.m2`; installing it would have changed other checkouts' builds).
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh, 13:01 min): BUILD SUCCESS; contracts 346,
    common-quarkus 580, game 528, athlete 1026, core 1262, e2e 38 (32 skipped); 0 failures. The first run found 4
    failures in `InvalidTokenEventsTest` (the public-key test issuer discovered compose's Keycloak through the new
    library default): fixed in `LocalTokenIssuer`.
  - `just test-go`: green, 15 packages, coverage 88.66 % / 98.84 % (domain), govulncheck clean. `just test-rust` not
    run: nothing of pdf-service changed (compose's resolved config for it is identical).
  - `python3 -I -m unittest discover -s scripts/tests`: 108 tests OK (1 skipped, online). Shell tests: tenancy-gate
    55/55, doctor drop-in 5/5, env-jdk 3/3. `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (kubeconform 397/397).
    Snapshot diff summary: umbrella-default/-tls/-kind/-cloud: 12 lines each, only `KEYCLOAK_URL` →
    `KEYCLOAK_ADMIN_URL` (core) / `OIDC_AUTH_SERVER_URL` (game, athlete) and the three env checksums; umbrella-kind
    additionally the databases ConfigMap body (the synced SQL, 39+/45-); eso and the service snapshots unchanged.
  - `just isolation-check` (worktree, by hand): 6 tests + 4 finance Go tests passed. `just db-role-check`: 13 tests +
    2 finance Go tests passed. `just docs-build` (strict): no issues. gitleaks on every commit: no leaks.
- **Not run (orchestrator, from the main checkout after the merge)**: the fresh compose stack and the e2e journey. The
  running compose stack is the owner's and my brief forbids `just down` against it; compose.yaml fixes the project name,
  container names and ports, so no second project could run beside it. Commands: `just down && podman volume rm
  hoops_pgdata && just up && just seed-users` (only if a fresh database is wanted; otherwise `just finance-up` brings
  the roles of the existing database up to date through `db-roles.sh`), then `just isolation-check`, `just
  db-role-check`, `just e2e` (needs `HOOPS_EXPOSE_KC_ADMIN=true`), and `apps/web/tool/keycloak_login_check.sh`.
- **`.env` keys for the orchestrator** (I did not read `.env`): rename `KEYCLOAK_URL` → `KEYCLOAK_ADMIN_URL` and
  `E2E_KEYCLOAK_ADMIN_URL` → `KEYCLOAK_ADMIN_URL` if present (values unchanged; with the compose defaults both can
  simply be deleted). `OIDC_AUTH_SERVER_URL` keeps its name. `FINANCE_MIGRATOR_PASSWORD` and `FINANCE_APP_PASSWORD` are
  now required by `just up` (compose `:?`): add them if missing (any value for a new volume; on an existing volume the
  values `just finance-up` used). Nothing else changes. A private `deploy/helm/hoops/values-local.yaml` that sets
  `KEYCLOAK_URL` in a service's `env` must rename it the same way.
- **Decisions/ADRs**: ADR-0071 (the two names, meanings, defaults; README line appended); ADR-0006 amendment (the one
  role list); ADR-0055 amendment (finance's passwords required, `db-roles.sh`).
- **Open points / follow-ups**:
  - `db-roles.sh` re-applies every role's password from `.env` (not only finance's): if `.env` and the database
    disagree, the database follows `.env`, which is what the services read anyway.
  - INF-07: the retrofit stays until the owner's Keycloak volume is rebuilt from the current realm file; then delete
    it from `infra/keycloak/seed-users.sh` (the memory rule says to do that yourself; I may not touch the owner's stack).
  - kind under load: Keycloak's first start re-augments (~150 s at load 30) and the probes restarted it twice, so
    `helm --wait` hit the Deployment's progress deadline; a longer `startupProbe` or `progressDeadlineSeconds` for
    Keycloak on kind would make `up.sh --deploy` robust on a busy 2-CPU VM.
  - MailHog has no newer release than v1.0.1 (2020, amd64 only); kind already uses Mailpit. Moving compose to Mailpit
    would need the e2e `MailSink` (it already speaks both APIs) and the docs; not done here.
  - Docs that list `finance-db.sh` historically (ADR-0055 body, WP118) were left as records.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| X-05 | Done | `OIDC_AUTH_SERVER_URL` in the library for all Quarkus services, 8180 gone, ADR-0071 |
| INF-01 | Done | as X-05; `KEYCLOAK_ADMIN_URL` for core and the e2e suite; chart, compose, `services-up.sh`, READMEs |
| DEP-07 | Done | `global.quarkusEnv` (CORS allow-list, realm URL) once for the three Quarkus services; DB URLs, `HOOPS_CORE_URL` and `PDF_SERVICE_URL` stay per service (different keys or two of three services) |
| INF-02 | Done | `scripts/lib/oidc-login.sh` for four scripts; password encoding and state check fixed; no Python helper needed (one Python copy) |
| INF-03 | Done | one role list in the SQL drives grants, `02_passwords.sh`, `db-roles.sh`, `roles.sh`, the Java and Go harnesses; literal lists tested |
| INF-04 | Done | `infra/keycloak/dev-users.sh` for compose and kind, secrets on stdin for both |
| INF-05 | Done | `nginx/common-headers.conf`; headers byte-equal before/after |
| INF-06 | Done (as corrected) | `x-hardened`, `x-service-env`; `container_name` and `restart` kept (verification) |
| INF-07 | Done (minimum) | one `realm_file` reader and `client_id_of`; deleting the retrofit needs the owner's volume rebuilt |
| INF-08 | Done (guard) | realm JSON kept (verification: only worth with a fourth client); `test_local_stack.py` checks every audience mapper has one shape and name |
| INF-09 | Done | four `upstream`s, one core export location |
| INF-10 | Skipped | done by WP136 (DEP-03, delta snapshots and blocklist pointer); the chart copy is DEP-04 |
| INF-11 | Skipped | PARTLY: outputs are the runbook's summary and asserted by the tofu tests; merging the rules renames resources (`moved` blocks) for no behaviour change; not touched otherwise |
| INF-12 | Done | `scripts/lib/stack.sh` |
| Scope 4 mailhog | Done | `v1.0.1@sha256:8d76a3d4…` |
| Scope 6 | Done | kind proof of chart 0.15.0 / `hoops-lib` / `platform.sh`: deployed, seed-users, smoke 57 checks passed; dependabot comment fixed |
