# syntax=docker/dockerfile:1
# pdf-service image (Rust, ADR-0051 §3, ADR-0052). Build context = services/pdf-service (only the Rust workspace).
#
#   podman build -f deploy/containers/pdf.Containerfile -t localhost/hoops/pdf-service:dev services/pdf-service
#
# services/pdf-service/.containerignore keeps the cargo target directory out of the context.
#
# Stage 1 compiles with the toolchain of rust-toolchain.toml (the builder image's version is the same pin) through
# cargo-auditable, which embeds the crate list in the binary: Trivy's image scan and SBOM then see every crate, not
# only the OS packages. Stage 2 is distroless (Debian 13, glibc and libgcc only): no shell, no package manager, user
# nonroot 65532, read-only root file system friendly (the service writes nothing). Both bases are pinned by the digest
# of their multi-arch index (ADR-0054); bump the tag and digest together with rust-toolchain.toml (ADR-0052).
ARG BUILDER_IMAGE=docker.io/library/rust:1.99.1-slim-trixie@sha256:f6c4a35d21dbb3c89d7a8d056c193e94fc09037f2b58dd858b09c39a47dd02d7
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian13:nonroot@sha256:29ee70762214fe8190cea04ef1c0a84a8365879e047ce8f911ae5a5ab2355fa2

# ---------- stage 1: build ------------------------------------------------------------------------------------------
FROM ${BUILDER_IMAGE} AS build
WORKDIR /src
# the builder image already has the pinned toolchain; do not let rustup fetch another one
ENV RUSTUP_TOOLCHAIN=1.99.1 CARGO_TERM_COLOR=never
RUN --mount=type=cache,target=/usr/local/cargo/registry,id=hoops-cargo-registry \
    cargo install --locked cargo-auditable@0.7.7
COPY Cargo.toml Cargo.lock rust-toolchain.toml ./
COPY crates crates
COPY fonts fonts
RUN --mount=type=cache,target=/usr/local/cargo/registry,id=hoops-cargo-registry \
    --mount=type=cache,target=/src/target,id=hoops-pdf-target \
    cargo auditable build --release --locked -p pdf-adapters --bin pdf-service \
 && install -D -m 0755 target/release/pdf-service /out/pdf-service

# ---------- stage 2: runtime ----------------------------------------------------------------------------------------
FROM ${RUNTIME_IMAGE}
# SOURCE_URL: repository URL for the OCI source label (ghcr.io links the package to it). CI passes github.repository.
ARG SOURCE_URL=""
LABEL org.opencontainers.image.title="hoops-pdf-service" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.description="Hoops Academy pdf-service (Rust): printable sheets, internal only"
COPY --from=build /out/pdf-service /usr/local/bin/pdf-service
USER 65532:65532
ENV PDF_HTTP_PORT=8084
EXPOSE 8084
ENTRYPOINT ["/usr/local/bin/pdf-service"]
