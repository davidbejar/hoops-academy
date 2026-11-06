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
- Built:
  - Realm (`infra/keycloak/realm-academy.json`): `browserSecurityHeaders` with a CSP that defines every directive
    (`default-src 'self'`, `form-action 'self' http://localhost:5173` — the chart rewrites the dev origin to its public
    URL —, `base-uri`, `frame-ancestors 'self'`, `object-src 'none'`, `img-src 'self' data:` for the OTP QR code) plus
    explicit X-Frame-Options, Referrer-Policy, HSTS, nosniff; explicit OTP policy (TOTP, SHA-1, 6 digits, 30 s,
    single use); password policy `... and passwordBlacklist(hoops-password-blocklist.txt)`.
  - Blocklist `infra/keycloak/password-blocklist/hoops-password-blocklist.txt` (10,000 most common passwords of 12–128
    chars, lower-cased, 140 KB) built by `scripts/password-blocklist.sh` from SecLists (MIT) xato-net top-1M (Burnett,
    public domain) at a pinned commit + SHA-256. Deviation from "top 100k": that list has only 488 entries of ≥ 12
    chars, below ASVS 6.2.4's 3000 policy-matching ones (ADR-0038). Mounted by compose, chart ConfigMap
    `keycloak-password-blocklist` (sync-chart-files.sh pair, checksum annotation), Testcontainers
    (`RealmKeycloakResource.container`). Bloom filter false-positive rate set to 1e-12
    (`KC_SPI_PASSWORD_POLICY__PASSWORD_BLACKLIST__FALSE_POSITIVE_PROBABILITY`; default 1e-4 would refuse 1 in 10,000
    temporary passwords).
  - Theme: `invalidPasswordBlacklistedMessage` in es/en/id. CSP: no theme change possible without template overrides
    (Keycloak 26 renders per-request inline scripts and has no nonce), so `script-src`/`style-src 'unsafe-inline'`
    remain on Keycloak pages.
  - OTP: Keycloak's built-in browser flow already has conditional 2FA and `CONFIGURE_TOTP` enabled / not default;
    the realm keeps both by listing no `authenticationFlows` / `requiredActions` (tested). Nobody forced.
  - `.zap/baseline.conf`: removed the `/auth/realms/` acceptances "Failure to Define Directive with No Fallback" and
    "Wildcard Directive"; one scoped to `login-status-iframe.html` only (Keycloak drops `frame-ancestors` there by
    design); `script-src unsafe-inline` on `/auth/realms/` kept with a new justification. `scripts/zap-gate.py` and
    `ci.yml` unchanged.
  - `infra/keycloak/seed-users.sh` patches headers, password policy and OTP policy into an existing compose realm.
  - Tests: `RealmBrowserSecurityTest`, `RealmPasswordPolicyTest` (blocklist ≥ 3000, lengths, lower-case, chart copy),
    `LoginThemeMessagesTest`, `TemporaryPasswordGeneratorTest.neverDrawsAPasswordOfTheRealmBlocklist` (100k draws; the
    generator needed no change), `RealmLoginHardeningKeycloakTest` (Keycloak: 25 generated temporary passwords pass,
    listed password refused in any case, theme message es/en/id at first sign-in, OTP enrolled via CONFIGURE_TOTP then
    asked at next sign-in, CSP header on the login page), `KeycloakBrowser` test helper.
- Verified:
  - Red first: the realm/theme tests failed (8) before the realm, theme and list changes, green after.
  - `./mvnw -B -ntp -pl services/core-service -am verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, core 801 tests,
    coverage checks met. `-Pkeycloak-it` for `RealmLoginHardeningKeycloakTest` 7/7, `KeycloakTemporaryPasswordKeycloakTest`
    3/3, `TemporaryPasswordExpiryKeycloakTest` 5/5. Isolation hook passed on every commit.
  - `just e2e` on compose: JourneyTest 23/23 (27/27 with MailSinkTest; the brief's 21 grew in other WPs).
  - ZAP baseline locally as in `ci.yml` (compose with `HOOPS_EXPOSE_KC_ADMIN=false` like `.env.example`, core on the
    host): before Medium=6 with 3 Keycloak CSP alerts accepted; after Medium=5, all accepted, `zap-gate.py` exit 0. The
    old report fails the new config (the old default CSP would block).
  - Headless Chrome over login, account console, "Signing in" (offers the authenticator set-up), CONFIGURE_TOTP page
    (QR rendered), logout confirmation: 0 CSP violations; login on client `web` redirects to a server on
    `http://localhost:5173` with a code (form-action holds).
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (85 ok) after the sync and snapshot update. The checksum
    annotation is `checksum/blocklist` because gitleaks flags a `password` key with a hash value.
  - Keycloak log: `Loading denylist finished: passwords=10000 ... falsePositiveProbability=1.0E-12`.
- Decisions/ADRs: ADR-0038 (indexed). ASVS 6.2.4 → Met, 6.3.3 → Partial (optional only, by decision); review F-24
  fixed (residual `script-src 'unsafe-inline'` accepted).
- Open points / follow-ups:
  - **Web account-console link not added**: WP53 owns `apps/web/lib` this wave. Add a profile-menu entry to
    `<issuer>/account` (es/en/id) in a later web WP; until then people go to `/auth/realms/academy/account`.
  - Existing realms: compose needs `just up` (new mount) + `just seed-users`; a kind realm keeps the old settings until
    its Keycloak database is recreated (chart imports with IGNORE_EXISTING).
  - Master realm (admin console, local only with `HOOPS_EXPOSE_KC_ADMIN=true`) keeps Keycloak's default CSP; a local ZAP
    run with the console exposed blocks on it (it did before WP57 too).
  - nginx adds its own `Referrer-Policy: strict-origin-when-cross-origin` after Keycloak's `no-referrer` on `/auth/`
    (two headers; browsers use the last). Not my file; worth aligning in a later infra WP.
  - Helm snapshots grew by the list (3 × ~10k lines).
  - I installed `libs/common-quarkus` (test-jar) into `~/.m2` once during the run; builds with `-am` are unaffected.
  - Commits carry `Co-Authored-By: Claude Opus 5.5` (the model that did the work, per the session's attribution
    rule) instead of the brief's Fable line.
