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
- [ ] admin path creates player ACTIVE + auto-approved audit row; coach path creates PENDING + hidden player
- [ ] approve with ineligible team → 422, stays PENDING; approve ok → ACTIVE + assignment; reject → player REJECTED/removed per design (document)
- [ ] double decide → 409; requester cannot approve own (unless ADMIN); assistant cannot request → 403
- [ ] RLS + role-matrix + cross-tenant tests; verify green
