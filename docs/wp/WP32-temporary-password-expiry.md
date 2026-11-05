# WP32 — Temporary passwords expire after 3 days (event-triggered sweep, no scheduler)

Model: Opus. Wave 2: starts after WP31 is merged (same core members/admins code). Depends on: WP24 (ADR-0024),
WP25, WP31. Skills: test-driven-development, tenant-isolation-testing, quarkus-hexagonal-service, owasp-security,
flutter-feature (console labels), verification-before-completion. Worktree: `~/code/hoops-wt/wp32-temp-password-expiry`,
branch `wp32-temp-password-expiry`.

Decision 4 of 2026-11-05 (ADR-0025 records the sign-up philosophy; this WP adds ADR-0026). The product owner does not
want a cron job. A temporary password older than 3 days is expired; the clean-up runs in the background when an
infrequent event happens.

## Facts to build on (read them first)
- `application/members/TemporaryPasswords.issue` writes the audit row `member.temporary_password_issued` and calls
  `IdentityProviderPort.setTemporaryPassword`; `IssueTemporaryPassword` guards re-issue with
  `identityProvider.hasOwnPassword(subject)` (a login that chose its own password is never reset).
- `adapters/out/keycloak/KeycloakIdentityProvider`: `setTemporaryPassword` (credential `temporary=true`),
  `hasOwnPassword`, users are created `enabled=true`. Core never sees the login itself: Keycloak's login page handles
  the temporary password and the forced change; the app only calls core afterwards (`/api/core/me`, `GetMe`), which
  is where an invitation flips PENDING → ACCEPTED (the "first login" event).
- `core.app_user` (V2, platform-wide, no RLS, no tenant data) has no timestamp for the temporary password.
- Jobs run one-at-a-time across replicas with `TenantScope.runExclusive("<svc>.<job>", work)` (advisory lock; see
  `adapters/in/scheduler/OnboardingRepairJob` for the pattern and its tests).
- The realm uses the custom login theme `hoops` (`infra/keycloak/...`, `apps/web`? find the theme directory).

## Scope
1. **Migration** `V<next>__temporary_password_expiry.sql`: `core.app_user.temporary_password_issued_at timestamptz`,
   `temporary_password_expired_at timestamptz`; grants as V4. No RLS change (table is global by design, V2 comment).
2. **Issue** (every path: invite, approve, create player with e-mail, tenant admin add, re-issue): set `issued_at =
   now()`, clear `expired_at`, and re-enable the Keycloak user if it was disabled by the sweep
   (`IdentityProviderPort.enable(subject)`), all inside `TemporaryPasswords.issue` so no caller can forget.
3. **Sweep** `application/identity/ExpireTemporaryPasswords`: for every `app_user` with `issued_at < now() - 3 days`,
   `expired_at is null`: if `hasOwnPassword` is false ⇒ Keycloak `disable(subject)`, set `expired_at`, audit row
   `member.temporary_password_expired` in every academy where the login has a PENDING person (no e-mail in
   metadata); if the login has its own password ⇒ just clear `issued_at` (nothing to expire). Keycloak failure ⇒ log,
   skip, next sweep retries. Window configurable: `hoops.temporary-password.ttl=P3D`.
4. **Triggers**: (a) `GetMe` when it accepts an invitation (first login of that person); (b) `TemporaryPasswords.issue`.
   Both hand the sweep to a background executor (`ManagedExecutor` / `Vertx.executeBlocking`, after the request's
   transaction commits) under `runExclusive("core.temporary_password_sweep", …)`; a request never waits for it and a
   sweep failure never fails the request. Test both triggers and the lock (pattern of the existing job tests).
5. **Contract** (core, minor bump): `MemberView` / `TenantAdminView` (and the pending-admin views) gain
   `temporaryPasswordStatus: ACTIVE | EXPIRED | NONE`, so the console can label an expired pending person; the
   re-issue operations are unchanged. `just gen-api`.
6. **Keycloak message**: the `hoops` login theme shows, for a disabled user, "Your temporary password has expired.
   Ask your academy administrator for a new one." in es / en / id (override the `accountDisabledMessage` key in the
   theme's `messages/messages_<lang>.properties`; keep the generic text for genuinely disabled accounts only if the
   theme can tell them apart — it cannot, so document that a disabled login always shows this text). Realm changes
   need a re-import: `just down && podman volume rm hoops_pgdata && just up && just seed-users`.
7. **Web console** (small): pending member / admin rows show "Temporary password expired" when the status is
   EXPIRED, next to the existing re-issue button; es/en/id; widget test.
8. **Docs**: ADR-0026 (expiry without a scheduler: trigger, lock, accepted gap until the next sweep, why disable
   rather than delete the credential); guides for admins and super admin (what the person sees, what to click);
   `docs/domain/authz-matrix.md` unchanged; `docs/security/review-2026-11.md` item "temporary passwords never expire"
   → resolved by WP32.

## Acceptance
- [ ] Failing tests first for: issue sets the timestamp and re-enables; sweep expires only temporary logins older
      than the TTL, disables them in Keycloak (keycloak-tagged test with the real container), writes the audit row,
      leaves own-password logins alone; triggers run the sweep in the background; second replica skips (lock)
- [ ] End to end (keycloak-tagged): a login issued 4 days ago (set `issued_at` in the test) cannot obtain a token
      after the sweep; after re-issue it can, and Keycloak asks for a new password
- [ ] `./mvnw -B -ntp -T 1C verify` green and `./mvnw -pl services/core-service -am verify -Pkeycloak-it` green
      (fresh; totals in the handover); `just web-test` green; `just isolation-check` and `just db-role-check` green
- [ ] Handover appended, ADR-0026 written

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
