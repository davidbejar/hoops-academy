# WP26 — Documentation: reconcile with reality, record the 2026-11-05 decisions

Model: Opus. Depends on: nothing (runs in parallel with WP27–WP31). Skills: verification-before-completion.
Worktree: `~/code/hoops-wt/wp26-docs`, branch `wp26-docs`.

The project docs lag the code and CI by a few days, and a product interview on 2026-11-05 settled fourteen open
questions. This WP owns `README.md`, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, `docs/conformance.md`,
`docs/roadmap.md` and `docs/security/review-2026-11.md`; no other WP touches those files.

## Rules for every statement
Verify before you write. Numbers come from commands you run (`git log`, `gh run view`, the surefire totals of a fresh
`./mvnw -B -ntp -T 1C verify`, `cd apps/web && flutter test`), not from older docs. Where a claim cannot be verified,
say so in the text ("not re-run since …") rather than guessing. Keep the existing tone: short, factual, no marketing.

## Known stale statements (fix these, then look for more)
- `README.md` "Project status": says WP0–WP20, 1,467 tests, "browser-level checks and CI workflows have not been run".
  Reality: WP0–WP25 done, CI (`ci`, `e2e`, `images`) green on `origin/main` since 2026-11-02, browser smoke ran.
- `docs/HANDOVER.md`: "secret `NVD_API_KEY` (currently rejected by NVD as invalid)" is wrong (valid since 2026-11-02);
  the "Pending" list must become: (1) make the four ghcr.io packages public (decision 9), (2) dependency-check cache
  note (see below), (3) the WP plan below. Keep the "Working conventions" section (including the Claude hook bullet).
  Add: on 2026-11-05 the NVD cache saved by a *failed* run was restored by a later run and the job ran > 40 min;
  the bad cache (`nvd-Linux-41422780377`) was deleted; the workflow still saves on failure (`if: always()`).
- `docs/wp/FOLLOW-UPS.md`: "NVD key activation" is done; "Withdrawn tenant logins" is decided (6); F-11 and the
  pre-account hijacking item are accepted by design (2, 3); items that now have a WP must point to it.
- `docs/conformance.md` and `docs/roadmap.md`: any "pending" that WP21–WP25 or CI closed.
- `docs/security/review-2026-11.md`: statuses for F-01 (planned, WP33), F-11 (accepted by design), the pre-account
  hijacking note (accepted by design), temporary password expiry (planned, WP32).

## Decisions of 2026-11-05 (record verbatim in meaning; these are the product owner's answers)
1. **Project nature.** Hoops Academy is a learning project, not commercial (yet). Easy sign-up (temporary password,
   reset at first login, no e-mail verification, no consent flow) matters more than closing account-linking gaps,
   because the owner tests by creating many users. One login being a member of several academies is a feature
   (a parent with children in two academies, a coach working for two).
2. **F-11** (inviting an existing login links it and reveals that it exists): accepted by design (1).
3. **Pre-account hijacking** (security review; ADR-0024): accepted by design (1).
4. **Temporary password expiry** → WP32: a temporary password older than 3 days is expired. No scheduler: a sweep
   runs in the background, triggered by a person's first login and by every issuance, one at a time across replicas
   (`runExclusive`). The sweep disables the login in Keycloak (only logins still on their temporary password; never
   one that chose its own), records it on `core.app_user` and in the audit log; Keycloak's `hoops` login theme shows
   "temporary password expired, ask your academy administrator" in es/en/id; re-issue re-enables. Accepted gap: an
   expired login works until the next sweep.
5. **F-01 match event feed** → WP33: PARENT/PLAYER get team-level events plus the events of their own or linked
   players, filtered server-side; the authz matrix and guides follow.
6. **Suspended / withdrawn academy**: logins stay enabled (they may belong to other academies); the up-to-30 s
   membership cache in game/athlete is accepted; no cache invalidation call.
7. **Shared login e-mail** → WP31: when the super admin changes the e-mail of a login used in several academies, every
   academy's `core.person.email` for that login changes in the same transaction (one person, one e-mail).
8. **Audit log** → WP34: ADMIN reads the events of their own academy, super admin reads everything; filters by date
   range and event type. The existing `core.audit_event` table suffices (tenant, actor, action, target, metadata,
   at); names are resolved at read time and never stored; no retention job (v2 purge job).
9. **ghcr.io packages**: make the four packages public (owner's click in GitHub; list the four package URLs in
   HANDOVER "Pending": `https://github.com/davidbejar/hoops-academy/pkgs/container/hoops-academy%2F<name>` for
   core-service, game-service, athlete-service, web — verify the URL form with `gh api` if possible).
10. **Ingress** → WP36 (last): move the chart from ingress-nginx to Gateway API (Envoy Gateway).
11. **Fitness norms** → WP27: research the missing cited tables now.
12. **Orchestration**: work packages run as parallel agents in git worktrees under `$HOME`, merged in waves.
13. **Bugs** → WP28 (web: PLAYER's own box-score line, REJECTED label), WP29 (contract `allOf` +
    `additionalProperties:false`, `MatchEvent` oneOf validation), WP30 (e2e readiness `status == UP`, Tiltfile
    chart sync, pinned `ubi9/openjdk-21-runtime`, guava pin).
14. **Web UX gaps** → WP35 (not-a-member-yet state, tenant timezone, usage chart, session edit/plan picker,
    availability badge, measurement/test/absence editing).

## WP plan (put this table in FOLLOW-UPS under a new "## Plan (2026-11-05)" section, before "## Open")
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

Open items without a WP stay in "## Open" unchanged (F-07/F-08/F-14 residuals, ASVS gaps, template i18n, guardian
logins, entitlement denial test, snapshot pruning, ended-season team ids, deprecated `resendTenantAdminInvitation`
(needs core 3.0.0), Keycloak-ahead-of-DB repair, `tilt ci` with core, PIT, Keycloak image, External Secrets,
Lighthouse / offline cold start / chromedriver in CI, demo mock, fonts, dev login origin).

## ADR
Write `docs/adr/0025-one-login-many-academies-easy-sign-up.md` (same format as 0024) for decisions 1–3 and 6:
context (learning project, testing by creating users), decision (temporary password without verification; a login
may join several academies; existing logins are linked on invite; logins outlive a withdrawn academy), consequences
(the accepted risks named in the security review, with the F-ids), and what would change if the project went
commercial (verification before cross-academy linking, consent on invite).

## Acceptance
- [ ] Every stale statement above fixed; a `grep -rn "1,467\|not been run\|rejected by NVD\|WP0 to WP20" README.md docs`
      finds nothing wrong
- [ ] FOLLOW-UPS has the Plan table, the decided items moved to "Resolved" (with the decision number) or pointed at
      their WP, and nothing lost
- [ ] HANDOVER "State" and "Pending" are true as of the day you write them (date in the title)
- [ ] ADR-0025 written and linked from `docs/adr/README.md` (or the index the others use)
- [ ] Security review statuses updated
- [ ] `git diff --stat` touches only documentation files
- [ ] Handover section appended to this file

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees and share the Podman machine; retry a container start once
  before calling it a failure.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Finish per the `work-package` skill: fresh full verification, checklist with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and numbers), left out and why,
  anything another WP must know.
