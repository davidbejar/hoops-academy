# WP57 — Keycloak: CSP headers, password blocklist, optional OTP

Model: Opus. Wave 2 (2026-11-06, fourth round): starts after WP56 is merged (same realm file); runs alongside
WP53, WP55, WP59, WP61, WP65. You own `infra/keycloak/realm-academy.json`, `infra/keycloak/themes/hoops`, the chart
realm copies (`scripts/sync-chart-files.sh`), `.zap/baseline.conf`, `scripts/zap-gate.py` and the ZAP job of
`.github/workflows/ci.yml` (WP55 owns the flutter job of the same file: touch only the ZAP step). Depends on: WP56,
ADR-0024 (temporary passwords), the ZAP acceptances. Skills: owasp-security, verification-before-completion,
systematic-debugging. Worktree: `~/code/hoops-wt/wp57-keycloak-hardening`, branch `wp57-keycloak-hardening`.

Decision 39 of 2026-11-06: realm `browserSecurityHeaders` carry a CSP that lets the accepted ZAP alerts under
`/auth/realms/` be removed; a password blocklist policy applies to every user; OTP is offered (optional) to every
login, enrolled from the account console; no breached-password extension. ADR-0038 reserved for you.

## Scope
1. **CSP**: `contentSecurityPolicy`, `xFrameOptions`, `referrerPolicy`, `strictTransportSecurity` in the realm's
   `browserSecurityHeaders`, compatible with the `hoops` login theme (inline scripts/styles? fix the theme instead of
   `unsafe-inline` where feasible; say what remains). Then remove the matching `IGNORE` lines from `.zap/baseline.conf`
   and prove the ZAP baseline job is green on the compose stack (run it locally as `ci.yml` does, with the ZAP
   container).
2. **Password blocklist**: realm password policy `passwordBlacklist(<file>)` with a blocklist file shipped in the
   Keycloak image/volume (compose and chart; `sync-chart-files.sh` if the chart copies it), sized reasonably (top
   100k list, pinned source and checksum, licence noted); the temporary-password generator (ADR-0024) never produces
   a blocked value (test); a user choosing a blocked password at first sign-in sees the Keycloak message in es/en/id
   (theme message keys).
3. **Optional OTP**: browser flow with conditional OTP (`CONFIGURE_TOTP` not forced); the account console link in the
   web profile menu if absent; `browser_login_check.py` unaffected. Super admin not forced (decision).
4. **Docs**: ADR-0038; `docs/security/asvs-checklist.md` rows 6.2.4, 6.3.3 (you own those rows), review file
   rows for the ZAP alerts; realm re-import note.

## Acceptance
- [ ] ZAP baseline green locally with the tightened `.zap/baseline.conf` (evidence: alert counts)
- [ ] Red tests first where code changes (temporary-password generator vs blocklist); `./mvnw -B -ntp -pl
      services/core-service -am verify -Dquarkus.http.test-port=0` green; `just e2e` 21/21 on compose
- [ ] `deploy/helm/tests/run.sh` green after the chart sync; `actionlint` clean if the workflow changed
- [ ] ADR-0038 written and indexed (append at the end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time; the compose stack ports (8080, 5432) are yours this wave.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
