# Super administrator guide

Languages: [Español](super-admin.es.md) · English · [Bahasa Indonesia](super-admin.id.md)

You sign in with your e-mail address and your password.

The **super administrator** runs the platform: creates and withdraws academies and reads their usage. It is a Keycloak
realm role (`super_admin`), not an academy role. A super administrator **cannot read academy content** (players, matches,
health data): the platform has no access to it. The one exception is the list of an academy's **administrators** (their
names, e-mail and invitation state), which the super administrator manages (see below, ADR-0023).

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

## Administrators
On the academy detail page (**Platform >** the academy) the **Administrators** section lists each administrator with
name, e-mail, invitation state (**Invitation pending** / **Invitation accepted**) and their other roles in the academy.
Every row has **Edit**, **Remove administrator** and, while the invitation is pending, **Resend invitation**; **Add
administrator** is at the top. The section works for ACTIVE and SUSPENDED academies; for a **withdrawn** academy it only
shows a note (its administrators can no longer be viewed or changed). The same operations exist in the platform API
`/platform/tenants/{id}/admins`.
- **List**: the active administrators with name, e-mail, invitation state and their other roles in the academy.
- **Add** (e-mail, first and last name, optional language): a member of the academy with that e-mail becomes
  administrator (their names are kept; a member without a login receives the set-password e-mail). Otherwise a new
  administrator is invited exactly like the first one. A deactivated member with that e-mail is refused.
- **Edit** first name, last name or e-mail. A new e-mail also becomes the person's sign-in address (Keycloak username and
  e-mail) and receives a verification e-mail — or the invitation again while it is pending. Unlike an academy
  administrator, you can do this also for a login that is used in several academies.
- **Remove** (asks for confirmation): the person loses the administrator role; other roles stay, and if it was their
  only role they are deactivated in this academy. Their login is never deleted (it may be used elsewhere).
- **The last administrator cannot be removed.** An academy always needs at least one active administrator. When only one
  administrator is listed, its **Remove** button is disabled and the row says: "An academy needs at least one
  administrator. Add another administrator first." If someone else has just changed the list and the server still
  refuses, you see the same message. Add the new administrator first, then remove the old one.
- **Resend invitation**: only while the invitation is pending.
Every change is written to the academy's audit trail with you as the actor.

## Usage dashboard
The academy detail shows **Usage** by service (Core, Matches, Athletes): members, players, active players, teams,
seasons, matches, live matches, match events, training sessions, attendance records, plans, test results, injuries,
body measurements. If a service did not answer, a notice "No data from: ..." names it; the rest still shows. A snapshot is
stored per academy per day (02:30 UTC); a trend chart is not in the app yet.

---
Status: written from the implemented screens, the contract and the translation files; not yet checked in a manual browser walk-through.
