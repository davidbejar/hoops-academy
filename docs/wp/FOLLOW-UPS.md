# Cross-cutting follow-ups (owned by the orchestrator)

Collected from the WP handovers and the WP20 review (2026-11-02); reconciled with the product interview of 2026-11-05
(WP26), with the WP26–WP37 handovers on 2026-11-06, with the WP38–WP42 handovers on the evening of 2026-11-06 and with
the WP43–WP51 handovers (third round) later that evening.
Grouped by area; **[v2]** marks items that are out of v1 by decision (PLAN §8, roadmap); **→ WPnn** marked an item the plans below assigned to a work package (all closed). Resolved items are listed at the bottom with the WP or decision that
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

## Plan (2026-11-06)
Second round, decided in the interview of 2026-11-06 (decisions 15–23 below); same mechanics (worktrees, waves,
rebase + fast-forward, one docs pass at the end). **All five are done**: merged into `main` on 2026-11-06 in the order
WP38, WP40, WP39, WP42, WP41 (WP39 rebased on WP38 and re-verified).

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP38 | Core: audit actor masked for academy admins, `ApprovalPayload.empty()` removed | Opus | Done (ADR-0029 amended; core 2.6.0) |
| 1 | WP39 | Athlete: `clear` list on update requests (ADR-0032), test-type code edit and delete | Opus | Done (ADR-0032; athlete 2.1.0) |
| 1 | WP40 | Gateway: global rate limiting with the Envoy rate-limit service and Redis (ADR-0033) | Opus | Done (ADR-0033; chart 0.3.0) |
| 2 | WP41 | Web: demo mock for platform and athlete, academy time zone from `/me` | Sonnet | Done (no contract change; web 646 tests) |
| 2 | WP42 | kind: e2e mail checks through Mailpit, `tilt ci` on the Gateway API chart | Sonnet | Done (journey 21/21 on kind with mail checks; `tilt ci` green) |

### Decisions of 2026-11-06 (product owner)
15. **Fitness norms (WP27) stay**: FitBack 2023 for the beep test and the "20 cm = toes" sit-and-reach scale are kept.
16. **Audit actor masking → WP38.** Academy ADMINs keep reading the super admin's free-text `reason`; platform actors
    are shown to them as "Platform administrator" (no subject, person or name). The super admin's view is unchanged.
17. **Clearing fields → WP39.** Update requests get a `clear` list of property names (absent/null = unchanged, named in
    `clear` = set to null). Repository convention (ADR-0032); athlete adopts it now, core and game when they need it.
18. **Gateway rate limits → WP40.** Global rate limiting (Envoy rate-limit service + Redis) replaces the per-replica
    local limits (ADR-0033). No gateway body-size limit: the services' 2 MB limit is the control (accepted).
19. **Academy time zone → WP41.** `/me` already carries `authz.timezone` per membership (WP2c); the web reads it from
    there and drops the tenant-profile call. No contract change.
20. **Test types → WP39.** A custom type's `code` can be changed; a custom type can be deleted unless results reference
    it (409).
21. **Demo mock → WP41.** Mock mode serves `/platform/*` and `/api/athlete/*` so every screen is reachable in the demo.
22. **kind gaps → WP42.** The e2e journey runs the mail checks on kind through Mailpit's API; `tilt ci` is re-run
    against the Gateway API chart and fixed.
23. **Podman VM clock drift**: the hook scripts resync the VM clock before each check (done 2026-11-06,
    `scripts/hooks/_common.sh`); no manual step. `ApprovalPayload.empty()` is deleted in WP38.

## Plan (2026-11-06, third round)
Decided in the second interview of 2026-11-06 (decisions 24–33). Same mechanics; the `dart format` pass runs alone at
the end because it touches every web file. **All nine are done**: merged into `main` on 2026-11-06 in the order WP50,
WP48, WP43, WP45, WP46, WP44, WP51, WP47, WP49 (WP44 rebased on WP45 and re-verified).

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP43 | json-schema-validator 3.x migration (Dependabot #3) | Opus | Done (not migrated: stays 2.0.8, Dependabot ignores the major, #3 closed; migration recorded) |
| 1 | WP46 | Gateway: Redis ACL for the rate-limit service, per-second burst cap | Opus | Done (ADR-0033 amended; chart 0.4.0) |
| 1 | WP48 | Web: injury edit dialog | Sonnet | Done (no contract change) |
| 1 | WP50 | GitHub Actions pinned to commit SHAs | Sonnet | Done (31 refs in four workflows) |
| 2 | WP44 | Core adopts the `clear` list (ADR-0032) | Opus | Done (ADR-0032; core 2.7.0) |
| 2 | WP45 | Game adopts the `clear` list (ADR-0032) | Sonnet | Done (ADR-0032; game 2.2.0) |
| 3 | WP47 | Web: demo mock parity (shared rosters, role filtering) | Sonnet | Done (no contract change; web 668 tests) |
| 4 | WP49 | Web: `dart format` policy (80 columns) and CI check | Sonnet | Done (`just web-format-check` in CI) |
| 3 | WP51 | `wp-round` skill: how a round is planned and run; CLAUDE.md pointer; HANDOVER conventions trimmed | Opus | Done (`.claude/skills/wp-round`) |

### Decisions of 2026-11-06, second interview (product owner)
24. **Dependabot.** Green PRs are merged (done: #1 actions, #2 Maven minor/patch, #4 cupertino_icons 2.0; the
    regenerated Dart clients differed only by whitespace). #3 (json-schema-validator 3.x) is fixed by migration → WP43
    (outcome: not migrated, the strict validator still needs 2.x; see Resolved).
25. **`.claude/skills/flutter-feature/SKILL.md`** front-matter quoting: committed.
26. **ADR-0032 everywhere** → WP44 (core 2.7.0), WP45 (game 2.2.0): null = unchanged, `clear` empties.
27. **Gateway hardening** → WP46: Redis ACL for the rate-limit service and a per-second rule next to the per-minute
    one so a minute-boundary burst cannot double the limit.
28. **Demo mock parity** → WP47: one roster source for the three mocks, role filtering per the authz matrix, data for
    every demo academy.
29. **Injury edit dialog** → WP48.
30. **Dart formatting** → WP49: default `dart format` (80 columns) for `apps/web` (not the generated packages), CI
    check.
31. **Actions pinned to commit SHAs** → WP50; Dependabot maintains them. The kind runbook's 18080 port-forward clash
    with Tilt stays as documented.
32. **Audit storage**: the stored audit row keeps the super admin's subject (accountability); only the academy read
    path masks it (WP38). Accepted. S-08 (`tilt ci` with core) is Implemented, as the docs pass recorded.
33. **Orchestration as a skill → WP51.** The round procedure (interview, briefs, waves, models, merge protocol, docs
    pass) becomes `.claude/skills/wp-round`; CLAUDE.md keeps one pointer line per skill; HANDOVER keeps state and
    environment facts only; memory keeps what the repo cannot derive.

## Plan (2026-11-06, fourth round)
Decided in the third interview of 2026-11-06 (decisions 34–48). Same mechanics (`wp-round` skill). One kind user
per wave; the web is owned by one WP per wave; wave 4 and 5 are the v2 events work.

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP52 | Web: match edit, jersey removal, member data and academy contact edits | Sonnet | Running |
| 1 | WP56 | Realm and services: token audience per service (F-14), refresh-token rotation (F-08) | Opus | Running |
| 1 | WP58 | Core: no-op PATCH audit rows, ended-season team ids, logins for guardians | Opus | Running |
| 1 | WP60 | Game: feed visibility filter in SQL | Opus | Running |
| 1 | WP63 | kind: proofs re-run on chart 0.4.0 (2 replicas, tilt ci, controller restart) | Sonnet | Running |
| 1 | WP64 | CI: NVD cache on success only, dependency-check findings reviewed | Sonnet | Running |
| 2 | WP53 | Web: demo mock role-filtered core reads, COACH on staff, persistence | Sonnet | After wave 1 |
| 2 | WP55 | CI: browser smoke and login round trip on the runner | Sonnet | After WP64 |
| 2 | WP57 | Keycloak: CSP headers, password blocklist, optional OTP | Opus | After WP56 |
| 2 | WP59 | Core 3.0.0: remove the deprecated `resendTenantAdminInvitation` alias | Opus | After WP58 |
| 2 | WP61 | Athlete: training-plan templates in es/en/id | Opus | After wave 1 |
| 2 | WP65 | Chart: Secrets from the External Secrets Operator | Opus | After WP63 |
| 3 | WP54 | Web: PWA installability, airplane-mode cold start, F-07 cache keys | Sonnet | After WP53 |
| 3 | WP62 | Athlete: remaining fitness-norm placeholders | Opus | After WP61 |
| 3 | WP66 | Events infra: Redpanda in compose, chart and kind; Dev Services | Opus | After WP65 |
| 4 | WP67 | Core: outbox publisher and the event contracts | Opus | After WP66, alone |
| 5 | WP68 | Game: roster replica from core events behind `RosterPort` | Opus | After WP67 |
| 5 | WP69 | Athlete: roster replica from core events behind `RosterPort` | Opus | After WP67 |
| 2 | WP70 | Web: public landing page (teaser, features, roadmap, invitation request placeholder) | Opus (copy by Fable) | After WP52 |

### Decisions of 2026-11-06, third interview (product owner)
34. **Web edits → WP52**: match edit dialog, jersey removal, member personal data, academy contact.
35. **Demo mock → WP53**: role-filtered core reads, the demo COACH on the staff list, changes persisted in the
    browser with a reset action.
36. **PWA → WP54**: Lighthouse installability (from a container, no Node on the host), scripted airplane-mode cold
    start, F-07 cache keys by tenant + person.
37. **Browser checks in CI → WP55**: mock-mode smoke in `ci`, login round trip in `e2e`.
38. **Token audience and refresh rotation → WP56** (F-14, F-08; ADR-0034).
39. **Keycloak hardening → WP57**: CSP headers (ZAP acceptances removed), password blocklist, OTP optional for
    everyone (no breached-password extension; ADR-0038).
40. **Core fixes → WP58**: no-op PATCH writes no audit row; ended seasons leave `staffTeamIds`/`playerTeamIds`;
    guardians added with an e-mail get a login with a temporary password (core 2.8.0).
41. **Deprecated alias removed → WP59**: core 3.0.0 (ADR-0035).
42. **Feed filter in SQL → WP60.**
43. **Template i18n → WP61** (athlete 2.2.0).
44. **Fitness norms → WP62**: another research pass on the 260 uncited rows.
45. **kind proofs → WP63**: 2 replicas, `tilt ci`, the controller-restart branch, on chart 0.4.0.
46. **CI → WP64**: NVD cache saved on success only; dependency-check findings below the gate reviewed once.
47. **External Secrets Operator → WP65** (ADR-0012 amendment).
48. **v2 events start → WP66, WP67, WP68, WP69**: Redpanda (ADR-0036), core outbox publisher with event contracts
    in `libs/contracts/events`, game and athlete replicas behind `RosterPort` with `hoops.roster.source` (ADR-0037).
    Not started: billing, the purge job (stay in v2).
49. **Envoy Gateway descriptor collision**: the orchestrator drafts the upstream issue text; the owner files it.
50. **Landing page → WP70.** The anonymous root of the web app becomes a marketing landing page: teaser of what the
    product does, basketball-only positioning, feature areas, roles, why it costs less, roadmap teaser, and two
    calls to action (request an invitation, sign in). The copy (es/en/id) is written by the orchestrator in
    `docs/marketing/landing-copy.md` and used verbatim; an Opus agent builds the page.
51. **Invitation-only sign-up (follow-up, not scheduled).** The landing form is a placeholder for now. The real
    flow: a visitor requests an invitation with name, e-mail, role (academy admin, coach or parent; players cannot
    request a new academy) and academy name (validated against existing academies); the super admin gets a
    workbench of pending requests and accepts or rejects; accepting runs the existing "create academy" logic
    (temporary password, fields prefilled from the request). Open question: what happens when the request comes
    from a parent or a coach rather than an admin (who becomes the academy's ADMIN?). See the Open item.

## Open

### Product / contract decisions
- **Invitation-only sign-up** (decision 51, 2026-11-06; after WP70): request form (name, e-mail, role admin / coach
  / parent, academy name unique), stored platform-side; super admin workbench (pending / accepted / rejected,
  reason); accept = create the academy with the request's data and issue the temporary password (ADR-0024), reject
  = e-mail or nothing (decide); rate-limited and spam-guarded at the gateway; audit rows. To decide before the WP:
  a request by a parent or coach for a new academy (reject, or create the academy with that person as its first
  ADMIN, or hold until an admin confirms); players never request a new academy.
- **`clear` lists the app does not send yet** (WP44): no web dialog edits a member's personal data or the academy's
  contact e-mail / website, so `UpdateMemberRequest.clear` and `UpdateTenantProfileRequest.clear` are unused by the app.
  In all three services an explicit `null` is now "unchanged" (ADR-0032); a client must name the field in `clear`.
- **Stored audit row keeps the super admin's subject** (WP38, ADR-0029 amendment): only the academy read masks platform
  actors; the row itself keeps the `sub` for accountability (by design). The v2 purge job is its only clean-up.
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
- **Jersey cannot be removed in the app** (WP44): the jersey dialog still requires a value (`noteDialog(required:
  true)`), although the API removes a jersey with `{clear: [jerseyNumber]}`.
- **No match edit UI** (WP45): only match creation exists; `MatchesRepository.update` (sends `clear` for an emptied
  venue) is the ready hook for an edit dialog (opponent, date, venue).
- **Demo mock limits** (WP47): core reads are not role-filtered (teams / players lists show everything to PARENT /
  PLAYER); the demo COACH is always staff of Mini A (the staff list does not include the demo user); PARENT + PLAYER on
  one login is only partly handled; plan completions and assignment progress filter by visible players, not by team;
  no suspended-tenant behaviour; `HOOPS_MOCK_ROLES` switches roles in Academia Demo only (Club Norte is the PARENT
  case); no `/internal/usage`; matches and players created in the demo are not persisted across reloads.
- **`curly_braces_in_flow_control_structures` lint disabled** (WP49): `dart format` puts `if (x) return y;` on two
  lines (87 infos); the rule is off in `apps/web/analysis_options.yaml` instead of adding braces. Re-enable it with a
  braces-only pass if wanted.
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
- **No-op PATCH writes an empty audit row** (WP44): `{"phone": null}` (unchanged) still records `member.updated` with
  no fields (pre-existing behaviour for unchanged values).
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
- **Mutation scope** (WP37): rule code reached only by container tests (`TenantScope`, `ProblemExceptionMappers`, use
  cases) is outside PIT's scope; extracting pure rules from them would let PIT cover them.
- **Dependency hygiene**: `dependency:analyze` lists Quarkus extensions as "unused" (false positives, runtime-only) and
  many transitive APIs as "used undeclared"; only `caffeine` in game/athlete was really unused (removed in WP20).

### Infra, CI, e2e
- **Per-IP limits** (WP40, ADR-0033, accepted): they can be dodged by rotating addresses (an IPv6 /64). The
  minute-boundary doubling is closed by the per-second caps (WP46, see Resolved).
- **Rate-limit Redis password rotation** (WP46): Redis reads the ACL file at start and `envoy-ratelimit` reads
  `REDIS_AUTH` at start, so a new `RATELIMIT_REDIS_PASSWORD` needs both restarted together (no checksum trigger;
  documented in `runbooks/rotate-secrets.md`).
- **Wrong Redis login fails open silently** (WP46): limits stop applying and only `WRONGPASS` / `NOPERM` in the
  `envoy-ratelimit` logs show it; no alert.
- **Not re-run after WP46** (WP40/WP46): `ratelimit-check.sh` with 2 Envoy replicas, `tilt ci`, and the branch of
  `deploy/kind/up.sh` that restarts the Envoy Gateway controller when its rate-limit config changes (only the unchanged
  path has run).
- **Envoy Gateway descriptor collision** (WP46): v1.9.3 builds the `sourceCIDR` descriptor without the rule index, so a
  per-minute and a per-second rule on the same route collapse into one; worked around with an always-true
  `path: {type: PathPrefix, value: /}` selector on the per-second rules (ADR-0033 amendment). Report it upstream and
  drop the selector once fixed.
- **No gateway body-size limit** (WP36; accepted, decision 18): Envoy streams bodies; the services reject bodies above
  2 MB with a 413 Problem. A gateway limit needs `BackendTrafficPolicy.requestBuffer`, which buffers every request.
- **Port 18080 while Tilt runs** (WP42): Tilt's Keycloak port-forward holds 18080, so the runbook's 18080 forward for
  the journey on kind only works after `tilt ci` / `tilt up` has exited (use another local port, e.g. 18081). In the
  Tilt UI `mailhog` and the services' NetworkPolicies are still "uncategorized" (pre-existing, cosmetic).
- **json-schema-validator 3.x** (WP43): blocked while `swagger-request-validator` (`openapi-request-validator-core`
  3.0.0, ADR-0027) is built on networknt 2.x (same class names, one classpath). When it moves to networknt 3.x: drop the
  maven `ignore` entry in `.github/dependabot.yml` and apply the migration recorded in the WP43 handover (pass JSON
  text instead of a Jackson 2 tree in `MatchEventJsonSchemaTest`, `MatchEventDecoder`, `EventSchema`; one version in
  the root pom). `MatchEventDecoderTest.schemaViolationMessagesKeepTheirWording` turns red if the wording changes.
- **Keycloak CSP hardening**: realm `browserSecurityHeaders`, so the accepted ZAP alerts under `/auth/realms/` can go
  (`.zap/baseline.conf`). (The CI workflows themselves are green on `origin/main` since 2026-11-02; see Resolved.)
- **dependency-check NVD cache** (2026-11-05): the "Save NVD data" step runs `if: always()`, so a failed or cancelled
  run can save a broken cache that later runs restore (the 2026-11-05 run restored `nvd-Linux-41422780377`, saved by
  the failed run 41422780377, and took 77 min; that cache has been deleted). Save on success only, or delete the key by
  hand (`gh cache delete`) when the job runs > 40 min. No WP yet.
- **Image pins** (WP30): the `ubi9/openjdk-21-runtime` digest is pinned but not auto-bumped (Dependabot covers Maven, pub
  and GitHub Actions only, not Containerfile ARGs, chart image tags or the kind pins); drop the guava pin in the root
  pom once the Quarkus BOM ships ≥ 33.7.2.
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
- WP44 / WP45 (decision 26): ADR-0032 everywhere. Core 2.7.0 carries `clear` on five update requests (tenant profile,
  member, age category, team, team player; `MergePatch` replaced by `PatchBody`, `CLEAR_CONFLICT` for value + clear)
  and game 2.2.0 on `UpdateMatchRequest` (`venue`); the web team, age-category and jersey edits and the demo mocks
  honour it; `UpdateRequestClearListContractTest` lists athlete, core and game as adopted.
- WP46 (decision 27): `ratelimit-redis` has an ACL (`default` off; only user `ratelimit`, `PING`/`INCRBY`/`EXPIRE` on
  the rate-limit keys, password from `.env` `RATELIMIT_REDIS_PASSWORD`) and every limited route a per-second burst cap
  next to its per-minute limit (10/s token + login form, 20/s `events:batch`), so a minute-boundary burst can no longer
  double the limit; `ratelimit-check.sh` incl. the `acl` mode passed on kind (ADR-0033 amendment, chart 0.4.0).
- WP48 (decision 29): injury edit dialog in the health screen (body part, severity, dates, description, expected and
  actual return; emptied fields named in `clear`), for ADMIN, staff and linked PARENT. The edit cannot reopen a
  recovered injury (status stays with the "Mark recovered" action, by contract).
- WP49 (decision 30): `apps/web` (not the generated packages) is formatted with default `dart format` (80 columns);
  `just web-format` / `just web-format-check`, the check runs in the CI flutter job before `flutter analyze`.
- WP50 (decision 31): the 31 `uses:` refs in `ci.yml`, `e2e.yml`, `images.yml` and `mutation.yml` are pinned to commit
  SHAs with the tag as a comment; Dependabot bumps SHA and comment together (`runbooks/release.md`, ASVS V15).
- WP47 (decision 28): the demo mocks share one roster per academy (core owns it; athlete and game read it, ids match),
  filter by role per the authz matrix (`lib/core/mock/mock_authz.dart`: 404 not visible, 403 visible but not allowed)
  and Club Norte has its own core, athlete and game data. Remaining limits under "Web app".
- WP51 (decision 33): the round procedure (interview, briefs, waves, models, merge protocol, traps, docs pass) is the
  skill `.claude/skills/wp-round` with a brief template; CLAUDE.md points to it; HANDOVER keeps state and environment
  facts only.
- WP43 / Dependabot #3 (decision 24): `json-schema-validator` stays on 2.0.8 (3.x cannot share a classpath with the
  strict validator's networknt 2.x); Dependabot ignores its semver-major updates; PR #3 closed on 2026-11-06 with that
  reason. Re-apply the recorded migration later (open item under "Infra, CI, e2e").
- WP38 (decision 16): audit rows with free text: academy ADMINs keep reading the super admin's `reason`, and platform
  actors are masked on the academy path ("Platform administrator", no subject / person / name); the super admin's view
  is unchanged (ADR-0029 amendment, core 2.6.0). Core `ApprovalPayload.empty()` (dead code found by WP37) deleted.
- WP39 (decision 17): update requests can clear a field: athlete's nine `Update*Request` bodies carry a `clear` list
  (absent or null = unchanged, `CLEAR_CONFLICT` for value + clear) and the web edit forms send it (ADR-0032, athlete 2.1.0).
- WP39 (decision 20): test types: a custom type's `code` can be changed (409 `TEST_TYPE_CODE_EXISTS`) and the type
  deleted unless results reference it (409 `TEST_TYPE_HAS_RESULTS`); web edit and delete with confirmation.
- WP40 (decision 18): gateway rate limits are global (Envoy Gateway's rate limit service + Redis `ratelimit-redis`,
  shared by every Envoy replica, fail open); `ratelimit-check.sh` passed on kind with 1 and 2 replicas and with Redis
  down (ADR-0033, chart 0.3.0; ADR-0031 decision 4 replaced).
- WP41 (decision 19): the academy time zone comes from `/me` (`authz.timezone` of the current membership); no tenant
  profile call, device zone as fallback.
- WP41 (decision 21): demo mock serves `/platform/*` and `/api/athlete/*` (every screen reachable; the demo user is a
  super admin unless `HOOPS_MOCK_SUPER_ADMIN=false`); the browser smoke walks training and the platform console.
- WP42 (decision 22): e2e mail checks on kind: `MailSink` detects MailHog v2 or Mailpit v1 and the checks are no longer
  skipped; the journey ran 21/21 on kind with the mail checks (and 25/25 incl. `MailSinkTest` on compose).
- WP42 (decision 22): `tilt ci` on the Gateway API chart with core-service: "All workloads are healthy" on a fresh kind
  cluster in 5 min 55 s; Tiltfile and `values-kind.yaml` needed no change.
- Dependabot (2026-11-06, 625a5f9): weekly grouped version updates for Maven (Quarkus on its own), pub and GitHub
  Actions; automated security fixes enabled in the repository settings. Repository description, topics and the
  AGPL-3.0 license (20f1921) set the same day.
- Podman VM clock drift (decision 23, 2026-11-06): `scripts/hooks/_common.sh` steps the VM clock to the host's when
  they differ by more than 30 s, before the isolation and role checks (`just isolation-check` / `just db-role-check`
  and the Claude hook); verified with a forced 120 s drift. The manual command stays in `docs/runbooks/kind.md`.
- `ci` red on 3b59360, trivy-fs KSV-0014 on WP36's new snapshot `umbrella-tls.yaml` (run 42112940234): the TLS
  snapshot added to the accepted KSV-0014 paths in `.trivyignore.yaml` on 2026-11-06 (same Keycloak finding, accepted
  until 2027-03-31; `trivy fs --scanners misconfig` from the repo root clean on every snapshot).
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
  (2026-11-02); last checked on 2026-11-06: `ci`, `e2e` and `images` green on bb68194 (WP39) and 33441be (WP41), `ci` and
  `e2e` on ba4e948 (WP42) and 625a5f9 (Dependabot); third round: `ci`, `e2e` and `images` green on 71e459a (WP50, the
  first run with SHA-pinned actions), a99c211 (WP44), fbb71ef (WP47) and b2ef8d5 (WP49, first run of the format
  check). Runner-only fixes
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
