import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/health/presentation/charts.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/training/application/training_providers.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

import '../support/athlete_scenarios.dart' show athleteCore;
import '../support/fake_athlete.dart';
import '../support/pump_helpers.dart';

/// Regenerate with `flutter test --update-goldens test/golden`.
/// "Today" is pinned to Monday 2026-11-02 (the week shown and the highlighted day), so the picture is the same on
/// any day the test runs.
DateTime _today() => DateTime(2026, 11, 2);

DateTime _day(int offset) => DateTime(2026, 11, 2 + offset);

void main() {
  testWidgets('week calendar, ADMIN, 360x780', (tester) async {
    final athlete = FakeAthlete(
      training: FakeTrainingRepository(
        sessions: [
          session('s1', day: _day(1), hour: 18, location: 'Pabellón Norte'),
          session(
            's2',
            day: _day(3),
            hour: 19,
            minutes: 60,
            location: 'Pista 2',
          ),
          session('s3', day: _day(3), hour: 17, teamId: 't2', location: null),
          session(
            's4',
            day: _day(5),
            hour: 10,
            status: ath.TrainingSessionStatus.CANCELLED,
            cancelReason: 'Lluvia',
          ),
        ],
      ),
    );
    await pumpAs(
      tester,
      roles: {TenantRole.admin},
      core: athleteCore(),
      athlete: athlete,
      overrides: [nowProvider.overrideWithValue(_today)],
      location: '/training',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/training_week_360x780.png'),
    );
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
