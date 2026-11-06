# Administrator guide

Languages: [Español](admin.es.md) · English · [Bahasa Indonesia](admin.id.md)

You sign in with your e-mail address and your password.

You are an **Administrator** of one academy. You set the academy up, invite people, build seasons and teams, and
decide on player requests. Menu names below are the labels shown in the English app.

## Getting around
- Sign in with your e-mail and the temporary password the platform administrator gave you; the first time, Keycloak
  asks you to choose your own password (at least 12 characters). No invitation e-mail is sent (ADR-0024).
- Bottom bar on a phone (side rail on a wide screen): **Admin**, **Teams**, **Matches**, **Training**, **Players**.
- Tap the academy logo/name in the top bar to **Switch academy** if you belong to several.
- **Profile** (top bar) holds **Language** (Español, English, Bahasa Indonesia) and **Sign out**.

## 1. Academy profile and logo
**Admin > Academy profile.**
- Name, **Time zone** (for example Europe/Madrid), **Default language**.
- **Age rule** and **Maximum play-up levels**: see section 7.
- **Logo**: **Choose image**, then **Upload logo**. PNG, JPEG or WebP, 512 KB at most. **Remove logo** deletes it.
  The logo appears in the top bar of every member.

## 2. Members and invitations
**Admin > Members.** Search by name or e-mail.
1. **Invite**: first name, last name, e-mail, and at least one **Role** (Administrator, Coach, Assistant coach, Parent,
   Player). A person can hold several roles.
2. No e-mail is sent. If the person had no login yet, a **Temporary password** dialog shows their password **once**
   (with a **Copy password** button; it only closes with **Done**): pass it on
   privately (in person, by phone or a messenger you trust; never in the same message as the e-mail address). They sign
   in with their e-mail and that password and must then choose their own. If the e-mail already signs in elsewhere (e.g.
   a member of another academy), there is no dialog, a note says they use the password they have. Until their first
   sign-in the member shows **Invitation pending**. While pending and before they have chosen a password, you can open their member page
   and use **Generate a new temporary password** for them (it replaces the previous one; refused for a login that is also used in another
   academy: ask the platform administrator).
   A temporary password nobody used **expires after 3 days** (ADR-0028): the person's sign-in page then says "Your
   temporary password has expired. Ask your academy administrator for a new one.", and the member shows **Temporary
   password expired** in the list and on their page. Use **Generate a new temporary password** there: the new one works
   at once (the login is enabled again) and also expires after 3 days if unused.
3. **Edit roles** changes roles later. **Deactivate** removes access (the person is kept, shown as **Inactive**).
4. **Changing the e-mail** of a member who has a login also changes their sign-in address: from then on they sign in
   with the new e-mail; no e-mail is sent and the password does not change. If the person also belongs to another
   academy, the change is refused ("used in another academy"): ask the platform administrator. A member with a login
   cannot have the e-mail removed.

## 3. Guardians (parents and players)
Open a member who has the **Parent** role. Under **Linked players**, use **Link player** and pick the child; remove a
link with the remove action. A parent only sees and edits data of linked players. Links can only be edited for members
with the Parent role, so invite the parent first.

## 4. Seasons and age categories
- **Admin > Seasons > New season**: name, start, end and **Reference year** (used by the birth-year rule). Seasons of
  one academy cannot overlap.
- **Admin > Age categories**: code, name, **Maximum age** (empty = no limit) and **Order**. U8 to U18 and SENIOR are
  created for you; you can edit them. Changing a category re-checks every team assignment.

## 5. Teams and staff
**Teams** tab, pick the season, then **New team**: name, alias (optional), **Category** and **Gender policy**
(Male, Female, Mixed). Open a team to:
- **Staff > Add staff member**: pick a member and the function (Coach or Assistant coach). A coach's authority over a
  team comes from being listed here.
- **Roster > Assign player**: search a player. The app shows **Eligible**, **Plays up (+n)** or **Not eligible** with
  the reasons (too old for the category, play-up limit exceeded, gender policy, missing birth date or gender, player
  not active). Ineligible players cannot be assigned. Set a **Jersey number** when assigning; **Change jersey number**
  and **Remove from roster** are on each row.

## 6. Players and approvals
**Players** tab: filters **Status** (Active, Orphan, Pending approval, Withdrawn), **Team**, **Category**; search box.
- **New player**: names, birth date, gender (required), optional e-mail, optional initial team. As an administrator the
  player is created immediately. With an e-mail the player also gets a login: its temporary password is shown once, as
  for an invitation.
- A player with no valid team is shown as **Orphan** ("Sin equipo válido" in Spanish) until assigned.
- Player detail: basic data, natural category, teams, guardians, **Assign to a team** (eligible teams only), health,
  **Season statistics**, and **Withdraw**.
- **Admin > Pending requests**: coaches ask to add or withdraw players. **Approve** (note optional) or **Reject**
  (note required). Approving an addition may still fail if the player is not eligible for the chosen team; the request
  then stays pending. Approving a player with an e-mail gives them a login; its temporary password is shown once.

## 7. Settings: age rule, play-up, language
**Admin > Academy profile**
- **Age rule**: **By birth year** (default: season reference year minus birth year) or **By birthday** (full years today).
- **Maximum play-up levels**: how many categories above their natural one a player may be placed. Empty means
  unlimited.
- **Default language**: used for people who have not chosen their own.
Saving a change to the age rule or the play-up limit re-evaluates all assignments. Nothing is deleted: assignments that
no longer qualify are marked **No longer eligible** and an eligibility case is opened.

## 8. Eligibility cases and season rollover
**Admin > Eligibility cases** lists open cases (player, invalidated team, reason). For each case choose
**Reassign** (pick an eligible team), **Remove from team** or **Dismiss case**.

**Season rollover**: **Admin > Seasons > Roll over** on the finished season.
1. Choose whether to **Copy team staff** and **Copy rosters**.
2. **Run rollover**. The result shows copied teams, **Players without a valid team** (for example players who aged out)
   and the number of cases opened.
3. **Go to eligibility cases** and resolve them. Under the birth-year rule, rollover is when most orphans appear; under
   the birthday rule they are also found by the nightly check.

## 9. Fitness tests and norms
Players list icons open **Test types** and **Norms**. Global norms are read-only; add your own **Academy override**
rows to replace them. Values flagged **Reference pending** are placeholders, not published norms: override them before
using bands for decisions (see `docs/domain/norms.md`).

## 10. Activity (audit trail)
**Administration → Activity** lists what was done in the academy, newest first: members invited, edited, given new roles
or deactivated, temporary passwords issued or expired, first sign-ins, guardian links, player requests and decisions,
profile, settings and logo changes, and what the platform administration did (administrators added, academy
suspended…). Each entry names the action, what it was about and who did it ("System" for automatic jobs, "Platform
administrator" for the super admin, whose identity is not shown; the reason of a suspension or withdrawal is). Names are shown as they are today; an entry about something that no longer exists
shows its type only. Filter by a date range and by one or several actions; move between pages with the arrows at the
bottom. Only administrators see it. Entries are never edited or deleted, and they are kept (no automatic clean-up yet).

---
Status: written from the implemented screens and the translation files; not yet checked in a manual browser walk-through.
