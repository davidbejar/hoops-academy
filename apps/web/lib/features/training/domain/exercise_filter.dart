import '../../../core/api/athlete_api.dart' as ath;

/// What the exercise catalogue shows: a part of the title, the scope (null =
/// global and the academy's own) and whether archived ones are included.
class ExerciseFilter {
  const ExerciseFilter({
    this.query = '',
    this.scope,
    this.includeArchived = false,
  });

  final String query;
  final ath.ExerciseScope? scope;
  final bool includeArchived;

  /// The text the server gets: trimmed, null when blank.
  String? get serverQuery => query.trim().isEmpty ? null : query.trim();

  ExerciseFilter copyWith({
    String? query,
    ath.ExerciseScope? Function()? scope,
    bool? includeArchived,
  }) => ExerciseFilter(
    query: query ?? this.query,
    scope: scope == null ? this.scope : scope(),
    includeArchived: includeArchived ?? this.includeArchived,
  );

  @override
  bool operator ==(Object other) =>
      other is ExerciseFilter &&
      other.query == query &&
      other.scope == scope &&
      other.includeArchived == includeArchived;

  @override
  int get hashCode => Object.hash(query, scope, includeArchived);
}
