# ADR-0077: Threat modelling: STRIDE, LINDDUN and MAESTRO, rated with PASTA's scale, kept current as VAST asks

- Status: Accepted
- Date: 2026-11-28
- Related: decisions 119 to 122 of 2026-11-28 (`docs/wp/FOLLOW-UPS.md`, eleventh round),
  [WP148](../wp/WP148-stride-threat-model-refresh.md) (STRIDE), [WP149](../wp/WP149-agentic-threat-model-build-system.md)
  (MAESTRO), [WP150](../wp/WP150-threat-modelling-method-and-privacy-refresh.md) (this ADR, the privacy refresh, the
  rule), WP112 (the LINDDUN model, decision 102), [`threat-model.md`](../security/threat-model.md),
  [`privacy-threat-model.md`](../security/privacy-threat-model.md), [`review-2026-11.md`](../security/review-2026-11.md),
  [`docs/domain/authz-matrix.md`](../domain/authz-matrix.md)

## Context
The project has two threat models: a STRIDE model per trust boundary (`threat-model.md`, six boundaries, written before
pdf-service, finance-service, Redpanda and the telemetry backend existed) and a LINDDUN privacy model per trust boundary
(`privacy-threat-model.md`, WP112, ten boundaries, two of them written while their services were still planned). The
security review (`review-2026-11.md`) rated its findings with its own rubric; neither model rated its residual risks.
The code is written by AI agents in an agent-driven build system that no model covered. The owner asked whether
MAESTRO could improve this (decision 119), and which of the other well-known methods (PASTA, VAST, Trike, OCTAVE) the
project should use. Decision 120: a combination, each method for the question it answers best, not one method for
everything.

## Decision
1. **STRIDE per trust boundary for the product** (`docs/security/threat-model.md`). One table per boundary (Spoofing,
   Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege), evidence per row.
   Findings `TM-`.
2. **LINDDUN per trust boundary for privacy** (`docs/security/privacy-threat-model.md`), with the same boundary numbers
   as the STRIDE model where both have the boundary (1 to 10; the STRIDE model's boundary 11, build and supply chain,
   has no privacy table). Findings `P-`.
3. **From PASTA only two parts.**
   - **The rating.** Likelihood and impact are each Low, Medium or High (1, 2, 3); their product is the rating: 6 or 9
     High, 3 or 4 Medium, 1 or 2 Low. Likelihood is judged for the project as it is exposed today; impact as if a real
     academy's data were in it.
   - **Attack chains** for the top assets (minors' and health data, tenant isolation, credentials): a numbered path
     across boundaries, the control that breaks each step and the step where no control stands.

   The full seven stages (business objectives, technical scope, decomposition, threat analysis, vulnerability analysis,
   attack modelling, risk and impact analysis) are too heavy for this project: its objectives and scope are one owner's,
   and the decomposition is already the boundary tables.
4. **From VAST only its idea that the model is kept current inside delivery**: a work package that adds or changes a
   trust boundary, a service, a data store or an agent guardrail updates the threat model that covers it (`CLAUDE.md`
   Definition of Done), and every round's close-out checks the three models against the round's changes (`wp-round`
   skill, Close-out list). VAST's tooling and its split into application and operational models are not taken.
5. **MAESTRO for the agent-driven build system** (`docs/security/agentic-threat-model.md`, WP149): the agents, their
   instructions, skills, hooks, worktrees and permissions. The product has no AI, so MAESTRO is not applied to it; that
   document says what an AI feature in the product would have to meet. Findings `AG-`.
6. **Not used.**
   - **Trike**: its actor, asset and action matrix with allowed operations is what `docs/domain/authz-matrix.md` already
     is, and the role-matrix tests enforce it (the matrix is their oracle, `CLAUDE.md` rule 3). A second matrix would
     only drift from the tested one.
   - **OCTAVE**: organisational risk workshops with business units and staff; the project has one owner and no
     organisation to interview.

## Consequences
- Three documents: `threat-model.md` (STRIDE), `privacy-threat-model.md` (LINDDUN), `agentic-threat-model.md`
  (MAESTRO); the security review stays the record of the code review that produced the `F-` findings.
- One rating scale for every new finding of the three documents. Findings rated before this ADR (`F-` of the review,
  `P-01` to `P-13` of WP112) keep their earlier severity until a revision re-rates them; the document that holds them
  says so.
- Finding ids: `F-` (security review), `P-` (privacy), `TM-` (STRIDE), `AG-` (agentic). Each series continues its own
  numbering; an id is never reused.
- A work package that changes a trust boundary, a service, a data store or an agent guardrail has one more Definition
  of Done item; a round's close-out has one more checkbox.
- Wave 2 of the eleventh round fixes the High and Medium findings of the three documents; Low and Info become open
  items.

## Alternatives considered
- **One method for everything** (STRIDE only, or MAESTRO for the whole system): STRIDE asks no privacy questions
  (linking, unawareness, non-compliance), and MAESTRO's layers are about AI systems, which the product is not.
- **Full PASTA**: see 3; the seven stages would mostly restate the boundary tables and the brief.
- **No rating, as before**: the residual risks could not be ordered, and wave 2 needs an order to choose what to fix.
- **Trike, OCTAVE**: see 6.
