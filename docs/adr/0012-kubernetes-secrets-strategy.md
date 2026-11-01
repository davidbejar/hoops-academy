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
  checksum annotation, decided with the first non-local environment).

## Rejected alternatives
- **Sealed Secrets (Bitnami):** encrypted secrets in git. Ties ciphertext to one cluster's controller key (re-seal per
  cluster, key backup/rotation is on us), puts long-lived credential material in git history, and gives no central
  audit or rotation. ESO keeps the source of truth in the cloud secret manager.
- **Secrets templated by Helm from values (`--set` / values-local.yaml):** values end up in the Helm release Secret,
  shell history and CI logs; makes `helm template` output secret-bearing.
- **SOPS-encrypted values files:** same "ciphertext in git" trade-off as Sealed Secrets plus a KMS/age key
  distribution problem for every developer.

## Consequences
- Local setup stays one command (`just kind-up`) and uses the same `.env` as compose.
- The ESO resources are not built yet (no non-local environment exists); adding them is a values/manifest change, not
  a chart change. Until then, any non-kind cluster needs the Secrets created out of band with the shapes above.
- Kubernetes Secrets are only base64 in etcd: real clusters must enable encryption at rest and restrict `get secrets`
  RBAC to the namespace's workloads.
