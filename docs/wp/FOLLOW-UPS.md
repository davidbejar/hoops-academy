# Cross-cutting follow-ups (owned by the orchestrator)

Collected from the WP handovers and the WP20 review (2026-11-02); reconciled with the product interview of 2026-11-05
(WP26), with the WP26–WP37 handovers on 2026-11-06, with the WP38–WP42 handovers on the evening of 2026-11-06, with
the WP43–WP51 handovers (third round) later that evening, with the WP52–WP71 handovers (fourth round) that night and
with the WP72–WP90 handovers (fifth round) on 2026-11-07.
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
Decided in the third interview of 2026-11-06 (decisions 34–51). Same mechanics (`wp-round` skill). One kind user
per wave; the web is owned by one WP per wave; wave 4 and 5 are the v2 events work. **All twenty are done**: merged
into `main` on 2026-11-06 in the order WP64, WP55, WP52, WP60, WP63, WP56, WP58, WP53, WP70, WP59, WP65, WP61, WP57,
WP54, WP62, WP66, WP67, WP69, WP68, WP71 (history order; WP71 added by the orchestrator after the WP67/WP69
handovers).

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP52 | Web: match edit, jersey removal, member data and academy contact edits | Sonnet | Done (no contract change; web 690 tests) |
| 1 | WP56 | Realm and services: token audience per service (F-14), refresh-token rotation (F-08) | Opus | Done (ADR-0034; common 1.1.1; F-08, F-14 fixed; e2e 23/23) |
| 1 | WP58 | Core: no-op PATCH audit rows, ended-season team ids, logins for guardians | Opus | Done (ADR-0024 amendment; core 2.8.0; mutation 99.8 %) |
| 1 | WP60 | Game: feed visibility filter in SQL | Opus | Done (ADR-0030 amendment; 4 statements per page; game 324 tests) |
| 1 | WP63 | kind: proofs re-run on chart 0.4.0 (2 replicas, tilt ci, controller restart) | Sonnet | Done (no code change; all proofs passed, journey 21/21 on kind) |
| 1 | WP64 | CI: NVD cache on success only, dependency-check findings reviewed | Sonnet | Done (cache saved on success; 2 CPE false positives suppressed) |
| 2 | WP53 | Web: demo mock role-filtered core reads, COACH on staff, persistence | Sonnet | Done (no contract change; web 713 tests) |
| 2 | WP55 | CI: browser smoke and login round trip on the runner | Sonnet | Done (`web-browser` in `ci`, login round trip in `e2e`; Chrome 157) |
| 2 | WP57 | Keycloak: CSP headers, password blocklist, optional OTP | Opus | Done (ADR-0038; ASVS 6.2.4 met; F-24 fixed) |
| 2 | WP59 | Core 3.0.0: remove the deprecated `resendTenantAdminInvitation` alias | Opus | Done (ADR-0035; core 3.0.0) |
| 2 | WP61 | Athlete: training-plan templates in es/en/id | Opus | Done (athlete 2.2.0; mutation 100 %) |
| 2 | WP65 | Chart: Secrets from the External Secrets Operator | Opus | Done (ADR-0012 amendment; chart 0.5.0; 14/14 synced on kind) |
| 3 | WP54 | Web: PWA installability, airplane-mode cold start, F-07 cache keys | Sonnet | Done (Lighthouse PWA score 1; airplane-mode check green; F-07 fixed; web 777 tests) |
| 3 | WP62 | Athlete: remaining fitness-norm placeholders | Opus | Done (475/630 cited; athlete 679 tests, mutation 100 %) |
| 3 | WP66 | Events infra: Redpanda in compose, chart and kind; Dev Services | Opus | Done (ADR-0036; chart 0.6.0; kind smoke 35 checks) |
| 4 | WP67 | Core: outbox publisher and the event contracts | Opus | Done (ADR-0008 amendment; 7 event schemas; core 871 tests, mutation 99.6 %) |
| 5 | WP68 | Game: roster replica from core events behind `RosterPort` | Opus | Done (ADR-0037; game 411 tests, mutation 99.5 %; e2e 23/23 on replica) |
| 5 | WP69 | Athlete: roster replica from core events behind `RosterPort` | Opus | Done (athlete 790 tests, mutation 100 %; e2e 23/23 on replica) |
| 2 | WP70 | Web: public landing page (teaser, features, roadmap, invitation request placeholder) | Opus (copy by Fable) | Done (no contract change; web 724 tests) |
| 6 | WP71 | Chart: services wired to the broker behind `events.enabled`, outbox and replicas proven on kind (orchestrator addition after the WP67/WP69 handovers: no WP owned the chart) | Opus | Done (chart 0.7.0; kind smoke 46 checks, athlete replica flip proven) |

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

## Plan (2026-11-06, fifth round)
Decided in the fourth interview of 2026-11-06 (decisions 52–63 below). Same mechanics (`wp-round` skill). The web is
redesigned this round: one design-system WP first, then one WP per feature area; one kind user per wave; whole-tree
passes (mutation, security fixes) run last and alone. **All eighteen are done** (WP79 was not used): merged into
`main` on 2026-11-06/07 in the order WP72, WP75, WP87, WP78, WP74, WP83, WP81, WP73, WP89, WP86, WP80, WP76, WP82,
WP85, WP90, WP77, WP88, WP84 (history order; commits in `docs/HANDOVER.md`).

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP72 | Web: design system (tokens, theme, shared widgets, shell) to the landing-page look | Opus | Done (ADR-0040; web 865 tests; 21 new + 16 re-recorded goldens) |
| 1 | WP78 | Athlete: session references any plan directly; exercise search inside templates and quick-add | Opus | Done (ADR-0041; athlete 2.3.0; mutation 100 %; web 890 tests; e2e 23/23) |
| 1 | WP81 | Core: producer recovery, `.removed` events on deletion, backfill and shadow period | Opus | Done (core 3.1.0 backfill op; producer reset; .removed types; core 887 tests, mutation 98.8 %; e2e 23/23 both replicas) |
| 1 | WP83 | CI: SAST (CodeQL, Semgrep, find-sec-bugs) and DAST (ZAP API scan, full scan on kind) gates, findings triaged | Opus | Done (ADR-0045; SpotBugs in verify; CodeQL + Semgrep + ZAP API gates; findings SD-01..SD-08 for WP84) |
| 1 | WP87 | Chart: Reloader on Secret rotation, remaining kind proofs, rate-limit load guard, Testcontainers flake | Opus | Done (chart 0.8.0 Reloader; ADR-0012 amendment; flake root cause; kind proofs moved to WP86 step 0) |
| 2 | WP73 | Web redesign: training, plans, sessions, health and fitness screens | Opus | Done (web 918 tests on the combined tree; kit ListRow details; 10 goldens) |
| 2 | WP74 | Web redesign: live match, match list and match statistics screens | Opus | Done (web 910 tests on the combined tree; 14 match goldens; kit SheetAction key) |
| 2 | WP75 | Web redesign: admin, platform, auth, profile and shell screens | Sonnet | Done (web 877 tests; kit IconTile; platform usage goldens) |
| 2 | WP80 | Season history: read-only access to past seasons for former staff and admins (core, game, athlete, web) | Opus | Done (ADR-0042; core 3.2.0, game 2.3.0, athlete 2.4.0; combined verify green; mutation core 98.8 / game 99.6 / athlete 100) |
| 2 | WP86 | Chart: OpenTelemetry collector, services' logs and traces exported, proven on kind | Opus | Done (ADR-0046; chart 0.9.0; WP87 six kind proofs run; trace Envoy→core→game/athlete) |
| 2 | WP89 | CI: scheduled bump of image digests, chart image tags and kind pins | Sonnet | Done (bump-pins.yml weekly; 12 pins; 5 outdated found) |
| 3 | WP76 | Web: gaps bundle (account console link, template refetch on language, match edit from the list, profile edits, guardian password, sit-and-reach hint) | Sonnet | Done (web 959 tests; 7 items; past-seasons selector) |
| 3 | WP82 | Game + athlete: replica housekeeping (applied/parked retention), `.removed` for every aggregate | Opus | Done (ADR-0037 amendment; game V6 / athlete V9; retention jobs; Kafka Dev Services off in tests; game 450 / athlete 870 tests) |
| 3 | WP85 | Security logging: Keycloak login events, authz-failure events in the services, SBOM in CI | Opus | Done (ADR-0043; security events + metric; realm events 30 d; SBOM per image; combined verify 0 failures) |
| 3 | WP90 | Invitation-only sign-up: request API, super admin workbench, landing form wired, rejection mail | Opus | Done (ADR-0044; core 3.3.0, V17; core 968 tests, mutation 98.9 %; web 997; e2e 25/25 with mails) |
| 4 | WP77 | Landing: language switch in the header, screenshots per locale re-captured from the redesigned app | Sonnet | Done (header language menu; 12 per-locale screenshots; web 1005 tests; Lighthouse PWA 1) |
| 4 | WP88 | Mutation round: wider PIT scope, baselines raised, Dart mutation tool for the web rule code | Opus | Done (PIT common 210/211, core 777/778, game 548/550, athlete 687/687; Dart tool 430/430; web 1077 tests on the combined tree) |
| 5 | WP84 | Security fixes: every SAST/DAST finding of WP83 fixed or accepted, review file updated | Opus | Done (SD-01..SD-08: 7 fixed, SD-03 accepted; e2e 26/26; all gates green) |

### Decisions of 2026-11-06, fourth interview (product owner)
52. **UI redesign → WP72, WP73, WP74, WP75 (WP77 at the end)**: the whole app takes the landing page's look this
    round: a design system first (tokens, theme, shared widgets, shell; ADR-0040), then every feature area; goldens
    re-recorded per feature; the landing screenshots re-captured only at the end.
53. **Session plans → WP78**: a session item references any plan directly (tenant plan or global template) by id; no
    assignment needed; assignment stays as an optional shortcut (pre-fills suggestions); templates stay read-only
    (copy to edit, as today). Athlete 2.3.0.
54. **Exercises → WP78 now, catalogue next round**: this round the plan/session search finds an exercise inside a
    template (typing "cooper" finds it) and one or several template items can be quick-added to a session or plan
    without going through the template. Next round: an exercise catalogue as its own entity (global localised ones
    plus tenant-defined), templates referencing it (athlete 3.0.0). Templates stay as curated collections.
55. **SAST and DAST → WP83 (tools), WP84 (fixes)**: all of them: CodeQL (Java, security-extended), Semgrep (Java and
    Dart rulesets, container), SpotBugs/find-sec-bugs in `verify`, a ZAP API scan per service driven by the OpenAPI
    contracts with a logged-in token in CI, a ZAP full scan against nginx/Keycloak on kind by hand; findings fixed in
    a second, last WP and recorded in the review file.
56. **Mutation round → WP88**: extract pure rules so PIT covers use cases and container-only code; baselines raised
    to the current scores (core 99.6, game 99.5, athlete 100); a Dart mutation tool (no Node) for the web rule code
    with its own baseline; survivors killed.
57. **Landing language and screenshots → WP77**: language switch moves to the header; screenshots stay PNGs,
    captured per locale (es/en/id) from the redesigned app at the end of the round. The existing PNGs are the
    reference for the design system and are not modified before WP72 is complete. (Live mock screens were judged
    too slow for the landing page.)
58. **Sign-up → WP90**: anyone with an admin, coach or parent role may request a new academy; on acceptance the
    requester becomes the academy's first ADMIN; rejection sends an e-mail with the reason; players never request.
    ADR-0044.
59. **Events hardening → WP81, WP82**: the core producer recovers by itself after a failed first SASL login (no
    rollout restart on a fresh install); deletions publish `.removed` events for every aggregate; a core backfill
    appends one `.changed` per aggregate older than WP67 and a documented shadow period measures parked and lag; the
    default stays `rest` (the flip is a later decision). Replica `applied_event` and `parked_event` get retention jobs.
60. **ASVS gaps → WP85, WP86**: Keycloak realm login events with retention and structured authorization-failure
    events in the services (16.3.1, 16.3.2; ADR-0043); CycloneDX SBOM for the images in CI; an OpenTelemetry collector
    in the chart with logs and traces exported (16.4.3; ADR-0046). Breached-password check not now.
61. **Web gaps → WP76**: one Sonnet WP after the redesign: account-console link, templates refetch on language
    change, match edit from the list tile, self-service name and locale edits, guardian temporary password from the
    member page, sit-and-reach unit hint.
62. **Season history → WP80**: past seasons' teams, matches, attendance and health records are readable (never
    editable) by the coaches who were staff then and by admins; a "past seasons" selector in the web lists. ADR-0042.
63. **Infra → WP87, WP89**: Stakater Reloader (pinned) restarts the pods that read a rotated Secret (closes the
    three rotation open points; ADR-0012 amendment); the kind proofs not yet run (events off, game flip, `tilt ci`,
    `--eso` with events, `up.sh --eso --deploy`); a load guard in `ratelimit-check.sh`; the Testcontainers flake;
    a scheduled bump of image digests, chart image tags and kind pins. Optimised Keycloak image not now.

## Plan (2026-11-10, sixth round)
Decided in the interview of 2026-11-10 (decisions 64–74 below). Same mechanics (`wp-round` skill), with two changes:
at most four building agents per wave (the 2-CPU Podman VM), and every brief names the model *and* the reasoning
effort of its agent. Core carries one WP per wave (WP91, then WP96); WP92 carries its own web part because athlete
3.0.0 is breaking; WP100 is the only kind user; WP103 runs on compose after kind is gone; the docs pass is last.
Found while planning: the weekly `bump-pins` workflow failed on its first scheduled run (2026-11-09, run
42629848979, skopeo "Exec format error": an arm64 digest on the amd64 runner) → WP93.

| Wave | WP | Title | Model | Status |
|---|---|---|---|---|
| 1 | WP91 | Core: `GET /platform/users`, own-name edit in `PATCH /me`, events-off producer switch, `ContainerStarts` in core | Opus · high | Running |
| 1 | WP92 | Athlete + web: exercise catalogue (athlete 3.0.0), quick-add in the new-session dialog and plan editor | Opus · high | Running |
| 1 | WP93 | Tooling: bump-pins multi-arch pin, hook false positive with a shell test, Podman machine playbook + doctor | Sonnet · medium | Done (skopeo index pin; hook matcher 49 cases; Podman playbook + doctor) |
| 1 | WP94 | Docs: ER and class diagrams per service, generated and drift-checked | Sonnet · medium | Running |
| 1 | WP95 | Web leftovers: kit follow-ups, Indonesian bottom nav, audit label, landing screenshots out of the precache | Sonnet · medium | Done (web 1091 tests; kit follow-ups; "Laga"; precache en only) |
| 2 | WP96 | Core: preferred jersey number with carry-over, free numbers; server-side CSV exports (roster, audit log) | Opus · high | After wave 1 |
| 2 | WP97 | Web: browser-built exports for player stats, box score and team calendar (CSV, deferred XLSX, ICS) | Sonnet · high | After wave 1 |
| 2 | WP98 | Events flip: `replica` by default in game and athlete, drift check, shared replica code, e2e await | Opus · high | After wave 1 |
| 2 | WP99 | Web: context switcher, application admin hub, own-name edit | Sonnet · high | After wave 1 |
| 3 | WP100 | Chart and kind: replica default, core SMTP, Envoy Gateway v1.10.0, pending proofs, chart 0.10.0 | Opus · high | After wave 2 |
| 3 | WP101 | Web: jersey preference and assignment dialogs, roster and audit export buttons | Sonnet · medium | After wave 2 |
| 4 | WP103 | Seed a test academy through the real API (`just seed-academy`) | Sonnet · medium | After wave 3 |
| 5 | WP102 | Docs pass | Opus · medium | Last alone |

### Decisions of 2026-11-10, fifth interview (product owner)
64. **Scope of the round → WP91–WP103**: the four owner-requested features (super admin hub, jersey numbers,
    exports, exercise catalogue) and four hygiene threads (tooling fixes, chart and kind, model diagrams, the
    leftovers bundle) in one round.
65. **Round size**: at most four building agents per wave; docs-only and script-only agents on top.
66. **Events flip now, with a drift check → WP98, WP100**: `replica` becomes the default roster source of game and
    athlete without the shadow period over days of ADR-0037 (the replica is fresher than the 30 s REST cache; the
    risk is silent divergence, answered by a reconciliation command that compares core's rows with each replica).
    `rest` stays as the fallback switch.
67. **Export formats → WP96, WP97, WP101**: CSV (UTF-8 with BOM) for every export; ICS for the team calendar; a
    real `.xlsx` for the browser-built exports (team calendar, player stats, box score). PDF later.
68. **Export side, hybrid**: the team roster with guardians and the audit log are produced by core, audited and
    rate-limited; player stats, box score and the team calendar are built in the browser from JSON already loaded.
69. **XLSX library on demand only**: loaded when the user asks for an Excel export (Dart deferred import), never in
    the initial bundle and not precached.
70. **Jersey preference → WP96, WP101**: ADMIN and COACH set a player's preferred number; PARENT and PLAYER may
    set it as a wish for their linked or own player; staff decide the real number on assignment.
71. **Super admin navigation → WP91, WP99**: one context switcher lists each academy of the login (e.g. "Hangtuah",
    "Dewa United", "Baskonia") plus "Application admin" for a super admin, each with its own menu; the application
    admin context is a hub (Academies, Users, Pending approvals with a badge, Audit trail, Billing placeholder).
    WP99 first finds out why `superadmin@hoops-academy.com` lands on the audit trail.
72. **Exercise catalogue → WP92** (closes decision 54): the seeded global templates' distinct items become
    localised catalogue exercises (plus the Cooper test) and templates reference them; tenant plan and session items
    keep their own text and gain an optional exercise reference. Athlete 3.0.0, ADR-0047.
73. **Own data → WP91, WP99**: a non-admin member edits their own first and last name; the e-mail stays with the
    admin.
74. **Test academy seed → WP103** (owner's addition to the plan): "Test Academy" created through the real API with
    `testadmin1..2`, `testcoach1`, `testparentplayer1..10` each linked to `testplayer1..10` (players with logins),
    one team with the ten players; every login active with the final shared password `TEST_ACADEMY_PASSWORD` kept
    in `.env`, where the script also records the usernames (`TEST_ACADEMY_USERS`). Sonnet · medium instead of the
    Haiku · max first written (accounts, passwords and tenant data need judgement).

## Open

### Pending user actions
- **Podman API without the idle timeout** (WP87, root cause of the Testcontainers "localhost:2375 failed to respond"
  flake): **applied by the owner on 2026-11-07** (drop-in `~/.config/systemd/user/podman.service.d/no-timeout.conf`
  in the VM; the running service shows `--time=0`). It survives `podman machine stop/start` and host reboots (the VM's
  home is on its disk) and is lost only on `podman machine rm` / `reset` / a re-init: making it re-apply itself is the
  item "Podman machine drop-in: playbook + doctor check" under "Infra, CI, e2e". CI's rootless `podman.socket` has
  the same default.
- **NVD key for Dependabot PRs** (found 2026-11-07, **done by the owner the same day**): a workflow triggered by
  Dependabot sees only *Dependabot* secrets, so `dependency-check` was red on Dependabot PR #5 (run 42367339615,
  `NVD_API_KEY:` empty). A new NVD key (the old one was not kept anywhere) is now the repository secret and the
  Dependabot secret of the same name, and in the owner's `.env` for `just scan`. PR #5 closed and reopened (the old
  run cannot be re-run): `dependency-check` green on the new `ci` run 42376816401 with the Dependabot secret.
- **bump-pins PRs** (WP89): repository settings **done by the owner on 2026-11-07** ("Allow GitHub Actions to create
  and approve pull requests" on, default token permissions read, label `dependencies` present; verified with
  `gh api repos/davidbejar/hoops-academy/actions/permissions/workflow`). The workflow has not run yet (first schedule
  Monday 2026-11-09 05:17 UTC, or `gh workflow run bump-pins`). Left for when the PR arrives: a PR opened with
  `GITHUB_TOKEN` does not start `ci` / `e2e`, so close and reopen it (or move to a PAT / GitHub App token later); its
  Envoy Gateway v1.9.3 → v1.10.0 bump needs the Gateway API matrix check (ADR-0031) and a kind proof before merging.
- **File the Envoy Gateway issue** from `docs/upstream/envoy-gateway-global-ratelimit-descriptor-collision.md`
  (decision 49); drop the `path: /` selector once fixed (item under "Infra, CI, e2e").
- **Local chromedriver** (WP55): the hand-installed one is 156, CI pins Chrome for Testing + chromedriver
  157.0.8103.38; update it when the local Chrome moves.

### Product / contract decisions
- **Jersey number across teams: preferred number and carry-over** (owner, 2026-11-07). The number exists today on
  the *assignment*, not the player: `core.team_player.jersey_number` (optional, `^[0-9]{1,2}$`, "0" ≠ "00"), unique
  among the open assignments of a team (partial unique index; 409 on a clash), set with `AssignPlayerRequest` or
  changed later with `UpdateTeamPlayerRequest` (`clear: [jerseyNumber]` removes it, ADR-0032), edited in the web
  team screen (`JerseyDialog`) and denormalised into the match roster of game. So a player can carry different
  numbers in different teams and a move never breaks uniqueness. Missing: nothing carries over. A new assignment
  starts without a number unless the admin types one, and nobody is told that the player's previous number is free
  or taken on the new team. Wanted: (1) a **preferred number** on the player (`core.player.preferred_jersey_number`,
  same pattern, nullable; `Player` / `UpdatePlayerRequest` with `clear`; editable by ADMIN and COACH, visible to
  PARENT / PLAYER, maybe editable by them as a wish: decision); (2) on **assignment** (`POST /teams/{teamId}/players`)
  without an explicit number: take the preferred number when free on the new team, else the number of the player's
  most recent assignment when free, else none; the response says which rule applied (`jerseySource`:
  `REQUESTED` / `PREFERRED` / `PREVIOUS` / `NONE`) so the web can tell the admin "7 is taken by X; free: 4, 9, 12"
  and offer the dialog at once; (3) a **free numbers** read per team (`GET /teams/{teamId}/jersey-numbers` or a
  field on the roster: taken numbers with the player, so the dialog shows what is free); (4) the roster event
  `core.team_player.changed` already carries the number (game replica) — no change there. Rules: never silently take
  a number from another open assignment; season rollover (`/seasons/{id}/rollover`) keeps the numbers of the copied
  assignments (check that it does today). Core minor (contract + V18), web team/assign dialogs, es/en/id, role-matrix
  tests (who edits the preference). Possibly one WP with the players-screen part of the export WP.
- **Export** (owner, 2026-11-07): nothing can be exported today (no CSV / PDF / ICS endpoint, no library in the
  poms). Wanted, downloadable from the web app (a button on each screen) and as contract endpoints with `Accept` /
  `format=` (CSV first, UTF-8 with BOM for Excel, `;`-safe quoting; PDF later where a printable sheet makes sense):
  (1) **audit log** (core `GET /api/core/audit-events` with the current filters: date range, action; the platform
  variant for the super admin; the same actor masking as the screen, ADR-0029), (2) **player stats** (game
  `/api/game/players/{playerId}/season-stats`: per match rows plus the season totals), (3) **game stats** (game
  box score of one match: both teams, every player line, the event log optional), (4) **team calendar** (the team's
  matches of game and training sessions of athlete over a season: CSV and **ICS** for phone calendars, with the
  venue and the cancel state; needs a cross-service read or a web-side merge of the two lists), (5) **team players
  with coach and parents** (core: the team's roster with each player's person data, age category, eligibility
  state, the team's staff with role, and each player's guardians with contact data; PARENT / PLAYER never get this
  one; it is personal data → audit row `team.roster_exported`, rate-limited, ADMIN and the team's COACH only, see
  `docs/domain/authz-matrix.md`). Decisions needed: formats (CSV + ICS now, PDF later?), the locale of headers and
  dates (the user's, es / en / id), file naming, size limits (paging vs one file), and whether exports stream from the
  services or the web builds them from the JSON it already has (simpler, offline-capable, but no audit row and no
  server-side limits: the roster export at least must be server-side). Each export is a contract change (`text/csv`,
  `text/calendar` responses) in the owning service, generated Dart clients, OpenAPI validation of the new media
  types in the contract tests, a role-matrix test, and goldens for the buttons.
- **Exercise catalogue** (decision 54, next round): exercises as their own entity (global localised ones plus
  tenant-defined), templates referencing them, listed and searchable on their own (athlete 3.0.0). WP78 only finds
  items inside templates and quick-adds copies; the seeded templates have no Cooper item yet (the catalogue should
  bring it; the demo mock has one).
- **Sign-up leftovers** (WP90, ADR-0044): the audit screen has no label for `tenant.request_accepted` (shows the wire
  name; add `auditActionTenantRequestAccepted` in `features/audit`); compose nginx has no `limit_req` for the public
  `/platform/academy-requests` (the gateway limits it, 10/min + 2/s per IP); the requester's name stays optional
  (contract and landing form; decide whether to require it); decided requests (personal data of non-members) are kept
  until the v2 purge job; a crash between claim and onboarding leaves an ACCEPTED request without an academy (runbook
  `onboard-tenant.md` "Requests", Recovery); no retry of a failed decision mail (`notifiedAt` stays empty).
- **Self-service name edit** (WP76): `UpdateMeRequest` carries `locale` only and `PATCH /members` is ADMIN, so a
  non-admin cannot change their own name or e-mail; needs a core contract change. An ADMIN reaches the own member
  record from the profile (`profile-own-data`).
- **Season history details** (WP80, WP76): game's `Match` and athlete's session responses carry no `seasonEnded` flag
  (the web derives it from core's team / season); the matches list without a selected past season still returns
  every season.
- **Stored audit row keeps the super admin's subject** (WP38, ADR-0029 amendment): only the academy read masks platform
  actors; the row itself keeps the `sub` for accountability (by design). The v2 purge job is its only clean-up.
- **`homeAway` of a match with events** (WP52): the contract does not say whether it may change; the edit dialog
  allows it and the server decides.

### Security (from `docs/security/review-2026-11.md`)
- **ASVS gaps left**: breached passwords (6.2.12; not now, decision 60), OTP only optional (6.3.3 Partial by decision
  39).
- **Security logging leftovers** (WP85, WP86): Keycloak's log is not exported over OTLP (Keycloak 26.8
  `opentelemetry-logs` + `telemetry-logs-*`), nor are Envoy access logs or Redpanda's; no signed SBOM attestation
  (cosign / `actions/attest-sbom` need `id-token: write` and a signing decision); retention and integrity of shipped
  logs belong to the environment's backend (16.4.2).
- **Edge headers on kind** (WP84): the chart's Keycloak `ResponseHeaderModifier` (SD-08) is validated by the chart
  tests only, not proven on kind; the chart pins `Host` only when `gateway.hostname` is set (kind accepts any host,
  local only); some Keycloak answers carry `X-Content-Type-Options: nosniff` twice (harmless).
- **Acceptances with an expiry** (ADR-0045): SD-03 Keycloak CORS reflection and the ZAP 40038 false positive until
  2027-05-07 (re-check SD-03 on every Keycloak upgrade); the Semgrep `@PermitAll` of the public academy request until
  2027-05-06; dependency-check suppressions until 2027-05-01 (Infra below).
- **ZAP API scan as a member** (WP83): the scan signs in as the super admin, who is in no academy, so tenant endpoints
  stop at 404/400; a member token with `X-Tenant-Id` (an e2e-created admin) would reach the academy logic.
- **SAST drift** (WP83): the Semgrep registry rulesets (`p/java`, `p/owasp-top-ten`) are fetched at run time, so the
  weekly runs can report new results on old code; Semgrep logs 9 partial-parse warnings (workflow `run:` blocks, a
  Dart mock, a shell file).
- **Keycloak master realm CSP** (WP57): the master realm (admin console, local only with `HOOPS_EXPOSE_KC_ADMIN=true`)
  keeps Keycloak's default CSP, so a local ZAP run with the console exposed reports it.
- **Offline end-session** is skipped, not queued (SSO session lives until its 4 h idle timeout) — accepted, ADR-0019.

### Web app (`apps/web`)
- **Super admin console: a proper admin menu** (owner, 2026-11-07). Today a super admin without memberships lands on
  `/platform`: the academies list (title "Platform", search, status chips, "New academy"), with two header buttons,
  "Requests" (`/platform/requests`, WP90) and "Academies' activity" (`/platform/activity`, WP34), and per academy a
  detail page (admins, usage, suspend/withdraw/reactivate, its activity). A super admin who is also a member lands on
  that academy's hub and reaches the console only through Profile → Platform (WP14). There was never a hub or submenu
  (the console was born as the list in ced3680 and was restyled, not restructured, in WP75), so nothing was lost;
  the owner reports landing on the audit trail: confirm with the account used (memberships? deep link?) before
  building. Wanted: the platform destination becomes a hub like the academy admin hub (WP75), with one sub-screen per
  area and the rail/bottom nav or a hub list to move between them: **Academies** (the current list + detail),
  **Users** (every login across academies: `core.app_user`, with its memberships per academy, e-mail change (WP31),
  temporary password; needs a new contract `GET /platform/users` with search and paging, core minor), **Pending
  approvals** (the sign-up requests from the landing form, WP90: accept creates the academy and its administrator,
  reject mails the requester; the pending count as a badge; the eligibility approvals inside an academy are not this), **Audit trail** (the current platform activity), **Billing** (placeholder screen "coming
  soon" over the v2 seams; no backend). Also: the super admin's landing is the hub, not a sub-screen; a super admin
  with memberships gets the platform entry in the nav (or the switcher), not only in Profile; es/en/id labels, goldens,
  the `web_smoke.sh` platform step and the user guide `docs/guides` updated. Probably two WPs: core `/platform/users`
  (Opus: cross-tenant read of logins, platform read policy as the audit one) and the web hub (Sonnet).
- **Design-system kit follow-ups** (WP72–WP75): `PageBody` / `ContentFrame` centre a narrower section (a bare
  `PageHeader` is centred; worked around with `SizedBox(width: double.infinity)`): stretch sections in the kit;
  `SectionCard` should provide a transparent `Material` for a `CheckboxListTile`; `AsyncBody` still renders
  `EmptyView` for empty lists (switch to `EmptyState`); delete `AppTokens` and `InfoChip` / `ChipTone` once unused;
  point `LandingPalette` at `HoopsColors` (same values today); a fab-clearance constant in `HoopsSize` instead of the
  per-feature copies; a kit `PickerDialog` for the `AlertDialog` + `ListTile` pickers; `TimezoneNote` pads itself
  16 px and does not line up in a `ContentFrame`; the chart card (`GrowthChart`) could become a `SectionCard` when the
  platform usage goldens are re-recorded.
- **Indonesian bottom navigation** (WP77): "Pertandingan" wraps over two lines at 360 px (visible in
  `assets/landing/live_match_id.png`).
- **PWA precache of the landing screenshots** (WP77): the service worker precaches every build file, so an install
  fetches all twelve PNGs (about 900 KB more than before); exclude the other languages from `collectPrecache` or
  quantise the PNGs (no tool on the host). The capture script fails once on a clean tree (run it twice).
- **Quick-add** (WP78): only on the session screen; not in the "new session" dialog, and `copyItemsToPlan` exists in
  the contract but is not wired in the plan editor.
- **Demo mock limits** (WP47, WP53, WP76): members stay ADMIN-only (403); replay re-stamps `createdAt` / `now`-derived
  fields and re-draws temporary passwords; a log from an older mock build may replay differently (bump the `v1` key
  when seeds change); a locale change (`PATCH /me`) is not stored; the logo and long logs share the browser quota; the
  reset reloads without a confirm dialog; roles per academy only by dart-define; plan completions and assignment
  progress filter by visible players, not by team; no suspended-tenant behaviour; no `/internal/usage`; templates are
  not localised by `Accept-Language`; writes on the ended demo team do not answer 409 (the UI hides them). The
  academy-request mock (WP90) sends no mail.
- **Landing contrast** (WP54, WP70): the app's fills are AA since WP72 (contrast test, ADR-0040); the landing's own
  palette is unverified by Lighthouse (no DOM text in the Flutter canvas) and its screenshots are light-theme captures
  in dark mode too.
- **PWA scripts not in CI** (WP54): `tool/lighthouse.sh` and `tool/offline_cold_start.sh` run locally only; the offline
  check runs against the in-process mock API, so the cached-read fallback is covered by unit tests only.
- **`synced_events` keyed by matchId** (WP54): the other cached reads are tenant + person scoped since F-07; this one
  relies on the wipe when another `sub` signs in.
- **Two-tab refresh soak** (WP56): no control run without `SerialRefresh` in a real browser (the unit test and the
  Keycloak test show the failure mode).
- **Web mutation leftovers** (WP88): equivalent mutants in `apps/web/lib` (`backoff.dart`, `game_clock.dart` clamp,
  the projector's dead initial values) could go with small refactors; the roster and training providers are not in the
  tool's manifest.
- **`curly_braces_in_flow_control_structures` lint disabled** (WP49): `dart format` puts `if (x) return y;` on two
  lines (87 infos); the rule is off in `apps/web/analysis_options.yaml` instead of adding braces. Re-enable it with a
  braces-only pass if wanted.
- **Fonts**: glyphs outside Roboto (CJK, emoji, the check / cross in "2 PT ✓" stat labels in Roboto-only captures,
  WP74) render as tofu; bundle a Noto subset if a language needs it.
- **Same-device two-tab clientSeq race** (WP13): accepted for now (second event is `CLIENT_SEQ_CONFLICT`, visible).
- **Dev login origin** (ADR-0022): `flutter run` on :5173 is another origin than Keycloak on :8080, so the address bar
  changes host during a local login (production keeps one origin). Optional: proxy the dev server through nginx on :8080.

### Backend
- **Entity and class diagrams per service** (owner, 2026-11-07). `docs/architecture.md` has Mermaid flowcharts and
  sequence diagrams of the system, nothing at the model level. Wanted, one page per service under `docs/domain/`
  (`core-model.md`, `game-model.md`, `athlete-model.md`): (1) an `erDiagram` of the schema (core 22 tables, game 16,
  athlete 24 by the Flyway files, incl. the `*_ref` replicas, outbox and billing seams) with keys, `tenant_id` and the
  main relations, and (2) a `classDiagram` of the domain layer (aggregates, value objects such as `TenantId` /
  `PlayerId`, ports) per hexagon. Keep them honest: generate the ER part from the live schema (a script in
  `scripts/`, e.g. `scripts/er-diagram.sh` reading `information_schema` of the compose database, or from the Flyway
  files) and the class part from the `domain` packages (a small tool over the sources, or by hand with a drift check
  in `just test` that fails when a `domain` class is missing from the diagram), so they do not rot; link them from
  `architecture.md` and the README. Mermaid renders on GitHub; no new build dependency.
- **Events-off producer warnings in core** (WP86): on kind with `events.enabled=false` core's producer kept connecting
  to `localhost:19092` (2 WARN lines every 6–10 s; game and athlete were quiet). Core needs a switch that keeps the
  producer from being created (set by the chart's `core.events.offEnv`); an env var alone could not address the old
  messaging channel (`MP_MESSAGING_OUTGOING_CORE_EVENTS_ENABLED` crash-looped core, rolled back). Re-check on the
  plain `KafkaProducer` of WP81.
- **Replica housekeeping choices** (WP82, ADR-0037 amendment): `applied_event` retention has a floor of 7 days (the
  tombstone retention; startup refuses less); soft-removed rows are kept for ever (pruning those older than the
  tombstone retention is a possible later step); uninspected parked rows are never deleted (by design); a tenant
  removal is marked, not cascaded.
- **Duplicated test and job code** (WP82, WP88): `RosterBrokerResource` and `ReplicaRetention` (with its rules test)
  exist in both game and athlete; the common-quarkus (test-)jar could host one copy.
- **Decoders on a missing contracts jar** (WP88): they now fail with `NullPointerException` (the message names the
  resource) instead of `IllegalStateException` at startup.
- **Outside PIT** (WP88): athlete `HealthAccess` / `TrainingAccess` / `PlanAccess`, core `RolloverSeason`,
  `EligibilityEngine`, `ManageTenantAdmins` (tested through `@QuarkusTest` only); candidates for pure unit tests.
- **Trigram index for the item search** (WP78, ADR-0041): needs `pg_trgm` created in `infra/db/init` and the chart's
  init (the migrator cannot create extensions); not needed at today's sizes.
- **Core test containers outside `ContainerStarts`** (WP87): core's `KeycloakContainerResource` and its MailHog
  container start without the ping-and-retry; wrap them with `ContainerStarts.start(...)`.
- **Keycloak ahead of the database** (WP22, as ADR-0013): a commit failure right after a successful login update leaves
  Keycloak with the new e-mail; no repair job detects `app_user.email` ≠ Keycloak e-mail yet.
- **Entitlement seam** has no test of a denial path (the noop implementation always allows).
- **Usage snapshots** are never pruned; the snapshot job aggregates tenants sequentially (fine for tens of tenants).
- **Unassigning an invalidated assignment** leaves its OPEN eligibility case open (resolve via the case API).
- **Backfill REJECTED** (WP2c): players rejected before core `V8` stay WITHDRAWN (pre-release data; accepted).
- **Fitness norms, remaining placeholders** (after WP62: 155 of 630 rows): T-test and vertical jump 8–11 (80; best lead
  Moreno-Gonzalez et al., BMC Pediatr 2026, doi:10.1186/s12887-026-07796-1, still behind a bot challenge), T-test 16–18
  and vertical jump girls 17–18 repeating the nearest cited age (45), sit-and-reach 8 and 18 (20), 20 m sprint 18 (10);
  the Cooper teenage table is not traced to a primary source; check the Catley PDF against the BMJ copy. Details:
  `docs/domain/norms.md`.
- **Dependency hygiene**: `dependency:analyze` lists Quarkus extensions as "unused" (false positives, runtime-only) and
  many transitive APIs as "used undeclared"; only `caffeine` in game/athlete was really unused (removed in WP20).

### Infra, CI, e2e
- **Claude commit/push hook: false positive on quoted text** (owner, 2026-11-07): `.claude/hooks/tenancy-gate.sh`
  (PreToolUse on Bash) greps the whole command text for `git commit` / `git push` with `runs_git`, so a command that
  only *mentions* them, e.g. `echo "=== git commit times"; git log ...`, runs the full isolation check (~3.5 min,
  seen 2026-11-07 20:38) before a read-only command. Match the words only at a command position: strip single- and
  double-quoted strings and comments (`#...`) from the command before matching, or tokenise on `;`, `&&`, `||`, `|`
  and test each simple command's first word(s). Keep `git -C dir commit`, `git -c k=v push`, `git --no-pager commit`
  matching; add a shell test file (`scripts/hooks/tenancy-gate.test.sh`) with the positive and negative cases, run by
  `just doctor` or `just test-hooks`. Also surface the hook's result line to the owner: Claude quotes it when it
  reports a commit or push (the hook output reaches only Claude's context).
- **Podman machine drop-in: playbook + doctor check** (owner decision 2026-11-07, both A and B): the `--time=0`
  drop-in for `podman.service` (WP87) lives on the VM disk and is lost on `podman machine rm` / `reset` / re-init; the
  stock `quay.io/podman/machine-os` image cannot carry it. (A) An Ansible playbook in the repo (`infra/podman/
  machine-playbook.yml`; `ansible-playbook` is in the machine image, Podman 6.1.4) that writes the drop-in with explicit
  `core` ownership, for `podman machine init --playbook infra/podman/machine-playbook.yml ...` (runs once after the
  first boot); check whether Podman runs it as root or as `core` before relying on `systemctl --user daemon-reload`
  inside it. (B) A self-healing step in `scripts/doctor.sh` (not `env.sh`: one `podman machine ssh` round trip per
  call): read `systemctl --user cat podman.service` through `podman machine ssh`; when `--time=0` is missing, write the
  drop-in, `daemon-reload`, restart the service when no container is running, and print the effective `ExecStart`.
  Docs: the init command in `docs/runbooks` (or the README dev setup), a line in the `podman-dev-env` skill and in
  HANDOVER "Working conventions". Verification: (B) on the owner's current machine (remove the drop-in, run
  `just doctor`, see it restored); (A) by `ansible-playbook --check` inside the existing VM, a real `machine rm` +
  `init --playbook` only in a quiet window of the owner's choosing.
- **Chart SMTP settings for core** (WP90): core sends the decision mails since core 3.3.0 but the chart sets no mail
  keys, so on kind core falls back to `localhost:1025` and the mails fail (decisions still work, `notifiedAt` empty).
  Needed in the core subchart values: `SMTP_HOST: mailhog`, `SMTP_PORT: "1025"` (kind's Mailpit Service keeps the
  name), `SMTP_START_TLS: OPTIONAL` (`REQUIRED` for a real server), `MAIL_FROM`, `HOOPS_PUBLIC_URL:
  '{{ .Values.global.publicUrl }}'`, and for a real server `SMTP_USERNAME` plus a `secretEnv` `SMTP_PASSWORD` (e.g.
  Secret `hoops-smtp`, key `password`). Mailpit's NetworkPolicy already admits the namespace's pods.
- **Chart version after WP84/WP85** (WP85): the Keycloak template env (event log level), the realm copy and the Keycloak
  route headers changed after chart 0.9.0 without a version bump; bump with the next chart change. Existing kind realms
  keep their event settings until the Keycloak database is recreated (`IGNORE_EXISTING`).
- **Core restart on a fresh install can go** (WP81): `deploy/kind/up.sh` still restarts core after
  `SASL authentication failed`, and `runbooks/events.md` still says "Fresh install: restart core once after the Job";
  since WP81 the producer recovers by itself (`ProducerRecoveryTest`). A kind proof of the recovery is still to run.
- **Envoy Gateway v1.10.0** (WP89): the first `bump-pins.sh --check` found Envoy Gateway v1.9.3 → v1.10.0 (plus mailpit,
  Trivy, Semgrep and the ZAP digest); the Envoy Gateway bump needs the Gateway API compatibility matrix check
  (ADR-0031) and a kind proof before merging. Pin shapes in `values.yaml` / `up.sh` must keep the patterns of
  `scripts/bump_pins.py` (exit 2 otherwise).
- **Envoy Gateway tracing `backendRefs`** (WP86): a Gateway turns `Accepted=False` when a tracing `backendRefs` Service
  has no ready endpoint; the chart uses the collector's DNS name instead. Worth an upstream issue / a note for clusters
  with their own `EnvoyProxy`.
- **Replica lag in the e2e tenant test** (WP82): with `replica` in game and athlete,
  `secondTenantCannotSeeTheFirstTenantsData` can ask game about tenant B before the replica knows it (1–2 s); an await
  on the first game/athlete call for tenant B would make it deterministic.
- **Redpanda outside kind** (WP66): the default (non-kind) sizing is unproven; the bootstrap Job never deletes ACLs or
  changes partition counts.
- **dependency-check suppressions** (WP64): check in a `dependency-check` report that keycloak-admin-client
  CVE-2026-0871 and opentelemetry-api CVE-2026-54285 show as suppressed (else adjust the packageUrl regex); they expire
  2027-05-01.
- **Per-IP limits** (WP40, ADR-0033, accepted): they can be dodged by rotating addresses (an IPv6 /64). The
  minute-boundary doubling is closed by the per-second caps (WP46).
- **Wrong Redis login fails open silently** (WP46): limits stop applying and only `WRONGPASS` / `NOPERM` in the
  `envoy-ratelimit` logs show it; no alert. The Reloader rotation of `RATELIMIT_REDIS_PASSWORD` (WP87) is not proven
  on kind (WP86 proved the database and broker passwords).
- **Envoy Gateway descriptor collision** (WP46): v1.9.3 builds the `sourceCIDR` descriptor without the rule index, so a
  per-minute and a per-second rule on the same route collapse into one; worked around with an always-true
  `path: {type: PathPrefix, value: /}` selector on the per-second rules (ADR-0033 amendment). Filing the drafted issue
  is the owner's action (above); drop the selector once fixed.
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
  The replica decoders of WP68/WP69 use the same 2.0.8.
- **Guava pin**: drop it from the root pom once the Quarkus BOM ships ≥ 33.7.2 (WP30).
- **Optimised Keycloak image** (read-only root FS; KSV-0014 accepted until 2027-03-31; not now, decision 63).

### v2 (by decision)
- **[v2] Events, default flip** (ADR-0037 "When rest flips"): done are the backfill, the producer recovery and
  `just e2e` with `replica` for both services (WP81), the game flip on kind (WP86) and the soft removals (WP82). Left:
  run the backfill once in each environment with pre-WP67 data, a shadow period over days in a shared environment
  (kind or staging) with `hoops_roster_replica_parked_total` at 0 and lag in seconds, then the owner decides the flip.
- **[v2] Fail-stop consumer and health** (WP68, ADR-0037 §5): a consumer that exhausts its retries turns liveness and
  readiness DOWN, so a long database outage restarts game/athlete pods also in `rest` mode (the consumer runs in both
  modes); revisit if it bites.
- **[v2] Billing module** on the existing seams (`billing.*`, `EntitlementService`, outbox events).
- **[v2] Purge job** for withdrawn tenants after the retention period; also the only clean-up of old
  `core.audit_event` rows (decision 8: no separate retention job) and of decided academy requests (WP90).
- **[v2]** Push notifications, native images, Pact broker.

## Resolved
Fifth round (WP72–WP90 without WP79, 2026-11-06/07; each line names the open item it closed):
- WP72, WP73, WP74, WP75, WP77 (decisions 52, 57): **App UI redesign to the landing-page look**: design tokens
  (`HoopsColors` light/dark, spacing, radii, type, motion), a token-mapped Material 3 theme and a shared kit
  (`core/ui/kit.dart`) with a contrast test (ADR-0040, WP72); training, plans, sessions, health and roster (WP73), live
  match, match list and statistics (WP74), admin, platform, audit, profile and shell (WP75) moved onto it with their
  goldens re-recorded. **Landing page language switch and screenshots** (WP77): the language menu sits in the header,
  and the device mock-ups are twelve PNGs captured per locale (es/en/id) from the redesigned app, pinned by a manifest
  test. Kit leftovers are under "Web app".
- WP78 (decision 53, 54): **Training plans in a session without pre-assignment**: a session references any readable
  plan or template directly; **Exercises as first-class, searchable items**, this round's part: `q` finds plans by an
  item title (`matchedItems`, "cooper" finds it) and quick-add copies one or several items into a plan or the
  session's own plan (ADR-0041, athlete 2.3.0). The catalogue entity stays open (decision 54).
- WP80 (decision 62): **Ended seasons** history: past seasons' teams, matches, attendance and health records are
  readable by the former staff (`historicStaffTeamIds`) and admins, every write answers 409 `SEASON_ENDED`
  (ADR-0042; core 3.2.0, game 2.3.0, athlete 2.4.0); WP76 added the "past seasons" selector in the web lists.
- WP76 (decision 61): **Account console link** (profile entry "Account and security" opens `<issuer>/account`),
  **Template language switch** (explicit `Accept-Language`, plan notifiers refetch on a locale change), **Match edit
  entry** (edit from the list tile), **Member edits** (the member dialog keeps the e-mail of a member with a login
  before the request; the name part moved to "Self-service name edit"), **Guardian first login from the member page**
  (`member-issue-password` for a PARENT without login and with an e-mail) and the **sit-and-reach unit hint** (Catley,
  20 cm = toes) in the result list and both dialogs.
- WP81 (decision 59): **core producer never recovers after a failed first SASL login**: the publisher replaces its
  `KafkaProducer` after consecutive failed sends (`ProducerRecoveryTest`, `hoops_outbox_producer_resets_total`;
  ADR-0008 amendment); **Fresh Helm installs need a core restart** is therefore no longer needed (removing the restart
  from `up.sh` stays open). **Deletions publish nothing**: person, player, team, team-player and tenant gain
  `.removed` events (contracts, `CoreEventSchemasTest` 84). The **core backfill** (`POST /platform/events/backfill`,
  `just events-backfill`, core 3.1.0) and the first shadow evidence (416 events on compose, replicas equal core,
  parked 0, lag under 1 s, `just e2e` 23/23 with `replica` in both services) are recorded in ADR-0037.
- WP82 (decision 59): **[v2] Replica housekeeping**: every `.removed` applied as a soft removal in game and athlete
  (state nulled, reads treat it as absent; tenant removal marked, not cascaded), retention jobs for `applied_event`
  (7 days, the floor) and `parked_event` (30 days after an explicit inspection mark), counter
  `hoops_roster_replica_pruned_total` (ADR-0037 amendment; game V6, athlete V9).
- WP87, WP82 (decision 63): **Athlete Testcontainers flake under load**: root cause found (the Podman API service
  closes keep-alive connections idle for 10 s, docker-java never validates pooled connections and Apache HttpClient
  does not re-send a POST); containment `ContainerStarts` (ping, retry on a closed connection) for the test-jar
  resources (WP87) and Kafka Dev Services off in tests with one pinned broker resource per service (WP82); the
  root-cause fix `--time=0` is a pending user action. Also the two weekday-dependent athlete schedule tests (WP78
  710b18f, orchestrator b520476).
- WP87 (decision 63): **Broker Secret rotation restarts by hand**, **Rotation rollout with ESO** and **Rate-limit
  Redis password rotation**: `global.reloader.enabled` (chart 0.8.0) annotates every workload that reads a Secret and
  `deploy/kind/up.sh` installs a pinned, namespaced Stakater Reloader (ADR-0012 amendment); proven on kind by WP86
  for the database and broker passwords (Reloader rolled game-service in the second the Secret changed; CNPG role
  Secrets labelled `cnpg.io/reload`). **Load-sensitive rate-limit checks**: `deploy/kind/load-guard.sh` (2 per CPU)
  makes `ratelimit-check.sh` end INCOMPLETE on a busy machine and gives `smoke.sh` more time.
- WP86 (decision 60, 63): the **kind proofs not run** since WP65/WP71 (WP87's six, run as WP86 step 0 on chart 0.9.0):
  `up.sh --eso --deploy --from-host` complete, `--eso` with the events, the rotation, the game replica flip,
  `events.enabled=false`, `tilt ci -- --eso --from-host` (4 min 32 s). **Log shipping / OTel collector** (ASVS
  16.4.3): chart 0.9.0 `global.observability.enabled` renders an OpenTelemetry collector (traces and logs over OTLP,
  ids stripped from spans), Envoy's edge span and Jaeger in memory on kind (ADR-0046); one trace from Envoy through
  core to game and athlete proven.
- WP85 (decision 60): **Keycloak login events** (16.3.1: realm events and admin events, 30 days, jboss-logging) and
  **authorization-failure logging** (16.3.2: one structured `hoops.security` event per denial,
  `hoops_authz_denied_total{kind}`; `tenant_mismatch` 404 instead of a 500), **SBOM** (a validated CycloneDX SBOM per
  image, workflow artifact, attached as OCI referrers; the ghcr.io attach proven on 054b629, `images` run
  42354136394, after the orchestrator's ORAS fix) (ADR-0043).
- WP83, WP84 (decision 55): **SAST and DAST, next round**: SpotBugs + find-sec-bugs in `verify`, CodeQL
  `security-extended`, Semgrep with repository rules, ZAP API scans per service after the e2e journeys, a ZAP full
  scan by hand, gates with expiring acceptances (ADR-0045, WP83); findings SD-01..SD-08: 7 fixed, SD-03 accepted until
  2027-05-07 (WP84). **Double Referrer-Policy on `/auth/`**: gone with SD-08 (WP84, 5078d40): the Keycloak location
  sets its own headers, so only Keycloak's `no-referrer` remains.
- WP88 (decision 56): **Mutation scope** and **Mutation testing, next round**: pure rules extracted (`ExclusiveLocks`,
  `ProblemMapping`, `BackfillPlan`, `EndedSeasons`, `EventAdmission`, `SeasonClose`), scopes widened, survivors
  killed, baselines = the scores rounded down (common 99, core 99, game 99, athlete 100); a Dart mutation tool for the
  web rule code (`apps/web/tool/mutation`, 430/430, baseline 100, monthly in `mutation.yml`). Found and fixed a 500 in
  athlete's `Accept-Language` parsing. After WP84: common 312/313, core 777/778, game 548/550, athlete 687/687.
- WP89 (decision 63): **Image pins** auto-bump: `scripts/bump-pins.sh` (12 pins: UBI runtime, nginx, redis,
  redpanda, mailpit, Trivy, Semgrep, ZAP, Envoy Gateway, CNPG, ESO, Reloader) and the weekly `bump-pins.yml` PR
  (`runbooks/release.md` §6). The guava pin and the GitHub settings stay open.
- WP90 (decisions 51, 58): **Invitation-only sign-up**: public `POST /platform/academy-requests` (202 whatever
  happened, honeypot, rate-limited at the gateway), a super admin workbench (accept = create the academy with the
  requester as first ADMIN and a temporary password; reject with a reason, e-mailed), decision mails in the request's
  language (ADR-0044, core 3.3.0, V17; e2e steps 70–71). The leftovers are under "Product / contract decisions".
- Orchestrator fixes during the round: Semgrep acceptances for WP81's backfill helpers and WP89's bump tool
  (483d595, 94b755b), the SpotBugs exclusion for the CDI `KafkaEventBroker` (7cdded2), the offline cold-start marker
  after WP72's switcher (599d38a, WP74's open point), the SBOM attach on the rootless runner (054b629), the
  weekday-dependent schedule tests (WP78 710b18f, b520476). Every red run on `main` during the round is listed in
  `docs/HANDOVER.md` "State".
- Already resolved in the fourth round, re-checked: F-07, F-08, F-14 (`security/review-2026-11.md`).

Fourth round (WP52–WP71, 2026-11-06; each line names the open item it closed):
- WP52 (decision 34): **`clear` lists the app does not send yet** (WP44), **Jersey cannot be removed in the app** (WP44)
  and **No match edit UI** (WP45): the web app has a match edit dialog (opponent, home/away, date and time in the
  academy zone, clearable venue, periods while SCHEDULED), a jersey dialog whose empty value sends
  `clear: [jerseyNumber]`, a member personal-data dialog and the academy contact e-mail / website, all clearable.
- WP53 (decision 35): **Demo mock limits** (WP47), the main part: core reads are filtered per role (404 not visible),
  the demo user's staff row is seeded on every academy's home team (`staffTeamIds` follows it), `HOOPS_MOCK_ROLES`
  applies to both academies, successful writes persist in the browser per academy and roles (`hoops.mock.v1.*`) and
  the profile menu resets the demo data. Residual limits stay under "Web app".
- WP54 (decision 36): **Browser-level tests**, the Lighthouse and airplane-mode part: `tool/lighthouse.sh` (Lighthouse
  11.7.1 in a Podman pod) gives PWA score 1 with every installability audit passing; `tool/offline_cold_start.sh`
  reloads the app offline from `sw.js` and opens a live match with the offline banner. **F-07 residual (apps/web)**:
  cached roster, match JSON and own events are keyed by tenant (+ person) (drift schema v2) and the DB is wiped when
  another `sub` signs in (`MatchStore.bindOwner`). Also the missing platform counter labels in es/en/id.
- WP55 (decision 37): **Browser-level tests**, the CI part, and **Browser login round trip in CI**: `ci` job
  `web-browser` runs `web_smoke.sh` in mock mode on pinned Chrome for Testing + chromedriver 157; the `e2e` job runs
  "Browser login round trip (first sign-in, temporary password)" (`tool/ci_login_check.sh`); both green on `main`
  (e.g. runs 42234657432 and 42234657458 on cbb19d3).
- WP56 (decision 38): **F-08 residual (realm)** and **F-14 token audience**: realm audience mappers per client (least
  privilege) with `quarkus.oidc.token.audience` per service, refresh-token rotation with reuse detection, web tabs
  refreshing one at a time (`SerialRefresh`); ADR-0034, common 1.1.1. `offline_access` stays an optional realm scope
  that the web client does not request.
- WP57 (decision 39): **Keycloak CSP hardening** and the ASVS 6.2.4 / 6.3.3 part of **ASVS gaps**: realm
  `browserSecurityHeaders` with a CSP defining every directive (ZAP acceptances for `/auth/realms/` removed but the
  session-iframe one; residual `script-src 'unsafe-inline'` accepted, F-24), a 10,000-entry password blocklist, OTP
  optional for every login (ADR-0038).
- WP58 (decision 40): **No-op PATCH writes an empty audit row** (no row and no write when nothing changes),
  **`staffTeamIds` / `playerTeamIds`** (teams of ended seasons dropped in the academy's time zone) and **Parents via
  the guardian flow** (`createGuardian` gives a guardian with an e-mail a login and temporary password; core 2.8.0,
  ADR-0024 amendment).
- WP59 (decision 41): **Remove `resendTenantAdminInvitation`**: core 3.0.0 drops the alias (ADR-0035); the demo mock
  dropped its path too (99926fd).
- WP60 (decision 42): **Feed filter in SQL**: one statement per page for filtered viewers (recursive CTE over VOID
  chains), checked against `EventVisibility` on 60 random matches; 4 statements per page for every caller (ADR-0030
  amendment).
- WP61 (decision 43): **Template i18n**: the 10 global templates carry es/en/id texts (`name_key` + `i18n` jsonb on the
  existing tables), resolved from `Accept-Language` (header wins, `en` fallback); plans expose `nameKey` (athlete
  2.2.0).
- WP62 (decision 44): **Fitness norms, remaining placeholders**, second pass: 370 → 475 of 630 rows cited (Balague 1982
  Cooper 8–12, Lesinski 2020 T-test 12–13, Leone 2025 vertical jump 12–17); placeholders 260 → 155 (open item
  rewritten).
- WP63 (decision 45): **Not re-run after WP46**: on chart 0.4.0 `ratelimit-check.sh` passed with 1 and 2 Envoy replicas
  (incl. `acl` and `redis-down`), `tilt ci` was green on a fresh cluster, the controller-restart branch of `up.sh`
  restarted on a changed config and not otherwise, the journey ran 21/21 on kind. No code change.
- WP64 (decision 46): **dependency-check NVD cache**: "Save NVD data" runs `if: success()`; the findings below the gate
  were reviewed once (3 hits, 2 CVEs, all CPE false positives, suppressed until 2027-05-01;
  `docs/security/review-2026-11.md`).
- WP65 (decision 47): **External Secrets Operator manifests**: chart 0.5.0 renders 14 `ExternalSecret`s behind
  `externalSecrets.enabled`, `up.sh --eso` installs ESO v2.14.0 with a Kubernetes-provider store; 14/14 synced and a
  rotation proven on kind (ADR-0012 amendment).
- WP66–WP69, WP71 (decision 48): **[v2] Events**, built behind the default `rest`: Redpanda in compose, chart (0.6.0)
  and Dev Services with SASL/SCRAM per service and ACLs (ADR-0036); core's outbox publisher and the seven event
  schemas (ADR-0008 amendment); game and athlete roster replicas behind `RosterPort` with `hoops.roster.source`
  (ADR-0037); the chart wires the services to the broker behind `events.enabled` + `global.events.enabled` (0.7.0) and
  the kind smoke proves publish → apply end to end, with the athlete replica flip. The default flip and housekeeping
  stay under "v2". The game/athlete "Unrecognized configuration key quarkus.kafka.devservices.*" warnings (WP67) went
  away with their Kafka extension (WP68, WP69).
- WP70 (decision 50): public landing page at the anonymous root (`/`, `/welcome`) with the es/en/id copy of
  `docs/marketing/landing-copy.md` and the invitation form as a placeholder (decision 51 stays open).
- Decision 49: the Envoy Gateway descriptor collision issue text is drafted (7b21a48); filing it is the owner's action
  (open item kept).

Earlier rounds:
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
