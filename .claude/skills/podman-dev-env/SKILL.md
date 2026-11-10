---
name: podman-dev-env
description: Podman-on-macOS specifics for this repo — Testcontainers/Quarkus Dev Services socket setup, Ryuk, compose, kind and Tilt gotchas, and how to diagnose "Could not find a valid Docker environment". Use when containers, Testcontainers, compose, kind or Tilt misbehave locally.
---

# Podman developer environment

Always `source scripts/env.sh` first; `just doctor` verifies the setup.

## Testcontainers / Quarkus Dev Services
- `DOCKER_HOST=unix://<podman machine socket>` and `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock`
  (set by `scripts/env.sh`).
- Ryuk (reaper) needs a privileged container: rootful machine → `TESTCONTAINERS_RYUK_PRIVILEGED=true` or
  `ryuk.container.privileged=true` in `~/.testcontainers.properties`; rootless → `TESTCONTAINERS_RYUK_DISABLED=true`
  (containers are then cleaned by JVM shutdown hooks; run `podman ps -a` after crashes).
- "Could not find a valid Docker environment": machine not running (`podman machine start`), or the shell did not
  source `scripts/env.sh`, or the socket path changed after a machine re-init.
- `host.docker.internal` is `host.containers.internal` under Podman. Prefer compose networks over host access.

- `localhost:2375 failed to respond` mid-run: the API service idled out. It needs the `--time=0` drop-in
  (`infra/podman/machine-playbook.yml` for `podman machine init --playbook`; `just doctor` adds it to an existing
  machine and never restarts the service while containers run). Do not restart `podman.service` while other builds use it.

## Compose
`podman compose` delegates to `podman-compose` (installed by bootstrap). Use `--wait` with healthchecks.
Volumes with `:Z` labels are harmless on macOS. Never run compose from the OneDrive folder.

## kind (WP16)
- `KIND_EXPERIMENTAL_PROVIDER=podman` (exported by env.sh). A rootful machine is strongly recommended:
  `podman machine stop && podman machine set --rootful && podman machine start`.
- Map 8080/8443 in the kind config, not 80/443.
- Load images with `kind load image-archive <tar>` (built by Quarkus Jib `buildTar` / `podman save`), not a local
  registry.

## Tilt
Use `custom_build` that produces a tar and calls `kind load image-archive`; `docker_build` assumes BuildKit and is
unreliable against the Podman socket.
