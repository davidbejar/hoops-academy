# WP0 — Repo bootstrap, toolchain, conventions, skills, secrets hygiene

Model: Sonnet (executed directly by the orchestrator on 2026-11-01). Depends on: —.

## Scope
- Toolchain install script and doctor; Podman socket env for Testcontainers.
- Repo at `~/code/hoops-academy`: parent POM (Quarkus BOM 3.40.1, Java 21, JaCoCo/PIT/dependency-check/ArchUnit/jqwik
  management), `.gitignore`, `.env.example`, `justfile`, pre-commit (gitleaks, detect-private-key), `.gitleaks.toml`.
- ADR-0001…0010, `CLAUDE.md`, `docs/domain/*`, vendored + project-local skills, CI skeleton.
- Maven wrapper; a throw-away `@QuarkusTest` proves Testcontainers works on Podman.

## Acceptance
- [ ] `./mvnw -q validate` passes
- [ ] `pre-commit run --all-files` passes; a commit containing a fake AWS key is blocked
- [ ] throw-away `@QuarkusTest` with Postgres Testcontainer passes via `scripts/env.sh`
- [ ] `just doctor` reports no blocking problems
