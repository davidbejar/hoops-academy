import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/training/application/exercise_providers.dart';
import 'package:hoops_app/features/training/application/training_providers.dart';
import 'package:hoops_app/features/training/domain/exercise_filter.dart';

import '../../support/fake_athlete.dart';

/// The catalogue's state (WP92): what is asked for, paging and the commands.
void main() {
  late FakeExercisesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeExercisesRepository(
      exercises: [
        exercise('g-cooper', 'Test de Cooper (12 min)', global: true),
        exercise('g-ft', 'Tiros libres', global: true),
        exercise('own-1', 'Rueda de pases', minutes: 8),
        exercise('own-old', 'Zona 2-3', archived: true),
      ],
    );
    container = ProviderContainer(
      overrides: [
        exercisesRepositoryProvider.overrideWithValue(repo),
        uiLanguageProvider.overrideWithValue('id'),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<List<String>> shown() async => [
    for (final e in (await container.read(
      exerciseCatalogueProvider.future,
    )).items)
      e.id,
  ];

  ExerciseFilterNotifier filter() =>
      container.read(exerciseFilterProvider.notifier);

  test(
    'starts with both scopes, no archived ones, in the UI language',
    () async {
      expect(await shown(), ['own-1', 'g-cooper', 'g-ft']);
      expect(repo.queries.single, (
        query: null,
        scope: null,
        includeArchived: false,
        page: 0,
        size: ExerciseCatalogueNotifier.pageSize,
        language: 'id',
      ));
      expect(container.read(exerciseCatalogueProvider).value!.hasMore, isFalse);
    },
  );

  test('the filter is sent as asked: trimmed text, scope, archived', () async {
    await shown();
    filter()
      ..search('  cooper ')
      ..scope(ath.ExerciseScope.GLOBAL)
      ..showArchived(true);
    expect(await shown(), ['g-cooper']);
    final last = repo.queries.last;
    expect(
      (last.query, last.scope, last.includeArchived),
      ('cooper', ath.ExerciseScope.GLOBAL, true),
    );
    filter()
      ..search('   ')
      ..scope(ath.ExerciseScope.TENANT);
    expect(await shown(), ['own-1', 'own-old']);
    expect(repo.queries.last.query, isNull);
  });

  test('a filter is a value: equal filters are equal', () {
    expect(
      const ExerciseFilter(query: 'a', scope: ath.ExerciseScope.TENANT),
      const ExerciseFilter(query: 'a', scope: ath.ExerciseScope.TENANT),
    );
    expect(
      const ExerciseFilter(query: 'a'),
      isNot(const ExerciseFilter(query: 'a', includeArchived: true)),
    );
  });

  test('more pages are appended until the last one', () async {
    repo.exerciseList
      ..clear()
      ..addAll([
        for (var i = 0; i < ExerciseCatalogueNotifier.pageSize + 2; i++)
          exercise('e${i.toString().padLeft(3, '0')}', 'Ejercicio $i'),
      ]);
    await shown();
    expect(container.read(exerciseCatalogueProvider).value!.hasMore, isTrue);

    await container.read(exerciseCatalogueProvider.notifier).loadMore();

    final listing = container.read(exerciseCatalogueProvider).value!;
    expect(listing.items, hasLength(ExerciseCatalogueNotifier.pageSize + 2));
    expect(listing.hasMore, isFalse);
    expect([for (final q in repo.queries) q.page], [0, 1]);
  });

  test('create, edit, archive and unarchive go to the repository and '
      'reload the list', () async {
    await shown();
    final catalogue = container.read(exerciseCatalogueProvider.notifier);

    await catalogue.create(ath.ExerciseInput((b) => b..title = 'Abanico'));
    expect(repo.created!.title, 'Abanico');
    expect(await shown(), ['own-4', 'own-1', 'g-cooper', 'g-ft']);

    await catalogue.edit(
      'own-1',
      ath.UpdateExerciseRequest((b) => b..title = 'Rueda larga'),
    );
    expect(repo.exerciseList[2].title, 'Rueda larga');

    await catalogue.archive('own-1');
    expect(await shown(), ['own-4', 'g-cooper', 'g-ft']);
    await catalogue.unarchive('own-1');
    expect(await shown(), ['own-4', 'own-1', 'g-cooper', 'g-ft']);
    expect(repo.calls, containsAllInOrder(['create', 'update', 'archive']));
  });

  test('the quick-add search: both scopes, never archived ones', () async {
    final found = await container.read(exerciseSearchProvider('e').future);
    expect([for (final e in found) e.id], ['own-1', 'g-cooper', 'g-ft']);
    final last = repo.queries.last;
    expect(
      (last.query, last.scope, last.includeArchived, last.language),
      ('e', null, false, 'id'),
    );
    final all = await container.read(exerciseSearchProvider('  ').future);
    expect(all, hasLength(3));
    expect(repo.queries.last.query, isNull);
  });
}
