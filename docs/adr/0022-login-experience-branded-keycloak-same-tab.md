# ADR-0022: Login experience — branded Keycloak pages in the same tab, back to the app

- Status: Accepted; amended 2026-11-15 (the sign-in page follows the look chosen in the app: one script in the theme, at the end)
- Date: 2026-11-02
- Related: ADR-0005 (Keycloak authentication only), ADR-0018 (web shell), ADR-0019 (web session and sign-out)

## Context
Users reported three problems with signing in from the PWA:
1. After a successful login the tab stayed on `redirect.html` saying "You can now close this tab and return to the app".
   Closing it closed the app (it *was* the app's tab). Cause: with the `oidc` package's `samePage` navigation,
   `redirect.html` can only navigate back when the login was started with an `original_uri`; `OidcAuthService.login()`
   passed none, so the page waited 10 s for an app tab that no longer existed. Sign-out had the same dead end: the
   hand-built end-session request sent the browser to `redirect.html` without any `state` to resume.
2. The login page was Keycloak's stock page, visibly a different product.
3. The address bar showed the Keycloak URL, read as "exposing internal details".

In every deployment the app and Keycloak share one origin (nginx/ingress serve Keycloak under `/auth`); only the local
Flutter dev server on :5173 is a different origin from Keycloak on :8080. The URL's realm name and client id are public
by design (discovery document), so point 3 is about trust and look, not confidentiality.

## Decision
1. **Same-tab redirect that always comes back.** `login()` passes the current app URL as `originalUri`; sign-out uses
   the app's own base URL as `post_logout_redirect_uri` (both allowed by the `web` client). Covered by
   `test/core/oidc_auth_service_test.dart` and the real-browser round trip `apps/web/tool/browser_login_check.py`.
2. **Branded Keycloak login theme `hoops`** (`infra/keycloak/themes/hoops/login`): extends `keycloak.v2` with CSS only
   (no FreeMarker overrides, so Keycloak upgrades keep working): the app's Material 3 colours from its seed colour,
   basketball logo and "Hoops Academy", dark mode following the browser like the app, 48 px buttons, phone-first card.
   Keycloak's own translations (es / en / id) are used. Realm `loginTheme: hoops`; mounted by compose and by the Helm
   chart (ConfigMap, copies synced by `scripts/sync-chart-files.sh`, asserted by the chart tests).
3. Keycloak keeps owning every credential screen: login, forgot password, the invitation's set-password and
   verify-email actions, brute-force lockout, and later MFA.

## Alternatives rejected
- **Username/password form inside Flutter (Resource Owner Password Credentials / direct access grant).** The URL would
  never change, but OAuth 2.0 Security BCP (RFC 9700) says the password grant MUST NOT be used; the app's JavaScript
  would handle raw passwords; the public `web` client would need direct grants enabled; and the required-action flows
  (invitation first login, verify e-mail, reset password, MFA) would have to be rebuilt or still open Keycloak pages.
- **Keycloak page in an iframe inside the app.** Needs Keycloak's clickjacking protection (`frame-ancestors`) relaxed,
  weakens password-manager autofill, and breaks across origins in development because browsers block third-party
  cookies. Keycloak discourages it.
- **Popup / new tab.** Not mobile first; popups are blocked or awkward on phones.

## Consequences
- In production the address bar keeps the app's domain; during login the path shows `/auth/realms/academy/...`.
  Locally the host changes from :5173 to :8080 because the dev server is another origin; serving the build through
  nginx on :8080 would make development match production (not done).
- Theme edits show on reload with `start-dev` (compose); in the cluster the `checksum/theme` annotation rolls Keycloak.
- An existing realm gets `loginTheme` from `infra/keycloak/seed-users.sh` (the realm JSON is imported only into an
  empty volume).
- Recreating the Keycloak container (e.g. after `compose.yaml` changes) needs `podman restart hoops-nginx`: nginx keeps
  the old container IP and answers 502 on `/auth` (runbook `troubleshooting.md`).

## Amendment 2026-11-15 (owner decision): the sign-in page follows the look chosen in the app
**Why.** The theme was CSS only and followed the browser's dark mode, "like the app". Since WP105 the app has its own
choice (light, dark or system, per browser), so a person who chose light on a dark system got a dark sign-in page. The
choice lives in the app's storage; Keycloak's pages are another origin locally (:5173 and :8080) and cannot read it.

**Decision.**
- The app sends the choice with the sign-in request as the extra parameter `hoops_theme` = `light`, `dark` or `system`
  (`loginThemeParameter`, `OidcAuthService.login`). Keycloak ignores parameters it does not know.
- The theme gets one script, `resources/js/hoops-theme.js`, named in `theme.properties` (`scripts=`): still no
  template override, so Keycloak upgrades keep working. It reads the parameter, keeps `light` or `dark` in the tab's
  `sessionStorage` for the follow-up pages of the same sign-in (their addresses no longer carry the parameter) and
  puts keycloak.v2's `pf-v5-theme-dark` class on or off `<html>`; a `MutationObserver` holds it against keycloak.v2's
  own script, which sets the class from the browser's preference. `system`, a missing or an unknown value clears the
  stored choice and follows the browser, as before.
- Security: the script is served by Keycloak itself, so the realm's CSP (`script-src 'self'`, ADR-0038) is unchanged.
  Only the two literal values are compared; nothing read from the address is written into the page, and the value
  decides a single fixed class. No cookie; nothing is kept after the tab closes.
- Not chosen: a cookie shared by the app and Keycloak. Simpler, but it only works when both are served from one host.

**Proof.** `apps/web/test/core/oidc_auth_service_test.dart` (the parameter is sent for each choice),
`test/web/keycloak_login_theme_test.dart` (the script as text: no Node), the chart test "login theme script mounted",
and headless Chrome against the compose Keycloak: with the browser dark and light, `light`, `dark`, `system`, no
parameter and a hostile value each gave the expected class on `<html>`.

**Consequences.** The pages reached without the app (the account console, a reset link opened from an e-mail in a new
tab) still follow the browser. The script depends on keycloak.v2's class name `pf-v5-theme-dark`: a Keycloak upgrade
that moves to another PatternFly major needs it and `hoops.css` changed together. The chart ships the script in the
theme ConfigMap (`scripts/sync-chart-files.sh`).
