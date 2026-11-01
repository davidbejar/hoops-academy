# Glossary

- **Tenant / Academy**: an organisation using the platform; all data is scoped to one tenant.
- **Person**: a human known to a tenant (may or may not have a login). **Member**: person with ≥ 1 role.
- **Player**: person with the PLAYER role, birth date and gender; has a status (PENDING_APPROVAL, ACTIVE, ORPHAN, WITHDRAWN).
- **Guardian link**: parent/guardian ↔ player relation that grants the parent scoped rights.
- **Season**: dated period with a `reference_year` used by the BIRTH_YEAR age rule.
- **Age category**: tenant-configurable band (U8 … U18, SENIOR) ordered by rank; `max_age` inclusive.
- **Natural category**: the lowest-ranked category a player qualifies for.
- **Play-up**: assignment to a team whose category rank is higher than the natural one (allowed; limit configurable).
- **Team**: squad within a season with a category and a gender policy (MALE, FEMALE, MIXED); has name and alias.
- **Team staff**: COACH / ASSISTANT_COACH attached to a team.
- **Orphan**: active player with no valid open team assignment (e.g. after rollover or birthday).
- **Eligibility case**: open issue created when an assignment becomes invalid; resolved by admin or staff.
- **Approval request**: coach-initiated ADD_PLAYER / WITHDRAW_PLAYER awaiting an admin decision.
- **Match event**: append-only, client-identified fact entered during a game; **projection**: box score derived from events.
- **Training session**: concrete dated occurrence (materialised from a schedule or ad hoc).
- **Plan / template**: ordered training items; templates are global and copied on use.
- **Norm band**: expected performance band for a physical test by gender and age.
