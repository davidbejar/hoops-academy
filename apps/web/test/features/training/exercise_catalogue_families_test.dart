import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

/// Decision 82 (WP108): PARENT and PLAYER browse the exercise catalogue from
/// the training area, read-only; staff keep the plan library's tab.
FakeAthlete _athlete() => FakeAthlete(
  plans: weekAthlete().plans,
  exercises: FakeExercisesRepository(exercises: catalogueExercises()),
);

Future<void> _pump(
  WidgetTester tester,
  Set<TenantRole> roles, {
  String location = '/training',
  Set<String> linkedPlayerIds = const {},
  String? ownPlayerId,
  Size size = const Size(360, 1600),
}) => pumpAs(
  tester,
  roles: roles,
  linkedPlayerIds: linkedPlayerIds,
  ownPlayerId: ownPlayerId,
  core: athleteCore(),
  athlete: _athlete(),
  size: size,
  location: location,
);

final _families = {
  'PARENT': ({TenantRole.parent}, const <String>{'p1'}, null as String?),
  'PLAYER': ({TenantRole.player}, const <String>{}, 'p1' as String?),
};

void main() {
  for (final MapEntry(key: name, value: (roles, linked, own))
      in _families.entries) {
    group(name, () {
      testWidgets('reaches the catalogue from the training area', (
        tester,
      ) async {
        await _pump(tester, roles, linkedPlayerIds: linked, ownPlayerId: own);
        await tapKey(tester, 'menu-exercises');

        expect(find.byKey(const Key('exercise-list')), findsOneWidget);
        expect(find.byKey(const Key('exercise-row-g-cooper')), findsOneWidget);
        expect(find.byKey(const Key('exercise-row-own-1')), findsOneWidget);
        expect(
          find.byKey(const Key('exercise-global-g-cooper')),
          findsOneWidget,
        );
      });

      testWidgets('cannot create, edit or archive', (tester) async {
        await _pump(
          tester,
          roles,
          location: '/training/exercises',
          linkedPlayerIds: linked,
          ownPlayerId: own,
        );

        expect(find.byKey(const Key('exercise-row-own-1')), findsOneWidget);
        expect(find.byKey(const Key('exercise-new')), findsNothing);
        expect(find.byKey(const Key('exercise-menu-own-1')), findsNothing);
        expect(find.byKey(const Key('exercise-show-archived')), findsNothing);
        expect(find.byKey(const Key('exercise-row-own-old')), findsNothing);
      });

      testWidgets('the scope chips and the search narrow the list', (
        tester,
      ) async {
        await _pump(
          tester,
          roles,
          location: '/training/exercises',
          linkedPlayerIds: linked,
          ownPlayerId: own,
        );
        await tapKey(tester, 'exercise-scope-academy');

        expect(find.byKey(const Key('exercise-row-own-1')), findsOneWidget);
        expect(find.byKey(const Key('exercise-row-g-cooper')), findsNothing);
      });
    });
  }

  testWidgets('staff do not get the extra entry: they have the library', (
    tester,
  ) async {
    await _pump(tester, {TenantRole.coach});
    expect(find.byKey(const Key('menu-plans')), findsOneWidget);
    expect(find.byKey(const Key('menu-exercises')), findsNothing);
  });
}
