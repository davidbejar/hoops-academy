# WP23 — Platform console: academy administrators

Model: Sonnet. Depends on: WP14, WP22 (contract + endpoints). Skills: flutter-feature, test-driven-development,
verification-before-completion.

The super admin manages the administrators of an academy from the academy detail page of the platform console.

## Scope
- `just gen-api` (regenerate `apps/web/packages/core` from the WP22 contract; never hand-edit generated code).
- `apps/web/lib/features/platform`: `PlatformRepository` / `ApiPlatformRepository` methods for list/add/edit/remove/
  resend admins; providers next to `TenantDetailNotifier`.
- `TenantDetailScreen` (`presentation/tenant_detail_screen.dart`): an **Administrators** section:
  - list rows: name, e-mail, invitation status (pending/accepted), other roles;
  - *Add administrator* (`FormDialog`, fields e-mail, first name, last name; same validators as `CreateTenantDialog`),
    say in the dialog that an existing member with that e-mail is promoted, otherwise an invitation e-mail is sent;
  - *Edit* (names, e-mail; note that changing the e-mail changes the login and asks the person to verify it);
  - *Remove* with confirmation ("removes the Administrator role; other roles stay");
  - *Resend invitation* for pending admins;
  - **Last admin**: when only one admin is listed the remove action is disabled and the row explains: an academy needs
    at least one administrator, add another one first. A 409 `LAST_ADMIN` from the server shows the same message.
  - Errors through `AppError` / `runAction` like the existing lifecycle buttons; disabled actions for WITHDRAWN tenants.
- Strings in `app_es.arb` (template), `app_en.arb`, `app_id.arb`; `flutter gen-l10n`.
- `apps/web/lib/core/http/mock_api_adapter.dart` is out of scope (it has no `/platform` at all; FOLLOW-UPS).
- Docs: `docs/guides/super-admin.{en,es,id}.md`: an "Administrators" section with the last-admin explanation.

## Acceptance
- [ ] Widget tests (`test/features/platform/platform_test.dart`, `FakePlatformRepository` extended): list, add, edit,
      remove, resend, last-admin disabled + explanation, 409 `LAST_ADMIN` message, error and loading states, withdrawn
- [ ] Goldens of the detail page with administrators at 360x780 and 1024x768
- [ ] l10n parity test green; `flutter analyze` clean; `just web-test` green
- [ ] Handover appended

## Handover
