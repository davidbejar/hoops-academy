# Hoops Academy

Multitenant web platform (mobile-first PWA) for basketball academies. Each academy is a fully isolated tenant. The UI is
available in Spanish, English and Indonesian.

- **Roster and eligibility**: seasons, age categories, teams, players, play-up rules, approvals, season rollover.
- **Live match statistics**: box-score entry that keeps working offline and syncs later, several scorers per match.
- **Training**: calendar, attendance, planned absences, plans and completion, an exercise catalogue.
- **Exports**: CSV of the team roster and the audit trail; CSV, Excel and calendar (ICS) files of stats and schedules.
- **Athlete health and fitness**: injuries and availability, height/weight growth, physical tests against age norms.

## Features by role
| Role | What they do |
|---|---|
| Super admin | an application admin hub: accept or reject academy requests from the landing page, create, suspend, reactivate and withdraw academies; add, edit and remove each academy's administrators; find any login and its academies (Users); see usage per service; export the platform audit trail; switch to an academy the login belongs to |
| Administrator | academy profile and logo, members and invitations, guardian links, seasons, categories, teams and staff, jersey numbers (preferred number, taken and free numbers), player approvals, eligibility cases, rollover, age rule and play-up limit; roster and audit trail exports |
| Coach | match setup and live scoring, training calendar, attendance, plans and the exercise catalogue, health and fitness entries, requests to add or withdraw players, players' preferred jersey numbers, exports of their teams' roster, stats and calendar; past seasons of teams they coached, read-only |
| Assistant coach | the same for matches, training and health; read-only on roster, no player requests |
| Parent | linked children: stats during matches, absences, plan completion, injuries and measurements, a jersey number wish |
| Player | own profile, season stats, plans, absences, health history (read-only), a jersey number wish |

Every member edits their own first and last name in Profile; a login in several academies switches between them.

## Stack
Java 25, Quarkus 3 (three services: `core`, `game`, `athlete`), PostgreSQL 17 with row-level security (one database, one
schema per service), Keycloak (authentication only), Flutter Web PWA (Riverpod, Drift offline store), OpenAPI contracts
with generated Dart clients, Podman, kind + Helm + Tilt, CloudNativePG. No Node anywhere.

## Quick start
Prerequisites are installed by the bootstrap script (macOS with Homebrew; Podman machine running).
```bash
scripts/bootstrap.sh                 # toolchain (JDK 25, Maven wrapper, Podman, Flutter, just, ...)
source scripts/env.sh && just doctor # JDK 25 + Podman socket for Testcontainers; toolchain check
cp .env.example .env                 # replace every change-me-* value (git-ignored)
just up                              # Postgres, Keycloak, MailHog, Redpanda, nginx on http://localhost:8080
just seed-users                      # e-mail logins <name>@hoops-academy.com: superadmin, admin1, coach1, assistant1, parent1, player1 (DEV_USER_PASSWORD)
just services-up && just seed-academy  # optional: "Test Academy" with 23 logins through the real API (TEST_ACADEMY_PASSWORD)
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
`just web-format`, `just gen-api` (regenerate Dart clients), `just kind-up` and `just tilt` (Kubernetes on kind).

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
| Domain rules and models | [`docs/domain/`](docs/domain): authz matrix, glossary, norms; generated ER and class diagrams per service: [core](docs/domain/core-model.md), [game](docs/domain/game-model.md), [athlete](docs/domain/athlete-model.md) (`just diagrams`) |
| Runbooks | [`docs/runbooks/`](docs/runbooks): [local stack](docs/runbooks/local-stack.md), [onboard tenant](docs/runbooks/onboard-tenant.md), [rotate secrets](docs/runbooks/rotate-secrets.md), [backup/restore (design)](docs/runbooks/backup-restore.md), [release](docs/runbooks/release.md), [kind](docs/runbooks/kind.md), [e2e](docs/runbooks/e2e.md), [events](docs/runbooks/events.md), [observability](docs/runbooks/observability.md), [troubleshooting](docs/runbooks/troubleshooting.md) |
| Security | [`docs/security/`](docs/security): [review](docs/security/review-2026-11.md), [threat model](docs/security/threat-model.md), [ASVS checklist](docs/security/asvs-checklist.md), [SAST/DAST](docs/security/sast-dast.md); mutation testing: [`docs/quality/mutation.md`](docs/quality/mutation.md) |
| Roadmap, plan and open items | [`docs/roadmap.md`](docs/roadmap.md), [`docs/wp/FOLLOW-UPS.md`](docs/wp/FOLLOW-UPS.md) (plans of 2026-11-05, the four rounds of 2026-11-06/07 and the sixth round of 2026-11-10), [`docs/HANDOVER.md`](docs/HANDOVER.md) (current state) |
| Agent conventions | [`CLAUDE.md`](CLAUDE.md) |

## Project status
Hoops Academy is a learning project, not a commercial product (ADR-0025). Work packages **WP0–WP103 are done** (no
WP79), with handovers in `docs/wp/` (the sixth round, WP91–WP103, merged on 2026-11-10). As of 2026-11-10: backend
`./mvnw verify` runs **3,347 JVM tests** green (contracts 315, common 403, core 1163, game 467, athlete 999; plus 6 e2e
unit tests, the 26 journey steps are skipped without a running stack) and `flutter test` **1436 tests**; the 26-step
e2e journey is green on a compose stack (CI `e2e` workflow, with a browser login round trip and the ZAP API scans).
Contract versions: core 3.5.0, game 2.3.0, athlete 3.0.0, common 1.1.1; roster event schemas in
`libs/contracts/events`.

- **Sixth round**: the super admin works in an application admin hub (Academies, Users, Pending approvals, Audit
  trail, a Billing placeholder) and a login switches between its academies and the hub (ADR-0049); every member edits
  their own name; players carry a preferred jersey number that the team assignment reuses when free; core exports the
  team roster and the audit trails as CSV (audited, rate-limited) and the browser builds CSV, Excel and ICS files of
  player stats, box scores and team calendars (ADR-0048); an exercise catalogue with global and academy exercises
  feeds plans and sessions (ADR-0047, athlete 3.0.0); generated ER and class diagrams per service with a drift check
  (`just diagrams`); `just seed-academy` seeds a ready-to-use test academy.
- **Design system**: the whole web app takes the landing page's look: tokens, a token-mapped Material 3 theme and a
  shared widget kit with a contrast test (ADR-0040, `apps/web/README.md` "Design system"); the landing page switches
  language in its header and shows screenshots per locale.
- **Sign-up**: visitors request an academy from the landing page; the super admin accepts (the requester becomes the
  first ADMIN with a temporary password) or rejects with a reason, and core e-mails the decision (ADR-0044).
- **Training and history**: a session references any plan or template directly and exercises from the catalogue or
  inside plans are searchable and quick-addable (ADR-0041, ADR-0047); past seasons are readable, never editable, by their former staff and admins
  (ADR-0042).
- **Events, the default roster source**: core publishes its roster changes from the outbox to Redpanda, recovers its
  producer by itself, publishes `.removed` for every aggregate and can backfill older data; game and athlete serve
  `RosterPort` from their own roster replicas (soft removals, retention jobs) by default since 2026-11-10, with
  `hoops.roster.source=rest` as the fallback and `just events-drift` comparing core with both replicas (ADR-0036,
  ADR-0037, ADR-0008 amendments).
- **Security gates**: SpotBugs + find-sec-bugs in `verify`, CodeQL, Semgrep with repository rules and ZAP API scans
  gate CI with expiring acceptances (ADR-0045); the round's findings SD-01..SD-08 are closed (7 fixed, 1 accepted).
  Tokens carry an audience per service and refresh tokens rotate (ADR-0034); Keycloak's pages have a full CSP, a
  password blocklist and optional OTP (ADR-0038); Keycloak login events and one structured event per authorization
  failure in the services (ADR-0043).
- **Supply chain**: a validated CycloneDX SBOM per image, attached to the pushed image as an OCI referrer (ADR-0043);
  GitHub Actions pinned to commit SHAs, Dependabot with a 7-day cooldown, and a weekly `bump-pins` PR for image
  digests, chart tags and kind pins.
- **Kubernetes**: the Helm chart (0.10.0) uses Gateway API with Envoy Gateway v1.10.0 (ADR-0031) and global rate limits through
  Redis with an ACL (ADR-0033), renders the broker behind `events.enabled` (with `global.events.enabled`), can take its
  Secrets from the External Secrets Operator and roll the pods on a rotation with Stakater Reloader
  (`global.reloader.enabled`, ADR-0012 amendments), and ships traces and logs through an OpenTelemetry collector
  (`global.observability.enabled`, ADR-0046); with events on, both services read their replicas; core's mail goes to
  Mailpit on kind; all proven on kind.
- **Quality**: mutation testing (PIT and a Dart tool for the web rule code) runs on demand and monthly against
  baselines equal to the scores (common 337/338, core 925/926, game 525/527, athlete 690/690, web 430/430;
  `docs/quality/mutation.md`). 475 of 630 fitness norm rows are cited from published tables; the rest are flagged
  "reference pending" (`docs/domain/norms.md`). The web app is an installable PWA (Lighthouse PWA score 1,
  airplane-mode cold start checked by script) and its demo mode (`HOOPS_MOCK_API=true`) reaches every screen.

The CI workflows `ci`, `e2e`, `images`, `codeql` and `semgrep` are green on `main`. Not built: billing (a placeholder
screen), the purge job, PDF exports. Open items: [`docs/wp/FOLLOW-UPS.md`](docs/wp/FOLLOW-UPS.md); current state:
[`docs/HANDOVER.md`](docs/HANDOVER.md); what the system does for each spec statement, with evidence:
[`docs/conformance.md`](docs/conformance.md).

## License
GNU Affero General Public License v3.0 ([LICENSE](LICENSE)): anyone who runs a modified version as a network service
must make their changes available under the same terms.
