# ADR-0020: Approval workflow and player lifecycle (ADD / WITHDRAW, REJECTED, ORPHAN on creation)

- Status: Accepted (records decisions taken in WP5, WP2c and WP17); amended by ADR-0024 — §5: a temporary password replaces the setup e-mail
- Date: 2026-11-02
- Related: ADR-0015 (status derivation), ADR-0016 §1 (`PlayerStatus.REJECTED`), ADR-0013 (login saga)

## Context
SPEC: "the admin and the coach can add or withdraw players, but if done by the coach it needs to be approved by an
admin." PLAN §2 fixed the request states but left open what exists while a request is pending, what a rejection
leaves behind, and how a player's login is created.

## Decision
1. **Who may request.** `ApprovalPolicy.requiresApproval(roles, action)`: ADMIN (alone or with other roles) executes
   immediately and an auto-approved request row is kept as an audit record; COACH without ADMIN creates a PENDING
   request; ASSISTANT_COACH, PARENT, PLAYER → 403. A coach may only withdraw players on a team they staff and may only
   name an initial team they coach.
2. **ADD_PLAYER creates the person and player rows at request time** with status `PENDING_APPROVAL` (so the request has
   a `player_id`; one PENDING request per action and player). Pending players are visible to ADMIN and the requesting
   coach only; they do not appear in the members list (WP17, F-16).
3. **Decisions.** Only PENDING can be decided (409 `NOT_PENDING`); concurrent decisions → one winner via `@Version`
   (409 `CONCURRENT_DECISION`). Reject requires a non-blank note. Approval runs the eligibility-checked assignment in
   the same transaction; a 422 `PLAYER_INELIGIBLE` rolls everything back and the request stays PENDING.
4. **Outcomes.** Approved ADD → ACTIVE if assigned to a team, otherwise **ORPHAN** (an active player without a valid
   assignment, ADR-0015). Rejected ADD → `REJECTED` (since contracts 2.0; earlier rows stay WITHDRAWN, no backfill),
   hidden from non-admins and not withdrawable. Cancelled ADD (by the requester) → WITHDRAWN. Approved WITHDRAW closes
   open assignments, resolves their open eligibility cases as `REMOVED_FROM_TEAM` and sets WITHDRAWN; until then the
   player stays ACTIVE.
5. **Player login.** A player created with an e-mail gets a Keycloak login through the same saga as member invitations
   (Keycloak first, setup e-mail last, compensation on failure); a failing invitation leaves the approval PENDING (502).
6. Every transition writes an outbox event (`player.requested|approved|rejected|withdrawn`) and an audit event
   (ADR-0017). The `PLAYERS` entitlement is checked at registration (billing seam).

## Consequences
- An admin-created player without a team lands on the orphan dashboard immediately, which is intended ("assign him").
- Rejected persons keep their e-mail reserved in the tenant (unique per tenant).
- Parents linked through guardian links get no login from this flow (follow-up). The web app still labels a REJECTED
  player as "withdrawn" (`lib/core/ui/labels.dart`, follow-up).
- Evidence: `ApprovalPolicyTest`, `ApprovalRequestTest`, `ApprovalRequestResourceTest`, `PlayerResourceTest`, e2e step
  `adminAddsPlayerAndCoachRequestsOneWhichTheAdminApproves`.

## Alternatives considered
- Store the request payload only and create the player on approval — rejected: the request could not reference a
  player, the "one pending per player" rule and the coach's view of their requested player would need a second model.
