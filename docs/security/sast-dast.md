# SAST and DAST: tools, gates, local runs, triage

Static (SAST) and dynamic (DAST) security testing of Hoops Academy (WP83, decision 55, [ADR-0045](../adr/0045-sast-dast-gates-and-expiring-acceptances.md)).
Findings are triaged into [`review-2026-11.md`](review-2026-11.md) ("Round 5 SAST/DAST findings"); fixes are WP84's.

## Tools and gates

| Tool | Where | Scope | Fails on | Accepted findings |
|---|---|---|---|---|
| SpotBugs 4.10.5 + find-sec-bugs 1.14.0 | `verify` of every module (root `pom.xml`), so `just test` and the `backend` job | main classes, effort Max, threshold Medium, all categories | any finding not excluded | `spotbugs-exclude.xml` (a comment per `<Match>`) |
| CodeQL 2.27 (codeql-action v4.39.3) | `.github/workflows/codeql.yml`: push to main, PRs, weekly | Java main code, suite `security-extended` | `security-severity` >= 7.0 (High, Critical) | `.github/codeql/accepted.json` |
| Semgrep 1.183.0 (image pinned by digest) | `.github/workflows/semgrep.yml`: push to main, PRs, weekly | whole repo minus `.semgrepignore` (tests, generated clients, build output, Helm templates); `p/java`, `p/owasp-top-ten`, `.semgrep/rules` | level `error` (rule severity ERROR) | `.semgrep/accepted.json` |
| ZAP baseline (passive) | `ci.yml` job `zap-baseline` | nginx + Keycloak + core on compose | High/Medium alert | `.zap/baseline.conf` |
| ZAP API scan (active) | `e2e.yml` after the journeys | each service's OpenAPI contract through nginx, signed in as the super admin | High/Medium alert | `.zap/api-<service>.conf` |
| ZAP full scan (spider + active) | by hand (below) | nginx, Keycloak pages, the web app | — (triaged into the review) | — |

Both SARIF reports (CodeQL, Semgrep) are uploaded to GitHub code scanning (Security tab). The gates read only the
accepted files, so they behave the same locally and in CI.

### Repository Semgrep rules (`.semgrep/rules`, tests in `.semgrep/tests`)
| Rule | Severity | What it stops |
|---|---|---|
| `hoops-permitall-on-api-resource` | ERROR | `@PermitAll` on a class or method under `@Path("/api…")`, `/platform…`, `/internal…` |
| `hoops-no-tenant-check-bypass` | ERROR | fields, methods or calls named `skipTenantCheck`, `bypassTenantFilter`, `disableTenantIsolation`, … |
| `hoops-no-rls-bypass-sql` | ERROR | SQL in Java that sets `row_security = off`, `SET ROLE`, `SESSION AUTHORIZATION` or mentions `BYPASSRLS` |
| `hoops-tenant-switch-outside-tenancy` | ERROR | `set_config(…)` outside `libs/common-quarkus/…/tenancy` (rebinding the tenant by hand needs a reviewed acceptance) |
| `hoops-sql-concat-from-parameter` | ERROR | taint: a `String` method parameter reaching the text of `createQuery`, `createNativeQuery`, `prepareStatement`, `execute*`, `addBatch` |
| `hoops-dart-window-open-without-noopener` | ERROR | `window.open(url, '_blank')` without `noopener` |
| `hoops-dart-secret-in-preferences` | ERROR | tokens, passwords or secrets written to `SharedPreferences` (localStorage) |
| `hoops-dart-unsafe-html` | ERROR | `innerHTML` / `setInnerHtml` / `document.write` |
| `hoops-dart-print-secret` | ERROR | tokens, passwords or secrets in `print`, `debugPrint`, `log` or a logger call |
| `hoops-dart-tls-bypass` | ERROR | `badCertificateCallback` returning `true` |

The Semgrep registry has no Dart/Flutter security ruleset (only an AI-SDK detector), so the Dart rules are ours.

## Running each tool locally (Podman, no Node)
Always `source scripts/env.sh` first. Reports go to the scratch paths shown; nothing here writes into the repo
except `target/` (git-ignored).

**SpotBugs** (part of `just test`; alone, on compiled classes, about 25 s):
```
./mvnw -B -ntp -T 1C -DskipTests -Djacoco.skip=true compile com.github.spotbugs:spotbugs-maven-plugin:check
# reports: <module>/target/spotbugsXml.xml and spotbugsSarif.json; -Dspotbugs.skip=true for a quick inner loop only
```

**Semgrep** (about 30 s once the image is pulled):
```
img=docker.io/semgrep/semgrep:1.183.0@sha256:2e45517a85e13a9cca14a2a00df6bb48affd66b8ebfae1b0991cd57578362fb0
python3 -m unittest discover -s scripts/tests                                  # gate scripts
podman run --rm -v "$PWD:/src:ro" -w /src/.semgrep "$img" semgrep --test --metrics off --config rules tests
mkdir -p target/semgrep && chmod 777 target/semgrep
podman run --rm -v "$PWD:/src:ro" -v "$PWD/target/semgrep:/out" -w /src "$img" semgrep scan --metrics off \
  --config p/java --config p/owasp-top-ten --config .semgrep/rules --sarif-output=/out/semgrep.sarif .
python3 -I scripts/sarif-gate.py --fail-on error --baseline .semgrep/accepted.json target/semgrep/semgrep.sarif
```

**CodeQL** (the same bundle as the action, in a JDK container; about 30 min on a laptop, needs about 6.5 GB of the Podman VM):
```
# once: the bundle named in codeql-action's src/defaults.json (v4.39.3 -> codeql-bundle-v2.27.4), checksum verified
gh release download codeql-bundle-v2.27.4 -R github/codeql-action -p 'codeql-bundle-linux-arm64.tar.gz*' -D /tmp/cq
(cd /tmp/cq && shasum -a 256 -c codeql-bundle-linux-arm64.tar.gz.checksum.txt && tar -xzf codeql-bundle-linux-arm64.tar.gz)
# a copy of the tree, so the traced build does not touch your target/ directories
rsync -a --exclude target --exclude .git --exclude .dart_tool ./ /tmp/cq-src/
podman run --rm -m 6500m -v /tmp/cq/codeql:/codeql:ro -v /tmp/cq-src:/src -v "$HOME/.m2:/root/.m2" -w /src \
  docker.io/library/maven:3-eclipse-temurin-25 bash -c '
  mkdir -p /src/target &&
  /codeql/codeql database create /src/target/cq-db --language=java --ram 4500 --threads 1 \
    --command "./mvnw -B -ntp -Dmaven.test.skip=true -Djacoco.skip=true -Dspotbugs.skip=true compile" &&
  /codeql/codeql database analyze /src/target/cq-db codeql/java-queries:codeql-suites/java-security-extended.qls \
    --format sarif-latest --output /src/target/java.sarif --ram 4500 --threads 1'
python3 -I scripts/sarif-gate.py --fail-on high --baseline .github/codeql/accepted.json --root /tmp/cq-src /tmp/cq-src/target/java.sarif
```
(Intel Linux / CI: the `linux64` bundle.)

**ZAP API scan** (needs the compose stack, seeded users and the three services: `just e2e` leaves them up, or
`just up && just seed-users && just services-up`). It writes junk data (tenants, admins) into that stack:
```
scripts/zap-api-scan.sh core      # then game, athlete; reports in target/zap/api-<service>/
```
On macOS `--network host` is the Podman VM's network, where `localhost:8080` is nginx's published port, so the same
command works. `ZAP_MAX_SCAN_MINUTES` caps the active scan (default 15).

**ZAP baseline**: as in `ci.yml` (`zap-baseline.py -t http://localhost:8080/ -c baseline.conf`, then
`scripts/zap-gate.py`).

## ZAP full scan (by hand)
Against kind (gateway on `:8090`) or, when kind is busy, compose through nginx (`:8080`):
```
mkdir -p target/zap/full && chmod 777 target/zap/full
podman run --rm --network host -v "$PWD/target/zap/full:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:stable@sha256:030d3df57735dacbb83464854758e674dd9ad01d79d12a129a8e58b1fd384238 \
  zap-full-scan.py -t http://localhost:8080/ -J zap-full.json -r zap-full.html -I -m 5 \
  -z "-config scanner.maxScanDurationInMins=30"
python3 -I scripts/zap-gate.py target/zap/full/zap-full.json .zap/baseline.conf   # triage aid, not a gate
```
The spider cannot render the Flutter app (canvas), so the scan reaches the static shell, `redirect.html`, the service
worker, Keycloak's login, account and OIDC endpoints and whatever links they expose; the APIs are the API scan's job.

## Triage
1. Read the finding in the tool's report (SARIF in the Security tab or the workflow artifact, ZAP HTML).
2. Decide: **true positive** (fix it; if the fix cannot land in this PR, accept with an expiry no later than the date
   it is due and add it to the review with its owner WP), **false positive** (accept with the reason it cannot happen
   here, scoped as narrowly as the tool allows) or **not applicable** (same, with the reason).
3. Record it next to the gate:
   - SARIF: `scripts/sarif-gate.py … --suggest` prints the entry (rule, path, line, fingerprint); add `reason` and
     `expires` (at most six months) to `.github/codeql/accepted.json` or `.semgrep/accepted.json`.
   - ZAP: an IGNORE line in the scan's `.conf` with `[alert=…]`, `[url=…]` and, for a pending fix, `[expires=…]`.
   - SpotBugs: a `<Match>` on the class and bug pattern in `spotbugs-exclude.xml`, with a comment.
4. In the Security tab, dismiss the alert with the matching reason ("false positive", "won't fix", "used in tests")
   and the same text, so tab and file agree. Dismissal alone does not open the gate.
5. The gates print STALE (an acceptance that matches nothing: delete it) and EXPIRED (fix or renew with a new reason).

## First runs (WP83, 2026-11-06)
Local runs as the workflows do them (Podman on macOS arm64). Findings, triage and WP84's order are in
[`review-2026-11.md`](review-2026-11.md#round-5-sastdast-findings-wp83-2026-11-06) (SD-01 … SD-08).

| Tool | Run | Result | Gate |
|---|---|---|---|
| SpotBugs + find-sec-bugs | `verify`, 4 modules with main code | 388 → 0 after `spotbugs-exclude.xml` (no true positive); a planted concatenated JDBC query fails the build | green |
| CodeQL 2.27.4 | 657 main-code Java files, `security-extended`; create 20 min, analyze 6.5 min (`--ram 4500 --threads 1`; 3000 ran out of heap) | 7 High: 5 × SD-01, 2 false positives | green with `.github/codeql/accepted.json` |
| Semgrep 1.183.0 | 327 rules, 1254 files, 24 s (+ `semgrep --test`: 10/10 rule tests) | 26: 20 ERROR accepted, 6 WARNING/MEDIUM (SD-04, SD-06, SD-07) | green with `.semgrep/accepted.json` |
| ZAP API scan core | 587 s, 135 URLs | Low 3 (SD-02: `q=%00` → 500; SD-08), Info 2 | green |
| ZAP API scan game | 278 s | High 1 (rate-limit false positive, accepted), Low 2, Info 2 | green with `.zap/api-game.conf` |
| ZAP API scan athlete | 343 s | Low 2, Info 2 | green |
| ZAP full scan | compose through nginx (kind was busy), 710 s, 64 URLs | High 1 (SD-03), Medium 6, Low 6, Info 8 | not a gate |

ZAP full scan alerts (compose, `HOOPS_EXPOSE_KC_ADMIN=true` locally):
- High 40040 CORS Misconfiguration (5): Keycloak realm, discovery, JWKS, userinfo, device reflect any origin with
  credentials → SD-03.
- Medium 10055 CSP: `style-src 'unsafe-inline'` (app shell and Keycloak), `script-src 'unsafe-inline'` and "no
  fallback" on Keycloak pages → accepted in `.zap/baseline.conf` (ADR-0038); the same alerts on
  `/auth/admin/master/console/` appear only because the local `.env` exposes the admin console (default: 403).
- Medium 10020 anti-clickjacking and 10202 anti-CSRF on Keycloak's session iframe, device and logout forms → accepted
  in `.zap/baseline.conf`.
- Low 10063 Permissions-Policy and 90004 COEP/COOP/CORP on Keycloak pages → SD-08; Low 10054 / 90027 cookie
  attributes on Keycloak's logout (Keycloak's own session cookies, `SameSite=None` by design for the OIDC iframe).
- Informational: suspicious comments in Keycloak's JS, cacheability, session management, user-agent fuzzer.

Things learned on the way: keep the Mac awake for the scans (a host sleep froze the Podman VM mid-scan and the token
expired; `.zap/hooks/bearer_refresh.py` now refreshes right after ZAP starts); the `events:batch` rate limit makes
ZAP's boolean SQL-injection rule fire (429 against 400), hence the scoped acceptance; CodeQL needs about 4.5 GB.

## Re-run after the fixes (WP84, 2026-11-07)
WP84 fixed SD-01, SD-02, SD-04 … SD-08 and accepted SD-03 (`.zap/baseline.conf`, 40040, until 2027-05-07); the
statuses and every tool's re-run result are in
[`review-2026-11.md`](review-2026-11.md#re-run-after-the-fixes-wp84-2026-11-07). All gates green locally. Notes for
the next local run:
- To scan the edge as CI sees it while the local `.env` exposes the Keycloak admin console, recreate only nginx with
  the default: `HOOPS_EXPOSE_KC_ADMIN=false podman compose --env-file .env -f infra/compose/compose.yaml up -d nginx`
  (and again without the override afterwards; `just e2e` needs `true`).
- The Podman VM's resolver failed intermittently for `semgrep.dev` (registry rulesets are fetched at run time):
  `podman run --dns 1.1.1.1 …` made the Semgrep scan reliable; it does not change what is scanned.
- New request-text rules (SD-02) answer `400` with code `INVALID_CHARACTERS`; a ZAP "Server Error" alert on a NUL or
  control-character payload is a regression.
