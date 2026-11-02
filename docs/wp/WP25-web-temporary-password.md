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
- [ ] Widget tests for each flow above (password shown once, copy, absent value -> existing-login text, re-issue for
      pending only, errors via `AppError`)
- [ ] Goldens of the dialog at 360x780 and 1024x768
- [ ] l10n parity green; `flutter analyze` clean; `just web-test` green
- [ ] Live check (`start.sh`, orchestrator): super admin adds an admin, signs in as that admin with the temporary
      password, Keycloak (theme `hoops`) asks for a new password, the app opens signed in
- [ ] Handover appended
