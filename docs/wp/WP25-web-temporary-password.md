# WP25 — Web: show the temporary password once; re-issue while pending

Model: Sonnet. Depends on: WP24 (contract core 2.3.0 + endpoints), WP23, WP14. Skills: flutter-feature,
test-driven-development, verification-before-completion.

After WP24 a new login has a server-generated temporary password returned once in the response; there is no setup or
verification e-mail any more. The web app must show that password to the person who created the login and let them
issue a new one while the invitation is pending.

## Scope
- `just gen-api` (core 2.3.0; never hand-edit generated code).
- One shared widget (e.g. `core/widgets/temporary_password_dialog.dart`): shows the password once in a monospace,
  selectable field with a copy button; text: share it privately, it is shown only now, the person chooses their own
  password at the first sign-in with their e-mail. Closing needs an explicit "Done". Never log it, never keep it in a
  provider after the dialog closes.
- Use it after every call that returns a `temporaryPassword`:
  - platform console: create academy (first admin), add administrator, re-issue for a pending administrator
    (replaces "Resend invitation" in `tenant_admins_section.dart`);
  - academy admin: invite member with a login, re-issue for a pending member (members screen);
  - approvals: approving a player request that creates a login;
  - players: an admin creating a player with an e-mail (`createPlayer`, `PlayerCommandResult.temporaryPassword`).
  WP24's handover lists the exact operations and models (`TenantWithPassword`, `TenantAdminWithPassword`,
  `MemberWithPassword`, `ApprovalRequestWithPassword`, `issueTenantAdminTemporaryPassword`,
  `issueMemberTemporaryPassword`; `resendTenantAdminInvitation` is deprecated: stop using it). Map 409
  `INVITATION_NOT_PENDING` and `LOGIN_SHARED` (member re-issue) to clear localised messages.
  When the response has no `temporaryPassword` (existing login), say they sign in with their existing password.
- Texts that promise an invitation / verification e-mail: replace them (`adminAddHint`, `memberInvited`,
  `adminInvited`, `adminInvitationResent`, `adminResend`, the edit-e-mail note, …) in `app_es.arb` (template),
  `app_en.arb`, `app_id.arb`; `flutter gen-l10n`.
- Docs: `docs/guides/{super-admin,admin}.{en,es,id}.md` screens and wording, if WP24 left anything for the UI.

## Acceptance
- [x] Widget tests for each flow above (password shown once, copy, absent value -> existing-login text, re-issue for
      pending only, errors via `AppError`)
- [x] Goldens of the dialog at 360x780 and 1024x768
- [x] l10n parity green; `flutter analyze` clean; `just web-test` green
- [x] Live check (`start.sh`, orchestrator): super admin adds an admin, signs in as that admin with the temporary
      password, Keycloak (theme `hoops`) asks for a new password, the app opens signed in
- [x] Handover appended

## Handover
- Built:
  - `just gen-api core` -> core client 2.3.0 (`pubspec.lock` follows). The generator now emits the base schemas that
    `allOf` extends (`Tenant`, `TenantAdmin`, `Member`, `ApprovalRequest`) as non-instantiable interfaces with a concrete
    `$Tenant`/`$TenantAdmin`/`$Member`/`$ApprovalRequest`; app code is unaffected (it never builds them), test fixtures
    build the `$` types.
  - Shared `lib/core/ui/temporary_password_dialog.dart` (placed in `core/ui` with the other shared dialogs, not
    `core/widgets`): `showTemporaryPasswordDialog` (selectable monospace value, **Copy password** with inline "copied"
    confirmation, three hints: private channel / shown only now / own password at first sign-in, no e-mail is sent;
    `barrierDismissible: false` + `PopScope(canPop: false)`, only **Done** closes it) and `announceLogin` (password ->
    dialog, then the success snack; no password -> snack "<done>. They already had an account: they sign in with their
    current password"). The password lives only in the dialog widget's constructor: no provider, no log, notifiers return
    the `...WithPassword` result to the caller and reload a password-free list.
  - `FormDialog`: `afterClose` (runs after the form has popped, so the password dialog never stacks under a spinner) and
    `PopScope(canPop: !_busy)` (a running request cannot be dismissed by the barrier, which would lose the result).
  - Flows: platform create academy (`CreateTenantDialog`), add administrator (`AdminFormDialog`), **key button** on pending
    administrator rows (`admin-issue-<id>`, replaces `admin-resend-<id>`; `issueTenantAdminTemporaryPassword`),
    academy members: invite dialog and member detail (pending chip + "Generate a new temporary password" button,
    `issueMemberTemporaryPassword`, errors `INVITATION_NOT_PENDING` / `LOGIN_SHARED` / 502 localised via `memberErrorText`),
    approvals (`ApprovalRequestWithPassword`, dialog only when a password is present, plain "approved" snack otherwise),
    new player form (`PlayerCommandResult.temporaryPassword`, only for a direct creation with an e-mail; a coach request
    creates no login yet). `resendTenantAdminInvitation` is no longer used.
  - l10n (es template, en, id; `flutter gen-l10n`): +16 keys (`tempPassword*`, `memberAdded`, `memberInviteHint`,
    `memberErrorNotPending`, `memberErrorLoginShared`, `playerEmailHint`); reworded `adminAddHint`, `adminEditEmailNote`;
    removed `memberInvited`, `adminInvited`, `adminInvitationResent`, `adminResend`. Invitation chip labels ("Invitation
    pending/accepted") stay: they describe the state, not an e-mail.
  - Mock mode: member invite returns a demo temporary password and `POST /members/{id}/temporary-password` exists, so the
    dialog also appears without a backend.
  - Guides `docs/guides/{super-admin,admin}.{en,es,id}.md`: dialog, button labels, "existing login" note; the WP24 "screens
    arrive in WP25" note removed.
- Verified (fresh, 2026-11-02):
  - Red first: commit `e154f2b` (tests + fakes) did not compile/load against the old code (`temporary_password_dialog.dart`
    missing, `resendAdminInvitation` abstract member).
  - `cd apps/web && flutter analyze`: No issues found. `flutter test` (= `just web-test`): **538 tests, all passed**
    (507 before this WP; +31: dialog 11, platform +9, members +8, players +4, approvals +2, goldens +2, minus replaced
    resend tests). `l10n_keys_test` (parity + placeholders) green; `mock_core_api_test` covers invite password and re-issue.
  - Goldens (looked at the PNGs; the test font draws blocks): `apps/web/test/golden/goldens/temporary_password_360x780.png`,
    `temporary_password_1024x768.png`; `platform_admin_add_360x780.png` regenerated for the new hint text.
- Decisions:
  - Results are announced after the form dialog has closed (`FormDialog.afterClose`) using the root navigator's context
    captured before the request, so a rebuilt or removed list row/card cannot lose the password.
  - The password dialog cannot be dismissed any other way than **Done** (also not by Escape/back); the clipboard copy is
    the user's explicit action. Only an academy admin sees the member re-issue (server enforces ADMIN; the UI shows it for
    active PENDING members only).
  - `announceLogin` without a password says "existing login" only where a login was requested (create/add/invite/player
    with e-mail); approvals without a password just show "approved" because an approval does not always create a login.
- Open points / follow-ups:
  - Live check (`start.sh`, orchestrator): super admin adds an admin, signs in with the temporary password, Keycloak theme
    `hoops` asks for a new password, app opens signed in. **Not done by this session.** Done by the orchestrator
    (2026-11-02, services with the WP24 jars, `flutter run -d web-server`): super admin (PKCE login) `POST
    /platform/tenants/{id}/admins` -> 201 `PENDING`, `Cache-Control: no-store`, 16-character `temporaryPassword` (kept
    in a 600 file, never printed); `browser_login_check.py` without `--set-new-password` stops at Keycloak's
    update-password page as intended; with `--set-new-password` (new option, this check) the branded `hoops`
    update-password page takes the new password and the app opens signed in on the admin home (Profile,
    Administration, Members, ...). Afterwards the own password signs in (`keycloak_login_check.sh` OK) and the
    temporary one is refused. The console's password dialog itself was checked by widget tests and goldens only, not
    clicked through in the browser.
  - `docs/conformance.md` / `authz-matrix.md` were not touched (no behaviour beyond WP24's).
  - The approval dialog names the person but cannot show the sign-in e-mail (the approval payload has none).
  - Members list shows "Invitation pending" for any PENDING member; the re-issue button is on the member detail page only.
