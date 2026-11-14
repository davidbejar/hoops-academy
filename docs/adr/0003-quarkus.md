# ADR-0003: Quarkus 3.x on Java 21 for backend services

- Status: Accepted; amended 2026-11-14 (decision 81, WP109: Java 25 LTS)
- Date: 2026-11-01

## Context
Services must be lightweight in Kubernetes, start fast, and integrate with Podman-based Testcontainers and OIDC. Candidates were Spring Boot 3 and Quarkus.

## Decision
Quarkus 3.x (platform BOM pinned in the parent POM), Java 21 LTS, JVM mode by default; native images are an optional later step.

## Consequences
Lower memory per pod, Dev Services and OIDC out of the box, first-class Flyway/Hibernate/REST client. Fewer third-party examples than Spring; agents must follow Quarkus idioms (CDI, Panache optional).

## Amendment 2026-11-14 (decision 81, WP109): Java 25 LTS
The services build and run on **Java 25 LTS** (`maven.compiler.release` 25, Temurin 25 in CI, build image
`maven:3-eclipse-temurin-25`, runtime `ubi9/openjdk-25-runtime` pinned by its multi-arch index digest). Quarkus has
supported Java 25 fully since 3.31 (runtime images and native builds); the platform in use (3.40.1.2) is later. Every
bytecode-reading tool in the build was checked against its release notes first and was already at or beyond its first
Java 25 release (JaCoCo 0.8.14, PIT 1.19.6 with ASM 9.8, ArchUnit 1.4.1, SpotBugs on ASM 9.11 and BCEL 6.13, CodeQL
2.23.1); no gate changed. The upgrade lives on the branch `jdk-25` until the owner merges it; the findings with their
sources are in `docs/wp/WP109-jdk-25-branch.md`. `scripts/env.sh` selects exactly the major in `_JDK_MAJOR`, and
`scripts/tests/test_jdk_pins.py` keeps it, the images and `actions/setup-java` equal to `maven.compiler.release`.
