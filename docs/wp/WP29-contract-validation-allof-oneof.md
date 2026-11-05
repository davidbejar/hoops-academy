# WP29 — Contracts: make every real response validatable (allOf + additionalProperties, MatchEvent oneOf)

Model: Opus. Depends on: WP2c, WP18b. Skills: test-driven-development, verification-before-completion,
quarkus-hexagonal-service (contract-first rules). Worktree: `~/code/hoops-wt/wp29-contract-validation`, branch
`wp29-contract-validation`.

Two validator gaps let real responses escape the contract check (`libs/contracts/README.md` documents the quirks):
- Schemas composed as `allOf: [X, {id}]` where a member has `additionalProperties: false` (e.g. `AgeCategory =
  allOf[AgeCategoryInput, {id}]`) cannot validate any real response; the service tests and the e2e journey *mute*
  those validation errors.
- `MatchEvent` oneOf/discriminator is not resolvable by the atlassian validator for feed responses; e2e reads the
  feed unvalidated.

Goal: no muted validation anywhere; every response in tests and e2e is validated against the contract.

## Scope
- Find every mute: search the services' test code, `libs/common-quarkus` test support and `e2e/` for the ignore /
  whitelist of validation messages (names like `additionalProperties`, `allOf`, `oneOf`, `discriminator`,
  `ValidationErrorsWhitelist`, `ignore`). List them in the handover.
- Fix the schemas, not the validator: drop `additionalProperties: false` from composed members (or restructure the
  composition so the response schema is a plain object), keep request strictness where it matters; give `MatchEvent`
  a shape the validator resolves (e.g. explicit `discriminator.mapping`, or a flattened object with a `type` enum and
  nullable variant fields, whichever keeps the generated Dart client usable). Version bumps follow the contract
  README's rules (patch if the wire format is unchanged).
- Remove the mutes; run the suites; fix whatever real mismatch the validator then finds (a response field missing
  from the contract is a contract bug: add it, with a test).
- `just gen-api` if a schema changed shape; the Dart packages are generated, never hand-edited. `apps/web` must still
  compile and `just web-test` stay green; do not change app code beyond what the regenerated models force (note any
  forced change in the handover, WP35 may touch the same screens).
- e2e: enable feed validation; run the journey on the compose stack if you can (`docs/runbooks/e2e.md`; only one
  compose stack can run on this machine, check `podman ps` first and skip with a note if it is in use).

## Acceptance
- [ ] No validation whitelist / ignore left in services, common-quarkus test support or e2e (grep evidence)
- [ ] `./mvnw -B -ntp -T 1C verify` green (fresh; module totals in the handover)
- [ ] `just web-test` green if packages were regenerated
- [ ] `libs/contracts/README.md` quirk section updated (what is gone, what remains)
- [ ] Handover appended

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees and share the Podman machine; retry a container start once
  before calling it a failure.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md (WP26 owns them); notes go in this file's Handover.
- Finish per the `work-package` skill: fresh full verification, checklist with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and numbers), left out and why,
  anything another WP must know (especially contract versions and regenerated packages).
