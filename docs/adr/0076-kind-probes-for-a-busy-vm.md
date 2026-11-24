# ADR-0076: kind probes for a busy Podman VM; helm's timeout stays the outer bound

- Status: Accepted
- Date: 2026-11-24
- Related: decision 116 of 2026-11-24, [WP146](../wp/WP146-kind-and-ci-hardening.md), WP139 (the failed `helm --wait`),
  WP86 (CNPG without leader election), WP87 (load guard of the checks), ADR-0051 (kind + Helm), ADR-0073 (PostgreSQL 19)

## Context
`deploy/kind/up.sh --deploy` runs the whole release (five JVM services, Keycloak, two CloudNativePG clusters, Redpanda,
the observability pods) on the Podman VM, which has 2 vCPUs and also runs the compose stack. WP139 saw `helm --wait`
fail once on Keycloak at a VM load of 31. WP146 ran the install with a Maven build alongside and recorded each failure:

| Run | Load (VM, 1 min) | What failed | Cause, with evidence |
| --- | --- | --- | --- |
| 1, no change | up to 68 | `helm upgrade`: the CNPG webhook refused the apply of both Clusters | the operator's upstream probes (1 s timeouts, 30 s to start) killed it into CrashLoopBackOff (7 restarts, exit 143) |
| 2, CNPG patched | 85-123, CPU pressure 97 % | 15 m ran out, Keycloak and three services not ready | Keycloak killed by its liveness probe (1 s timeout, exit 137) about 10 minutes into its start; the services by theirs (2-3 s, 30 s to a kill) |
| 3, all below | 32-63 | 15 m ran out, core, game, athlete and lgtm not ready | Keycloak, both databases and the operator came up with 0 restarts; the three services were killed by liveness and startup probes, and the kube-apiserver itself restarted |

Helm 4 waits with kstatus: a Deployment whose `Progressing` condition says `ProgressDeadlineExceeded` is `Failed`, and
Helm stops waiting for it (`pkg/kube/statuswait.go`, `fluxcd/cli-utils` `kstatus/status/core.go`). Keycloak had no
`progressDeadlineSeconds` (600 s by default) while its startup probe alone allows 620 s, so Kubernetes could declare it
failed while its own probe still waited, before helm's 15 m.

## Decision
1. **On kind only**, probes tolerate a slow answer: Keycloak, core, game, athlete, pdf and finance get 5 s per probe
   answer, a liveness kill only after a minute of failures, and 5 minutes to start (`values-kind.yaml`, one YAML anchor
   for the services; the Keycloak sub-chart takes the optional `probeTimeoutSeconds`). On a busy VM a slow answer is
   load, not a dead process, and every kill throws away minutes of start-up work.
2. **Keycloak's Deployment on kind** gets `progressDeadlineSeconds: 900`, equal to up.sh's `helm --timeout 15m`.
   That timeout stays the outer bound: it is not raised, so a real failure still ends the install after 15 minutes.
3. **The CloudNativePG operator on kind** is patched by `deploy/kind/cnpg-patch.sh` (besides no leader election: 5 s
   probe timeouts, 5 minutes to start, a kill after a minute), and up.sh waits for the operator to be `Available` right
   before `helm upgrade`, whose apply needs its webhook.
4. Everything outside kind renders as before (the default, TLS and cloud renders keep Kubernetes' defaults for
   Keycloak; the ESO render is kind's and has the kind probes; the cloud VM installs the upstream CNPG manifest). `deploy/helm/tests/run.sh` and
   `scripts/tests/kind-cnpg-patch.test.sh` check all of this.

## Consequences
- What the change fixed is shown by run 3: Keycloak, the operator and the databases survived a load twice WP139's.
- It does not make a 2-CPU VM fit the release under any load: at a load of 50-60 the JVM services still miss 15
  minutes and the control plane restarts. The install converged about 5 minutes after the extra build ended, and
  `up.sh --deploy`, seed and smoke then passed on the same cluster. More vCPUs for the VM (owner's machine, stops the
  compose stack) or not building while installing are the remedies; neither is a chart setting.
- A hung process on kind is detected a minute later than before. The cloud keeps the tighter defaults.
