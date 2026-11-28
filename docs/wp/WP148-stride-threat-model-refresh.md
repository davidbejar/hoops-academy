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
- **Built** (cc897b4a, `docs/security/threat-model.md` only):
  - New header: scope at cc4fb3e2, method, and the rating scale (L×I: 6/9 High, 3/4 Medium, 1/2 Low). Likelihood is
    for today's exposure: no cloud applied, compose and kind on 127.0.0.1, the repository public.
  - Assets, actors and the data-flow diagram cover five services, Redpanda, the collector with LGTM / Jaeger, the
    Gateway, CNPG, ghcr.io and OpenTofu. The AI agents are named as an actor.
  - Boundaries 1–6 re-checked against the code, with a `Rating` column. Corrected rows:
    - Audience check present (F-14 fixed).
    - Optional OTP instead of "no MFA"; the password policy now has a max length and a blocklist.
    - No gstatic in the CSP.
    - F-03, F-07 and F-08 are fixed; only their residuals remain.
    - Replica mode for game and athlete.
    - finance and pdf audiences in the realm.
    - New residuals: migrator passwords in serving pods, the HTTP listener, Postgres open to the namespace, Keycloak's
      `X-Forwarded-For`.
  - New boundaries 7–11 (same numbers as the privacy model): Redpanda, telemetry, pdf-service, finance-service, and
    the build and supply chain.
  - Four attack chains: A health data, B tenant isolation, C credentials, D supply chain.
  - Findings TM-01..TM-14, a "to verify" list, and a Verification section.
  - The two files of the other packages are named as code text, not links: `agentic-threat-model.md` (WP149) and
    ADR-0077 (WP150). A link to a missing file fails the strict build; tried and confirmed, then reverted.
- **Findings** (Medium and above go to wave 2):

  | ID | Rating | Finding | Proposed fix |
  |---|---|---|---|
  | TM-01 | Medium (L1×I3) | Serving pods hold their schema's migrator password (owner: can turn RLS off, delete audit rows) | Migrations in a Job / init container; serving pods get `*_app` only; chart test |
  | TM-02 | Medium (L1×I3) | core, game, athlete (and Keycloak) have no egress NetworkPolicy | `hoops-lib.networkPolicy` with egress lists; chart tests |
  | TM-03 | Medium (L1×I3) | `main` unprotected (no protection, no ruleset); `images.yml` pushes without the security gates | Ruleset with required checks; images after a green `ci` |
  | TM-04 | Medium (L1×I3) | Floating build images, tools, platform installs (Maven builder, nginx + `apk upgrade`, Flutter stable, Trivy, Keycloak, CNPG manifest from a branch) | Digest / checksum pins in `bump-pins.sh` |
  | TM-05 | Medium (L1×I3) | Maven wrapper without checksum, no Maven checksum policy, `pub get` without `--enforce-lockfile`, Semgrep rules unpinned | Checksums, strict policy, enforce the lock file, pin rules |
  | TM-06 | Medium (L1×I3) | The HTTP listener serves every route with TLS on; no redirect, no HSTS; cloud opens :80 | Redirect route; app routes on `https` only |
  | TM-07 | Medium (L1×I3) | No second factor required, the super admin included (decision 39) | Required OTP for `super_admin` (ADR-0038 amendment) |
  | TM-08 | Medium (L1×I3) | Images not signed or attested; the chart deploys by tag | cosign + attestation; deploy by digest |
  | TM-09 | Low (L1×I2) | Postgres open to every pod of the namespace; no `sslmode` | Narrow the NetworkPolicy; `verify-full` |
  | TM-10 | Low (L1×I2) | Logs skip id stripping; Grafana anonymous with viewers-can-edit | Decide the log attributes (P-07); turn edit off |
  | TM-11 | Low (L1×I2) | gitleaks allow-lists all `docs/**/*.md` and skills | Fingerprint / regex allow-list instead |
  | TM-12 | Low (L1×I1) | pdf-service has no render timeout or queue bound; core holds a DB transaction during the call | Render timeout, bounded wait; call outside the transaction |
  | TM-13 | Low (L1×I1) | No `SECURITY.md`, CODEOWNERS or signed commits in a public repository | `SECURITY.md` with private reporting |
  | TM-14 | Low (L1×I1), to verify | A client `X-Forwarded-For` may reach Keycloak's event IP | Check on kind; set the client IP at the Gateway |

- **Verified:**
  - `just docs-build`: "No issues found" on the committed file.
  - gitleaks: no leaks.
  - Ten rows spot-checked against the tree (and the eleventh against GitHub):
    1. §1 S audience: core `application.properties:41`.
    2. §1 D `events:batch`: `nginx.conf:99-102`, `values.yaml:338-339`.
    3. §1 E deny paths: `nginx.conf:60`, `charts/keycloak/values.yaml:46-47`.
    4. §2 S placeholders: `realm-academy.json:206,269,319`, `deploy/cloud/install.sh:25`.
    5. §3 S: `InternalResource:21`, `InternalRosterResource:31`.
    6. §4 S migrator env: `values.yaml:320,356,380`.
    7. §4 I: `charts/databases/templates/networkpolicy.yaml:15-16`.
    8. §6 D: `TenantLogoResource:73-75`.
    9. §7 T: `CoreEventDecoder:84-107`.
    10. §8 I: `observability.yaml:111-119,401-405`.
    11. §11 S: `gh api .../branches/main/protection` → "Branch not protected", `.../rulesets` → `[]`.
  - Three read-only subagents gathered evidence for §7–§11. Every `file:line` in a finding was then reopened by hand.
  - `just test` was not run: no code, configuration or test changed.
- **Decisions/ADRs:** none. The method is ADR-0077 (WP150). TM-07 asks to revisit decision 39.
- **Open points / could not verify:**
  - Turn the two code-text names into links once WP149 and WP150 are merged: `agentic-threat-model.md` (header,
    Actors, §11, Out of scope) and ADR-0077 (header).
  - To verify live, on kind:
    - A consumer's SCRAM login is refused a produce on `core.*`.
    - TM-14.
    - Whether Postgres connections use TLS (TM-09).
    - Whether kindnet and k3s enforce NetworkPolicy.
  - Also to verify:
    - Whether JSON Schema error messages (the parked reason) quote values.
    - Whether ghcr.io tags can be overwritten.
    - Envoy edge-span attributes.
  - The repository settings in §11 are live GitHub state on 2026-11-28, not files.
  - Drift seen in other docs (not edited, outside scope):
    - `docs/security/sast-dast.md` and ADR-0045 list CodeQL and Semgrep for Java only.
    - ADR-0043 names UBI packages and ORAS 1.3.6.
    - ADR-0036 §7 lists three broker users (there are four).
    - ADR-0037 §4 says the app role only inserts into `parked_event` (game and athlete may delete).
