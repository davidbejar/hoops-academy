# Cross-cutting follow-ups (owned by the orchestrator)

Collected from the WP handovers and the WP20 review (2026-11-02); reconciled with the product interview of 2026-11-05
(WP26) and with the WP26–WP37 handovers on 2026-11-06. Grouped by area; **[v2]** marks items that are out of v1 by
decision (PLAN §8, roadmap); **→ WPnn** marked an item the plan below assigned to a work package (all closed). Resolved items are listed at the bottom with the WP or decision that
closed them. The statement-by-statement status of the spec is in [`../conformance.md`](../conformance.md).

## Plan (2026-11-05)
Work packages run as parallel agents in git worktrees under `$HOME`, merged in waves (decision 12). Briefs and
handovers: `docs/wp/WP<n>-*.md`. **All twelve are done**: merged into `main` on 2026-11-05/06 in the order WP26…WP37
(WP37 before WP36 at the end).

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP26 | Docs reconciliation and decisions | Opus | Done (ADR-0025) |
| 1 | WP27 | Fitness norms: cited tables | Opus | Done (370 of 630 rows cited) |
| 1 | WP28 | Web bugs: own box-score line, REJECTED label | Sonnet | Done |
| 1 | WP29 | Contract validation: allOf/additionalProperties, MatchEvent oneOf | Opus | Done (ADR-0027; core 2.3.1, game 2.0.1, athlete 2.0.1) |
| 1 | WP30 | Infra hygiene: e2e readiness, Tiltfile sync, image pins | Sonnet | Done |
| 1 | WP31 | Shared login e-mail propagates to every academy | Opus | Done (ADR-0026) |
| 2 | WP32 | Temporary password expiry (event-triggered sweep) | Opus | Done (ADR-0028; core 2.4.0) |
| 2 | WP33 | Match feed filtered for parents and players (F-01) | Opus | Done (ADR-0030; game 2.1.0) |
| 3 | WP34 | Audit log read API and console screens | Opus | Done (ADR-0029; core 2.5.0) |
| 3 | WP35 | Web UX gaps | Sonnet | Done |
| 4 | WP36 | Gateway API (Envoy Gateway) replaces ingress-nginx | Opus | Done (ADR-0031; chart 0.2.0) |
| 4 | WP37 | Mutation testing: on-demand PIT runs, mutants fixed, baseline kept (not in every build) | Opus | Done (baselines 95/95/95/100) |

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
- **Audit rows with free text** (found in WP34): `tenant.suspended` / `tenant.withdrawn` store the super admin's `reason`
  in the audit metadata, against the no-personal-data rule, and academy admins now read those rows. Decide: keep (the
  reason is meant for them) or move it out of the audit row. Also: rows done from the platform show the super admin's
  Keycloak `sub` to academy admins; could be shown as "platform administrator".
- **Feed filter in SQL** (WP33): for non-staff callers the feed filter walks all of a match's events in memory.
- **Template i18n** (WP9): `nameKey`/`locale` on `TrainingPlanSummary`; the 10 templates are English-only in the DB.

### Security (from `docs/security/review-2026-11.md`)
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
- **Update requests cannot clear a field** (WP35): every `Update*Request` treats null as "unchanged", so a session's plan,
  location or notes, an absence reason, a result's notes or a measurement value can be changed but not removed. Needs a
  contract convention (explicit null, or a `clear` list) in core and athlete.
- **`/me` memberships carry no tenant `timezone`**: the app calls the tenant profile for it (WP35). Add it to `TenantSummary`.
- **Test types**: no operation to change a type's code or delete a type (WP35 left them out).
- **Demo mock** lacks `/api/athlete/*` and `/platform/*` (all WP35 screens are unreachable in mock mode).
- **Fonts**: glyphs outside Roboto (CJK, emoji) render as tofu; bundle a Noto subset if a language needs it.
- **Same-device two-tab clientSeq race** (WP13): accepted for now (second event is `CLIENT_SEQ_CONFLICT`, visible).

- **Dev login origin** (ADR-0022): `flutter run` on :5173 is another origin than Keycloak on :8080, so the address bar
  changes host during a local login (production keeps one origin). Optional: proxy the dev server through nginx on :8080.
- **Browser login round trip in CI**: `apps/web/tool/browser_login_check.py` (stdlib WebDriver) runs locally only; add it
  with chromedriver to the e2e job.

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
- **Fitness norms, remaining placeholders** (after WP27: 260 of 630 rows): Cooper 8–12 (no youth table found), T-test and
  vertical jump outside 14–15 (lead: Moreno-Gonzalez et al., BMC Pediatr 2026, doi:10.1186/s12887-026-07796-1, not
  fetchable yet), edge ages that repeat the nearest cited age; the girls' T-test placeholders run ~1.2 s too fast; the
  Cooper figures are not traced to the 1968 paper; check the Catley PDF against the BMJ copy. The sit-and-reach scale is
  now "20 cm = toes" (Catley): the web UI should show the unit hint. Details: `docs/domain/norms.md`.
- **`ApprovalPayload.empty()`** in core is never called (dead code found by WP37; its mutant stays uncovered): delete it
  or use it.
- **Mutation scope** (WP37): rule code reached only by container tests (`TenantScope`, `ProblemExceptionMappers`, use
  cases) is outside PIT's scope; extracting pure rules from them would let PIT cover them.
- **Dependency hygiene**: `dependency:analyze` lists Quarkus extensions as "unused" (false positives, runtime-only) and
  many transitive APIs as "used undeclared"; only `caffeine` in game/athlete was really unused (removed in WP20).

### Infra, CI, e2e
- **Gateway rate limits** (WP36, product owner to decide): Envoy Gateway local rate limits hold **per Envoy replica**
  and the burst equals the per-minute rate (ingress-nginx allowed 5 x); global rate limiting (Envoy ratelimit service +
  Redis) if the proxy runs more than one replica and the limit must hold across them (ADR-0031).
- **No gateway body-size limit** (WP36, product owner to decide): Envoy streams bodies; the services reject bodies above
  2 MB with a 413 Problem. A gateway limit needs `BackendTrafficPolicy.requestBuffer`, which buffers every request.
- **e2e MailHog checks skipped on kind** (WP36): kind runs Mailpit as Service `mailhog`, whose API is `/api/v1`, not
  MailHog's; the journey skips those checks there (green on compose).
- **`tilt ci` with core-service** has not been run (WP16 deployed game/athlete/web; WP18 used `up.sh --deploy`; not
  re-run after WP30's Tiltfile sync or WP36's Gateway API chart).
- **`ci` red on 3b59360: trivy-fs KSV-0014** (found 2026-11-06, run 42112940234): WP36's new chart snapshot
  `deploy/helm/tests/snapshots/umbrella-tls.yaml` renders the Keycloak Deployment without `readOnlyRootFilesystem`
  (accepted until 2027-03-31), but `.trivyignore.yaml` lists only `umbrella-default.yaml` and `umbrella-kind.yaml` under
  KSV-0014. Add the TLS snapshot path there (one line; every other `ci` job passed). Not done in the docs pass.
- **Podman VM clock drift** (seen in WP36 and on 2026-11-06, 15–59 min): after the host sleeps, the Podman machine's
  clock falls behind or stalls, Keycloak tokens from Testcontainers look expired, and the Claude commit/push hooks fail
  with 401 or time out. Workaround: `podman machine ssh "sudo date -u -s @$(date +%s)"`; needs a host-level fix (time
  sync in the VM after resume).
- **Keycloak CSP hardening**: realm `browserSecurityHeaders`, so the accepted ZAP alerts under `/auth/realms/` can go
  (`.zap/baseline.conf`). (The CI workflows themselves are green on `origin/main` since 2026-11-02; see Resolved.)
- **dependency-check NVD cache** (2026-11-05): the "Save NVD data" step runs `if: always()`, so a failed or cancelled
  run can save a broken cache that later runs restore (the 2026-11-05 run restored `nvd-Linux-41422780377`, saved by
  the failed run 41422780377, and took 77 min; that cache has been deleted). Save on success only, or delete the key by
  hand (`gh cache delete`) when the job runs > 40 min. No WP yet.
- **Image pins** (WP30): the `ubi9/openjdk-21-runtime` digest is pinned but not auto-bumped (no Renovate/Dependabot for
  Containerfile ARGs); drop the guava pin in the root pom once the Quarkus BOM ships ≥ 33.7.2.
- **Optimised Keycloak image** (read-only root FS; KSV-0014 accepted until 2027-03-31).
- **External Secrets Operator manifests** (ADR-0012).

### v2 (by decision)
- **[v2] Events**: outbox publisher + Redpanda + `*_ref` replicas behind `RosterPort` (WP19 brief; `core.outbox` is
  already written and never read).
- **[v2] Billing module** on the existing seams (`billing.*`, `EntitlementService`, outbox events).
- **[v2] Purge job** for withdrawn tenants after the retention period; also the only clean-up of old
  `core.audit_event` rows (decision 8: no separate retention job).
- **[v2]** Push notifications, native images, Pact broker.

## Resolved
- WP37 (decision of 2026-11-05): mutation testing with PIT on demand (`just mutation [module]`, never in `verify`) and in
  `.github/workflows/mutation.yml` (manual + monthly; first manual run 42112955113 on 3b59360 green for all four modules). Scores after the killing tests: common-quarkus 99.1 %, core
  99.6 %, game 99.5 %, athlete 100 %; baselines 95 / 95 / 95 / 100; equivalent survivors listed in
  `docs/quality/mutation.md`. No production defect found.
- WP36 (decision 10): Helm chart 0.2.0 on Gateway API with Envoy Gateway v1.9.3 (Gateway API v1.6.1) instead of
  ingress-nginx: HTTPRoutes per prefix, deny routes, per-IP local rate limits, HSTS on HTTPS, kind NodePort on :8090
  (ADR-0031). The e2e journey is **green on kind** for the first time (21 tests, 159 s); `ratelimit-check.sh` passed.
  Remaining gateway items are listed under "Infra, CI, e2e".
- Production prefixes vs `NETWORK_ONLY_PREFIXES` in `web/sw.js` (re-check after WP36, 2026-11-06): the chart routes
  `/api/core`, `/platform`, `/api/game`, `/api/athlete`, `/auth` and the `/internal` deny route all fall under
  `/api/`, `/auth/`, `/platform/`, `/internal/`; re-check if a route prefix changes.
- Date-dependent week-calendar golden (found in WP26): "today" comes from `nowProvider` and is pinned in the golden
  (commit 7e13cec).
- WP30: `e2e/bin/services-up.sh` waits for `"status":"UP"`; the Tiltfile runs `scripts/sync-chart-files.sh` before
  `helm(...)`; `ubi9/openjdk-21-runtime:1.24` pinned by digest; guava pin kept (the BOM still resolves 33.6.0).
- WP28: a PLAYER sees their own line in the live box score; `PlayerStatus.REJECTED` has its own label in es/en/id.
- WP35 (decision 14): not-a-member-yet state, academy time zone in calendars/pickers (`timezone` package, zone from the
  tenant profile), usage trend chart, session edit + plan picker, editable measurements/results/test types/absences,
  availability badge in rosters and match setup.
- WP34 (decision 8): audit trail read API (`GET /api/core/audit-events` for ADMIN under RLS, `GET /platform/audit-events`
  for super_admin through a platform read policy), filters by date range and action, `AuditAction` enum kept equal to
  the contract and `docs/domain/audit-events.md` by a test, `member.invitation_accepted` recorded, Activity screens in
  the admin hub and the platform console (ADR-0029, core 2.5.0). No retention (v2 purge job).
- WP29: contracts without `allOf` composition (plain objects + `x-extends`), no muted validation anywhere, e2e validates
  requests and the match-event feed (ADR-0027; core 2.3.1, game 2.0.1, athlete 2.0.1).
- WP33 (decision 5, F-01): the match event feed applies the box-score visibility rule server-side (team-level events
  for every member, player events only for own or linked players, voids follow their event); parents and players
  take the score from the server box score (ADR-0030, game 2.1.0). Follow-up: the filter walks all events in memory
  for non-staff callers; move it into SQL if feeds grow large.
- WP32 (decision 4, F-23): unused temporary passwords expire after 3 days; swept in the background on issuance and
  first sign-in under a cluster lock, the Keycloak login disabled with an es/en/id message, re-issue re-enables
  (ADR-0028, core 2.4.0 `temporaryPasswordStatus`). Known: expiry happens at the first sweep after the 3 days.
- WP27 (decision 11): 370 of 630 norm rows cited (FitBack 2023 beep test 8–18, Catley & Tomkinson 2013 sit-and-reach
  9–17, Cossio-Bolaños 2026 sprint 8–17, Mascherini 2022 T-test and vertical jump 14–15); remaining gaps tracked above.
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
