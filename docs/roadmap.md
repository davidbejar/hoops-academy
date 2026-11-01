# Roadmap (v2 and beyond)

Sources: `wp/FOLLOW-UPS.md`, the WP handovers, `security/review-2026-11.md`, `PLAN.md`. Items are grouped by theme, not
ordered by date; there are no committed dates. IDs F-nn refer to the security review. "Seam" means the extension point
already exists in v1.

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
- **Member e-mail changes** are not synced to Keycloak.
- **Invite of an existing Keycloak account (F-11).** It links without the owner's consent and reveals the account
  (ACCEPTED vs PENDING). Decide on a notification e-mail and a uniform response.

## Events and integration (WP19, ADR-0008)
- Transactional outbox in core (the `core.outbox` table is written by use cases today), a polling publisher
  (`FOR UPDATE SKIP LOCKED`), Redpanda single node in compose and Helm, topics `core.person|player|team|team-player|team-staff|
  guardian-link|tenant`.
- Consumers in game and athlete upsert `*_ref` replica tables (with RLS); `RosterPort` replica adapter behind
  `hoops.roster.source=rest|replica`. Acceptance: replica equals core after replay from empty, duplicate delivery idempotent,
  same contract tests pass for both adapters. Removes runtime coupling to core and the 30 s authz staleness.
- Move the duplicated `CoreReachabilityCheck` (game, athlete) into `common-quarkus`.

## Native images
Quarkus native builds for the three services (ADR-0003 calls it an optional later step): faster start and lower memory per
pod, cheaper HPA. Cost: slower CI, reflection configuration for Hibernate and the Keycloak admin client, native test runs.
Start with athlete or game. Also: a pre-built optimized Keycloak image so the pod can use a read-only root file system.

## Push notifications
Not started and not designed. Candidates: web push for the PWA (needs a service-worker push handler, VAPID keys, a
subscription table, consent UI) for training changes, cancelled sessions, plan due dates, approval decisions and
invitation reminders. Depends on events (above) to avoid polling. A "new version available, reload" prompt for the service
worker is a small separate item.

## Security follow-ups (`security/review-2026-11.md`)
- **F-01 event-feed visibility.** `GET /api/game/matches/{id}/events` returns all players' stat events to PARENT and PLAYER
  members, while the box score hides them. Either filter the feed to own or linked players plus team events, or document it
  as intended and align `domain/authz-matrix.md`. Needs a product decision and a contract note.
- **F-03 web sign-out offline, F-07 offline DB not wiped, F-08 tokens in localStorage.** Forget the user locally before
  end-session, wipe the Drift database on logout or subject change, scope cached `roster`/`matchJson`/`ownEvents` by tenant and
  person, drop `offline_access`, enable refresh-token rotation in the realm.
- **F-09/F-10 web supply chain.** `flutter build web --no-web-resources-cdn` with bundled fonts, then remove gstatic from both
  CSPs; pin the sha256 of `sqlite3.wasm`. F-19/F-20: derive service-worker network-only prefixes from config; fail release
  builds that contain the mock API or an http issuer.
- **F-14 token audience.** Audience mapper per service and `quarkus.oidc.token.audience`.
- **Audit read API.** `core.audit_event` is written but has no endpoint: add ADMIN `GET /api/core/audit-events` (and a
  super-admin view) in the contract, plus a retention job running as `core_migrator`.
- **ASVS gaps.** Password blocklist (6.2.4) and breached-password check (6.2.12), optional OTP for ADMIN and super admin
  (6.3.3), Keycloak login events (16.3.1), authorization-failure logging (16.3.2), log shipping or an OTel collector
  (16.4.3), SBOM.
- Pin the `ubi9/openjdk-21-runtime` tag (trivy DS-0001); drop the guava pin once the Quarkus BOM ships >= 33.7.2.

## Web offline and quality
- **Chromedriver-based browser tests.** Install a chromedriver matching Chrome, then run `apps/web/tool/web_smoke.sh`
  (mock and `--real`), the `flutter drive` smoke, and the Lighthouse installability check. None has ever run.
- **Verify the offline cold start in a real browser**: install/activate/reload of `sw.js` in airplane mode, replacement of a
  previously registered Flutter worker, the wasm/IndexedDB path.
- Two tabs on one device can allocate the same `clientSeq` (visible `CLIENT_SEQ_CONFLICT`); add a cross-tab lock if it matters.
- Calendar uses the device time zone (use the tenant zone from `AuthzSummary.timezone`); availability badge in rosters and
  match setup; usage trend chart once the regenerated package exposes `getTenantUsageHistory`; list pagination UI and a
  category filter on `GET /players` (contract); editing sessions, measurements, results and absences in the UI;
  `nameKey`/`locale` for plan templates; mock mode lacks athlete and platform screens.

## Norms research completion (WP10b)
Only BEEP_TEST ages 9-17 (a school sample, not athletes) and COOPER_12MIN ages 13-19 (a secondary-source table, not traced to
the 1968 paper) are flagged as sourced; everything else is a placeholder shown as "reference pending". Replace with cited
tables (FITNESSGRAM Healthy Fitness Zone, ALPHA-Fit/Eurofit percentiles, published youth vertical-jump and T-test norms),
re-verify the Cooper figures, update `R__physical_test_norms.sql` and `domain/norms.md`. Data work; schema and UI are ready.

## Platform and operations
- **Production ingress.** ingress-nginx is in upstream retirement; choose a Gateway API implementation. Re-check the
  rate-limit, `/internal` 403 and `events:batch` pass-through rules on the new controller.
- **External Secrets Operator manifests** and a rollout trigger for rotated secrets (ADR-0012); encryption at rest for Secrets.
- **Backups.** Implement and rehearse CNPG backups (`runbooks/backup-restore.md` is a design).
- **Observability.** OTel collector and dashboards (traces are off by default), alerting on audit and authz failures.
- **CI proof.** None of the workflows has run on a CI runner; run `ci.yml`, `images.yml`, `e2e.yml`, get an NVD API key for
  dependency-check, publish images to a registry, cut the first release (`runbooks/release.md`).
- **Tiltfile** should call `scripts/sync-chart-files.sh` before rendering the chart.
- Scale: the usage snapshot job and the eligibility sweep iterate tenants sequentially (fine for tens of tenants); snapshots
  are never pruned.

## Data and history
- Backfill of `REJECTED` for players rejected before core `V8` (they remain `WITHDRAWN`).
- `OPPONENT_FOUL` event type (removed from the box score in contracts 2.0.0 because no source event existed).
- Decide whether a SCHEDULED match should still accept events (`MATCH_NOT_STARTED` is reserved in the contract).
