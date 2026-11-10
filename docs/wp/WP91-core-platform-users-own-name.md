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
- **Built** (12 commits, red test first for each change):
  - **Contract core 3.4.0** (`libs/contracts/openapi/core.yaml`, `PlatformUsersContractTest`): `listPlatformUsers`
    and the extended `updateMe`.
  - **`GET /platform/users`** (super_admin; every tenant role 403, anonymous 401): `q` 2–100 characters (400
    otherwise), literal case-insensitive substring of the login's e-mail or of a person's "given family" name in any
    academy; `page` / `size` (1–200) as `/platform/audit-events`; ordered by e-mail (case-insensitive, none last); each
    login's memberships ordered by academy name, any academy status, active or deactivated. Read-only.
    Read through core_platform (`PlatformUserRepository`): one count and one page statement (logins left-joined to
    persons, academies, roles), never a query per login. **Migration V18** (`V18__platform_user_read.sql`): column
    grants `app_user (id, email, created_at)`, `person (id, tenant_id, user_id, given_name, family_name, active)` with
    policy `person_platform_read` (`user_id is not null`), roles of those persons, an index on `person.user_id`. The
    transaction binds the nil tenant (the standard policy raises otherwise). Nothing for core_app, no BYPASSRLS.
  - **Own name** (`PATCH /api/core/me`): `givenName` / `familyName` (1–80, non-blank, as `updateMember`) need
    `tenantId` (and `tenantId` needs a name), else 400; `locale` became optional; any other member, `email` included,
    is a 400 (`additionalProperties: false`). The caller's own active person in that ACTIVE academy is renamed, else
    404 (nothing stored, the name runs before the locale). Side effects as the admin's edit: `member.updated` with the
    changed field names (actor = the person), the `core.person` event; unchanged name writes nothing. No Keycloak
    call: the admin path updates Keycloak only on an e-mail change.
  - **Events off**: property **`hoops.outbox.enabled`**, env **`CORE_OUTBOX_ENABLED`** (default `true`). With `false`
    `OutboxPublisherJob` never runs the publisher and `KafkaEventBroker` never creates a `KafkaProducer` (a send fails
    at once, not counted as a broker failure). The outbox keeps filling. WP100: `core.events.offEnv:
    {CORE_OUTBOX_ENABLED: "false"}` (the old `CORE_OUTBOX_POLL_INTERVAL: "off"` can stay or go).
  - **ContainerStarts**: core's `KeycloakContainerResource` (Keycloak and MailHog) and `SaslRedpandaResource`.
  - Docs: two rows at the end of `docs/domain/authz-matrix.md`; the `member.updated` row of `audit-events.md` (no new
    action); ADR-0029 amendment "the platform reads logins and their names" (no new ADR number).
- **Shapes for WP99's mock**:
  - `GET /platform/users?q=&page=&size=` → `{"items": [{"id": uuid, "email": "a@x.org" (optional, nullable),
    "createdAt": date-time, "memberships": [{"tenantId", "tenantName", "tenantSlug", "tenantStatus":
    "ACTIVE|SUSPENDED|WITHDRAWN", "personId", "givenName", "familyName", "roles": ["ADMIN", …] (enum order),
    "active": bool}]}], "page": {"page", "size", "totalElements", "totalPages"}}`.
  - `PATCH /api/core/me` body `{"givenName"?, "familyName"?, "tenantId"?, "locale"?}` (at least one) → `Me` as before.
  - Field names follow the contract's `givenName` / `familyName` (as `Member`, `UpdateMemberRequest`), not the
    brief's "firstName / lastName"; `tenantId` goes in the body because the conventions forbid `X-Tenant-Id` on `/me`.
- **Verified** (fresh, `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`, BUILD SUCCESS, coverage and SpotBugs
  gates met): common-quarkus 392, contracts 284, core-service 1029, game-service 468, athlete-service 914, e2e 32
  (26 skipped); 0 failures. `just mutation core-service`: 779/780 killed (99.9 %, baseline 99), 100 s.
  `-Pkeycloak-it` `CrossTenantAccessTest` (the isolation check) 6/6 and `KeycloakLoginUpdateKeycloakTest` (MailHog)
  2/2 in this worktree.
- **Decisions**: the super-admin flag is **not** returned (core stores no copy of the realm role; asking Keycloak per
  page would put it on a read path; the web knows the caller from `/me`). The read is **not audited**: ADR-0029 and
  ADR-0017 record administrative changes only, no read; the query text is never logged (`PlatformUserResourceTest`).
  `MeChangesTest` (the record's invariant) was written after its code, as a unit test of an already covered path.
- **Open points**: the first full build failed on `TenantRegistryRlsTest` (it asserted core_platform reads nothing of
  `app_user`); updated in its own commit to "no whole rows", the second on SpotBugs (fixed). The Claude Code commit hook in the main
  checkout (WP93's new `tenancy-gate.sh`) printed `line 38: w: bad array subscript` and treated a non-commit command
  (a heredoc into an ADR) as a commit, then failed its isolation check on Podman 502/504 under load: worth a look.
  `docs/adr/README.md`'s 0029 row does not mention the amendment (left to the docs pass).
