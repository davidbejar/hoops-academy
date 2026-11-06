# -*- mode: Python -*-
# Hoops Academy inner loop on kind (WP16). Prerequisite: `just kind-up` (cluster, Envoy Gateway, CNPG, namespace).
#   tilt up                       build images with Podman, load them into kind, deploy the umbrella chart
#   tilt up -- --services=game-service,athlete-service   only build/deploy a subset (others stay disabled)
#   tilt ci                       same, exits when everything is Ready (or fails)
#   tilt ci game-service athlete-service -- --services=game-service,athlete-service   subset + their dependencies
# Images: custom_build -> scripts/build-images.sh (podman build + `kind load image-archive`); no registry, no BuildKit.
# Secrets: rendered from .env by deploy/kind/secrets.sh into memory and applied as k8s objects; never written to disk.
#   tilt up -- --eso              on a cluster from `deploy/kind/up.sh --eso` (WP65): no secrets.sh, the chart's
#                                 ExternalSecrets (externalSecrets.enabled=true) and the External Secrets Operator make them

config.define_string_list('to-run', args=True, usage='resources to run (default: all); dependencies are included')
config.define_string_list('services', args=False, usage='services to build/deploy (default: all three)')
config.define_bool('from-host', args=False, usage='package with ./mvnw on the host and copy the fast-jar (faster)')
config.define_bool('skip-flutter', args=False, usage='reuse apps/web/build/web instead of running flutter build web')
config.define_bool('eso', args=False, usage='Secrets from the External Secrets Operator (cluster from `deploy/kind/up.sh --eso`)')
cfg = config.parse()
if cfg.get('to-run'):
    config.set_enabled_resources(cfg.get('to-run'))

ALL_SERVICES = ['core-service', 'game-service', 'athlete-service']
# Accept both `--services=a,b` and `--services a --services b`.
services = [x.strip() for item in cfg.get('services', ALL_SERVICES) for x in item.split(',') if x.strip()]
for svc in services:
    if svc not in ALL_SERVICES:
        fail('unknown service %s (expected one of %s)' % (svc, ALL_SERVICES))
from_host = cfg.get('from-host', False)
eso = cfg.get('eso', False)

allow_k8s_contexts('kind-hoops')
if k8s_context() != 'kind-hoops':
    warn('kubectl context is %s, expected kind-hoops (run `just kind-up`)' % k8s_context())
k8s_namespace('hoops')
update_settings(max_parallel_updates=1, k8s_upsert_timeout_secs=600)  # 2-CPU Podman machine: build one at a time
os.putenv('KIND_EXPERIMENTAL_PROVIDER', 'podman')

# ---------------------------------------------------------------------------------------------------- secrets
# Equivalent of secret_from_dict() for every key in .env: the YAML only lives in Tilt's memory; Tilt redacts the values
# in its logs/UI (secret_settings default). Missing .env => fail with a clear message.
# With --eso the Secrets come from ESO instead (the ExternalSecrets are part of the chart below).
if not eso:
    if not os.path.exists('.env'):
        fail('.env missing: cp .env.example .env and set values')
    watch_file('.env')
    secrets_yaml = local('deploy/kind/secrets.sh', quiet=True, echo_off=True)
    k8s_yaml(secrets_yaml)

# ---------------------------------------------------------------------------------------------------- images
SERVICE_DEPS = {
    'core-service':    ['services/core-service/src', 'services/core-service/pom.xml'],
    'game-service':    ['services/game-service/src', 'services/game-service/pom.xml'],
    'athlete-service': ['services/athlete-service/src', 'services/athlete-service/pom.xml'],
}
COMMON_DEPS = ['libs/common-quarkus/src', 'libs/common-quarkus/pom.xml', 'libs/contracts', 'pom.xml',
               'deploy/containers/service.Containerfile']

for svc in services:
    custom_build(
        'localhost/hoops/' + svc,
        'scripts/build-images.sh %s--kind-load --tag "$EXPECTED_REF" %s' % ('--from-host ' if from_host else '', svc),
        deps=SERVICE_DEPS[svc] + COMMON_DEPS,
        skips_local_docker=True,   # the image goes straight into kind; Tilt never pushes it
        disable_push=True,
    )

# Flutter: `flutter build web` on the host (native arm64, uses the local pub cache), then an nginx image.
local_resource(
    'flutter-build-web',
    cmd='cd apps/web && flutter pub get >/dev/null && flutter build web --release --pwa-strategy=offline-first',
    deps=['apps/web/lib', 'apps/web/web', 'apps/web/pubspec.yaml', 'apps/web/assets'],
    labels=['web'],
    auto_init=not cfg.get('skip-flutter', False),
)
custom_build(
    'localhost/hoops/web',
    'scripts/build-images.sh web --skip-web-build --kind-load --tag "$EXPECTED_REF"',
    deps=['apps/web/build/web', 'deploy/containers/web.Containerfile', 'deploy/containers/web-nginx.conf'],
    skips_local_docker=True,
    disable_push=True,
)

# ---------------------------------------------------------------------------------------------------- helm
# The chart carries copies of the realm and init SQL; refresh them from their sources before rendering.
local('scripts/sync-chart-files.sh', quiet=True)
helm_set = []
for svc in ALL_SERVICES:
    if svc not in services:
        helm_set.append('%s.enabled=false' % svc.replace('-service', ''))
if eso:
    helm_set.append('externalSecrets.enabled=true')
k8s_yaml(helm(
    'deploy/helm/hoops',
    name='hoops',
    namespace='hoops',
    values=['deploy/helm/hoops/values-kind.yaml'] + (['deploy/helm/hoops/values-local.yaml'] if os.path.exists('deploy/helm/hoops/values-local.yaml') else []),
    set=helm_set,
))
watch_file('deploy/helm/hoops')
watch_file('infra/keycloak/realm-academy.json')
watch_file('infra/db/init/01_roles_schemas.sql')

# ---------------------------------------------------------------------------------------------------- resources
# Ordering: secrets -> databases -> keycloak -> services | web (services and web do not wait on each other, so a
# broken service image never blocks the rest).
SECRET_NAMES = ['hoops-db-core-migrator', 'hoops-db-core-app', 'hoops-db-core-platform',
                'hoops-db-game-migrator', 'hoops-db-game-app', 'hoops-db-athlete-migrator', 'hoops-db-athlete-app',
                'keycloak-db-app', 'keycloak-admin', 'hoops-oidc-core-service', 'hoops-oidc-game-service',
                'hoops-oidc-athlete-service', 'hoops-ratelimit-redis',
                # event broker logins (WP66, ADR-0036)
                'hoops-redpanda-admin', 'hoops-redpanda-core-service', 'hoops-redpanda-game-service',
                'hoops-redpanda-athlete-service']
# --eso: the ExternalSecrets (same names; ESO creates the Secrets, which Tilt does not track); hoops-dev-users is only
# rendered by secrets.sh. envoy-ratelimit-redis-auth is the REDIS_AUTH of the rate limit pods (WP46).
SECRET_KIND = 'externalsecret' if eso else 'secret'
k8s_resource(
    new_name='secrets',
    objects=['%s:%s' % (n, SECRET_KIND) for n in SECRET_NAMES + ([] if eso else ['hoops-dev-users'])] +
        ['envoy-ratelimit-redis-auth:%s:envoy-gateway-system' % SECRET_KIND],
    labels=['infra'],
)
k8s_resource(
    new_name='databases',
    objects=['hoops-db:cluster', 'keycloak-db:cluster', 'databases:networkpolicy'],
    resource_deps=['secrets'],
    labels=['infra'],
    extra_pod_selectors=[{'cnpg.io/cluster': 'hoops-db'}, {'cnpg.io/cluster': 'keycloak-db'}],
    pod_readiness='wait',
)
# Edge (WP36): GatewayClass, Gateway, Envoy settings and client policies; the HTTPRoutes and rate-limit policies of
# each workload follow below (Tilt does not attach Gateway API objects to workloads by itself).
k8s_resource(
    new_name='gateway',
    objects=['envoy-gateway:gatewayclass', 'hoops:gateway', 'hoops:envoyproxy',
             'hoops-http:clienttrafficpolicy', 'hoops-https:clienttrafficpolicy'],
    labels=['infra'],
)
# Counter store of the global rate limits (WP40, ADR-0033); Envoy Gateway's envoy-ratelimit pods (outside this
# namespace, installed by `just kind-up`) are its only clients.
k8s_resource('ratelimit-redis', objects=['ratelimit-redis:networkpolicy'], resource_deps=['secrets'], labels=['infra'])
# Event broker (WP66, ADR-0036; events.enabled in values-kind.yaml). The bootstrap Job (a Helm post-install hook, a plain
# Job for Tilt) waits for the broker itself, then sets users, ACLs and topics. The services connect to it (WP71: core's
# publisher, the game/athlete replica consumers). core waits for the Job: its idempotent producer does not recover when its
# first producer-id request fails authentication (user not created yet); the consumers reconnect by themselves.
k8s_resource('redpanda', objects=['redpanda-config:configmap', 'redpanda:networkpolicy'],
             resource_deps=['secrets'], labels=['infra'])
k8s_resource('redpanda-bootstrap', objects=['redpanda-bootstrap:configmap'], resource_deps=['redpanda'], labels=['infra'])
k8s_resource('keycloak', objects=['keycloak-realm:configmap', 'keycloak:httproute', 'keycloak-ratelimited:httproute',
                                  'keycloak-ratelimited:backendtrafficpolicy', 'keycloak-admin-deny:httproute'],
             resource_deps=['databases'],
             port_forwards=['18080:8080'], labels=['infra'])  # direct Keycloak (no gateway) for debugging

# Host ports 1808x so they never clash with services started with `quarkus:dev` (8081-8083) or compose (8080).
PORTS = {'core-service': 8081, 'game-service': 8082, 'athlete-service': 8083}
ROUTES = {
    'core-service': ['core-service-api-core:httproute', 'core-service-platform:httproute'],
    'game-service': ['game-service-api-game:httproute', 'game-service-events-batch:httproute',
                     'game-service-events-batch:backendtrafficpolicy'],
    'athlete-service': ['athlete-service-api-athlete:httproute'],
}
for svc in services:
    k8s_resource(svc, objects=['%s-env:configmap' % svc, '%s-health:httproute' % svc] + ROUTES[svc],
                 resource_deps=['keycloak'] + (['redpanda-bootstrap'] if svc == 'core-service' else []),
                 port_forwards=['%d:%d' % (PORTS[svc] + 10000, PORTS[svc])], labels=['services'])

k8s_resource('web', objects=['web:httproute'], resource_deps=['flutter-build-web', 'keycloak'], labels=['web'])
