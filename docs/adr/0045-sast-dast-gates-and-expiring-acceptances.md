# ADR-0045: SAST and DAST gates in CI, with acceptances that carry a reason and an expiry

- Status: Accepted
- Date: 2026-11-06
- Related: decision 55 of 2026-11-06, WP83 (gates), WP84 (fixes the findings), WP17 / WP57 (ZAP baseline,
  `scripts/zap-gate.py`), WP50 (actions pinned to SHAs), ADR-0038, `docs/security/sast-dast.md`,
  `docs/security/review-2026-11.md` ("Round 5 SAST/DAST findings")

## Context
Until round 5 the only automated security checks were secrets (gitleaks), dependencies (dependency-check, trivy) and
a passive ZAP baseline of the public pages. Nothing read our own code for injection or authorization mistakes, and
nothing attacked the APIs. Decision 55 of 2026-11-06: all of CodeQL, Semgrep, SpotBugs with find-sec-bugs, a ZAP API
scan per service with a logged-in token in CI and one ZAP full scan by hand; WP84 fixes what they find. Every tool
produces false positives and findings that wait for a fix, so each gate needs a way to accept a finding that is
visible in review and does not silently last for ever.

## Decision
1. **What runs where.**
   - SpotBugs 4.10 + find-sec-bugs 1.14 in `verify` of every module (root pom): effort Max, threshold Medium, all
     bug categories, main classes. `just test` and the `backend` CI job run it.
   - CodeQL (`codeql.yml`): Java, suite `security-extended`, manual build of the main code only
     (`-Dmaven.test.skip=true`), on pushes to main, pull requests and weekly; SARIF to code scanning.
   - Semgrep (`semgrep.yml`): pinned image (tag and digest), registry rulesets `p/java` and `p/owasp-top-ten`, and the
     repository rules in `.semgrep/rules` with their tests (`semgrep --test`), on pushes, pull requests and weekly;
     SARIF to code scanning. Tests, generated clients and build output are not scanned (`.semgrepignore`).
   - ZAP API scan (`e2e.yml`, after the journeys): `zap-api-scan.py` per service, driven by
     `libs/contracts/openapi/<service>.yaml`, against nginx, as the platform super admin (PKCE sign-in by
     `scripts/zap-login.py`, token refreshed by `.zap/hooks/bearer_refresh.py`), ZAP's API policy with no rule switched
     off. The passive baseline (`ci.yml`) stays. The ZAP image is pinned by digest in both.
   - ZAP full scan (spider + active) of nginx, Keycloak and the web app: by hand, before a release or after a big
     change to the edge, documented in `docs/security/sast-dast.md`; not in CI (it needs a long, disposable stack).
2. **What fails the build.**
   - SpotBugs: any finding of rank Medium or higher not matched by `spotbugs-exclude.xml`.
   - CodeQL: a result with `security-severity` >= 7.0 (High, Critical) not accepted in `.github/codeql/accepted.json`.
   - Semgrep: a result of level `error` (rule severity ERROR) not accepted in `.semgrep/accepted.json`.
   - ZAP (baseline and API scans): a High or Medium alert instance not accepted in `.zap/baseline.conf` /
     `.zap/api-<service>.conf`.
   - Lower levels (CodeQL Medium/Low, Semgrep WARNING, ZAP Low/Informational) are reported and triaged into the
     security review, not gated.
   "New" for CodeQL means "not in the accepted file": the gate does not depend on GitHub's alert state, so it runs the
   same locally and in CI. Dismissing an alert in the Security tab keeps that tab tidy but does not open the gate.
3. **Acceptances.** One reviewed record per finding, next to the gate, changed only in a pull request:
   - SARIF gates (`scripts/sarif-gate.py`): entry = rule, path, fingerprint (hash of the flagged source line, so it
     survives code moving around it but not a change of that line), reason, expiry; reason and expiry are mandatory
     (exit 2 otherwise), the expiry at most six months ahead; after it the finding blocks again. Entries that match
     nothing are printed as STALE to be removed.
   - ZAP (`scripts/zap-gate.py`): an IGNORE line must carry a justification (exit 2 otherwise), may be narrowed with
     `[alert=…]` and `[url=…]`, and gets `[expires=YYYY-MM-DD]` when it waits for a fix. Acceptances never switch a
     ZAP rule off in the scan itself.
   - SpotBugs: `<Match>` entries with a comment; scoped to a class and bug pattern; a SECURITY pattern is never excluded
     globally. The filter format has no expiry: the exclusions are reviewed with the other baselines each round.
   - A finding that waits for a fix (not a false positive) is accepted only with an expiry no later than the date its
     fix is due, and is listed in the security review with its owner work package.
4. **Inline suppressions** (`// nosemgrep`, `@SuppressFBWarnings`, CodeQL comments) are not used: the record lives in
   the acceptance files, where a reviewer sees every one together.

## Consequences
- `verify` takes about half a minute more (SpotBugs; numbers in the WP83 handover). CodeQL and Semgrep run in their own
  workflows and do not slow the backend job.
- Registry rulesets and the CodeQL bundle change under us: the weekly runs surface new findings on unchanged code;
  they are triaged like any other.
- The API scan's super admin is not a member of any academy, so tenant endpoints answer 404 after authentication: the
  scan covers authentication, input handling up to the tenant check, the platform API and the edge, not the
  academy-internal logic (role-matrix tests and `just isolation-check` cover that).
- The API scan writes junk data into the stack it scans: run it only on a disposable stack (CI) or tell the people
  sharing a local one.
- Every action stays pinned to a commit SHA (WP50), the Semgrep and ZAP images to a digest.
