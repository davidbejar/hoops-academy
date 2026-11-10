# WP91 — Core: platform users read, own-name edit, events-off producer switch

Model: Opus · effort high. Wave 1 (2026-11-10, sixth round): runs alongside WP92 (athlete-service, athlete contract,
`features/training`), WP93 (workflows, hooks, `scripts/doctor.sh`), WP94 (model diagrams), WP95 (web kit, audit,
landing). You own `services/core-service`, `libs/contracts/openapi/core.yaml` and its contract tests, Flyway core
`V18` (reserved, only if you need it; WP96 has `V19`), your rows in `docs/domain/authz-matrix.md` (append at the
end) and your entry in `UpdateRequestClearListContractTest` (append at the end, one entry per line). You do NOT
regenerate `apps/web/packages/core` and do not touch `apps/web` (WP99 does both in wave 2). Depends on: decisions 71
and 73, ADR-0029 (audit, platform reads), ADR-0026 (shared login), ADR-0037 / WP81 (plain `KafkaProducer`), WP87
(`ContainerStarts`). Skills: quarkus-hexagonal-service, tenant-isolation-testing, owasp-security,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp91-core-platform-users`, branch `wp91-core-platform-users`.

Decision 71 of 2026-11-10: the super admin gets an "Application admin" hub with a Users area listing every login
across academies. Decision 73: a non-admin member may edit their own first and last name; the e-mail stays with the
admin.

## Scope
1. **Contract core → 3.4.0**: `GET /platform/users` (super admin only, same authorisation and non-super-admin
   answer as the other `/platform` reads): `q` (case-insensitive match on e-mail and name, minimum 2 characters),
   paging in the convention `/platform/audit-events` already uses; each item is one login (`core.app_user`: id,
   e-mail, whether it is a super admin if core knows it, created) with its memberships (`tenantId`, academy name and
   slug, tenant status, `personId`, first and last name in that academy, roles, active flag). Read-only this round:
   no e-mail change and no temporary password from this endpoint (the existing per-academy endpoints stay the way
   to do that). Contract test first, then role-matrix tests (every tenant role and an anonymous caller are refused).
2. **Cross-tenant read done right**: use the platform read path that `/platform/audit-events` and the tenant list
   use (the platform database role), never a widened policy for `core_app` and never `BYPASSRLS`. One query per
   page, no N+1 per login. Record the read as the audit trail records other platform reads if ADR-0029 does so;
   otherwise say in the handover why not. Never log e-mails at INFO.
3. **Own name** (`PATCH /api/core/me`): `UpdateMeRequest` gains optional `firstName` and `lastName` with the
   validation the member endpoints use; any active member changes the name of their own person in the current
   academy; the same side effects as an admin's name edit of that member (audit row, outbox event
   `core.person.changed`, Keycloak profile if the admin path updates it). The e-mail is not accepted here. Role-matrix
   test for all five roles.
4. **Events-off switch** (FOLLOW-UPS "Events-off producer warnings in core"): one configuration key that keeps the
   outbox publisher from creating its `KafkaProducer` at all when events are off (no connection attempts, no WARN
   lines), settable by one environment variable; the outbox rows still accumulate. Unit test on the publisher's
   wiring. Put the exact property and env name in your handover: WP100 sets it in the chart.
5. **`ContainerStarts`** (WP87 leftover): core's `KeycloakContainerResource` and the MailHog test container start
   through `ContainerStarts.start(...)` like the other resources.
6. **Docs**: authz matrix rows for the two operations; `docs/domain/audit-events.md` if a new action exists.

## Acceptance
- [ ] Contract 3.4.0 validated by the contract tests; `OpenApiConventionsTest` green
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals per module)
- [ ] `just mutation core-service` at or above the baseline (record the score)
- [ ] Handover appended: the response shape WP99 needs for its mock, the events-off property and env name for
      WP100, whether a migration was used

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

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
