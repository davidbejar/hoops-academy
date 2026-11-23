# WP139 — Infra, chart, services, scripts: one name for the realm URL everywhere; one login helper for the scripts; database roles from one list

Model: Opus · high. Wave 5 (2026-11-23, ninth round): starts after wave 4 is merged and runs alone: you may touch any
area. You own `infra/**`, `.env.example`, `start.sh`, `stop.sh`, `config/**`, and for the rename the
`application.properties` of the services, `deploy/**`, the `Tiltfile`, `scripts/**`, `.github/**`, `e2e/**`,
`apps/web/tool/**`, the finance and pdf services' configuration and the docs that name the variables. Depends on:
WP136, WP137. Skills: work-package, podman-dev-env, owasp-security, systematic-debugging, test-driven-development,
clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp139-realm-url-one-name-login-helper-db-roles`, branch
`wp139-realm-url-one-name-login-helper-db-roles`.

Decision 110 of 2026-11-23: one variable for the realm URL and one for the admin base URL in every service, compose,
the chart, kind, Tilt, the scripts and `.env.example`, with working defaults; the stale `localhost:8180` goes.
ADR-0071 is reserved for you (write it: the two names, their meaning, the defaults). Do not read or edit the owner's
`.env`: list in the handover exactly which keys the orchestrator must rename or add there.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `infra.md`
(INF-01..12), verification `verify-deploy-infra-ci.md`; X-05 in `cross-cutting.md`, verification
`verify-cross-cutting-libs.md`; DEP-07 in `deploy.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Realm variables (X-05, INF-01, DEP-07)**: first a test or script check that fails while any old name or `8180` is
   left in the tree; then the rename everywhere in one commit per area. `quarkus:dev` of each service starts against
   `just up` with no variable set.
2. **Login helper (INF-02)**: the browser-less PKCE login copied into at least five scripts becomes one sourced shell
   library (and one Python helper if `zap-login.py` needs it); the Java test class stays.
3. **Database roles (INF-03)**: role names listed by hand in about eight places: one list drives the SQL, the password
   scripts and the checks; `just db-role-check` stays green; no password value in git.
4. **Compose**: `mailhog` pinned (not `latest`); INF-04 (dev users once for compose and kind), INF-05 (nginx header
   blocks), INF-06 (hardening and OTel blocks through anchors or `extends`).
5. **The rest**: every other INF finding of your scope.

Not yours: DEP-04 (the chart's copies of `infra/` files stay; run `scripts/sync-chart-files.sh` after changing a
source and bump the chart version if a rendered value changes).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just test-go` and `just test-rust` green if their configuration changed
- [ ] `just down && just up`, then `just isolation-check`, `just db-role-check` green on a fresh stack
- [ ] `deploy/helm/tests/run.sh` green (snapshots updated only for the renamed variables: show the diff summary);
      `deploy/kind/up.sh --deploy` and `smoke.sh` green
- [ ] the e2e journey on compose: run it, or say exactly why it could not run so the orchestrator does
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
