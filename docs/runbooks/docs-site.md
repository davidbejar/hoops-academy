# Runbook: documentation site

The Markdown under `docs/` is also a browsable site with search, navigation and rendered Mermaid diagrams:
<https://davidbejar.github.io/hoops-academy/>. It is built by [Zensical](https://zensical.org/) and published to
GitHub Pages from `main` ([ADR-0057](../adr/0057-documentation-site-zensical-github-pages.md)). The files stay plain
Markdown that reads well on GitHub.

## Commands

```
just docs-serve                     # preview on http://localhost:8000, reloads on save
just docs-serve -a localhost:8001   # another port
just docs-build                     # strict build into target/docs-site (what CI runs)
```

Both create `.venv-docs/` on first use (Python 3 only, no Node) from the pins in `config/docs/requirements.txt`, and
rebuild it when that file changes.

## How it is put together

| File | Role |
|---|---|
| `mkdocs.yml` | Site configuration in the MkDocs format, which Zensical reads: theme, Markdown extensions, link validation |
| `docs/.nav.yml` | Order and titles of the top-level sections; folders are listed whole |
| `docs/wp/.nav.yml` | Natural order of the work packages (WP2 before WP10) |
| `docs/index.md` | Landing page |
| `config/docs/requirements.txt` | Pinned Zensical and its dependencies |
| `.github/workflows/pages.yml` | Builds and publishes on a push to `main` that touches the site |
| `ci.yml`, job `docs-site` | The same strict build on every pull request, without publishing |

A new page in an existing folder appears on its own; its title is its first `# heading`. Only a new top-level folder
or page needs a line in `docs/.nav.yml`.

## Rules for pages

- Link to another page with a relative path to the `.md` file (`../adr/0006-rls-multitenancy.md`), never to a folder
  (`../adr/`): a folder link works on GitHub but not on the site, and the strict build rejects it.
- Refer to files outside `docs/` (source code, `README.md`, `CLAUDE.md`) as code (`` `services/core-service` ``), not
  as links: the site only contains `docs/`.
- Diagrams are fenced `mermaid` blocks, as before.
- Everything under `docs/` is public once it is on `main`. That includes the security review and the threat models,
  which is accepted for this learning project (ADR-0057); secrets never belong in `docs/` in any case.

## What the strict build checks

`just docs-build`, the `docs-site` job of `ci` and `pages.yml` fail on a link to a page that does not exist, a link to
a heading that does not exist, a folder link, and a configuration or navigation error.

## Publishing

`pages.yml` runs on a push to `main` that changes `docs/`, `mkdocs.yml`, `config/docs/` or the workflow itself, and
can be started by hand from the Actions tab. It needs the repository setting Pages > Source "GitHub Actions" (set on
2026-11-21). To take the site down: Settings > Pages > Unpublish, and disable the workflow.

## Things to know

- **Mermaid comes from a CDN.** The theme loads the Mermaid script from unpkg.com in the reader's browser on pages
  with a diagram; fonts are the system ones (`font: false`), so that is the only third-party request.
- **Zensical is young** (0.1.x). Its `serve` has no strict mode yet, so run `just docs-build` before pushing. If a
  release breaks the site, the fallback is Material for MkDocs 9.8 with `mkdocs-awesome-nav`, which builds the same
  `mkdocs.yml` and `.nav.yml` files unchanged (tried on 2026-11-21) and is maintained until 2027-05-05.
