# ADR-0052: pdf-service in Rust: axum, krilla, a pinned toolchain through `just`, layering as crates, the same gates

- Status: Accepted
- Date: 2026-11-16
- Records: decisions 89 and 90 of 2026-11-15 (WP111 brief), the stack items ADR-0051 §5 left to the brief
- Amends: ADR-0051 §3 and §5 (no gateway route; callers are core and game), see the amendment there
- Related: ADR-0034 (token audience per service), ADR-0043 (security events, SBOM), ADR-0045 (SAST gates), ADR-0046
  (traces and logs over OTLP), ADR-0048 (exports: labels, file names, dates), ADR-0054 (distroless images),
  `libs/contracts/openapi/pdf.yaml`, `.claude/skills/rust-service/SKILL.md`

## Context
ADR-0051 decided a stateless PDF renderer in Rust and left the frameworks, the PDF engine, the toolchain pins and the
counterparts of the Java gates (ArchUnit, JaCoCo, SpotBugs / PMD, dependency-check) to the work package. Decision 89
(owner, 2026-11-15): the service that owns the data calls `pdf-service` and returns the PDF; the browser never calls it.
Decision 90: the first two sheets are the match sheet / box score and the team roster, in es / en / id.

## Decision
### Service
- **Cargo workspace** `services/pdf-service`, outside the Maven reactor, three crates = three layers:
  `pdf-domain` (sheets, limits, labels, file names, the print document; depends on `chrono`, `chrono-tz`,
  `unicode-normalization` only), `pdf-application` (use cases `PrintSheets`, ports `PdfRenderer` and `Clock`; depends on
  the domain only), `pdf-adapters` (everything else and the binary). A crate can only use what its manifest lists, so a
  wrong import does not compile; `tests/layering.rs` pins the manifests (the counterpart of ArchUnit).
- **HTTP**: axum 0.8 on tokio (HTTP/1 only). `POST /internal/pdf/match-sheet`, `POST /internal/pdf/team-roster`
  (contract `pdf.yaml` 1.0.0), `/q/health/{live,ready,started}` and `/q/metrics` like the Quarkus services. JSON only
  (415), 256 KiB at most (413), strict bodies (`deny_unknown_fields` = the contract's `additionalProperties: false`),
  rows over a list's `maxItems` 422 `TOO_MANY_ROWS`, every other contract violation 400 `VALIDATION_FAILED`. Problem+JSON
  with `type urn:hoops:problem:<slug>`, `code`, `violations` that name the field and a code, never a value (privacy
  finding P-11); no stack trace. Renders run on the blocking pool, as many at once as the pod has CPUs.
- **PDF engine**: krilla 0.8 (pure Rust, by the authors of typst's PDF export): fonts embedded as subsets with
  ToUnicode maps (the text can be read back, which the tests do), no creation date or random id unless set, so a fixed
  input and clock give the same bytes. **Fixed templates only**: the domain builds a print document (headline, facts,
  tables, notes) and the renderer only draws it on A4 landscape, tables flowing over pages with their header repeated,
  cells cut with "…", "Page n of m". No markup, font, image or URL comes from a caller; the renderer fetches nothing.
  Fonts: Roboto Regular and Bold (Apache-2.0), compiled into the binary (`THIRD_PARTY.md`).
- **Authentication** (ADR-0034): `jsonwebtoken` 12 (pure-Rust crypto backend), RS256 only; keys from the realm's JWKS
  (`<OIDC_AUTH_SERVER_URL>/protocol/openid-connect/certs`, read on first use and again for an unknown key id at most every
  30 s), issuer from the realm's discovery document unless `OIDC_ISSUER` is set; audience `pdf-service`, `sub` required,
  realm role `service` required (403 otherwise). The realm unreachable: 503 `AUTH_UNAVAILABLE`. These reads of Keycloak
  are the service's only outbound calls besides OTLP (`reqwest` without TLS: both are in-cluster HTTP).
- **Security events** (ADR-0043): one WARN record of target `hoops.security` per refusal with the same fields and message
  as `common-quarkus` (`kind` = `unauthenticated` | `invalid_token` | `realm_role`, `tenantId` empty), and
  `hoops_authz_denied_total{kind}` with every kind at 0 from the start.
- **Telemetry** (ADR-0046): JSON lines on stdout (`tracing`), and with `OTEL_SDK_DISABLED=false` spans and log records
  over OTLP **HTTP/protobuf** (port 4318; the collector already listens there) with parent-based ratio sampling and W3C
  `traceparent` from the caller. A request span carries method, route template and status only; nothing of a body is
  logged or put on a span (`tests/logs.rs`).

### Toolchain and gates (the counterparts of the Java gates)
- **Pins**: `rust-toolchain.toml` 1.99.1 (rustfmt, clippy, llvm-tools-preview), `Cargo.lock` committed, crates at exact
  minor versions. Installed by `scripts/bootstrap.sh` (Homebrew `rustup`, keg-only, plus `cargo-llvm-cov` and
  `cargo-deny`), checked by `just doctor`. No Node.
- **`just test`** = Maven `verify`, then `just test-rust` (`services/pdf-service/scripts/check.sh`): `cargo fmt --check`;
  Clippy with `all` + `pedantic`, `unwrap_used` denied and warnings denied (the counterpart of SpotBugs / PMD);
  the tests under `cargo-llvm-cov`; the coverage gate (≥ 80 % lines in the workspace, ≥ 90 % in `pdf-domain`, `main.rs`
  outside the measure); `cargo deny check` (RustSec advisories, licence allow-list, no git or unknown sources).
- **Contract tests in Rust**: `pdf.yaml` and the `Problem` of `common.yaml` are turned into JSON Schemas (OpenAPI's
  `nullable` rewritten) and validated with `jsonschema`, formats included: the fixtures follow the contract, every answer
  is a declared status and media type with a valid `Problem` or the declared headers, and the service refuses exactly
  the bodies the contract refuses. The Java side reads the same file from the contracts jar (`classpath:openapi/pdf.yaml`).
- **CI**: job `rust` in `ci.yml` (same script); CodeQL analyses Rust (`build-mode: none`) next to Java; Semgrep adds the
  `p/rust` ruleset; Dependabot `cargo` weekly with the 7-day cooldown. Not covered: the repository's own Semgrep rules are
  Java and Dart only (no Rust rule written); OWASP dependency-check has no Rust analyser (cargo deny and Trivy cover it);
  no mutation testing for Rust yet (`cargo-mutants` would be the candidate).

### Delivery
- **Image** `deploy/containers/pdf.Containerfile`: build on `rust:1.99.1-slim-trixie` with `cargo auditable` (the crate
  list is embedded, so Trivy scans the crates and lists them in the SBOM), runtime `distroless/cc-debian13:nonroot`, both
  pinned by index digest; user 65532, read-only root file system, ~49 MB. Context `services/pdf-service`
  (its `.containerignore` leaves `target/` out). `images.yml` job `pdf`: build, non-root read-only start, Trivy gate,
  SBOM, push. The weekly `bump-pins` does not move these pins yet: they are bumped by hand with the toolchain.
- **Compose**: service `pdf-service` on 127.0.0.1:8084 behind the profile `pdf` (`just pdf-up`), so `just up` neither
  builds nor starts it. core and game on the host read `PDF_SERVICE_URL=http://localhost:8084` (`.env`).
- **Chart 0.11.0**: sub-chart `pdf-service` (alias `pdf`, off by default, on in `values-kind.yaml` and `values-cloud.yaml`):
  no HTTPRoute; a NetworkPolicy that admits `core-service` and `game-service` only and lets the pod reach DNS, Keycloak's
  port and the collector's OTLP/HTTP port only. `PDF_SERVICE_URL=http://pdf-service:8084` in core's and game's
  environment whether or not the sub-chart is on. Tilt resource `pdf-service` (`--no-pdf` leaves it out).
- **Realm**: bearer-only client `pdf-service` (an audience; no flow, no service account). The audience mappers
  `pdf-service` on the clients `core-service` and `game-service` belong with it but are not in the realm file yet: adding
  them changes the expected audiences of `RealmTokenPolicyTest` (core's Java tests), which this work package was not to
  touch; WP116 adds both in its first red/green step (WP111 handover).

## Alternatives rejected
- **typst as the engine**: a full typesetting language; templates in it would be close to an open renderer, the
  dependency tree is large, and krilla is the part of it this service needs.
- **printpdf / genpdf**: fewer guarantees on text extraction and determinism, less active.
- **HTML to PDF** (wkhtmltopdf, a headless Chromium): a browser in the image, network fetches by design, the opposite of
  "not an open renderer".
- **OTLP over gRPC (tonic)**: adds HTTP/2 and protobuf code generation for no gain; the collector takes OTLP/HTTP.
- **Behind the gateway, called by the browser** (ADR-0051's first sketch): the owning service would have to hand the
  browser the data or a signed request anyway; decision 89 keeps authorisation and audit where the data is.
- **A JWKS mounted from a ConfigMap**: no fetch, but a realm key rotation would break the service until a redeploy.

## Consequences
- Three toolchains in `just test`; a Rust gate failure fails `just test` like a Maven one.
- Tenant binding, authz and Problem+JSON are not needed here (no tenant data at rest); the security event and metric
  exist twice (Java and Rust) and are kept equal by hand (same field names, same message format).
- A realm change needs a re-import on an existing compose stack; `just seed-users` now also creates missing bearer-only
  clients (and, from the file, any new audience mapper).
- `finance-service` (Go, WP118) can copy the wiring: a per-service `scripts/check.sh` called from `just test-<lang>`,
  the coverage gate script, the doctor and bootstrap lines, the CI job with pinned tool downloads, the image job,
  the sub-chart and Tilt pattern.
