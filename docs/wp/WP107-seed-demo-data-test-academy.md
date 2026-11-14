# WP107 — Seed: demo data in the Test Academy that looks like the landing screenshots

Model: Sonnet · effort medium. Wave 1 (2026-11-14, seventh round): runs alongside WP104 (OpenTofu), WP105 (web
shell) and WP106 (core; its changes are not on `main` while you work, and you do not need them). You own
`infra/keycloak/seed-academy.sh` and its helpers, the `seed-academy` recipe in the `justfile`, the "Test academy"
section of `docs/runbooks/local-stack.md` and any new placeholder key in `.env.example`. You change no service
code, no contract and nothing under `apps/web`. Depends on: decision 80, the WP103 brief and handover (how the
script talks to Keycloak and the API, how secrets are handled, idempotency), the browser demo data in
`apps/web/lib/core/mock/**` (what the landing screenshots show), `apps/web/assets/landing/*.png` and
`apps/web/test/golden/landing_screens_capture.dart` (which screens), the e2e `JourneyTest` (request sequences for
matches, sessions and health). Skills: owasp-security, systematic-debugging, verification-before-completion.
Worktree: `~/code/hoops-wt/wp107-seed-demo-data`, branch `wp107-seed-demo-data`.

Decision 80 of 2026-11-14 (owner): **extend the existing Test Academy** (no second academy) with data that looks
like the landing screenshots, so the design can be checked against the real backend with the `test*` logins.

## Scope
1. **What to seed**, through the public API only (no SQL), as the role that may do it: what the four pictured screens
   need and what makes the other screens non-empty. At least: an injured player with an open injury like the
   pictured one, body measurements over time and physical test results for several players; a training week
   (schedule, sessions, a plan with exercises from the catalogue, attendance with some absences); one finished match
   with a full event log (box score, season statistics) and one match in progress with events (the live-match
   screen); jersey numbers; staff on the team. Take names, numbers and shapes from the mock where the API allows it;
   say in the handover where the real API cannot hold what the mock shows.
2. **Idempotent**: a second run changes nothing and fails on nothing (look up before creating, as WP103 does). Dates
   relative to today so the training week and the match stay current; say how the in-progress match behaves on a
   re-run.
3. **Safety** (as WP103): local base URL only unless the existing override is set; never print a password, a token
   or a response body; `shellcheck` clean.
4. **Docs**: the runbook section says what the Test Academy contains after a run and which login shows which screen.

## Acceptance
- [ ] Two consecutive runs against the local stack succeed; the second creates nothing (evidence in the handover)
- [ ] Each seeded area read back through the API with a `test*` login of the matching role (counts in the handover)
- [ ] `just events-drift` reports core and both replicas equal after the run
- [ ] `shellcheck` clean; `gitleaks` clean; nothing secret in the output of a run
- [ ] Handover appended: what is seeded, what could not be, which login to use for each landing screen

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The compose stack is up. The owner may have the services running on 8081–8083 and the web app on 5173 (`./start.sh`):
  if 8081–8083 answer, use them and **never stop them**; only if they do not, start them with `just services-up` from
  your worktree and stop what you started when you finish. You are the only agent that uses these ports.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with a
  `Co-Authored-By:` line that names the model you are.
- `.env` is git-ignored: copy it from `~/code/hoops-academy/.env` into your worktree; never commit it, never print it.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built: the demo phase of `infra/keycloak/seed-academy.sh` (same run; `SEED_ACADEMY_DEMO=0` skips, `SEED_ACADEMY_DEMO_ONLY=1`
  repeats only the demo part), `.env.example` block, runbook subsection "Demo data in the Test Academy" (contents, which
  login shows which landing screen, what the API cannot hold). New: assistant coach `testassistant1` (staff of Test
  Team, a login like the others) and a second team "Infantil A" (coach testcoach1, no players) so the training week has two
  teams like the picture. Seeded through the API as testcoach1 / testadmin1: 3 + 2 schedules; sessions of the last 14 days
  DONE (created by hand: the API materialises schedule sessions only from today) with attendance on Test Team's; one
  cancelled and one plan-carrying upcoming session; plans "Calentamiento Mini" (4 catalogue exercises) and
  "Condicionamiento semanal" (3); one assignment with a completion; a planned absence; matches Lobos (FINISHED 32-25, 99
  events), Tigres (LIVE 4-9, 11 events, starters players 1,2,4,5,7), Aguilas (SCHEDULED); injuries (player 7 open knee,
  player 4 recovered ankle); 3 body measurements and 4 test results for each of players 1,2,4,5,7,8,10.
  Mapping to the pictured names by jersey: Sara 4 = Test Player 1, Iker 5 = 2, Ana 7 = 4, Noa 8 = 5, Leo 10 = 7 (injured),
  Hugo 11 = 8, Lia 13 = 10; names stay "Test Player N".
- Verified: runs against the local stack (services built from this worktree, started by me, stopped at the end): demo-only
  run created 14 things in the last pass, the following full runs reported "nothing to create" (run 3 and run 4, 144 s
  and 240 s under load). Read back with logins: coach: staff 2, roster 10 (jerseys 4-13), schedules 3 + 2, sessions in
  -14..+14 days main 13 (6 DONE, 1 CANCELLED, 6 PLANNED incl. one of the owner's) and Infantil 8, plans 4 + 3 items,
  matches Tigres LIVE 4-9 (events 11, Players 2 and 7 two points each, 10-player roster, starters jerseys 4,5,7,8,10),
  Lobos FINISHED 32-25 (99 events, player lines sum to 32), season stats of player 4 = 2 games 6 points, injuries 2,
  player 7 unavailable until the expected return, 3 measurements and 4 test results (all bands MATCHED), absence 1;
  parent 7 and player 7 read the injury, parent 4 the absence and stats; superadmin reads usage of the academy.
  `just events-drift`: "the replicas equal core", exit 0. shellcheck clean, gitleaks clean, run logs contain no token or
  password.
- Decisions/ADRs: none. Anything found while testing: a first request through the gateway right after the services
  start can give 502 (stale upstream connection); `api` now retries reads on 502/503/504. Dates: the Spanish locale
  prints a decimal comma, so the numbers are formatted with `LC_ALL=C`.
- Open points: (1) the Tigres match stays LIVE for ever (and its start time is that of the first run); (2) measurements
  and test results are found by "the player has any", so their dates stay those of the first run; (3) one session of the
  first, hand-made probe was moved to 2026-10-26 (DONE) instead of being left as a duplicate; sessions of the first run have
  seconds in their start time (harmless, lookups compare to the minute); (4) the owner's own data in the academy (a session
  "A tomar por saco", a match "Los peores") was left untouched; (5) the mock's names, academy name "Academia Demo" and
  third team are not representable on the `test*` logins; (6) a full run takes 1.5-4 minutes (Keycloak logins, gateway
  rate limit).
