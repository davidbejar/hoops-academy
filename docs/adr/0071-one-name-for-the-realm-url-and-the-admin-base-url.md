# ADR-0071: one name for the realm URL and one for the Keycloak admin base URL

- Status: Accepted
- Date: 2026-11-24
- Related: ADR-0005 (Keycloak for authentication only), ADR-0034 (audiences), ADR-0051 and ADR-0052 / ADR-0055 (the Rust
  and Go services), ADR-0069 (settings shared in common-quarkus), decision 110 of 2026-11-23,
  [WP139](../wp/WP139-realm-url-one-name-login-helper-db-roles.md), audit 2026-11-23 X-05, INF-01, DEP-07

## Context
The same Keycloak was described by variables of two shapes. core, pdf-service and finance-service read the realm URL
(`OIDC_AUTH_SERVER_URL`, e.g. `http://localhost:8080/auth/realms/academy`); game and athlete read a Keycloak base
(`KEYCLOAK_URL`) and appended `/realms/academy` themselves, with a default of `http://localhost:8180` where nothing has
ever listened. core read `KEYCLOAK_URL` too, but as the base of its Admin API client, and the e2e suite had a third
name for that base (`E2E_KEYCLOAK_ADMIN_URL`). So the chart set `KEYCLOAK_URL` and `OIDC_AUTH_SERVER_URL` for core and
only `KEYCLOAK_URL` for game and athlete, `e2e/bin/services-up.sh` exported both, and `quarkus:dev` of game or athlete
without that script could not validate a token.

## Decision
1. **`OIDC_AUTH_SERVER_URL`** is the realm as the process reaches it (the back channel: discovery, keys, the token
   endpoint for service tokens). Every service reads it: the Quarkus services through common-quarkus'
   `microprofile-config.properties` (`quarkus.oidc.auth-server-url` and `quarkus.oidc-client.auth-server-url`, ADR-0069;
   no service sets them itself), pdf-service and finance-service in their own config code. It is the name Quarkus' key
   (`auth-server-url`) and the two other languages already used. The issuer in the tokens is a different value where
   the public URL differs (kind, cloud: `OIDC_ISSUER` of pdf and finance, Keycloak's `KC_HOSTNAME`) and keeps its names.
2. **`KEYCLOAK_ADMIN_URL`** is the Keycloak base the Admin API is called on (`<base>/admin/realms/academy/...`): core's
   admin client (`quarkus.keycloak.admin-client.server-url`) and the e2e suite's `KeycloakAdmin`. Read next to
   `KEYCLOAK_ADMIN` / `KEYCLOAK_ADMIN_PASSWORD`, it is the address of that admin.
3. **Defaults** are where `just up` serves Keycloak: `http://localhost:8080/auth/realms/academy` and
   `http://localhost:8080/auth`. `quarkus:dev` and `e2e/bin/services-up.sh` need neither variable; `.env.example`
   documents both, commented out. The chart sets the in-cluster `http://keycloak:8080/auth/realms/academy` once for the
   three Quarkus services (`global.quarkusEnv`, with the CORS allow-list: DEP-07) and `KEYCLOAK_ADMIN_URL:
   http://keycloak:8080/auth` for core; compose sets the in-network realm URL once for pdf and finance
   (`x-service-env`). The e2e suite defaults the admin base to `<base URL>/auth`; on kind the port-forward is passed as
   `KEYCLOAK_ADMIN_URL=http://localhost:18080/auth`.
4. **Retired**: `KEYCLOAK_URL`, `E2E_KEYCLOAK_ADMIN_URL` and `localhost:8180`. `scripts/tests/test_realm_variables.py`
   fails while a tracked file outside the ADRs and the work-package records names one; `LibraryDefaultsContract`
   and core's `KeycloakAdminUrlTest` show that each service sees the defaults, follows the variable and ignores the old
   name.

## Alternatives rejected
- **`KEYCLOAK_URL` as the one base, each service appending the realm**: the Rust and Go services and two Quarkus keys
  take the realm URL; the realm name would be repeated in every consumer.
- **New names for both (`HOOPS_REALM_URL`, ...)**: renames three services, compose and the chart for no gain over the
  name most of them already read.
- **Keeping `E2E_KEYCLOAK_ADMIN_URL`**: a third name for the same base; the `E2E_` prefix marks settings only the suite
  has (mail sink, redirect URI).

## Consequences
- A `.env` (or a private `values-local.yaml`) that set `KEYCLOAK_URL` or `E2E_KEYCLOAK_ADMIN_URL` must rename it to
  `KEYCLOAK_ADMIN_URL`; for game and athlete a `KEYCLOAK_URL` is now ignored (set `OIDC_AUTH_SERVER_URL` to the realm).
- Chart 0.15.0: game's and athlete's ConfigMaps carry `OIDC_AUTH_SERVER_URL` instead of `KEYCLOAK_URL`, core's
  `KEYCLOAK_ADMIN_URL` instead of `KEYCLOAK_URL`.
