# Roadmap (v2 and beyond)

Sources: `wp/FOLLOW-UPS.md`, the WP handovers, `security/review-2026-11.md`, `PLAN.md`. Items are grouped by theme, not
ordered by date; there are no committed dates. IDs F-nn refer to the security review. "Seam" means the extension point
already exists in v1. The plans of 2026-11-05 (`wp/FOLLOW-UPS.md`, WP26–WP37) and of 2026-11-06 (WP38–WP42, third
round WP43–WP51, fourth round WP52–WP71) are done (all merged by 2026-11-06); the items they closed are no longer
listed here. Hoops Academy is a learning project, not commercial (yet) (ADR-0025): the "if it goes commercial"
items below are deliberately not planned.

## Product and billing
- **Billing.** Seams exist: `billing.plan` (seeded `FREE`), `billing.tenant_subscription`, `EntitlementService.check(tenant,
  PLAYERS|TEAMS)` called from team and player creation with a no-op implementation. Needed: plans and limits, a payment
  provider, subscription lifecycle linked to tenant suspension, an entitlement implementation, an invoice/usage view. Billing
  can subscribe to core's events, which are published to Redpanda since WP67.
- **Tenant purge job.** Withdrawn tenants keep data until `retainUntil` (default 365 days) but nothing deletes it afterwards.
  Needs a platform job, per-schema deletion in FK order, an audit record and a dry-run mode. Also a per-tenant export for data
  portability (not designed).
- **Super admin who is also a member.** Done in the Profile menu (Platform console); only a product check remains.
- **Invitation-only sign-up** (decision 51). The landing page (WP70) has a placeholder form; the real flow is a stored
  request (name, e-mail, role, academy name), a super admin workbench to accept or reject, and acceptance running the
  existing "create academy" logic with a temporary password. Open: who becomes ADMIN when a parent or coach asks for a
  new academy (`wp/FOLLOW-UPS.md`).
- **History of past seasons for coaches.** Since WP58 coaches lose access to teams of ended seasons; a read-only rule
  for past seasons is not designed.
- **If it goes commercial (ADR-0025).** F-11 (invite links an existing login without consent and reveals it) and F-22
  (pre-account hijacking) are accepted by design today. Before real users: verify the e-mail before linking an existing
  login into another academy, ask for consent and notify on a link, give invites a uniform response.

## Events and integration (ADR-0008, ADR-0036, ADR-0037)
- **Built (fourth round, WP66–WP69, WP71):** core's transactional outbox and polling publisher (`FOR UPDATE SKIP
  LOCKED`, order per aggregate, at least once), one Redpanda node in compose, chart and Dev Services with topics
  `core.person|player|team|team-player|team-staff|guardian-link|tenant` (compacted, SASL/SCRAM per service in the
  chart), and roster replicas in game and athlete behind `hoops.roster.source=rest|replica` (replay from empty equals
  core, duplicates idempotent, the same contract tests on both adapters). The chart wires the services behind
  `events.enabled` + `global.events.enabled` (0.7.0); on kind an event reaches both replicas in under a second.
- **Still to do before `replica` is the default:** a core backfill that publishes every aggregate older than WP67, a
  fix so core's producer recovers when the broker users appear after it started, a shadow period (parked 0, lag in
  seconds), the game flip on kind, then flip the defaults. Housekeeping: prune `applied_event`, a retention for
  `parked_event`. That removes the runtime coupling to core and the 30 s authz staleness.

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
- **Done in the fourth round:** F-07 (match cache keyed by tenant and person, wipe on a subject change; WP54), F-08
  and F-14 (refresh-token rotation, an audience per service; WP56, ADR-0034), F-24 and ASVS 6.2.4 (realm CSP, password
  blocklist, optional OTP; WP57, ADR-0038).
- **ASVS gaps.** Breached-password check (6.2.12), OTP only optional (6.3.3), Keycloak login events (16.3.1),
  authorization-failure logging (16.3.2), log shipping or an OTel collector (16.4.3), SBOM. Smaller: the master realm
  keeps Keycloak's default CSP; nginx sends a second Referrer-Policy on `/auth/`.
- **Image and dependency pins.** The `ubi9/openjdk-21-runtime` digest is pinned (WP30) but not auto-bumped; drop the
  guava pin once the Quarkus BOM ships >= 33.7.2. GitHub Actions are pinned to commit SHAs (WP50).
- **json-schema-validator 3.x** (WP43): blocked until the strict OpenAPI validator (ADR-0027) moves to networknt 3.x;
  then drop the Dependabot ignore rule and apply the migration recorded in the WP43 handover.

## Web offline and quality
- **Browser checks.** The mock-mode smoke and the login round trip run in CI (WP55); Lighthouse installability and
  the airplane-mode cold start run by script locally (WP54). Still to do: put those two scripts in CI, check the
  landing's colour contrast, replace a previously registered Flutter worker and the wasm/IndexedDB path in a real
  browser, the account-console link in the profile menu, refetch plans when the UI language changes.
- Two tabs on one device can allocate the same `clientSeq` (visible `CLIENT_SEQ_CONFLICT`); add a cross-tab lock if it matters.
- **Mutation testing** runs on demand and monthly (WP37, `docs/quality/mutation.md`); rule code reached only by
  container tests (`TenantScope`, exception mappers, use cases) is outside PIT's scope until pure rules are extracted.
- List pagination UI and a category filter on `GET /players` (contract).
- **Demo mock depth (WP47, WP53).** Role-filtered core reads, the demo user on the staff list and persistence across
  reloads are done; members stay ADMIN-only, replay re-stamps timestamps, no suspended-tenant behaviour.
- **Lint**: `curly_braces_in_flow_control_structures` is disabled since the `dart format` pass (WP49); re-enable it
  with a braces-only change if wanted.

## Norms research completion (WP10b → WP27 → WP62; remainder open)
WP27 sourced 370 of 630 rows, WP62 475 of 630 (Cooper 8-12 Balague 1982, T-test 12-13 Lesinski 2020, vertical jump
12-17 Leone 2025, on top of the beep test 8-18, sit-and-reach 9-17, 20 m sprint 8-17, T-test and vertical jump 14-15 and
Cooper 13-19). Still "reference pending" (155 rows): T-test and vertical jump 8-11 (best lead: Moreno-Gonzalez et al.,
BMC Pediatr 2026, not fetchable yet), T-test 16-18 and girls' jump 17-18 repeating the nearest cited age, sit-and-reach
8 and 18, sprint 18. The Cooper teenage figures are still not traced to a primary source. Sources, mapping rules and
leads: `domain/norms.md`.

## Platform and operations
- **Gateway (WP36, ADR-0031).** The chart runs on Gateway API with Envoy Gateway; the e2e journey is green on kind.
  Rate limits are global since WP40 (ADR-0033: Envoy Gateway's rate limit service + Redis, shared by every Envoy
  replica, fail open); since WP46 Redis has an ACL (only the rate limit user, only `PING`/`INCRBY`/`EXPIRE`) and every
  limited route a per-second burst cap next to its per-minute limit (ADR-0033 amendment, chart 0.4.0); WP63 re-proved
  2 replicas, `tilt ci` and the controller-restart branch. Still open: a restart-free Redis password rotation and an
  alert when a wrong login silently disables the limits, and filing the Envoy Gateway descriptor collision upstream
  (drafted in `upstream/`; then drop the `path: /` selector); accepted: no body-size limit at the gateway (the
  services reject > 2 MB); a production certificate and cluster.
- **Secrets.** The chart can source every Secret from the External Secrets Operator (WP65, ADR-0012 amendment). Still
  open: a rollout trigger for rotated secrets (Reloader or similar), the broker Secrets' manual pod restart,
  encryption at rest for Secrets.
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
