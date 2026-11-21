# ADR-0057: Documentation site built by Zensical and published to GitHub Pages

- Status: Accepted
- Date: 2026-11-21
- Related: ADR-0004 (no Node toolchain), ADR-0025 (learning project), `mkdocs.yml`, `docs/.nav.yml`,
  `config/docs/requirements.txt`, `.github/workflows/pages.yml`, [runbook](../runbooks/docs-site.md)

## Context
`docs/` holds about 240 Markdown pages (ADRs, work packages, runbooks, guides in three languages, security). On GitHub
they can be read one at a time, without search across them and without navigation between sections. The owner asked
for a documentation site (MkDocs) and, the same day, whether its successor could be used straight away.

Material for MkDocs, the usual MkDocs theme, announces its end of life for 2027-05-05 on every build. Its authors'
successor is Zensical, which reads an MkDocs configuration file unchanged. Both were tried on this repository on
2026-11-21 with the same `mkdocs.yml` and `docs/.nav.yml`:

| | Material for MkDocs 9.8.2 + awesome-nav 3.3.0 | Zensical 0.1.3 |
|---|---|---|
| Builds all pages, 7 navigation sections | yes | yes |
| Folder-based navigation from `.nav.yml`, natural order of work packages | yes (plugin) | yes (built in) |
| Mermaid diagrams, search, edit links | yes | yes |
| Strict build fails on a broken link or anchor | yes | yes |
| Python packages installed | 33 | 11 |
| Maintained after 2027-05-05 | no | yes |

## Decision
1. **Generator**: Zensical, from the start, instead of adopting Material for MkDocs and migrating within six months.
   The configuration stays in the MkDocs format (`mkdocs.yml`), so going back is a change of the installed package
   and of two commands, not of the content.
2. **Content stays plain Markdown** that reads well on GitHub: no generator-specific syntax in pages. Navigation is
   by folder (`docs/.nav.yml`), so a new ADR or work package needs no configuration change.
3. **Toolchain**: Python only, in a virtualenv (`.venv-docs`, not committed), every package pinned in
   `config/docs/requirements.txt` and bumped by Dependabot with the repository's 7-day cooldown. No Node (ADR-0004).
4. **Gate**: a strict build (`just docs-build`) runs in `ci` on every pull request (`docs-site`); a broken link or
   anchor between pages fails it.
5. **Publishing**: GitHub Pages, from `main`, by `.github/workflows/pages.yml` (official Pages actions, pinned by
   commit SHA, `pages: write` and `id-token: write` on the deploy job only).
6. **Everything under `docs/` is public**, including the security review, the threat models and the ASVS checklist.
   The repository is already public, so the site exposes nothing new; it only makes it easier to find. This is
   accepted because Hoops Academy is a learning project with no production deployment (ADR-0025). If real academies
   ever use it, revisit: move the security pages out of the published tree or make the site private.

## Consequences
- The documentation has search and navigation at <https://davidbejar.github.io/hoops-academy/>.
- Links between pages must point to `.md` files, not folders; the strict build enforces it.
- Zensical is at 0.1.x: breaking releases are possible, and its `serve` has no strict mode yet. The pins and the
  `docs-site` job contain that; the fallback (Material 9.8 with `mkdocs-awesome-nav`, same files) holds until
  2027-05-05.
- Pages with a diagram load Mermaid from unpkg.com in the reader's browser. No other third-party request (system
  fonts).
- One more Dependabot ecosystem (pip) and one more workflow to keep green.

## Alternatives considered
- **Material for MkDocs now, Zensical later**: the most used option today, but it ends in under six months and adds a
  migration for no gain, since Zensical already builds this site.
- **Plain MkDocs with its built-in theme**: no Mermaid rendering and a weaker search; MkDocs itself warns about an
  incompatible 2.0.
- **No site, GitHub rendering only**: zero maintenance, but no search across 240 pages.
- **Not publishing (local and CI build only)**: avoids advertising the security documents; rejected by the owner for
  a pet project whose repository is public anyway.
