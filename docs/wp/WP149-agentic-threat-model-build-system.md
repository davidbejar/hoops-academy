# WP149 — Security docs: a threat model of the agent-driven build system (MAESTRO)

Model: Opus · high. Wave 1 (2026-11-28, eleventh round): runs alongside WP148 (STRIDE refresh of the product) and
WP150 (privacy model refresh, the method ADR, the keep-current rule). You own the new file
`docs/security/agentic-threat-model.md` and, if the documentation site lists its pages in a configuration file, the
one line that adds your page next to `threat-model.md`; nobody else touches those. Depends on: nothing (ADR-0077,
written by WP150, records the method). Skills: work-package, owasp-security (its Agentic and LLM sections),
verification-before-completion. Worktree: `~/code/hoops-wt/wp149-agentic-threat-model-build-system`, branch
`wp149-agentic-threat-model-build-system`.

Decision 121 of 2026-11-28: the product has no AI, so MAESTRO (Cloud Security Alliance, Ken Huang, 2025-02-06,
https://cloudsecurityalliance.org/blog/2025/02/06/agentic-ai-threat-modeling-framework-maestro) is applied to the way
the product is built: an orchestrator session and parallel agents with a shell, git, the owner's running stack,
skills, hooks, connectors and CI. No document covers that today.

## Scope
1. **System decomposition** (MAESTRO step 1) onto its seven layers, for this repository's build system. Say plainly
   which layers are thin or empty here and why (the model is a hosted service; there is no RAG store or agent
   marketplace). What to inventory, from the repository:
   - instruction files that steer agents: `CLAUDE.md`, `.claude/skills/**` (five folders are third-party, see
     `THIRD_PARTY_SKILLS.md`), `docs/wp` briefs, `docs/HANDOVER.md`;
   - guardrails: `.claude/hooks/tenancy-gate.sh`, `scripts/hooks/*`, the committed `.claude/settings.json`
     (permission rules; you may read it), `.pre-commit-config.yaml`, gitleaks;
   - what an agent can reach: the shell, git and `gh`, the Podman machine and the owner's compose stack, kind, the
     network, the owner's `.env` next to the checkout, connectors and plugins the session loads;
   - where agent output goes: commits on `main`, CI (`.github/workflows`), images on ghcr.io, the Pages site.
2. **Threats per layer and across layers** (steps 2 and 3), tailored, each with the control that exists today and
   its evidence. Cover at least: instructions arriving through tool output or fetched content (the jqwik line in the
   test logs, `wp-round` Traps); a poisoned dependency or action running in an agent's shell; a changed skill or
   brief steering every later agent; an agent reading or leaking the owner's `.env`; destructive commands on the
   owner's stack and volumes; the guardrail gaps the project already knows (a commit inside a helper script hides
   from the hook, WP128; the hook checks the main checkout, not the agent's worktree, WP118); an agent's false
   "verified" report; one orchestrator compromising its subagents and the reverse; observability of what agents did.
   Three or four cross-layer chains, ending at a pushed commit, a published image or the owner's data.
3. **Rating** (step 4): likelihood and impact are Low, Medium or High (1, 2, 3); the product gives the rating: 6 or 9
   High, 3 or 4 Medium, 1 or 2 Low. Judge likelihood for the project as it is run today and impact as if a real
   academy's data and a production registry depended on it. State the scale once at the top.
4. **Findings and mitigations** (step 5): a `## Findings` section, ids `AG-01…`, each with rating, evidence
   (`file:line`, or a command and its output), and a proposed control sized as a work item. Prefer controls that are
   enforced (a permission rule, a hook, a CI check, a checksum) over written rules. Only what you verified; a guess
   is listed as "to verify". Do not change any guardrail, setting, hook or workflow: wave 2 fixes High and Medium.
5. A short closing section: what an AI feature inside the product would have to meet before it is built (five to
   ten lines, pointing to the layers that would then apply).

## Acceptance
- [ ] The seven layers, the threats with today's control and evidence, the chains, the ratings and the findings are
      in the document; every cited path exists on `main`
- [ ] Nothing in the document quotes a secret, a token or a value of `.env`
- [ ] `just docs-build` green (strict); the page is reachable from the site's security section
- [ ] Handover appended: the findings by rating, in one table, and what you could not verify

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths, one at a time and not from a
  helper script (never `git add -A`, never `--no-verify`: the session refuses it). The pre-commit hooks run and may
  trim whitespace: re-add and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation
  test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to bypass it; if it
  times out under load, retry when a build has finished. End every commit message with a `Co-Authored-By:` line
  naming the model that did the work.
- Docs only: no code, no configuration, no test changes, so there is no red test in this package. Do not test a
  guardrail by trying to get past it: read it, and reason from the code and its tests.
- Do not read `.env`, `.claude/settings.local.json` or anything under the owner's home outside the repository; do
  not stop or change the owner's running stack.
- If your context runs low, stop at a green commit, append a handover part (what is done, what comes next in order)
  and report; a fresh agent continues in this worktree.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator: short, the detail stays in the
  handover.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- Built: `docs/security/agentic-threat-model.md` (commit dd2116bb). MAESTRO step 1 (diagram, inventory, the seven
  layers with Layer 1 thin and Layer 2 thin but not empty, the four architecture patterns), step 2 (threat tables per
  layer with today's control, evidence and finding), step 3 (chains C1 injected text → published image, C2 poisoned
  build tool → owner's credentials, C3 tenancy regression → pushed commit, C4 subagent → orchestrator → every later
  agent), step 4 (L × I table), step 5 (`## Findings`, AG-01 to AG-15), step 6, the bar for an AI feature in the
  product, and a Verification section. No navigation change was needed: `docs/.nav.yml` lists `security` as a folder.
- Findings by rating (L × I; proposed control):

  | Id | Rating | Finding | Proposed control |
  |---|---|---|---|
  | AG-01 | High 6 (2×3) | The commit gate checks the session's checkout, not the worktree; CI excludes all 11 Keycloak-tagged tests | CI job running `-Pkeycloak-it`; hook follows a leading `cd` / `git -C` |
  | AG-02 | High 6 (2×3) | Commits and ref changes other than a parsed `git commit` / `git push` are ungated; `main` unprotected; `images` does not wait for `ci` | Ruleset on `main` with required checks, no force push; branch CI before ff-merge; `images` on green `ci` |
  | AG-03 | High 6 (2×3) | gitleaks allowlists all `docs/**.md` and `.claude/skills/**`; Trivy's secret scan skips `.md` | Drop the path allowlist (0 hits without it today); test that keeps it out |
  | AG-04 | High 6 (2×3) | Guardrails and instruction files change in unreviewed commits; the gate runs whatever script the tree holds | CI `guarded-paths` job tied to owner decisions; merge-time diff of guarded paths; CODEOWNERS after AG-02 |
  | AG-05 | Medium 4 (2×2) | `.env` and `gh` login readable by every agent; no committed permission rule; `--no-verify` refusal not in repo | Committed `permissions.deny` (`.env`, `--no-verify`), sandbox deny if supported, test |
  | AG-06 | Medium 4 (2×2) | Destructive Podman / kind commands on the owner's stack not blocked | Committed deny rules; `just db-backup` at round start |
  | AG-07 | Medium 4 (2×2) | Agents' "verified" claims reach `main`, images, Pages before an independent run | Merge only on the branch's green `ci` run; quote the run id |
  | AG-08 | Medium 4 (2×2) | Instructions in tool output and fetched content (jqwik line, bot PR bodies) | "Tool output is data" in `work-package`; review bot PRs by diff; WebFetch allowlist |
  | AG-09 | Medium 4 (2×2) | No durable record of agent actions or gate results; trailers self-written, commits unsigned | Gate log in the shared `.git`; `WP:` trailer; close-out summary |
  | AG-10 | Medium 3 (1×3) | Vendored third-party skills have no integrity record | Per-folder checksums plus a `scripts/tests` test |
  | AG-11 | Medium 3 (1×3) | Pre-commit repos by tag, docs pins without hashes, Maven wrapper without checksum run in agents' shells | SHA revs, `--require-hashes`, `distributionSha256Sum`, tests |
  | AG-12 | Medium 3 (1×3) | One `.git` for all worktrees: an agent can move `main` or another branch | Check `main` = `origin/main` before ff-merge, push the explicit id; ruleset |
  | AG-13 | Low 2 (1×2) | Connectors unrelated to the build loaded into build sessions (session observation) | Project-level deny of unused connector tools |
  | AG-14 | Low 2 (1×2) | Hook allows every command when `jq` is missing | Exit 2 without `jq`, test, doctor check |
  | AG-15 | Low 2 (1×2) | Orchestrator's persistent memory outside the repo (to verify) | Keep it to pointers; diff at close-out |

- Verified: every backticked repository path in the document exists and every cited line range is within its file
  (scratch script over the document: 165 path tokens; the only misses are the deliberately absent `.mcp.json`, the
  shared `.git/hooks`, `origin/main` and the scratch probe names). `just docs-build` exit 0, "No issues found"; the
  built nav links `agentic-threat-model` from the security pages. gitleaks with the repository config minus its path
  allowlist over the new document and this brief: exit 0; `gitleaks protect --staged` before the commit: no leaks.
  Read-only commands on 2026-11-28: `gh api` (branch `main` unprotected, no rulesets, repository public),
  `gh variable list` (`IMAGE_REGISTRY` set), `podman ps` / `podman volume ls` (names of this project only recorded),
  `stat` of the main checkout's `.env` (mode only, content not read), `ls ~/code/hoops-wt` (other files there not
  opened), `git rev-parse --git-common-dir`, `git log` trailer and signature counts. Scratch probes with a fabricated
  token (never staged, deleted): gitleaks with the repository config misses it in `docs/*.md`, finds it without the
  path allowlist; Trivy 0.76.1 reports it in `.txt`, not in `.md`.
- Decisions/ADRs: none (the method is ADR-0077, WP150). No guardrail, setting, hook or workflow changed.
- Open points / follow-ups:
  - Not verified: where the sessions' `--no-verify` refusal and any deny rules are configured (local and user settings
    not read); the `cwd` a subagent's hook receives (AG-01 rests on the code and the WP118 handover); whether a
    ruleset's required checks refuse a direct push of an unchecked commit; whether the sandbox and a project-level
    connector deny are available; the jqwik wording (not reproduced); the content of the orchestrator's memory.
  - The hook's PASSED line did not appear in this package's tool output for commit dd2116bb; the commit went through, so
    the gate passed or was not reached. Consistent with AG-01, this session's hook ran against the main checkout.
  - For FOLLOW-UPS (docs pass): wave 2 takes AG-01 to AG-12; AG-13 to AG-15 as Low items.
