import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/fake_platform.dart' show problem;
import '../../support/pump_helpers.dart';

final _jump = testType('ty-jump', 'VJ', 'Salto vertical', 'cm');
final _sprint = testType('ty-sprint', 'S20', 'Sprint 20 m', 's', higher: false);

FakeAthlete _athlete() => FakeAthlete(
  health: FakeHealthRepository(
    injuries: [
      injury('inj-1', 'p1', part: 'Rodilla', expected: ath.Date(2026, 11, 30)),
      injury(
        'inj-2',
        'p1',
        part: 'Tobillo',
        severity: ath.InjurySeverity.MINOR,
        status: ath.InjuryStatus.RECOVERED,
        actual: ath.Date(2026, 9, 20),
      ),
    ],
    measurements: [
      measurement('m1', 'p1', ath.Date(2026, 1, 10), height: 140, weight: 35),
      measurement('m2', 'p1', ath.Date(2026, 6, 10), height: 144, weight: 37.5),
      measurement('m3', 'p1', ath.Date(2026, 10, 10), height: 148, weight: 40),
    ],
  ),
  fitness: FakeFitnessRepository(
    types: [
      _jump,
      _sprint,
      testType('ty-custom', 'CUS', 'Test club', 'pts', global: false),
    ],
    norms: [
      norm('n1', 'ty-jump', band: ath.NormBand.BELOW_AVERAGE, min: 20, max: 30),
      norm(
        'n2',
        'ty-jump',
        band: ath.NormBand.AVERAGE,
        min: 30,
        max: 40,
        pending: true,
      ),
      norm(
        'n3',
        'ty-jump',
        band: ath.NormBand.EXCELLENT,
        min: 40,
        max: 60,
        global: false,
        source: 'Club 2026',
      ),
    ],
    results: [
      testResult(
        'r1',
        'p1',
        _jump,
        28,
        ath.Date(2026, 3, 1),
        band: ath.NormBand.BELOW_AVERAGE,
      ),
      testResult(
        'r2',
        'p1',
        _jump,
        34,
        ath.Date(2026, 7, 1),
        band: ath.NormBand.AVERAGE,
        pending: true,
      ),
      testResult('r3', 'p1', _jump, 36, ath.Date(2026, 10, 1)),
    ],
  ),
);

final _reach = testType(
  'ty-reach',
  'SIT_AND_REACH',
  'Flexibilidad (sit and reach)',
  'cm',
);

/// A player with one sit-and-reach and one jump result (the hint belongs to the first only).
FakeAthlete _athleteWithReach() => FakeAthlete(
  fitness: FakeFitnessRepository(
    types: [_jump, _reach],
    results: [
      testResult('r-reach', 'p1', _reach, 22, ath.Date(2026, 10, 1)),
      testResult('r-jump', 'p1', _jump, 30, ath.Date(2026, 10, 1)),
    ],
  ),
);

Future<void> _staff(
  WidgetTester tester,
  FakeAthlete a, {
  String loc = '/players/p1/health',
}) => pumpAs(
  tester,
  roles: {TenantRole.coach},
  staffTeamIds: {'t1'},
  core: athleteCore(),
  athlete: a,
  location: loc,
  size: const Size(360, 2000),
);

void main() {
  group('entry points from the Players module', () {
    testWidgets(
      'player detail links to the health page; the players list links to test types and norms',
      (tester) async {
        final h = await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: _athlete(),
          location: '/players/p1',
        );
        await tapKey(tester, 'player-health');
        expect(
          h.container.read(routerProvider).state.uri.path,
          '/players/p1/health',
        );
        expect(find.text('Rodilla'), findsOneWidget);
        await h.go(tester, '/players');
        await tapKey(tester, 'open-tests');
        expect(
          h.container.read(routerProvider).state.uri.path,
          '/players/tests',
        );
        await h.go(tester, '/players');
        await tapKey(tester, 'open-norms');
        expect(
          h.container.read(routerProvider).state.uri.path,
          '/players/norms',
        );
      },
    );
  });

  group('injuries', () {
    testWidgets(
      'list with severity, status, expected return and availability badge',
      (tester) async {
        await _staff(tester, _athlete());
        expect(find.text('Rodilla'), findsOneWidget);
        expect(find.text('Tobillo'), findsOneWidget);
        expect(find.text('Regreso previsto: 30/11/2026'), findsOneWidget);
        expect(find.text('Recuperada el 20/09/2026'), findsOneWidget);
        expect(find.byKey(const Key('availability-injured')), findsOneWidget);
        expect(find.text('Lesionado: Rodilla'), findsOneWidget);
      },
    );

    testWidgets('available player shows the available badge', (tester) async {
      final a = _athlete();
      a.health.injuryList.removeWhere((i) => i.status == ath.InjuryStatus.OPEN);
      await _staff(tester, a);
      expect(find.byKey(const Key('availability-ok')), findsOneWidget);
    });

    testWidgets('empty, loading and error', (tester) async {
      await _staff(tester, FakeAthlete());
      expect(find.text('Sin lesiones registradas'), findsOneWidget);
      await _staff(
        tester,
        FakeAthlete(health: FakeHealthRepository()..failWith = StateError('x')),
      );
      expect(find.text('Reintentar'), findsWidgets);
    });

    testWidgets(
      'create requires the body part and stores severity and expected return',
      (tester) async {
        final a = _athlete();
        await _staff(tester, a);
        await tapKey(tester, 'injury-new');
        await tapKey(tester, 'form-submit');
        expect(find.text('Campo obligatorio'), findsOneWidget);
        await enter(tester, 'injury-part', 'Muñeca');
        await tapKey(tester, 'injury-severity');
        await tester.tap(find.text('Grave').last);
        await tester.pumpAndSettle();
        await tapKey(tester, 'form-submit');
        expect(a.health.createdInjury!.bodyPart, 'Muñeca');
        expect(a.health.createdInjury!.severity, ath.InjurySeverity.SEVERE);
        expect(a.health.createdInjury!.playerId, 'p1');
        expect(find.text('Muñeca'), findsOneWidget);
      },
    );

    testWidgets(
      'mark recovered sends status and return date; the badge disappears',
      (tester) async {
        final a = _athlete();
        await _staff(tester, a);
        await tapKey(tester, 'injury-recover-inj-1');
        await tester.tap(find.text('ACEPTAR'));
        await tester.pumpAndSettle();
        expect(a.health.lastInjuryUpdate!.status, ath.InjuryStatus.RECOVERED);
        expect(a.health.lastInjuryUpdate!.actualReturnOn, isNotNull);
        expect(find.byKey(const Key('availability-injured')), findsNothing);
        expect(find.byKey(const Key('injury-recover-inj-1')), findsNothing);
      },
    );

    testWidgets('update the expected return date', (tester) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'injury-return-inj-1');
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(a.health.lastInjuryUpdate!.expectedReturnOn, isNotNull);
      expect(a.health.lastInjuryUpdate!.status, isNull);
    });

    testWidgets(
      'edit opens with the current values and sends only values plus clear for emptied fields',
      (tester) async {
        final a = _athlete();
        a.health.injuryList[0] = a.health.injuryList[0].rebuild(
          (b) => b.description = 'Golpe',
        );
        await _staff(tester, a);
        await tapKey(tester, 'injury-edit-inj-1');
        expect(find.widgetWithText(TextFormField, 'Rodilla'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Golpe'), findsOneWidget);
        await enter(tester, 'injury-part', 'Menisco');
        await enter(tester, 'injury-description', '');
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('injury-expected')),
            matching: find.byIcon(Icons.clear),
          ),
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'form-submit');
        final u = a.health.lastInjuryUpdate!;
        expect(u.bodyPart, 'Menisco');
        expect(u.description, isNull);
        expect(u.expectedReturnOn, isNull);
        expect(u.clear!.toSet(), {
          ath.UpdateInjuryRequestClearEnum.description,
          ath.UpdateInjuryRequestClearEnum.expectedReturnOn,
        });
        expect(find.text('Menisco'), findsOneWidget);
      },
    );

    testWidgets(
      'edit validates the body part and names the empty optional fields in clear',
      (tester) async {
        final a = _athlete();
        await _staff(tester, a);
        await tapKey(tester, 'injury-edit-inj-1');
        await enter(tester, 'injury-part', '');
        await tapKey(tester, 'form-submit');
        expect(find.text('Campo obligatorio'), findsOneWidget);
        expect(a.health.lastInjuryUpdate, isNull);
        await enter(tester, 'injury-part', 'Rodilla izq.');
        await tapKey(tester, 'form-submit');
        expect(a.health.lastInjuryUpdate!.bodyPart, 'Rodilla izq.');
        expect(a.health.lastInjuryUpdate!.clear!.toSet(), {
          ath.UpdateInjuryRequestClearEnum.description,
        });
      },
    );

    testWidgets(
      'edit also works on a recovered injury and can clear the return date',
      (tester) async {
        final a = _athlete();
        await _staff(tester, a);
        await tapKey(tester, 'injury-edit-inj-2');
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('injury-actual')),
            matching: find.byIcon(Icons.clear),
          ),
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'form-submit');
        expect(a.health.lastInjuryUpdate!.clear!.toSet(), {
          ath.UpdateInjuryRequestClearEnum.description,
          ath.UpdateInjuryRequestClearEnum.expectedReturnOn,
          ath.UpdateInjuryRequestClearEnum.actualReturnOn,
        });
      },
    );

    testWidgets('a server error keeps the edit dialog open', (tester) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'injury-edit-inj-1');
      a.health.failWith = StateError('x');
      await tapKey(tester, 'form-submit');
      expect(find.byKey(const Key('injury-part')), findsOneWidget);
    });

    testWidgets(
      'edit action is hidden for the PLAYER and shown to the linked PARENT',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.parent},
          linkedPlayerIds: {'p1'},
          core: athleteCore(),
          athlete: _athlete(),
          location: '/my-players',
          size: const Size(360, 2000),
        );
        await tapKey(tester, 'hub-tab-health');
        expect(find.byKey(const Key('injury-edit-inj-1')), findsOneWidget);
        await pumpAs(
          tester,
          roles: {TenantRole.player},
          ownPlayerId: 'p1',
          core: athleteCore(),
          athlete: _athlete(),
          location: '/me',
          size: const Size(360, 2000),
        );
        await tapKey(tester, 'hub-tab-health');
        expect(find.byKey(const Key('injury-edit-inj-1')), findsNothing);
      },
    );

    testWidgets(
      'PARENT of the player records injuries; the PLAYER only reads',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.parent},
          linkedPlayerIds: {'p1'},
          core: athleteCore(),
          athlete: _athlete(),
          location: '/my-players',
          size: const Size(360, 2000),
        );
        await tapKey(tester, 'hub-tab-health');
        expect(find.byKey(const Key('injury-new')), findsOneWidget);
        expect(find.byKey(const Key('injury-recover-inj-1')), findsOneWidget);
        await pumpAs(
          tester,
          roles: {TenantRole.player},
          ownPlayerId: 'p1',
          core: athleteCore(),
          athlete: _athlete(),
          location: '/me',
          size: const Size(360, 2000),
        );
        await tapKey(tester, 'hub-tab-health');
        expect(find.text('Rodilla'), findsOneWidget);
        expect(find.byKey(const Key('injury-new')), findsNothing);
        expect(find.byKey(const Key('injury-recover-inj-1')), findsNothing);
      },
    );
  });

  group('growth', () {
    testWidgets('height and weight charts with a table view of the values', (
      tester,
    ) async {
      await _staff(tester, _athlete());
      await tapKey(tester, 'health-tab-growth');
      expect(find.text('Altura (cm)'), findsOneWidget);
      expect(find.text('Peso (kg)'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Gráfico de Altura')),
        findsOneWidget,
      );
      await tapKey(tester, 'table-toggle-Altura (cm)');
      expect(find.text('148'), findsOneWidget);
      expect(find.text('Ocultar tabla'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await _staff(tester, FakeAthlete());
      await tapKey(tester, 'health-tab-growth');
      expect(find.text('Sin medidas todavía'), findsOneWidget);
    });

    testWidgets('adding needs height or weight (or both)', (tester) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-growth');
      await tapKey(tester, 'growth-add');
      await tapKey(tester, 'form-submit');
      expect(find.byKey(const Key('growth-need-one')), findsOneWidget);
      expect(a.health.createdMeasurement, isNull);
      await enter(tester, 'growth-height', '150,5');
      await tapKey(tester, 'form-submit');
      expect(a.health.createdMeasurement!.heightCm, 150.5);
      expect(a.health.createdMeasurement!.weightKg, isNull);
    });

    testWidgets('invalid number is rejected', (tester) async {
      await _staff(tester, _athlete());
      await tapKey(tester, 'health-tab-growth');
      await tapKey(tester, 'growth-add');
      await enter(tester, 'growth-weight', 'abc');
      await tapKey(tester, 'form-submit');
      expect(find.text('Introduce un número válido'), findsOneWidget);
    });
  });

  group('edit and delete of measurements', () {
    testWidgets('staff edit a measurement; the list shows the new value', (
      tester,
    ) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-growth');
      expect(find.byKey(const Key('measurement-m3')), findsOneWidget);
      await tapKey(tester, 'measurement-edit-m3');
      expect(
        find.widgetWithText(TextFormField, '148'),
        findsOneWidget,
      ); // prefilled
      await enter(tester, 'growth-height', '149,5');
      await tapKey(tester, 'form-submit');
      expect(a.health.updatedMeasurement!.heightCm, 149.5);
      expect(a.health.createdMeasurement, isNull);
      expect(find.textContaining('149.5'), findsWidgets);
    });

    testWidgets('emptying the weight clears it; the height stays', (
      tester,
    ) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-growth');
      await tapKey(tester, 'measurement-edit-m3');
      await enter(tester, 'growth-weight', '');
      await tapKey(tester, 'form-submit');
      expect(a.health.updatedMeasurement!.clear, {
        ath.UpdateBodyMeasurementRequestClearEnum.weightKg,
      });
      expect(a.health.updatedMeasurement!.heightCm, 148);
      final stored = a.health.measurementList.firstWhere((m) => m.id == 'm3');
      expect((stored.heightCm, stored.weightKg), (148, null));
    });

    testWidgets('delete asks first, then removes the measurement', (
      tester,
    ) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-growth');
      await tapKey(tester, 'measurement-delete-m1');
      await tapKey(tester, 'dialog-cancel');
      expect(a.health.measurementList.length, 3);
      await tapKey(tester, 'measurement-delete-m1');
      await tapKey(tester, 'dialog-confirm');
      expect(a.health.measurementList.map((m) => m.id), ['m2', 'm3']);
      expect(find.byKey(const Key('measurement-m1')), findsNothing);
    });

    testWidgets('players have no edit / delete buttons', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.player},
        ownPlayerId: 'p1',
        core: athleteCore(),
        athlete: _athlete(),
        location: '/me',
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'hub-tab-health');
      await tapKey(tester, 'health-tab-growth');
      expect(find.byKey(const Key('measurement-m3')), findsOneWidget);
      expect(find.byKey(const Key('measurement-edit-m3')), findsNothing);
      expect(find.byKey(const Key('measurement-delete-m3')), findsNothing);
    });
  });

  group('edit and delete of test results', () {
    testWidgets(
      'staff correct a result value; the band is refreshed from the server',
      (tester) async {
        final a = _athlete();
        await _staff(tester, a);
        await tapKey(tester, 'health-tab-tests');
        await tapKey(tester, 'result-edit-r3');
        await tester.enterText(find.byKey(const Key('result-value')), '38,5');
        await tester.pump();
        await tapKey(tester, 'form-submit');
        expect(a.fitness.updatedResult!.value, 38.5);
        expect(
          a.fitness.resultList.firstWhere((r) => r.id == 'r3').value,
          38.5,
        );
      },
    );

    testWidgets('emptying the notes of a result clears them', (tester) async {
      final a = _athlete();
      a.fitness.resultList[2] = a.fitness.resultList[2].rebuild(
        (b) => b..notes = 'Con viento',
      );
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-tests');
      await tapKey(tester, 'result-edit-r3');
      await enter(tester, 'result-notes', '');
      await tapKey(tester, 'form-submit');
      expect(a.fitness.updatedResult!.clear, {
        ath.UpdatePhysicalTestResultRequestClearEnum.notes,
      });
      expect(a.fitness.resultList[2].notes, isNull);
    });

    testWidgets('delete asks first, then removes the result', (tester) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-tests');
      await tapKey(tester, 'result-delete-r1');
      await tapKey(tester, 'dialog-confirm');
      expect(a.fitness.resultList.map((r) => r.id), ['r2', 'r3']);
    });
  });

  group('sit-and-reach scale hint (Catley, 20 cm = toes)', () {
    testWidgets('shown with the sit-and-reach results, not with other tests', (
      tester,
    ) async {
      await _staff(tester, _athleteWithReach());
      await tapKey(tester, 'health-tab-tests');
      expect(find.byKey(const Key('scale-hint-SIT_AND_REACH')), findsOneWidget);
      expect(find.textContaining('20 cm'), findsOneWidget);
    });

    testWidgets('shown in the entry dialog once the test is chosen', (
      tester,
    ) async {
      await _staff(tester, _athleteWithReach());
      await tapKey(tester, 'health-tab-tests');
      final inDialog = find.descendant(
        of: find.byType(Dialog),
        matching: find.byKey(const Key('scale-hint-SIT_AND_REACH')),
      );
      await tapKey(tester, 'test-add');
      expect(inDialog, findsNothing);
      await tapKey(tester, 'result-type');
      await tester.tap(find.text('Salto vertical (cm)').last);
      await tester.pumpAndSettle();
      expect(inDialog, findsNothing);
      await tapKey(tester, 'result-type');
      await tester.tap(find.text('Flexibilidad (sit and reach) (cm)').last);
      await tester.pumpAndSettle();
      expect(inDialog, findsOneWidget);
    });

    testWidgets('shown in the correction dialog', (tester) async {
      await _staff(tester, _athleteWithReach());
      await tapKey(tester, 'health-tab-tests');
      await tapKey(tester, 'result-edit-r-reach');
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byKey(const Key('scale-hint-SIT_AND_REACH')),
        ),
        findsOneWidget,
      );
    });
  });

  group('physical tests', () {
    testWidgets(
      'history chart per test type, band chips and the reference-pending flag',
      (tester) async {
        await _staff(tester, _athlete());
        await tapKey(tester, 'health-tab-tests');
        expect(
          find.byKey(const Key('band-chart-Salto vertical')),
          findsOneWidget,
        );
        expect(find.text('Bajo la media'), findsWidgets);
        expect(find.text('Referencia pendiente'), findsOneWidget);
        expect(
          find.text('Sin norma'),
          findsNWidgets(2),
        ); // legend entry + the chip of r3 (no band)
      },
    );

    testWidgets('results entry shows the expected band right after saving', (
      tester,
    ) async {
      final a = _athlete();
      await _staff(tester, a);
      await tapKey(tester, 'health-tab-tests');
      await tapKey(tester, 'test-add');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await tapKey(tester, 'result-type');
      await tester.tap(find.text('Salto vertical (cm)').last);
      await tester.pumpAndSettle();
      await enter(tester, 'result-value', '45');
      await tapKey(tester, 'form-submit');
      expect(find.byKey(const Key('result-band')), findsOneWidget);
      expect(find.text('Resultado guardado. Banda: Excelente'), findsOneWidget);
      await tapKey(tester, 'result-close');
      expect(a.fitness.resultList.last.value, 45);
    });

    testWidgets(
      'a value matching a pending-reference norm flags it in the dialog',
      (tester) async {
        await _staff(tester, _athlete());
        await tapKey(tester, 'health-tab-tests');
        await tapKey(tester, 'test-add');
        await tapKey(tester, 'result-type');
        await tester.tap(find.text('Salto vertical (cm)').last);
        await tester.pumpAndSettle();
        await enter(tester, 'result-value', '35');
        await tapKey(tester, 'form-submit');
        expect(find.text('Resultado guardado. Banda: Medio'), findsOneWidget);
        expect(find.text('Referencia pendiente'), findsWidgets);
      },
    );

    testWidgets('a value without a norm says so', (tester) async {
      await _staff(tester, _athlete());
      await tapKey(tester, 'health-tab-tests');
      await tapKey(tester, 'test-add');
      await tapKey(tester, 'result-type');
      await tester.tap(find.text('Sprint 20 m (s)').last);
      await tester.pumpAndSettle();
      await enter(tester, 'result-value', '3,5');
      await tapKey(tester, 'form-submit');
      expect(
        find.text('Resultado guardado (sin norma aplicable)'),
        findsOneWidget,
      );
    });

    testWidgets('PARENT and PLAYER read results but cannot enter them', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/my-players',
        size: const Size(360, 2000),
      );
      await tapKey(tester, 'hub-tab-health');
      await tapKey(tester, 'health-tab-tests');
      expect(
        find.byKey(const Key('band-chart-Salto vertical')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('test-add')), findsNothing);
    });

    testWidgets('empty', (tester) async {
      await _staff(tester, FakeAthlete());
      await tapKey(tester, 'health-tab-tests');
      expect(find.text('Sin resultados de pruebas'), findsOneWidget);
    });
  });

  group('test types', () {
    testWidgets('lists global and custom types; ADMIN creates a custom one', (
      tester,
    ) async {
      final a = _athlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: a,
        location: '/players/tests',
        size: const Size(360, 1200),
      );
      expect(find.text('Salto vertical (cm)'), findsOneWidget);
      expect(find.text('De la academia'), findsOneWidget);
      expect(find.text('Global'), findsNWidgets(2));
      await tapKey(tester, 'type-new');
      await enter(tester, 'type-code', 'agi');
      await enter(tester, 'type-name', 'Agilidad T');
      await enter(tester, 'type-unit', 's');
      await tapKey(tester, 'type-higher');
      await tapKey(tester, 'form-submit');
      expect(a.fitness.createdType!.code, 'AGI');
      expect(a.fitness.createdType!.higherIsBetter, isFalse);
      expect(find.text('Agilidad T (s)'), findsOneWidget);
    });

    testWidgets(
      'ADMIN edits a custom test type; global types have no edit button',
      (tester) async {
        final a = _athlete();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: a,
          location: '/players/tests',
          size: const Size(360, 1400),
        );
        expect(find.byKey(const Key('type-edit-ty-jump')), findsNothing);
        await tapKey(tester, 'type-edit-ty-custom');
        expect(
          find.widgetWithText(TextFormField, 'Test club'),
          findsOneWidget,
        ); // prefilled
        await enter(tester, 'type-name', 'Test club 2');
        await tapKey(tester, 'form-submit');
        expect(a.fitness.updatedType!.name, 'Test club 2');
        expect(a.fitness.createdType, isNull);
        expect(find.text('Test club 2 (pts)'), findsOneWidget);
      },
    );

    testWidgets(
      'ADMIN changes the code of a custom type and clears its description',
      (tester) async {
        final a = _athlete();
        a.fitness.typeList[2] = a.fitness.typeList[2].rebuild(
          (b) => b..description = 'Circuito',
        );
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: a,
          location: '/players/tests',
          size: const Size(360, 1400),
        );
        await tapKey(tester, 'type-edit-ty-custom');
        await enter(tester, 'type-code', 'cus_2');
        await enter(tester, 'type-description', '');
        await tapKey(tester, 'form-submit');
        expect(a.fitness.updatedType!.code, 'CUS_2');
        expect(a.fitness.updatedType!.clear, {
          ath.UpdatePhysicalTestTypeRequestClearEnum.description,
        });
        expect(find.textContaining('CUS_2'), findsOneWidget);
        expect(find.textContaining('Circuito'), findsNothing);
      },
    );

    testWidgets(
      'ADMIN deletes a custom type after confirming; global types have no delete button',
      (tester) async {
        final a = _athlete();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: a,
          location: '/players/tests',
          size: const Size(360, 1400),
        );
        expect(find.byKey(const Key('type-delete-ty-jump')), findsNothing);
        await tapKey(tester, 'type-delete-ty-custom');
        await tapKey(tester, 'dialog-cancel');
        expect(a.fitness.typeList.length, 3);
        await tapKey(tester, 'type-delete-ty-custom');
        await tapKey(tester, 'dialog-confirm');
        expect(
          a.fitness.typeList.map((t) => t.id),
          isNot(contains('ty-custom')),
        );
        expect(find.text('Test club (pts)'), findsNothing);
        expect(find.text('Tipo de prueba eliminado'), findsOneWidget);
      },
    );

    testWidgets('a type with results is not deleted and the reason is shown', (
      tester,
    ) async {
      final a = _athlete()
        ..fitness.deleteTypeError = problem(409, 'TEST_TYPE_HAS_RESULTS');
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: a,
        location: '/players/tests',
        size: const Size(360, 1400),
      );
      await tapKey(tester, 'type-delete-ty-custom');
      await tapKey(tester, 'dialog-confirm');
      expect(
        find.text(
          'Este tipo de prueba tiene resultados y no se puede eliminar',
        ),
        findsOneWidget,
      );
      expect(find.text('Test club (pts)'), findsOneWidget);
    });

    testWidgets('a coach sees the list but not the create button', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {'t1'},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/players/tests',
      );
      expect(find.text('Salto vertical (cm)'), findsOneWidget);
      expect(find.byKey(const Key('type-new')), findsNothing);
    });
  });

  group('norms admin', () {
    testWidgets(
      'effective layer by default with global read-only rows and the pending flag',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: _athlete(),
          location: '/players/norms',
          size: const Size(360, 1400),
        );
        expect(find.byKey(const Key('norm-n1')), findsOneWidget);
        expect(find.byKey(const Key('norm-n3')), findsOneWidget);
        expect(find.text('Global (solo lectura)'), findsNWidgets(2));
        expect(find.text('Propia de la academia'), findsOneWidget);
        expect(find.text('Referencia pendiente'), findsOneWidget);
        expect(find.byKey(const Key('norm-delete-n1')), findsNothing);
        expect(find.byKey(const Key('norm-delete-n3')), findsOneWidget);
      },
    );

    testWidgets('scope filter asks the repository for GLOBAL / TENANT', (
      tester,
    ) async {
      final a = _athlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: a,
        location: '/players/norms',
        size: const Size(360, 1400),
      );
      await tester.tap(find.text('Globales'));
      await tester.pumpAndSettle();
      expect(a.fitness.normScopes.last, 'GLOBAL');
      expect(find.byKey(const Key('norm-n3')), findsNothing);
      await tester.tap(find.text('De la academia').first);
      await tester.pumpAndSettle();
      expect(a.fitness.normScopes.last, 'TENANT');
      expect(find.byKey(const Key('norm-n3')), findsOneWidget);
      expect(find.byKey(const Key('norm-n1')), findsNothing);
    });

    testWidgets('ADMIN creates a tenant override; age range is validated', (
      tester,
    ) async {
      final a = _athlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: a,
        location: '/players/norms',
        size: const Size(360, 1400),
      );
      await tapKey(tester, 'norm-new');
      await tapKey(tester, 'norm-type');
      await tester.tap(find.text('Salto vertical').last);
      await tester.pumpAndSettle();
      await enter(tester, 'norm-min-age', '12');
      await enter(tester, 'norm-max-age', '10');
      await tapKey(tester, 'form-submit');
      expect(
        find.text('La edad máxima debe ser mayor o igual que la mínima'),
        findsOneWidget,
      );
      await enter(tester, 'norm-max-age', '14');
      await enter(tester, 'norm-min-value', '50');
      await tapKey(tester, 'form-submit');
      expect(a.fitness.savedNorm!.minAge, 12);
      expect(a.fitness.savedNorm!.maxAge, 14);
      expect(a.fitness.savedNorm!.minValue, 50);
      expect(a.fitness.savedNorm!.source_, isNull);
      expect(a.fitness.normList.last.referencePending, isTrue);
    });

    testWidgets('delete a tenant norm after confirming', (tester) async {
      final a = _athlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: a,
        location: '/players/norms',
        size: const Size(360, 1400),
      );
      await tapKey(tester, 'norm-delete-n3');
      await tapKey(tester, 'dialog-confirm');
      expect(a.fitness.normList.map((n) => n.id), ['n1', 'n2']);
    });

    testWidgets('a coach reads norms but cannot edit; empty and error states', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {'t1'},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/players/norms',
        size: const Size(360, 1400),
      );
      expect(find.byKey(const Key('norm-new')), findsNothing);
      expect(find.byKey(const Key('norm-delete-n3')), findsNothing);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: FakeAthlete(),
        location: '/players/norms',
      );
      expect(find.text('No hay normas con este filtro'), findsOneWidget);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: FakeAthlete(
          fitness: FakeFitnessRepository()..failWith = StateError('x'),
        ),
        location: '/players/norms',
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('parents and players are blocked by the destination guard', (
      tester,
    ) async {
      final h = await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/players/norms',
      );
      expect(h.container.read(routerProvider).state.uri.path, '/matches');
      expect(find.byKey(const Key('norm-scope')), findsNothing);
    });
  });
}
