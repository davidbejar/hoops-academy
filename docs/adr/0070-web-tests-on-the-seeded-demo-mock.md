# ADR-0070: The web widget tests run against the demo mock, seeded per test

- Status: Accepted (migration complete with WP138 part 5: no repository fake is left)
- Date: 2026-11-24
- Records: decision 108 of 2026-11-23 (audit finding WEB-02)
- Amends: ADR-0030 (its last consequence: the test fakes no longer mirror the feed rule, they go)
- Related: ADR-0061 (the mock pages like the services), ADR-0067, F-20 (no mock in a release),
  [WP138](../wp/WP138-web-tests-on-the-demo-mock.md)

## Context
The web app imitated the services twice: the demo mock behind `MockApiAdapter` (JSON level, about 7,200 lines,
a deliberate demo feature) and the repository fakes of the widget tests (`test/support/fake_*.dart`, 3,580 lines).
Every contract change had to be made in the repository, the mock and the fake, and nothing checked that the mock
and the fake agreed: the migration so far found three places where they did not (below). The fakes also replaced the
app's real repositories, generated clients and error mapping, so a widget test never exercised them.

## Decision
1. **One imitation.** A widget test talks to the demo mock through the app's real repositories, generated clients
   and interceptors. `apiAdapterProvider` (`core/http/dio_provider.dart`) is the one seam: the adapter the app's
   Dio sends through (the mock in mock mode, the network otherwise); the test `Harness` points it at a
   `MockBackend`.
2. **Empty, seeded per test.** `MockBackend` (`test/support/mock_backend.dart`) is the mock built with `demo: false`:
   both academies and the platform start empty (no demo data in a test), the test academy has the id of the
   test membership, and answers come at once (`latency` zero). A test seeds what it needs through the mocks'
   collections, which are `@visibleForTesting`, with helpers that take the generated models (`coreJson`,
   `audit_seed.dart`, `platform_seed.dart`), so the fixtures are the shapes the services send.
3. **Failures in front of the mock.** What the mock cannot produce is injected by `MockBackend`, never by a second
   fake: `fail` (a Problem+JSON with status and business code), `hang` (held until released), `networkDown`, `heal`.
   A failure the mock can produce is produced by it (a taken identifier, a request decided meanwhile, the last
   administrator removed meanwhile).
4. **Assertions on the wire.** Tests read what the app sent (`requests`, `requestsTo`, `lastQuery`, `lastBody`) and
   what the mock answered (`lastAnswer`), instead of fields of a fake.
5. **A difference between mock and fake is decided against the contract** (`libs/contracts/openapi/*.yaml`), with a
   red test on the mock first. Decided so far: the academy trail filters by `action`, `from`, `to`; an existing login
   gets no temporary password (invitation ACCEPTED); the last administrator cannot be removed (409 `LAST_ADMIN`). In
   all three the fake was right and the mock was fixed.
6. **Nothing of it ships.** The seeding hooks live in the mock, and a release build must not hold the mock:
   `build_web.sh` already refuses `HOOPS_MOCK_API`, and now `tool/verify_no_mock.dart` fails the build when
   `main.dart.js` or a deferred part holds a string only the mock API has (checked both ways on real builds).
7. **Feature by feature.** A feature moves in one commit (tests to the backend, its fake deleted, the suite green).
   Where a fake cannot go without making its tests worse it stays, with the reason in the work package.

## Alternatives
- **Keep two layers and share the rules** (one file both call, as `feed_visibility.dart` already is): halves the
  drift, keeps two imitations and the untested repositories.
- **Seed through the public API only:** no hooks at all, but much of what the tests need (another academy's trail,
  usage figures, a login elsewhere) has no create operation, and every set-up would pay a request per row.
- **Tests on the demo data:** no seeding code, but every change to the demo would break unrelated tests and a test
  would no longer say what it depends on.

## Consequences
- A widget test now covers the repository, the generated client's (de)serialisation and the error mapping too.
- The mock has to model what the tests need (it gained usage, history and login seeding and three contract rules);
  the demo improves with it.
- Until the migration ends, core, athlete, game and finance tests still use their fakes (`fake_repos.dart`,
  `fake_athlete.dart`, `fake_game.dart`, `fake_finance.dart`); the `Harness` combines both (a faked repository wins,
  everything else reaches the empty mock).
- *Amendment (WP138 part 2):* `MockAuthService` is chosen only in a demo build (`mockBuild`, a compile-time
  constant), so a release no longer holds it; `verify_no_mock.dart` checks its token too.
- *Amendment (WP138 part 4):* the finance, game and athlete mocks gained seeding hooks (`seedPlan`, `seedDues`,
  `seedExpense`, `seedCurrency`; `seedMatch`, `seedRoster`, `seedEvent`; the exercise catalogue), which the demo's own
  finance seed now uses too, so a test seeds an empty academy explicitly. The match screens use the app's real
  `ApiEventsRemote` on the mock, so the box score, the feed and the season statistics come from the same stored
  events; the Drift store and the sync timers stay in the test, and `FakeGameServer` stays as the sync worker's
  contract fake (it is not an imitation of the screens' backend).
- *Amendment (WP138 part 5):* the athlete side is migrated too (training, plans, health, fitness): every widget and
  provider test runs the app's real repositories on the mock, and the repository fakes are gone. The athlete mock
  exposes its collections and its answer views (`resultView`, `planView`, `assignmentView`) for seeding and reading
  back; the data classes of `athlete_seed.dart` share one base (seed once, failures and hangs on their own paths,
  `MockBackend.heal(path)` heals only those). What the mock computes is seeded, not told: a result's band comes from
  seeded norms, an attendance sheet from the roster, the planned absences and the open injuries. `FakeCore` and
  `FakeAthlete` remain as plain data bundles (in `core_seed.dart` and `athlete_seed.dart`); `FakeGameServer` stays as
  the sync worker's contract fake. A provider test listens to an auto-dispose provider as a screen does, because the
  answers now arrive asynchronously.
