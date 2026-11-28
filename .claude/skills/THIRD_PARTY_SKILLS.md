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

Not vendored (CC-BY-SA 4.0, used via marketplace instead): Trail of Bits skills — add with
`claude plugin marketplace add trailofbits/skills` and install `property-based-testing`,
`mutation-testing`, `insecure-defaults` when needed.
