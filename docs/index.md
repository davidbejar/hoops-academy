# Hoops Academy documentation

Hoops Academy is a multitenant platform for basketball academies: roster and age-category eligibility, offline-first
live match statistics, training and attendance, athlete health and fitness. It is a learning project, not a commercial
product ([ADR-0025](adr/0025-one-login-many-academies-easy-sign-up.md)).

## Where to start

| You want to | Read |
|---|---|
| Know the current state and what is pending | [Session handover](HANDOVER.md), [roadmap](roadmap.md), [open items](wp/FOLLOW-UPS.md) |
| Understand how the system is built | [Architecture overview](architecture.md), [decisions (ADR)](adr/README.md) |
| Look up a domain rule | [Glossary](domain/glossary.md), [authorization matrix](domain/authz-matrix.md), [norms](domain/norms.md), models of [core](domain/core-model.md), [game](domain/game-model.md) and [athlete](domain/athlete-model.md) |
| Use the application | User guides: [administrator](guides/admin.en.md), [coach](guides/coach.en.md), [parent](guides/parent.en.md), [player](guides/player.en.md), [super admin](guides/super-admin.en.md) (each in es / en / id) |
| Run or operate it | [Local stack](runbooks/local-stack.md), [kind](runbooks/kind.md), [release](runbooks/release.md), [troubleshooting](runbooks/troubleshooting.md) |
| Review its security | [Security review](security/review-2026-11.md), [threat model](security/threat-model.md), [privacy threat model](security/privacy-threat-model.md), [ASVS checklist](security/asvs-checklist.md) |
| Compare it with the original request | [Specification](SPEC.md), [plan](PLAN.md), [conformance](conformance.md) |

## This site

The pages are the Markdown files of `docs/` in the repository, rendered by Zensical and published from `main`
([ADR-0057](adr/0057-documentation-site-zensical-github-pages.md), [runbook](runbooks/docs-site.md)). `just docs-serve`
previews the site locally and `just docs-build` builds it and fails on a broken link between pages.
