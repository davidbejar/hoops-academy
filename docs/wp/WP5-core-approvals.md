# WP5 — core-service: approvals workflow

Model: Sonnet. Depends on: WP4. Lane CORE. Plan §2 "Approvals". Skills: test-driven-development, quarkus-hexagonal-service,
tenant-isolation-testing.

## Scope
- Flyway: `approval_request` (action ADD_PLAYER|WITHDRAW_PLAYER, payload jsonb, requested_by, status, decided_by,
  decided_at, decision_note, created_at, version); partial unique index: one PENDING per (action, player).
- `ApprovalPolicy.requiresApproval(roles, action)`: ADMIN → no (auto-approved audit row); COACH → yes; others → forbidden.
- `CreatePlayer` (admin direct / coach → PENDING + player PENDING_APPROVAL visible only to admins and requester),
  `WithdrawPlayer` (admin direct / coach → PENDING), `ApproveRequest` (applies optional initial team assignment via
  `AssignPlayerToTeam`; eligibility failure → 422 and request stays PENDING), `RejectRequest`, `CancelRequest` (requester),
  list/get with filters; visibility rules in queries (PENDING_APPROVAL players hidden from parents/players and from
  staff of other teams).

## Acceptance
- [x] admin path creates player ACTIVE + auto-approved audit row; coach path creates PENDING + hidden player (`PlayerResourceTest.anAdminAddsAPlayerDirectly…`, `…anAdminMayAssignTheInitialTeam…`, `…aCoachRequestsAPlayerWhoStaysPending…`, `…pendingPlayersAreVisibleToAdminsAndTheirRequesterOnly`)
- [x] approve with ineligible team → 422, stays PENDING; approve ok → ACTIVE + assignment; reject → player WITHDRAWN (contract has no REJECTED; documented) (`ApprovalRequestResourceTest.anIneligibleAssignmentFailsWith422…`, `approvingAnAddActivates…`, `rejectingAnAddLeavesThePlayerWithdrawn…`)
- [x] double decide → 409; requester cannot approve own (unless ADMIN); assistant cannot request → 403 (`aDecidedRequestCannotBeDecidedAgain`, `twoConcurrentDecisionsHaveExactlyOneWinner`, `aCoachCannotApproveTheirOwnRequest`, `PlayerResourceTest.roleMatrixOfAddAndWithdraw`)
- [x] RLS + role-matrix + cross-tenant tests; verify green (`CoreRlsSchemaMetaTest`/`CoreRlsIsolationTest` incl. `core.approval_request`, `onlyAnAdminApprovesAndRejects`, `unknownAndForeignRequestsAreNotFound`, `anotherTenantsPlayersAreNotFound`; verify 398 tests green)

## Handover

### Built
All in `services/core-service` (no other module touched).
- **Flyway `V6__approvals.sql`**: `core.approval_request` (id, tenant_id, action ADD_PLAYER|WITHDRAW_PLAYER, `player_id` NOT NULL
  (FK to player), payload jsonb, requested_by_person_id, status PENDING|APPROVED|REJECTED|CANCELLED, decided_by_person_id,
  decided_at, decision_note, created_at, `version`), check "PENDING <=> undecided", partial unique
  `(tenant_id, action, player_id) where status = 'PENDING'`, `app.enable_tenant_rls`. `CoreRlsIsolationTest` fixtures extended.
- **Domain `domain.approvals`** (pure): `ApprovalAction`, `ApprovalStatus`, `ApprovalRequestId`, `ApprovalPayload`,
  `ApprovalPolicy.requiresApproval(roles, action)` (ADMIN wins -> false; COACH -> true; others -> `AccessDeniedException` 403),
  `ApprovalRequest` (`pending`, `autoApproved`, `approve`, `reject`, `cancel`; 409 `NOT_PENDING`; cancel by requester only).
- **Application**: `application.approvals` = `CreatePlayer`, `WithdrawPlayer`, `ApproveRequest`, `RejectRequest`,
  `CancelRequest`, `ApprovalQueries`, `PlayerLifecycle` (register / admit / place / withdraw, shared by the direct and approval
  paths), `ApprovalViews`, `ApprovalOutbox` (`player.requested|approved|rejected|withdrawn`), `ApprovalUsageCounter`;
  `application.players` = `PlayerQueries`, `PlayerViews` (open assignments + natural category of the current season),
  `PlayerAccess` (visibility rules). Ports: `ApprovalRepository`; `PlayerRepository` gained `find/page/Visibility/PlayerRow`
  and `countsByStatus`; `EligibilityCaseRepository.openOfPlayer`; `PlayerSummary` now carries given/family name.
- **Adapters**: `PlayerResource` (`GET/POST /api/core/players`, `GET /players/{id}`, `POST /players/{id}/withdraw`; `eligible-teams`
  stays in `EligibleTeamsResource`), `ApprovalRequestResource` (list/get/approve/reject/cancel), DTOs for Player, ApprovalRequest,
  PlayerCommandResult, CreatePlayerRequest; JPA `ApprovalRequestEntity` (`@Version`) + `JpaApprovalRepository`.

### How verified (fresh, 2026-11-02)
`source scripts/env.sh && ./mvnw -pl services/core-service clean verify` -> exit 0, **BUILD SUCCESS, Tests run: 398, Failures 0,
Errors 0, Skipped 0** (WP4: 329), "All coverage checks have been met": lines **98.7 %** (3145/3185), branches 92.3 %, domain 99.2 %,
`domain.approvals` 97.7 %, `application.approvals` 100 %, `application.players` 100 %. Keycloak-tagged tests stay excluded.
New tests: `ApprovalPolicyTest` (9), `ApprovalRequestTest` (6) - seen red first (compile errors) - `PlayerResourceTest` (20),
`ApprovalRequestResourceTest` (20), RLS suites now 17 tables. Red check: removing `enable_tenant_rls('core.approval_request')`
fails `CoreRlsSchemaMetaTest` and `CoreRlsIsolationTest` (restored). The REST suites were written together with the code, so the
mutation check above and the 422-rollback test (`anIneligibleAssignmentFailsWith422AndTheRequestStaysPending`) are the evidence they bite.
Every response of both resources is validated against `core.yaml` (`Contract.CORE`); only deliberately invalid requests use
`Approvals.lenientRequest()` (`RESPONSES_ONLY`).

### Decisions
- **ADD_PLAYER creates the person (PLAYER role) and player rows immediately** with status PENDING_APPROVAL; `player_id` is never null.
- **Reject / cancel of ADD_PLAYER -> player WITHDRAWN** (contract: `PlayerStatus` has no REJECTED, and the contract text says so);
  rows are kept for the audit trail (the person stays active, holding its e-mail). Rejected WITHDRAW leaves the player as is.
- **Admin-created player without a team is ORPHAN, not ACTIVE** (ADR-0014: ACTIVE without a valid assignment is ORPHAN;
  `PlayerStatusSync.rederive` is called so the orphan dashboard is immediate). With a team: ACTIVE. Same after an approval.
- **Approval executes in the same transaction**: the decision row is updated first (version check), then the side effects; a 422 from
  `AssignPlayerToTeam` rolls everything back, so the request stays PENDING. Concurrent decisions: `@Version` -> 409
  `CONCURRENT_DECISION` (proved by `twoConcurrentDecisionsHaveExactlyOneWinner`, two real transactions); a late second decision -> 409 `NOT_PENDING`.
- **Withdraw**: closes open assignments (`TeamPlayer.close`), resolves OPEN eligibility cases as `REMOVED_FROM_TEAM` with note
  "Player withdrawn" by the decider (the contract's resolution enum has no WITHDRAWN), then WITHDRAWN. A COACH may only request it
  for a player on a team they staff (else 403); PENDING_APPROVAL / WITHDRAWN players -> 409 `PLAYER_NOT_WITHDRAWABLE`.
- **Visibility**: ADMIN all; staff all but PENDING_APPROVAL players they did not request; PARENT linked / PLAYER self, never pending.
  Requests: ADMIN all, COACH own (others 404), assistants/parents/players 403 (role gate).
- **Reject needs a note** (400 when blank; the contract's schema leaves it optional but the brief requires it).
- Outbox: no event on cancel. A coach with an initial team must be COACH of that team (403) - eligibility is checked at approval, not request.
- Entitlement `PLAYERS` is checked at registration (billing seam).

### Open points
- `email` of CreatePlayerRequest is stored on the person (unique per tenant, 409 `EMAIL_TAKEN`) but **no Keycloak login/invitation is
  provisioned** here (the contract says "player gets a login"); a later invite flow or WP follow-up must do it (saga as in `InviteMember`).
- Pending/rejected players' persons appear in member lists and the `members` counter; deactivating the person on reject was not done
  (it would keep the e-mail reserved anyway).
- `GET /players?teamId=` lists players with an open assignment (valid or invalidated). No `requestedBy` filter on approval requests
  (the contract offers `playerId`; COACH visibility already restricts to own).
