# ADR-0038: Keycloak pages get a full CSP, the password policy a blocklist, every login an optional OTP

- Status: Accepted
- Date: 2026-11-06
- Related: decision 39 of 2026-11-06, WP57, ADR-0022 (branded login, CSS-only theme), ADR-0024 (temporary passwords),
  ADR-0028 (temporary password expiry), ADR-0034 (realm patching by `seed-users`), `.zap/baseline.conf`,
  `docs/security/asvs-checklist.md` 6.2.4 / 6.3.3

## Context
Keycloak's login and account pages went out with Keycloak's default realm headers: a CSP of three directives
(`frame-src 'self'; frame-ancestors 'self'; object-src 'none'`), which the ZAP baseline reports as three Medium alerts,
accepted until now for `/auth/realms/` only. The realm password policy (`length(12) and maxLength(128) and notUsername
and notEmail`) let any common password of 12 or more characters through (ASVS 6.2.4 gap), and no second factor was
offered (6.3.3 gap). Decision 39 of 2026-11-06: a CSP in the realm's `browserSecurityHeaders` that lets the accepted
ZAP alerts go; a blocklist for every user; OTP offered to every login, set up from the account console, forced on
nobody (not on the super admin either); no breached-password extension.

## Decision
1. **Realm security headers** (`browserSecurityHeaders`, explicit): CSP `default-src 'self'; script-src 'self'
   'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self';
   frame-src 'self'; frame-ancestors 'self'; form-action 'self' http://localhost:5173; base-uri 'self'; object-src
   'none';`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy: no-referrer`, HSTS `max-age=31536000; includeSubDomains`,
   `nosniff`, `X-Robots-Tag: none`.
   - `form-action` lists the Flutter dev server because Chrome applies it to the redirect after the login POST; the
     chart rewrites that origin to its public URL (= `'self'`) unless `allowDevServer`, like the redirect URIs.
   - `img-src data:` is the OTP set-up QR code. Everything else is same origin (nginx / the gateway serve app and
     Keycloak on one origin, ADR-0022).
   - **What remains:** `script-src` and `style-src` keep `'unsafe-inline'`. Keycloak 26.8 renders per-request inline
     scripts (session polling with the tab id, the auth-session hash check, import maps, `onsubmit` handlers in about
     a dozen templates, the account console's bootstrap) and has no CSP nonce; hashes cannot match per-request
     content. Removing them means overriding Keycloak's templates and scripts, which ADR-0022 rejected (CSS only, so
     upgrades keep working). The ZAP acceptance `CSP: script-src unsafe-inline` stays, scoped to `/auth/realms/`; the
     `style-src` one (Flutter) now names Keycloak too. The two other Keycloak CSP acceptances are removed.
2. **Password blocklist** for every user: policy `... and passwordBlacklist(hoops-password-blocklist.txt)`.
   - The file (`infra/keycloak/password-blocklist/hoops-password-blocklist.txt`, ~140 KB) holds the **10,000 most
     common passwords of 12 to 128 characters**, lower-cased, from Mark Burnett's 10-million-password sample (public
     domain) as published in SecLists (MIT): `xato-net-10-million-passwords-1000000.txt` at a pinned commit, verified
     by SHA-256 in `scripts/password-blocklist.sh`, which rebuilds it. Shorter and longer entries are dropped because
     the length rules reject them first; the top-100k of the same sample holds only 488 passwords of 12+ characters,
     below ASVS 6.2.4's "top 3000 that match the policy", hence the top-1M source. Keycloak lower-cases list and
     candidate, so the check ignores letter case.
   - Shipped as a read-only mount at `/opt/keycloak/data/password-blacklists` (Keycloak's default folder): compose
     mounts the directory, the chart a ConfigMap (`keycloak-password-blocklist`, copy kept by
     `scripts/sync-chart-files.sh`, pod restarted on change by a checksum annotation), the Testcontainers Keycloak copies
     it (`RealmKeycloakResource.container`).
   - Keycloak keeps the list in a Bloom filter whose default false-positive rate (1e-4) would refuse one temporary
     password in 10,000 although it is on no list (core then answers 502 and rolls back). The rate is set to 1e-12
     (`KC_SPI_PASSWORD_POLICY__PASSWORD_BLACKLIST__FALSE_POSITIVE_PROBABILITY`, compose, chart and tests): about 72 KB
     of memory for 10,000 entries.
   - The temporary-password generator (ADR-0024) is unchanged: 16 characters of a 57-character alphabet (~93 bits);
     `TemporaryPasswordGeneratorTest` checks 100,000 draws against the list, the Keycloak test 25 issues against the
     real policy. Only 45 list entries even fit its shape, so a draw lands on one with a probability below 1e-21.
   - The theme says why in es/en/id (`invalidPasswordBlacklistedMessage`; Keycloak's own text calls the password
     "blacklisted"): at the first sign-in after a temporary password, on "forgot password" and on a password change.
   - No breached-password (HIBP) extension: it would be a third-party provider jar and a call out per password change.
3. **Optional OTP.** Keycloak's built-in `browser` flow already asks for a one-time code only when the login set one up
   (`Browser - Conditional 2FA`: condition "user configured", OTP form), and its built-in required action
   `CONFIGURE_TOTP` is enabled and not a default action. The realm file keeps both built-ins by listing neither
   `authenticationFlows` nor `requiredActions` (a list would replace them) and states the OTP policy explicitly: TOTP,
   HmacSHA1, 6 digits, 30 s, look-ahead 1, a code used once (the settings every authenticator app reads). A person
   sets it up in the account console (`/auth/realms/academy/account`, "Signing in" → "Set up authenticator
   application", which runs `CONFIGURE_TOTP`) and removes it there; an academy admin cannot see or reset it (only the
   Keycloak admin console can delete the credential). Nobody is forced, the super admin included. Direct grants are
   disabled for client `web`, so no flow bypasses the code.
4. **Existing realms.** The realm file is imported into an empty Keycloak database only. `just seed-users` patches a
   compose realm in place (headers, password policy, OTP policy, read from the realm file; the blocklist mount needs
   `just up` with the new compose file first). The chart imports with `IGNORE_EXISTING`: an existing kind realm keeps
   its settings until the Keycloak database is recreated (`deploy/kind/down.sh` + `up.sh`) or the settings are set in
   the admin console.

## Consequences
- ZAP: the Keycloak CSP findings "Failure to Define Directive with No Fallback" and "Wildcard Directive" are no longer
  accepted for `/auth/realms/`. One instance remains, accepted for that single URL: the OIDC session-status iframe
  (`login-status-iframe.html`) gets the realm CSP without `frame-ancestors`, which Keycloak drops there so the SPA can
  frame it (the same reason as the existing anti-clickjacking acceptance). `script-src unsafe-inline` stays accepted
  for `/auth/realms/` until Keycloak supports nonces (re-check per upgrade).
- A headless Chrome sweep (login, account console, "Signing in", the OTP set-up page with its QR code, logout
  confirmation, the login redirect to the dev-server origin) logged no CSP violation.
- A password on the list is refused wherever Keycloak sets one (sign-in pages, account console, admin API): dev seed
  passwords and test passwords must not be on it (none is).
- The web app has no link to the account console yet (it was not in this round's `apps/web` ownership): until it has
  one, a person reaches it at `/auth/realms/academy/account`.
- The master realm (admin console, only exposed locally with `HOOPS_EXPOSE_KC_ADMIN=true`) keeps Keycloak's default
  headers; the ZAP job runs with the console blocked.
