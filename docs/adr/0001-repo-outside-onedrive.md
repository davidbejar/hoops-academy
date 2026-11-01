# ADR-0001: Source repository lives outside cloud-synced folders

- Status: Accepted
- Date: 2026-11-01

## Context
The project was started in a OneDrive folder. Maven `target/`, Flutter `.dart_tool/`, git objects and Podman bind mounts generate thousands of small, frequently changing files that cloud sync clients lock, duplicate or re-upload.

## Decision
The git repository lives at `~/code/hoops-academy`. The OneDrive folder keeps only the specification, the plan and a README pointer.

## Consequences
Builds and tests are fast and deterministic; the plan documents are still backed up. Developers must clone the repo rather than open the OneDrive folder.
