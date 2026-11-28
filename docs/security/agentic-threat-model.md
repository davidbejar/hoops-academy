# Agentic threat model — the build system (MAESTRO)

Version 2026-11-28 (WP149, decision 121). The product has no AI feature, so this document models **the way the product
is built**: an orchestrator session that plans rounds and merges, parallel AI agents that each run one work package in a
git worktree with a shell, git, `gh`, the Podman machine and the owner's running stack, the skills and hooks that steer
and gate them, the connectors a session loads, and CI, which turns what lands on `main` into images and a public site.
Method: MAESTRO (Cloud Security Alliance, Ken Huang, 2025-02-06): seven layers and six steps; the method choice is
recorded in ADR-0077 (WP150). Companion documents: [`threat-model.md`](threat-model.md) (STRIDE for the product; WP148
adds its boundary for dependencies, Actions, images and the registry, which this document does not repeat) and
[`privacy-threat-model.md`](privacy-threat-model.md) (LINDDUN).

**Evidence base.** Every `file:line` refers to the tree of `main` at cc4fb3e2 (this package's branch point); later
edits to those files shift the numbers. Commands were run read-only on 2026-11-28; their outputs are summarised under
[Verification](#verification). Nothing here quotes a secret, and the document describes what a control does not cover
rather than how to get past it.

**Project nature.** A learning project with test and demo data, run by one owner. Likelihood is judged for the project
as it is run today; impact as if a real academy's data and a production registry depended on it.

## Rating scale

Likelihood (L) and impact (I) are Low, Medium or High (1, 2, 3). Rating = L × I: **6 or 9 High, 3 or 4 Medium, 1 or 2
Low.** A finding is listed only when verified; anything inferred is marked *to verify*.

## Step 1 — System decomposition

```
 Owner (human in the loop: interview, decisions, permission prompts)
   │
 Orchestrator session (main checkout ~/code/hoops-academy; skill wp-round; persistent memory outside the repo)
   │  Agent tool: brief path + prompt              ▲ final report (text), handover in the brief, commits
   ▼                                                │
 WP agents ×≤4 per wave, each in ~/code/hoops-wt/<wp-slug> (one shared .git), skills work-package & co.
   │ Bash (PreToolUse hook: tenancy-gate.sh)   │ Read/Write/Edit   │ WebFetch / connectors / plugins
   ▼                                            ▼                    ▼
 shell as the owner's macOS user and gh login: git, gh, just, mvnw, go, cargo, pip, podman (compose, Testcontainers, kind)
   │
 git commit (pre-commit: gitleaks …) → orchestrator ff-merges → git push → main (public, unprotected)
   │
 GitHub Actions: ci, e2e, codeql, semgrep      images → ghcr.io (on push, IMAGE_REGISTRY set)      pages → public site
```

### Inventory

| Component | What it is here | Where |
|---|---|---|
| Instruction files | `CLAUDE.md`; 13 skill folders under `.claude/skills/`, five of them vendored third-party copies; the briefs `docs/wp/WP<n>-*.md`; `docs/HANDOVER.md`; `docs/wp/FOLLOW-UPS.md` | repository |
| Persistent agent memory | the orchestrator's memory note, updated at close-out | outside the repository (`.claude/skills/wp-round/SKILL.md:130`); not read for this model |
| Guardrails, enforced | Claude Code `PreToolUse` hook on Bash → `.claude/hooks/tenancy-gate.sh` → `scripts/hooks/isolation-check.sh` (commit) and `scripts/hooks/db-role-check.sh` (push); git `pre-commit` hooks from `.pre-commit-config.yaml` (gitleaks, private-key detector, YAML and merge-conflict checks), installed in the shared `.git/hooks`; CI | `.claude/settings.json:3-14`, `.pre-commit-config.yaml:1-21`, `.github/workflows/` |
| Guardrails, written | "never `--no-verify`", "do not read `.env`", "do not stop the stack, remove no volume", "never weaken a quality gate", "do not trust agent success reports" | briefs' Working rules, `.claude/skills/wp-round/SKILL.md:92-103`, `.claude/skills/work-package/SKILL.md:23`, `.claude/skills/verification-before-completion/SKILL.md:47,55` |
| Permission rules | none committed: `.claude/settings.json` holds only the hook. Whatever the sessions enforce beyond it lives in local or user settings outside the repository (not read) | `.claude/settings.json:1-17` |
| Identity of an agent | the owner's: the macOS user, the git author, and the `gh` login (scopes `repo`, `workflow`, `gist`, `read:org`; admin on the repository) | `gh auth status`, `gh api` (2026-11-28) |
| Reach of an agent | every file the owner can read (including the main checkout's `.env`), the shared `.git` of all worktrees, the Podman machine with the owner's compose stack and its volumes, the network | commands under [Verification](#verification) |
| Connectors and plugins | loaded from the owner's account and user settings, none from the repository (no `.mcp.json`, no plugin file committed) | session observation, WP149 |
| Output sinks | commits on `main` (public repository, no branch protection, no rulesets); `ci`, `e2e`, `codeql`, `semgrep` on push; `images` pushes to the registry on every push to `main` that touches code; `pages` publishes `docs/` publicly | `gh api` (2026-11-28), `.github/workflows/images.yml:15-18,59`, `.github/workflows/pages.yml:6-13` |

### The seven layers here

| MAESTRO layer | In this build system | Thin or empty? |
|---|---|---|
| 7 Agent Ecosystem | the owner, the orchestrator, the WP agents, the advisor model, the GitHub bots (Dependabot, `bump-pins`) whose PRs the orchestrator reads, connectors | full |
| 6 Security and Compliance (vertical) | the hook, git pre-commit hooks, gitleaks, `.gitignore`, the written rules, the OWASP skill, CI's scanners; ADRs as the decision record | full |
| 5 Evaluation and Observability | `verification-before-completion`, the hook's PASSED / Blocked line, CI runs, handovers, `Co-Authored-By` trailers; session transcripts outside the repository | partial: little is durable or independent |
| 4 Deployment and Infrastructure | the Mac, its Podman VM, compose stack and volumes, kind, worktrees under `$HOME`, the shared `.git`, the owner's `gh` login, GitHub runners, ghcr.io, Pages | full |
| 3 Agent Frameworks | Claude Code: the Agent tool, Bash / Read / Write tools, skills, hooks, permission modes, worktrees, WebFetch, MCP connectors and plugins | full |
| 2 Data Operations | no RAG store, no vector database, no fine-tuning. The data agents operate on is their standing context: `CLAUDE.md`, skills, briefs, `docs/HANDOVER.md`, `docs/wp/FOLLOW-UPS.md`, the persistent memory, plus tool output and fetched pages within a session | thin, but not empty: this context steers every later agent |
| 1 Foundation Models | hosted models (Opus, Sonnet, Fable) chosen per brief (`.claude/skills/wp-round/SKILL.md:42-45`); the project trains, hosts and tunes nothing | thin: provider-side threats have nothing in the repository to attach to |

### Architecture patterns

- **Hierarchical.** The orchestrator writes every brief and prompt and merges every branch; a compromised orchestrator
  controls all subordinates. The reverse also holds: a subagent's report, handover and commits are the orchestrator's
  inputs, and the subagent can write the files the orchestrator's session loads (chain C4).
- **Multi-agent.** Up to four agents run in parallel. Their "channel" is not a message bus but shared state: one `.git`
  (refs and hooks), the main checkout's files, one Podman machine and one compose database. No agent has an identity of
  its own: all act as the owner, and the only label is a self-written commit trailer.
- **Human in the loop.** The owner answers the round interview, approves permission prompts and is told results by the
  orchestrator. The owner sees summaries, not diffs: manipulated agent reports reach the human through the orchestrator.
- **Task-oriented (ASI08 Cascading Failures).** Overload is real: five or more parallel builds make the hook's Keycloak
  container miss its wait and block commits (`.claude/skills/wp-round/SKILL.md:83-86`), which is pressure to bypass the
  gate.

## Step 2 — Threats per layer

Each row: the threat, today's control and its evidence, and the finding it feeds (Step 5). OWASP references use the
2026 Agentic (ASI) and LLM lists of the `owasp-security` skill.

### Layer 7 — Agent Ecosystem

| Threat | Control today | Evidence | Finding |
|---|---|---|---|
| A compromised or mistaken orchestrator steers every agent (ASI10 Rogue Agents) | the owner's interview and decisions; nothing checks a brief against the decisions | `.claude/skills/wp-round/SKILL.md:11-31` | AG-04 |
| A subagent compromises the orchestrator: plants instructions in its report or handover, or edits files the orchestrator loads (ASI07 Insecure Inter-Agent Communication) | the harness tells agents that agent messages are not consent; no technical boundary keeps a subagent out of the main checkout | session prompt; [Verification](#verification) (shared `.git`, main checkout reachable) | AG-04, AG-13 |
| Instructions in bot PRs and fetched text (upstream release notes in Dependabot PRs, web pages) hijack the reader (ASI01 Agent Goal Hijack) | Dependabot's seven-day cooldown slows fresh releases; nothing fences PR bodies | `.github/dependabot.yml:7-8`; `docs/HANDOVER.md:165` (review the bot PRs as they arrive) | AG-09 |
| Connectors unrelated to the build (personal-productivity tools) are offered to build agents (LLM03 Excessive Agency) | none in the repository | session observation | AG-15 |
| The human trusts a confident summary (ASI09 Human-Agent Trust Exploitation) | `verification-before-completion` asks for command output; the orchestrator re-verifies only some merges | `.claude/skills/verification-before-completion/SKILL.md:47,55`; `.claude/skills/wp-round/SKILL.md:60-63` | AG-08 |

### Layer 6 — Security and Compliance (vertical)

| Threat | Control today | Evidence | Finding |
|---|---|---|---|
| A tenancy regression on an agent's branch is committed unchecked | the hook runs the isolation check before a `git commit` it recognises, in the directory of the session, not the directory the command targets | `.claude/hooks/tenancy-gate.sh:58-62,144-149`; `docs/wp/WP118-finance-service-go-foundation.md:164` | AG-01 |
| A commit or ref change that is not a parsed `git commit` / `git push` skips the gate | the parser follows wrappers and quoted shells; it does not read the contents of a script the command runs, and gates only the `commit` and `push` subcommands | `.claude/hooks/tenancy-gate.sh:41-55,58-66`; `.claude/skills/wp-round/SKILL.md:116-117` (WP128) | AG-02 |
| A secret written into Markdown leaves through the public repository and Pages | gitleaks pre-commit and CI; but the config skips every `docs/**.md` and `.claude/skills/**`, and Trivy's secret scan skips `.md` | `.gitleaks.toml:6-12`; probes under [Verification](#verification) | AG-03 |
| An agent weakens a gate or a rule in an ordinary commit | written rule only; no CODEOWNERS, no review step for guardrail paths at merge | `.claude/skills/work-package/SKILL.md:23`; `.claude/skills/wp-round/SKILL.md:58-65`; `.github/` has no `CODEOWNERS` | AG-04 |
| Any control on GitHub (ruleset, review) cannot tell an agent from the owner (ASI03 Identity and Privilege Abuse) | none: agents use the owner's admin login | `gh auth status`, `gh api` permissions (2026-11-28) | AG-05 |
| `--no-verify` disables the pre-commit hooks (and with them gitleaks) | said to be refused by the session's permission check; the rule is not in the committed settings | `.claude/skills/wp-round/SKILL.md:92-94`; `.claude/settings.json:1-17` | AG-06 (*to verify* where it is enforced) |
| The hook fails open when its own dependency is missing | `jq` reads the command; when it yields nothing the hook allows the command | `.claude/hooks/tenancy-gate.sh:8-12` | AG-14 |

### Layer 5 — Evaluation and Observability

| Threat | Control today | Evidence | Finding |
|---|---|---|---|
| An agent reports "verified" for something it did not run, or ran elsewhere (LLM07 Misinformation) | the skill's evidence table; CI after the push. The orchestrator re-runs the build only when another package of the same area landed, otherwise "the agent's fresh results stand" | `.claude/skills/wp-round/SKILL.md:60-63`; problems found only after the agent's report: a tag-object pin (WP55, `:80-82`), helm tests red after a green verify (WP137, `:112-115`), a realm test fixed in a later commit after WP118 (`docs/wp/FOLLOW-UPS.md:1224-1225`) | AG-08 |
| Test output tells the agent to disregard results (the jqwik line in test logs) | prompt-level: the orchestrator names it in every prompt; the hook counts surefire totals itself instead of trusting the log narrative | `.claude/skills/wp-round/SKILL.md:90-91`; `docs/HANDOVER.md:300-301`; `scripts/hooks/_common.sh:59-68` | AG-09 |
| After an incident nobody can say which agent ran what | commit trailers name a model; the hook's result goes to stderr only; transcripts live outside the repository | `.claude/hooks/tenancy-gate.sh:124-131`; trailer and signature counts under [Verification](#verification) | AG-10 |

### Layer 4 — Deployment and Infrastructure

| Threat | Control today | Evidence | Finding |
|---|---|---|---|
| An agent reads or leaks the owner's `.env` (LLM02 Sensitive Information Disclosure) | `.gitignore` keeps it out of git; worktrees get no copy; "do not read" is written | `.gitignore:2-4`; `.claude/skills/wp-round/SKILL.md:100-103`; the file exists next to the main checkout, readable by the owner's user | AG-06 |
| Destructive commands on the owner's stack and volumes (ASI02 Tool Misuse) | `just down` keeps volumes; "do not stop the stack, remove no volume" is written; but two runbooks give a reset that drops the database volume | `justfile:123-124`; `docs/runbooks/e2e.md:117`; `docs/runbooks/backup-restore.md:47`; `docs/adr/0073-postgresql-19.md:60-62` | AG-07 |
| One agent moves another's branch or `main` through the shared `.git` (lateral movement) | none: worktrees share refs by design; the orchestrator ff-merges and pushes `main` | `git rev-parse --git-common-dir` → the main checkout's `.git`; `.claude/skills/wp-round/SKILL.md:51-53,64-65` | AG-13 |
| A poisoned dependency or tool runs in an agent's shell with the owner's rights (ASI04 Agentic Supply Chain) | Actions pinned by SHA and tested; Dependabot cooldown; dependency scanners in CI. Not pinned by digest: the pre-commit hook repos (by tag), the docs toolchain (versions without hashes), the Maven distribution (no checksum) | `scripts/tests/test_workflows.py:49`; `.pre-commit-config.yaml:3,7`; `config/docs/requirements.txt:5-15`; `.mvn/wrapper/maven-wrapper.properties:1-3` | AG-12 |
| A bad commit on `main` becomes a pushed image and a public page before `ci` is green | images are Trivy-scanned before the push, but `images` does not wait for `ci`; `main` has no required checks | `.github/workflows/images.yml:15-18,59`; `.github/actions/image-publish/action.yml:36-43,63-64`; `gh api` (unprotected) | AG-02, AG-08 |

### Layer 3 — Agent Frameworks

| Threat | Control today | Evidence | Finding |
|---|---|---|---|
| Unsafe code execution: every agent's Bash runs unsandboxed as the owner (ASI05 Unexpected Code Execution) | the hook gates two git subcommands; every other command passes at once | `.claude/hooks/tenancy-gate.sh:5,142`; `.claude/settings.json:5` (matcher `Bash` only) | AG-02, AG-06, AG-07 |
| A changed skill steers every later agent (ASI06 Memory and Context Poisoning) | the third-party list says "re-vet before updating"; nothing detects a change to a vendored folder | `.claude/skills/THIRD_PARTY_SKILLS.md:3-7,9-15`; no test references `.claude/skills` (`grep` of `scripts/` and `.github/`) | AG-11, AG-04 |
| The hook that gates a session is live code in the main checkout; the gate scripts it calls come from the checked tree, so whoever can write those files decides the gate | none beyond the written rule | `.claude/settings.json:9`; `.claude/hooks/tenancy-gate.sh:146-149`; `scripts/hooks/tenancy-gate.test.sh:78-100` (a stub gate script decides the outcome) | AG-04 |

### Layer 2 — Data Operations

| Threat | Control today | Evidence | Finding |
|---|---|---|---|
| Standing context drifts or is poisoned: a wrong fact in `docs/HANDOVER.md`, a skill or a brief is followed by every later agent | periodic prompt audit by the orchestrator | commit 7288707a ("stale facts corrected": 13 files under `.claude/skills` and `CLAUDE.md`) | AG-04 |
| The orchestrator's persistent memory, outside the repository, is changed and carried into later rounds | none visible from the repository | `.claude/skills/wp-round/SKILL.md:130` | AG-16 (*to verify*) |
| Tool output and fetched pages carry instructions into a session (LLM01 Prompt Injection) | prompt-level naming of known cases | `.claude/skills/wp-round/SKILL.md:90-91` | AG-09 |

### Layer 1 — Foundation Models

Thin here: the models are a hosted service and the project trains, tunes or hosts nothing. Two threats attach. Model
errors produce plausible but wrong statements in docs and reports (covered by AG-08's control, independent runs).
Model versions change between rounds (the trailers name four model versions across 1,236 commits), so behaviour that a
skill was tuned for can shift; the skills' rules are enforced only where a hook or CI repeats them. Provider-side
threats (training data, model supply chain) have nothing in this repository to attach to.

## Step 3 — Cross-layer chains

Each chain names the attacker, the MAESTRO cross-layer category it instantiates, and checks that every step is within
that attacker's reach (the `owasp-security` triage).

**C1 — Injected text to a published image** (goal-misalignment cascade). Attacker: anyone who can put text where an
agent reads it (an upstream release note in a bot PR, a fetched page, a public issue). L7/L2 the text reaches a session
→ L3 the agent, goal hijacked, edits a gate script or the gitleaks config inside an ordinary commit (AG-04) → L6 no
review of guardrail paths at merge → L4 the orchestrator ff-merges and pushes to an unprotected `main` → `images` pushes
the image without waiting for `ci` (AG-02). Every step is reachable; the first one depends on the model following
injected text, which no control here prevents, only lowers (AG-09). Ends at a **published image**.

**C2 — Poisoned build tool to the owner's credentials** (supply chain attack, data leakage). Attacker: a maintainer or
hijacker of a tool fetched at build time (a pre-commit hook repo retagged, a docs dependency, a Maven plugin). L4 the
tool runs in an agent's shell as the owner's user (AG-12) → reads the `.env` next to the main checkout (AG-06) and uses
the owner's `gh` login, which holds admin on the repository and the `workflow` scope (AG-05) → sends data over the
network, which nothing restricts, or changes the repository's settings. Every step is reachable once the poisoned
release is fetched; the Dependabot cooldown and pins shrink that window. Ends at **the owner's data and credentials**.
The product-side half of this boundary (dependencies, Actions, images, registry) belongs to
[`threat-model.md`](threat-model.md).

**C3 — Tenancy regression to `main`** (goal-misalignment cascade: "done" drifts from the goal). Attacker: none needed;
an agent's honest mistake suffices. L3 an agent changes tenancy code in its worktree → L6 the commit hook checks the
main checkout's tree (AG-01) → L5 the agent reports "verified" from a run that did not cover the Keycloak path (AG-08)
→ the orchestrator merges without re-running → CI's `verify` runs the RLS suites and the Go cross-tenant tests but
excludes every Keycloak-tagged test (`pom.xml:61`, `scripts/hooks/isolation-check.sh:10`). The half of the chain up to
the merge is routine: agents of the eighth to tenth rounds ran the checks by hand because the hook did not
(`docs/wp/FOLLOW-UPS.md:947-956`); what stops the chain today is that discipline. Ends at **a pushed commit** that a
production academy would run.

**C4 — Subagent to orchestrator to every later agent** (lateral movement, privilege escalation). Attacker: a
compromised WP agent (through C1 or C2). L4 the agent writes outside its worktree: into the main checkout's
`CLAUDE.md`, a skill, the hook script, or moves a ref in the shared `.git` (AG-13) → L7 the orchestrator's session and
every agent it starts load those files; the hook runs the edited script for all sessions → L6 later commits are gated by
the attacker's version. Every step is reachable with the reach recorded under [Verification](#verification); *to
verify* is whether a permission prompt in the owner's local settings would stop a write outside the worktree. Ends at
**every later pushed commit**.

## Step 4 — Risk assessment

| Id | Title | L | I | Rating |
|---|---|---|---|---|
| AG-01 | The commit gate checks the session's checkout, and CI runs no Keycloak-tagged test | 2 | 3 | **High 6** |
| AG-02 | Commits and ref changes outside a parsed `git commit` / `git push` are ungated; `main` is unprotected | 2 | 3 | **High 6** |
| AG-03 | Secret scanning skips the Markdown agents write and the public site publishes | 2 | 3 | **High 6** |
| AG-04 | Guardrails and instruction files change in unreviewed commits | 2 | 3 | **High 6** |
| AG-05 | Agents act with the owner's identity, including an admin `gh` login | 2 | 3 | **High 6** |
| AG-06 | The owner's `.env` is readable by every agent; no committed permission rule | 2 | 2 | Medium 4 |
| AG-07 | Destructive commands on the owner's stack and volumes are not blocked | 2 | 2 | Medium 4 |
| AG-08 | Agents' "verified" claims reach `main`, images and Pages before an independent run | 2 | 2 | Medium 4 |
| AG-09 | Instructions in tool output and fetched content | 2 | 2 | Medium 4 |
| AG-10 | No durable record of what agents ran or what the gate decided | 2 | 2 | Medium 4 |
| AG-11 | Vendored third-party skills have no integrity record | 1 | 3 | Medium 3 |
| AG-12 | Build tools fetched by tag or without checksum run with the owner's rights | 1 | 3 | Medium 3 |
| AG-13 | One `.git` for all worktrees: an agent can move `main` or another branch | 1 | 3 | Medium 3 |
| AG-14 | The hook allows every command when `jq` is missing | 1 | 3 | Medium 3 |
| AG-15 | Connectors unrelated to the build are loaded into build sessions | 1 | 2 | Low 2 |
| AG-16 | The orchestrator's persistent memory sits outside the repository (*to verify*) | 1 | 2 | Low 2 |

## Findings

Controls are sized as work items and prefer enforcement (a permission rule, a hook, a CI check, a checksum) over a
written rule. Two limits apply to all of them: every agent acts as the owner (AG-05), so a GitHub-side control binds
agents only once they use a narrower credential; and a Claude Code deny rule for Bash matches the command text, so it
stops the plain form of a command and mistakes, not a determined agent, while the file that holds the rules is itself a
guarded path (AG-04). The operating system sandbox is the layer that would enforce (*to verify* in the owner's version).
This package changes no control; wave 2 takes the High and Medium findings.

### AG-01 — The commit gate checks the session's checkout, not the commit's worktree (High 6: L2 × I3)
- **Evidence.** `.claude/hooks/tenancy-gate.sh:144-149` takes the directory from the hook input's `cwd` and runs
  `scripts/hooks/isolation-check.sh` at that tree's top level; a `cd` or `git -C` inside the command only moves the
  parser past it (`:58-62`), it does not choose the tree. The comment at `:6` ("a worktree included") holds only for a
  session whose own directory is the worktree. Consistent with the WP118 handover
  (`docs/wp/WP118-finance-service-go-foundation.md:164`), `docs/HANDOVER.md:187-191` and
  `docs/wp/FOLLOW-UPS.md:947-956`; what `cwd` holds for a subagent is harness behaviour, not read here. CI does not
  cover the gap: `pom.xml:61` excludes the `keycloak` tag from `verify`, and `scripts/hooks/isolation-check.sh:10` says
  so. Eleven test classes carry that tag (cross-tenant access through real Keycloak, login hardening, refresh-token
  rotation, temporary passwords, security events, token audience in all three Java services); CI still runs the RLS
  suites, the role-matrix tests and the Go cross-tenant tests, so the gap is the path through a real Keycloak login,
  which only the hook or a hand run exercises.
- **Control (one work item).** (a) A CI job that runs `-Pkeycloak-it` for the three Java services on every push and
  pull request (the runner has Docker for Testcontainers). (b) The hook resolves the target tree from a leading `cd` or
  `git -C` in the command and runs the gate there, with cases added to `scripts/hooks/tenancy-gate.test.sh`.

### AG-02 — Commits and ref changes outside a parsed `git commit` / `git push` are ungated; `main` is unprotected (High 6: L2 × I3)
- **Evidence.** The hook classifies only the `commit` and `push` subcommands (`.claude/hooks/tenancy-gate.sh:58-66`);
  merges, cherry-picks, rebases and ref updates create or move commits without a gate. It does not read the contents of
  a script or recipe the command runs (`:41-55`); WP128's commits through a helper script ran no check
  (`.claude/skills/wp-round/SKILL.md:116-117`). The matcher is `Bash` only (`.claude/settings.json:5`). On GitHub,
  `main` is not protected and has no rulesets (`gh api`, 2026-11-28), so whatever is pushed lands; `images` pushes on
  every push to `main` that touches code (`.github/workflows/images.yml:15-18,59`) without waiting for `ci`.
- **Control (one work item plus an owner decision; needs AG-05 first to bind agents).** A ruleset on `main`: no force
  push, no deletion, required checks (`ci`'s backend, scripts, secrets scan, docs site and the AG-01 job). The
  orchestrator then pushes the WP branch, waits for green and ff-merges (*to verify*: that a ruleset's required checks
  also refuse a direct push of an unchecked commit). `images` runs on a green `ci` (`workflow_run`) instead of its own
  push trigger.

### AG-03 — Secret scanning skips the Markdown agents write and the public site publishes (High 6: L2 × I3)
- **Evidence.** `.gitleaks.toml:6-12` allowlists every path matching `docs/.*\.md$` and `\.claude/skills/.*`; the
  pre-commit hook and CI's gitleaks action read the same file. Trivy's secret scan in CI
  (`.github/workflows/ci.yml:268`) does not report secrets in `.md` files either. Probes with a fabricated GitHub token
  in a scratch copy (never staged): repository config on a `docs/*.md` file exit 0 (missed), same config without the
  path allowlist exit 1 (found); Trivy 0.76.1 reported the token in a `.txt` file and not in the `.md` files. A scan of
  today's `docs/` and `.claude/skills/` without the path allowlist found **0** findings, so the allowlist protects no
  current fixture. Agents write handovers with pasted command output in every package, and `pages` publishes `docs/`.
- **Control (small work item).** Drop the two path entries from `.gitleaks.toml` (keep the `change-me-` regex; handle a
  future fixture with a fingerprint in `.gitleaksignore`), and add a test in `scripts/tests` that fails when the
  allowlist names `docs/` or `.claude/` wholesale.

### AG-04 — Guardrails and instruction files change in unreviewed commits (High 6: L2 × I3)
- **Evidence.** The hook is live code in the main checkout (`.claude/settings.json:9`), and the gate it runs is the
  script in the checked tree (`.claude/hooks/tenancy-gate.sh:146-149`); the committed test shows a stub script decides
  the outcome (`scripts/hooks/tenancy-gate.test.sh:78-100`). `CLAUDE.md`, skills, `.gitleaks.toml`,
  `.pre-commit-config.yaml` and workflows travel in ordinary commits. There is no `CODEOWNERS`, the merge steps have no
  diff review of these paths (`.claude/skills/wp-round/SKILL.md:58-65`), and "never weaken a quality gate" is written
  only (`.claude/skills/work-package/SKILL.md:23`). The pressure exists: the gate times out under load
  (`.claude/skills/wp-round/SKILL.md:83-86`).
- **Control (one work item).** A tripwire first: a CI job `guarded-paths` that lists every change to `.claude/**`,
  `CLAUDE.md`, `scripts/hooks/**`, `.gitleaks.toml`, `.pre-commit-config.yaml` and `.github/**` in the run summary and
  fails unless the commit names an owner decision number that exists in `docs/wp/FOLLOW-UPS.md` (self-declared, so it
  catches mistakes and makes a change visible, it does not stop a determined agent); a merge step in `wp-round` that
  shows the owner the branch's changes to those paths. Enforcement once AG-05 and AG-02 are in place: `CODEOWNERS` with
  required review by the owner's own account for the same paths.

### AG-05 — Agents act with the owner's identity, including an admin `gh` login (High 6: L2 × I3)
- **Evidence.** `gh auth status` (scopes only read): the login every agent's shell uses has the scopes `repo`,
  `workflow`, `gist` and `read:org`; `gh api` reports admin permission on the repository. Commits carry the owner as
  author (`git log`). So an agent can push workflow files, change repository settings and rulesets, and approve as the
  owner; GitHub cannot tell the two apart, which is why AG-02 and AG-04's enforced controls depend on this one (ASI03
  Identity and Privilege Abuse).
- **Control (one work item plus an owner decision).** A separate, narrower credential for agent sessions: a
  fine-grained token limited to this repository with contents write and no administration or workflow permission (or no
  push at all for WP agents, with only the orchestrator pushing), set for agent sessions instead of the owner's login;
  the owner's admin login stays with the owner. *To verify*: how the harness gives subagents a different `gh`
  environment than the owner's session.

### AG-06 — The owner's `.env` is readable by every agent; no committed permission rule (Medium 4: L2 × I2)
- **Evidence.** `.claude/settings.json:1-17` has no `permissions` block. The `.env` next to the main checkout exists and
  is readable by the owner's user, which every agent runs as (`stat`, value not read); worktrees are siblings under
  `~/code/hoops-wt/`. "Agents do not read the owner's `.env`" is written (`.claude/skills/wp-round/SKILL.md:100-103`,
  every brief's Working rules). Container inspection and resolved compose configuration would also show the stack's
  credentials without opening the file (reasoned, not run). The `--no-verify` refusal the process relies on
  (`.claude/skills/wp-round/SKILL.md:92-94`) is likewise not in the committed settings: *to verify* where it is
  enforced. Impact is Medium because the local `.env` holds local stack credentials, not production ones.
- **Control (small work item).** A committed `permissions.deny` in `.claude/settings.json` for reads of `.env` files
  other than `.env.example` and for `git commit --no-verify` / `-n`, the Claude Code sandbox's filesystem deny for the
  same paths if the owner's version supports it (*to verify*), and a test in `scripts/tests` that the deny list stays.
  Limits as stated above the findings.

### AG-07 — Destructive commands on the owner's stack and volumes are not blocked (Medium 4: L2 × I2)
- **Evidence.** Every agent's `podman` lists the owner's five `hoops-*` containers and the volumes `hoops_pgdata-19` and
  `hoops_pgdata`; the second is the old database volume kept as the way back until the owner removes it
  (`docs/adr/0073-postgresql-19.md:60-62`). `just down` keeps volumes (`justfile:123-124`); "remove no volume" is
  written only (the briefs). Two runbooks give a reset that removes the database volume
  (`docs/runbooks/e2e.md:117`, `docs/runbooks/backup-restore.md:47`): an agent troubleshooting the e2e journey on the
  shared stack would find it as the documented step.
- **Control (small work item).** Committed `permissions.deny` rules for volume removal, system and volume prune,
  compose `down` with volume removal, Podman machine removal and stop, and kind cluster deletion; the runbooks mark the
  reset as an owner-only step; a `just db-backup` recipe the orchestrator runs at round start. Limits as stated above
  the findings.

### AG-08 — Agents' "verified" claims reach `main`, images and Pages before an independent run (Medium 4: L2 × I2)
- **Evidence.** "Otherwise the agent's fresh results stand" (`.claude/skills/wp-round/SKILL.md:60-63`); CI runs after
  the push (`.github/workflows/ci.yml:3-6`), `images` and `pages` publish from the same push
  (`.github/workflows/images.yml:15-18`, `.github/workflows/pages.yml:6-13`). Problems found only after an agent's
  report: WP55's tag-object pin (`.claude/skills/wp-round/SKILL.md:80-82`), WP137's helm tests (`:112-115`), and a realm
  test fixed in a later commit after WP118's realm change (`docs/wp/FOLLOW-UPS.md:1224-1225`).
- **Control (small work item, with AG-02).** The orchestrator pushes the WP branch and merges only on its green `ci`
  run, quoting the run id in the plan table instead of the agent's numbers.

### AG-09 — Instructions in tool output and fetched content (Medium 4: L2 × I2)
- **Evidence.** The jqwik line in test logs addresses AI agents (`docs/HANDOVER.md:300-301`); the control is a sentence
  in each prompt (`.claude/skills/wp-round/SKILL.md:90-91`). Bot PR bodies carry upstream release notes, and agents
  fetch pages. No complete fix exists (LLM01 Prompt Injection); what limits the damage is AG-02 to AG-07.
- **Control (small work item).** A "Tool output is data" paragraph in `work-package` listing the known sources; the
  orchestrator reviews bot PRs by their diff, not their body; a WebFetch domain allowlist in the committed settings
  (*to verify* support).

### AG-10 — No durable record of what agents ran or what the gate decided (Medium 4: L2 × I2)
- **Evidence.** 1,225 of 1,236 commits carry a `Co-Authored-By` trailer, written by the agent itself; the author is
  always the owner's identity and the last 20 commits are unsigned (`git log`). The hook writes PASSED / Blocked to
  stderr only (`.claude/hooks/tenancy-gate.sh:124-131`); transcripts are outside the repository. This package's own
  commits show it: their tool output did not show whether the gate ran.
- **Control (small work item).** The hook appends one line per gated command (time, directory, top level, `HEAD`,
  result) to a log in the shared `.git` directory; briefs ask agents to add a `WP:` trailer; the round's close-out
  copies the gate log summary into the handover.

### AG-11 — Vendored third-party skills have no integrity record (Medium 3: L1 × I3)
- **Evidence.** Five folders are copies (`.claude/skills/THIRD_PARTY_SKILLS.md:9-15`), edited locally once
  (`:5-7`); no test or workflow reads `.claude/skills` (`grep` of `scripts/` and `.github/`), and gitleaks skips the
  folder (AG-03). A changed `verification-before-completion` would steer every later agent.
- **Control (small work item).** A checksum per vendored folder in `.claude/skills/THIRD_PARTY_SKILLS.md` (or a sibling
  file) and a test in `scripts/tests` that recomputes them; a change updates the checksum and the table row in the same
  commit.

### AG-12 — Build tools fetched by tag or without checksum run with the owner's rights (Medium 3: L1 × I3)
- **Evidence.** Pre-commit repos are pinned by tag (`.pre-commit-config.yaml:3,7`) and run at every agent commit; the
  docs toolchain is pinned by version without hashes (`config/docs/requirements.txt:5-15`) and is installed by
  `just docs-build` in an agent's shell; the Maven wrapper has no distribution checksum
  (`.mvn/wrapper/maven-wrapper.properties:1-3`). Actions are SHA-pinned and tested (`scripts/tests/test_workflows.py:49`).
- **Control (small work item).** Pre-commit `rev:` as commit SHAs with the tag as a comment, `--require-hashes` for the
  docs requirements, `distributionSha256Sum` in the wrapper properties, and tests that keep each pinned.

### AG-13 — One `.git` for all worktrees: an agent can move `main` or another branch (Medium 3: L1 × I3)
- **Evidence.** `git rev-parse --git-common-dir` in this worktree prints the main checkout's `.git`; refs and git hooks
  are shared. The orchestrator ff-merges and pushes `main` from that store (`.claude/skills/wp-round/SKILL.md:64-65`).
  A ref move is not a `commit` or `push` (AG-02). The effect is reasoned from git's worktree design, not exercised.
- **Control (small work item).** At merge, the orchestrator checks that local `main` equals `origin/main` before the
  ff-merge and pushes the explicit commit id; the AG-02 ruleset refuses force pushes.

### AG-14 — The hook allows every command when `jq` is missing (Medium 3: L1 × I3)
- **Evidence.** `.claude/hooks/tenancy-gate.sh:8-12`: without `set -e`, a missing `jq` leaves the command empty and the
  hook exits 0; `scripts/doctor.sh` does not check for `jq`. macOS ships one, so the likelihood is low; the impact is
  the same as AG-01's (no isolation check before a commit, and no role check before a push).
- **Control (tiny work item).** Exit 2 when `jq` is absent, a test case for it, and a doctor check.

### AG-15 — Connectors unrelated to the build are loaded into build sessions (Low 2: L1 × I2)
- **Evidence.** Session observation (WP149): the session offered account-level connectors for personal productivity
  with write actions, and a configured GitHub MCP server that failed to start; none is configured in the repository.
  Impact is the owner's personal data, not the product's.
- **Control (small work item).** A project-level deny of connector tools the build does not use, in the committed
  settings (*to verify* the setting's reach over account connectors).

### AG-16 — The orchestrator's persistent memory sits outside the repository (Low 2: L1 × I2, *to verify*)
- **Evidence.** The close-out updates the orchestrator's memory note (`.claude/skills/wp-round/SKILL.md:130`); it is
  carried into later sessions and not versioned or reviewed here. Its content was not read.
- **Control (to verify first).** Keep in memory only what points into the repository; the round's close-out diffs it.

## Step 6 — Implementation and monitoring

- Wave 2 of the eleventh round takes the five High and nine Medium findings; the two Low ones go to
  `docs/wp/FOLLOW-UPS.md` through this package's handover. Order: AG-05 before AG-02 and AG-04, whose enforced forms
  depend on it. A finding closes when its control is enforced and tested, not when it is written down.
- Monitoring that exists after those controls: the AG-01 and AG-04 CI jobs on every push, the gate log of AG-10, the
  checksum test of AG-11, and the ruleset of AG-02 (GitHub audit log).
- WP150 adds a keep-current rule for the threat models to `wp-round` (ADR-0077); this document is kept current under it.

## Before an AI feature enters the product

The product has no model call today. A feature that adds one (for example a coach's assistant over match statistics)
must first:

1. Get an ADR and a MAESTRO pass of its own: Layers 1 and 2 stop being thin (model provider and data residency for
   minors' data; any retrieval store is a tenant table under RLS, `tenant_id` + `FORCE ROW LEVEL SECURITY`).
2. Run with the caller's tenant and role only: the model's tools are the application's use cases behind
   `@RequiresTenantRole` and `Authz`, never a database or admin credential (LLM03 Excessive Agency).
3. Treat model output as untrusted input before any sink (LLM10 Improper Output Handling), and fence retrieved records
   as data (LLM01 Prompt Injection), with tests that plant instructions in player notes.
4. Keep personal and health data out of prompts unless the privacy model allows it, and log no prompt
   ([`privacy-threat-model.md`](privacy-threat-model.md)).
5. Cap tokens, calls and cost per tenant (LLM06 Unbounded Consumption), and record each model call in the audit trail
   (Layer 5).

## Verification

Read-only, 2026-11-28, in the worktree `wp149-agentic-threat-model-build-system` at cc4fb3e2:

- Read: `.claude/settings.json`, `.claude/hooks/tenancy-gate.sh`, `scripts/hooks/*`, `.pre-commit-config.yaml`,
  `.gitleaks.toml`, `.github/workflows/*.yml`, `.github/actions/image-publish/action.yml`, `.github/dependabot.yml`,
  the skills `wp-round`, `work-package`, `verification-before-completion`, `owasp-security`,
  `.claude/skills/THIRD_PARTY_SKILLS.md`.
- `gh api repos/<owner>/hoops-academy/branches/main` → `protected: false`; `…/rulesets` → `[]`; repository
  `visibility: public`, permissions `admin: true`; `gh variable list` → `IMAGE_REGISTRY` set; Pages built by workflow.
  `gh auth status` → scopes `gist`, `read:org`, `repo`, `workflow` (token not displayed or recorded).
- `git rev-parse --git-common-dir` → the main checkout's `.git`; `.git/hooks/pre-commit` generated by pre-commit.
- `git rev-list --count HEAD` → 1236; commits with a `Co-Authored-By` trailer → 1225; `git log -20 --format=%G?` → 20 ×
  `N`.
- `podman ps` → `hoops-redpanda`, `hoops-mailhog`, `hoops-postgres`, `hoops-keycloak`, `hoops-nginx`; `podman volume
  ls` → `hoops_pgdata-19`, `hoops_pgdata`, `hoops_redpanda-data` (other names not recorded).
- `stat` of the main checkout's `.env` → exists, mode `-rw-r--r--` (content not read).
- `grep` for `@Tag("keycloak")` under `services/` and `libs/` → eleven test classes.
- gitleaks 8.30.1 with the repository config minus its path allowlist over `docs/` and `.claude/skills/` → 0 findings.
  Scratch probes with a fabricated token (never staged, deleted after): repository config on a `docs/*.md` copy → exit
  0; without the path allowlist → exit 1; Trivy 0.76.1 `--scanners secret` → reports the `.txt` copy, not the `.md`
  copies.
- Not verified: where the session's `--no-verify` refusal and any deny rules are configured (local and user settings
  not read); the `cwd` a subagent's hook receives; whether GitHub rulesets refuse a direct push without checks; how
  subagents could get a separate `gh` credential; the exact jqwik wording (in the owner's Maven repository, not read).
