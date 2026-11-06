# Session handover (updated 2026-11-06 evening — third round WP43–WP51 merged, `main` green)

Read `CLAUDE.md` first. This page is the short "where are we" for a fresh session; the detail is in the linked files.
The original request is `docs/SPEC.md` (verbatim); the approved plan with its status box is `docs/PLAN.md`; what was built
versus the spec is `docs/conformance.md`; the three plans of 2026-11-05 and 2026-11-06, the product owner's decisions
1–33 and the backlog are in `docs/wp/FOLLOW-UPS.md`. The former OneDrive planning folder
(`.../Code/Claude/projects/dummy-project2`) is archived and must not be written to.

## State
- Built and committed: all v1 work packages (WP0–WP20; WP19 events/Redpanda not built, v2), WP21–WP25 (e-mail logins,
  super admin manages academy admins, temporary password at first sign-in), the twelve WPs of the 2026-11-05 plan
  (WP26–WP37), the five of the first 2026-11-06 plan (WP38–WP42; details in FOLLOW-UPS "Resolved") and the nine of the
  third round, merged into `main` on 2026-11-06 after the briefs (6042547) in this order:
  - WP50 (71e459a) the 31 GitHub Actions refs in the four workflows pinned to commit SHAs (`@<sha> # <tag>`).
  - WP48 (f8cddec) injury edit dialog in the health screen; emptied fields named in `clear`.
  - WP43 (79b16af) `json-schema-validator` stays 2.0.8: `swagger-request-validator` 3.0.0 is built on networknt 2.x;
    Dependabot ignores that major, PR #3 closed; the 3.x migration is recorded in the handover.
  - WP45 (a5036b0) `clear` on `UpdateMatchRequest` (`venue`), demo mock honours it (game 2.2.0); a5036b0 itself is the
    orchestrator's `pubspec.lock` update.
  - WP46 (feb3fe3) Redis ACL user `ratelimit` for the rate-limit store, per-second burst caps next to the per-minute
    limits, Envoy Gateway descriptor bug worked around with a `path: /` selector (ADR-0033 amendment; chart 0.4.0; new
    `.env` key `RATELIMIT_REDIS_PASSWORD`).
  - WP44 (a99c211) `clear` on five core update requests, `MergePatch` → `PatchBody` (ADR-0032; core 2.7.0).
  - WP51 (a67326d) round procedure as `.claude/skills/wp-round` + brief template; CLAUDE.md pointer; the conventions
    below trimmed.
  - WP47 (fbb71ef) demo mock parity: one roster per academy shared by the core, athlete and game mocks, role filtering
    per the authz matrix (`mock_authz.dart`), data for Club Norte.
  - WP49 (b2ef8d5) `apps/web` formatted with `dart format` (80 columns), `just web-format(-check)`, check in CI;
    lint `curly_braces_in_flow_control_structures` disabled.
  Also today: Dependabot PRs #1 actions (92695b1), #4 `cupertino_icons` 2.0 (d9ef533) and #2 Maven minor/patch
  (573dda3) merged; Dependabot config (625a5f9), AGPL-3.0 (20f1921).
  Contract versions now: **core 2.7.0, game 2.2.0, athlete 2.1.0, common 1.1.0**; Helm chart **0.4.0**.
- Tests: fresh local `./mvnw -B -ntp -T 1C clean verify` after WP44 rebased on WP45: JVM contracts 157, common-quarkus
  186, core 784, game 259, athlete 653 = **2,039 tests**, 0 failures, every coverage gate met; plus the `e2e` module's
  25 (4 `MailSinkTest` run, the 21 journey tests skipped without `e2e.baseUrl`). `flutter test` after WP49: **668
  passed**, analyze clean, `just web-format-check` clean. Mutation: core 498/499 (99.8 %, WP44), game 399/401 (99.5 %,
  WP43/WP45), athlete 430/430 (WP39); baselines 95/95/95/100. Chart tests: 85 checks, kubeconform 147/147 (WP46).
- e2e: `JourneyTest` 21/21 on compose (CI `e2e` on every push) and 21/21 on kind with the mail checks (WP42).
  `ratelimit-check.sh` incl. the `acl` and `redis-down` modes passed on kind with 1 Envoy replica (WP46); 2 replicas and
  `tilt ci` were last run before WP46 (WP40 / WP42).
- CI on `main`: `ci`, `e2e` and `images` green on 71e459a (WP50, runs 42169267974, 42169267964, 42169268009), a99c211
  (WP44, 42175415217, 42175415224, 42175415215) and fbb71ef (WP47, 42177864173, 42177864168, 42177864076);
  and b2ef8d5 (WP49, 42180256976, 42180256896, 42180256997): `main` is green end to end.
- Dependabot: weekly grouped version updates (Maven with Quarkus in its own group, pub, GitHub Actions; Monday 06:00
  Europe/Madrid), automated security fixes, actions bumped as SHA + tag comment; the maven block ignores
  `com.networknt:json-schema-validator` semver-major updates (WP43). No Dependabot PR is open.
- Browser checks: `apps/web/tool/web_smoke.sh` green in mock mode in WP47; `--real` mode and `browser_login_check.py
  --set-new-password` last green on 2026-11-02 / WP25. Lighthouse, airplane-mode cold start and chromedriver in CI are
  still open.
- GitHub: `davidbejar/hoops-academy` (public, AGPL-3.0, description and topics set), branch `main`. Repository variable
  `IMAGE_REGISTRY=ghcr.io/davidbejar/hoops-academy`; secret `NVD_API_KEY` (valid since 2026-11-02). The four ghcr.io
  packages (core-service, game-service, athlete-service, web) are **public** (decision 9); a cluster pulls them without
  `global.imagePullSecrets`.

## Pending
1. Nothing is blocking. `RATELIMIT_REDIS_PASSWORD` (chart 0.4.0) is already in the local `.env`.
2. **Review the Dependabot PRs as they arrive** (weekly, Monday). A future json-schema-validator major is ignored on
   purpose (WP43); re-check when `swagger-request-validator` moves to networknt 3.x.
3. Non-blocking: the dependency-check NVD cache is still saved `if: always()` (if the job takes more than 40 min,
   `gh cache delete` the `nvd-Linux-*` key it restored; rerun on NVD 503); the `dependency-check-report` findings below
   the CVSS 7 gate were never reviewed.

## Working conventions learned the hard way
- **Parallel sessions and rounds of work packages:** follow `.claude/skills/wp-round` (one worktree per session or WP
  under `$HOME`, never switch branches in a shared checkout; `gitleaks protect --staged` + `git commit --no-verify` with
  explicit paths; waves, ownership, ADR numbers, merge protocol and traps).
- Claude Code hook (`.claude/settings.json` → `.claude/hooks/tenancy-gate.sh`, PreToolUse on Bash): before Claude
  runs `git commit` it runs `just isolation-check` (academy A logs in through real Keycloak and cannot read academy B,
  ~40 s); before `git push`, `just db-role-check` (no service connects as a table owner, superuser or BYPASSRLS role,
  ~40 s). A failure blocks the git command; `--no-verify` does not skip it. Both need Podman. Commits a person makes in a
  terminal are not gated: run the two `just` recipes yourself. Review or disable the hook with `/hooks`.
- `flutter drive` on web needs `-d web-server` (`-d chrome` hangs forever); chromedriver matching Chrome must be on PATH
  (Homebrew cask is disabled; download from Chrome for Testing and `xattr -d com.apple.quarantine`).
- Workflows: run `actionlint .github/workflows/*.yml` before pushing. Goldens are macOS-exact; CI uses
  `GOLDEN_DIFF_TOLERANCE=0.06`. ZAP acceptances live in `.zap/baseline.conf` with `[alert=..][url=..]` scoping (`scripts/zap-gate.py`).
- `.env` needs `RATELIMIT_REDIS_PASSWORD` since chart 0.4.0 (WP46); `deploy/kind/secrets.sh` stops without it.
- Realm changes need a Keycloak re-import: `just down && podman volume rm hoops_pgdata && just up && just seed-users`.
- **Podman VM clock drift.** After the host sleeps (also in maintenance sleep / dark wake), the Podman machine's clock
  falls behind or stalls (16–59 min behind on 2026-11-06), so Keycloak tokens look expired. Since e6a8847 the hook
  scripts (`scripts/hooks/_common.sh`) step the VM clock before each check; by hand outside the hooks:
  `podman machine ssh "sudo date -u -s @$(date +%s)"`.

## Next candidates without a work package (see FOLLOW-UPS.md for the full list)
- Web: a match edit dialog (`MatchesRepository.update` is ready), removing a jersey (dialog requires a value), member
  personal-data and academy contact edits (their `clear` lists are unused by the app).
- Demo mock: role-filtered core reads, a demo COACH on the staff list, persistence across reloads.
- Gateway: re-run `ratelimit-check.sh` with 2 Envoy replicas and `tilt ci` on chart 0.4.0, exercise the
  controller-restart branch of `deploy/kind/up.sh`; report the Envoy Gateway descriptor collision upstream.
- Keycloak CSP hardening via realm `browserSecurityHeaders` (removes the accepted ZAP alerts under `/auth/realms/`).
- Lighthouse installability and airplane-mode cold start for the PWA; chromedriver in CI.
- Save the NVD cache on success only.
- v2: outbox + Redpanda (WP19), billing module on the existing seams, purge job (also for old audit rows).
