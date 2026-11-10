# WP94 — Docs: entity and class diagrams per service, generated and drift-checked

Model: Sonnet · effort medium. Wave 1 (2026-11-10, sixth round): runs alongside WP91 (core), WP92 (athlete: it adds
migration `V10` and domain classes in its own branch), WP93 (tooling), WP95 (web). You own
`docs/domain/core-model.md`, `docs/domain/game-model.md`, `docs/domain/athlete-model.md` (new),
`scripts/model-diagrams.sh` and its helpers (new), and one step in `.github/workflows/ci.yml` (nobody else edits
`ci.yml` this wave). Shared file: `justfile` (recipes `diagrams` and `diagrams-check` next to the related ones; WP93
adds `test-hooks`). Do not add or change files inside `services/**` or `libs/**`. Depends on: FOLLOW-UPS "Backend:
Entity and class diagrams per service". Skills: clean-code, podman-dev-env, verification-before-completion.
Worktree: `~/code/hoops-wt/wp94-model-diagrams`, branch `wp94-model-diagrams`.

## Scope
1. **ER diagram per service** (Mermaid `erDiagram`): every table of the service's schema with its primary key,
   foreign keys, `tenant_id` and the main columns, including the `*_ref` replicas, outbox and billing seams. It is
   generated, never drawn: `scripts/model-diagrams.sh` starts a throwaway PostgreSQL (the pinned image the repo
   already uses, with `infra/db/init`), applies the service's Flyway files of the working tree in order, reads
   `information_schema` / `pg_catalog` and writes the Mermaid block. Do not read the shared compose database: other
   worktrees migrate it. Output must be deterministic (sorted, no timestamps).
2. **Class diagram per service** (Mermaid `classDiagram`) of the `domain` packages: aggregates, value objects
   (`TenantId`, `PlayerId`, …), enums and ports of `application`, with the main relations. Also generated: a small
   parser over the Java sources (python3 standard library only; no new build dependency, no Node). Keep it readable:
   group by sub-package, leave out private members, cap the members listed per class.
3. **Drift check**: `scripts/model-diagrams.sh --check` regenerates into a temp directory and fails with a diff when
   a page is stale; `just diagrams` regenerates, `just diagrams-check` checks; one step in `ci.yml` runs the check
   (the runner has rootless Podman; follow how the existing jobs start containers).
4. **Pages**: each `docs/domain/<service>-model.md` has a short hand-written introduction (what the service owns),
   then the two generated blocks between marker comments so the generator replaces only them. Mermaid must render on
   GitHub (check the size limits: split a diagram by area when it is too large to read).

## Acceptance
- [ ] `just diagrams` twice gives no diff; `just diagrams-check` passes; a deliberately added column or domain class
      makes it fail (show both in the handover)
- [ ] The three pages render (paste how you checked: a Mermaid CLI is not available, so validate the syntax with a
      strict parser of your own or by the rules of the Mermaid grammar you rely on)
- [ ] `actionlint .github/workflows/*.yml` clean
- [ ] Handover appended: how long the check takes, how other WPs regenerate (`just diagrams`), links the docs pass
      must add to `docs/architecture.md` and the README

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.
- WP91 and WP92 change the model in parallel. Your pages describe `main` as you branched; the orchestrator
  regenerates on the combined tree when it merges you last in this wave.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
