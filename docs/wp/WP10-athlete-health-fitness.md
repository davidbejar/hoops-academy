# WP10 — athlete-service: injuries, body measurements, physical tests + norms

Model: Sonnet. Depends on: WP8. Lane ATHLETE. Plan §2 "Health & fitness". Skills: as WP8; docs/domain/norms.md must cite sources.

## Scope
- Flyway: `injury`, `body_measurement` (unique player+measured_on), `physical_test_type` (code pk, name, unit,
  higher_is_better, global flag, tenant_id null), `physical_test_result`, `physical_test_norm` (tenant_id null = global;
  test_type, gender, age_min, age_max, band, min_value, max_value).
- Seeds: test types COOPER_12MIN (m), SPRINT_20M (s), VERTICAL_JUMP (cm), AGILITY_T_TEST (s), SIT_AND_REACH (cm),
  BEEP_TEST (level); norms for ages 8–18 by gender from published sources (cite in docs/domain/norms.md; values
  without a source are flagged `reference_pending=true` and shown as such by the UI).
- Use cases: injuries CRUD (staff; parent for linked; player read self) with availability flag exposed via
  `GET /players/{id}/availability`; measurements CRUD (staff, parent linked; player read) + history; test types list
  (+ tenant custom types); results CRUD (staff) returning `expectedBand` computed from norms (tenant override > global;
  age at measurement, gender from RosterPort); norms admin CRUD (tenant overrides).

## Acceptance
- [ ] band resolution tests: override precedence, age edges, higher/lower-is-better, missing norm → null band + flag
- [ ] invariants: expected_return ≥ occurred_on; unique measurement per day; permissions matrix
- [ ] norms seed cites a source per (test, gender) block; RLS suites; contract validation; verify green
