import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/ui/actions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/training_providers.dart';

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
        width: 480,
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

/// Decision 54 (ADR-0041): finds exercises in the academy's plans and the
/// templates and quick-adds the picked ones (several, across searches) to the
/// session, in the order they were picked.
class ExerciseSearchDialog extends ConsumerStatefulWidget {
  const ExerciseSearchDialog({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<ExerciseSearchDialog> createState() =>
      _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends ConsumerState<ExerciseSearchDialog> {
  String _query = '';
  final _picked = <String, ath.PlanItemRef>{};

  void _toggle(String planId, String itemId, bool on) => setState(() {
    final key = '$planId/$itemId';
    if (on) {
      _picked[key] = ath.PlanItemRef(
        (b) => b
          ..planId = planId
          ..itemId = itemId,
      );
    } else {
      _picked.remove(key);
    }
  });

  Future<void> _add(AppLocalizations l) async {
    final refs = _picked.values.toList();
    final ok = await runAction(
      context,
      () => ref
          .read(sessionDetailProvider(widget.sessionId).notifier)
          .addExercises(refs),
      success: l.sessionExercisesAdded(refs.length),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.sessionAddExercises),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SearchField(
              fieldKey: const Key('exercise-search'),
              hint: l.sessionExerciseSearchHint,
              onChanged: (q) => setState(() => _query = q),
            ),
            Flexible(child: _results(l)),
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

  Widget _results(AppLocalizations l) {
    if (_query.trim().isEmpty) return _Hint(l.sessionExerciseSearchEmpty);
    return switch (ref.watch(planSearchResultsProvider(_query))) {
      AsyncData(:final value) when value.isEmpty => _Hint(
        l.sessionPlanNoResults,
      ),
      AsyncData(:final value) => ListView(
        shrinkWrap: true,
        children: [
          for (final p in [...value.academy, ...value.templates]) ...[
            _GroupHeader(
              p.name,
              subtitle: p.template ? l.planTemplates : l.sessionPlanAcademy,
            ),
            ..._items(p),
          ],
        ],
      ),
      AsyncError(:final error) => _Hint(AppErrorText.of(error, l)),
      _ => const LinearProgressIndicator(),
    };
  }

  /// The matched exercises; a plan found by its name offers all of them.
  List<Widget> _items(ath.TrainingPlanSummary p) {
    final matched = p.matchedItems;
    final items = matched != null
        ? [for (final i in matched) (i.id, i.title)]
        : [
            for (final i
                in ref.watch(planDetailProvider(p.id)).value?.items ??
                    const <ath.PlanItem>[])
              (i.id, i.title),
          ];
    return [
      for (final (id, title) in items)
        CheckboxListTile(
          key: Key('exercise-${p.id}-$id'),
          dense: true,
          value: _picked.containsKey('${p.id}/$id'),
          title: Text(title),
          onChanged: (on) => _toggle(p.id, id, on ?? false),
        ),
    ];
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
    padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.spaceSm),
      child: ListTile(
        dense: true,
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle == null ? null : Text(subtitle!),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppTokens.spaceMd),
    child: Text(text, textAlign: TextAlign.center),
  );
}
