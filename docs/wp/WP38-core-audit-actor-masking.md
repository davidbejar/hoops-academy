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

## Handover
- Built:
  - Contract core **2.6.0**: `AuditActor.subject` nullable ("null when the actor is masked for the caller (platform actors
    seen from an academy)"), still required; `listAuditEvents` and the info say the super admin is masked. No new field
    (no test needed one: `kind` = PLATFORM already tells the client). Dart core client regenerated (`scripts/gen-api.sh
    core`); web `AuditEntry.actorSubject` is now `String?`.
  - Core: the rule lives in the read use case. `AuditEntry` now carries an `AuditEntry.Actor` (kind, subject, person,
    name); `ReadAuditTrail` applies `Actor.maskedForAcademy()` (PLATFORM → no subject/person/name; PERSON and SYSTEM as
    stored); `ReadPlatformAuditTrail` does not. Metadata untouched (the `reason` stays). `AuditDtos.ActorDto.subject` is
    `@JsonInclude(ALWAYS)` because core serialises with `non_null` and the contract keeps `subject` required.
  - Web: label `auditActorPlatform` is now "Platform administrator" / "Administrador de la plataforma" / "Administrator
    platform" (existing key, value changed; no new key). The mock API masks the super admin on the academy list.
  - Dead code: `ApprovalPayload.empty()` deleted (no caller anywhere); `docs/quality/mutation.md` updated.
  - Docs: ADR-0029 "Amendment 2026-11-06"; authz matrix row "Academy activity"; `docs/domain/audit-events.md` (Actor
    rule); threat model row R; admin guides en/es/id §10 (label and "identity not shown, reason shown").
- Verified (fresh, 2026-11-06):
  - Red first: `test(contracts)` 87faf74 (3 failures), `test(core)` a60bfd8 (`AuditEventResourceTest` 2 failures: subject
    still returned; `AuditEntryTest` red by compilation), `test(web)` 1677916 (5 failures: old label, mock subject) —
    each before its `feat`.
  - `./mvnw -B -ntp -q -pl libs/contracts verify`: 147 tests, BUILD SUCCESS.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0`: BUILD SUCCESS — contracts 147, common-quarkus 186,
    game 255, athlete 613, core 773 = **1,974 tests**, 0 failures/errors/skips; all coverage checks met. New/changed:
    `AuditEventResourceTest` (+`theSuperAdminIsMaskedWhileTheSuspensionReasonIsKept`; the PLATFORM row of the listing
    test now asserts null subject/person/name), `PlatformAuditEventResourceTest` (subject and `reason` still shown to the
    super admin), `AuditEntryTest` 2, `AuditTrailContractTest` (+1, version 2.6.0, nullable subject).
  - `cd apps/web && flutter analyze`: no issues. `just web-test`: **612 passed** (+3 widget tests, one per locale, for
    the masked actor; +1 repository test for a null subject; mock API test asserts the masked subject).
  - Golden re-recorded: `audit_activity_1024x768` only (diff reviewed: just the platform row's actor line);
    `audit_activity_360x780` unchanged.
  - `just isolation-check`: 6 passed.
- Decisions/ADRs: ADR-0029 amended (no new number): masking in `ReadAuditTrail`, subject required + nullable written as
  explicit null.
- Open points:
  - The stored row still holds the super admin's subject (accountability); only the academy read masks it.
  - Commits use the brief's `Co-Authored-By: Claude Fable 5.1` line, although the work was done by Claude Opus 5.5.
