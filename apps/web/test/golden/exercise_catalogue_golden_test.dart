import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/athlete_scenarios.dart';
import '../support/fake_athlete.dart';
import '../support/pump_helpers.dart';

/// The exercise catalogue tab of the plan library and the exercise editor
/// (WP92) at both breakpoints. Regenerate with
/// `flutter test --update-goldens test/golden/exercise_catalogue_golden_test.dart`.
void main() {
  Future<void> expectGolden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  Future<void> openCatalogue(WidgetTester tester, Size size) async {
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {'t1'},
      core: athleteCore(),
      athlete: FakeAthlete(
        exercises: FakeExercisesRepository(exercises: catalogueExercises()),
      ),
      size: size,
      location: '/training/plans',
    );
    await tapKey(tester, 'tab-exercises');
  }

  for (final (suffix, size) in [
    ('360x780', const Size(360, 780)),
    ('1024x768', const Size(1024, 768)),
  ]) {
    testWidgets('exercise catalogue, COACH, $suffix', (tester) async {
      await openCatalogue(tester, size);
      await expectGolden('exercise_catalogue_$suffix');
    });

    testWidgets('exercise editor, COACH, $suffix', (tester) async {
      await openCatalogue(tester, size);
      await tapKey(tester, 'exercise-menu-own-1');
      await tapKey(tester, 'sheet-action-edit');
      await expectGolden('exercise_editor_$suffix');
    });
  }
}
