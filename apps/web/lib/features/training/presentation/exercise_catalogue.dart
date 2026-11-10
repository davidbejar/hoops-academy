import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/api/clear_list.dart';
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/exercise_providers.dart';
import 'exercise_form.dart';
import 'training_labels.dart';

/// The exercise catalogue (decision 72, ADR-0047), a tab of the plan library:
/// the platform's global exercises (read-only, marked) and the academy's own,
/// which staff create, edit and archive. The library's search box filters it.
class ExerciseCatalogue extends ConsumerWidget {
  const ExerciseCatalogue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        const ContentFrame(child: _Filters()),
        Expanded(
          child: AsyncBody<ExerciseListing>(
            value: ref.watch(exerciseCatalogueProvider),
            onRetry: () => ref.invalidate(exerciseCatalogueProvider),
            isEmpty: (d) => d.items.isEmpty,
            emptyMessage: l.exerciseEmpty,
            builder: (context, d) => ListView.separated(
              key: const Key('exercise-list'),
              padding: const EdgeInsets.only(
                top: HoopsSpace.md,
                bottom: fabClearance,
              ),
              itemCount: d.items.length + (d.hasMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: HoopsSpace.gap),
              itemBuilder: (context, i) => ContentFrame(
                child: i < d.items.length
                    ? _ExerciseRow(exercise: d.items[i])
                    : const _LoadMore(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Scope (all / global / the academy's) and, for staff, archived ones too.
class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(exerciseFilterProvider);
    final notifier = ref.read(exerciseFilterProvider.notifier);
    Widget scope(String key, String label, ath.ExerciseScope? value) =>
        ChoiceChip(
          key: Key('exercise-scope-$key'),
          label: Text(label),
          selected: filter.scope == value,
          onSelected: (_) => notifier.scope(value),
        );
    // One row that scrolls sideways: the list keeps the height on a phone.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: HoopsSpace.md),
      child: Row(
        spacing: HoopsSpace.sm,
        children: [
          scope('all', l.exerciseScopeAll, null),
          scope('global', l.exerciseScopeGlobal, ath.ExerciseScope.GLOBAL),
          scope('academy', l.exerciseScopeAcademy, ath.ExerciseScope.TENANT),
          if (ref.watch(capabilitiesProvider).canEditPlans)
            FilterChip(
              key: const Key('exercise-show-archived'),
              label: Text(l.exerciseShowArchived),
              selected: filter.includeArchived,
              onSelected: notifier.showArchived,
            ),
        ],
      ),
    );
  }
}

class _LoadMore extends ConsumerWidget {
  const _LoadMore();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: OutlinedButton(
      key: const Key('exercise-more'),
      onPressed: () => runAction(
        context,
        ref.read(exerciseCatalogueProvider.notifier).loadMore,
      ),
      child: Text(AppLocalizations.of(context).exerciseLoadMore),
    ),
  );
}

/// One exercise: its facts, description and marks; staff act on the
/// academy's own (edit, archive / restore).
class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({required this.exercise});
  final ath.Exercise exercise;

  Future<void> _act(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final e = exercise;
    final catalogue = ref.read(exerciseCatalogueProvider.notifier);
    final v = await showActionSheet<String>(
      context,
      title: e.title,
      actions: [
        SheetAction(icon: Icons.edit_outlined, label: l.edit, value: 'edit'),
        if (e.archived)
          SheetAction(
            icon: Icons.unarchive_outlined,
            label: l.exerciseUnarchive,
            value: 'unarchive',
          )
        else
          SheetAction(
            icon: Icons.archive_outlined,
            label: l.exerciseArchive,
            value: 'archive',
          ),
      ],
    );
    if (v == null || !context.mounted) return;
    switch (v) {
      case 'edit':
        await showDialog<bool>(
          context: context,
          builder: (_) => ExerciseDialog(exercise: e),
        );
      case 'archive':
        await runAction(
          context,
          () => catalogue.archive(e.id),
          success: l.exerciseArchivedDone,
          errorText: exerciseErrorText,
        );
      case 'unarchive':
        await runAction(
          context,
          () => catalogue.unarchive(e.id),
          success: l.exerciseUnarchivedDone,
          errorText: exerciseErrorText,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final e = exercise;
    final editable = !e.global && ref.watch(capabilitiesProvider).canEditPlans;
    final hasInfo = e.description != null || e.videoUrl != null;
    return ListRow(
      key: Key('exercise-row-${e.id}'),
      leading: IconTile(
        e.global ? Icons.public : Icons.fitness_center,
        tone: e.global ? HoopsTone.info : HoopsTone.accent,
      ),
      title: e.title,
      subtitle: exerciseFacts(
        l,
        minutes: e.durationMinutes,
        sets: e.sets,
        repetitions: e.repetitions,
      ),
      details: !e.global && !e.archived && !hasInfo
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: HoopsSpace.sm,
              children: [
                if (e.global)
                  StatusChip(
                    l.exerciseGlobal,
                    key: Key('exercise-global-${e.id}'),
                    tone: HoopsTone.info,
                    icon: Icons.public,
                  ),
                if (e.archived)
                  StatusChip(
                    l.exerciseArchived,
                    key: Key('exercise-archived-${e.id}'),
                    tone: HoopsTone.warning,
                    icon: Icons.archive_outlined,
                  ),
                if (hasInfo)
                  ExerciseInfo(
                    description: e.description,
                    videoUrl: e.videoUrl,
                  ),
              ],
            ),
      trailing: editable
          ? IconButton(
              key: Key('exercise-menu-${e.id}'),
              tooltip: l.moreActions,
              icon: const Icon(Icons.more_vert),
              onPressed: () => _act(context, ref),
            )
          : null,
    );
  }
}

/// A new exercise of the academy, or an edit of [exercise] (one of its own:
/// global exercises are read-only). Emptied fields are cleared (ADR-0032).
class ExerciseDialog extends ConsumerStatefulWidget {
  const ExerciseDialog({super.key, this.exercise});
  final ath.Exercise? exercise;

  @override
  ConsumerState<ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends ConsumerState<ExerciseDialog> {
  final _form = GlobalKey<FormState>();
  late final _fields = ExerciseFields(
    title: widget.exercise?.title,
    description: widget.exercise?.description,
    minutes: widget.exercise?.durationMinutes,
    sets: widget.exercise?.sets,
    repetitions: widget.exercise?.repetitions,
    videoUrl: widget.exercise?.videoUrl,
  );

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final catalogue = ref.read(exerciseCatalogueProvider.notifier);
    final f = _fields;
    final exercise = widget.exercise;
    if (exercise == null) {
      return catalogue.create(
        ath.ExerciseInput(
          (b) => b
            ..title = f.title
            ..description = f.description
            ..durationMinutes = f.minutes
            ..sets = f.sets
            ..repetitions = f.repetitions
            ..videoUrl = f.videoUrl,
        ),
      );
    }
    return catalogue.edit(
      exercise.id,
      ath.UpdateExerciseRequest(
        (b) => b
          ..title = f.title
          ..description = f.description
          ..durationMinutes = f.minutes
          ..sets = f.sets
          ..repetitions = f.repetitions
          ..videoUrl = f.videoUrl
          ..clear = clearList({
            ath.UpdateExerciseRequestClearEnum.description: f.description,
            ath.UpdateExerciseRequestClearEnum.durationMinutes: f.minutes,
            ath.UpdateExerciseRequestClearEnum.sets: f.sets,
            ath.UpdateExerciseRequestClearEnum.repetitions: f.repetitions,
            ath.UpdateExerciseRequestClearEnum.videoUrl: f.videoUrl,
          }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final creating = widget.exercise == null;
    return FormDialog(
      title: creating ? l.exerciseNew : l.planItemEdit,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        _save,
        success: creating ? l.exerciseCreated : l.exerciseSaved,
        errorText: exerciseErrorText,
      ),
      children: _fields.build(l, keyPrefix: 'exercise'),
    );
  }
}
