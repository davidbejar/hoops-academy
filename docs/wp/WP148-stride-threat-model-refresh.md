# WP148 — Security docs: the STRIDE threat model covers the system as built, with ratings and attack chains

Model: Opus · high. Wave 1 (2026-11-28, eleventh round): runs alongside WP149 (agentic threat model of the build
system) and WP150 (privacy model refresh, the method ADR, the keep-current rule). You own
`docs/security/threat-model.md`; nobody else touches it. You touch no other file except this brief's Handover.
Depends on: nothing (ADR-0077, written by WP150, records the method; its content is fixed below). Skills:
work-package, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp148-stride-threat-model-refresh`, branch `wp148-stride-threat-model-refresh`.

Decision 119 of 2026-11-28: the STRIDE model is brought up to date in this round. It covers six trust boundaries and
three services; the privacy model covers ten. Decision 120: from PASTA it takes a likelihood and impact rating and a
few attack chains, not the full seven stages.

## Scope
1. **Header, assets, actors, data-flow diagram**: the system as `main` has it (five services, Redpanda, the
   collector and the LGTM backend, the Gateway, CloudNativePG). Read the code, compose file and chart, not only the
   docs; give evidence as the existing rows do (class, test, file, ADR).
2. **Missing boundaries**, numbered as in `docs/security/privacy-threat-model.md` so the two documents line up:
   7 core → Redpanda → replicas; 8 services → collector → log and trace backend; 9 core / game → pdf-service;
   10 browser ↔ finance-service. One STRIDE table each, same columns as the existing ones. Re-check the six existing
   tables against the code and correct rows that are no longer true.
3. **Boundary 11, build and supply chain of the product**: dependencies (Maven, Cargo, Go modules, pub), GitHub
   Actions and their pins, workflow permissions, the image build, ghcr.io, the Helm chart, the OpenTofu state. The AI
   agents that write the code are WP149's subject: name them as an actor and link to
   `agentic-threat-model.md`, do not model them here.
4. **Rating**: a `Rating` column for every residual risk. Likelihood and impact are Low, Medium or High (1, 2, 3);
   the product gives the rating: 6 or 9 High, 3 or 4 Medium, 1 or 2 Low. Judge likelihood for the project as it is
   exposed today and impact as if a real academy's data were in it. State the scale once at the top.
5. **Attack chains**: three or four chains for the top assets (minors' and health data, tenant isolation,
   credentials), each a numbered path across boundaries with the control that breaks it at each step and the step
   where no control stands.
6. **Findings**: a `## Findings` section, ids `TM-01…`, each with rating, evidence (`file:line` or a command and its
   output), and a proposed fix sized as a work item. Only what you verified in the repository; a guess is listed as
   "to verify". Do not fix anything: wave 2 fixes High and Medium.

## Acceptance
- [ ] Every table row cites evidence that exists on `main` (spot-check ten rows and list them in the handover)
- [ ] Boundaries 7 to 11, the rating column, the chains and the findings are in the document
- [ ] `just docs-build` green (strict)
- [ ] Handover appended: the findings by rating, in one table, and what you could not verify

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- Docs only: no code, no configuration, no test changes, so there is no red test in this package.
- Do not read `.env` or `.claude/settings.local.json`; do not stop or change the owner's running stack.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator: short, the detail stays in the
  handover.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
