# Roadmap (v2 and beyond)

Sources: `wp/FOLLOW-UPS.md`, the WP handovers, `security/review-2026-11.md`, `PLAN.md`. Items are grouped by theme, not
ordered by date; there are no committed dates. IDs F-nn refer to the security review. "Seam" means the extension point
already exists in v1. The plans of 2026-11-05 (`wp/FOLLOW-UPS.md`, WP26–WP37) and of 2026-11-06 (WP38–WP42, third
round WP43–WP51) are done (all merged by 2026-11-06); the items they closed are no longer listed here. Hoops Academy is a learning project, not commercial (yet) (ADR-0025): the "if it goes commercial"
items below are deliberately not planned.

## Product and billing
- **Billing.** Seams exist: `billing.plan` (seeded `FREE`), `billing.tenant_subscription`, `EntitlementService.check(tenant,
  PLAYERS|TEAMS)` called from team and player creation with a no-op implementation. Needed: plans and limits, a payment
  provider, subscription lifecycle linked to tenant suspension, an entitlement implementation, an invoice/usage view. Billing
  would subscribe to the outbox events once they are published.
- **Tenant purge job.** Withdrawn tenants keep data until `retainUntil` (default 365 days) but nothing deletes it afterwards.
  Needs a platform job, per-schema deletion in FK order, an audit record and a dry-run mode. Also a per-tenant export for data
  portability (not designed).
- **Super admin who is also a member.** Done in the Profile menu (Platform console); only a product check remains.
- **Parents without a login via the guardian flow.** WP17 covered players only; parents get a login through the member
  invitation. Decide whether a guardian entered with a player should be invited automatically.
- **Edit screens the API already supports.** A match edit dialog (opponent, date, venue; `MatchesRepository.update`
  sends `clear`, WP45), removing a jersey (the dialog still requires a value, WP44), a member's personal data and the
  academy's contact e-mail / website (their `clear` lists are unused by the app, WP44).
- **If it goes commercial (ADR-0025).** F-11 (invite links an existing login without consent and reveals it) and F-22
  (pre-account hijacking) are accepted by design today. Before real users: verify the e-mail before linking an existing
  login into another academy, ask for consent and notify on a link, give invites a uniform response.

## Events and integration (WP19, ADR-0008)
- Transactional outbox in core (the `core.outbox` table is written by use cases today), a polling publisher
  (`FOR UPDATE SKIP LOCKED`), Redpanda single node in compose and Helm, topics `core.person|player|team|team-player|team-staff|
  guardian-link|tenant`.
- Consumers in game and athlete upsert `*_ref` replica tables (with RLS); `RosterPort` replica adapter behind
  `hoops.roster.source=rest|replica`. Acceptance: replica equals core after replay from empty, duplicate delivery idempotent,
  same contract tests pass for both adapters. Removes runtime coupling to core and the 30 s authz staleness.

## Native images
Quarkus native builds for the three services (ADR-0003 calls it an optional later step): faster start and lower memory per
pod, cheaper HPA. Cost: slower CI, reflection configuration for Hibernate and the Keycloak admin client, native test runs.
Start with athlete or game. Also: a pre-built optimized Keycloak image so the pod can use a read-only root file system.

## Push notifications
Not started and not designed. Candidates: web push for the PWA (needs a service-worker push handler, VAPID keys, a
subscription table, consent UI) for training changes, cancelled sessions, plan due dates, approval decisions and
invitation reminders. Depends on events (above) to avoid polling. (The "new version available, reload" prompt for the
service worker exists since WP14b.)

## Security follow-ups (`security/review-2026-11.md`)
- **F-07/F-08 residuals.** WP14b fixed sign-out (F-03: local forget first, Drift wipe, no `offline_access`; ADR-0019). Still
  open: scope cached `roster`/`matchJson`/`ownEvents` by tenant and person and wipe on a subject change; enable
  refresh-token rotation in the realm.
- **F-09/F-10/F-19/F-20** were fixed in WP14b (no CDN, pinned `sqlite3.wasm`, network-only prefixes incl. `/platform`,
  release-build guards; ADR-0018). The network-only prefixes match the Gateway API routes (re-checked 2026-11-06).
- **F-14 token audience.** Audience mapper per service and `quarkus.oidc.token.audience`.
- **ASVS gaps.** Password blocklist (6.2.4) and breached-password check (6.2.12), optional OTP for ADMIN and super admin
  (6.3.3), Keycloak login events (16.3.1), authorization-failure logging (16.3.2), log shipping or an OTel collector
  (16.4.3), SBOM.
- **Image and dependency pins.** The `ubi9/openjdk-21-runtime` digest is pinned (WP30) but not auto-bumped; drop the
  guava pin once the Quarkus BOM ships >= 33.7.2. GitHub Actions are pinned to commit SHAs (WP50).
- **json-schema-validator 3.x** (WP43): blocked until the strict OpenAPI validator (ADR-0027) moves to networknt 3.x;
  then drop the Dependabot ignore rule and apply the migration recorded in the WP43 handover.

## Web offline and quality
- **Chromedriver-based browser tests.** `apps/web/tool/web_smoke.sh` (the `flutter drive` smoke) ran green in mock and
  `--real` modes on 2026-11-02 with a hand-installed chromedriver, and `tool/browser_login_check.py` covers the login
  round trip; both run locally only. Still to do: the Lighthouse installability check and chromedriver in CI.
- **Verify the offline cold start in a real browser**: install/activate/reload of `sw.js` in airplane mode, replacement of a
  previously registered Flutter worker, the wasm/IndexedDB path.
- Two tabs on one device can allocate the same `clientSeq` (visible `CLIENT_SEQ_CONFLICT`); add a cross-tab lock if it matters.
- **Mutation testing** runs on demand and monthly (WP37, `docs/quality/mutation.md`); rule code reached only by
  container tests (`TenantScope`, exception mappers, use cases) is outside PIT's scope until pure rules are extracted.
- List pagination UI and a category filter on `GET /players` (contract); `nameKey`/`locale` for plan templates.
- **Demo mock depth (WP47).** The mocks share one roster and filter by role, but core reads are not role-filtered, the
  demo COACH is fixed to Mini A, `HOOPS_MOCK_ROLES` applies to the demo academy only, and nothing persists across
  reloads.
- **Lint**: `curly_braces_in_flow_control_structures` is disabled since the `dart format` pass (WP49); re-enable it
  with a braces-only change if wanted.

## Norms research completion (WP10b → WP27, done 2026-11-05; remainder open)
WP27 sourced 370 of 630 rows (beep test 8-18, sit-and-reach 9-17, 20 m sprint 8-17, T-test and vertical jump 14-15; Cooper
13-19 kept). Still "reference pending": Cooper 8-12 (no youth table found), T-test and vertical jump outside 14-15 (best
lead: Moreno-Gonzalez et al., BMC Pediatr 2026, not fetchable yet), and a few edge ages that repeat the nearest cited
age. The Cooper figures are still not traced to the 1968 paper. Sources, mapping rules and leads: `domain/norms.md`.

## Platform and operations
- **Gateway (WP36, ADR-0031).** The chart runs on Gateway API with Envoy Gateway; the e2e journey is green on kind.
  Rate limits are global since WP40 (ADR-0033: Envoy Gateway's rate limit service + Redis, shared by every Envoy
  replica, fail open); since WP46 Redis has an ACL (only the rate limit user, only `PING`/`INCRBY`/`EXPIRE`) and every
  limited route a per-second burst cap next to its per-minute limit (ADR-0033 amendment, chart 0.4.0). Still open:
  exercising the controller-restart branch of `deploy/kind/up.sh`, re-running the 2-replica check and `tilt ci` on
  0.4.0, a restart-free Redis password rotation and an alert when a wrong login silently disables the limits, and
  reporting the Envoy Gateway descriptor collision upstream (then drop the `path: /` selector); accepted: no body-size
  limit at the gateway (the services reject > 2 MB); a production certificate and cluster.
- **External Secrets Operator manifests** and a rollout trigger for rotated secrets (ADR-0012); encryption at rest for Secrets.
- **Backups.** Implement and rehearse CNPG backups (`runbooks/backup-restore.md` is a design).
- **Observability.** OTel collector and dashboards (traces are off by default), alerting on audit and authz failures.
- **Release.** `ci`, `e2e` and `images` are green on GitHub since 2026-11-02 (NVD key valid, images pushed to ghcr.io per
  commit); Dependabot opens weekly grouped update PRs (Maven, pub, GitHub Actions pinned to SHAs; base images and
  chart image tags stay manual). No release has been cut yet (no git tag): follow `runbooks/release.md`.
- Scale: the usage snapshot job and the eligibility sweep iterate tenants sequentially (fine for tens of tenants); snapshots
  are never pruned.

## Data and history
- Backfill of `REJECTED` for players rejected before core `V8` (they remain `WITHDRAWN`).
- `OPPONENT_FOUL` event type (removed from the box score in contracts 2.0.0 because no source event existed).
- Decide whether a SCHEDULED match should still accept events (`MATCH_NOT_STARTED` is reserved in the contract).
