# ADR-0019: Web session lifetime and sign-out semantics

- Status: Accepted (records decisions taken in WP11, WP13 and WP14b)
- Date: 2026-11-02

## Context
Coaches and parents score matches on shared tablets and phones, sometimes offline for the whole game. WP11 requested
`offline_access`, so a long-lived offline refresh token sat in localStorage (F-08). The security review found that a
sign-out while offline or with Keycloak unreachable left every token in localStorage, so the next person was signed in
as the previous one (F-03), and that the offline match database survived sign-out (F-07).

## Decision
1. **Scopes `openid profile email`, no `offline_access`.** The refresh token is a normal SSO-session token (realm SSO
   idle 4 h, max 12 h; access token 5 min). The app refreshes proactively (`refreshBefore` 60 s) with a 401
   refresh-once backstop. Scoring offline needs no token; only sending the batch does.
2. **Session expiry keeps local data.** When a refresh fails (`expireSession`), the sync queue pauses (`pausedForAuth`),
   unsynced events stay in Drift and are sent after the next sign-in. Events are only ever sent with the token of the
   person who recorded them (sync scope = tenant + person).
3. **Sign-out order** (`lib/app/sign_out.dart`): warn if any unsynced events exist (Cancel changes nothing); clear the
   selected tenant; wipe the whole match database including the device id (`MatchStore.wipe`); then
   `OidcAuthService.logout`, which forgets the user locally first (after a best-effort refresh-token revocation, 3 s
   timeout, online only) and only then navigates to the end-session URL it builds itself.
4. **Offline sign-out** skips the end-session call instead of queueing it (queueing would require keeping the id token on
   the device). The Keycloak SSO cookie then expires by itself.

## Consequences
- A device offline for more than 4 h must sign in again once online; its unsynced events are kept and sync afterwards.
- Signing out discards unsynced events after an explicit warning: shared-device privacy is preferred over retention.
- Residual (F-07): cached reads are keyed by match id only, and a *different* user signing in after an expired session
  (no sign-out) does not wipe the database. Follow-up: tenant + person columns and a wipe on `sub` change.
- Residual (F-08): refresh-token rotation / reuse detection is not enabled in the realm.
- Not verified against a real Keycloak end-session round trip in a browser (no chromedriver); unit tests in
  `test/app/sign_out_test.dart`, `test/core/app_config_test.dart`, `test/features/match/data/match_store_wipe_test.dart`.

## Alternatives considered
- Keep `offline_access` for long matches — rejected: long-lived bearer secret in localStorage for marginal benefit.
- Keep unsynced events across sign-out — rejected: the next user of a shared device could read or send them.
