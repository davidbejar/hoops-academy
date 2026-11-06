# WP66 — Events infra: Redpanda in compose, chart and kind; Dev Services for tests

Model: Opus. Wave 3 (2026-11-06, fourth round): starts after WP65 is merged (kind); runs alongside WP54 (web) and
WP62 (athlete norms); you are the only agent using kind this wave. You own `infra/compose/compose.yaml`,
`deploy/helm/**`, `deploy/kind/*`, `Tiltfile`, `libs/common-quarkus` messaging config (if a shared config class is
needed), the root `pom.xml` dependency management for `quarkus-messaging-kafka`, `docs/runbooks/`, `docs/adr/0036-*.md`.
Not the services' code (WP67–WP69). Depends on: ADR-0008 (outbox + events), WP19 brief (`docs/wp/WP19-outbox-redpanda.md`),
WP46/WP65 (chart conventions, Secrets). Skills: podman-dev-env, owasp-security, verification-before-completion.
Worktree: `~/code/hoops-wt/wp66-redpanda`, branch `wp66-redpanda`.

Decision 48 of 2026-11-06: v2 events start now. Redpanda (single node, pinned image) is the broker in compose,
the chart (behind `events.enabled`, on for kind) and kind; tests use Quarkus Dev Services for Kafka (Redpanda
image pinned to the same version). ADR-0036 reserved for you (broker choice, topics and naming, retention,
auth inside the cluster, what the services will do in WP67–WP69).

## Scope
1. **compose**: `redpanda` service (pinned tag, resource-limited, dev mode, no auth) + `rpk` topic bootstrap of the
   seven topics from the WP19 brief (`core.person`, `core.player`, `core.team`, `core.team-player`,
   `core.team-staff`, `core.guardian-link`, `core.tenant`) with 1 partition each (document the key: tenant id +
   aggregate id); a `just events-topics` recipe; `just up` includes it; `.env.example` keys if any.
2. **Chart**: `redpanda` StatefulSet or the official chart as a dependency (pin; compare size/complexity and decide
   in the ADR), NetworkPolicy that admits only the three services, read-only root FS / non-root like the other
   pods, SASL/SCRAM inside the cluster with credentials from a Secret (`secrets.sh` + the WP65 ESO path), topic
   bootstrap Job; chart tests and snapshots; `kubeconform` schemas if CRDs are involved.
3. **kind**: `up.sh` deploys it with the kind values; `smoke.sh` gains a broker check (`rpk cluster health` or the
   admin API); delete the cluster at the end.
4. **Dev Services**: root pom `quarkus-messaging-kafka` managed version; a `libs/common-quarkus` note on
   `quarkus.kafka.devservices.image-name` pinned; nothing enabled in the services yet (WP67).
5. **Docs**: ADR-0036; runbooks (`kind.md`, deploy §4 in `release.md`, a short `events.md` runbook: topics, how to
   tail with `rpk`, reset a consumer group).

## Acceptance
- [ ] `just up` with Redpanda healthy and the topics present (`rpk topic list` output in the handover); `just e2e`
      still 21/21 on compose
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED; kind: Redpanda ready behind the NetworkPolicy, smoke green;
      cluster deleted
- [ ] `shellcheck -S warning` and `actionlint` clean on anything touched; ADR-0036 written and indexed (append at the
      end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds on the same machine; the compose stack ports and kind are yours this wave.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
