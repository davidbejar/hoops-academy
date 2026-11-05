# Cross-cutting follow-ups (owned by the orchestrator)

Collected from the WP handovers and the WP20 review (2026-11-02); reconciled with the product interview of 2026-11-05
(WP26). Grouped by area; **[v2]** marks items that are out of v1 by decision (PLAN §8, roadmap); **→ WPnn** marks an
item that the plan below assigns to a work package. Resolved items are listed at the bottom with the WP or decision that
closed them. The statement-by-statement status of the spec is in [`../conformance.md`](../conformance.md).

## Plan (2026-11-05)
Work packages run as parallel agents in git worktrees under `$HOME`, merged in waves (decision 12). Briefs:
`docs/wp/WP<n>-*.md` (WP26–WP37 written).

| Wave | WP | Title | Model |
|---|---|---|---|
| 1 | WP26 | Docs reconciliation and decisions | Opus |
| 1 | WP27 | Fitness norms: cited tables | Opus |
| 1 | WP28 | Web bugs: own box-score line, REJECTED label | Sonnet |
| 1 | WP29 | Contract validation: allOf/additionalProperties, MatchEvent oneOf | Opus |
| 1 | WP30 | Infra hygiene: e2e readiness, Tiltfile sync, image pins | Sonnet |
| 1 | WP31 | Shared login e-mail propagates to every academy | Opus |
| 2 | WP32 | Temporary password expiry (event-triggered sweep) | Opus |
| 2 | WP33 | Match feed filtered for parents and players (F-01) | Opus |
| 3 | WP34 | Audit log read API and console screens | Opus |
| 3 | WP35 | Web UX gaps | Sonnet |
| 4 | WP36 | Gateway API (Envoy Gateway) replaces ingress-nginx | Opus |
| 4 | WP37 | Mutation testing: on-demand PIT runs, mutants fixed, baseline kept (not in every build) | Opus |

### Decisions of 2026-11-05 (product owner)
1. **Project nature.** Hoops Academy is a learning project, not commercial (yet). Easy sign-up (temporary password,
   reset at first login, no e-mail verification, no consent flow) matters more than closing account-linking gaps,
   because the owner tests by creating many users. One login being a member of several academies is a feature (a parent
   with children in two academies, a coach working for two). ADR-0025.
2. **F-11** (inviting an existing login links it and reveals that it exists): accepted by design (1). ADR-0025.
3. **Pre-account hijacking** (security review F-22; ADR-0024): accepted by design (1). ADR-0025.
4. **Temporary password expiry → WP32.** A temporary password older than 3 days is expired. No scheduler: a sweep runs
   in the background, triggered by a person's first login and by every issuance, one at a time across replicas
   (`runExclusive`). The sweep disables the login in Keycloak (only logins still on their temporary password; never one
   that chose its own), records it on `core.app_user` and in the audit log; Keycloak's `hoops` login theme shows
   "temporary password expired, ask your academy administrator" in es/en/id; re-issue re-enables. Accepted gap: an
   expired login works until the next sweep.
5. **F-01 match event feed → WP33.** PARENT/PLAYER get team-level events plus the events of their own or linked
   players, filtered server-side; the authz matrix and guides follow.
6. **Suspended / withdrawn academy.** Logins stay enabled (they may belong to other academies); the up-to-30 s
   membership cache in game/athlete is accepted; no cache invalidation call. ADR-0025.
7. **Shared login e-mail → WP31.** When the super admin changes the e-mail of a login used in several academies, every
   academy's `core.person.email` for that login changes in the same transaction (one person, one e-mail).
8. **Audit log → WP34.** ADMIN reads the events of their own academy, super admin reads everything; filters by date
   range and event type. The existing `core.audit_event` table suffices (tenant, actor, action, target, metadata, at);
   names are resolved at read time and never stored; no retention job (v2 purge job).
9. **ghcr.io packages.** Make the four packages public (the owner's click in GitHub). Done: public as of 2026-11-05
   (see Resolved).
10. **Ingress → WP36 (last).** Move the chart from ingress-nginx to Gateway API (Envoy Gateway).
11. **Fitness norms → WP27.** Research the missing cited tables now.
12. **Orchestration.** Work packages run as parallel agents in git worktrees under `$HOME`, merged in waves.
13. **Bugs** → WP28 (web: PLAYER's own box-score line, REJECTED label), WP29 (contract `allOf` +
    `additionalProperties:false`, `MatchEvent` oneOf validation), WP30 (e2e readiness `status == UP`, Tiltfile chart
    sync, pinned `ubi9/openjdk-21-runtime`, guava pin).
14. **Web UX gaps → WP35** (not-a-member-yet state, tenant timezone, usage chart, session edit/plan picker, availability
    badge, measurement/test/absence editing).

## Open

### Product / contract decisions
- **→ WP33. F-01 event feed** (Medium): `GET /api/game/matches/{id}/events` returns every player's events to
  PARENT/PLAYER members; the box score hides them. Decided (5): filter server-side to team-level events + own/linked
  players; align `docs/domain/authz-matrix.md` and the guides.
- **→ WP34. Audit read API**: `core.audit_event` has no endpoint. Decided (8): ADMIN reads their academy's events, super
  admin reads everything, filters by date range and event type, names resolved at read time; no retention job (v2 purge).
- **→ WP29. Contract `allOf` + `additionalProperties: false`** (WP18b): e.g. `AgeCategory = allOf[AgeCategoryInput, {id}]` cannot
  validate any real response; tests and e2e mute those errors. Drop `additionalProperties:false` from composed members
  (or move to `unevaluatedProperties` with OpenAPI 3.1).
- **→ WP29. `MatchEvent` oneOf/discriminator** is not resolvable by the atlassian validator for feed responses (WP18b); e2e reads
  the feed unvalidated.
- **Template i18n** (WP9): `nameKey`/`locale` on `TrainingPlanSummary`; the 10 templates are English-only in the DB.

### Security (from `docs/security/review-2026-11.md`)
- **→ WP32. Temporary passwords never expire** (WP24, security review F-23): Keycloak keeps a temporary credential
  until it is used or replaced. Decided (4): expire after 3 days via an event-triggered background sweep that disables
  the login; re-issue re-enables.
- **F-07 residual (apps/web)**: cached reads (`roster`, `matchJson`, `ownEvents`) are keyed by matchId only; add
  tenant + person columns (drift migration) and wipe when a *different* `sub` signs in after an expired session.
- **F-08 residual (realm)**: refresh-token rotation / reuse detection in `infra/keycloak/realm-academy.json`; the realm
  still lists `offline_access` as an optional scope.
- **F-14 token audience**: audience mapper per service + `quarkus.oidc.token.audience`.
- **ASVS gaps**: password blocklist (6.2.4), breached passwords (6.2.12), optional OTP for ADMIN/super_admin (6.3.3),
  Keycloak login events (16.3.1), authorization-failure logging (16.3.2), log shipping / OTel collector (16.4.3), SBOM.
- **Offline end-session** is skipped, not queued (SSO session lives until its 4 h idle timeout) — accepted, ADR-0019.

### Web app (`apps/web`)
- **Browser-level tests**: `apps/web/tool/web_smoke.sh` ran green in mock mode on 2026-11-02 (chromedriver 156 installed
  by hand from Chrome for Testing; the Homebrew cask is disabled). Still open: the Lighthouse installability check and the
  airplane-mode cold-start check (README "Offline cold start"); add chromedriver to CI.
- **→ WP28. PLAYER's own line in the live box score**: `scoring_rights.dart` `canSeeLine` ignores `ownPlayerId` (server returns
  the line).
- **→ WP28. REJECTED player label**: `lib/core/ui/labels.dart` maps `PlayerStatus.REJECTED` to "withdrawn"; add a label in es/en/id.
- **→ WP35. Training plan on a session**: no plan picker on ad-hoc sessions and no session edit screen (`SessionDetailNotifier.edit`
  exists); also no UI to edit/delete measurements and test results, update test types or edit absences.
- **→ WP35. Availability badge** in team roster rows and match setup (needs the athlete fake in those tests).
- **→ WP35. Calendar timezone**: times are shown in the device zone; `/me` now carries the tenant `timezone`, use it.
- **→ WP35. Usage trend chart** on the platform console (`getTenantUsageHistory` is in the regenerated package, unused).
- **Demo mock** lacks `/api/athlete/*` and `/platform/*`.
- **Fonts**: glyphs outside Roboto (CJK, emoji) render as tofu; bundle a Noto subset if a language needs it.
- **Same-device two-tab clientSeq race** (WP13): accepted for now (second event is `CLIENT_SEQ_CONFLICT`, visible).
- **Production ingress prefixes** must match `NETWORK_ONLY_PREFIXES` in `web/sw.js` if they ever differ (re-check in
  WP36).
- **→ WP35. Signed in without any academy** (2026-11-02): `/api/core/me` answers 404 for a Keycloak user with no person/
  membership (e.g. the seeded `coach1`/`player1` before an academy invites them), and the app shows the generic "not found"
  error with *Retry* / *Sign out*. Show a dedicated "you are not a member of an academy yet" state instead.
- **Dev login origin** (ADR-0022): `flutter run` on :5173 is another origin than Keycloak on :8080, so the address bar
  changes host during a local login (production keeps one origin). Optional: proxy the dev server through nginx on :8080.
- **Browser login round trip in CI**: `apps/web/tool/browser_login_check.py` (stdlib WebDriver) runs locally only; add it
  with chromedriver to the e2e job.
- **Date-dependent golden** (found in WP26, 2026-11-05): `test/golden/training_health_golden_test.dart` "week calendar,
  ADMIN, 360x780" fixes the week of 2026-11-02, but `training_screen.dart` highlights the heading of `DateTime.now()`, so
  a local `flutter test` (exact goldens) fails with a 1.61 % pixel diff on the days of that week; CI passes with
  `GOLDEN_DIFF_TOLERANCE=0.06`. Inject the clock (or move the fixed week away from any real "today" check). No WP yet.

### Backend
- **Remove `resendTenantAdminInvitation`** (WP24): deprecated alias of `issueTenantAdminTemporaryPassword` kept in core
  2.3.0 so the pre-WP25 web build keeps working; drop it in core 3.0.0 once WP25 uses the new operation.
- **Keycloak ahead of the database** (WP22, as ADR-0013): a commit failure right after a successful login update leaves
  Keycloak with the new e-mail; no repair job detects `app_user.email` ≠ Keycloak e-mail yet.
- **Parents via the guardian flow** get no login (WP5 note); WP17 covered players only (ADMIN add + approval).
- **Entitlement seam** has no test of a denial path (the noop implementation always allows).
- **Usage snapshots** are never pruned; the snapshot job aggregates tenants sequentially (fine for tens of tenants).
- **`staffTeamIds` / `playerTeamIds`** include teams of ended seasons while a staff row / assignment is open.
- **Unassigning an invalidated assignment** leaves its OPEN eligibility case open (resolve via the case API).
- **Backfill REJECTED** (WP2c): players rejected before core `V8` stay WITHDRAWN (pre-release data; accepted).
- **→ WP27. Fitness norms** (WP10b): replace placeholders with cited five-band tables (Tomkinson 2017 for the beep test,
  ALPHA-Fit/HELENA for sit-and-reach, sprint / T-test / vertical jump sources) and obtain a primary Cooper table.
- **Dependency hygiene**: `dependency:analyze` lists Quarkus extensions as "unused" (false positives, runtime-only) and
  many transitive APIs as "used undeclared"; only `caffeine` in game/athlete was really unused (removed in WP20).

### Infra, CI, e2e
- **e2e journey on kind**: never green (blocked by the realm defect at the time, not re-run). Run per
  `docs/runbooks/e2e.md` (port-forwards for the Keycloak Admin API and MailHog).
- **`tilt ci` with core-service** has not been run (WP16 deployed game/athlete/web; WP18 used `up.sh --deploy`).
- **→ WP30. Tiltfile**: call `scripts/sync-chart-files.sh` before `k8s_yaml(helm(...))` (chart copies of realm/init SQL).
- **→ WP30. `e2e/bin/services-up.sh`** treats any HTTP answer as ready and its comment says game/athlete have no health
  extension; switch to `status == UP` on `/q/health/ready` now that all three have it.
- **Keycloak CSP hardening**: realm `browserSecurityHeaders`, so the accepted ZAP alerts under `/auth/realms/` can go
  (`.zap/baseline.conf`). (The CI workflows themselves are green on `origin/main` since 2026-11-02; see Resolved.)
- **dependency-check NVD cache** (2026-11-05): the "Save NVD data" step runs `if: always()`, so a failed or cancelled
  run can save a broken cache that later runs restore (the 2026-11-05 run restored `nvd-Linux-41422780377`, saved by
  the failed run 41422780377, and took 77 min; that cache has been deleted). Save on success only, or delete the key by
  hand (`gh cache delete`) when the job runs > 40 min. No WP yet.
- **→ WP30. Pin `ubi9/openjdk-21-runtime`** in `deploy/containers/service.Containerfile` (trivy DS-0001); drop the guava pin in the
  root pom once the Quarkus BOM ships ≥ 33.7.2.
- **Optimised Keycloak image** (read-only root FS; KSV-0014 accepted until 2027-03-31).
- **→ WP36. Production ingress**: decided (10): move the chart from ingress-nginx (retiring upstream) to Gateway API
  (Envoy Gateway).
- **External Secrets Operator manifests** (ADR-0012).
- **PIT** (mutation testing) is configured in the root pom but no run is recorded → WP37 (decision of 2026-11-05: on demand and on a monthly schedule, never in every build; a baseline threshold catches regressions).

### v2 (by decision)
- **[v2] Events**: outbox publisher + Redpanda + `*_ref` replicas behind `RosterPort` (WP19 brief; `core.outbox` is
  already written and never read).
- **[v2] Billing module** on the existing seams (`billing.*`, `EntitlementService`, outbox events).
- **[v2] Purge job** for withdrawn tenants after the retention period; also the only clean-up of old
  `core.audit_event` rows (decision 8: no separate retention job).
- **[v2]** Push notifications, native images, Pact broker.

## Resolved
- WP31 (decision 7): a shared login's e-mail moved by the super admin reaches every academy that uses it, in the
  same transaction (ADR-0026); 409 `EMAIL_TAKEN` when another member of such an academy already uses the address.
- nginx `/platform/**` → core (WP2b handover) — fixed in commit 3418100.
- Keycloak `core-service` service account lacked realm-management `manage-users`/`view-users` — fixed in commit 85e3ca0.
- `Problem.code` alignment between contracts and common — done in WP2a.
- WP2c: AuthzContext enrichment — core `/internal/authz` and `/me` carry `timezone` and `playerTeamIds`; `ownPlayerId`
  is the own player id.
- WP2c: 503 `ServiceUnavailable` on every game/athlete operation; 502 `UpstreamIdentityProvider` on `createTenant` /
  `inviteMember`.
- WP2c: optimistic-lock → 409, `UnauthorizedException` → 401, `UpstreamUnavailableException` → 503 mappers in common.
- WP2c: `openapi-request-validator-restassured` 3.0.0 (relocated name) in the root pom and the three services.
- WP2c: RosterPort REST code moved to `com.hoopsacademy.common.client`; game/athlete keep thin adapters.
- WP2c: `TenantScope.runExclusive` for core's sweep and snapshot and athlete's materialisation.
- WP2c: `/internal/usage/{tenantId}` → 200 with zero counters for an unknown tenant in every service.
- WP2c: allOf / additionalProperties validator quirk, combinator side effects and colon paths documented in
  `libs/contracts/README.md`.
- WP2c: `hoops.tenancy.exempt-paths` replaces core's `MePathRewriteFilter`.
- WP2c: plan `:archive` / `:unarchive` and assignment progress in the contract and wired.
- WP2c: `nullableTenantTables()` RLS hook for shared global+tenant tables.
- WP2c: game contract — fixed `type` per variant, `EVENT_ID_REUSED`, `MATCH_NOT_STARTED` (reserved), `StatLine` foul
  counters, `BoxScore.opponentFouls` removed (ADR-0016).
- WP2c: nginx passes `events:batch` (and `%3A`) through unchanged.
- WP2c: athlete availability operation + `bandStatus` + nullable `ageAtMeasurement` in the contract.
- WP2c: core `PlayerStatus.REJECTED`, usage history endpoint, required reject note, counter keys documented.
- WP2c: Problem `instance` double slash in game 503 responses.
- WP10b: norms research — beep test 9–17 sourced (Zhang 2020), sit-and-reach anchored on FITNESSGRAM HFZ; remaining
  placeholders tracked above.
- WP14: super_admin with memberships reaches the Platform console from Profile.
- WP14: caching service worker `web/sw.js` for the offline cold start (ADR-0018; browser check tracked above).
- WP14b: "new version available, reload" prompt (SKIP_WAITING).
- WP14b: F-03 sign-out, F-08 `offline_access` dropped, F-09 no CDN, F-10 sqlite3.wasm sha256, F-19 network-only prefixes,
  F-20 release-build guards; security review statuses updated in WP20.
- WP17: onboarding crash window — `RepairOnboarding` + `OnboardingRepairJob` (ADR-0017).
- WP17: uploads > 2 MB → 413 Problem `REQUEST_TOO_LARGE` for every service.
- WP17: player login for ADMIN add + approval (core contract 2.1.0).
- WP17: members list hides persons of PENDING_APPROVAL / REJECTED players.
- WP17: measurement-per-day race → 409 `MEASUREMENT_EXISTS_FOR_DATE`.
- WP17: `quarkus-smallrye-health` in game and athlete; TCP probe overrides dropped.
- WP17: Keycloak `web` client 5173 URIs + web origin; CORS allow-list; `basic` scope on every client (tokens carry
  `sub`; sub-less JWTs → 401).
- WP17: rate limiting (nginx `limit_req`, ingress-nginx `limit-rpm`).
- WP17: chart symlinks replaced by copies + `scripts/sync-chart-files.sh` (drift check in the chart tests).
- WP17: mail in kind (mailpit as Service `mailhog`); `no-cache` for the app shell files; ingress forwards `events:batch`.
- WP18: kind deploy of core-service + `smoke.sh core game athlete` + superadmin `/api/core/me` through the ingress.
- WP18b: realm re-imported on compose; `HOOPS_EXPOSE_KC_ADMIN=true` for the e2e Admin API; **journey 20/20 green on
  compose** (three consecutive runs).
- apps/web after WP2c: Dart packages regenerated (core 2.1.0, game/athlete 2.0.0) and the app adapted.
- WP20: `CoreReachabilityCheck` moved to common-quarkus (core disables it with `hoops.core.reachability-check.enabled=false`).
- WP20: flaky job-lock tests (`NightlyEligibilityJobTest`, `UsageSnapshotJobTest`, `NightlyMaterialisationTest`) release
  the other replica's session lock explicitly instead of relying on connection close.
- WP20: runbooks, apps/web README, PLAN implementation notes, security review statuses reconciled; ADR-0018…0021.
- WP22: member e-mail changes are synced to Keycloak (username = e-mail, realm `registrationEmailAsUsername`) and
  `core.app_user`; academy admins get 409 `LOGIN_SHARED` for a login used in another academy (ADR-0023). The super admin
  manages each academy's administrators via `/platform/tenants/{id}/admins` (console screens: WP23).
- WP23: platform console lists, adds, edits and removes academy administrators.
- WP24/WP25: a server-generated temporary password replaces the setup and verification e-mails (ADR-0024); the console
  shows it once; re-issue for pending admins and members.
- CI workflows (`ci`, `e2e`, `images`) first ran on GitHub on 2026-11-02 and are green on `origin/main` since 5ab1f71
  (2026-11-02); last checked on 70d860b (2026-11-05, runs 42038926658, 42038926724, 42038926785). Runner-only fixes
  landed on 2026-11-02 (`git log --grep ci`). Notes kept: the e2e workflow's throw-away `.env` must set
  `HOOPS_EXPOSE_KC_ADMIN=true`; dependency-check needs `secrets.NVD_API_KEY`.
- NVD key activation: `NVD_API_KEY` is valid since 2026-11-02 (commit 929d1df); dependency-check green with the cached
  NVD data (run 41447129375, 2 min).
- Decision 9 (2026-11-05): **make the ghcr.io packages public (or configure a pull secret)** — the four packages
  (core-service, game-service, athlete-service, web) are public; the product owner checked them in GitHub and an
  anonymous registry token gets 200 on `/v2/davidbejar/hoops-academy/<name>/tags/list` (verified 2026-11-05).
- Decision 2 (2026-11-05): **F-11** invite of an existing Keycloak account (links without consent, reveals the account)
  — accepted by design, ADR-0025.
- Decision 3 (2026-11-05): **pre-account hijacking without e-mail verification** (WP24, ADR-0024, security review F-22)
  — accepted by design, ADR-0025.
- Decision 6 (2026-11-05): **withdrawn / suspended academy logins** stay enabled (they may belong to other academies);
  the up-to-30 s membership cache in game/athlete is accepted; no cache invalidation call — ADR-0025.
