import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/core_seed.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

const _seasons = '/api/core/seasons';
const _categories = '/api/core/age-categories';

void main() {
  group('seasons', () {
    const path = '/admin/seasons';

    testWidgets('loading / error / empty', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: path,
        settle: false,
        prepare: (b) => b.hang(_seasons),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: path,
        prepare: (b) => b.fail(_seasons, status: 504),
      );
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      final core = FakeCore(seasons: []);
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
      final h = await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
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
      expect(h.backend.lastBody(_seasons)['name'], '2027/28');
      expect(find.text('2027/28'), findsOneWidget);
    });
  });

  group('rollover wizard', () {
    testWidgets(
      'confirm -> result lists orphans with a link to eligibility cases',
      (tester) async {
        // Two teams; Ana (born 2014) is too old for Mini A (U12) next season.
        final h = await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: FakeCore(),
          location: '/admin/seasons/$seasonId/rollover',
          size: const Size(360, 1100),
          prepare: (b) => b
            ..seedTeams([team('t1', 'Mini A'), team('t2', 'Mini B')])
            ..seedPlayers([
              player(
                'p9',
                'Ana Ruiz',
                teams: [assignment('t1', 'Mini A')],
              ).rebuild((b) => b.birthDate = api.Date(2014, 3, 4)),
            ]),
        );
        const rollover = '$_seasons/$seasonId/rollover';
        expect(find.byKey(const Key('rollover-intro')), findsOneWidget);
        expect(h.backend.requestsTo(rollover, method: 'POST'), isEmpty);

        await tapKey(tester, 'rollover-clone-players'); // untick
        await tapKey(tester, 'rollover-run');
        final sent = h.backend.lastBody(rollover);
        expect(sent['fromSeasonId'], seasonId);
        expect(sent['cloneStaff'], isTrue);
        expect(sent['clonePlayers'], isFalse);
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
        final h = await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: FakeCore(),
          location: '/admin/seasons/$seasonId/rollover',
        );
        h.backend.fail('$_seasons/$seasonId/rollover', status: 409);
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
      final empty = FakeCore(categories: []);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: empty,
        location: path,
      );
      expect(find.text('Aún no hay categorías'), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: path,
        prepare: (b) => b.networkDown(_categories),
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
      final h = await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
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
      expect(h.backend.core.categories.last['code'], 'U16');
      expect(h.backend.core.categories.last['maxAge'], isNull);
      expect(find.text('Sin límite de edad'), findsOneWidget);

      await tapKey(tester, 'category-delete-$catU12Id');
      expect(find.textContaining('¿Eliminar la categoría'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(
        h.backend.core.categories.any((c) => c['id'] == catU12Id),
        isFalse,
      );
    });
  });
}
