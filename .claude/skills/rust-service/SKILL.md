---
name: rust-service
description: "How to change the Rust pdf-service of Hoops Academy (services/pdf-service): the crate layering, contract-first changes to pdf.yaml, adding a sheet or a label, the security and privacy rules, the gates of just test-rust, and the image, compose, chart and kind wiring. Use whenever changing anything under services/pdf-service, pdf.yaml, pdf.Containerfile or the chart's pdf-service sub-chart."
---

# Working on pdf-service (Rust)

Read first: ADR-0051 (why Rust, the amendment of 2026-11-16), ADR-0052 (stack, gates, delivery), `libs/contracts/openapi/pdf.yaml`.
The service renders printable sheets from data the caller sends. It owns no data, connects to no database or broker,
and is called only by core-service and game-service (decision 89); the browser never calls it.

## Toolchain
- `rust-toolchain.toml` pins the toolchain; rustup installs it on first use. Homebrew's rustup is keg-only:
  `scripts/check.sh` finds it; in a shell use `export PATH="$(brew --prefix rustup)/bin:$PATH"`.
- `just test-rust` (also the end of `just test`) = `services/pdf-service/scripts/check.sh`: rustfmt check, Clippy
  (all + pedantic, warnings denied, no `unwrap`/`expect` in service code: `expect_used` is a warning that `-D warnings` denies), the tests under cargo-llvm-cov, the coverage
  gate (>= 80 % lines workspace, >= 90 % `pdf-domain`), `cargo deny check`. `--offline` skips the advisory fetch.
- `scripts/bootstrap.sh` named in `check.sh` is the repo root's script, not one under `services/pdf-service/scripts`.
- Inner loop: `cd services/pdf-service && cargo test -p pdf-domain` (fast), `cargo test --workspace`, `cargo fmt`.
- A new crate dependency: exact minor version in the crate's `Cargo.toml`, `cargo deny check` green (licence on the
  allow-list in `deny.toml`), and `tests/api/layering.rs` updated only if the layer is allowed to have it (never a framework
  in `pdf-domain`, never anything but the domain in `pdf-application`).

## Layering (crates = layers; a wrong import does not compile)
```
crates/domain       pdf-domain        sheets (MatchSheet, TeamRoster), limits, field checks, labels es/en/id,
                                      file names, PrintDocument (what a page shows). jiff and
                                      unicode-normalization only.
crates/application  pdf-application   PrintSheets (check -> document for "now" -> render -> file name), ports
                                      PdfRenderer and Clock. Depends on pdf-domain only.
crates/adapters     pdf-adapters      http (axum router, auth middleware, handlers), dto (serde bodies -> domain),
                                      auth (JWT against the realm), problem (Problem+JSON), security (events, metric),
                                      render (krilla), telemetry, config, main.rs (wiring).
```

## TDD and where tests live
- Red first, committed: a failing test (or a stub with `todo!()`) in one commit, the code in the next.
- Domain rules and documents: unit tests in the module (`#[cfg(test)]`). Renderer: `tests/api/render.rs` reads the text
  back with lopdf in es / en / id. HTTP: `tests/api/http.rs` (real router, test realm key, fixed clock). Contract:
  `tests/api/contract.rs` validates requests and answers against `pdf.yaml` (the documents and validators are parsed
  and compiled once per binary, `tests/common/contract.rs`). Verifier against a realm over HTTP: `tests/api/realm.rs`.
  Layers: `tests/api/layering.rs` (the manifests). These five are ONE test binary (`tests/api/main.rs`: one link, one
  RSA key); a new file there needs a `mod` line in `main.rs`. Logs: `tests/logs.rs` (own binary: tracing caches
  callsite interest per process). Shared helpers (`post_json` / `post_raw`, `with` / `without` for JSON pointers, the
  path constants from `pdf_adapters::http`, `assert_no_request_values`, which reads its leak list from the fixtures):
  `tests/common`. Fixtures (valid request bodies): `crates/adapters/tests/fixtures/*.json`; WP116 / WP117 and
  `deploy/kind/smoke.sh` reuse them.
- Problem type slugs and the token clock leeway follow the Java services (ADR-0064): a unit test in `problem.rs` reads
  `ProblemType.java`; a slug the enum lacks (`unsupported-media-type`, `method-not-allowed`) is listed there as pdf's own.

## Contract first
1. Change `libs/contracts/openapi/pdf.yaml` (OpenAPI 3.0.3, no `allOf`, `additionalProperties: false` on bodies,
   `nullable` for optional values, `maxItems` for every list, bump `info.version`).
2. A failing test: `tests/contract.rs` (`the_contracts_limits_are_the_domains`, the refusal cases) and the HTTP test.
3. Domain limits and checks (`MAX_*` constants equal the contract's), DTO with `deny_unknown_fields`, labels.
4. Callers (core, game) validate their requests against `classpath:openapi/pdf.yaml` (contracts jar).

## Adding a sheet
Domain: a sheet struct, `check()` (limits first with `Checks::rows`, then field rules with `text::*`), `document(now)`
building a `PrintDocument` from `Block`s (Headline, Facts, Table, Note) with `PrintDocument::new(locale, &academy,
title_label, blocks, now)`, which frames academy, title, footer and page words; `file_name(now)` with `file_name::pdf`.
Labels: add `Label` variants with all three languages (`Label::ALL` too). Application: a `PrintSheets` method. Adapters:
DTO, handler, route in `http::router`, the operation in `pdf.yaml`. Never accept markup, fonts, images or URLs.

## Security and privacy (do not weaken)
- Every `/internal/**` route sits behind `authenticate`: RS256, audience `pdf-service`, `sub`, realm role `service`.
  Refusals go through `SecurityEvents::deny` (event + `hoops_authz_denied_total`); never log the token or a claim of
  an unverified token.
- Nothing of a request body in a log line, a span field or an error answer (P-11): Problem `violations` name the field
  path and a code only. Do not `Debug`-print DTOs or sheets in logs; `tests/logs.rs` and the HTTP tests check fixtures'
  names and contacts never appear.
- Output deterministic for a fixed body and clock (no creation date, no random ids): keep `tests/api/render.rs` green.
- No outbound call except the realm (keys, discovery) and OTLP; the NetworkPolicy's egress allows only those.

## Image, compose, chart, kind
- `deploy/containers/pdf.Containerfile` (context `services/pdf-service`): `cargo auditable` on the pinned rust image,
  distroless `cc-debian13:nonroot`; bump the toolchain, the builder tag+digest and the runtime digest together.
  `scripts/build-images.sh pdf-service`, CI `images.yml` job `pdf` (Trivy gate, SBOM).
- Compose: `just pdf-up` (profile `pdf`, :8084). Callers on the host use `PDF_SERVICE_URL` from `.env`.
- Chart: sub-chart `charts/pdf-service` (alias `pdf`, `pdf.enabled`), no HTTPRoute, NetworkPolicy for `callers` only.
  A new caller: add it to `pdf.callers` and give its client the audience mapper in `infra/keycloak/realm-academy.json`
  (and the expected audiences in core's `RealmTokenPolicyTest`). Chart tests: `deploy/helm/tests/run.sh`
  (`--update` re-records snapshots).
- kind: `deploy/kind/up.sh --deploy` or `tilt up` (resource `pdf-service`, port 18084); `deploy/kind/smoke.sh` checks the
  render from a core-labelled pod and the NetworkPolicy refusing other pods.

## Stubbing pdf-service in a Java test
WireMock (or a Quarkus test resource) on `PDF_SERVICE_URL` answering `200`, `Content-Type: application/pdf`, a body
starting with `%PDF-`, and Problems from `pdf.yaml` for the error paths; validate the request the stub receives against
`classpath:openapi/pdf.yaml` (schemas `MatchSheetRequest` / `TeamRosterRequest`) with the contract validator the
services already use.
