import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../data/exercises_repository.dart';
import '../domain/exercise_filter.dart';
import 'training_providers.dart' show uiLanguageProvider;

final exercisesRepositoryProvider = Provider<ExercisesRepository>(
  (ref) => ApiExercisesRepository(
    ref.watch(ath.athleteApiProvider),
    ref.watch(api.tenantIdProvider),
  ),
);

/// The catalogue screen's filter; its text is the plan library's search box.
class ExerciseFilterNotifier extends Notifier<ExerciseFilter> {
  @override
  ExerciseFilter build() => const ExerciseFilter();

  void search(String query) => state = state.copyWith(query: query);
  void scope(ath.ExerciseScope? scope) =>
      state = state.copyWith(scope: () => scope);
  void showArchived(bool on) => state = state.copyWith(includeArchived: on);
}

final exerciseFilterProvider =
    NotifierProvider<ExerciseFilterNotifier, ExerciseFilter>(
      ExerciseFilterNotifier.new,
    );

/// The exercises loaded so far and whether the server has more pages.
class ExerciseListing {
  const ExerciseListing(this.items, {required this.hasMore});
  final List<ath.Exercise> items;
  final bool hasMore;
}

/// The catalogue screen: the first page for the filter, further pages on
/// request, and the commands on the academy's own exercises.
class ExerciseCatalogueNotifier extends AsyncNotifier<ExerciseListing> {
  static const pageSize = 50;
  int _page = 0;

  ExercisesRepository get _repo => ref.read(exercisesRepositoryProvider);

  @override
  Future<ExerciseListing> build() {
    _page = 0;
    return _load(
      ref.watch(exercisesRepositoryProvider),
      ref.watch(exerciseFilterProvider),
      ref.watch(uiLanguageProvider),
      page: 0,
    );
  }

  /// Page [page] for [filter], appended to [before].
  static Future<ExerciseListing> _load(
    ExercisesRepository repo,
    ExerciseFilter filter,
    String language, {
    required int page,
    List<ath.Exercise> before = const [],
  }) async {
    final result = await repo.exercises(
      query: filter.serverQuery,
      scope: filter.scope,
      includeArchived: filter.includeArchived,
      page: page,
      size: pageSize,
      language: language,
    );
    return ExerciseListing([
      ...before,
      ...result.items,
    ], hasMore: page + 1 < result.page.totalPages);
  }

  Future<void> loadMore() async {
    final next = await _load(
      _repo,
      ref.read(exerciseFilterProvider),
      ref.read(uiLanguageProvider),
      page: _page + 1,
      before: state.requireValue.items,
    );
    _page++;
    state = AsyncData(next);
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> create(ath.ExerciseInput input) async {
    await _repo.create(input);
    await _reload();
  }

  Future<void> edit(
    String exerciseId,
    ath.UpdateExerciseRequest request,
  ) async {
    await _repo.update(exerciseId, request);
    await _reload();
  }

  Future<void> archive(String exerciseId) async {
    await _repo.archive(exerciseId);
    await _reload();
  }

  Future<void> unarchive(String exerciseId) async {
    await _repo.unarchive(exerciseId);
    await _reload();
  }
}

final exerciseCatalogueProvider =
    AsyncNotifierProvider<ExerciseCatalogueNotifier, ExerciseListing>(
      ExerciseCatalogueNotifier.new,
    );

/// Catalogue exercises the quick-add pickers offer for a query: both scopes,
/// never archived ones (they cannot be added), the first page.
final exerciseSearchProvider = FutureProvider.autoDispose
    .family<List<ath.Exercise>, String>((ref, query) async {
      final page = await ref
          .watch(exercisesRepositoryProvider)
          .exercises(
            query: ExerciseFilter(query: query).serverQuery,
            size: ExerciseCatalogueNotifier.pageSize,
            language: ref.watch(uiLanguageProvider),
          );
      return page.items.toList();
    });
