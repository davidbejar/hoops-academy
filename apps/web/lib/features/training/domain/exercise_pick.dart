import '../../../core/api/athlete_api.dart' as ath;

/// One exercise chosen for a quick-add (ADR-0041, ADR-0047): what the server
/// copies and the title shown meanwhile. [key] tells picks apart, so picking
/// the same source again unpicks it.
class ExercisePick {
  ExercisePick.exercise(ath.Exercise exercise)
    : key = 'exercise:${exercise.id}',
      title = exercise.title,
      source = ath.PlanItemSource((b) => b..exerciseId = exercise.id);

  ExercisePick.planItem({
    required String planId,
    required String itemId,
    required this.title,
  }) : key = 'item:$planId/$itemId',
       source = ath.PlanItemSource(
         (b) => b
           ..planId = planId
           ..itemId = itemId,
       );

  final String key;
  final String title;
  final ath.PlanItemSource source;
}
