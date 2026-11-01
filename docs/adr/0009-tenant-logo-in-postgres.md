# ADR-0009: Academy logo stored in Postgres, served by core-service

- Status: Accepted
- Date: 2026-11-01

## Context
Admins upload an academy logo. Object storage (S3/MinIO) would add an infrastructure component for a few hundred small files.

## Decision
`core.tenant_logo(tenant_id pk, content_type, bytes bytea, etag, updated_at)`; upload limited to 512 KB, PNG/JPEG/WebP (magic bytes checked), SVG rejected in v1; served at `GET /api/core/tenant/logo` with ETag/Cache-Control. Object storage is a documented extension behind a `LogoStorage` port.

## Consequences
No extra infrastructure; logos are covered by RLS and backups like any row. Large binary growth would motivate the object-storage adapter later.
