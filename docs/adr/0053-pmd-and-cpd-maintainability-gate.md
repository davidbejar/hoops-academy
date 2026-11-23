# ADR-0053: PMD and CPD maintainability gate in `verify`, thresholds from the code of 2026-11-15

- Status: Accepted
- Date: 2026-11-15
- Related: decision 101 of 2026-11-15 (owner), WP113, ADR-0045 (acceptances with a reason), `docs/quality/pmd.md`,
  `docs/quality/mutation.md`, `config/pmd/`

## Context
The gates in `verify` and CI cover bugs and security (SpotBugs + find-sec-bugs, CodeQL, Semgrep, ZAP), tests (JaCoCo,
PIT) and layering (ArchUnit). Nothing measured maintainability: a method could grow to any length or nesting, a class
to any size, and a block could be copied between two use cases without anyone noticing. Most of the Java of the
coming rounds is written by agents, so the limits have to be in the build, where a breach fails the agent's own
`just test`, not in a review.

SonarQube was considered and not chosen: it needs a server or an external service; its findings largely duplicate
CodeQL and Semgrep, which already gate security; and it brings a second coverage gate next to JaCoCo. To be looked at
again once the Go and Rust services of ADR-0051 exist (PMD and CPD cover Java only; CPD itself can read Go and Rust).

## Decision
1. **Tool.** `maven-pmd-plugin` 3.28.0 with PMD 7.29.0 pinned in the root pom (`pmd-plugin.version`, `pmd.version`;
   the plugin ships 7.17), `targetJdk` = `maven.compiler.release` (25; PMD 7.29 parses the whole main code of 2026-11-15
   with no processing error). Goals `check` (execution `pmd-check`) and `cpd-check` (execution `cpd-check`), bound to
   `verify` in every module through the root `<plugins>`, as SpotBugs is. `failurePriority` 5: every rule of the
   ruleset fails the build, whatever its priority.
2. **Scope.** Main code of every Java module. **Tests are out**: test code is built for reading one scenario top to
   bottom, so long methods, many literals and repeated arrange blocks are normal there, and a gate on them would push
   toward helpers that hide what a test checks. Generated code is excluded (`target/generated-sources`); today no
   module generates Java (the Dart clients are generated outside Maven).
3. **Ruleset** (`config/pmd/ruleset.xml`): single rules, never a whole category, so a PMD upgrade cannot widen the gate
   by itself.

   | Rule | Measures | Fails at | Measured max (2026-11-15) |
   |---|---|---|---|
   | `CyclomaticComplexity` | branches of a method / sum of a class | method ≥ 15, class ≥ 65 | 17 (a decoder switch), class 60 (`Match`) |
   | `CognitiveComplexity` | nesting-weighted branches of a method | ≥ 15 | 18 → 14 after the WP113 refactor |
   | `NcssCount` | statements of a method / class | method ≥ 30, class ≥ 150 | 27, class 137 (`Match`) |
   | `ExcessiveParameterList` | parameters, constructors included | ≥ 12 | 17 (`Match.restore`), 12 (`CreatePlayer`) |
   | `UnusedPrivateField`, `UnusedPrivateMethod`, `UnusedLocalVariable`, `UnnecessaryImport` | unused code | any | 10 unused locals, 4 imports: fixed |
   | `EmptyCatchBlock` | swallowed exception (a commented block is accepted) | any | 0 |
   | CPD | a copy of ≥ 100 tokens (PMD's default) inside one module | any | 108 (outbox insert: fixed), 103 (accepted) |

   Method limits sit at the usual values with few exceptions; class and size limits just above today's maximum, so
   they stop growth without forcing a rewrite. Each rule reports when the value *reaches* the threshold.
4. **Acceptances** (ADR-0045 applied): `config/pmd/exclude-pmd.properties` (class = rules) and
   `config/pmd/exclude-cpd.properties` (the classes of one duplication per line), each entry under a comment with its
   reason, reviewed with the other baselines each round. No `@SuppressWarnings("PMD…")` and no `// NOPMD` in the code:
   the records live in the acceptance files, as for the other gates. The filter format has no expiry; an entry that
   waits for a fix names the work package in its comment. `scripts/tests/test_pmd_exclusions.py` keeps the files honest
   (a reason above every entry, every class exists, PMD entries name ruleset rules, no blank line in the CPD file:
   the plugin reads a blank line as an empty class name that matches every path and silently accepts every
   duplication inside one file).
5. **Changing a threshold**: only in a pull request that changes `config/pmd/ruleset.xml`, `docs/quality/pmd.md` (new
   measured maxima) and this ADR's table together, with the reason. Raising a limit to let one class through is not a
   reason: refactor it, or accept that one class with a reason. Lowering a limit is welcome when the code allows it.

## Consequences
- `verify` takes a few seconds more (about 3–6 s wall on the 2-CPU VM, numbers in `docs/quality/pmd.md`); CI's
  backend job runs it through `./mvnw verify` with no workflow change, and so does the `security-scan` job.
- Agents of later rounds see a `PMD Failure:` / `CPD Failure:` line with the class, line, rule and value; the fix is in
  `docs/quality/pmd.md` ("When the gate fails").
- CPD runs per module: a copy *between* services (both `PatchBody` classes, for instance) is not found. An aggregate
  CPD over the reactor would find it, but the services are deliberately independent, so a shared copy is often the
  right call; left for a later look.
- An entry in `exclude-pmd.properties` covers its whole class for that rule; a second offending method in the same
  class goes through. The comment names the method, and the review of the baselines catches it.
- `ExcessiveParameterList` counts constructors, so a CDI use case may take at most 11 collaborators; at 12 it is time
  to split it (`CreatePlayer` is accepted at 12 and may not take a 13th).

## Amendment 2026-11-24 (decision 107, WP134): a copy of the tenant-isolation rule between modules is not accepted
ADR-0066 takes the "later look" above for one rule: the membership rule that builds every request's authorisation
context lived in core, game and athlete. It is now written once in `com.hoopsacademy.common.authz` with one table test
and one PIT entry; a copy of a tenant-isolation rule between Java modules is not accepted (the Go copy in
finance-service is a language decision, ADR-0055). Other copies between modules keep the rule above.
