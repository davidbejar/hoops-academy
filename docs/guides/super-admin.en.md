# Super administrator guide

Languages: [Español](super-admin.es.md) · English · [Bahasa Indonesia](super-admin.id.md)

You sign in with your e-mail address and your password.

The **super administrator** runs the platform: creates and withdraws academies and reads their usage. It is a Keycloak
realm role (`super_admin`), not an academy role. A super administrator **cannot read academy content** (players, matches,
health data): the platform has no access to it.

## Finding the console
- A super administrator with no academy membership lands on **Platform** directly.
- One who also belongs to an academy sees that academy's navigation; open **Profile > Platform console** to get to the
  platform.

## Tenant (academy) list
**Platform** lists academies with a search box (name or slug) and status chips: **Active**, **Suspended**, **Withdrawn**.
Open one for its detail and usage.

## Creating an academy
**Platform > New academy** (see also `docs/runbooks/onboard-tenant.md`):
- **Academy name**, **Identifier (slug)** (lowercase letters, numbers and hyphens, 3-50), **Time zone**, **Language**.
- **First admin e-mail**, first name and last name.
On **Create**, the academy and its first administrator exist at once, default age categories (U8 to U18, SENIOR) are
seeded, and the administrator receives an e-mail with a link to choose a password. If the identity provider is
unavailable the creation fails as a whole and nothing is left behind ("502").

## Lifecycle and what it means
| State | Meaning |
|---|---|
| **Active** | normal operation |
| **Suspended** | reversible stop. Every member gets "not found" (404) on all academy APIs; the academy disappears from their academy list. Data is untouched. Peers cache a membership for up to 30 s, so enforcement can lag by that long. |
| **Withdrawn** | terminal. Logins are blocked at once; data is kept until the **retain until** date (default 365 days after withdrawal). A purge job does not exist yet (see `docs/roadmap.md`), so data is not deleted automatically. |

Actions on an academy's detail page:
- **Suspend**: a reason is required.
- **Reactivate**: only from Suspended; restores access as it was.
- **Withdraw**: a reason is required and a warning explains that the retention period starts. It cannot be undone.
Every lifecycle change is written to the academy's append-only audit trail.

## Usage dashboard
The academy detail shows **Usage** by service (Core, Matches, Athletes): members, players, active players, teams,
seasons, matches, live matches, match events, training sessions, attendance records, plans, test results, injuries,
body measurements. If a service did not answer, a notice "No data from: ..." names it; the rest still shows. A snapshot is
stored per academy per day (02:30 UTC); a trend chart is not in the app yet.

---
Status: written from the implemented screens, the contract and the translation files; not yet checked in a manual browser walk-through.
