# WP9 — athlete-service: training plans, templates, assignments, completion

Model: Sonnet. Depends on: WP8. Lane ATHLETE. Plan §2 "Training". Skills: as WP8.

## Scope
- Flyway: `training_plan` (tenant_id NULL for global templates, name, description, author_person_id, is_template,
  archived), `plan_item` (plan, position, title, description, duration_min, category), `plan_assignment` (plan,
  team_id xor player_id, due_on, assigned_by, note), `plan_completion` (assignment, player, status, note, marked_at,
  marked_by; pk assignment+player). RLS: templates readable by all tenants (policy `tenant_id is null or tenant_id =
  app.current_tenant()`, writes only own tenant) — allow-list the nullable case in the meta-test subclass with reason.
- Seed ~10 global templates (warm-up, ball handling, shooting form, conditioning, …) in a repeatable migration with
  items in es/en/id names? No — item text is coach content; seed in English with a `locale` column; UI translates
  template names via keys (document).
- Use cases: list/create/patch/archive plans (staff), copy template (copy-on-use), items CRUD, assignments (team or
  player), fan-out read model (team assignment → current roster via RosterPort), completion marking (player self,
  parent linked, staff team), progress summary per assignment.

## Acceptance
- [ ] global templates visible read-only to every tenant; tenant cannot modify templates (RLS test on nullable tenant_id)
- [ ] copy-on-use creates an independent tenant plan; assignment XOR constraint; completion permissions matrix
- [ ] RLS suites; contract validation; verify green, coverage ≥ 80 %
