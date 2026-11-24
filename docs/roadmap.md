# Roadmap (v2 and beyond)

Sources: `wp/FOLLOW-UPS.md`, the WP handovers, `security/review-2026-11.md`, `PLAN.md`. Items are grouped by theme, not
ordered by date; there are no committed dates. IDs F-nn refer to the security review. "Seam" means the extension point
already exists in v1. The plans of 2026-11-05 (`wp/FOLLOW-UPS.md`, WP26–WP37) and of 2026-11-06/07 (WP38–WP42, third
round WP43–WP51, fourth round WP52–WP71, fifth round WP72–WP90) of 2026-11-10 (sixth round WP91–WP103), of 2026-11-14 (seventh round WP104–WP110) of 2026-11-15/16 (eighth round
WP111–WP125) and of 2026-11-23/24 (ninth round WP126–WP140, from an audit for duplication and inefficiencies) are done (JDK 25 merged on 2026-11-15); the items they closed are no longer listed here. Hoops Academy is a learning project, not commercial (yet) (ADR-0025): the "if it goes commercial"
items below are deliberately not planned.

## Product and billing
- **Billing.** Seams exist: `billing.plan` (seeded `FREE`), `billing.tenant_subscription`, `EntitlementService.check(tenant,
  PLAYERS|TEAMS)` called from team and player creation with a no-op implementation. Needed: plans and limits, a payment
  provider, subscription lifecycle linked to tenant suspension, an entitlement implementation, an invoice/usage view. Billing
  can subscribe to core's events, which are published to Redpanda since WP67.
  Stays in core, in Java (ADR-0051).
- **Landed in the eighth round:** academy finance in a Go `finance-service` (currency, fee plans with a cadence, dues
  by hand and by a daily job, hand-recorded payments, waivers, expenses, season balance, CSV exports; ADR-0055,
  ADR-0056) with web screens for the administrator, the coach (status only) and families; a stateless Rust
  `pdf-service` rendering the team roster and the match sheet, called by core and game (ADR-0052, ADR-0048
  amendments); language and theme on the academy chooser; the audit `team` target named.
- **Finance, next steps.** The owner's IDR decision (2 minor digits today); retention of finance records (with the
  purge job); the finance leftovers of `wp/FOLLOW-UPS.md` (the `currencyLocked` wording, the web's balance 404 and
  `EXPORT_TOO_LARGE` against the real service); a payment provider stays out by decision. (The family tab reads every
  due since WP129, the mock answers the balance's 404 like the service since WP138.)
- **Tenant purge job.** Withdrawn tenants keep data until `retainUntil` (default 365 days) but nothing deletes it afterwards.
  Needs a platform job, per-schema deletion in FK order, an audit record and a dry-run mode. It is also the only clean-up of
  old audit rows and of decided academy requests (WP90), and should cover finance records once their legal period is
  known. Also a per-tenant export for data portability (not designed).
- **Privacy before real academies** (LINDDUN, WP112, `security/privacy-threat-model.md`): P-01 erasure and a per-person
  export across core, game, athlete and finance; P-02 retention (the purge job above); P-03 deleting old published
  outbox rows; P-04 an audit trail for health writes; P-05 a privacy notice in es / en / id and a DPIA note.
- **Landed in the sixth round:** the application admin hub (Academies, Users across academies, Pending approvals,
  Audit trail, a Billing placeholder) and a context switcher between a login's academies and the application admin
  (WP91, WP99, ADR-0049); a member edits their own name (WP91, WP99); a preferred jersey number with carry-over on
  assignment and the taken numbers per team (WP96, WP101); CSV exports of the team roster and the audit trails from
  core and CSV / Excel / ICS exports of player stats, box score and team calendar built in the browser (WP96, WP97,
  WP101, ADR-0048); the exercise catalogue with global and academy exercises (WP92, ADR-0047, athlete 3.0.0).
- **Exports, next steps.** A paged PDF for teams over the sheet's limits (today the CSV); period scores and the
  opponent's lines on the box score; the browser exports' 10,000-row limit.
- **Users area depth.** E-mail change and a temporary password from the application admin's Users list (not in WP99).
- **Landed in the seventh round:** a light / dark / system theme next to the language in the menu behind the avatar
  (WP105); the exercise catalogue for parents and players (WP108); the roster export for ADMIN and the team's current
  coach only (WP106, WP108, ADR-0048 amendment); given and family name per membership in `/me` (WP106, core 3.6.0);
  landing-like demo data in the Test Academy (WP107).
- **Landed in the fifth round:** invitation-only sign-up from the landing page with a super admin workbench and
  decision e-mails (WP90, ADR-0044); read-only history of past seasons for former staff and admins (WP80, ADR-0042);
  sessions that reference any plan directly (WP78, ADR-0041); the whole web app on one design system (WP72–WP77,
  ADR-0040). Sign-up leftovers: the purge of decided requests (with the purge job above), mail retry.
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
- **Eighth round:** finance-service consumes the same topics into its own replica (Go, franz-go; no birth date or
  gender); game refuses `replica` without its consumer (WP117) and keeps the academy name from `tenant.changed`.
- **Landed in the ninth round (WP126, WP130, WP134, WP131):** game parks a record once (unique position) and reads
  its feed cursor race-free; decoder, consumer loop, meters, bookkeeping stores and retention run are one pipeline in
  common-quarkus with one retry policy (ADR-0062), the membership rule one class there (ADR-0066); finance prunes
  `applied_event` after 7 days (ADR-0063).
- **Still open:** the web can show the old roster for the 1–2 s of replica lag; Redpanda outside kind is unproven;
  `just events-drift` compares neither finance's replica nor game's academy names; finance has no lag metric and no
  `parked_event` retention; the `RosterSource` switch and the test builders of the replicas are still per service.

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
  >= 33.7.2 (3.40.1.2 still manages 33.6.0-jre). The Java images are on distroless Java 25 since WP114 (ADR-0054),
  which cleared the `krb5-libs` findings; the pdf and finance base images are not in `bump-pins` yet. Envoy Gateway is
  on v1.10.0 since WP100. The weekly PR cannot carry workflow-file pins (the Actions token
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
  after the shell and screen changes of the sixth to eighth rounds (owner's wish), and language and theme on the
  profile screen (the chooser has them since WP115).
- Two tabs on one device can allocate the same `clientSeq` (visible `CLIENT_SEQ_CONFLICT`); add a cross-tab lock if it matters.
- **Mutation testing** runs on demand and monthly (WP37, `docs/quality/mutation.md`); since WP88 pure rules are
  extracted from use cases and mappers, the baselines equal the scores, and a Dart tool mutates the web rule code.
  Still outside: athlete's access rules, core's rollover and eligibility engine, the web providers, and the Rust and Go
  services (`cargo-mutants`, `gremlins` candidates). Maintainability: PMD / CPD gate the Java code since WP113.
- A category filter on `GET /players` (contract). (Lists are read whole through `fetchAll` or paged with the kit
  `Pager` since WP129, ADR-0061.)
- **Web test base:** since WP138 every widget and provider test runs the real repositories against the demo mock,
  seeded per test, with no repository fake (ADR-0070). Left from it: the mock answers 403 to a parent's or player's
  read of attendance, computes the age at measurement from a fixed birthday, and `FakeCore` / `FakeAthlete` keep
  their names as data bundles. The season rollover wizard, which sent the opened season as source and target,
  asks for a target season since WP141 (ADR-0072); the mock still ignores `cloneStaff` / `clonePlayers`.
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
  `global.observability.enabled` is set (WP86, ADR-0046); since WP120 it also scrapes metrics and sends all three to one
  Grafana LGTM pod on kind and in a compose profile (24 h retention, anonymous Viewer, three dashboards); the cloud
  values keep the in-memory Jaeger, and a real environment brings its own backend. Still open: database spans,
  request metrics for pdf and finance, alerting on audit and authz failures (`hoops_authz_denied_total`, WP85),
  Keycloak, Envoy access and Redpanda logs to the collector.
- **Mail.** Core sends the sign-up decision e-mails (WP90); since chart 0.10.0 (WP100) the chart sets core's SMTP keys
  (Mailpit on kind, an optional `hoops-smtp` Secret for a real server; ESO has no `hoops-smtp` entry by default).
- **Release.** `ci` and `e2e` are green on GitHub since 2026-11-02 (`images` too, apart from the krb5 findings of
  2026-11-14 to WP114; since the eighth round also for pdf-service and finance-service) (NVD key valid, images pushed to ghcr.io per
  commit, each with its SBOM since WP85), `codeql` and `semgrep` since WP83; Dependabot opens weekly grouped update PRs
  (Maven, pub, GitHub Actions pinned to SHAs) and `bump-pins` a weekly PR for base images, chart image tags and kind
  pins (WP89). Since WP133 superseded pull request runs are cancelled (never a run on `main`), each gate runs once and
  set-up and image publishing are composite actions (ADR-0065). No release has been cut yet (no git tag): follow
  `runbooks/release.md`.
- Scale: the usage snapshot job and the eligibility sweep iterate tenants sequentially (fine for tens of tenants); snapshots
  are never pruned.

## Data and history
- Backfill of `REJECTED` for players rejected before core `V8` (they remain `WITHDRAWN`).
- `OPPONENT_FOUL` event type (removed from the box score in contracts 2.0.0 because no source event existed).
- Decide whether a SCHEDULED match should still accept events (`MATCH_NOT_STARTED` is reserved in the contract).
