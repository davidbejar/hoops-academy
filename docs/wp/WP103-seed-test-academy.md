# WP103 — Seed a test academy through the real API (`just seed-academy`)

Model: Sonnet · effort medium. Wave 4 (2026-11-10, sixth round): starts after wave 3 is merged and the kind cluster
is gone (compose is up again); runs alone. You own `infra/keycloak/seed-academy.sh` (new) and its helpers, the
`justfile` recipe `seed-academy` (next to `seed-users`), the new keys in `.env.example`, the section "Test academy"
in `docs/runbooks/local-stack.md`. You change no service code and no contract. Depends on: decision 74,
`infra/keycloak/seed-users.sh` (how Keycloak is driven and how secrets are passed), the e2e `JourneyTest` and its
helpers (the request sequence and how a token is obtained), `docs/runbooks/onboard-tenant.md`, ADR-0024 (temporary
passwords), ADR-0038 (password policy). Skills: owasp-security, systematic-debugging, verification-before-completion.
Worktree: `~/code/hoops-wt/wp103-seed-academy`, branch `wp103-seed-academy`.

Decision 74 of 2026-11-10 (owner): pre-populate the local application with a test academy whose accounts are ready
to use: every login active, no e-mail verification, no forced password change, one shared final password kept in
`.env`, and the list of usernames recorded in `.env` too.

## Scope
1. **What exists after a run** (all through the public and platform API, never by SQL: the outbox must publish,
   because game and athlete read the roster from their replicas since decision 66):
   - academy "Test Academy" (slug `test-academy`, time zone `Europe/Madrid`, default language `es`), ACTIVE;
   - `testadmin1`, `testadmin2` (ADMIN); `testcoach1` (COACH);
   - `testplayer1` … `testplayer10`: player records with a birth date and gender that make them eligible for the
     team's age category, each with a login (PLAYER role, linked to its own player);
   - `testparentplayer1` … `testparentplayer10` (PARENT), parent N linked as guardian to player N only;
   - a current season, one age category and one team "Test Team" with the ten players assigned (jersey numbers
     4–13) and `testcoach1` as its coach; any approval the eligibility rules require is approved by `testadmin1`.
   Logins are `<name>@hoops-academy.com`; first names "Test", last names like "Player 1", "Parent of Player 1".
2. **Passwords**: core issues temporary passwords for new members. After creating each login the script sets
   `TEST_ACADEMY_PASSWORD` with `kcadm.sh set-password` (not temporary), clears the required actions and marks the
   e-mail verified, the way `seed-users.sh` does for the dev users. Secrets travel only in the environment of the
   `podman exec`, never on a command line, never in output. The script stops with a clear message when
   `TEST_ACADEMY_PASSWORD` is missing, shorter than 12 characters or refused by the realm policy.
3. **Idempotent**: a second run creates nothing, changes no data and only resets the passwords; a half-finished
   run is completed by the next one. Look things up by slug, e-mail and name before creating.
4. **Local only**: the script refuses a base URL that is not `localhost` / `127.0.0.1` unless
   `SEED_ACADEMY_ALLOW_REMOTE=1` is set, and says so in the runbook.
5. **`.env`**: `.env.example` gets `TEST_ACADEMY_PASSWORD=change-me-test-academy` and a commented list of the
   usernames. At the end of a successful run the script adds `TEST_ACADEMY_USERS=<comma-separated logins>` to the
   repository's `.env` when the key is not there yet (it never rewrites other lines and never prints the password),
   and prints the list of logins.
6. **Docs**: `docs/runbooks/local-stack.md` "Test academy": what is created, how to run it, how to remove it
   (withdraw the academy as the super admin).

## Acceptance
- [ ] On the compose stack with the services of `main` running: `just seed-academy` succeeds; a second run reports
      "nothing to create"
- [ ] A token can be obtained for `testadmin1`, `testcoach1`, `testparentplayer3` and `testplayer3` with the shared
      password and without a required action (show the check, not the password)
- [ ] As `testparentplayer3`, `/api/core/me` and the players read show player 3 only; the team roster in game and
      in athlete shows ten players; `just events-drift` exits 0
- [ ] `gitleaks protect --staged` clean; `.env` is not staged; `shellcheck` clean if installed
- [ ] Handover appended: the usernames, how long a run takes, anything the docs pass should add to the guides

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.
- You work in a worktree with a copy of `.env`. Ask the orchestrator for nothing secret: generate your own
  `TEST_ACADEMY_PASSWORD` for the worktree copy (`openssl rand -base64 18`); the orchestrator sets the owner's value
  in the main checkout and runs the script there after the merge.
- The compose database is shared and keeps the owner's data: never reset volumes; if a run leaves a broken academy
  behind, withdraw it through the API and say so.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
