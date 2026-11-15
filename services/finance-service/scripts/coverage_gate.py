"""Coverage gate of finance-service (ADR-0055): reads a Go cover profile (`go test -coverprofile`, mode set or atomic)
and fails when statement coverage is below 80 % for the module or below 90 % for the domain packages
(internal/domain), the same thresholds as the JaCoCo gates of the Java services. Left out of the measure, like
Quarkus' entry points and the Rust main.rs: the wiring in cmd/ and the test support (internal/testsupport,
internal/archtest), which only tests use.

    python3 -I scripts/coverage_gate.py coverage.out
"""

import sys

MODULE = "hoopsacademy.local/finance/"
TOTAL_MIN = 80.0
DOMAIN_MIN = 90.0
EXCLUDED = ("cmd/", "internal/testsupport/", "internal/archtest/")


def blocks(lines):
    """Unique blocks of the profile: (file, span) -> (statements, covered). A block listed twice (several test
    binaries cover the same package) counts once, covered when any listing covered it."""
    seen = {}
    for line in lines:
        line = line.strip()
        if not line or line.startswith("mode:"):
            continue
        location, statements, count = line.rsplit(" ", 2)
        name, span = location.rsplit(":", 1)
        name = name.removeprefix(MODULE)
        if name.startswith(EXCLUDED):
            continue
        key = (name, span)
        was = seen.get(key, (int(statements), False))
        seen[key] = (was[0], was[1] or int(count) > 0)
    return seen


def measure(seen, prefix=""):
    statements = covered = 0
    for (name, _), (count, hit) in seen.items():
        if name.startswith(prefix):
            statements += count
            covered += count if hit else 0
    return covered, statements


def percent(covered, count):
    return 100.0 * covered / count if count else 100.0


def gate(lines):
    seen = blocks(lines)
    results = [
        ("module", *measure(seen), TOTAL_MIN),
        ("domain", *measure(seen, "internal/domain/"), DOMAIN_MIN),
    ]
    failed = False
    for name, covered, count, minimum in results:
        value = percent(covered, count)
        ok = value >= minimum and count > 0
        failed |= not ok
        print(f"coverage {name}: {value:.2f} % statements ({covered}/{count}), minimum {minimum:.0f} %: "
              f"{'ok' if ok else 'FAIL'}")
    return 1 if failed else 0


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as handle:
        sys.exit(gate(handle.readlines()))
