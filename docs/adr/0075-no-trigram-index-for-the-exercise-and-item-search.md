# ADR-0075: No trigram index for the exercise and item search: row-level security keeps it out of the plan

- Status: Accepted (amends ADR-0041 §5)
- Date: 2026-11-24
- Related: decision 116 of 2026-11-24, [WP145](../wp/WP145-trigram-index-for-the-item-search.md), ADR-0041 (plan search
  by item title), ADR-0047 (exercise catalogue), ADR-0039 (localized template texts), ADR-0006 (RLS, non-owner app
  roles), ADR-0073 (PostgreSQL 19)

## Context
ADR-0041 §5 left the plan search without a trigram index because `pg_trgm` was not installed and the migrator may not
create extensions; decision 116 asked for the index now that the round touches the database bootstrap. Before adding
anything, WP145 measured what the searches do and whether a trigram index could serve them.

**The searches.** Three predicates of the same shape, all in athlete-service's persistence adapter:

| Search | Code | Predicate |
| --- | --- | --- |
| Exercise catalogue `GET /exercises?q=` | `ExerciseJpaRepository.search` | `lower(coalesce(i18n->:language->>'title', i18n->'en'->>'title', title)) like :q escape '\'` |
| Plan name `GET /training-plans?q=` | `PlanJpaRepository.search` | the same over `training_plan.name` |
| Item title (inside plans and templates) | `PlanJpaRepository.search` | `or exists (select … from plan_item i where i.plan_id = p.id and lower(coalesce(…, i.title)) like :q)` |

`:q` is `LikePattern.contains`: `%term%`, lower-cased in the root locale, wildcards escaped. There is no `unaccent`:
the match is case-insensitive and accent-sensitive. The texts are the shown ones for the caller's language: the
translation, else English, else the own text (ADR-0039, ADR-0047). The language is a bound parameter (`jsonb_extract_path_text(i18n, ?, 'title')`).

**The measurement.** A throwaway `postgres:19.0-trixie` with `infra/db/init/01_roles_schemas.sql`, every athlete
migration applied as `athlete_migrator`, and a realistic load: 60 academies × 80 own exercises (4 800) plus the global
catalogue (60), 60 × 40 plans × 8 items (19 200 items) plus the ten templates; `ANALYZE`d. The queries are a hand
transcription of the JPQL with the parameters bound as literals (language `es`, term `cooper`); the plans were taken as
`athlete_app` with a tenant bound, as the service runs them.

**Before** (no extension), the exercise search:

```
Limit (actual time=0.310..0.312 rows=6)
  ->  Sort  Sort Key: (COALESCE(…es…, …en…, title)), id
        ->  Bitmap Heap Scan on exercise e (actual rows=6)
              Recheck Cond: ((owner_tenant_id IS NULL AND NOT archived) OR (owner_tenant_id = current_tenant() AND NOT archived))
              Filter: ((owner_tenant_id IS NULL OR owner_tenant_id = current_tenant()) AND lower(COALESCE(…)) ~~ '%cooper%')
              Rows Removed by Filter: 130
              ->  BitmapOr
                    ->  Bitmap Index Scan on exercise_owner_idx  Index Cond: (owner_tenant_id IS NULL AND archived = false)   rows=60
                    ->  Bitmap Index Scan on exercise_owner_idx  Index Cond: (owner_tenant_id = current_tenant() AND archived = false)   rows=76
Execution Time: 0.350 ms
```

The plan search: a bitmap scan of `training_plan_owner_idx` for the tenant's 40 plans, and per plan the correlated
`EXISTS` reads its 8 items through `plan_item_plan_idx` (`loops=40`); 0.824 ms. The template path: 10 templates, 0.207 ms.
Both searches are already index scans: the RLS policy (`owner_tenant_id is null or owner_tenant_id =
app.current_tenant()`) is an index condition, so a search reads one academy's rows plus the global ones, never the
platform's.

**After**, with `create extension pg_trgm schema app` and GIN trigram indexes on exactly the searched expressions
(`lower(coalesce(cast(jsonb_extract_path_text(i18n, 'es', 'title') as varchar), …, title)) app.gin_trgm_ops` on
`exercise` and `plan_item`, the name expression on `training_plan`), same data, same role: **the plans are identical**
(same nodes, same index conditions, same row counts; 0.286 ms and 2.045 ms). The trigram indexes are not used.

**Why.** PostgreSQL applies a query's own conditions after the RLS policy unless they are leakproof; only a leakproof
condition may become an index condition ahead of the policy (`restriction_is_securely_promotable`). None of the
search's functions is:

```
select proname, proleakproof from pg_proc where proname in ('lower', 'textlike', 'jsonb_extract_path_text', 'texteq');
texteq                  | t
textlike                | f      -- the ~~ (LIKE) operator
lower                   | f
jsonb_extract_path_text | f
```

Checked three ways on the same database:
- **Stress**: one academy with 50 000 own exercises (11 matches). As `athlete_app`: the bitmap scan of
  `exercise_owner_idx` reads all 50 060 rows and filters 50 049 (54.6 ms); with `enable_seqscan = off` the plan is the
  same; the trigram index is never chosen.
- **Control without RLS**: the same query as `athlete_app` with RLS disabled on the table (in a rolled-back
  transaction) and as the superuser: `Bitmap Index Scan on exercise_title_es_trgm, Index Cond: (lower(COALESCE(…)) ~~
  '%cooper%')`. The index works; RLS is what keeps it out.
- **Item side without RLS**: the planner turns the `EXISTS` into a hashed subplan over `plan_item_title_es_trgm`; so
  the `or exists` shape is no second obstacle, RLS is the only one.

A second, independent obstacle: the searched expression contains the caller's language, a bound parameter. An
expression index fixes it, so serving every caller needs one index per language per table (three languages × three
tables), and with the JDBC driver's server-side prepared statements (after five executions) the generic plan carries
`$1` where the index has `'es'`, which never matches.

## Decision
1. **No `pg_trgm`, no trigram index.** Nothing is added to `infra/db/init`, the `databases` sub-chart's bootstrap,
   `infra/compose/db-roles.sh` or the athlete migrations; an extension and nine indexes that no plan uses would only
   cost write time and upgrade surface. ADR-0041 §5's reason is replaced: the extension could be installed by the
   bootstrap (it ships in both `postgres:19.0-trixie` and CloudNativePG's `19.0-minimal-trixie`, and is a trusted
   extension), but the app role's searches cannot use it.
2. **The tenant index is the search's index.** The work per search is bounded by one academy's library plus the global
   catalogue (≈ 140 rows, under a millisecond at the measured size; 55 ms for a 50 000-exercise academy).
3. **Rejected ways to make the index usable**, each weakening the isolation design (ADR-0006): marking `lower`,
   `textlike` and `jsonb_extract_path_text` `LEAKPROOF` (a superuser change to built-ins for every role and schema
   that overrides PostgreSQL's own classification); a `SECURITY DEFINER` search function, an owner or
   `BYPASSRLS` connection for the search (all three skip the policies and are what `just db-role-check` forbids).
4. **Revisit** only when an academy's own exercises or plan items reach tens of thousands, or the search is rewritten
   without RLS on the read path (for example a search projection keyed by tenant); measure first, as here.

## Consequences
- No migration, no bootstrap or chart change, nothing to run on an existing database.
- The comment on `PlanJpaRepository.search` now gives this reason instead of "the migrator may not create extensions".
- The ADR-0041 follow-up "a trigram index needs the extension in `infra/db/init` and the chart" is closed by this
  record, not by an index.
- The measurement scripts are not kept; the setup above is enough to repeat it on a throwaway container.
