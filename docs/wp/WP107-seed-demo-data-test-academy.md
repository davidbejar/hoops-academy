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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
