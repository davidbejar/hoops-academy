# ADR-0039: Shared seed content is localized on the server from `Accept-Language`, stored as jsonb next to its own text

- Status: Accepted (recorded in the round-4 docs pass from the WP61 handover; implemented in WP61, athlete 2.2.0)
- Date: 2026-11-06
- Related: decision 43 of 2026-11-06, WP61, ADR-0006 (RLS), ADR-0016 §6 (global templates via `owner_tenant_id`),
  `libs/contracts/openapi/athlete.yaml` (info description, parameter `AcceptLanguage`),
  `services/athlete-service/src/main/resources/db/migration/V4__template_texts.sql`

## Context
The ten global training-plan templates are seed content that every academy sees. Until WP61 their names, descriptions
and 59 item texts were English only, while the UI is Spanish, English and Indonesian. Two choices had to be made:
which language a response uses (a person has a stored locale in core, and the web client also knows its UI
language), and where the other languages live without weakening tenant isolation.

## Decision
1. **The request's `Accept-Language` header decides.** The first of `es`, `en`, `id` in the header's preference order
   wins (`q=0` refused, `in` is an alias of `id`); absent, `*`, unsupported or malformed = `en`, never a 400. The
   service does not read the person's stored locale: the web client sends its UI language, which already follows
   that locale, and a header keeps the read free of a call to core.
2. **Only shared content is translated.** Tenant plans are returned as stored, whatever the header says; a copy of a
   template keeps the texts it was copied with (localize, then copy). `nameKey` is a stable, language-free key of a
   global template (null for tenant plans) so a client can recognise a template across languages.
3. **Translations are jsonb columns on the existing tables**, not a translation table: `training_plan.name_key` +
   `i18n` and `plan_item.i18n` (`{"es": {...}, "id": {...}}`), the template's own language staying in the ordinary
   columns. Checks keep them on template rows only (`owner_tenant_id is null`), require an object, and forbid the own
   language inside `i18n`, so "requested, else `en`, else own" is a plain SQL `coalesce`. The app role never writes
   them (read-only mapping); the repeatable seed fills them.

## Consequences
- RLS policies, grants and the generic RLS suites are untouched: no new table, no new tenant boundary to prove.
- Search (`q`) and ordering use the shown (localized) name.
- A cached client response is per language: the web app must refetch when the UI language changes (open in
  `FOLLOW-UPS.md`, WP61).
- Adding a language is a seed change plus the negotiation list; other shared seed content (test types, norms
  descriptions) can follow the same pattern when it needs translating.

## Alternatives considered
- **Stored locale of the person wins**: needs the locale on the request path (a call to core or the authz context),
  and a person switching the UI language would see templates in another language than the screen.
- **A translation table `(entity, language, field, text)`**: a new global table next to tenant tables, more joins,
  its own grants and a place in the RLS meta test, for ten templates.
- **Client-side translation from ARB keys**: ties seed content to app releases and leaves other clients English.
