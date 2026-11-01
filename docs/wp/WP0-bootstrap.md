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

## Handover (2026-11-01)
- Built: repo at `~/code/hoops-academy` (git, main); parent POM (Quarkus 3.40.1, Java 21, JaCoCo/PIT/dependency-check/
  ArchUnit/jqwik/keycloak-admin-client/testcontainers-keycloak/swagger-request-validator managed); Maven wrapper
  3.9.11; `scripts/{env,bootstrap,doctor}.sh`; `justfile`; `.gitignore`, `.env.example`, `.gitleaks.toml`,
  pre-commit (gitleaks 8.30, detect-private-key, hygiene hooks) installed; CI skeleton; ADR-0001…0010; `CLAUDE.md`;
  `docs/domain/{authz-matrix,glossary}.md`; vendored skills (clean-code, test-driven-development,
  verification-before-completion, systematic-debugging, owasp-security — MIT, Markdown only, provenance in
  `.claude/skills/THIRD_PARTY_SKILLS.md`) + project skills (quarkus-hexagonal-service, tenant-isolation-testing,
  flutter-feature, podman-dev-env, work-package); `infra/db/init/01_roles_schemas.sql` + `02_passwords.sh`;
  placeholder module POMs for `libs/common-quarkus` and `libs/contracts`; briefs WP1–WP11, WP16.
- Toolchain installed via Homebrew: openjdk@21 (formula; the temurin cask needs sudo and was skipped), maven 3.10,
  kind 0.33, helm 4.3, tilt 0.37, podman-compose 1.6 (podman compose currently delegates to the docker-compose
  binary found at /usr/local/bin), gitleaks 8.30, pre-commit 4.7, openapi-generator 7.26, trivy 0.76, just 1.59,
  Flutter 3.47.9 (web enabled, Chrome found).
- Verified: `./mvnw -q validate` OK; `pre-commit run --all-files` all hooks pass; a staged file with a fake
  `AKIA…` key + secret is blocked by the gitleaks hook (`leaks found: 1`); throw-away Quarkus 3.40.1 project with
  Postgres Dev Services ran 1 test, 0 failures through the Podman socket (rootless machine, Ryuk disabled);
  `just doctor` → 18 ok, 0 blocking.
- Decisions: Homebrew openjdk@21 instead of Temurin cask; Podman machine kept rootless (2 CPU / 8 GiB) for now —
  rootful + 6 CPU / 12 GiB recommended before WP16 (kind); WP briefs are written just-in-time per wave rather than all
  in WP0 (more accurate briefs).
- Open points: `testcontainers.reuse.enable=true` in `~/.testcontainers.properties` would speed local runs (optional);
  the OneDrive folder holds only spec/plan/README.
