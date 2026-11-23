# ADR-0061: Web lists are read whole through `fetchAll` or paged with the kit `Pager`

- Status: Accepted
- Date: 2026-11-23
- Records: decision 105 of 2026-11-23 (audit findings WEB-03, WEB-15 in part)
- Related: ADR-0040 (widget kit), `libs/contracts/openapi/common.yaml` (`Page`, `Size`), `PageOffset` in
  `libs/common-quarkus`, `apps/web/lib/core/api/fetch_all.dart`, `apps/web/lib/core/ui/pager.dart`,
  [WP129](../wp/WP129-web-lists-whole-live-match-dispose.md)

## Context
Every list operation of the four services is paged: `size` is 1..200 (50 by default) and the services refuse a
larger one (`PageOffset.MAX_SIZE`). The web app read lists three ways. Twenty repository calls asked for one page of
50, 100 or 200 items and showed it as the whole list, with no sign that something was missing: a parent past the
100th lost the login button in the guardian dialog, the members list, the staff picker and the players list stopped
at 100 (the category filter ran on the cut list), upcoming planned absences fell off after 100, and the fee plans and
a family's dues stopped at 200 and 50. Four screens paged correctly, each with its own copy of the same chevron row
and two identical sets of translation keys. The demo mock answered most lists as one fixed page, so the cut could
not show in the demo either.

## Decision
1. **A list a screen needs whole is read whole.** Pickers, maps by id, client-side filters, calendars and the other
   lists the app shows in full go through `fetchAll` (`core/api/fetch_all.dart`) in their repository: pages of 200
   (the largest the services accept) in order until the server's last page or an empty one. The repository returns a
   `List`, never a page.
2. **A safety bound, never a silent cut.** `fetchAll` reads at most 50 pages (10,000 items, far above any academy).
   Past that it throws `ListTooLongError`, which the screen shows as an error, instead of showing part of the list.
3. **A list that grows without bound is paged on screen.** Dues, expenses, the activity log and the platform users
   page on the server and show the kit's `Pager`: the chevrons around "Page x of y", keys `<prefix>-previous` and
   `<prefix>-next`, one key set `pageOf` / `pagePrevious` / `pageNext`, nothing while the list fits one page. The
   exercise catalogue keeps its "load more". A repository method that returns a `*Page` belongs to such a screen.
4. **No list call reads one page and shows it as all.** A new list call is either rule 1 or rule 3.
5. **The demo mock pages like the services.** `MockQuery.page` serves `size` 1..200 with 50 by default and answers
   a 400 for anything else or a negative page; every mock list (core, game, athlete, finance, platform) goes through it.
6. **Tests.** `test/support/server_pages.dart` (`ServerPagesAdapter`) serves any list like the services from the
   mock's item shapes; `test/core/lists_read_every_page_test.dart` reads each whole list over 450 items, and
   `test/core/mock_paging_test.dart` holds the mock to rule 5.

No contract changes.

## Alternatives
- **A larger `size`.** The services refuse more than 200, and raising the ceiling only moves the cut.
- **Page every list on screen.** The pickers, the guardian logins (a map by person) and the client-side filters need
  the whole list; paging them would add a pager to every dialog for lists that stay in the hundreds.

## Consequences
- A large academy costs one request per 200 items (450 members: three requests) where it used to cost one, and gets
  the whole list.
- A list that one day reaches thousands moves from rule 1 to rule 3 with a server-side filter; the bound makes that
  visible as an error rather than as missing rows.
- The activity log no longer shows "Page 1 of 1" with two disabled chevrons, like the other three paged screens.
