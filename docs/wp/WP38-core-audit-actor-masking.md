# WP38 — Core: audit actor masked for academy admins, dead code removed

Model: Opus. Wave 1 (2026-11-06): runs alongside WP39 (athlete) and WP40 (gateway); disjoint files except
`apps/web/lib/l10n/*.arb` (add your keys next to the existing `audit*` keys, not at the end of the file). Depends on:
WP34 (ADR-0029). Skills: quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, flutter-feature,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp38-core-audit-actor`, branch
`wp38-core-audit-actor`.

Decision 16 of 2026-11-06: academy ADMINs keep reading the super admin's free-text `reason` on `tenant.suspended` /
`tenant.withdrawn` rows (it is meant for them), but they must not see who the super admin is: for a caller scoped to an
academy, every PLATFORM-kind actor is shown as "Platform administrator". The super admin's own view
(`listPlatformAuditEvents`) is unchanged.

## Scope
1. **Contract** (`libs/contracts/openapi/core.yaml`, minor bump 2.5.0 → 2.6.0): on `AuditActor` make `subject`
   nullable with the description "null when the actor is masked for the caller (platform actors seen from an
   academy)"; `personId` and `displayName` are already nullable. Do not add a new field unless a test shows the
   client needs one. `./mvnw -pl libs/contracts verify`, `just gen-api`, commit the regenerated `apps/web/packages/core`.
2. **Core** (`listAuditEvents`, the academy-scoped read): PLATFORM-kind actors are returned with `subject: null`,
   `personId: null`, `displayName: null`. Decide where in the application layer this belongs (the read use case,
   not the resource, not the repository) and write the test first: an ADMIN of academy A lists events and the
   `tenant.suspended` row's actor carries no subject, person or name, while the `reason` in `metadata` is intact; the
   super admin's platform list still carries the subject. Extend the existing WP34 tests rather than adding a parallel
   class where that fits.
3. **Web** (`apps/web/lib/features/audit`): the Activity screen renders a PLATFORM actor with a null subject as
   "Platform administrator" (es: "Administrador de la plataforma", id: "Administrator platform"); widget test first.
4. **Dead code**: delete `ApprovalPayload.empty()` in core (WP37 found it uncovered and never called); if something
   does call it, say so in the handover and leave it.
5. **Docs**: a short "Amendment 2026-11-06" section at the end of `docs/adr/0029-audit-trail-read-api.md` (no new ADR
   number); `docs/domain/authz-matrix.md` if it states what an ADMIN sees in audit rows.

## Acceptance
- [ ] Contract 2.6.0 validated (`./mvnw -pl libs/contracts verify`); Dart package regenerated and committed
- [ ] Red test committed before each change (core use case, web widget)
- [ ] `./mvnw -B -ntp -T 1C verify` green (fresh; totals); `cd apps/web && flutter analyze` clean; `just web-test`
      green (fresh; totals)
- [ ] ADR-0029 amendment written; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: if a Testcontainers run fails with "localhost:2375 failed to respond" or a
  port clash, re-run that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
