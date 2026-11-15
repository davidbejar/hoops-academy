"""Coverage gate of pdf-service (ADR-0052): reads the JSON summary of `cargo llvm-cov --json --summary-only` and
fails when line coverage is below 80 % for the workspace or below 90 % for the domain crate (crates/domain), the
same thresholds as the JaCoCo gates of the Java services. `main.rs` (wiring) is outside the measure, as Quarkus' entry
points are for JaCoCo.

    python3 -I scripts/coverage_gate.py target/llvm-cov.json
"""

import json
import sys

TOTAL_MIN = 80.0
DOMAIN_MIN = 90.0


def lines(files):
    count = sum(f["summary"]["lines"]["count"] for f in files)
    covered = sum(f["summary"]["lines"]["covered"] for f in files)
    return covered, count


def percent(covered, count):
    return 100.0 * covered / count if count else 100.0


def gate(report):
    files = [f for f in report["data"][0]["files"] if not f["filename"].endswith("/src/main.rs")]
    domain = [f for f in files if "/crates/domain/" in f["filename"]]
    results = [
        ("workspace", *lines(files), TOTAL_MIN),
        ("domain", *lines(domain), DOMAIN_MIN),
    ]
    failed = False
    for name, covered, count, minimum in results:
        value = percent(covered, count)
        ok = value >= minimum and count > 0
        failed |= not ok
        print(f"coverage {name}: {value:.2f} % lines ({covered}/{count}), minimum {minimum:.0f} %: {'ok' if ok else 'FAIL'}")
    return 1 if failed else 0


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as handle:
        sys.exit(gate(json.load(handle)))
