# WP8 — athlete-service: schedules, sessions, attendance, absences

Model: Sonnet. Depends on: WP2a, WP2b. Lane ATHLETE. Contract: `libs/contracts/openapi/athlete.yaml`. Plan §2 "Training".
Skills: test-driven-development, quarkus-hexagonal-service, tenant-isolation-testing.

## Scope
- Module `services/athlete-service`, package `com.hoopsacademy.athlete`, datasource `athlete_app`, Flyway as `athlete_migrator`;
  `RosterPort` adapter identical in shape to game's (consider copying the pattern; shared code may move to common later —
  note it in handover rather than modifying common-quarkus).
- Flyway V1: `training_schedule` (team_id, weekday, start_time, duration_min, location, valid_from, valid_to),
  `training_session` (team_id, schedule_id null, starts_at, ends_at, location, plan_id null, status, notes),
  `planned_absence` (player_id, from_date, to_date, reason, created_by), `attendance` (session_id, player_id, status
  PRESENT|LATE|ABSENT|EXCUSED, minutes_late, note, recorded_by; pk session+player). RLS on all.
- Use cases: schedules CRUD (staff/admin), `MaterialiseSessions` (8 weeks ahead, idempotent, tenant timezone, DST-safe;
  nightly job + on schedule change), sessions list by team/date range, ad-hoc create, patch, cancel; attendance put
  (staff), absences CRUD (parent for linked, player self, staff any); session attendance view overlays planned
  absences as EXPECTED_ABSENT; `/internal/usage/{tenantId}`.

## Acceptance
- [ ] materialisation idempotent (re-run → no duplicates), handles DST transition in Europe/Madrid and Asia/Jakarta
- [ ] role matrix for attendance/absences (parent linked only; player self only; staff any)
- [ ] RLS suites; cross-tenant 404; contract validation; verify green, coverage ≥ 80 %
