# ADR-0003: Quarkus 3.x on Java 21 for backend services

- Status: Accepted
- Date: 2026-11-01

## Context
Services must be lightweight in Kubernetes, start fast, and integrate with Podman-based Testcontainers and OIDC. Candidates were Spring Boot 3 and Quarkus.

## Decision
Quarkus 3.x (platform BOM pinned in the parent POM), Java 21 LTS, JVM mode by default; native images are an optional later step.

## Consequences
Lower memory per pod, Dev Services and OIDC out of the box, first-class Flyway/Hibernate/REST client. Fewer third-party examples than Spring; agents must follow Quarkus idioms (CDI, Panache optional).
