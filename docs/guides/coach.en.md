# Coach and assistant coach guide

Languages: [Español](coach.es.md) · English · [Bahasa Indonesia](coach.id.md)

You sign in with your e-mail address and your password.

You are a **Coach** or an **Assistant coach**. Your rights apply to the teams where an administrator listed you under
**Staff**. Bottom bar: **Teams**, **Matches**, **Training**, **Players**.
The round button with your initials (top right) opens a menu: **Profile** (your name, sign out), **Language** and
**Theme** (**System**, **Light**, **Dark**; remembered in this browser, **System** follows your device).

## What assistants can and cannot do
| Task | Coach | Assistant coach |
|---|---|---|
| Create matches, set up the roster, start/finish, clock, enter any stat | yes | yes |
| Training calendar, attendance, plans, assignments, absences | yes | yes |
| Injuries, height/weight, physical test results | yes | yes |
| Assign players to a team, resolve eligibility cases (own teams) | yes | no (read only) |
| Request a new player or a withdrawal (needs administrator approval) | yes | no |
| Change a player's preferred jersey number | yes | no (read only) |
| Export the team roster (CSV) | yes (teams you coach now) | no |
| Exercise catalogue: create, edit, archive own exercises | yes | yes |

Screens you may not use show "Read-only: you are not allowed to change this".

## 1. Match setup
**Matches** tab: list with a team filter and status chips (Scheduled, Live, Finished, Cancelled).
1. **New match**: team, opponent, date. Default format is 4 periods of 10 minutes.
2. Open the match and choose **Set up roster**: tick the players, mark **Starter** and give a **Jersey** number. At least
   one starter is required. Setup needs a connection; once saved, the roster is cached on the device.
3. **Start match**.

## 2. Live scoring
The live view has a header (score, period, clock) and three tabs: **Court**, **Plays**, **Box score**.
- **Start Q1** / **End Q1** control periods. **Start the clock** / **Stop the clock** and the **Minus/Plus 10 seconds**
  buttons run a local game clock (a convenience, not stored as a play).
- **Court** shows the five on court and the bench. Tap a player to open the action sheet: 2 PT / 3 PT / FT made or missed,
  Assist, Off. rebound, Def. rebound, Steal, Block, Turnover, Personal / Technical / Unsportsmanlike foul.
- Tap a bench player to substitute: "X comes in for..." and pick who leaves.
- Header buttons: **Opp +1 / +2 / +3** for the opponent, **Timeout** and **Opponent timeout**, **Undo**.
- **Plays** tab lists every entry with its sync state and who recorded it. **Void** cancels a play (a VOID entry is
  recorded; nothing is deleted). **Undo** voids your last play still in effect.
- **Box score** tab: period scores, per-player table, team totals and **Copy result**. A line "N consistency warnings
  (fix with Void)" means the entered plays contradict each other (for example a substitution of someone not on court).
- **Finish match** ends it. Corrections stay possible afterwards.
Several people (two coaches, parents) can score at once; their plays are merged by game time.
You (and the admin) see every play. Parents and players see team plays (periods, opponent points, timeouts, team notes)
plus their own children's or their own plays only, with the official score.

## 3. Working offline and the "N unsynced" banner
Every play is written to the device first, then sent in the background. You can keep scoring with no network as long as
the app tab stays open.
- Each play shows **Pending**, **Sending**, **Synced** or **Rejected: reason**.
- The banner **"N unsynced"** (with **Retry**) shows plays not yet confirmed. It clears by itself when the connection
  returns, when you reopen the app, or when you sign in again. Retries back off from 1 to 60 seconds.
- **Sign in again to sync; your data is kept**: your session expired. Sign in; the queue is sent afterwards.
- **Rejected** plays (for example "not allowed", "match cancelled") will never be accepted: **Discard** them.
- Replaying a batch is safe: duplicates are recognised, nothing is counted twice.
- Known limits: reopening the app with no network at all relies on a service worker that has not yet been checked in a real
  browser; do not open the same match in two tabs of one device.

## 4. Training
**Training** tab: week calendar with previous/next/today and a team filter. Menu: **Plans**, **Schedules**,
**Absences**, **Assignments**.
- **Schedules > New schedule**: weekday, time, duration, location, validity. Sessions are created automatically ahead
  of time; a one-off session is added with **New session**.
- Open a session for details; **Cancel session** asks for a reason. **Attendance**: mark each player **Present**, **Late**
  (minutes 1-180), **Absent** or **Excused**, then **Save attendance**. Players with a planned absence show a chip and
  are pre-selected as Excused; injured players show **Injured**.
- **Plans**: tabs **Our plans** and **Templates**. A template is read-only; **Use template** copies it. In the editor add
  exercises (title, minutes, sets, reps, https video link) and reorder with Move up/Move down.
- **Assign**: to a team or a player, with a due date. **Assignments** shows Done / Partial / Not done counts; open one to see
  each player and mark completion yourself if needed.
- **Absences**: record a planned absence for any player (from, to, reason).

## 5. Health and fitness entries
**Players** > a player > health icon:
- **Injuries**: **Record injury** (body part, severity Minor/Moderate/Severe, date, expected return). **Mark recovered**
  when back. Injured players are shown as unavailable.
- **Growth**: **Add measurement** (height cm, weight kg; one per day); chart or table.
- **Physical tests**: **Record result**; the app answers with the **expected band** for the player's age and gender. "No
  norm for this age and gender" means no matching norm; **Reference pending** means the norm is a placeholder.

## 6. Requesting players (coach only)
**Players** > **Request new player**: names, birth date, gender, optional e-mail, initial team (must be one you coach)
and a note for the administrator. **Players > My requests** lists them; cancel a pending one with **Cancel request**.
To withdraw a player of your team use **Withdraw** on the player: it is sent as a request. The player stays visible only
to you and the administrators until approved. You cannot approve your own request.

## 7. Exercise catalogue and adding exercises
**Training > Plans** has a third tab, **Exercises**: the exercise catalogue.
- **Global** exercises (the exercises of the templates plus the Cooper test, shown in your language) are read-only.
  Your academy's own exercises are created with **New exercise**, edited, archived (**Archive**) and restored
  (**Restore**) by coaches, assistant coaches and administrators. Filter with **All**, **Global** and **Academy**;
  **Show archived** lists archived ones too; **Load more** at the end. The plan search also finds catalogue exercises.
- **Add exercises** on a session, in the **New session** dialog and **Add from catalogue** in the plan editor: search
  (e.g. "cooper"); catalogue exercises come first, matching items of your plans and templates below. Tick several and
  press **Add (n)**: they are added in the order you ticked them. In the new-session dialog they are added once the
  session exists; if that fails, the session is kept and the dialog says why.
- An added item keeps its own text, which you may edit, and is marked **From the exercise catalogue**. Archiving an
  exercise leaves the items that use it as they are, but an archived exercise cannot be added again ("That exercise is
  archived: pick another one").

## 8. Jersey numbers
- The player page shows the **Preferred jersey number**. Coaches change it (**Change preferred number**; one or two
  digits, empty removes it); assistant coaches only see it. Parents and players may enter it as a wish.
- When you assign a player to one of your teams without typing a number, the app uses the preferred number if it is
  free on that team, else the number of the player's most recent team that had one, if free, else none, and says which
  rule applied. With no number the picker opens at once: it lists **Taken numbers** with their players and **Free
  numbers** (0-99); a taken number is refused with its holder.

## 9. Exports
- **Team roster** (the team's current coach only; not for a team you coached in an ended season): the download icon in
  the team's top bar (**Export the roster (CSV)**) saves the players with their data, category, eligibility and guardians'
  contact data, and the staff as a second block. The server builds it: it needs a connection, uses the app's language
  and is recorded in the academy's activity. Assistant coaches have no roster export.
- Built on your device from what the screen has already loaded (download icon **Export**): **Season statistics**
  (one row per match plus the totals) and a match's box score as a **CSV file** or an **Excel file**; the matches list and
  the training week as a team calendar (matches and sessions of the selected season) as CSV, Excel or **Calendar file
  (.ics)**, which a phone or desktop calendar can import. Excel is loaded the first time you choose it and needs a
  connection then; without one the app says so and the CSV file still works.

## 10. Your name
**Profile > Your name** changes your own first and last name as this academy sees it (**Save name**; needs a
connection); it starts with your first and last name as this academy stores them. Your e-mail stays with the
administrator.

---
Status: written from the implemented screens and the translation files; not yet checked in a manual browser walk-through.
