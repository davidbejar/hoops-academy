# WP31 — A login's e-mail change reaches every academy that shares the login

Model: Opus. Depends on: WP22 (ADR-0023), WP23. Skills: test-driven-development, tenant-isolation-testing,
quarkus-hexagonal-service, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp31-shared-login-email`, branch `wp31-shared-login-email`.

Decision 7 of 2026-11-05: one person, one e-mail. Today, when the super admin changes the e-mail of a login used in
several academies (`/platform/tenants/{id}/admins/{personId}`, and any other path through
`application/members/LoginEmailSync`), Keycloak and `core.app_user.email` get the new address but only the edited
academy's `core.person.email` changes; the other academies keep the old one.

## Scope
- Read `LoginEmailSync`, its callers (`ManageTenantAdmins`, member update) and the WP22 handover first.
- Behaviour: in the same transaction that updates Keycloak and `app_user`, update `core.person.email` for every
  person row that links the same login, in every academy. The academy-admin path is unchanged (it is already
  refused with 409 `LOGIN_SHARED` when the login is shared; keep that).
- Tenancy: those rows live under other tenants' RLS. Use the existing platform mechanism (`core_platform` role /
  `TenantScope` platform scope / per-tenant `runAs`, whichever `/platform/**` already uses for cross-tenant work);
  never bypass RLS and never widen the app role. One audit row (`member.login_email_changed`) per affected academy,
  with no e-mail in the metadata.
- Tests first: an integration test with a login shared by academies A and B, super admin changes it via A ⇒ B's
  person row has the new e-mail, B's audit log has a row, and an academy admin of A still gets 409. A GenericRls /
  schema test change is not expected (no new table).
- Contract: no new operation. If the response or the docs describe the per-tenant behaviour, fix the wording
  (`libs/contracts/core.yaml` description, `docs/guides/super-admin.*.md`).

## Acceptance
- [ ] Failing test committed first, then the change (Conventional Commits)
- [ ] `./mvnw -pl services/core-service -am verify` green (fresh; totals in the handover); the keycloak-tagged
      suite too if you touch the Keycloak adapter (`-Pkeycloak-it`)
- [ ] Authz matrix untouched or consciously updated (`docs/domain/authz-matrix.md`)
- [ ] Handover appended; ADR only if you had to choose between mechanisms (say which and why)

## Working rules (all WPs of this wave)
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Other agents work in parallel in sibling worktrees and share the Podman machine; retry a container start once
  before calling it a failure.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md (WP26 owns them); notes go in this file's Handover.
- Finish per the `work-package` skill: fresh full verification, checklist with evidence, `## Handover` appended.
- Final report to the orchestrator, at most 300 words: built, verified (commands and numbers), left out and why,
  anything WP32/WP34 (which also touch core members/admins code) must know.
