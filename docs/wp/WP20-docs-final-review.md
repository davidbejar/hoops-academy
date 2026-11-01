# WP20 — Documentation and final spec-conformance review

Model: Sonnet (docs) + Opus (review). Depends on: WP18.

## Scope
- User guides per role (admin, coach/assistant, parent, player, super admin) in es/en/id (docs/guides/).
- Runbooks: onboard tenant, rotate secrets, CNPG backup/restore, kind rebuild, release process.
- Architecture overview with diagrams; roadmap (billing, events v2, native images, push notifications, purge job).
- Opus review: walk `docs/SPEC.md` + `docs/PLAN.md` §2 line by line with evidence (tests/e2e) → conformance checklist;
  simplification pass (dead code, duplicated patterns between game/athlete RosterPort adapters → move to common);
  ADR completeness.

## Acceptance
- [x] conformance checklist with every spec statement mapped to a test or e2e step; gaps listed with follow-ups (`docs/conformance.md`, review handover below)

## Handover (docs)

Documentation half of WP20 (Sonnet). The Opus review half (conformance checklist, simplification pass, ADR completeness)
is **not** done; the acceptance box above stays open. No code, contract, infra, deploy or other docs/wp file was touched, and
no git command was run.

### Written (lines)
- User guides, es/en/id each, in `docs/guides/`: `admin` 90/87/90, `coach` 87/82/85, `parent` 52/49/52, `player` 41/39/39,
  `super-admin` 47/46/45 (15 files, 931 lines in total, suffixes `.es.md`, `.en.md`, `.id.md`).
- Runbooks (new): `onboard-tenant.md` 60, `rotate-secrets.md` 64, `backup-restore.md` 68 (design), `release.md` 67,
  `troubleshooting.md` 83.
- `docs/architecture.md` 191 (five Mermaid diagrams: context, containers, request flow with tenant header and RLS, offline
  sync sequence, eligibility/rollover; ADR table; data ownership; testing strategy; security posture).
- `docs/roadmap.md` 92. Root `README.md` 83 (refreshed). Existing runbooks (`local-stack`, `kind`, `e2e`) were not edited.

### How it was checked
- Menu and button names in the guides come from `apps/web/lib/l10n/app_{es,en,id}.arb` (dumped and read); screens and rights
  from the WP11-WP14 handovers and `docs/domain/authz-matrix.md`. Relative links in README, architecture, roadmap, runbooks and
  guides were checked with a script: none broken. Mermaid blocks were scanned for `;` (a known parser trap) and fixed; they
  were **not rendered** here.
- Commands in the runbooks and README were copied from the justfile, scripts, `kind.md`, `e2e.md`, `local-stack.md` and the
  apps/web README. I did not run any of them.

### Could not verify
- No screen was clicked through in a browser; every guide ends with a status line saying so. Guides describe the app as built
  according to the handovers (e.g. the player box score shows team totals only, per WP13, while the authz matrix says "self").
- Test counts in `architecture.md` are copied from the WP17 verification table (JVM) and WP14 (Flutter 447); not re-run.
  The e2e journey (20 steps) is documented as PARTIAL in `WP18-e2e.md`; I found no later record of a full green run.
- `rotate-secrets.md`: compose and Keycloak rotation steps and `ALTER ROLE`/`kcadm update clients` are not executed (marked);
  the kind path follows `kind.md`/ADR-0012.
- `backup-restore.md` is design only (CNPG barman-cloud plugin names, `pg_dump`/`pg_restore` flags, owner handling after
  restore). `release.md`: no release, tag, registry or CI run exists; the Helm/image steps follow WP16 and the workflows.
- `onboard-tenant.md`: the MailHog `jq` expression assumes the MailHog API v2 shape used by `e2e/.../MailHog.java`; kind
  mailpit access follows WP17 notes.
- Invented nothing about push notifications, billing or purge beyond "not built"; the roadmap marks undesigned items.

### Doc drift noticed (not fixed, outside my files)
- `docs/runbooks/e2e.md` says game/athlete have no health extension and lists the realm `basic` scope as an open blocker;
  WP17 fixed both. `docs/runbooks/kind.md` still says game/athlete use TCP probes.
- `CLAUDE.md`, `libs/contracts/README.md` and WP2b still mention `apps/web/lib/api` (now `apps/web/packages`).
- `apps/web/README.md` still says core-service "does not exist yet" and that the realm only allows :8080 (WP17 added 5173).
- `docs/PLAN.md` describes `servers: /api/<svc>` and symlinked chart files; the implementation differs (copies plus
  `scripts/sync-chart-files.sh`).

### Open points for the Opus review
Conformance walk of `docs/SPEC.md` and PLAN section 2 against tests/e2e; WP19 is unbuilt; F-01 needs a product decision before
the authz matrix and the guides can state what parents and players see in the event feed.

## Handover (review)

Opus half of WP20, 2026-11-02. No git command was run; everything below is uncommitted in the working tree.

### What changed
**1. Conformance checklist** — new `docs/conformance.md`: 69 statements (SPEC.md S-01…S-50, user additions U-01/U-02,
PLAN §2 split into 15 rules R-01…R-15, v2 items V-01/V-02), each with status, location and evidence (test classes, e2e
step names from `JourneyTest`, handover references). **Implemented 49 · Partial 12 · Deviated 5 · Not implemented 0 ·
Deferred-v2 3.** Every cited test class/file was checked to exist. Includes the top-10 gaps and a "deviations, stated
plainly" table (event ingest for SCHEDULED/FINISHED, BIRTH_YEAR orphan timing, REJECTED, assistant rights, parent stat
rules, coach approvals, placeholder norms, offline cold start, super_admin blind to tenant content, billing seams only,
kind coverage, manual browser tests, health vs training visibility, sign-out).

**2. Documentation reconciliation**
- `docs/runbooks/e2e.md`: health of all three services, `basic`/`sub` realm fix (F-21), status section (20/20 on compose,
  not on kind).
- `docs/runbooks/kind.md`: chart files are copies synced by `scripts/sync-chart-files.sh` (Tiltfile does not call it),
  HTTP probes for all services, `sub` rejection, verification status; `postInitApplicationSQLRefs` wording.
- `apps/web/README.md`: core exists, 5173 redirect/origin + CORS in the realm/services (re-import note), no
  `offline_access`, `build_web.sh` guards and `--no-web-resources-cdn`, sw network-only prefixes incl. `/platform`,
  `/internal`, update banner; links to ADR-0018/0019.
- `CLAUDE.md` and `libs/contracts/README.md` already said `apps/web/packages` (fixed earlier); CLAUDE.md now points to
  `conformance.md` and `FOLLOW-UPS.md`. `services/core-service/README.md` (realm grants, health), game/athlete READMEs
  (check moved to common). Root `README.md` status + conformance link; `docs/roadmap.md` security items updated.
- `docs/PLAN.md`: a status box + "Implementation notes / deviations" at the top; the original text is unchanged.
- `docs/security/review-2026-11.md`: F-03, F-09, F-10, F-19, F-20 Fixed (WP14b) with test evidence; F-07, F-08 Partly
  fixed; F-21 verified by WP18b; counts now fixed 16 / partly 2 / open 3 (F-01, F-11, F-14).
- `docs/wp/FOLLOW-UPS.md`: rewritten — deduplicated, grouped (product/contract, security, web, backend, infra/CI/e2e, v2),
  `[v2]` marks, closed items moved to Resolved (WP10b, WP14, WP14b, WP18, WP18b, Dart regeneration, WP20), new items
  from the review (PLAYER own box-score line, REJECTED label, session plan picker, services-up readiness, tilt with core,
  entitlement denial test, tenant suspension propagation, contract `allOf` flaw).
- `docs/architecture.md`: counts (common 168, contracts 99, core 429, game 193, athlete 578 = 1,467; Flutter 477; e2e
  20 green on compose), ADR table 0018–0021, open findings.
- Skills: `quarkus-hexagonal-service` (shared readiness check, lock release in tests), `tenant-isolation-testing`
  (release the advisory lock explicitly).

**3. Simplification pass** (small, test-covered)
- `CoreReachabilityCheck` was byte-identical in game and athlete → moved to `libs/common-quarkus`
  (`com.hoopsacademy.common.client`, `@IfBuildProperty(hoops.core.reachability-check.enabled, enableIfMissing)`); common
  now depends on `quarkus-smallrye-health`; core sets the property to `false`. New tests: `CoreReachabilityCheckTest`
  (common, 4: reachable, failing, closed port, TTL cache — characterisation of moved code, green at first run) and
  `CoreHealthEndpointsTest` (core, 2: no self-probe; **seen red** with the property removed, restored). The services'
  existing `HealthEndpointsTest` (6 each) still pass unchanged.
- Removed the unused direct `caffeine` dependency from game and athlete (only common uses it since WP2c).
- `./mvnw dependency:analyze` on all modules: the other "unused declared" entries are Quarkus extensions (runtime-only,
  false positives) or aggregators (jqwik, swagger-parser, contracts as a resource jar); "used undeclared" are transitive
  APIs. Nothing else removed.
- `dart fix --dry-run` in `apps/web`: "Nothing to fix!".
- Flaky test found by the first full run: `NightlyEligibilityJobTest.whileAnotherReplicaRunsTheSweepThisOneSkipsIt`
  failed once (passed 3/3 alone). Cause: the other "replica" connection's session advisory lock is freed only when the
  backend exits after `close()`, which can lag. The test (and the two siblings with the same pattern,
  `UsageSnapshotJobTest`, athlete `NightlyMaterialisationTest`) now call `pg_advisory_unlock` before closing. Test-only.
- Not done (would ripple or is not duplication): test-support classes duplicated by name (`Contract`, `CoreStubs`,
  `RealResolverProfile`, `NoBuiltInCredentialsTest`) differ per service; `AthleteExceptionMappers` / `CoreExceptionMappers`
  are service-specific.

**4. ADR completeness** — new: ADR-0018 web offline shell (own service worker, no CDN, update prompt), ADR-0019 web
session and sign-out semantics, ADR-0020 approval workflow and player lifecycle (pending rows, REJECTED, ORPHAN on
creation, player login), ADR-0021 authorization refinements beyond the matrix (assistant rights, match/feed visibility,
event status/parent rules, team-scoped health, super_admin). Already covered: SCHEDULED/FINISHED ingest (ADR-0014 §3),
REJECTED in contracts (ADR-0016), audit log (ADR-0017), orphan scope/rollover (ADR-0015).

### Verification (commands run, output read)
| Command | Result |
|---|---|
| `./mvnw dependency:analyze -DskipTests -pl <5 modules> -am` | BUILD SUCCESS; findings above |
| `cd apps/web && dart fix --dry-run` | Nothing to fix! |
| `./mvnw -pl libs/common-quarkus,services/{core,game,athlete}-service -am test -Dtest='CoreReachabilityCheckTest,CoreHealthEndpointsTest,HealthEndpointsTest' -Djacoco.skip=true` | 4 + 2 + 6 + 6 green |
| red check: core property commented out, `CoreHealthEndpointsTest` | 1 failure ("not a collection containing core-service"); restored |
| `./mvnw -q clean verify` (1st) | exit 1: core 429 tests, 1 failure (the flaky lock test above) |
| `NightlyEligibilityJobTest` alone ×3 | 5/5 green each time |
| `./mvnw -q clean verify` (2nd, after the lock fix) | **exit 0, all coverage gates met**: common 168 (lines 95.0 %), contracts 99, core 429 (98.6 %), game 193 (98.5 %), athlete 578 (97.2 %) = **1,467 tests, 0 failures/errors/skipped** |
| `e2e/bin/services-up.sh` (fresh package) + readiness curl | core: DB check only; game/athlete: DB + `core-service` reachable |
| `./mvnw -q -pl e2e test -De2e.baseUrl=http://localhost:8080` | **`JourneyTest` 20 tests, 0 failures/errors/skipped, 69.8 s**; then `services-down.sh` |
| `cd apps/web && flutter analyze && flutter test` | No issues found; **+477: All tests passed!** |
| link check over all edited docs and ADRs | 0 broken relative links |

Not run: kind (no cluster up), chart tests (`deploy/` untouched), browser checks (no chromedriver). The compose stack was
left up; the three services are stopped; the e2e run added one more set of `e2e-*` tenants/users to the stack.

### Top-10 recommended next steps (prioritised)
1. **Commit this review** (the tree was clean before it; these changes are uncommitted) as a few Conventional Commits
   (`refactor(common): …`, `test(core): …`, `docs: …`); run `pre-commit run --all-files` first.
2. **Decide F-01** (event-feed visibility for parents/players), then implement the filter or update the authz matrix,
   ADR-0021 §3 and the guides.
3. **Run the browser checks once**: install chromedriver 156.x, `apps/web/tool/web_smoke.sh` (mock, then `--real`), the
   airplane-mode cold start and Lighthouse; then add chromedriver to CI.
4. **Run the CI workflows** on GitHub (`ci.yml` with `NVD_API_KEY`, `images.yml`, `e2e.yml` with `HOOPS_EXPOSE_KC_ADMIN=true`)
   and fix what the runner finds.
5. **Kubernetes end to end**: add `scripts/sync-chart-files.sh` to the Tiltfile, `tilt ci` with core, then the e2e journey on
   kind (`docs/runbooks/e2e.md`).
6. **Small web fixes**: PLAYER's own box-score line, `REJECTED` label, plan picker / session edit, tenant timezone in the
   calendar, availability badge in roster and match setup.
7. **Security residuals**: F-07 tenant+person scoping and wipe on `sub` change, F-08 refresh-token rotation, F-14 audience
   check, then the ASVS gaps (blocklist, breached passwords, OTP for admins, login/authz-failure events).
8. **Fitness norms**: replace placeholder bands with cited tables and verify Cooper against a primary source (data work;
   schema and "reference pending" flag are ready).
9. **Contract hygiene**: remove `additionalProperties:false` from `allOf` members, make `MatchEvent` validator-resolvable,
   add the audit read endpoint; update `e2e/bin/services-up.sh` to wait for `status == UP`.
10. **Tenant lifecycle hardening before billing**: propagate suspend/withdraw to game/athlete caches (or shorten the TTL),
    decide on disabling Keycloak logins, give guardian-linked parents a login, and add an entitlement-denial test; then
    the v2 items (outbox publisher/Redpanda, billing module, purge job).
