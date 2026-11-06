-- athlete-service V7: a session's own (ad-hoc) plan for quick-added exercises (WP78, decisions 53-54, ADR-0041).
--
-- No new table: a training_plan row of a tenant may belong to one training session. RLS and grants of training_plan
-- stay as they are (custom owner policy, TemplateRlsIsolationTest); the composite foreign key ties the plan to a
-- session of the same tenant, the session's deletion takes its plan along, and a session has at most one such plan.
-- The service deletes the plan when the session stops referencing it and lists only plans without a session.
--
-- Item-title search: no trigram index. pg_trgm is not installed and the migrator (no CREATE on the database) cannot
-- install it; the search is a correlated EXISTS per plan over plan_item_plan_idx, which suits the size of an academy's
-- plan library (ADR-0041 records the follow-up).

alter table athlete.training_plan
  add column ad_hoc_for_session uuid,
  add constraint training_plan_ad_hoc_tenant_only check (ad_hoc_for_session is null or owner_tenant_id is not null),
  -- NOT VALID: validating would scan training_plan under its forced RLS without a tenant; the new column is null in
  -- every existing row, and new or changed rows are checked as usual.
  add constraint training_plan_ad_hoc_session_fk foreign key (owner_tenant_id, ad_hoc_for_session)
    references athlete.training_session (tenant_id, id) on delete cascade not valid;
create unique index training_plan_ad_hoc_session_uq on athlete.training_plan (ad_hoc_for_session)
  where ad_hoc_for_session is not null;
