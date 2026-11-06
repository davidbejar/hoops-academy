# ADR-0034: A token audience per service, refresh tokens rotate with reuse detection

- Status: Accepted
- Date: 2026-11-06
- Related: decision 38 of 2026-11-06, WP56, `docs/security/review-2026-11.md` F-08 and F-14, ADR-0005 (Keycloak
  authentication only), ADR-0019 (web session and sign-out), ADR-0008 (synchronous `/internal` calls)

## Context
Every service accepted any access token of realm `academy` (F-14): a token minted for one client was good at all three
services, including a service's own client-credentials token at its own API. The web client's refresh token lived in
browser storage and could be replayed for the whole SSO session (F-08, partly fixed in WP14b by dropping
`offline_access`). Decision 38 of 2026-11-06: each service verifies its own audience, the realm maps the audiences, the
web client's token carries all three, and the realm rotates refresh tokens with reuse detection.

Who calls whom: the browser (client `web`) calls core, game and athlete; game and athlete call core's `/internal`
(`CoreInternalClient`, authz and roster) with their own client-credentials token (`ServiceTokenClientFilter`); core
calls game's and athlete's `/internal/usage` with its own. No user token is forwarded between services.

## Decision
1. **One audience per service, verified by the service.** `quarkus.oidc.token.audience=<service>-service` in each
   service (`core-service`, `game-service`, `athlete-service`, the services' own client ids). A token whose `aud` lacks
   it is a 401 before any role or tenant check; the realm role `service` does not help.
2. **The realm maps the audiences per client, least privilege.** Each client has `oidc-audience-mapper` protocol
   mappers (`included.client.audience`, access token only, not the id token):
   | client | `aud` of its access tokens |
   |---|---|
   | `web` (public, PKCE) | `core-service`, `game-service`, `athlete-service` |
   | `core-service` (service account) | `game-service`, `athlete-service` |
   | `game-service` | `core-service` |
   | `athlete-service` | `core-service` |

   A service's token is for the services it calls, never for itself. Mappers sit on the clients, not in realm-level
   `clientScopes`: a realm import that lists `clientScopes` gets none of Keycloak's built-in scopes (`basic`, `roles`,
   ...), which would drop `sub` again (F-21). Keycloak adds `account` (and `realm-management` for core's service
   account) on its own; no service accepts those as its audience.
3. **Refresh tokens rotate with reuse detection.** Realm `revokeRefreshToken: true`, `refreshTokenMaxReuse: 0`:
   every refresh answers a new refresh token and the presented one is spent; presenting a spent one is refused with
   `invalid_grant`. The SSO session lengths stay (idle 4 h, max 12 h), so does the 5-minute access token.
   Keycloak 26 goes further than refusing: the reuse **ends the client's session**, so the newest refresh token of
   that chain is refused too ("Session doesn't have required client"; `RealmRefreshTokenRotationKeycloakTest`).
   A thief who replays a spent token and the user who owns the chain are both out; the user signs in again (the SSO
   cookie usually makes that one click).
4. **The web client survives rotation, also with several tabs.** `package:oidc` sends the refresh token of the last
   answer and stores it (pinned by `apps/web/test/core/oidc_refresh_rotation_test.dart`). But all tabs share the
   stored session while each keeps a copy in memory, and all of them refresh before the same expiry: without care the
   second tab presents the token the first has just spent, and by point 3 every tab is signed out every few minutes.
   `SerialRefresh` (the token hook of `OidcAuthService`) prevents that: a refresh runs under the exclusive Web Lock
   `hoops-oidc-refresh` that all tabs of the origin share (`navigator.locks`; an in-process lock where the API is
   missing), sends the refresh token currently in the store instead of the tab's own copy when the two differ, and
   keeps the lock until `package:oidc` has stored the answer (at most 2 s), so the next tab reads the new token. A
   retry after a refusal would not help: the refusal has already ended the session.

## Consequences
- Proof, real Keycloak with the real realm file (`@Tag("keycloak")`, `-Pkeycloak-it`): `TokenAudienceKeycloakTest` in
  each service (a token for audience `another-service` with role `service` is a 401; the service's own token is a 401;
  the calling service's token and the web client's token pass), `RealmRefreshTokenRotationKeycloakTest` (reuse refused).
  In `verify`: `RealmTokenPolicyTest` pins the mappers and the realm settings. On compose the e2e journey checks both
  (`everyServiceRejectsATokenThatIsNotForItsAudience`, `aRefreshTokenWorksOnceAndIsRejectedWhenUsedAgain`). Two tabs
  on one chain: `oidc_refresh_rotation_test.dart` (a fake token endpoint with the realm's reuse semantics). The test
  realm (`TestRealm` in common's test-jar) adds a copy of `web` with direct grants, so test tokens carry the web
  client's real audiences.
- **A realm change needs a re-import** on an existing stack (Keycloak imports only into an empty database):
  `docs/runbooks/local-stack.md`. `just seed-users` also adds the audience mappers and the rotation settings to an
  older realm. Until then every API call answers 401. kind always imports a fresh realm (chart copy synced by
  `scripts/sync-chart-files.sh`).
- `deploy/kind/smoke.sh` called each service's API with that service's own token and expected "not 401"; under
  decision 2 that is a 401 by design. It now calls core with game's token and game and athlete with core's (not 401),
  and each service with its own token (401).
- A new service or a new caller needs a mapper on the calling client and the callee's audience in its properties;
  `RealmTokenPolicyTest` lists the expected audiences per client.
- Residual (F-08): tokens are still in browser storage (XSS would read them; none found). A stolen refresh token works
  until either party refreshes; the next presenter of a spent token ends the session for both.
- Residual (UX): a tab that cannot take part in the lock (a second browser profile is a separate store anyway; an old
  browser without Web Locks with two tabs open) can still race and be signed out; it then signs in again.
