# ADR-0041: Sessions reference any plan directly; the plan search finds exercises; quick-add copies into a session's own plan

- Status: Accepted (WP78, athlete 2.3.0)
- Date: 2026-11-07
- Related: decisions 53 and 54 of 2026-11-06, WP9 (plans and templates), ADR-0039 (localized template texts),
  ADR-0027 (contracts without allOf, `x-mixins`), ADR-0032 (`clear` lists), ADR-0006 (RLS),
  `libs/contracts/openapi/athlete.yaml`, `services/athlete-service/src/main/resources/db/migration/V7__session_plans.sql`

## Context
The owner wants a coach to put a template on a session without first copying or assigning it (decision 53), and to
find an exercise inside a template ("cooper") and drop one or several exercises into a session or a plan without going
through the template (decision 54). The service already accepted any readable plan id on a session (WP9 only checked
that the plan exists under RLS); the web session dialog offered only the academy's own plans, so in practice a template
had to be copied first. There is no exercise catalogue yet: exercises are the items of plans and templates.

## Decision
1. **Direct reference.** `CreateTrainingSessionRequest.planId` / `UpdateTrainingSessionRequest.planId` accept any plan the
   tenant reads: one of its tenant plans (plans are not tied to a team, so a COACH may pick any of them) or a global
   template; no assignment is needed. Another tenant's plan is invisible under RLS and answers 404. Templates stay
   read-only. Assignments remain an optional, separate feature.
2. **Search.** `GET /training-plans?q=` matches the plan name **or the title of one of its items**, both in the
   negotiated language for templates (ADR-0039: translation, else English, else the own text) and as stored for tenant
   plans. Each summary lists the matching items in `matchedItems` (`id`, `planId`, `title`), absent when only the name
   matched. Descriptions are not searched.
3. **Quick-add copies.** `POST /training-plans/{planId}/items:copy` appends copies of the given items (any readable plan
   or template, in the given order, 1–50) to a tenant plan; a template target is 403. `POST
   /training-sessions/{sessionId}/items` appends them to the **session's own plan**: a tenant plan with `sessionId` set
   (`training_plan.ad_hoc_for_session`, V7). On the first quick-add the session gets that plan: empty and named after the
   session's day in the caller's language ("Sesión 2027-09-07") when it had no plan, otherwise a copy of its current plan
   (a template copied in the caller's language, `sourceTemplateId` pointing at it) — **copy on write**, so neither a
   template nor a plan shared with other sessions or assignments is ever changed. Copies get fresh ids and keep the text
   they were read in. Authz as for editing the session (ADMIN, staff of the team) or the plan (ADMIN, staff roles);
   CANCELLED sessions are 409.
4. **The own plan belongs to its session.** It is not listed, cannot be assigned (422 `PLAN_OF_A_SESSION`) or attached
   to another session (422 `PLAN_OF_ANOTHER_SESSION`), is deleted with its items when the session stops referencing it
   (PATCH to another plan or `clear`) and when the session is deleted (FK `on delete cascade`). It can be edited like
   any tenant plan and copied ("save as plan") into an ordinary plan. The web dialog warns before a change drops it.
5. **No trigram index.** `pg_trgm` is not installed and the migrator has no CREATE on the database, so it cannot
   install it; the item side of the search is a correlated `EXISTS` over `plan_item_plan_idx`, adequate for an academy's
   plan library plus ten templates. A trigram index needs the extension in `infra/db/init` and the chart (follow-up).
6. **No new table.** The own plan is a `training_plan` row; its RLS (custom owner policies, `TemplateRlsIsolationTest`)
   is unchanged. The composite FK `(owner_tenant_id, ad_hoc_for_session) → training_session (tenant_id, id)` keeps it on
   a session of the same tenant (added `NOT VALID`: validation would scan the table under forced RLS without a tenant;
   the column is new and null everywhere). A unique partial index allows one own plan per session.
7. **The exercise catalogue entity is deferred** to the next round; when it exists, the search and quick-add take
   catalogue entries as a further source.

## Consequences
- athlete 2.3.0 (minor: new fields and operations). `TrainingPlanSummary` and `TrainingPlan` now share the mixin
  `TrainingPlanFields` (ADR-0027) instead of `TrainingPlan` extending the summary, because only the summary carries
  `matchedItems`.
- A `q` that used to match names only now also returns plans with a matching exercise (e.g. "Warm-up" finds the
  conditioning template with "Easy warm-up jog").
- The seeded templates have no Cooper item; "cooper" finds the demo mock's conditioning template and, on a real
  stack, whatever plan the academy gives such an item (the catalogue will bring it).
- Session plan names are server-made in the caller's language; renaming them is an ordinary plan edit.
