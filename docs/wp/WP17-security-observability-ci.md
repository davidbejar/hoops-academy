# WP17 — Security hardening, observability, CI gates

Model: Opus. Depends on: all services, WP11. Skills: owasp-security, verification-before-completion.

## Scope
- Run the OWASP skill review over each service and the Flutter auth/offline code; fix findings; threat model doc
  (`docs/security/threat-model.md`), ASVS L2 checklist with evidence (`docs/security/asvs-checklist.md`).
- Gates: dependency-check (`-Psecurity-scan`) in CI with suppression file discipline; Trivy image scan in images workflow;
  ZAP baseline against compose stack (CI job, allowed-failures list); gitleaks full history (already).
- Runtime: security headers + CORS allow-list at nginx/ingress; rate limiting for `/auth` and `events:batch`; audit
  log table/stream for admin actions (member/role changes, approvals, tenant lifecycle); Keycloak hardening review
  (brute force, password policy, no `start-dev` in kind, admin console not exposed via ingress).
- Observability: Micrometer Prometheus + OpenTelemetry traces (OTLP, disabled by default locally), JSON logs with
  tenantId/traceId MDC, health/readiness probes verified under Helm.

## Acceptance
- [ ] ZAP baseline: no High/Medium; Trivy: no CRITICAL; dependency-check: no unsuppressed CVSS ≥ 7
- [ ] audit events emitted for all admin actions (tests); headers verified by e2e; `/internal` unreachable via proxy and ingress (tests)
- [ ] `docs/security/*` complete with evidence links
