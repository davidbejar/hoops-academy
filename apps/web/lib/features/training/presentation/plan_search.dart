import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/exercise_providers.dart';
import '../application/training_providers.dart';
import '../domain/exercise_pick.dart';
import 'training_labels.dart';

/// Width of the picker dialogs (they shrink to the screen on phones).
const _pickerWidth = WidthClass.readingMax * 2 / 3;

/// The plan chosen in [PlanPickerDialog]; [planId] null = no plan.
class PlanChoice {
  const PlanChoice(this.planId);
  final String? planId;
}

/// Decision 53 (ADR-0041): a session references any academy plan or template
/// directly. Lists both groups; the search also matches exercise titles and
/// says which exercise was found. Pops a [PlanChoice], or null when dismissed.
class PlanPickerDialog extends ConsumerStatefulWidget {
  const PlanPickerDialog({super.key, this.selected});
  final String? selected;

  @override
  ConsumerState<PlanPickerDialog> createState() => _PlanPickerDialogState();
}

class _PlanPickerDialogState extends ConsumerState<PlanPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final results = ref.watch(planSearchResultsProvider(_query));
    Widget tile(ath.TrainingPlanSummary p) {
      final found = p.matchedItems?.map((i) => i.title).join(', ');
      return ListTile(
        key: Key('plan-option-${p.id}'),
        title: Text(p.name),
        subtitle: Text(
          found != null
              ? l.sessionPlanFound(found)
              : l.planSummary(p.itemCount, p.totalDurationMinutes),
        ),
        selected: p.id == widget.selected,
        trailing: p.id == widget.selected ? const Icon(Icons.check) : null,
        onTap: () => Navigator.pop(context, PlanChoice(p.id)),
      );
    }

    return AlertDialog(
      title: Text(l.sessionPlanPick),
      content: SizedBox(
        width: _pickerWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SearchField(
              fieldKey: const Key('plan-search'),
              hint: l.sessionPlanSearchHint,
              onChanged: (q) => setState(() => _query = q),
            ),
            Flexible(
              child: switch (results) {
                AsyncData(:final value) => ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      key: const Key('plan-none'),
                      title: Text(l.sessionNoPlan),
                      onTap: () =>
                          Navigator.pop(context, const PlanChoice(null)),
                    ),
                    if (value.academy.isNotEmpty) ...[
                      _GroupHeader(l.sessionPlanAcademy),
                      for (final p in value.academy) tile(p),
                    ],
                    if (value.templates.isNotEmpty) ...[
                      _GroupHeader(l.planTemplates),
                      for (final p in value.templates) tile(p),
                    ],
                    if (value.isEmpty) _Hint(l.sessionPlanNoResults),
                  ],
                ),
                AsyncError(:final error) => _Hint(AppErrorText.of(error, l)),
                _ => const LinearProgressIndicator(),
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}

/// Decisions 54 and 72 (ADR-0041, ADR-0047): picks exercises for a quick-add,
/// from the catalogue first and, for a search, from the matching items of the
/// academy's plans and the templates (so items written by hand stay
/// reachable); several, across searches, in the order they were picked.
/// [onAdd] copies them and the dialog closes once it succeeds; without it the
/// dialog pops the picks (`List<ExercisePick>`) for the caller to add later.
class ExerciseSearchDialog extends ConsumerStatefulWidget {
  const ExerciseSearchDialog({super.key, this.onAdd});
  final Future<void> Function(List<ath.PlanItemSource> items)? onAdd;

  @override
  ConsumerState<ExerciseSearchDialog> createState() =>
      _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends ConsumerState<ExerciseSearchDialog> {
  String _query = '';
  final _picked = <String, ExercisePick>{};

  void _toggle(ExercisePick pick, bool on) => setState(() {
    on ? _picked[pick.key] = pick : _picked.remove(pick.key);
  });

  Future<void> _add(AppLocalizations l) async {
    final picks = _picked.values.toList();
    final onAdd = widget.onAdd;
    if (onAdd == null) {
      Navigator.pop(context, picks);
      return;
    }
    final ok = await runAction(
      context,
      () => onAdd([for (final p in picks) p.source]),
      success: l.sessionExercisesAdded(picks.length),
      errorText: exerciseErrorText,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalogue = ref.watch(exerciseSearchProvider(_query));
    return AlertDialog(
      title: Text(l.sessionAddExercises),
      content: SizedBox(
        width: _pickerWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SearchField(
              fieldKey: const Key('exercise-search'),
              hint: l.sessionExerciseSearchHint,
              onChanged: (q) => setState(() => _query = q),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ..._catalogue(l, catalogue),
                  ..._planItems(l, {
                    for (final e in catalogue.value ?? const <ath.Exercise>[])
                      e.id,
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('exercise-add'),
          onPressed: _picked.isEmpty ? null : () => _add(l),
          child: Text(l.sessionExercisesAddCount(_picked.length)),
        ),
      ],
    );
  }

  /// The catalogue's exercises for the query (all of them while it is empty).
  List<Widget> _catalogue(
    AppLocalizations l,
    AsyncValue<List<ath.Exercise>> catalogue,
  ) => [
    _GroupHeader(l.exerciseCatalogueSection),
    switch (catalogue) {
      AsyncData(:final value) when value.isEmpty => _Hint(l.exerciseEmpty),
      AsyncData(:final value) => Column(
        children: [for (final e in value) _exerciseTile(l, e)],
      ),
      AsyncError(:final error) => _Hint(AppErrorText.of(error, l)),
      _ => const LinearProgressIndicator(),
    },
  ];

  Widget _exerciseTile(AppLocalizations l, ath.Exercise e) {
    final pick = ExercisePick.exercise(e);
    final facts = exerciseFacts(
      l,
      minutes: e.durationMinutes,
      sets: e.sets,
      repetitions: e.repetitions,
    );
    final subtitle = [if (e.global) l.exerciseGlobal, ?facts].join(' · ');
    return CheckboxListTile(
      key: Key('catalogue-${e.id}'),
      dense: true,
      value: _picked.containsKey(pick.key),
      title: Text(e.title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      onChanged: (on) => _toggle(pick, on ?? false),
    );
  }

  /// Items of plans and templates that match a search, grouped by plan,
  /// leaving out copies of an exercise the catalogue lists above.
  List<Widget> _planItems(AppLocalizations l, Set<String> listedExercises) {
    if (_query.trim().isEmpty) return [_Hint(l.sessionExerciseSearchEmpty)];
    final results = ref.watch(planSearchResultsProvider(_query));
    if (results case AsyncError(:final error)) {
      return [_Hint(AppErrorText.of(error, l))];
    }
    final plans = results.value;
    if (plans == null) return const [LinearProgressIndicator()];
    final groups = [
      for (final p in [...plans.academy, ...plans.templates])
        if (_items(p, listedExercises) case final items when items.isNotEmpty)
          [
            _GroupHeader(
              p.name,
              subtitle: p.template ? l.planTemplates : l.sessionPlanAcademy,
            ),
            for (final pick in items) _itemTile(pick),
          ],
    ];
    if (groups.isEmpty) return const [];
    return [_GroupHeader(l.exercisePlansSection), for (final g in groups) ...g];
  }

  /// The matched items; a plan found by its name offers all of them.
  List<ExercisePick> _items(
    ath.TrainingPlanSummary p,
    Set<String> listedExercises,
  ) {
    final matched = p.matchedItems;
    final items = matched != null
        ? [for (final i in matched) (i.id, i.title, i.exerciseId)]
        : [
            for (final i
                in ref.watch(planDetailProvider(p.id)).value?.items ??
                    const <ath.PlanItem>[])
              (i.id, i.title, i.exerciseId),
          ];
    return [
      for (final (id, title, exerciseId) in items)
        if (!listedExercises.contains(exerciseId))
          ExercisePick.planItem(planId: p.id, itemId: id, title: title),
    ];
  }

  Widget _itemTile(ExercisePick pick) {
    final source = pick.source;
    return CheckboxListTile(
      key: Key('exercise-${source.planId}-${source.itemId}'),
      dense: true,
      value: _picked.containsKey(pick.key),
      title: Text(pick.title),
      onChanged: (on) => _toggle(pick, on ?? false),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.fieldKey,
    required this.hint,
    required this.onChanged,
  });
  final Key fieldKey;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: HoopsSpace.sm),
    child: TextField(
      key: fieldKey,
      autofocus: true,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: onChanged,
    ),
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title, {this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HoopsSpace.md,
        HoopsSpace.md,
        HoopsSpace.md,
        HoopsSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: subtitle == null
                  ? HoopsType.eyebrow(text, c)
                  : text.titleSmall,
            ),
          ),
          if (subtitle != null)
            Text(subtitle!, style: HoopsType.eyebrow(text, c)),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(HoopsSpace.md),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!
          .copyWith(color: HoopsTokens.colorsOf(context).inkMuted),
    ),
  );
}
