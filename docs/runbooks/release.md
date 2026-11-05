# Runbook: release

Status: describes the process the repository's tooling supports. **No release has been cut yet**: the Maven version is
`0.1.0-SNAPSHOT`, the Helm chart `0.1.0`, no registry is configured, and the workflows in `.github/workflows` have not been
run from a CI runner (`docs/wp/WP16` and `WP17` handovers). Steps marked (design) are not implemented.

## 1. What is versioned
| Artifact | Version source | Rule |
|---|---|---|
| OpenAPI contracts | `info.version` in `libs/contracts/openapi/{core,game,athlete,common}.yaml` (now core 2.1.0, game 2.0.0, athlete 2.0.0, common 1.1.0) | SemVer; policy in `libs/contracts/README.md` |
| Maven modules and service jars | root `pom.xml` (`0.1.0-SNAPSHOT`) | one version for the repo |
| Container images | tag `dev` locally; `${{ github.sha }}` in `images.yml` | immutable, per commit |
| Helm chart | `deploy/helm/hoops/Chart.yaml` (`version`, `appVersion`) | bump with every chart change |
| Web app | built from the same commit as the services | released together |

### Contract versioning
- Minor: additive only (new operation, optional field, optional query parameter, new value of a request-only enum).
- Major: removal, rename, optional->required, type change, tightened constraint, status code change, **new value in a
  response enum**. Needs an ADR and a migration note (ADR-0016 is the template). No parallel `/v2` paths: services and web
  ship together.
- Patch: descriptions and examples.
- Steps for a contract change:
  1. Edit the YAML and bump `info.version`.
  2. `source scripts/env.sh && ./mvnw -pl libs/contracts verify` (conventions, JSON Schema consistency, strict validation).
  3. `just gen-api` and commit the regenerated `apps/web/packages/{core,game,athlete}`; adapt `apps/web`; `just web-test`.
  4. Adapt the service and make its tests validate responses against the new spec; `just test`.
The match-event JSON Schema is mirrored in `game.yaml`; `MatchEventSchemaConsistencyTest` fails on drift.

## 2. Pre-release checklist
```bash
source scripts/env.sh
just test                      # ./mvnw verify: unit, integration, ArchUnit, RLS suites, coverage gates
just web-test                  # flutter test
just scan                      # gitleaks (full history) + OWASP dependency-check (needs an NVD API key)
deploy/helm/tests/run.sh       # lint, snapshots, kubeconform, policy assertions, gitleaks on rendered output
just e2e                       # journey on compose (docs/runbooks/e2e.md)
```
Also: ADR for any decision taken, handover notes in `docs/wp`, `docs/roadmap.md` updated.
Realm or init-SQL changes: run `scripts/sync-chart-files.sh` (copies into the charts; the chart test fails on drift) and
refresh snapshots with `deploy/helm/tests/run.sh --update` after reviewing the diff.

## 3. Build and publish images
Locally: `scripts/build-images.sh [--from-host] [--kind-load] [--push] [core-service|game-service|athlete-service|web]`.
Web: build with `apps/web/tool/build_web.sh` (stamps the service worker); a plain `flutter build web` leaves `sw.js`
unstamped. In CI `images.yml` runs on pushes to `main` that touch services, libs, web, containers or the pom:
build per service, assert non-root, Trivy gate (`HIGH,CRITICAL --ignore-unfixed`, fails the job), and push only from
`main` and only when the repository variable `IMAGE_REGISTRY` is set. Use a repo-scoped prefix so package names never
collide with another repository's: `gh variable set IMAGE_REGISTRY --body ghcr.io/<owner>/hoops-academy` (refs become
`ghcr.io/<owner>/hoops-academy/core-service:<sha>`). For ghcr.io under the repository's own owner no credential is needed:
the push jobs request `packages: write` and log in with the run's `GITHUB_TOKEN`. For any other registry (or another
owner) set BOTH secrets `REGISTRY_USERNAME`/`REGISTRY_PASSWORD`; setting only one fails the step. Images carry the
`org.opencontainers.image.source` label (build arg `SOURCE_URL`, derived from the `origin` remote by
`scripts/build-images.sh`) so ghcr.io links each package to this repository.

The first push creates each ghcr.io package **private**. The four Hoops Academy packages are **public** (verified
2026-11-05: an anonymous pull works), so a cluster needs no secret. For a private fork, either make the packages public
(package settings on github.com, fine for a public repo) or give the cluster a pull secret and reference it from the chart:
```bash
kubectl -n hoops create secret docker-registry ghcr-pull --docker-server=ghcr.io \
  --docker-username=<owner> --docker-password=<PAT with read:packages>
helm upgrade --install hoops deploy/helm/hoops -n hoops --set 'global.imagePullSecrets[0].name=ghcr-pull' ...
```
Pin the `ubi9/openjdk-21-runtime` tag in `deploy/containers/service.Containerfile` before the first release (open item).

## 4. Deploy with Helm
Umbrella chart `deploy/helm/hoops`; values `values.yaml` (defaults), `values-kind.yaml`, git-ignored `values-local.yaml`.
Image per service: `core|game|athlete.image.repository` and `.tag`.
```bash
# kind (verified in WP16): cluster + Secrets + build + helm upgrade --install --wait
just kind-up --deploy --from-host
# any cluster (design): Secrets created first (ADR-0012), then
helm upgrade --install hoops deploy/helm/hoops -n hoops -f values.prod.yaml \
  --set core.image.tag=<sha> --set game.image.tag=<sha> --set athlete.image.tag=<sha> --set web.image.tag=<sha>
```
Order that matters: Secrets -> CNPG clusters -> Keycloak -> services (Flyway runs on start as `*_migrator`) -> web.
Services restart a few times on first install until `hoops-db-rw` is ready; they converge by themselves (WP18).
Database migrations are forward-only; roll back by deploying a compatible previous image or restoring (`backup-restore.md`).
Run `deploy/kind/smoke.sh core game athlete` (or the equivalent checks) after every deploy.

## 5. Tag and record
(design) Tag the commit `vX.Y.Z` after the images for that SHA exist and the smoke test passes; record the contract
versions and the image SHAs in the release notes. Move resolved items in `docs/wp/FOLLOW-UPS.md` to "Resolved".
