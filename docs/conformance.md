# Spec conformance checklist (WP20 review, 2026-11-02; reconciled 2026-11-05, WP26, 2026-11-06, after WP37, WP42, WP51 and WP71, 2026-11-07, after WP90, and 2026-11-10, after WP103)

This page walks the original requirements — [`SPEC.md`](SPEC.md) sentence by sentence, the two additions the user made
when the plan was locked (trilingual UI, admin-uploaded logo), and the domain rules of [`PLAN.md`](PLAN.md) §2 — and
states for each what was built, where, and what proves it. It was written from the work-package handovers
([`wp/`](wp/)), the ADRs, the security review and a read of the code; nothing here was taken on trust from a single
source when the code could be checked. WP26 (2026-11-05) updated the evidence and gaps after WP21–WP25, the first green
CI runs and the product decisions of 2026-11-05 (`wp/FOLLOW-UPS.md` "Plan (2026-11-05)"); no status changed. The
reconciliation of 2026-11-06 follows WP26–WP37 (all merged): S-36, S-46 and R-11 moved from Partial to Implemented
(WP35, WP28, WP33), the e2e journey is green on kind (WP36) and the edge is Gateway API with Envoy Gateway (ADR-0031). The evening
reconciliation follows WP38–WP42 (all merged): S-08 moved from Partial to Implemented (`tilt ci` green with every
service, WP42); update requests can clear a field (ADR-0032, WP39); the gateway's rate limits are global (ADR-0033,
WP40); the journey's mail checks run on kind too (WP42); the demo mock reaches every screen (WP41). The reconciliation
after the third round (WP43–WP51, all merged on 2026-11-06) changed no status: core 2.7.0 and game 2.2.0 adopt the
`clear` list (ADR-0032, WP44, WP45); the rate-limit Redis has an ACL and every limited route a per-second burst cap
(ADR-0033 amendment, chart 0.4.0, WP46); injuries can be edited in the web app (WP48); the demo mocks share one roster
and filter by role (WP47); `apps/web` has a format check in CI (WP49); the GitHub Actions are pinned to commit SHAs
(WP50); `json-schema-validator` stays on 2.x (WP43). The reconciliation after the fourth round (WP52–WP71, all merged
on 2026-11-06): S-03 moved from Partial to Implemented (Lighthouse installability and an airplane-mode cold start in
Chrome, WP54; browser smoke and login round trip in CI, WP55); V-01 moved from Deferred-v2 to Partial (core's outbox
publisher, Redpanda and the game/athlete roster replicas are built and proven behind `hoops.roster.source`, default
still `rest`; WP66–WP69, WP71); the norms are cited for 475 of 630 rows (WP62); the web app edits matches, jerseys,
member data and academy contacts (WP52) and opens on a public landing page (WP70); tokens carry an audience per
service and refresh tokens rotate (ADR-0034, WP56); Keycloak's pages have a full CSP, a password blocklist and
optional OTP (ADR-0038, WP57); core 3.0.0 drops the deprecated alias (ADR-0035, WP59); templates speak es/en/id
(ADR-0039, WP61). The reconciliation after the fifth round (WP72–WP90, all merged on 2026-11-07) changed no status
(recounted: 54 / 8 / 5 / 0 / 2): the web app is redesigned on one design system (ADR-0040, WP72–WP75, WP77; S-02);
a session references any plan directly and exercises inside templates are searchable (ADR-0041, WP78; S-36, S-37);
academies are requested from the landing page and accepted or rejected by the super admin (ADR-0044, WP90; S-38);
past seasons are read-only history for former staff and admins (ADR-0042, WP80; R-14); SAST/DAST gates, security
events, an SBOM per image and an OpenTelemetry collector were added (ADR-0043, ADR-0045, ADR-0046; WP83–WP86); V-01
gained the producer recovery, removals, backfill and housekeeping (WP81, WP82) but the default is still `rest`.
The reconciliation after the sixth round (WP91–WP103, all merged on 2026-11-10): **V-01 moved from Partial to
Implemented** (the replica is the default roster source of game and athlete in the services, compose and the chart with
events, a drift check `just events-drift` compares core with both replicas, `rest` stays the fallback; ADR-0037
amendment, decision 66, WP98, WP100), so the count is 55 / 7 / 5 / 0 / 2. Also: an exercise catalogue with global and
academy exercises (ADR-0047, WP92, athlete 3.0.0; S-37); a preferred jersey number with carry-over on assignment and
the taken numbers per team (ADR-0048, WP96, WP101; beyond the spec); CSV exports of the roster and the audit trails built by core,
and CSV / Excel / ICS exports of player stats, box score and team calendar built in the browser (ADR-0048, WP96, WP97,
WP101); the application admin hub with a Users area and a context switcher (ADR-0049, WP91, WP99; S-38); a member
edits their own name (WP91, WP99); chart 0.10.0 with Envoy Gateway v1.10.0 (WP100; S-04).

**Status legend**
- **Implemented** — built as asked and covered by automated tests.
- **Partial** — built, but part of the statement is missing, or the evidence stops short of the statement (e.g. not run
  in a real browser).
- **Deviated** — built differently from the literal statement, on purpose, with the reason recorded (ADR or handover).
- **Not implemented** — asked for, not built, not planned.
- **Deferred-v2** — explicitly out of v1 by the spec or a locked decision; seams may exist.

**Evidence sources.** JVM tests run by `./mvnw verify` (counts in [§ Verification baseline](#verification-baseline));
Flutter tests run by `flutter test` in `apps/web`; e2e steps are methods of `e2e/src/test/java/com/hoopsacademy/e2e/JourneyTest.java`
(21 ordered steps since WP24, 23 since WP56; green on compose in WP18b and in every CI `e2e` run on `main` since
2026-11-02; green on kind through the Envoy Gateway in WP36, with its mail checks since WP42, 21/21 again in WP63). "WPn" refers to `docs/wp/WPn-*.md` `## Handover`.

## Summary

| Status | Count |
|---|---|
| Implemented | 55 |
| Partial | 7 |
| Deviated | 5 |
| Not implemented | 0 |
| Deferred-v2 | 2 |
| **Total statements** | **69** |

(Spec statements S-01…S-50, user additions U-01…U-02, plan §2 rules R-01…R-15, v2 items V-01…V-02; one row each.
Partial: S-04, S-09, S-16, S-43, S-44, R-13, R-15. Deviated: S-25, S-41, R-01, R-04, R-09.
Deferred-v2: S-15, V-02.)

### Top gaps a user should know
1. **Browser-level checks — in CI since WP55, PWA checks local.** The `flutter drive` smoke (`tool/web_smoke.sh`, mock
   mode) runs in the `ci` job `web-browser` and the browser login round trip with a temporary password in the `e2e`
   job, both on pinned Chrome for Testing 157. Lighthouse installability (PWA score 1) and the airplane-mode cold
   start (`tool/offline_cold_start.sh`: offline reload from `sw.js`, live match with the offline banner) ran in
   Chrome in WP54, locally only, the latter against the mock API (S-03). Colour contrast of the landing's orange
   buttons is unverified (Lighthouse sees no DOM text in the Flutter canvas).
2. **Kubernetes is proven on kind only.** kind + Helm + Tilt deployed game, athlete and web (WP16), all three services
   passed the smoke script (WP18), since WP36 the 21-step journey is green on kind through the Envoy Gateway
   (Gateway API, ADR-0031), and since WP42 with its mail checks (Mailpit) and after a green `tilt ci` with all three
   services (5 min 55 s on a fresh cluster). The rate limits are global across Envoy replicas (Redis, ADR-0033, WP40)
   and, since WP46, capped per second too, with a Redis ACL (chart 0.4.0; re-proven on kind with 1 and 2 replicas,
   `tilt ci` and the controller restart in WP63). Chart 0.5.0 sources Secrets from the External Secrets Operator
   (WP65), 0.6.0 adds Redpanda and 0.7.0 wires the services to it (WP66, WP71; kind smoke 46 checks with events end
   to end and the athlete replica flip). Chart 0.8.0 adds Stakater Reloader for rotated Secrets (WP87) and 0.9.0 an
   OpenTelemetry collector (WP86); WP86 re-proved on kind the full `up.sh --eso --deploy`, a rotation, the game
   replica flip, events off and `tilt ci`. Chart 0.10.0 (WP100) runs both services on the replica with events, sends
   core's mail to Mailpit, rate-limits the CSV exports and moves to Envoy Gateway v1.10.0; its kind proofs passed
   (`tilt ci` was not re-run on 0.10.0). No cluster beyond kind exists (S-04).
3. **Event feed visibility (F-01) — resolved in WP33.** The feed now follows the box score's rule (ADR-0030): ADMIN and
   team staff read every event, anybody else team-level events plus their own or linked players' (S-30, R-11).
4. **Fitness norms are partly placeholders.** Since WP62 (2026-11-06), 475 of 630 norm rows are sourced (beep test
   8–18 FitBack 2023; sit-and-reach 9–17 Catley & Tomkinson 2013; 20 m sprint 8–17 Cossio-Bolaños 2026; T-test and
   vertical jump 14–15 Mascherini 2022, T-test 12–13 Lesinski 2020, vertical jump 12–17 Leone 2025; Cooper 12-min 8–12
   Balague 1982 and 13–19 from reproductions). The remaining 155 (T-test and vertical jump 8–11, T-test 16–18 and girls'
   jump 17–18 repeating the nearest cited age, sit-and-reach 8 and 18, sprint 18) stay flagged "reference pending" in
   the UI; the Cooper teenage figures are not traced to a primary source (S-44). Sources, mapping rules and open leads:
   `docs/domain/norms.md`.
5. **Birthday → orphan works differently from the literal spec** under the default `BIRTH_YEAR` rule: a birthday changes
   nothing; orphans arise at season rollover, and the player's status only flips to ORPHAN when the old season ends
   (the rollover report lists them at once). `BIRTHDAY` mode behaves literally (S-24, R-05).
6. **Clearing a field — resolved in every service.** Update requests name the fields to clear in a `clear` list
   (ADR-0032: athlete 2.1.0 in WP39, core 2.7.0 in WP44, game 2.2.0 in WP45) and the web edit forms send it, so a
   session's plan, a location, a note, an injury's dates or a team alias can be removed (S-36, S-35). Since WP52 the
   app also removes a jersey, edits a match and a member's personal data and the academy's contact e-mail / website.
7. **Players see their own line in the live box score** since WP28 (S-46); no longer a gap.
8. **Billing is seams only** (S-15, S-16; the application admin hub shows a Billing placeholder, WP99). The outbox is
   published since WP67 (Redpanda, ADR-0036), and since 2026-11-10 game and athlete serve their roster from replicas
   of those events by default (ADR-0037 amendment, WP98, WP100; `just events-drift` checks them; V-01).
9. **CI** is green on GitHub since 2026-11-02 (`ci` incl. OWASP dependency-check with a valid NVD key, `e2e` journey
   on the runner, `images` built, scanned and pushed to ghcr.io), apart from one `trivy-fs` failure on 3b59360 fixed on
   2026-11-06; `ci`, `e2e` and `images` green on bb68194 (WP39), 33441be (WP41), 71e459a (WP50), a99c211 (WP44),
   fbb71ef (WP47) and b2ef8d5 (WP49); fourth round e.g. c9a5af7 (WP62), 107d86d (WP66), 1d2a252 (WP67), e058aff
   (WP69) and cbb19d3 (WP68), with the browser jobs of WP55. Every action is pinned to a commit SHA (WP50). Dependabot opens weekly grouped update PRs (Maven,
   pub, GitHub Actions; the `json-schema-validator` major is ignored, WP43). Mutation testing runs on demand (`just mutation`, WP37: scores 99.1–100 %, baselines kept;
   latest: core 558/560 after WP67, game 438/440 after WP68, athlete 471/471 after WP61/WP69). Fifth round: SAST/DAST
   gates (SpotBugs in `verify`, CodeQL, Semgrep, ZAP API scans; ADR-0045, WP83) and two more workflows `codeql` and
   `semgrep`; an SBOM per image (WP85); all five workflows green at the end of the round (49ba555), after fixes for
   the reds during the round (`docs/HANDOVER.md`). Mutation after WP88/WP84: common 312/313, core 777/778, game 548/550, athlete 687/687, web 430/430.
   Sixth round: a `model-diagrams` CI job (WP94); every workflow green at the end of the round after fixes for the reds
   during it (`docs/HANDOVER.md`); mutation common 337/338, core 925/926, game 525/527, athlete 690/690.
10. **Withdrawn/suspended tenants**: members are blocked at once in core but up to 30 s later in game/athlete (membership
    cache); Keycloak logins themselves stay enabled; both accepted by design on 2026-11-05 (decision 6, ADR-0025: a
    login may belong to other academies); no purge job (R-15).

## A. SPEC.md, sentence by sentence

| ID | Statement (SPEC.md) | Status | Where | Evidence |
|---|---|---|---|---|
| S-01 | Application in Java using a microservices architecture | Implemented | Java 25 / Quarkus 3.40.1; `services/core-service`, `game-service`, `athlete-service` (ADR-0003, ADR-0007); hexagonal per service | `ArchitectureTest` / `AthleteArchitectureTest` / `HoopsArchitectureRules` (ArchUnit); root `./mvnw verify` |
| S-02 | Frontend web, mobile first | Implemented | Flutter Web in `apps/web` (ADR-0004), 360 px layout, bottom bar < 720 px / rail ≥ 720 px; one design system for the whole app since WP72–WP75 (tokens, theme, kit `core/ui/kit.dart`, AA button contrast; ADR-0040) | goldens at 360×780 (`test/golden/goldens/*`, re-recorded per feature in light and dark, WP72–WP77), `navigation_roles_test.dart`, `contrast_test.dart`, `theme_test.dart`, kit widget tests (`test/core/ui/`) |
| S-03 | "Progressive loading application kind of thing" (PWA) | Implemented | manifest + icons, deferred libraries per feature (160 `*.part.js`), own caching `web/sw.js` (ADR-0018), update banner | `sw_manifest_test.dart`, `service_worker_test.dart`, `csp_hashes_test.dart`, headless-Chrome boot (WP14b); `tool/web_smoke.sh` in Chrome, mock and `--real`, 2026-11-02, mock mode in CI since WP55; WP54: `tool/lighthouse.sh` PWA score 1 (installable manifest, maskable icon, service worker), `tool/offline_cold_start.sh` offline reload from `sw.js` (185 files cached) into a live match. Gap: both WP54 scripts run locally, not in CI |
| S-04 | Backend eventually deployed in Kubernetes | Partial | `deploy/helm/hoops` (umbrella, CNPG, Keycloak, 3 service subcharts, web), `deploy/kind/*` | `deploy/helm/tests/run.sh` (lint, snapshots, kubeconform 85/85, assertions); WP18 `smoke.sh core game athlete` SMOKE PASSED. WP36: chart 0.2.0 on Gateway API (Envoy Gateway v1.9.3, ADR-0031), journey on kind 21/21 green, `ratelimit-check.sh` PASSED. WP40: chart 0.3.0, global rate limits (Envoy rate limit service + Redis, ADR-0033), `ratelimit-check.sh` PASSED with 1 and 2 replicas and Redis down. WP42: journey 21/21 on kind with the mail checks. WP46: chart 0.4.0, Redis ACL and per-second burst caps, `ratelimit-check.sh` (incl. `acl` mode) PASSED with 1 replica, 85 chart checks. WP63: on 0.4.0 with 2 replicas, `tilt ci`, controller restart, journey 21/21. WP65: chart 0.5.0, ExternalSecrets (14/14 synced on kind). WP66/WP71: chart 0.6.0/0.7.0, Redpanda and the services on it, kind smoke 46 checks, 134 chart checks. WP87: chart 0.8.0, Reloader annotations (144 checks). WP86: chart 0.9.0, OpenTelemetry collector (175 checks); on kind `up.sh --eso --deploy --from-host`, a Secret rotation rolled by Reloader, the game replica flip, `events.enabled=false`, `tilt ci`, a trace Envoy → core → game/athlete. Gap: kind only, no other cluster |
| S-05 | Use Podman instead of Docker | Implemented | `scripts/env.sh` (Podman socket for Testcontainers), `podman compose`, `KIND_EXPERIMENTAL_PROVIDER=podman`, images via `podman build` | WP0/WP1/WP16 handovers; every `verify` runs Testcontainers on Podman |
| S-06 | Frontend: avoid Node, use something different | Implemented | Flutter/Dart only; sqlite3.wasm fetched + `dart compile js` for the drift worker (`tool/fetch_web_db_assets.sh`) | no `package.json` in the repo; WP11/WP13. (A one-off `deno` run checked `sw.js` in WP14; not part of the toolchain) |
| S-07 | Backend with docker compose, but with Podman | Implemented | `infra/compose/compose.yaml` (Postgres 17, Keycloak 26.8.1, MailHog, nginx) + `e2e/bin/services-up.sh` | WP1 checks; **e2e journey 20/20 green on compose, three consecutive runs** (WP18b) |
| S-08 | Then, when the app works, kind + Helm + Tilt | Implemented | `deploy/kind/{up,down,secrets,seed-users,smoke}.sh`, `Tiltfile`, `just kind-up` / `just tilt` | WP16: `tilt ci` green for game + athlete + web; WP18: core/game/athlete via Helm + smoke. WP30: the Tiltfile runs `scripts/sync-chart-files.sh` before rendering; WP36: Gateway API routes and rate limits checked on kind; WP40: global rate limits (Redis) checked with 1 and 2 Envoy replicas; WP42: `just tilt ci -- --from-host` "All workloads are healthy" with core, game, athlete and web on a fresh cluster (5 min 55 s) |
| S-09 | Write tests for everything | Partial | JUnit 5/AssertJ/jqwik/REST Assured/WireMock/ArchUnit/Testcontainers as non-owner roles; `flutter test`; e2e module | 2,481 JVM tests (last full builds of round 4: contracts 223, common 186, core 871, game 411, athlete 790) plus 4 e2e unit tests, 778 Flutter tests, 23 e2e steps on compose (CI) and 21 on kind (mail checks included); JaCoCo gates (≥ 80 %, domain ≥ 90 %) met; all three CI workflows green since 2026-11-02; mutation testing on demand (PIT, WP37: common 99.1 %, core 99.6 %, game 99.5 %, athlete 100 %; latest core 558/560, game 438/440, athlete 471/471). Browser smoke and login round trip in CI (WP55). Gaps: Lighthouse and airplane-mode scripts local only, several WPs admit code written before its tests. Sixth round: 3,347 JVM tests (contracts 315, common 403, core 1163, game 467, athlete 999, WP98), 1436 Flutter tests, 26 e2e steps on compose with the replica default. Fifth round: 3,047 JVM tests (contracts 279, common 392, core 914, game 468, athlete 994, WP84), 1077 Flutter tests, 26 e2e steps on compose; SpotBugs + find-sec-bugs in `verify`, CodeQL, Semgrep and ZAP API scans in CI (ADR-0045); mutation baselines equal to the scores and a Dart mutation tool for the web rule code (WP88) |
| S-10 | One big git project or several: your choice | Implemented | single monorepo (ADR-0002) | repo layout |
| S-11 | A lightweight database that works well in k8s | Implemented | PostgreSQL 17, one database, schema per service, CloudNativePG on kind (`charts/databases`) | WP16 CNPG clusters healthy, managed roles reconciled; RLS suites. (Postgres rather than an embedded DB: chosen for RLS and CNPG) |
| S-12 | Make sure secrets are not pushed to git | Implemented | `.env` ignored, `.env.example` placeholders, gitleaks pre-commit + CI, realm export without credentials, Secrets from `.env` (ADR-0012) | WP0 (fake AWS key blocked), WP16/WP17 `helm template … \| gitleaks detect --pipe` clean, `gitleaks detect --no-git` hits only in ignored `.env`; `NoBuiltInCredentialsTest` (game, athlete) |
| S-13 | Find skills on clean code, security, TDD on the internet and add them | Implemented | `.claude/skills/{clean-code,owasp-security,test-driven-development,verification-before-completion,systematic-debugging}` (vendored, provenance in `THIRD_PARTY_SKILLS.md`) + 5 project skills | WP0 handover |
| S-14 | A basketball application for basketball academies | Implemented | domain: roster/eligibility, matches/box score, training, health & fitness | whole suite; user guides `docs/guides/*` |
| S-15 | No billing module for the moment | Deferred-v2 | — | roadmap (`docs/roadmap.md`) |
| S-16 | … but prepare for billing as a possible expansion | Partial | `billing.plan` (seeded FREE), `billing.tenant_subscription` (created at onboarding), `EntitlementService` port + `NoopEntitlementService` called from team creation, member invite and player registration; `core.outbox` rows written | `CoreRlsIsolationTest` covers `billing.tenant_subscription`; `PlatformTenantResourceTest` (FREE subscription). Since WP67 the outbox is published to Redpanda, so a billing module could subscribe. Gap: no test of an entitlement denial path; no billing module |
| S-17 | Multitenant: academies must not see each other's contents | Implemented | `tenant_id` + ENABLE/FORCE RLS on every tenant table, non-owner NOBYPASSRLS roles, `app.current_tenant()` raising when unset, `TenantHeaderFilter` 404 for non-members (ADR-0006, ADR-0011) | `CoreRlsSchemaMetaTest`/`CoreRlsIsolationTest`, `GameRlsIsolationTest`, `AthleteGenericRlsIsolationTest`, `TenantRegistryRlsTest`, per-resource `anotherTenants…NotFound`; e2e `secondTenantCannotSeeTheFirstTenantsData` |
| S-18 | Each tenant has four roles: administrator, coach, parent, player | Implemented | `core.membership_role`: ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER (additive) — tenant roles live in the DB, not Keycloak (ADR-0005) | `Members.roleSetsWithAdminFlag` matrices in `MemberResourceTest` & co |
| S-19 | Players belong to categories | Implemented | `age_category` (U8…U18, SENIOR seeded, editable), natural category derived per season; players belong to teams of a category | `CategoryLadderTest`, `AgeCategoryResourceTest`, `PlatformTenantResourceTest` (seeded ladder) |
| S-20 | They cannot be in categories for lower ages | Implemented | `EligibilityEvaluator` → `INELIGIBLE(CATEGORY_TOO_LOW)`; assignment command checks it | `EligibilityPropertiesTest` (jqwik "never lower category"), `EligibilityEvaluatorTest`, `TeamPlayerResourceTest` |
| S-21 | … but some players may play in higher categories | Implemented | `PLAY_UP(n)` with per-tenant `max_play_up_levels` (null = unlimited), `team_player.play_up_levels` | `EligibilityPropertiesTest` (play-up limit), `eligibleTeamsListsOnlyEligibleTeamsInRankOrder`; web play-up badge (`teams_test.dart`) |
| S-22 | A coach trains n age categories | Implemented | derived from `team_staff` rows (any number of teams/categories) → `staffTeamIds` in `/me` and `/internal/authz` | `MeResourceTest` (staffTeamIds), `InternalRosterResourceTest` |
| S-23 | An administrator can also be a coach or a parent or both | Implemented | roles are a union per person | role-set matrices incl. ADMIN+COACH, COACH+PARENT, ADMIN+PLAYER (`MemberResourceTest`, `RoleMatrixTest`, `HealthRoleMatrixTest`, `EventAuthorizationTest`) |
| S-24 | Different teams in a particular age group | Implemented | `team(season, name, alias, age_category, gender_policy)`, unique name per season only | `TeamResourceTest`; e2e `adminCreatesSeasonCategoriesAndTeam` |
| S-25 | On a birthday a player who no longer fits becomes orphan; coach and/or admin fix it by assigning a new group | Deviated | default `age_rule = BIRTH_YEAR` (ADR-0010): birthdays never change the category; the rollover re-evaluates and lists orphans; `BIRTHDAY` rule: hourly sweep after local midnight invalidates + opens a case. Status ORPHAN ⇔ no valid open assignment in a season that has not ended (ADR-0015), so after a rollover the status flips when the old season ends. Fix: `EligibilityCaseService.resolve` / reassign by ADMIN or COACH of the team | `NightlyEligibilityJobTest` (BIRTHDAY day-after, BIRTH_YEAR untouched, idempotent), `RolloverResourceTest` (orphan list + cases), `EligibilityCaseResourceTest`; e2e `rolloverIntoTheNextSeasonProducesAnOrphanWhichIsResolved` (asserts via the report, not `status=ORPHAN`, WP18b fix 5) |
| S-26 | Groups have names or alias, and age category | Implemented | `team.name`, `team.alias`, `team.age_category_id` | `TeamResourceTest`; web team form (`teams_test.dart`) |
| S-27 | Also gender: a male cannot play in girls' groups and vice versa | Implemented | `GenderPolicy.admits` (MALE / FEMALE / MIXED), reason `GENDER_POLICY`; PLAYER requires gender + birth date | `EligibilityPropertiesTest` (gender property), `EligibilityEvaluatorTest` (MALE/FEMALE) |
| S-28 | There may be mixed groups that allow both genders | Implemented | `gender_policy = MIXED` | `EligibilityEvaluatorTest` (MIXED) |
| S-29 | Coach can have an assistant coach; separate role? | Implemented | separate tenant role `ASSISTANT_COACH` with a defined capability set (ADR-0021 §1): match ops, all stats, training, attendance, health; **no** add/withdraw requests, assignments or case resolution | `TeamPlayerResourceTest.roleMatrix` (assistant of the team), `ApprovalPolicyTest`, `EventAuthorizationTest`, `RoleMatrixTest` |
| S-30 | Coach, assistant and parent have access to the match view | Implemented | web Matches destination for every role; server: any member may read matches/roster/feed (ADR-0021 §3). the feed is filtered for everybody but ADMIN / team staff (F-01, WP33, ADR-0030) | `MatchResourceTest`, `match_screens_test.dart` (role variants), `MatchEventFeedRoleMatrixTest` |
| S-31 | In the match view they enter game data and player stats as the game goes (assists, points, turnovers, …) | Implemented | 15 event types (SHOT 1/2/3 made/missed, ASSIST, REBOUND, TURNOVER, STEAL, BLOCK, FOUL kinds, SUB_IN/OUT, PERIOD_START/END, OPPONENT_SCORE, TIMEOUT, VOID, NOTE); offline-first queue with idempotent batch sync (ADR-0014) | `MatchEventResourceTest`, `BoxScoreProjectorTest`, `ProjectionVectorsTest` + Dart `projector_vectors_test.dart`, `sync_worker_test.dart` (50 queued → 50 ACCEPTED → replay 50 DUPLICATE); e2e `coachAndParentEnterEventsAndTheParentIsRestricted`, `replayingTheCoachBatchIsIdempotent` |
| S-32 | A parent can only enter stats of their linked child unless also assistant coach or coach | Implemented | `EventAuthorization`: PARENT → 7 player-stat types for linked players + VOID of own events; staff union wins. Deviation in detail: parents never record clock/period/opponent/subs, and after FINISHED only events recorded before `finishedAt` count | `EventAuthorizationTest` (roles, unions, FINISHED rule), `parentMayRecordStatsOfTheLinkedPlayerAndVoidOwnEventsOnly`; web parent mode (`match_screens_test.dart`, `scoring_rights_test.dart`); e2e step above |
| S-33 | Assistant coach and coach can enter stats for everybody in the team | Implemented | staff of the match's team: any event type for any player | `EventAuthorizationTest`, `MatchEventResourceTest` |
| S-34 | Starting team, minutes played, when they came to the court | Implemented | `match_roster.is_starter`; SUB_IN/SUB_OUT with period + clock; `seconds_played`, `was_starter` projected; event log shows each substitution | `MinutesTest` (re-entry, period boundaries, overtime), vector `substitutions-and-minutes`; `startWithoutStarterIs422` |
| S-35 | Coach, assistant coach and parent can enter injuries and expected return date | Implemented | `injury(occurred_on, body_part, severity, expected_return_on ≥ occurred_on, actual_return_on, OPEN/RECOVERED)`; PARENT for linked players (create/update, not delete); availability derived. **Web**: injury edit dialog (dates, description, return; emptied fields in `clear`, WP48) | `InjuryApiTest`, `HealthRoleMatrixTest`, `HealthDomainTest`; web `health_test.dart` (incl. the edit dialog); e2e `injuryMakesPlayerUnavailableThenMeasurementAndPhysicalTestWithBand` |
| S-36 | Coach and assistant enter the training calendar: location, schedule and training plan | Implemented | schedules (weekday, time, duration, location, validity) materialised 8 weeks ahead in the tenant zone; ad-hoc sessions; `training_session.plan_id` in the API. **Web**: plan picker on ad-hoc sessions and a session edit dialog (WP35); emptied fields are cleared and a plan can be detached (`clear` list, ADR-0032, WP39); plans also reach players through assignments (team/player, due date). Since WP78 (ADR-0041, athlete 2.3.0) a session references any readable plan or template directly (no assignment) through a plan picker, and exercises can be quick-added into the session's own plan | `ScheduleApiTest`, `SessionMaterialiserTest` (DST Madrid, Jakarta), `SessionPlanApiTest`; web `calendar_test.dart`, `schedules_absences_test.dart`, `session_edit_test.dart`; e2e `scheduleMaterialisesSessionsAndAttendanceHonoursPlannedAbsence` |
| S-37 | Predefined training plans, and the coach can also enter their own | Implemented | 10 global templates (`R__plan_templates.sql`, texts in es/en/id from `Accept-Language` since WP61, ADR-0039), copy-on-use into the tenant; own plans with items, reorder, archive; plan search also matches item titles (`matchedItems`, WP78) and items are copied into a plan or session (quick-add). Since WP92 (ADR-0047, athlete 3.0.0) an exercise catalogue: 60 global exercises (the template items plus the Cooper test, es/en/id, read-only) and the academy's own (created, edited, archived by plan managers); templates reference it; quick-add from the catalogue in the session, the new-session dialog and the plan editor | `ExerciseApiTest`, `ExerciseRoleMatrixTest`, `ExerciseRlsIsolationTest`, `ExerciseCatalogueMigrationTest`, `ExerciseCatalogueContractTest`; web `exercise_catalogue_test.dart`; `SessionQuickAddApiTest`, `TemplateSeedTest`, `TemplateRlsIsolationTest` (templates read-only), `TrainingPlanApiTest`; web `plans_test.dart`; e2e `planCopyOnUseAssignmentAndCompletion` |
| S-38 | Overall admin manages tenants: sign up and withdraw tenants | Implemented | `/platform/tenants` create (tenant + FREE subscription + seeded categories + first ADMIN login, saga ADR-0013), suspend, reactivate, withdraw (retention `P365D`); `super_admin` realm role. Sign-up is invitation-only since WP90 (ADR-0044, core 3.3.0): a visitor requests an academy from the landing page (`POST /platform/academy-requests`, anonymous, 202, honeypot, rate-limited), the super admin accepts (the academy is created with the requester as first ADMIN) or rejects with a reason, and core e-mails the decision; the super admin also lists, adds, edits and removes each academy's administrators (`/platform/tenants/{id}/admins`, ADR-0023). A new login's temporary password is returned once and Keycloak forces a new password at the first sign-in; no setup e-mail (ADR-0024, re-issue while PENDING). Since WP99 (ADR-0049) the web console is an application admin hub (Academies, Users across academies through `GET /platform/users` of core 3.4.0, Pending approvals, Audit trail with CSV export, Billing placeholder) reached through a context switcher | `PlatformUserResourceTest`, `PlatformUsersContractTest`; web `context_landing_test.dart`, `platform_users_test.dart`; `PlatformTenantResourceTest` (saga compensation cases), `PlatformAdminResourceTest`, `OnboardingRepairTest`, `KeycloakTemporaryPasswordKeycloakTest` (`-Pkeycloak-it`), `AcademyRequestContractTest`, `domain.signup` tests; web `platform_test.dart`, `academy_requests_test.dart`; e2e steps 70–71 (request, accept, decision mail, first login; rejection mail); e2e `superAdminCreatesTenantWithFirstAdmin`, `firstAdminSignsInWithTheTemporaryPasswordAndMustChooseTheirOwn`, `suspendedTenantAnswersNotFound…` |
| S-39 | … can see how many teams, players, games and other usage statistics | Implemented | `GET /platform/tenants/{id}/usage` aggregating core + game + athlete `/internal/usage` (`unavailableServices` on failure), daily snapshots + `/usage/history` | `TenantUsageResourceTest`, `TenantUsageHistoryResourceTest`, `UsageSnapshotJobTest`, `UsageAndInternalApiTest`; web usage dashboard and trend chart (`platform_test.dart`, WP35); e2e `platformUsageShowsTheCounts` |
| S-40 | Admin and coach can add or withdraw players; by a coach it needs admin approval | Implemented | `approval_request` ADD_PLAYER / WITHDRAW_PLAYER; ADMIN direct (auto-approved audit row), COACH → PENDING, approval runs the eligibility-checked assignment (ADR-0020) | `ApprovalPolicyTest`, `ApprovalRequestResourceTest` (422 keeps PENDING, double decide 409, concurrent decisions), `PlayerResourceTest`; web `approvals_cases_test.dart`; e2e `adminAddsPlayerAndCoachRequestsOneWhichTheAdminApproves` |
| S-41 | (Approval outcome: rejected requests) | Deviated | a rejected ADD leaves the player `REJECTED` (a fifth status, contracts 2.0, ADR-0016/0020), hidden from non-admins; web labels it "Rejected" (es/en/id, WP28) | `rejectingAnAddLeavesThePlayerRejected…` (core); web `labels_test.dart` |
| S-42 | Coach can enter other physical-education stats, e.g. Cooper test results with date | Implemented | `physical_test_type` (6 global: COOPER_12MIN, SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST, SIT_AND_REACH, BEEP_TEST + tenant types), `physical_test_result(player, date, value)` | `PhysicalTestApiTest`, `HealthRoleMatrixTest`; web `health_test.dart` |
| S-43 | For each, an indication of the expected level for the age | Partial | `BandResolver`: band POOR…EXCELLENT by gender + age at test date + value, tenant norms override global; `bandStatus` MATCHED / NO_NORM / MISSING_PLAYER_DATA; "reference pending" flag in the UI | `BandResolverTest`, `NormSeedTest`; web `charts_test.dart`. **Data gap**: 475 of 630 norm rows sourced (WP27, WP62; see S-44) |
| S-44 | (Expected levels must be real reference values) | Partial | sourced (475 of 630 rows, WP27 + WP62): BEEP_TEST 8–18 (FitBack 2023), SIT_AND_REACH 9–17 (Catley & Tomkinson 2013), SPRINT_20M 8–17 (Cossio-Bolaños 2026), AGILITY_T_TEST and VERTICAL_JUMP 14–15 (Mascherini 2022), AGILITY_T_TEST 12–13 (Lesinski 2020), VERTICAL_JUMP 12–17 (Leone 2025), COOPER_12MIN 8–12 (Balague 1982) and 13–19 (Cooper 1968 as reproduced, primary not obtained); the other 155 rows are placeholders flagged `reference_pending` (`docs/domain/norms.md`) | `NormSeedTest` (placeholders ⇔ flagged pending, band edges per source, ≤ 155 placeholders and ≥ 475 cited, placeholder count per test); WP10b, WP27 and WP62 handovers |
| S-45 | Each player has weight and height, modifiable by parents, coach and assistant coach | Implemented | `body_measurement(player, measured_on, height_cm, weight_kg)` unique per day (409 on a same-day race); PARENT linked write; PLAYER read; growth charts | `BodyMeasurementApiTest`, `MeasurementSameDayRaceTest`, `HealthRoleMatrixTest`; web `charts_test.dart` |
| S-46 | Players can see their own stats | Implemented | server: box score returns the PLAYER's own line, season stats for self (`GetPlayerSeasonStats`); web Me → season statistics. web live box score shows the PLAYER's own line and no other (`ScoringRights.ownPlayerId`, WP28) | `StatisticsResourceTest` (self line, season stats visibility); web `profile_test.dart`, `scoring_rights_test.dart`, `match_screens_test.dart` |
| S-47 | … and the training program given by the coach, and mark it done / not done / partially | Implemented | `plan_assignment` fan-out at read time, `plan_completion` DONE / PARTIAL / NOT_DONE by self, linked parent or team staff; progress view | `PlanCompletionApiTest`, `PlanRoleMatrixTest` (102 cases), `PlanProgressTest`; web `plans_test.dart`, `profile_test.dart`; e2e `planCopyOnUseAssignmentAndCompletion` |
| S-48 | Parents and players can record a planned absence | Implemented | `planned_absence(player, from, to, reason)`: PARENT linked, PLAYER self, staff any; shown as `expectedAbsent` on the attendance sheet | `PlannedAbsenceApiTest`, `RoleMatrixTest`; web `schedules_absences_test.dart`; e2e step above |
| S-49 | Coach and assistant record a player late or missing a training | Implemented | `attendance(session, player, PRESENT/LATE/ABSENT/EXCUSED, minutes_late)` by ADMIN / staff of the team | `AttendanceApiTest`, `RoleMatrixTest` (73 cases); web `session_test.dart` |
| S-50 | Plan run by different agents, the adequate model per task (Sonnet/Opus), no Fable except for the plan design | Implemented | PLAN §5 model table; every WP brief names its model; orchestrated per the user's 2026-11-01 update | WP briefs `Model:` lines |

> S-41 and S-44 split a consequence out of the preceding sentence (approval outcome, quality of the reference values) so
> each can carry its own status; S-50 is the process requirement at the end of the spec.

## B. User additions (locked 2026-11-01)

| ID | Statement | Status | Where | Evidence |
|---|---|---|---|---|
| U-01 | UI trilingual from the start: Spanish, English, Indonesian; locale per user with tenant default | Implemented | `apps/web/lib/l10n/app_{es,en,id}.arb` (es template, real Indonesian), Profile language picker → local + `PATCH /api/core/me`; effective locale: user choice > academy `defaultLocale` > es; user guides in es/en/id (`docs/guides/`) | `l10n_keys_test.dart` (key + placeholder parity, not-a-copy), `locale_test.dart` (es/en/id switch, persisted, tenant default); `sign_out_test.dart` (es/en/id strings). Backend Problem `detail` texts are English only (the UI never shows server text) |
| U-02 | Academy logo uploaded by an ADMIN (PNG/JPEG/WebP, SVG sanitised or rejected, ≤ 512 KB, in Postgres, ETag caching) | Implemented | `PUT/GET/DELETE /api/core/tenant/logo`, `core.tenant_logo` bytea, magic-byte detection, SVG and GIF rejected (415), 512 KB (413), ETag/304 + Cache-Control + nosniff (ADR-0009); web upload with client-side checks and app-bar refresh | `TenantLogoResourceTest` (16), `LogoImageTest`; web `logo_validation_test.dart`, `academy_profile_test.dart`, `api_repositories_test.dart` (exact bytes) |

## C. PLAN.md §2 domain rules

PLAN §2 is prose; it is split here into 15 checkable rules (roster & eligibility R-01…R-05, approvals R-06,
match statistics R-07…R-11, training R-12, health & fitness R-13, authorization matrix R-14, tenant withdrawal R-15).

| ID | Rule (PLAN §2) | Status | Where | Evidence |
|---|---|---|---|---|
| R-01 | Person / membership model: PLAYER requires birth date + gender; `player.status` PENDING_APPROVAL / ACTIVE / ORPHAN / WITHDRAWN; guardian links | Deviated | as planned plus status `REJECTED` (ADR-0016) | `PersonTest`, `PlayerStatusDerivationTest`, `GuardianLinkResourceTest`, `V8__player_rejected.sql` check |
| R-02 | Seasons non-overlapping with a reference year; categories seeded U8…U18, SENIOR, editable; teams with gender policy; a player may be on several teams; `team_staff` is the single source of "coach trains N" | Implemented | `V5__roster.sql`; non-overlap by trigger + advisory lock (no `btree_gist`, ADR-0015) → 409 `SEASON_OVERLAP` | `SeasonTest`, `RosterSchemaTest` (23P01 as `core_app`), `SeasonResourceTest`, `TeamResourceTest`, `CategoryLadderTest` |
| R-03 | Eligibility engine: `AgeFunction` BIRTH_YEAR (default) / BIRTHDAY; `eligibility(player, team, asOf)` → ELIGIBLE / PLAY_UP(n) / INELIGIBLE(reasons: CATEGORY_TOO_LOW, PLAY_UP_LIMIT_EXCEEDED, GENDER_POLICY, MISSING_BIRTH_DATE, MISSING_GENDER, PLAYER_NOT_ACTIVE); invariants | Implemented | `domain.eligibility` (pure, 100 % lines) | `AgeFunctionTest` (Dec-31/Jan-1, Feb-29), `EligibilityEvaluatorTest`, `EligibilityPropertiesTest` (4 jqwik properties × 1000) |
| R-04 | ORPHAN ⇔ ACTIVE player with no valid open assignment | Deviated | scope narrowed to assignments of seasons that have not ended in the tenant zone (ADR-0015 "orphan scope"); consequence under BIRTH_YEAR described in S-25 | `PlayerStatusDerivationTest`, `RolloverResourceTest` (status derivation season scope mutant caught) |
| R-05 | Evaluator never deletes: sets `invalidated_at` + reason and opens an `eligibility_case` (OPEN → RESOLVED by ADMIN or the team's staff); nightly per tenant + synchronous rollover; assignment UI offers eligible teams only | Implemented | `EligibilityEngine`, `NightlyEligibilityJob` (hourly, each tenant after its local midnight, `runExclusive`), `RolloverSeason`, `GET /players/{id}/eligible-teams`. Resolution by ADMIN or COACH of the team (assistants read only) | `NightlyEligibilityJobTest`, `ReevaluationTriggersTest`, `RolloverResourceTest`, `EligibilityCaseResourceTest`, `eligibleTeamsListsOnlyEligibleTeamsInRankOrder`; web `teams_test.dart` (assign verdicts), `approvals_cases_test.dart` |
| R-06 | Approvals: ADMIN executes immediately (audit row), COACH → PENDING, assistants cannot request; ADD creates player PENDING_APPROVAL visible to admins + requester; approval applies the team via the checked command (may 422 and stay PENDING); WITHDRAW keeps ACTIVE until approval; only PENDING decidable; one PENDING per (action, player) | Implemented | `domain.approvals`, `application.approvals` (ADR-0020); plus player login provisioning (WP17) and audit events (ADR-0017) | `ApprovalPolicyTest`, `ApprovalRequestTest`, `ApprovalRequestResourceTest` (`anIneligibleAssignmentFailsWith422AndTheRequestStaysPending`, `twoConcurrentDecisionsHaveExactlyOneWinner`), `PlayerResourceTest` |
| R-07 | Match: SCHEDULED → LIVE → FINISHED / CANCELLED, period count/minutes, roster with display name, jersey, starter | Implemented | `Match` aggregate, `MatchRoster` (denormalised display name/jersey, ADR-0008) | `MatchTest`, `MatchRosterTest`, `MatchResourceTest`, `MatchRosterResourceTest` |
| R-08 | Event = client UUIDv7 id, server_seq, (device, client_seq) unique, 15 types each with a JSON Schema; server validates schema + authz only, never domain consistency (impossible sequences → projection warnings, fixed by VOID) | Implemented | `V2__events.sql`, `libs/contracts/events/match-event.schema.json`, `MatchEventDecoder`, projection warnings (13 codes) | `MatchEventJsonSchemaTest`, `MatchEventDecoderTest`, vector `impossible-sequences-warnings`, `ProjectionPropertiesTest` |
| R-09 | `events:batch` → per-event ACCEPTED / DUPLICATE / REJECTED; row lock; re-projection of player stats + summary; total ordering; `GET /events?after=seq`; minutes from starters + period/sub events | Deviated | as planned, **plus** events are accepted for SCHEDULED and FINISHED matches, only CANCELLED rejects (ADR-0014 §3; `MATCH_NOT_STARTED` reserved, unused); id reused for another match → `EVENT_ID_REUSED` (ADR-0016) | `ConcurrentIngestTest` (overlapping concurrent batches = sequential replay), `repostingABatchIsAllDuplicate…`, `MinutesTest`, `ProjectionVectorsTest`; Dart `sync_worker_test.dart` |
| R-10 | Event authz: staff → any event + transitions; PARENT → player-attributed stat events of linked players, VOID own only, never clock/period/opponent/roster; PLAYER read-only | Implemented | `EventAuthorization` (pure), ADR-0014 §4, ADR-0021 §4 | `EventAuthorizationTest`, `MatchEventResourceTest`; e2e `coachAndParentEnterEventsAndTheParentIsRestricted` |
| R-11 | View match stats: staff all, PARENT linked, PLAYER self | Implemented | box score and season stats are line-filtered on the server, and the event feed by the same rule since WP33 (F-01, ADR-0030); the web live box score shows the PLAYER's own line (S-46, WP28) | `StatisticsResourceTest`, `MatchEventFeedRoleMatrixTest`; security review F-01 |
| R-12 | Training: schedules materialised 8 weeks ahead (idempotent, DST), ad-hoc sessions, plans + items (global templates, copy-on-use), assignment to exactly one of team/player fanned out at read time, completion by self / linked parent / team staff, planned absence, attendance by staff, absence overlay | Implemented | `athlete` V1/V2 + `R__plan_templates.sql`; templates via `owner_tenant_id` (NULL = global) instead of `tenant_id NULL` (WP9, `nullableTenantTables()` hook, ADR-0016 §6); training reads open to all staff (ADR-0021 §5) | `SessionMaterialiserTest`, `ScheduleApiTest`, `NightlyMaterialisationTest`, `PlanDomainTest`, `PlanAssignmentApiTest`, `PlanCompletionApiTest`, `AttendanceApiTest`, `PlannedAbsenceApiTest`, `TemplateRlsIsolationTest` |
| R-13 | Health & fitness: injury → player unavailable; measurements unique per day editable by parent + staff; test types; results; norms (tenant rows override global); expected level = band for (gender, age at measurement, value); seeds cite sources, uncited flagged "reference pending" | Partial | all built (`V3__health.sql`, `BandResolver`, availability endpoint); staff access team-scoped (ADR-0021 §6); availability badge shown in the health view, attendance sheet, team roster and match setup (WP35); 155 of 630 norm rows are still placeholders (S-44, WP62) | `HealthDomainTest`, `InjuryApiTest`, `BodyMeasurementApiTest`, `PhysicalTestApiTest`, `BandResolverTest`, `NormSeedTest`, `HealthRlsIsolationTest` |
| R-14 | Authorization matrix (oracle for role-matrix tests); non-members 404; super_admin only for tenant lifecycle and usage, cannot read tenant content | Implemented | `docs/domain/authz-matrix.md` + refinements ADR-0021; `TenantHeaderFilter`, `@RequiresTenantRole`, `Authz`; super_admin without membership → 404 on `/api/**` (by design). Past seasons (WP80, ADR-0042): a team of an ended season is read-only history for its former staff (`historicStaffTeamIds`) and admins, writes answer 409 `SEASON_ENDED`; structured `hoops.security` event per denial (ADR-0043) | role-matrix suites in every service (`Members.roleSetsWithAdminFlag`, `RoleMatrixTest`, `PlanRoleMatrixTest`, `HealthRoleMatrixTest`, `TeamPlayerResourceTest.roleMatrix`), `RealAuthzResolverTest.superAdminWithoutMembershipGetsNotFound`, `TenantRegistryRlsTest` (platform cannot read tenant tables), `SeasonHistoryContractTest`, `SeasonHistoryTest` (core, game), `SeasonHistoryApiTest` (athlete), web `season_history_test.dart`, `AuthzDenialEventsTest` |
| R-15 | Tenant withdrawal: logins blocked immediately, data retained for a configurable period, purge job v2 | Partial | `TenantLifecycle` (retention `hoops.tenant.withdrawn-retention=P365D`); memberships of SUSPENDED/WITHDRAWN tenants disappear from `/me` and the resolvers. Core blocks at once (cache invalidated); game/athlete after up to 30 s (`hoops.core.cache-ttl`); Keycloak accounts stay enabled (a member of another tenant keeps working there); the 30 s delay and enabled logins are accepted by design (decision 6, ADR-0025). Purge job: Deferred-v2 | `RealAuthzResolverTest.suspendedAndWithdrawnTenantsAnswerNotFound`, `PlatformTenantResourceTest`; e2e `suspendedTenantAnswersNotFoundForItsMembersAndReactivationRestoresIt` (waits for the 30 s caches) |

## D. Explicit v2 / out-of-scope items

| ID | Item | Status | Notes |
|---|---|---|---|
| V-01 | Events v2: transactional outbox publisher + Redpanda + local replicas (WP19, optional) | Implemented | Built behind a switch (decision 48): Redpanda in compose, chart and Dev Services (ADR-0036, WP66); core appends each roster change to the outbox and publishes it to `core.<aggregate>` (ADR-0008 amendment, WP67; `OutboxPublisherJobTest`, 7 event schemas); game and athlete replicas behind `RosterPort` with `hoops.roster.source=rest|replica` (ADR-0037, WP68, WP69; port contract tests on both sources, replay tests, e2e 23/23 with `replica`); chart wiring and a kind proof with the athlete flip (WP71). WP81: producer recovery (`ProducerRecoveryTest`), `.removed` for every aggregate, backfill (`just events-backfill`; on compose the replicas equal core, e2e 23/23 with `replica` in both services); WP82: soft removals and retention jobs; WP86: the game flip on kind. Since 2026-11-10 (decision 66, ADR-0037 amendment "Flip of 2026-11-10") `replica` is the default roster source of game and athlete in the services and compose (WP98: `RosterSourceDefaultsTest` per service, `just events-drift` and its 49-check test, e2e JourneyTest 26/26 on the replica default) and in chart 0.10.0 wherever events are on (WP100: chart tests, kind `smoke.sh` "roster source: game replica, athlete replica", `just events-drift --kind` equal); `rest` stays the fallback switch (runbook `events.md` "Rollback to rest"). Left: game still starts on `replica` with its consumer switched off, a combination athlete refuses (WP98 open point) |
| V-02 | Purge job for withdrawn tenants, push notifications, native images, Pact broker | Deferred-v2 | PLAN §8; roadmap |

## Deviations, stated plainly
These are the places where the system knowingly differs from a literal reading of the spec or plan. Each has a recorded
reason; none is a silent gap.

| Topic | What the system does | Recorded in |
|---|---|---|
| Event ingest for SCHEDULED / FINISHED matches | accepted (only CANCELLED rejects); a final rejection would lose events recorded offline before the start call arrived. After FINISHED staff may correct; parent events only if recorded before `finishedAt` | ADR-0014 §3, ADR-0016 |
| Orphans under `BIRTH_YEAR` | birthdays change nothing; orphans arise at rollover; status ORPHAN only once the old season has ended (the rollover report and cases show them immediately) | ADR-0010, ADR-0015, WP18b fix 5 |
| Rejected players | fifth status `REJECTED` (rows kept for audit, hidden from non-admins, e-mail stays reserved) | ADR-0016, ADR-0020 |
| Assistant coach permissions | separate role; match + stats + training + health, but no player add/withdraw requests, assignments or case resolution | ADR-0021 §1 |
| Parents entering stats | linked players only, 7 stat types + VOID of own events; never clock, periods, opponent score, substitutions | ADR-0014 §4, ADR-0021 §4 |
| Coach add / withdraw | always through an approval request unless the coach is also ADMIN; withdraw only for players on own teams | ADR-0020 |
| Cooper / fitness norms | 475 of 630 rows cited (WP27, WP62); the other 155 are placeholders flagged "reference pending"; Cooper 13–19 from reproductions, not the primary paper | `docs/domain/norms.md`, WP10b, WP27, WP62 |
| Offline cold start | Flutter's worker caches nothing; own `sw.js` instead; exercised in Chrome by `tool/offline_cold_start.sh` (WP54, locally) | ADR-0018, WP54 |
| super_admin and tenant content | cannot read tenant content without a membership (404), sees counters only | PLAN §1.3, ADR-0021 §8 |
| Billing | extension points only (tables, noop `EntitlementService`, published outbox events), no module | PLAN locked decisions, V-01 |
| Kubernetes | deployed and smoke-tested on kind (game/athlete/web via Tilt; core/game/athlete via Helm); edge is Gateway API with Envoy Gateway with global rate limits (Redis with an ACL, per-minute and per-second rules); the e2e journey is green on kind with its mail checks and `tilt ci` is green (WP42, WP63); Secrets optionally from the External Secrets Operator; Redpanda and the services' event wiring behind `events.enabled` (kind smoke 46 checks); Reloader on Secret rotation and an OpenTelemetry collector (WP86, WP87); no other cluster | WP16, WP18, WP36, WP40, WP42, WP46, WP63, WP65, WP66, WP71, WP86, WP87, ADR-0012, ADR-0031, ADR-0033, ADR-0036, ADR-0046 |
| Browser tests | `integration_test` + `tool/web_smoke.sh` run locally with a hand-installed chromedriver (green in mock and `--real` modes, 2026-11-02; mock mode again in WP41, WP47 and WP53); in CI since WP55 (mock-mode smoke in `ci`, login round trip in `e2e`); Lighthouse and the airplane-mode script locally (WP54) | WP11, WP18, WP54, WP55 |
| Health vs training visibility | health data team-scoped for staff, training data tenant-wide for staff | ADR-0021 §5–6 |
| Session sign-out | no `offline_access`; sign-out wipes the offline DB after warning about unsynced events | ADR-0019 |
| First sign-in / e-mail verification | no setup or verification e-mail; a server-generated temporary password is shown once to the creator, Keycloak forces a new password at the first sign-in; e-mail ownership is never verified (pre-account hijacking F-22, accepted by design) | ADR-0024, ADR-0025 |
| One login, several academies | an invite of an e-mail that already signs in links that login without asking its owner and reveals that it exists (F-11, accepted by design); logins stay enabled when an academy is suspended or withdrawn | ADR-0025 |

## Verification baseline
- **Backend**: last full verify of the sixth round (WP98 after its rebase, 2026-11-10, `./mvnw -B -ntp -T 1C verify`):
  contracts 315, common-quarkus 403, core-service 1163, game-service 467, athlete-service 999 = **3,347 tests**,
  0 failures, every coverage and SpotBugs gate met. The `e2e` module runs 32 in `verify`: 6 `MailSinkTest` tests and the
  26 `JourneyTest` steps reported as skipped (no `e2e.baseUrl`). CI on `main` green at the end of the round; the reds
  during the round and the run ids are in `HANDOVER.md`.
  (After the fifth round: 3,047 at 49ba555; after the fourth round: 2,481; after the third round: 2,039; CI on 3b59360 after WP37: 1,970; WP26 baseline on
  ec3360e: 1,760; WP20 review: 1,467.)
- **Flutter**: `flutter test` on the combined tree at the WP101 merge: **1436 tests passed** (1077 after the fifth
  round; 1146 after WP92, 1250 after WP99, 1372 after WP97; 865 after
  WP72, 959 after WP76, 997 after WP90, 1005 after WP77; 778 after the fourth round). Goldens re-recorded per feature
  in light and dark (WP72–WP77).
- **Browser**: CI `ci` job `web-browser` (mock-mode smoke) and `e2e` step "Browser login round trip (first sign-in,
  temporary password)" green on `main`. Locally: Lighthouse PWA score 1 (WP54, again WP77), `tool/offline_cold_start.sh`
  green (marker fixed after WP72 in 599d38a).
- **e2e**: CI `e2e` green on every push to `main` (compose stack on the runner; requests and responses validated,
  ADR-0027; ZAP API scans per service since WP83); **26/26** since WP84 (sign-up steps 70–71 with MailHog, WP90; edge
  step 54, WP84). On compose with the replica default (no override) 26/26 (WP98); earlier 23/23 with `replica` set by
  hand (WP81). The test academy of `just seed-academy` (WP103: 23 logins, 10 players with guardians) is equal in core
  and both replicas (`just events-drift`).
- **Security gates**: SpotBugs `BugInstance size is 0` in all four modules; CodeQL High 2 (both accepted false
  positives); Semgrep ERROR 20 (all accepted); ZAP API scans and baseline green; full scan triaged (WP84 re-run,
  `security/review-2026-11.md` "Round 5 SAST/DAST findings").
- **Mutation**: PIT common 337/338, core 925/926, game 525/527, athlete 690/690 (WP96, WP98); Dart tool 430/430 (WP88);
  baselines 99 / 99 / 99 / 100 and web 100 (`quality/mutation.md`).
- **Charts**: chart 0.10.0 (`keycloak` 0.6.0, `hoops-service` 0.8.0); `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED
  (182 checks, kubeconform 278/278, WP100). On kind (WP100, fresh cluster): `up.sh --eso --deploy --from-host` (18/18
  ExternalSecrets), `smoke.sh` 47 checks with both replicas, events off with a quiet core, producer recovery after a
  deleted broker user, core's decision mail in Mailpit, export rate limits, a Redis password rotation rolled by
  Reloader, `just events-drift --kind` equal. On kind (WP86, chart 0.9.0): `up.sh --eso --deploy --from-host` + `smoke.sh`, a rotation
  rolled by Reloader, the game replica flip, `events.enabled=false`, `tilt ci -- --eso --from-host`, traces and logs
  in the collector. Earlier: `ratelimit-check.sh` with 1 and 2 Envoy replicas incl. `acl` and `redis-down` (WP63),
  14/14 ExternalSecrets synced (WP65), `smoke.sh` 46 checks with events end to end (WP71).
