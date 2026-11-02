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
- [x] Widget tests (`test/features/platform/platform_test.dart`, `FakePlatformRepository` extended): list, add, edit,
      remove, resend, last-admin disabled + explanation, 409 `LAST_ADMIN` message, error and loading states, withdrawn
- [x] Goldens of the detail page with administrators at 360x780 and 1024x768
- [x] l10n parity test green; `flutter analyze` clean; `just web-test` green
- [x] Handover appended

## Handover

- Built:
  - `just gen-api`: `apps/web/packages/core` regenerated for contract 2.2.0 (new `TenantAdmin`, `TenantAdminPage`,
    `AddTenantAdminRequest`, `UpdateTenantAdminRequest`, five `PlatformApi` operations; `pubspec.lock` follows). `game`
    and `athlete` packages came out unchanged.
  - Data/application: `PlatformRepository` + `ApiPlatformRepository` (`admins`, `addAdmin`, `updateAdmin`,
    `removeAdmin`, `resendAdminInvitation`; the list asks for 100); `TenantAdminsNotifier` family
    (`tenantAdminsProvider`: add/edit (merge patch, only changed fields)/remove/resend, each reloads the list from the
    server); `isTenantWithdrawn(error)` by the `TENANT_WITHDRAWN` code.
  - UI (`tenant_admins_section.dart`, placed between the lifecycle header and the usage dashboard): rows with name,
    e-mail, status chip (pending/accepted; `NONE` shows no chip), "Also: <roles>" with the localised role labels, icon
    actions edit / resend (pending only) / remove, `AdminFormDialog` (add: explains promotion vs invitation e-mail and
    sends the academy's default language; edit: prefilled, e-mail-is-the-login note, sends only changed fields, closes
    without a call when nothing changed; e-mail validator shared with `CreateTenantDialog` via `platform_validators.dart`).
    Remove asks for confirmation ("other roles stay"). Last admin: with one administrator listed the remove button is
    disabled and the row shows the explanation. Withdrawn academy: only a note and no GET; a GET answering 409
    `TENANT_WITHDRAWN` (stale status) shows the same note, not an error screen. Load error and spinner are inline in the
    section (the tenant and usage stay visible), with retry. SUSPENDED academies are managed like ACTIVE ones.
  - Errors by code, never by English `detail`: `adminErrorText` maps `LAST_ADMIN`, `EMAIL_TAKEN`,
    `LOGIN_ALREADY_MEMBER`, `IDENTITY_PROVIDER_UNAVAILABLE`, `INVITATION_NOT_PENDING`, `TENANT_WITHDRAWN`; everything else
    falls back to the generic per-kind `AppError` message. `runAction` gained an optional `errorText` callback for this.
  - 25 new l10n keys (`admin*`) in es/en/id (reuses `memberEmail`, `memberGivenName`, `memberFamilyName`,
    `memberInvitationPending`, role labels); `lib/l10n/gen` regenerated.
  - Docs: `docs/guides/super-admin.{en,es,id}.md` "Administrators" section rewritten for the console screens, with the
    last-admin explanation (disabled button, row text, same message on a server 409, add the new admin first).
- Verified (fresh, this session):
  - Red first: `platform_test.dart` administrators group committed against the fake and the repository methods only
    (21 of the 22 new cases failing; the remaining one asserts absence only). Mutation check: `onPressed: isLast ? null :
    remove` -> `remove` made the "only administrator cannot be removed" test fail.
  - `flutter test test/features/platform/platform_test.dart`: 38 tests green (16 existing + 22 new: list, loading,
    list error + retry, add + validation, add 409 `EMAIL_TAKEN`, add 502, edit names only, edit e-mail + validation, edit
    unchanged, remove + cancel, resend, resend 409, last admin disabled + note, two admins enabled, remove down to one,
    server 409 `LAST_ADMIN` message without the English detail, last-admin text in en and id, withdrawn, stale 409
    `TENANT_WITHDRAWN`, suspended managed, long names/e-mail/roles at 360 px without overflow).
  - `flutter analyze`: No issues found. `flutter test test/l10n`: 3 tests green (placeholder and key parity).
  - `just web-test` (`flutter test`): 507 tests, All tests passed (the memory baseline was 477; this WP adds 22 widget tests and 4 golden tests;
    the remaining difference comes from tests added by other work packages since that note).
  - Goldens (Ahem blocks like the existing ones; viewed the PNGs: no overflow or clipping, add button right-aligned at
    1024, last-admin note wraps inside the card at 360, dialog fits 360x780):
    `apps/web/test/golden/goldens/platform_admins_360x780.png`, `platform_admins_1024x768.png`,
    `platform_admins_last_360x780.png`, `platform_admin_add_360x780.png` (test `test/golden/platform_admins_golden_test.dart`).
- Decisions/ADRs: none new (ADR-0023 covers the backend rule). Success text after Add is "Invitation sent" when the
  returned administrator is `PENDING`, else "Administrator added" (derived from the body, so the repository does not
  expose the 200/201 status).
- Open points / follow-ups:
  - Not checked in the running app or against the real backend in a browser (the user's `start.sh` session was left
    alone); the e2e journey for WP22 covers the API, no Flutter e2e for this screen. `mock_api_adapter.dart` still has no
    `/platform` (out of scope, FOLLOW-UPS).
  - The list is one page of up to 100 administrators; more than that would hide the rest and could show the "last admin"
    state wrongly (not realistic for academies; no paging UI).
  - Goldens render with the Ahem test font, so text width in the PNGs is indicative only.
