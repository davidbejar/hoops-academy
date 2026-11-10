# Audit events (core.audit_event)

The audit trail of administrative actions (ADR-0017), read by an academy's ADMIN (`GET /api/core/audit-events`) and by
the super admin across academies (`GET /platform/audit-events`, ADR-0029). One source for the action names: core's
`AuditAction` enum, which every `AuditEvent.of(...)` takes. `AuditActionCompletenessTest` keeps the enum, the contract
enums `AuditAction` / `AuditTargetType` (core.yaml) and the table below equal: a new action cannot be recorded without
appearing in all three.

**Rules**
- **No personal data in metadata.** It holds ids, role and enum names, and the *names* of changed fields, never
  values, names, e-mails, phone numbers or notes. Names are resolved when the trail is read, from the rows that still
  exist (a renamed person shows the new name; a row that no longer exists shows its id only). One exception, older than
  WP34: `tenant.suspended` / `tenant.withdrawn` carry the super admin's free-text `reason` (also in the outbox and on
  the tenant registry).
- **Only real changes** (WP58). `fields` lists the fields whose stored value changed. An edit whose effective change
  set is empty (every given value equals the stored one; a `clear` of a field that is already empty) writes no row
  (`member.updated`, `admin.updated`, `tenant.profile_changed`, `tenant.master_data_changed`) and returns the resource
  unchanged (200); team, age category, season and jersey PATCHes write no audit row at all and skip the write too.
- **Actor.** `actor_sub` is the token subject of the caller, or `system` for background jobs; `actor_person_id` is the
  caller's person in that academy, or null when the caller has none there (the super admin, who acts from the platform).
  The API derives `actor.kind`: PERSON (person set), SYSTEM (`system`), PLATFORM (otherwise). On the academy path a
  PLATFORM actor is masked: `subject`, `personId` and `displayName` are null (decision 16, WP38, core 2.6.0); the
  platform path shows the subject.
- **Names on the platform path** are limited to academies and persons who are active administrators of their academy
  (the identity the platform already manages, ADR-0023). Other persons and players show their id.
- **Append-only.** No role may update or delete a row (trigger, ADR-0017). **Retention: none in v1**; a purge job
  (run as `core_migrator`) is a v2 item.

| Action | Target | Metadata keys | Written by |
|---|---|---|---|
| `admin.added` | person | `invited` (true: new member invited; false: existing member promoted) | super admin, `POST /platform/tenants/{id}/admins` |
| `admin.removed` | person | `membershipDeactivated` (true when ADMIN was the only role) | super admin, `DELETE /platform/tenants/{id}/admins/{personId}` |
| `admin.temporary_password_issued` | person | – | super admin, re-issue for a pending administrator |
| `admin.updated` | person | `fields` (changed field names: `givenName`, `familyName`, `email`) | super admin, `PATCH /platform/tenants/{id}/admins/{personId}` |
| `approval.cancelled` | approval_request | `action` (`ADD_PLAYER` / `WITHDRAW_PLAYER`), `playerId` | the requester withdrew a PENDING request |
| `guardian_link.created` | guardian_link | `guardianPersonId`, `playerId` | ADMIN |
| `guardian_link.removed` | guardian_link | – | ADMIN |
| `member.deactivated` | person | `roles` (roles left, normally none) | ADMIN |
| `member.invitation_accepted` | person | – | the person, at the first sign-in (`GET /api/core/me` turns PENDING into ACCEPTED; actor = that person) |
| `member.invited` | person | `roles`, `login` (a login was created or linked) | ADMIN, onboarding, approval of ADD_PLAYER with e-mail, a new guardian (`POST /api/core/guardians`), a guardian's first login (`login: true`, WP58) |
| `member.login_email_changed` | person | – | super admin moving a shared login's e-mail (written in every academy that uses the login, ADR-0026) |
| `member.roles_replaced` | person | `before`, `after` (role names) | ADMIN |
| `member.temporary_password_expired` | person | – | `system`: the expiry sweep, in every academy where the login's person is PENDING (ADR-0028) |
| `member.temporary_password_issued` | person | – | ADMIN or super admin: every temporary password (invite, re-issue, new login) |
| `member.updated` | person | `fields` (changed field names) | ADMIN, super admin (`admin.updated` path), the member for their own `givenName` / `familyName` (`PATCH /api/core/me`, WP91; actor = target) |
| `player.approved` | player | `approvalRequestId`, `action`, `playerId`, `status`, `requestedBy`, `decidedBy` | ADMIN decision, or an ADMIN's auto-approved request (also an outbox event) |
| `player.rejected` | player | as `player.approved` | ADMIN decision (also an outbox event) |
| `player.requested` | player | `approvalRequestId`, `action`, `playerId`, `status`, `requestedBy` | COACH request (also an outbox event) |
| `player.withdrawn` | player | as `player.approved` | ADMIN withdrawal or approved WITHDRAW_PLAYER (also an outbox event) |
| `tenant.created` | tenant | `slug` | super admin, onboarding |
| `tenant.events_backfilled` | tenant | `force`, `events` (count appended), `topics` (topic names) | super admin, `POST /platform/events/backfill` (WP81) |
| `tenant.logo_removed` | tenant | – | ADMIN |
| `tenant.logo_replaced` | tenant | `contentType`, `sizeBytes` | ADMIN |
| `tenant.master_data_changed` | tenant | `fields` (`name`, `timezone`, `defaultLocale`) | super admin |
| `tenant.profile_changed` | tenant | `fields` (changed profile field names) | ADMIN |
| `tenant.reactivated` | tenant | `status` | super admin (also an outbox event) |
| `tenant.request_accepted` | tenant | `academyRequestId`, `requesterRole` (`ADMIN` / `COACH` / `PARENT`) | super admin accepting an academy request: the academy was created from it, its requester is the first ADMIN (WP90, ADR-0044; a rejection has no academy and is recorded on the request itself) |
| `tenant.settings_changed` | tenant | `eligibilityRulesChanged` | ADMIN |
| `tenant.suspended` | tenant | `status`, `reason` (free text, see Rules) | super admin (also an outbox event) |
| `tenant.withdrawn` | tenant | `status`, `reason` (free text, see Rules) | super admin (also an outbox event) |

## Reading the trail
- Newest first (`at desc`, then insertion order). `from` is inclusive, `to` exclusive (RFC 3339 instants); `action`
  takes one or several names. Page size 1–200 (default 50).
- Academy path: core_app under the academy's RLS; names are read in the same scope, so an id of another academy never
  resolves.
- Platform path: core_platform through its read policy `audit_event_platform_read` (V11), joined to the registry for
  the academy's name; administrator names per academy inside `TenantScope.runAs` (core_app, that academy's RLS).
- Indexes: `(tenant_id, at desc)` (V9) for the academy page, `(tenant_id, action, at desc)` for the action filter and
  `(at desc)` for the platform page (V12; measured with EXPLAIN ANALYZE, see the WP34 handover). Counting a large
  unfiltered trail still scans it (about 0.1–0.2 s per million rows); acceptable in v1.
