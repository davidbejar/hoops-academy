---
name: work-package
description: How an agent starts, executes and hands over a Hoops Academy work package (WP) from docs/wp. Use at the beginning and end of any WP, or when asked to "run WPn".
---

# Executing a work package

## Start
1. Read `CLAUDE.md`, the WP brief `docs/wp/WP<n>-*.md`, and the ADRs it references. Read `docs/PLAN.md` sections
   it points to. Do not read the whole plan.
2. `source scripts/env.sh && just doctor` (or at least `./mvnw -q validate`).
3. Write the acceptance criteria from the brief as a checklist at the top of your working notes; add any you
   discover.
4. Skills to apply: `test-driven-development` (always), `clean-code` (always), `quarkus-hexagonal-service` or
   `flutter-feature` (by area), `tenant-isolation-testing` (any table/endpoint), `owasp-security` (auth, uploads,
   config, deps), `systematic-debugging` (any failure).

## During
- Small vertical slices: contract → failing test → minimal code → refactor → commit (Conventional Commits).
- Keep the brief's scope; if something outside scope is required, note it in the handover instead of doing it.
- Never weaken a quality gate, disable a test, or connect to the DB as superuser to get green.

## Finish (verification-before-completion)
1. Run the full command(s): `just test` (and `just web-test` for Flutter) — fresh, complete; read the output.
2. Walk the acceptance checklist line by line; each item needs evidence (test name, command output).
3. Append to the WP file:
   ```
   ## Handover
   - Built: …
   - Verified: <commands + results summary>
   - Decisions/ADRs: …
   - Open points / follow-ups: …
   ```
4. Report: what was built, how verified (with numbers), what was left out and why.
