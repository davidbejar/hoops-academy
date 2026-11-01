# ADR-0010: Age categories computed by birth year vs season by default

- Status: Accepted
- Date: 2026-11-01

## Context
The spec describes players becoming ineligible on their birthday; federations (FIBA and national leagues) assign categories by birth year relative to the season. Academies may follow either.

## Decision
Per-tenant setting `age_rule` with strategies `BIRTH_YEAR` (default: season reference year − birth year) and `BIRTHDAY` (full years on the evaluation date). The same eligibility engine runs nightly per tenant and synchronously at season rollover.

## Consequences
Under BIRTH_YEAR orphans arise at rollover (admin wizard shows them); under BIRTHDAY the nightly job flags them. Both paths share tests.
