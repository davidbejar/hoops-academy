# syntax=docker/dockerfile:1
# finance-service image (Go, ADR-0051 §2, ADR-0055). Build context = services/finance-service (only the Go module).
#
#   podman build -f deploy/containers/finance.Containerfile -t localhost/hoops/finance-service:dev services/finance-service
#
# services/finance-service/.containerignore keeps target/ (coverage, local binaries) out of the context.
#
# Stage 1 compiles with the Go of go.mod's toolchain line (the builder image's version is the same pin), static
# (CGO_ENABLED=0), trimmed paths, without VCS stamping; Go embeds the module list in the binary, so Trivy's image scan
# and the SBOM see every module. Stage 2 is distroless static (Debian 13: CA certificates, tzdata, /etc/passwd only):
# no shell, no libc, no package manager, user nonroot 65532, read-only root file system (the service writes nothing).
# Both bases are pinned by the digest of their multi-arch index, resolved 2026-11-16; bump the tag and digest together
# with go.mod's toolchain line.
ARG BUILDER_IMAGE=docker.io/library/golang:1.27.4-trixie@sha256:b54b2639de8c1bfe538ec5ffc45f29b1932235ac5f6d63c059853646677112d9
ARG RUNTIME_IMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:aafe993665bf6200db38a02c11a9351e782a84b6a45e7f33b6695638c88e3931

# ---------- stage 1: build ------------------------------------------------------------------------------------------
FROM ${BUILDER_IMAGE} AS build
WORKDIR /src
# the builder image already has the pinned toolchain; never let the go command download another one
ENV GOTOOLCHAIN=local CGO_ENABLED=0 GOFLAGS=-mod=readonly
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod,id=hoops-go-modules go mod download
COPY cmd cmd
COPY db db
COPY internal internal
RUN --mount=type=cache,target=/go/pkg/mod,id=hoops-go-modules \
    --mount=type=cache,target=/root/.cache/go-build,id=hoops-go-build \
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o /out/finance-service ./cmd/finance-service

# ---------- stage 2: runtime ----------------------------------------------------------------------------------------
FROM ${RUNTIME_IMAGE}
# SOURCE_URL: repository URL for the OCI source label (ghcr.io links the package to it). CI passes github.repository.
ARG SOURCE_URL=""
LABEL org.opencontainers.image.title="hoops-finance-service" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.description="Hoops Academy finance-service (Go): fee plans, dues, payments, expenses"
COPY --from=build /out/finance-service /usr/local/bin/finance-service
USER 65532:65532
ENV FINANCE_HTTP_PORT=8085
EXPOSE 8085
ENTRYPOINT ["/usr/local/bin/finance-service"]
