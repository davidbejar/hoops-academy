# ADR-0004: Flutter Web as the mobile-first PWA without a Node toolchain

- Status: Accepted
- Date: 2026-11-01

## Context
The frontend must be web, mobile-first, installable, work offline for court-side stat entry, and must not depend on Node. Alternatives: HTMX + Thymeleaf (pure Java, weak offline story), Vaadin (spawns Node internally).

## Decision
Flutter Web (Dart) PWA in `apps/web`: Riverpod, go_router, Dio, oidc (PKCE), Drift (sqlite3 wasm / IndexedDB) for the offline queue, Material 3, ARB localisation for es/en/id. API clients generated from OpenAPI with the Java-based openapi-generator.

## Consequences
Strong offline and app-like UX; one more language in the stack (Dart). Standard CanvasKit build (no COOP/COEP, which would break Keycloak flows); initial download mitigated with deferred libraries.
