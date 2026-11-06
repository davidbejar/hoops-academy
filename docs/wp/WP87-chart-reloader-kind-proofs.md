# WP87 — Chart: Reloader on Secret rotation, remaining kind proofs, rate-limit load guard, Testcontainers flake

Model: Opus. Wave 1 (2026-11-06, fifth round): runs alongside WP72 (web), WP78 (athlete), WP81 (core), WP83
(workflows; it wants kind for a ZAP full scan at its end: tell the orchestrator when you are done with kind). You own
`deploy/helm/**`, `deploy/kind/*`, `Tiltfile`, `.trivyignore.yaml`, `docs/runbooks/{kind,rotate-secrets,events,
deploy-related}.md`, `docs/adr/0012-*.md` (amendment), and for the flake only
`libs/common-quarkus/src/test/java/com/hoopsacademy/common/testing/**`, `.testcontainers.properties` / test
`application.properties` of the three services (Testcontainers settings only). Depends on: WP65 (ESO), WP66/WP71
(broker Secrets, bootstrap Job), WP63 (`ratelimit-check.sh`), WP46. Skills: podman-dev-env, owasp-security,
systematic-debugging, verification-before-completion. Worktree: `~/code/hoops-wt/wp87-chart-reloader`, branch
`wp87-chart-reloader`.

Decision 63 of 2026-11-06: Stakater Reloader (pinned) restarts the pods that read a rotated Secret; the kind proofs
not yet run are run; `ratelimit-check.sh` warns on high load; the Testcontainers flake is fixed or contained.

## Scope
1. **Reloader**: install pinned (OCI chart by version + digest, or manifests) from `up.sh` like ESO; annotate the
   Deployments/StatefulSets that read Secrets (`reloader.stakater.com/auto` or explicit lists) in the chart behind
   `reloader.enabled` (on in kind values); chart tests: annotations present on every workload that mounts/env-reads a
   Secret (derive the list from the render, red first), none when disabled; kubeconform; snapshots. kind proof:
   rotate `GAME_APP_PASSWORD` through ESO and a `hoops-redpanda-game-service` password: the pods restart without a
   manual rollout; `smoke.sh` green after. `rotate-secrets.md` updated (drop the manual restart notes), ADR-0012
   amendment. Chart 0.7.0 → 0.8.0.
2. **Remaining kind proofs** (WP71/WP65 open points): a deploy with `events.enabled=false` (+ the services healthy,
   no broker warnings), the game replica flip (`--set game.rosterSource=replica`), `tilt ci` on the current chart,
   `up.sh --eso` with the events, `up.sh --eso --deploy`; record each in `kind.md` "Verification status".
3. **Load guard**: `ratelimit-check.sh` (and `smoke.sh`) print the Podman VM load average and warn/skip the timing
   checks above a threshold (document the number; runbook symptom D).
4. **Testcontainers flake**: `AthleteDatabaseRoleTest` / `ReplicaAuthzRulesTest` "localhost:2375 failed to respond"
   on a Quarkus restart under load. Systematic debugging first (docker-java connection pool/keep-alive against the
   Podman socket? `TESTCONTAINERS_HOST_OVERRIDE`? the resource restarting the container?): fix or contain (retry on
   the resource start with backoff), proven by running the athlete module 3× while two other builds run.
5. **Docs**: runbooks as above; `.trivyignore.yaml` if Reloader adds a policy hit (with justification + expiry).

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED with the new assertions (red first); `shellcheck -S warning`,
      `actionlint` (if touched), `trivy fs` misconfig clean
- [ ] kind: rotation proof (both secrets) with pod restarts observed; the five remaining proofs recorded; cluster
      deleted at the end
- [ ] Flake: root cause or containment described with evidence; athlete module 3/3 green under load
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:**
  - Chart 0.8.0 (`hoops-service` 0.6.0, `keycloak` 0.5.0): `global.reloader.enabled` (default off, on in `values-kind.yaml`)
    puts `secret.reloader.stakater.com/auto: "true"` on the metadata of core, game, athlete, keycloak, ratelimit-redis and
    redpanda (every Deployment/StatefulSet that reads a Secret); not on web, mailpit or the `redpanda-bootstrap` Job.
  - `deploy/kind/up.sh` installs Stakater Reloader in both modes: chart 2.2.19 by version + digest
    (`sha256:dfa9fd16...`), image v1.4.23 by digest (`sha256:82c80a15...`), namespace `hoops-reloader`,
    `watchGlobally=false` + `namespaces=[hoops, envoy-gateway-system]` (namespaced Roles, no ClusterRole), `ignoreConfigMaps`,
    `ignoreJobs`, `ignoreCronJobs`, reload strategy `annotations`, read-only root FS, drop ALL, 10m/32Mi-128Mi.
    `envoy-ratelimit` gets the annotation through Envoy Gateway's `rateLimitDeployment.patch` (`EG_VALUES`).
  - `deploy/kind/kind-config.yaml`: `leader-elect=false` for kube-controller-manager and kube-scheduler (single control
    plane; under load they lost their lease every few minutes).
  - Load guard: `deploy/kind/load-guard.sh` (sourced): 1-minute load of the Podman VM and of the host; busy above
    `HOOPS_MAX_LOAD_PER_CPU` (default **2 per CPU**, i.e. 4 on the 2-CPU VM). `ratelimit-check.sh` prints it, skips the bursts
    on a busy machine and ends `RATE LIMIT CHECK INCOMPLETE` (exit 3; ACL check still runs; `HOOPS_LOAD_WAIT=<s>` waits,
    `HOOPS_LOAD_GUARD=off` forces); `smoke.sh` prints it and gives the events 270 s instead of 90 s.
  - Flake: `ContainerStarts` (common-quarkus test-jar) pings the Docker API before a container start and retries a start
    that met a closed connection (3 attempts, 1 s / 2 s backoff, only for that cause); `PostgresRlsResource` and
    `RealmKeycloakResource` use it. `IdleDockerConnectionTest` reproduces the flake deterministically, `ContainerStartsTest`
    (8 unit tests) specifies the containment.
  - Docs: ADR-0012 amendment (decision 63), `rotate-secrets.md` (sections C, D, E: the manual restarts replaced by what is
    still manual), `events.md` (service user and superuser rotation), `kind.md` (Start, Secrets, Verification status WP87),
    `release.md` (chart 0.8.0, installing Reloader elsewhere), `troubleshooting.md` symptom D (the threshold).
- **Verified:**
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED, **144 ok** (134 + 10 new, committed red first in `f9fa366`),
    kubeconform 230/230. New block "secret rotation": annotation iff the workload reads a Secret, derived from the render,
    in `umbrella-kind`, `umbrella-eso` and `service-all` (subchart alone); none in `umbrella-default`, `umbrella-tls`,
    `service-defaults`; Job not annotated; kind switch on; Reloader pinned in `up.sh`. Five mutations (redpanda not
    annotated, annotation while off, web annotated, kind switch off, image digest missing) each failed the run.
    `shellcheck -S warning -x` (run.sh, deploy/kind/*.sh) clean; `trivy fs --scanners misconfig --severity HIGH,CRITICAL
    --ignorefile .trivyignore.yaml` exit 0 (no new ignore). `trivy config` of the rendered Reloader install: no
    HIGH/CRITICAL; MEDIUM KSV-0048/0049/0113/0125 are what Reloader does (patch workloads, read Secrets, ghcr.io).
  - Load guard: on this machine (VM 9-11 on 2 CPUs, host 17-19 on 10) `ratelimit-check.sh events` printed the loads and
    ended INCOMPLETE, exit 3; with `HOOPS_MAX_LOAD_PER_CPU=1000` it ran the burst. Found and fixed on the way: in an
    `es_ES` locale `sysctl` prints `14,70` and awk misreads decimals, so the guard runs both with `LC_ALL=C`.
  - kind, partial: the first `up.sh --eso --deploy --from-host` installed ESO, then Reloader (no ClusterRole; Roles in
    `hoops`, `envoy-gateway-system`, `hoops-reloader`; log `Watching scoped namespaces: envoy-gateway-system, hoops,
    hoops-reloader`, `created controller for: secrets` only), Envoy Gateway (`envoy-ratelimit` annotated through the patch),
    CNPG, built and loaded the four images, then the chart install failed (CNPG webhook unreachable: controller-manager,
    scheduler and the CNPG operator restarting at a VM load of 30-68 from four other agents' builds). With leader election
    off (both manifests show `--leader-elect=false`) two more attempts lost the API server itself (TLS handshake timeout,
    `http2: client connection lost`). Cluster deleted each time. **Not run:** the rotation proof (`GAME_APP_PASSWORD`, then
    `hoops-redpanda-game-service`, then optionally `RATELIMIT_REDIS_PASSWORD` with `ratelimit-check.sh acl`),
    `events.enabled=false`, the game replica flip, `tilt ci`, `--eso` with the events, a complete `up.sh --eso --deploy`.
    Helper for the proof: rotate a source property, force-sync, watch `reloader-reloader` logs and the pod ages; the
    runbook text in `rotate-secrets.md` E describes the expected behaviour, not yet observed.
  - Flake diagnosis (systematic debugging):
    1. Evidence: the Podman API service (`podman system service`, default `--time 5`) closes keep-alive connections idle for
       **10 s** (2 x `--time`): a raw socket client got EOF without a response after 11 and 15 s of idle, an answer after
       2-9 s. docker-java 3.7.1 (Testcontainers 2.0.5) builds its pool with `validateAfterInactivity(-1)` (bytecode of
       `ApacheDockerHttpClientImpl`), so it never checks a pooled connection. Apache HttpClient re-sends a GET that met a
       closed connection (`HttpRequestRetryExec ... recoverable I/O exception (NoHttpResponseException) ... re-executed`)
       but not a POST.
    2. Reproduction without load: a POST after 3/8 s idle ok, after 12/12/20 s `NoHttpResponseException: localhost:2375
       failed to respond`. `IdleDockerConnectionTest` (start the database, stop it, wait 12 s, start again) failed 10 ms
       after "Creating container", exactly as in WP60. Once Testcontainers knows an image it sends no GET before the
       create, so the POST gets the dead connection. Load matters only because it stretches the Quarkus restart between
       classes past 10 s.
    3. Fix in code (containment): the ping before the start. Green: `IdleDockerConnectionTest` (the ping hit the dead
       connection, was re-sent, the create succeeded), `ContainerStartsTest` 8/8.
    4. Under load (other builds: core-service in the main checkout, WP78 athlete, the commit hook), `./mvnw -pl
       services/athlete-service -am verify -Dquarkus.http.test-port=0` with the containment: **2 of 3 failed**, both in
       `ReplicaAuthzRulesTest`, now on the Kafka **Dev Services** container (Redpanda), which Quarkus starts in its own
       classloader with its own Docker client (exchange counter `ex-0000000003` every time), out of reach of test code.
       The database containers (the original reports) no longer failed.
    5. Root-cause fix, proven without touching the shared service: a second API service in the VM with `--time=0`
       (`systemd-run --user ... podman system service --time=0`, forwarded by ssh) kept idle connections at 9/11/15/25 s,
       and the athlete module through it went **3/3 green** (790 tests each, 0 `failed to respond`, 0 re-sends) at a VM load
       of 11-20 and a host load of 15-27 with the core build and the commit hook's isolation check running. Service and
       forward removed afterwards.
- **Decisions/ADRs:** ADR-0012 amendment (decision 63). The switch is `global.reloader.enabled`, not the briefed
  `reloader.enabled`, because the subcharts see only `global` and a new key needs no mirror. `secret.` auto annotation
  (Secrets only, ConfigMaps already roll through checksums), annotations strategy, namespaced scope, Reloader installed by
  `up.sh` like ESO rather than by the chart. Checksum annotations rejected (the chart never sees Secret values). Leader
  election off on kind's single control plane. Load threshold 2 per CPU.
- **Open points / follow-ups:**
  - **kind proofs not run** (the machine was saturated the whole session; see Verified). Run them in a quiet window, in this
    order on one cluster: `up.sh --eso --deploy --from-host`, `smoke.sh`, rotate `GAME_APP_PASSWORD` and
    `REDPANDA_GAME_SERVICE_PASSWORD` (then `helm upgrade` for the Job), smoke, `--set game.rosterSource=replica`, smoke,
    `--set events.enabled=false --set global.events.enabled=false`, check logs for broker warnings, smoke; then
    `helm uninstall hoops` and `tilt ci -- --eso --from-host`. If the CNPG operator still restarts under load, turn its
    leader election off too (up.sh patch).
  - **Pending user action (root cause of the flake):** run the Podman API without the idle timeout. In the VM:
    `mkdir -p ~/.config/systemd/user/podman.service.d` and a drop-in `[Service]` / `ExecStart=` /
    `ExecStart=/usr/bin/podman $LOGGING system service --time=0`, then `systemctl --user daemon-reload`. It takes effect
    when the service next restarts (it exits after 5 s without connections, or `systemctl --user restart podman.service`
    when no build runs). Lost on `podman machine rm`. Worth a check in `just doctor` / `scripts/env.sh` and a line in the
    `podman-dev-env` skill (not my files). CI's rootless `podman.socket` has the same default (WP83's workflows).
  - Core's own `KeycloakContainerResource` and its MailHog container (core-service, WP81's files) start containers
    without `ContainerStarts`; wrap them with `ContainerStarts.start(...)`.
  - The commit hook's isolation check failed twice under load (Keycloak `/health/ready` not up within 5 min); passed on retry.
  - Docs pass: README/HANDOVER/FOLLOW-UPS (the athlete flake entry can point here), ADR README row for 0012.

