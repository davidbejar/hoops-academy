import 'package:built_collection/built_collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

void main() {
  group('seasons', () {
    const path = '/admin/seasons';

    testWidgets('loading / error / empty', (tester) async {
      final loading = FakeCore()..seasons.hang = true;
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: loading,
        location: path,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      final core = FakeCore()
        ..seasons.failWith = const AppError(kind: AppErrorKind.timeout);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      final core = FakeCore(seasons: FakeSeasonsRepository([]));
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      expect(find.text('Aún no hay temporadas'), findsOneWidget);
    });

    testWidgets('populated shows the current season marker', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: path,
      );
      expect(find.text('2026/27'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
    });

    testWidgets('create with the date pickers', (tester) async {
      final core = FakeCore();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      await tapKey(tester, 'season-new');
      await enter(tester, 'season-name', '2027/28');
      await tapKey(tester, 'form-submit');
      expect(find.byKey(const Key('season-dates-error')), findsOneWidget);

      Future<void> pickDay(String key, String day) async {
        await tapKey(tester, key);
        await tester.tap(find.text(day).last);
        await tester.pump();
        await tester.tap(find.text('ACEPTAR'));
        await tester.pumpAndSettle();
      }

      // Start is "today" by default in the picker; pick the 10th, then the 20th.
      await pickDay('season-start', '10');
      await pickDay('season-end', '20');
      await tapKey(tester, 'form-submit');
      expect(core.seasons.calls, contains('create'));
      expect(find.text('2027/28'), findsOneWidget);
    });
  });

  group('rollover wizard', () {
    testWidgets(
      'confirm -> result lists orphans with a link to eligibility cases',
      (tester) async {
        final result = api.SeasonRolloverResult(
          (b) => b
            ..fromSeasonId = seasonId
            ..toSeasonId = 'next'
            ..clonedTeams.replace([
              teamRef('t1', 'Mini A'),
              teamRef('t2', 'Mini B'),
            ])
            ..orphans.replace([
              api.Orphan(
                (o) => o
                  ..player.replace(playerRef('p9', 'Ana Ruiz'))
                  ..previousTeam.replace(teamRef('t1', 'Mini A'))
                  ..reasons = ListBuilder<api.EligibilityReason>([
                    api.EligibilityReason.CATEGORY_TOO_LOW,
                  ]),
              ),
            ])
            ..openedCaseIds.replace(['c1']),
        );
        final core = FakeCore(
          seasons: FakeSeasonsRepository([
            season(seasonId, '2026/27', current: true),
          ], rolloverResult: result),
        );
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '/admin/seasons/$seasonId/rollover',
          size: const Size(360, 1100),
        );
        expect(find.byKey(const Key('rollover-intro')), findsOneWidget);
        expect(core.seasons.rolledFrom, isNull);

        await tapKey(tester, 'rollover-clone-players'); // untick
        await tapKey(tester, 'rollover-run');
        expect(core.seasons.rolledFrom, seasonId);
        expect(core.seasons.lastCloneStaff, isTrue);
        expect(core.seasons.lastClonePlayers, isFalse);
        expect(find.text('Cambio de temporada completado'), findsOneWidget);
        expect(find.text('Equipos copiados: 2'), findsOneWidget);
        expect(find.text('Ana Ruiz (antes: Mini A)'), findsOneWidget);
        expect(
          find.text('Es demasiado mayor para esta categoría'),
          findsOneWidget,
        );

        await tapKey(tester, 'rollover-go-cases');
        expect(find.text('No hay casos abiertos'), findsOneWidget);
      },
    );

    testWidgets(
      'a failing rollover keeps the confirm step and shows a localized error',
      (tester) async {
        final core = FakeCore();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '/admin/seasons/$seasonId/rollover',
        );
        core.seasons.failWith = const AppError(
          kind: AppErrorKind.conflict,
          status: 409,
        );
        await tapKey(tester, 'rollover-run');
        expect(find.byKey(const Key('rollover-run')), findsOneWidget);
        expect(find.byKey(const Key('rollover-done')), findsNothing);
        expect(find.textContaining('Los datos han cambiado'), findsOneWidget);
      },
    );

    testWidgets('no orphans shows the all-clear', (tester) async {
      final core = FakeCore();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '/admin/seasons/$seasonId/rollover',
      );
      await tapKey(tester, 'rollover-run');
      expect(find.byKey(const Key('rollover-no-orphans')), findsOneWidget);
    });
  });

  group('age categories', () {
    const path = '/admin/age-categories';

    testWidgets('empty / error', (tester) async {
      final empty = FakeCore(categories: FakeAgeCategoriesRepository([]));
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: empty,
        location: path,
      );
      expect(find.text('Aún no hay categorías'), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      final core = FakeCore()
        ..categories.failWith = const AppError(kind: AppErrorKind.network);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('populated sorted by order, with limits', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: path,
      );
      expect(find.text('U12 · Mini'), findsOneWidget);
      expect(find.text('Hasta 12 años'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('U12 · Mini')).dy,
        lessThan(tester.getTopLeft(find.text('U14 · Infantil')).dy),
      );
    });

    testWidgets('create validates numbers, saves, and delete confirms', (
      tester,
    ) async {
      final core = FakeCore();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      await tapKey(tester, 'category-new');
      await enter(tester, 'category-max-age', '200');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(
        find.text('Introduce un número válido'),
        findsNWidgets(2),
      ); // max age + rank

      await enter(tester, 'category-code', 'U16');
      await enter(tester, 'category-name', 'Cadete');
      await enter(tester, 'category-max-age', '');
      await enter(tester, 'category-rank', '3');
      await tapKey(tester, 'form-submit');
      expect(core.categories.categories.last.code, 'U16');
      expect(core.categories.categories.last.maxAge, isNull);
      expect(find.text('Sin límite de edad'), findsOneWidget);

      await tapKey(tester, 'category-delete-$catU12Id');
      expect(find.textContaining('¿Eliminar la categoría'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(core.categories.categories.any((c) => c.id == catU12Id), isFalse);
    });
  });
}
