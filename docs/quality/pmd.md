# Maintainability gate (PMD and CPD)

Since WP113 (2026-11-15, ADR-0053) every `verify` runs PMD with a small repository ruleset and CPD (the copy-paste
detector) on the main code of every Java module, and fails on any finding the acceptance files do not list. Tests and
generated code are not checked. `just test`, `./mvnw verify` and CI's backend job run it; nothing to start by hand.

| What | Where |
|---|---|
| Ruleset and thresholds | `config/pmd/ruleset.xml` |
| Accepted PMD findings | `config/pmd/exclude-pmd.properties` (`<fully.qualified.Class>=<Rule>,...`) |
| Accepted duplications | `config/pmd/exclude-cpd.properties` (`<ClassA>,<ClassB>` per duplication; no blank line) |
| Plugin, versions, CPD token threshold | root `pom.xml` (`pmd-plugin.version` 3.28.0, `pmd.version` 7.29.0, `cpd.minimumTokens` 100) |
| Guard of the acceptance files | `scripts/tests/test_pmd_exclusions.py` (`just test-hooks`, Semgrep workflow) |
| Reports of a run | `<module>/target/pmd.xml`, `<module>/target/cpd.xml` |

## Rules and thresholds

A rule reports when the value **reaches** its threshold: "method ≥ 15" means a method may have at most 14.

| Rule | Fails at | Measured max on 2026-11-15 (main code, before → after WP113) |
|---|---|---|
| `CyclomaticComplexity`, method | ≥ 15 | 17 `MatchEventJson.decode`, 16 `RosterEventMapper.map`, 16 `CoreEventMapper.change` (accepted; the mappers replaced the decoders in WP130); then 14 `UpdateMatchRequest.clearedProperties` |
| `CyclomaticComplexity`, class (sum of its methods) | ≥ 65 | 60 `Match`, 44 athlete `PatchBody`, 41 core `PatchBody` |
| `CognitiveComplexity`, method | ≥ 15 | 18 `AssignmentJpaRepository.search` → refactored; then 14 `BandResolver.bandsAreOrdered` |
| `NcssCount`, method (statements) | ≥ 30 | 27 `JpaMatchRepository.list`, 25 `JpaMatchRepository.save` |
| `NcssCount`, class | ≥ 150 | 137 `Match`, 115 `ProjectionRun`, 98 → 106 `AssignmentJpaRepository` (the extracted helpers) |
| `ExcessiveParameterList` (constructors too) | ≥ 12 | 17 `Match.restore`, 12 `CreatePlayer(…)` (both accepted); then 11 (five classes) |
| `UnusedPrivateField`, `UnusedPrivateMethod` | any | 0 |
| `UnusedLocalVariable` | any | 10 → 0 (unused pattern variables became `_`) |
| `UnnecessaryImport` | any | 4 → 0 |
| `EmptyCatchBlock` (a block with a comment saying why is fine) | any | 0 |
| CPD, per module | ≥ 100 tokens | 108 outbox insert in `JpaOutboxRepository` / `PlatformOutboxRepository` → `OutboxRowRepository`; 103 `ManageExercises` / `ManagePlans` (accepted); then 89 |

How it was measured: every threshold set to 1 (CPD to 50 tokens), `./mvnw -T 1C -DskipTests compile pmd:pmd pmd:cpd`,
the values read from the `target/pmd.xml` and `target/cpd.xml` of each module. Repeat that to re-measure.

## Accepted findings (each with its reason in the file)

| File | Entry | Why |
|---|---|---|
| `exclude-pmd.properties` | `MatchEventJson`, `RosterEventMapper`, `CoreEventMapper` = `CyclomaticComplexity` | a flat exhaustive switch from wire type to event, one arm per type; cognitive complexity stays low; under mutation testing |
| `exclude-pmd.properties` | `Match` = `ExcessiveParameterList` | `Match.restore` rehydrates the aggregate from its row, one parameter per column |
| `exclude-pmd.properties` | `CreatePlayer` = `ExcessiveParameterList` | CDI constructor with 12 collaborators; may not take a 13th; splitting the use case is follow-up work |
| `exclude-cpd.properties` | `ManageExercises`, `ManagePlans` | the edits of an exercise and of a plan item copy the same six patchable fields; two aggregates that only look alike |

## When the gate fails

The build stops in `verify` with lines like these (also in `target/pmd.xml` / `target/cpd.xml`):

```
[WARNING] PMD Failure: com.hoopsacademy.core.application.approvals.CreatePlayer:55 Rule:ExcessiveParameterList Priority:3 Avoid long parameter lists (12 parameters - threshold is 12)..
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-pmd-plugin:3.28.0:check (pmd-check) on project core-service: PMD 7.29.0 has found 1 violation. ...
[WARNING] CPD Failure: Found 12 lines of duplicated code at locations:
[WARNING]     .../SomeClass.java line 5
[WARNING]     .../OtherClass.java line 18
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-pmd-plugin:3.28.0:cpd-check (cpd-check) on project common-quarkus: CPD 7.29.0 has found 1 duplication. ...
```

Fix it in the code; that is almost always right:

| Finding | Usual fix |
|---|---|
| `CyclomaticComplexity` / `CognitiveComplexity` | extract the conditions or the branches into named private methods; replace flags by early returns; a guard clause instead of nesting |
| `NcssCount` (method) | split the method into steps with names (query building, binding, mapping) |
| `NcssCount` / `CyclomaticComplexity` (class) | the class does too much: move a responsibility to its own class (a use case, a mapper, a policy) |
| `ExcessiveParameterList` | a parameter object or record for values that travel together; for a CDI constructor, split the use case |
| unused private field / method / local / import | delete it; an unused pattern variable becomes `_` (`case Foo _ ->`) |
| `EmptyCatchBlock` | handle, rethrow or log; if ignoring is right, say why in a comment inside the block |
| CPD | extract the shared code (a helper in the same package, or one `*Repository` class for shared SQL: native SQL is allowed only there, ArchUnit) |

Refactor test first (`test-driven-development`): pin the behaviour with a test, then move the code, as WP113 did with
`AssignmentSearchClauseTest`. Code under mutation testing (`docs/quality/mutation.md`) keeps its baseline: run
`just mutation <module>` after the refactor.

Only when the code is right as it is, accept the finding: one line in the exclusion file, under a comment with the
reason (and the work package if it waits for a fix). Never raise a threshold to let one class through, never add
`@SuppressWarnings("PMD…")` or `// NOPMD` (ADR-0053, as ADR-0045 for the other gates). `python3 -I -m unittest discover
-s scripts/tests` checks the files.

A quick local loop may skip the gate with `-Dpmd.skip -Dcpd.skip`; the full `verify` before a commit never does.

## Notes

- PMD prints `Adding current platform .../jrt-fs.jar to auxClasspath, which could be the wrong java version`: the
  build JDK is the release (25), so the warning is harmless.
- PMD keeps an analysis cache in `<module>/target/pmd/pmd.cache`; `clean` removes it, and a cold run is still a few
  seconds.
- Added build time (WP113, 2-CPU VM under the load of three other builds): compile + gate 10–12 s against compile alone
  6–10 s on the whole reactor, cold or warm, i.e. about 3–6 s wall.
