# Coach and assistant coach guide

Languages: [Español](coach.es.md) · English · [Bahasa Indonesia](coach.id.md)

You are a **Coach** or an **Assistant coach**. Your rights apply to the teams where an administrator listed you under
**Staff**. Bottom bar: **Teams**, **Matches**, **Training**, **Players**. **Profile** is in the top bar.

## What assistants can and cannot do
| Task | Coach | Assistant coach |
|---|---|---|
| Create matches, set up the roster, start/finish, clock, enter any stat | yes | yes |
| Training calendar, attendance, plans, assignments, absences | yes | yes |
| Injuries, height/weight, physical test results | yes | yes |
| Assign players to a team, resolve eligibility cases (own teams) | yes | no (read only) |
| Request a new player or a withdrawal (needs administrator approval) | yes | no |

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

---
Status: written from the implemented screens and the translation files; not yet checked in a manual browser walk-through.
