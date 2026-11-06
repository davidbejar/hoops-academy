# ADR-0012: Kubernetes secrets — Secrets from .env locally, External Secrets Operator beyond local

- Status: Accepted
- Date: 2026-11-02

## Context
WP16 packages the platform for Kubernetes (kind locally, a managed cluster later). The workloads need 14 secret
values: seven PostgreSQL role passwords (managed by CloudNativePG), the Keycloak DB and admin credentials, three
confidential OIDC client secrets (substituted into the realm import and read by the services) and the dev users'
password. CLAUDE.md rule 6: no secret literal in git. The Helm charts must therefore never contain or template a
secret value, and the rendered output must pass `gitleaks`.

## Decision
- **Charts reference, never create, Secrets.** Every chart value is a Secret *name* (`existingSecret`,
  `secretEnv[].secretName`, CNPG `passwordSecret`, `bootstrap.initdb.secret`). `helm template` renders no `Secret`
  object (asserted by `deploy/helm/tests/run.sh`, which also pipes the output through gitleaks).
- **Secret shape is fixed** so any provider can fill it: CNPG roles use `kubernetes.io/basic-auth` with
  `username` = role name; client secrets use key `client-secret`; `keycloak-admin` has `username`/`password`.
  Names: `hoops-db-<role>` (e.g. `hoops-db-core-app`), `keycloak-db-app`, `keycloak-admin`,
  `hoops-oidc-<service>`, `hoops-dev-users`.
- **Local (kind):** `deploy/kind/secrets.sh` renders the Secrets from the git-ignored `.env`
  (`kubectl create secret … --dry-run=client -o yaml`, values fed via process substitution, never on a command line,
  never written to disk). `deploy/kind/up.sh` pipes it into `kubectl apply`; the `Tiltfile` loads the same output into
  memory (`local()` → `k8s_yaml`), which Tilt redacts in its UI. A missing `.env` or key fails fast.
- **Beyond local:** External Secrets Operator (ESO) with a `ClusterSecretStore` for the platform's secret manager
  (AWS Secrets Manager / GCP Secret Manager / Azure Key Vault / Vault). One `ExternalSecret` per Secret above,
  producing exactly the same names/keys/types, so the charts do not change. Rotation: ESO `refreshInterval`; CNPG
  re-applies role passwords when the Secret changes; services pick up rotated values on rollout (Reloader or a
  checksum annotation, decided with the first non-local environment; Reloader since WP87, amendment below).

## Amendment 2026-11-06 (decision 47, WP65): the chart sources its Secrets from ESO behind a switch
- **Switch:** `externalSecrets.enabled` (default `false`). Off, nothing changes: the Secrets exist before the install
  (`deploy/kind/secrets.sh` on kind and for small installs, kept). On, the umbrella chart renders one
  `external-secrets.io/v1` `ExternalSecret` per Secret the workloads read (12 in `hoops` plus the rate limit Redis
  login, see below), each with `target.name` = the Secret name, the same `type` and the same keys, so no workload,
  CNPG `Cluster` or Envoy Gateway setting changes (asserted by `deploy/helm/tests/run.sh`: the `umbrella-eso` render
  differs from `umbrella-kind` only by the `ExternalSecret`s, and every Secret key a workload reads has one).
  The first rule above still holds in spirit: the chart renders no `Secret` and no value, only store, remote key and
  property names; ESO writes the Secrets.
- **Store:** the `ClusterSecretStore` / `SecretStore` (`externalSecrets.storeRef`, default `ClusterSecretStore/hoops`)
  belongs to the cluster, not to the chart: it holds the provider credentials. Restrict it to the namespaces that need it
  (`spec.conditions`); kind's store admits `hoops` and `envoy-gateway-system` only.
- **Remote layout:** one remote secret (`externalSecrets.remoteKey`, default `hoops`) with one property per value,
  named like the `.env` keys (`CORE_APP_PASSWORD`, …), so `.env`, the store and the chart use one vocabulary. An entry
  may override `remoteKey`, or give a full `remoteRef` for one-value-per-secret stores.
- **Shapes kept:** CNPG roles and `keycloak-db-app` are `kubernetes.io/basic-auth` whose `username` (the role name) is a
  fixed template literal next to the fetched `password` (`mergePolicy: Merge`). `creationPolicy: Owner` (the Secret
  goes with its `ExternalSecret`), `deletionPolicy: Retain` (a value deleted at the source keeps the last Secret).
- **Rate limit Redis login:** derived from `rateLimit.redis` (`externalSecrets.rateLimitRedis`): one source property
  `RATELIMIT_REDIS_PASSWORD` feeds `hoops-ratelimit-redis` (in-chart Redis only) and, in
  `rateLimit.redis.clientNamespace`, `envoy-ratelimit-redis-auth` with `auth` = `<acl.user>:<password>` (an ESO template).
  It is the chart's only object outside the release namespace: Envoy Gateway's rate limit pods read Secrets of their
  own namespace only.
- **Not sourced:** `hoops-dev-users` (no workload reads it; `seed-users.sh` and `smoke.sh` use `.env`) and the Gateway's
  TLS certificate (`gateway.tls.certificateRefs`; cert-manager, or an extra `kubernetes.io/tls` entry).
- **Rotation:** `refreshInterval` (default 1h, kind 1m) is how soon a changed source reaches the Secret. Nothing rolls
  the pods yet (still open from above; Reloader is the candidate once a real environment exists): CNPG re-applies role
  passwords by itself, the services, Keycloak and Redis need a restart (`docs/runbooks/rotate-secrets.md` section E).
  Superseded by the WP87 amendment below: Reloader rolls them.
- **Kind proof:** `deploy/kind/up.sh --eso` installs ESO (pinned `ESO_VERSION`, v2.14.0) and a `ClusterSecretStore`
  with the Kubernetes provider reading one bootstrap Secret in namespace `hoops-secret-store`, built from `.env` by
  `deploy/kind/eso-store.sh` (get-only reader ServiceAccount); the chart is installed with
  `externalSecrets.enabled=true` and `secrets.sh` never runs. The fake provider was not used: it would put every value
  into the store object itself. `kubeconform` validates the `ExternalSecret`s against a JSON schema generated from the
  pinned version's CRD (`deploy/helm/tests/schemas`, `update-eso.sh`), and the chart tests fail when the two pins differ.
- **Trust:** ESO's controller can read and write Secrets in every namespace (its chart's default RBAC); whoever can
  create an `ExternalSecret` in an admitted namespace can read every property of the store. Keep the store's
  `conditions` tight and `create externalsecrets` RBAC as narrow as `get secrets`.

## Amendment 2026-11-07 (decision 63, WP87): Stakater Reloader rolls the pods that read a rotated Secret
- **Switch:** `global.reloader.enabled` (default `false`, on in `values-kind.yaml`). Global rather than the briefed
  `reloader.enabled`: the service and Keycloak subcharts see only their own values and `global`, and a new key needs no
  mirror (unlike `events.enabled`, WP71). On, every Deployment/StatefulSet that reads a Secret (env `secretKeyRef`,
  `envFrom` `secretRef`, a secret volume) carries `secret.reloader.stakater.com/auto: "true"` on its own metadata: core,
  game, athlete, keycloak, ratelimit-redis, redpanda. The chart tests derive that list from the render (a new workload or
  Secret reference is covered without editing the test) and assert none when off. The `secret.` form reacts to Secrets
  only: ConfigMap changes already roll the pods through the chart's checksum annotations. The `redpanda-bootstrap` Job is
  not annotated: `helm upgrade` runs it again.
- **Controller:** Stakater Reloader, installed by `deploy/kind/up.sh` like ESO: chart 2.2.19 (v1.4.23) pinned by chart
  digest and image digest, namespace `hoops-reloader`, `watchGlobally=false` with `namespaces` = `hoops` and
  `envoy-gateway-system` (namespaced Roles, no ClusterRole), `ignoreConfigMaps`, `ignoreJobs`, `ignoreCronJobs`, reload
  strategy `annotations` (a pod-template annotation, no injected env var), read-only root FS, no capabilities. Envoy
  Gateway's `envoy-ratelimit`, not a chart object, gets the annotation through its `rateLimitDeployment.patch`. Other
  clusters install it the same way (`release.md`); without a controller the annotation is inert and the manual restarts
  of `rotate-secrets.md` section E apply.
- **Why not a checksum annotation:** the chart never sees a Secret value (first rule above); hashing would need `lookup`,
  which makes `helm template` non-deterministic, gives the deployer `get secrets` and still misses an ESO refresh between
  two upgrades.
- **Still manual:** where the other side of a credential changes elsewhere, Reloader only removes the restart step. CNPG
  applies a role password on its own reconcile, so the new pod may start before it and retries until then; the broker
  takes a service user's new password when the bootstrap Job runs (`helm upgrade`); Keycloak client secrets, the Keycloak
  admin, `KC_DB_PASSWORD` and the broker superuser must change at their server first (`rotate-secrets.md` section E).
- **Trust:** Reloader's ServiceAccount can list and watch every Secret and patch Deployments/StatefulSets in the watched
  namespaces (its chart's Role also allows Jobs from CronJobs; unused with `ignoreCronJobs`). `trivy config` of the
  rendered controller reports no HIGH/CRITICAL; the MEDIUM ones (KSV-0048/0049/0113, KSV-0125 for ghcr.io) are this
  function. It reads Secrets to hash them and logs only names.

- **Sealed Secrets (Bitnami):** encrypted secrets in git. Ties ciphertext to one cluster's controller key (re-seal per
  cluster, key backup/rotation is on us), puts long-lived credential material in git history, and gives no central
  audit or rotation. ESO keeps the source of truth in the cloud secret manager.
- **Secrets templated by Helm from values (`--set` / values-local.yaml):** values end up in the Helm release Secret,
  shell history and CI logs; makes `helm template` output secret-bearing.
- **SOPS-encrypted values files:** same "ciphertext in git" trade-off as Sealed Secrets plus a KMS/age key
  distribution problem for every developer.

## Consequences
- Local setup stays one command (`just kind-up`) and uses the same `.env` as compose.
- The ESO resources exist since WP65 (amendment above, `externalSecrets.enabled`); without them, any non-kind cluster
  needs the Secrets created out of band with the shapes above.
- Kubernetes Secrets are only base64 in etcd: real clusters must enable encryption at rest and restrict `get secrets`
  RBAC to the namespace's workloads.
