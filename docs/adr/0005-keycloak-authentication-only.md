# ADR-0005: Keycloak for authentication; tenant roles owned by core-service

- Status: Accepted
- Date: 2026-11-01

## Context
Users need SSO-grade authentication (PKCE, password policies, brute-force protection) without us storing passwords. Tenant roles are relational (team staff, guardian links) and change frequently.

## Decision
Keycloak realm `academy` handles authentication only; the single Keycloak role is `super_admin`. Tenant memberships and roles live in `core.membership_role`; every request carries `X-Tenant-Id` and services resolve an `AuthzContext` (core from its DB, others via `/internal/authz` with a 30 s cache). Non-members receive 404.

## Consequences
No dual writes to Keycloak and no stale role claims; one extra cached internal call for game/athlete services. Keycloak Admin API is used only to provision users on invitation.
