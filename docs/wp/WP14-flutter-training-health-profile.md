# WP14 — Flutter: training & attendance, health & fitness, player profile, super-admin console

Model: Sonnet. Depends on: WP11, WP8–WP10 contracts, WP3 (platform API). Lane WEB. Skills: flutter-feature, test-driven-development.

## Scope
- features/training: week calendar per team, session detail (location, plan, attendance sheet for staff), schedule
  editor, ad-hoc session, planned absence form (parent/player), plan library (templates + own), plan editor, assignment,
  completion marking (player: DONE/PARTIAL/NOT_DONE), progress view for staff.
- features/health: injuries (list/create/update return), availability badge, body measurements with growth charts
  (height/weight over time, fl_chart), physical tests: results entry (staff) with expected band shown, history chart vs
  band, norms admin (tenant override) with "reference pending" flag display.
- features/profile: player sees own season stats, trainings, plans, health; parent switches between linked children;
  language picker (es/en/id); logout.
- features/platform (super_admin): tenants list/create/suspend/withdraw, usage dashboard (counts per tenant).

## Acceptance
- [ ] widget tests per screen incl. role variants; goldens for calendar and growth chart (360 px)
- [ ] charts render with sample data; band colouring consistent (dataviz tokens)
- [ ] localization parity; `flutter analyze && flutter test` green
