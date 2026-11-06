# Hoops Academy

Multitenant web platform (mobile-first PWA) for basketball academies. Each academy is a fully isolated tenant. The UI is
available in Spanish, English and Indonesian.

- **Roster and eligibility**: seasons, age categories, teams, players, play-up rules, approvals, season rollover.
- **Live match statistics**: box-score entry that keeps working offline and syncs later, several scorers per match.
- **Training**: calendar, attendance, planned absences, plans and completion.
- **Athlete health and fitness**: injuries and availability, height/weight growth, physical tests against age norms.

## Features by role
| Role | What they do |
|---|---|
| Super admin | create, suspend, reactivate and withdraw academies; add, edit and remove each academy's administrators; see usage per service |
| Administrator | academy profile and logo, members and invitations, guardian links, seasons, categories, teams and staff, player approvals, eligibility cases, rollover, age rule and play-up limit |
| Coach | match setup and live scoring, training calendar, attendance, plans, health and fitness entries, requests to add or withdraw players |
| Assistant coach | the same for matches, training and health; read-only on roster, no player requests |
| Parent | linked children: stats during matches, absences, plan completion, injuries and measurements |
| Player | own profile, season stats, plans, absences, health history (read-only) |

## Stack
Java 21, Quarkus 3 (three services: `core`, `game`, `athlete`), PostgreSQL 17 with row-level security (one database, one
schema per service), Keycloak (authentication only), Flutter Web PWA (Riverpod, Drift offline store), OpenAPI contracts
with generated Dart clients, Podman, kind + Helm + Tilt, CloudNativePG. No Node anywhere.

## Quick start
Prerequisites are installed by the bootstrap script (macOS with Homebrew; Podman machine running).
```bash
scripts/bootstrap.sh                 # toolchain (JDK 21, Maven wrapper, Podman, Flutter, just, ...)
source scripts/env.sh && just doctor # JDK 21 + Podman socket for Testcontainers; toolchain check
cp .env.example .env                 # replace every change-me-* value (git-ignored)
just up                              # Postgres, Keycloak, MailHog, nginx on http://localhost:8080
just seed-users                      # e-mail logins <name>@hoops-academy.com: superadmin, admin1, coach1, assistant1, parent1, player1 (DEV_USER_PASSWORD)
```
`DEV_USER_PASSWORD` in `.env` is the plain login password for all seeded users (Keycloak stores only its hash). To change
it, edit `.env` (at least 12 characters) and re-run `just seed-users`; it resets every seeded user's password.

**One command:** once `.env` is filled, `./start.sh` does everything below: it starts the Podman machine if needed,
sources `scripts/env.sh`, runs `just up`, `just seed-users` and `just services-up`, then the web app on
http://localhost:5173. Flags:

| Flag | Web app |
|---|---|
| *(none)* | debug run in a Chrome window that Flutter opens (hot reload and debugging are tied to that window). Other Chrome tabs on the same URL also run it (`apps/web/tool/browser_login_check.py` drives one); Safari stays blank, use `--release` |
| `--web-server` | debug run without a browser; open http://localhost:5173 in any browser yourself (hot reload; debugging outside Chrome is limited) |
| `--release` | release build with `tool/build_web.sh` (as in production, no CDN), served by `python3 -m http.server`; the reliable choice for Safari and other browsers, no hot reload (rebuild about a minute) |
| `--no-build` | reuse the built service jars (faster); combines with any of the above |

After `--release`, its caching service worker stays registered for http://localhost:5173 and can keep serving that
build in a later debug run: accept the "update available" banner, or unregister it (DevTools > Application > Service
workers). Quitting the web app (`q` or Ctrl+C) stops the services; the compose stack keeps running. `./stop.sh` stops everything (web app and its Chrome window, services, compose stack)
from any terminal, whether `start.sh` is still running or was already interrupted; it is safe to run repeatedly and
leaves the Podman machine running.

Or step by step. Start the backend services (host mode; nginx reaches them on 8081 to 8083):
```bash
set -a; source .env; set +a
./mvnw -pl services/core-service    quarkus:dev     # :8081  (one terminal each)
./mvnw -pl services/game-service    quarkus:dev     # :8082
./mvnw -pl services/athlete-service quarkus:dev     # :8083
# or: just services-up   (builds jars, starts all three in the background; just services-down to stop)
```
Start the web app against the stack:
```bash
cd apps/web && flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=HOOPS_API_BASE=http://localhost:8080
```
A demo without any backend: `flutter run -d chrome --web-port 5173 --dart-define=HOOPS_MOCK_API=true`.
After pulling realm changes, reset Keycloak: `just down && podman volume rm hoops_pgdata && just up && just seed-users`.
Create your first academy as `superadmin@hoops-academy.com`: `docs/runbooks/onboard-tenant.md`.

Common commands: `just test` (backend verify with coverage and RLS gates), `just web-test`, `just e2e`, `just scan`,
`just gen-api` (regenerate Dart clients), `just kind-up` and `just tilt` (Kubernetes on kind).

## Layout
```
libs/common-quarkus   tenancy, RLS, authz, Problem+JSON, shared test fixtures
libs/contracts        OpenAPI specs + event JSON Schemas (source of truth for clients)
services/*            core-service, game-service, athlete-service (Quarkus)
apps/web              Flutter Web PWA (generated API clients in apps/web/packages)
infra/                compose stack, DB init SQL, Keycloak realm
deploy/               Helm charts, container files, kind scripts; Tiltfile at the root
e2e/                  journey tests against the running stack
docs/                 guides, runbooks, architecture, ADRs, security, work packages
```

## Documentation
| | |
|---|---|
| User guides (es / en / id) | [`docs/guides/`](docs/guides): `admin`, `coach`, `parent`, `player`, `super-admin` as `<role>.<lang>.md` |
| Architecture and diagrams | [`docs/architecture.md`](docs/architecture.md) |
| Plan, original requirements, conformance | [`docs/PLAN.md`](docs/PLAN.md), [`docs/SPEC.md`](docs/SPEC.md), [`docs/conformance.md`](docs/conformance.md) |
| Decisions | [`docs/adr/`](docs/adr/README.md) (index) |
| Domain rules | [`docs/domain/`](docs/domain): authz matrix, glossary, norms |
| Runbooks | [`docs/runbooks/`](docs/runbooks): [local stack](docs/runbooks/local-stack.md), [onboard tenant](docs/runbooks/onboard-tenant.md), [rotate secrets](docs/runbooks/rotate-secrets.md), [backup/restore (design)](docs/runbooks/backup-restore.md), [release](docs/runbooks/release.md), [kind](docs/runbooks/kind.md), [e2e](docs/runbooks/e2e.md), [troubleshooting](docs/runbooks/troubleshooting.md) |
| Security | [`docs/security/`](docs/security): [review](docs/security/review-2026-11.md), [threat model](docs/security/threat-model.md), [ASVS checklist](docs/security/asvs-checklist.md) |
| Roadmap, plan and open items | [`docs/roadmap.md`](docs/roadmap.md), [`docs/wp/FOLLOW-UPS.md`](docs/wp/FOLLOW-UPS.md) (plans of 2026-11-05 and 2026-11-06), [`docs/HANDOVER.md`](docs/HANDOVER.md) (current state) |
| Agent conventions | [`CLAUDE.md`](CLAUDE.md) |

## Project status
Hoops Academy is a learning project, not a commercial product (ADR-0025). Work packages **WP0–WP42 are done**, with
handovers in `docs/wp/` (WP19, the optional events/Redpanda package, and billing are not built). As of 2026-11-06:
backend `./mvnw verify` runs **2,019 JVM tests** green (plus 4 e2e unit tests; the 21 journey tests are skipped without
a running stack) and `flutter test` **646 tests**; the 21-step e2e journey is green on a compose stack (CI `e2e`
workflow) and on kind, including its mail checks (Mailpit). Contract versions: core 2.6.0, game 2.1.0, athlete 2.1.0,
common 1.1.0. The Helm chart (0.3.0) uses Gateway API with Envoy Gateway (ADR-0031) and global per-IP rate limits shared
by every Envoy replica through Envoy's rate limit service and Redis (ADR-0033); `tilt ci` is green on kind. Mutation
testing (PIT) runs on demand with `just mutation` and in the `mutation.yml` workflow (manual + monthly), never in every
build (scores 99.1–100 %, athlete 430/430 after WP39; `docs/quality/mutation.md`). 370 of 630 fitness norm rows are
cited from published tables; the rest are flagged "reference pending" (`docs/domain/norms.md`). The CI workflows `ci`,
`e2e` and `images` are green on `main` (the four images go to ghcr.io, public); Dependabot opens weekly grouped update
PRs for Maven, pub and GitHub Actions, with automated security fixes on. The demo mode (`HOOPS_MOCK_API=true`) reaches
every screen, the platform console included. The browser smoke (`apps/web/tool/web_smoke.sh`) runs locally, not in CI;
the Lighthouse and airplane-mode checks have not been run. Open items: [`docs/wp/FOLLOW-UPS.md`](docs/wp/FOLLOW-UPS.md);
current state: [`docs/HANDOVER.md`](docs/HANDOVER.md); what the system does for each spec statement, with evidence:
[`docs/conformance.md`](docs/conformance.md).

## License
GNU Affero General Public License v3.0 ([LICENSE](LICENSE)): anyone who runs a modified version as a network service
must make their changes available under the same terms.
