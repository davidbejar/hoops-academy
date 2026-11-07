import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/health/presentation/charts.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/training/application/training_providers.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

import '../support/athlete_scenarios.dart';
import '../support/core_fixtures.dart';
import '../support/fake_repos.dart';
import '../support/fake_athlete.dart';
import '../support/pump_helpers.dart';

/// The training week and the player health screens are two of the four
/// screens showcased on the landing page (`assets/landing/training_week.png`,
/// `player_health.png`); the data mirrors the demo mock (`lib/core/mock`):
/// Mini A at Pabellón Norte, Infantil A at Pabellón Sur, Leo Gil's left knee.
/// Regenerate with
/// `flutter test --update-goldens test/golden/training_health_golden_test.dart`.
/// "Today" is pinned to Thursday 2026-11-05 (the week shown and the highlighted
/// day), so the picture is the same on any day the test runs.
DateTime _today() => DateTime.utc(2026, 11, 5, 10);

/// [hour]:[minute] in Madrid (UTC+1 in November) on 2026-11-(2 + [offset]).
DateTime _madrid(int offset, int hour, int minute) =>
    DateTime.utc(2026, 11, 2 + offset, hour - 1, minute);

ath.TrainingSession _demo(
  String id,
  int offset,
  int hour,
  int minute, {
  required String teamId,
  required String place,
  int minutes = 90,
  ath.TrainingSessionStatus status = ath.TrainingSessionStatus.DONE,
}) => session(
  id,
  day: DateTime(2026, 11, 2),
  teamId: teamId,
  location: place,
  minutes: minutes,
  status: status,
).rebuild((b) => b..startsAt = _madrid(offset, hour, minute));

FakeCore _demoCore() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [
      team('t1', 'Mini A', players: 3),
      team('t2', 'Infantil A', cat: u14, players: 1),
    ],
  ),
  players: FakePlayersRepository([
    player('p2', 'Leo Gil', cat: u12, teams: [assignment('t1', 'Mini A')]),
  ]),
);

FakeAthlete _demoWeek() => FakeAthlete(
  training: FakeTrainingRepository(
    sessions: [
      _demo('s1', 0, 17, 30, teamId: 't1', place: 'Pabellón Norte'),
      _demo('s2', 1, 18, 30, teamId: 't2', place: 'Pabellón Sur'),
      _demo('s3', 2, 17, 30, teamId: 't1', place: 'Pabellón Norte'),
      _demo(
        's4',
        3,
        18,
        30,
        teamId: 't2',
        place: 'Pabellón Sur',
        status: ath.TrainingSessionStatus.PLANNED,
      ),
      _demo(
        's5',
        4,
        17,
        0,
        teamId: 't1',
        place: 'Pista exterior',
        minutes: 60,
        status: ath.TrainingSessionStatus.CANCELLED,
      ),
    ],
  ),
);

FakeAthlete _leoHealth() => FakeAthlete(
  health: FakeHealthRepository(
    injuries: [
      injury(
        'inj-1',
        'p2',
        part: 'rodilla izquierda',
        expected: ath.Date(2026, 11, 18),
      ).rebuild(
        (b) => b
          ..occurredOn = ath.Date(2026, 10, 31)
          ..description = 'Golpe en un entrenamiento',
      ),
    ],
  ),
);

void main() {
  Future<void> expectGolden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  void useBrightness(WidgetTester tester, Brightness brightness) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  for (final (name, size, brightness) in [
    ('training_week_360x780', const Size(360, 780), Brightness.light),
    ('training_week_360x780_dark', const Size(360, 780), Brightness.dark),
    ('training_week_1024x768', const Size(1024, 768), Brightness.light),
  ]) {
    testWidgets('week calendar, ADMIN, $name', (tester) async {
      useBrightness(tester, brightness);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _demoCore(),
        athlete: _demoWeek(),
        timezone: 'Europe/Madrid',
        size: size,
        overrides: [nowProvider.overrideWithValue(_today)],
        location: '/training',
      );
      await expectGolden(name);
    });
  }

  for (final (name, brightness) in [
    ('player_health_360x780', Brightness.light),
    ('player_health_360x780_dark', Brightness.dark),
  ]) {
    testWidgets('player health, injuries, ADMIN, $name', (tester) async {
      useBrightness(tester, brightness);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _demoCore(),
        athlete: _leoHealth(),
        location: '/players/p2/health',
      );
      await expectGolden(name);
    });
  }

  testWidgets('session detail with attendance, ADMIN, 360x780', (tester) async {
    await pumpAs(
      tester,
      roles: {TenantRole.admin},
      core: athleteCore(),
      athlete: weekAthlete(),
      overrides: [nowProvider.overrideWithValue(_today)],
      location: '/training/session/s1',
    );
    await expectGolden('session_detail_360x780');
  });

  testWidgets('growth chart (height and weight), 360x780', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final heights = [
      for (final (m, h) in [
        (1, 138.0),
        (3, 140.5),
        (5, 142.0),
        (7, 144.5),
        (9, 146.0),
        (11, 148.5),
      ])
        ChartPoint(DateTime.utc(2026, m, 10), h),
    ];
    final weights = [
      for (final (m, w) in [
        (1, 33.0),
        (3, 34.5),
        (5, 35.0),
        (7, 37.0),
        (9, 38.5),
        (11, 40.0),
      ])
        ChartPoint(DateTime.utc(2026, m, 10), w),
    ];
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(title: const Text('Ana Ruiz')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GrowthChart(title: 'Altura (cm)', points: heights),
              GrowthChart(title: 'Peso (kg)', points: weights),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/growth_chart_360x780.png'),
    );
  });
}
