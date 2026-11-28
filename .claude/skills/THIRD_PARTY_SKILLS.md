# Third-party skills vendored into this repository

Each folder below was copied verbatim (Markdown only, no scripts or hooks) after review on 2026-11-01.
Re-vet before updating from upstream.
Local edits since (prompt audit of 2026-11-25): references to files and skill names that were not vendored removed
(`systematic-debugging`, `test-driven-development`); emphasis-only wording (capitals, "MANDATORY", fatigue lines)
reworded in `verification-before-completion`, `test-driven-development` and `systematic-debugging`, rules unchanged.

| Skill folder | Upstream | Commit date | License |
|---|---|---|---|
| `clean-code/` | https://github.com/markoa/clean-code-skill (`skills/clean-code`) | 2026 | MIT |
| `test-driven-development/` | https://github.com/obra/superpowers (`skills/test-driven-development`) | 2025–2026 | MIT |
| `verification-before-completion/` | https://github.com/obra/superpowers | 2025–2026 | MIT |
| `systematic-debugging/` | https://github.com/obra/superpowers (scripts `find-polluter.sh` and `.ts` example intentionally omitted) | 2025–2026 | MIT |
| `owasp-security/` | https://github.com/agamm/claude-code-owasp (`.claude/skills/owasp-security`) | 2026 | MIT |

## Checksums
One SHA-256 per vendored folder (AG-11, ADR-0078): of the `shasum -a 256` lines of its tracked files, from
`cd .claude/skills && git ls-files -z -- <folder> | LC_ALL=C sort -z | xargs -0 shasum -a 256 | shasum -a 256`.
`scripts/tests/test_agent_guardrails.py` recomputes them; a change to a vendored folder is re-vetted and updates its
line here in the same commit.

| Skill folder | SHA-256 |
|---|---|
| `clean-code/` | `a64c1fcab3b2cc16beb3ad22c82babf27a3413d85edc1bf75de9b9e8365f5354` |
| `test-driven-development/` | `1ace30155fb58dde0fd21f52da9e6eb5b8c6cfea6d54f41bade25787535df33a` |
| `verification-before-completion/` | `4ccaf14bb7ef99c1c1eb3cf3cef90c6cca31953ec0b836e321604124cf567a01` |
| `systematic-debugging/` | `b9d34e976b8d9bf6a76a77440cc26487bdb4ba8d221e60863eaedf41cfe5d79b` |
| `owasp-security/` | `a097f28480cf21a8bbe9a03fdbfc865e5dd3223ae8b5b2d340c87b79189dacda` |

Not vendored (CC-BY-SA 4.0, used via marketplace instead): Trail of Bits skills — add with
`claude plugin marketplace add trailofbits/skills` and install `property-based-testing`,
`mutation-testing`, `insecure-defaults` when needed.
