# Roadmap (v2 and beyond)

Sources: `wp/FOLLOW-UPS.md`, the WP handovers, `security/review-2026-11.md`, `PLAN.md`. Items are grouped by theme, not
ordered by date; there are no committed dates. IDs F-nn refer to the security review. "Seam" means the extension point
already exists in v1. The plans of 2026-11-05 (`wp/FOLLOW-UPS.md`, WP26–WP37) and of 2026-11-06/07 (WP38–WP42, third
round WP43–WP51, fourth round WP52–WP71, fifth round WP72–WP90) of 2026-11-10 (sixth round WP91–WP103) and of 2026-11-14 (seventh round WP104–WP110) are done
(all merged by 2026-11-14, except WP109's JDK 25 branch, which waits for the owner); the items they closed are no longer listed here. Hoops Academy is a learning project, not commercial (yet) (ADR-0025): the "if it goes commercial"
items below are deliberately not planned.

## Product and billing
- **Billing.** Seams exist: `billing.plan` (seeded `FREE`), `billing.tenant_subscription`, `EntitlementService.check(tenant,
  PLAYERS|TEAMS)` called from team and player creation with a no-op implementation. Needed: plans and limits, a payment
  provider, subscription lifecycle linked to tenant suspension, an entitlement implementation, an invoice/usage view. Billing
  can subscribe to core's events, which are published to Redpanda since WP67.
- **Tenant purge job.** Withdrawn tenants keep data until `retainUntil` (default 365 days) but nothing deletes it afterwards.
  Needs a platform job, per-schema deletion in FK order, an audit record and a dry-run mode. It is also the only clean-up of
  old audit rows and of decided academy requests (WP90). Also a per-tenant export for data portability (not designed).
- **Landed in the sixth round:** the application admin hub (Academies, Users across academies, Pending approvals,
  Audit trail, a Billing placeholder) and a context switcher between a login's academies and the application admin
  (WP91, WP99, ADR-0049); a member edits their own name (WP91, WP99); a preferred jersey number with carry-over on
  assignment and the taken numbers per team (WP96, WP101); CSV exports of the team roster and the audit trails from
  core and CSV / Excel / ICS exports of player stats, box score and team calendar built in the browser (WP96, WP97,
  WP101, ADR-0048); the exercise catalogue with global and academy exercises (WP92, ADR-0047, athlete 3.0.0).
- **Exports, next steps.** PDF where a printable sheet makes sense (decision 67: later); a name for the audit `team`
  target (shows the type only); the compose nginx has no `limit_req` for the export paths (the gateway limits them).
- **Users area depth.** E-mail change and a temporary password from the application admin's Users list (not in WP99).
- **Landed in the seventh round:** a light / dark / system theme next to the language in the menu behind the avatar
  (WP105); the exercise catalogue for parents and players (WP108); the roster export for ADMIN and the team's current
  coach only (WP106, WP108, ADR-0048 amendment); given and family name per membership in `/me` (WP106, core 3.6.0);
  landing-like demo data in the Test Academy (WP107).
- **Landed in the fifth round:** invitation-only sign-up from the landing page with a super admin workbench and
  decision e-mails (WP90, ADR-0044); read-only history of past seasons for former staff and admins (WP80, ADR-0042);
  sessions that reference any plan directly (WP78, ADR-0041); the whole web app on one design system (WP72–WP77,
  ADR-0040). Sign-up leftovers: a compose `limit_req` for the public path, the purge of decided requests (with the
  purge job above), mail retry.
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
- **Landed in the fifth round (WP81, WP82, WP86):** core's producer recovers by itself after a failed first SASL
  login, every aggregate publishes `.removed` and the replicas apply it as a soft removal, a core backfill
  (`just events-backfill`) completes the topics with pre-WP67 data, retention jobs prune `applied_event` (7 days) and
  inspected `parked_event` rows, and the game flip ran on kind. On compose the replicas equal core and `just e2e` is
  green with `replica` for both services.
- **Landed in the sixth round (WP98, WP100, decision 66):** `replica` is the default roster source of game and
  athlete (services, compose, chart 0.10.0 with events) without the shadow period over days; a drift check
  (`just events-drift [--kind]`) compares core's rows with both replicas; `rest` stays the fallback switch. The shared
  replica code lives in common-quarkus. Core's producer is never created with events off (`CORE_OUTBOX_ENABLED`, WP91).
- **Still open:** game starts on `replica` with its consumer switched off (athlete refuses that combination); the web
  can show the old roster for the 1–2 s of replica lag; Redpanda outside kind is unproven.

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
- **Done in the fifth round:** SAST and DAST gates in CI (SpotBugs + find-sec-bugs in `verify`, CodeQL, Semgrep, ZAP
  API scans; ADR-0045, WP83) and their findings SD-01..SD-08 (7 fixed, SD-03 accepted; WP84); Keycloak login events and
  structured authorization-failure events (ASVS 16.3.1, 16.3.2), a CycloneDX SBOM per image (WP85, ADR-0043); an
  OpenTelemetry collector for traces and logs (16.4.3; WP86, ADR-0046); nginx's double Referrer-Policy on `/auth/` gone
  (WP84).
- **ASVS gaps.** Breached-password check (6.2.12; not now, decision 60), OTP only optional (6.3.3). Smaller: the
  master realm keeps Keycloak's default CSP; Keycloak's log is not shipped over OTLP; the SBOMs are not signed
  (attestation); the ZAP API scan runs as the super admin, not as an academy member.
- **Pins.** Image digests, chart image tags and kind pins are bumped by a weekly PR (WP89); GitHub Actions are pinned to
  commit SHAs and Dependabot waits 7 days for a release (WP50, WP84). Drop the guava pin once the Quarkus BOM ships
  >= 33.7.2 (3.40.1.2 still manages 33.6.0-jre). The service images fail the Trivy gate since 2026-11-14 on 14
  `krb5-libs` findings in the Red Hat base image whose fix is not published: wait or accept with an expiry. Envoy Gateway is on v1.10.0 since WP100. The weekly PR cannot carry workflow-file pins (the Actions token
  may not push workflows): Trivy, Semgrep and the ZAP digest are bumped by hand with `scripts/bump-pins.sh --apply`, or
  a fine-grained token lets the PR include them.
- **json-schema-validator 3.x** (WP43): blocked until the strict OpenAPI validator (ADR-0027) moves to networknt 3.x;
  then drop the Dependabot ignore rule and apply the migration recorded in the WP43 handover.

## Web offline and quality
- **Browser checks.** The mock-mode smoke and the login round trip run in CI (WP55); Lighthouse installability and
  the airplane-mode cold start run by script locally (WP54). Still to do: put those two scripts in CI, check the
  landing's colour contrast, replace a previously registered Flutter worker and the wasm/IndexedDB path in a real
  browser. (The account-console link and the plan refetch on a language change landed in WP76.)
- **Design system leftovers:** the kit follow-ups and the Indonesian bottom navigation landed in WP95; left are kit
  wishes from WP92 (scrolling empty / error views, replacing snack bars, a business-code message registry, a searchable
  multi-select picker), training's own copies of `fabClearance` and pickers, recapturing the landing screenshots
  after the shell and screen changes of the sixth and seventh rounds (owner's wish), and the avatar menu on the academy
  chooser, which has none (WP105).
- Two tabs on one device can allocate the same `clientSeq` (visible `CLIENT_SEQ_CONFLICT`); add a cross-tab lock if it matters.
- **Mutation testing** runs on demand and monthly (WP37, `docs/quality/mutation.md`); since WP88 pure rules are
  extracted from use cases and mappers, the baselines equal the scores, and a Dart tool mutates the web rule code.
  Still outside: athlete's access rules, core's rollover and eligibility engine, the web providers.
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
- **Cloud deployment.** First slice written in the seventh round (WP104, ADR-0050): an OpenTofu module for one k3s VM
  on Alibaba Cloud, Jakarta, with an EIP and an sslip.io name, encrypted local state, and the chart installed by
  `deploy/cloud/install.sh` with `values-cloud.yaml`; proven only with `tofu test` against a mocked provider and a
  render snapshot. Next: the first real apply, install, seed, smoke and destroy (`runbooks/cloud.md`); then TLS
  certificates (cert-manager / Let's Encrypt), real SMTP, CNPG backups to object storage, External Secrets against a
  real store, and the GDPR work before real academies use it. One node, no HA by design of the slice.
- **Java 25.** Built and verified on the branch `jdk-25` (WP109, draft pull request #7, ADR-0003 amendment there); not
  merged until the owner says so.
- **Gateway (WP36, ADR-0031).** The chart runs on Gateway API with Envoy Gateway; the e2e journey is green on kind.
  Rate limits are global since WP40 (ADR-0033: Envoy Gateway's rate limit service + Redis, shared by every Envoy
  replica, fail open); since WP46 Redis has an ACL (only the rate limit user, only `PING`/`INCRBY`/`EXPIRE`) and every
  limited route a per-second burst cap next to its per-minute limit (ADR-0033 amendment, chart 0.4.0); WP63 re-proved
  2 replicas, `tilt ci` and the controller-restart branch. WP100 moved to Envoy Gateway v1.10.0, limited the CSV
  exports and proved a Redis password rotation rolled by Reloader on kind. Still open: an alert when a wrong login
  silently disables the limits, and filing the Envoy Gateway descriptor collision upstream (drafted in `upstream/`;
  re-tested on v1.10.0: not fixed, so the `path: /` selector stays); accepted: no body-size limit at the gateway (the
  services reject > 2 MB); a production certificate and cluster.
- **Secrets.** The chart can source every Secret from the External Secrets Operator (WP65, ADR-0012 amendment) and
  rolls the pods that read a rotated Secret through Stakater Reloader (`global.reloader.enabled`, WP87, ADR-0012
  amendment; proven on kind in WP86). Still open: encryption at rest for Secrets.
- **Backups.** Implement and rehearse CNPG backups (`runbooks/backup-restore.md` is a design).
- **Observability.** An OpenTelemetry collector ships the services' traces and logs (and Envoy's spans) when
  `global.observability.enabled` is set (WP86, ADR-0046; Jaeger in memory on kind); the backend is the environment's.
  Wanted by the owner: one Grafana pod with traces, logs and metrics instead of the in-memory Jaeger. Still open: dashboards, alerting on audit and authz failures (`hoops_authz_denied_total`, WP85), Keycloak, Envoy
  access and Redpanda logs to the collector, metrics stay Prometheus.
- **Mail.** Core sends the sign-up decision e-mails (WP90); since chart 0.10.0 (WP100) the chart sets core's SMTP keys
  (Mailpit on kind, an optional `hoops-smtp` Secret for a real server; ESO has no `hoops-smtp` entry by default).
- **Release.** `ci` and `e2e` are green on GitHub since 2026-11-02 (`images` too until the krb5 findings of 2026-11-14) (NVD key valid, images pushed to ghcr.io per
  commit, each with its SBOM since WP85), `codeql` and `semgrep` since WP83; Dependabot opens weekly grouped update PRs
  (Maven, pub, GitHub Actions pinned to SHAs) and `bump-pins` a weekly PR for base images, chart image tags and kind
  pins (WP89). No release has been cut yet (no git tag): follow `runbooks/release.md`.
- Scale: the usage snapshot job and the eligibility sweep iterate tenants sequentially (fine for tens of tenants); snapshots
  are never pruned.

## Data and history
- Backfill of `REJECTED` for players rejected before core `V8` (they remain `WITHDRAWN`).
- `OPPONENT_FOUL` event type (removed from the box score in contracts 2.0.0 because no source event existed).
- Decide whether a SCHEDULED match should still accept events (`MATCH_NOT_STARTED` is reserved in the contract).
