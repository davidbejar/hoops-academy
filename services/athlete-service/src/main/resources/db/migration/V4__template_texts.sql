-- athlete-service V4: global templates in es / en / id (WP61, decision 43).
--
-- A template keeps its own texts in name / description (plan_item: title / description), in the language of
-- training_plan.locale ('en' for the seed), and its other languages in i18n:
--   training_plan.i18n  {"es": {"name": ..., "description": ...}, "id": {...}}
--   plan_item.i18n      {"es": {"title": ..., "description": ...}, "id": {...}}
-- plus a stable name_key. Columns on the existing tables keep RLS and grants as they are (no new table); the app
-- role never writes them (templates are immutable for it), and the checks keep them off tenant rows.
-- R__plan_templates.sql fills them.

alter table athlete.training_plan
  add column name_key text,
  add column i18n jsonb,
  add constraint training_plan_texts_template_only check ((name_key is null and i18n is null) or owner_tenant_id is null),
  add constraint training_plan_i18n_object check (i18n is null or jsonb_typeof(i18n) = 'object'),
  -- the own language lives in name/description only, so "translation, else en, else own" is a plain coalesce
  add constraint training_plan_i18n_not_own_language check (i18n is null or (i18n -> locale) is null);
create unique index training_plan_name_key_uq on athlete.training_plan (name_key) where name_key is not null;

alter table athlete.plan_item
  add column i18n jsonb,
  add constraint plan_item_texts_template_only check (i18n is null or owner_tenant_id is null),
  add constraint plan_item_i18n_object check (i18n is null or jsonb_typeof(i18n) = 'object');
