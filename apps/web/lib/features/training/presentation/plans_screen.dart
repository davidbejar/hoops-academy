import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/presentation/eligibility_widgets.dart' show TeamLabel;
import '../application/training_providers.dart';
import 'player_picker.dart';

/// Plan library: templates (read-only, copy on use) and the academy's plans.
class PlanLibraryScreen extends ConsumerWidget {
  const PlanLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return SubPage(
      title: l.planLibraryTitle,
      parentPath: '/training',
      floatingActionButton: caps.canEditPlans
          ? FloatingActionButton.extended(
              key: const Key('plan-new'),
              onPressed: () => _newPlan(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l.planNew),
            )
          : null,
      child: Guarded(
        allowed: caps.canSeeModule,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 0),
                child: TextField(
                  key: const Key('plan-search'),
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.planSearchHint, isDense: true),
                  onChanged: (v) => ref.read(planSearchProvider.notifier).set(v),
                ),
              ),
              TabBar(tabs: [Tab(key: const Key('tab-mine'), text: l.planMine), Tab(key: const Key('tab-templates'), text: l.planTemplates)]),
              const Expanded(child: TabBarView(children: [_PlanList(templates: false), _PlanList(templates: true)])),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _newPlan(BuildContext context, WidgetRef ref) async {
    ath.TrainingPlan? created;
    final ok = await showDialog<bool>(context: context, builder: (_) => NewPlanDialog(onCreated: (p) => created = p));
    if ((ok ?? false) && created != null && context.mounted) context.go('/training/plans/${created!.id}');
  }
}

/// Name / description of a new plan; reports the created plan.
class NewPlanDialog extends ConsumerStatefulWidget {
  const NewPlanDialog({super.key, required this.onCreated});
  final ValueChanged<ath.TrainingPlan> onCreated;

  @override
  ConsumerState<NewPlanDialog> createState() => _NewPlanDialogState();
}

class _NewPlanDialogState extends ConsumerState<NewPlanDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.planNew,
      formKey: _form,
      onSubmit: () => runAction(context, () async {
        widget.onCreated(
          await ref
              .read(planLibraryProvider(false).notifier)
              .create(_name.text.trim(), description: _description.text.trim().isEmpty ? null : _description.text.trim()),
        );
      }),
      children: [
        TextFormField(
          key: const Key('plan-name'),
          controller: _name,
          decoration: InputDecoration(labelText: l.planName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('plan-description'),
          controller: _description,
          maxLines: 2,
          decoration: InputDecoration(labelText: l.planDescription),
        ),
      ],
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({required this.templates});
  final bool templates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return AsyncBody<List<ath.TrainingPlanSummary>>(
      value: ref.watch(planLibraryProvider(templates)),
      onRetry: () => ref.invalidate(planLibraryProvider(templates)),
      isEmpty: (d) => d.isEmpty,
      emptyMessage: templates ? l.planEmptyTemplates : l.planEmptyMine,
      builder: (context, data) => ListView(
        padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 88),
        children: [
          for (final p in data)
            Card(
              child: ListTile(
                key: Key('plan-${p.id}'),
                title: Text(p.name),
                subtitle: Text(
                  [l.planSummary(p.itemCount, p.totalDurationMinutes), if (p.description != null) p.description!].join('\n'),
                ),
                isThreeLine: p.description != null,
                onTap: () => context.go('/training/plans/${p.id}'),
                trailing: templates && caps.canEditPlans
                    ? FilledButton.tonal(
                        key: Key('plan-use-${p.id}'),
                        onPressed: () async {
                          ath.TrainingPlan? copy;
                          final ok = await runAction(
                            context,
                            () async => copy = await ref.read(planLibraryProvider(true).notifier).copy(p.id),
                            success: l.planCopied,
                          );
                          if (ok && copy != null && context.mounted) context.go('/training/plans/${copy!.id}');
                        },
                        child: Text(l.planUse),
                      )
                    : const Icon(Icons.chevron_right),
              ),
            ),
        ],
      ),
    );
  }
}

/// Plan detail / editor. Templates are read-only (copy first).
class PlanEditorScreen extends ConsumerWidget {
  const PlanEditorScreen({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final plan = ref.watch(planDetailProvider(planId));
    final editable = caps.canEditPlans && plan.value?.template == false;
    return SubPage(
      title: plan.value?.name ?? l.planLibraryTitle,
      parentPath: '/training/plans',
      actions: [
        if (editable)
          IconButton(
            key: const Key('plan-delete'),
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (!await confirmDialog(context, message: l.planDeleteConfirm, confirmLabel: l.delete)) return;
              if (!context.mounted) return;
              final ok = await runAction(context, () => ref.read(planLibraryProvider(false).notifier).delete(planId));
              if (ok && context.mounted) context.go('/training/plans');
            },
          ),
      ],
      floatingActionButton: editable
          ? FloatingActionButton.extended(
              key: const Key('item-add'),
              onPressed: () => showDialog<bool>(context: context, builder: (_) => PlanItemDialog(planId: planId)),
              icon: const Icon(Icons.add),
              label: Text(l.planItemAdd),
            )
          : null,
      child: AsyncBody<ath.TrainingPlan>(
        value: plan,
        onRetry: () => ref.invalidate(planDetailProvider(planId)),
        builder: (context, p) => _PlanBody(plan: p, editable: editable),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan, required this.editable});
  final ath.TrainingPlan plan;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final notifier = ref.read(planDetailProvider(plan.id).notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 88),
      children: [
        if (plan.description != null) Text(plan.description!, style: theme.textTheme.bodyMedium),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
          child: Text(l.planSummary(plan.itemCount, plan.totalDurationMinutes), style: theme.textTheme.labelLarge),
        ),
        if (plan.template)
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.planTemplateReadOnly, key: const Key('template-hint')),
                  if (caps.canEditPlans)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTokens.spaceSm),
                      child: FilledButton(
                        key: const Key('plan-use'),
                        onPressed: () async {
                          ath.TrainingPlan? copy;
                          final ok = await runAction(
                            context,
                            () async => copy = await ref.read(planLibraryProvider(true).notifier).copy(plan.id),
                            success: l.planCopied,
                          );
                          if (ok && copy != null && context.mounted) context.go('/training/plans/${copy!.id}');
                        },
                        child: Text(l.planUse),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (!plan.template && caps.canAssignPlans)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
            child: FilledButton.icon(
              key: const Key('plan-assign'),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text(l.planAssign),
              onPressed: () => showDialog<bool>(context: context, builder: (_) => AssignDialog(planId: plan.id)),
            ),
          ),
        Text(l.planItems, style: theme.textTheme.titleMedium),
        if (plan.items.isEmpty)
          Padding(padding: const EdgeInsets.all(AppTokens.spaceMd), child: Text(l.planNoItems)),
        for (var i = 0; i < plan.items.length; i++)
          Card(
            key: Key('item-${plan.items[i].id}'),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceSm),
                    child: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                  ),
                  Expanded(child: _ItemInfo(item: plan.items[i])),
                  if (editable)
                    PopupMenuButton<String>(
                      key: Key('item-menu-${plan.items[i].id}'),
                      tooltip: l.moreActions,
                      onSelected: (v) async {
                        final item = plan.items[i];
                        if (v == 'edit') {
                          await showDialog<bool>(context: context, builder: (_) => PlanItemDialog(planId: plan.id, item: item));
                        } else if (v == 'up') {
                          await runAction(context, () => notifier.move(i, i - 1));
                        } else if (v == 'down') {
                          await runAction(context, () => notifier.move(i, i + 1));
                        } else if (v == 'delete') {
                          if (!await confirmDialog(context, message: l.planItemDeleteConfirm, confirmLabel: l.delete)) return;
                          if (!context.mounted) return;
                          await runAction(context, () => notifier.deleteItem(item.id));
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l.edit)),
                        if (i > 0) PopupMenuItem(value: 'up', child: Text(l.planItemMoveUp)),
                        if (i < plan.items.length - 1) PopupMenuItem(value: 'down', child: Text(l.planItemMoveDown)),
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({required this.item});
  final ath.PlanItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final facts = [
      if (item.durationMinutes != null) l.sessionDurationMinutes(item.durationMinutes!),
      if (item.sets != null && item.repetitions != null) l.planItemSetsReps(item.repetitions!, item.sets!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: theme.textTheme.titleSmall),
        if (facts.isNotEmpty) Text(facts.join(' · '), style: theme.textTheme.bodySmall),
        if (item.description != null) Text(item.description!),
        if (item.videoUrl != null)
          Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 16),
              const SizedBox(width: 4),
              Expanded(child: SelectableText(item.videoUrl!, style: theme.textTheme.bodySmall)),
            ],
          ),
      ],
    );
  }
}

/// Add / edit one exercise.
class PlanItemDialog extends ConsumerStatefulWidget {
  const PlanItemDialog({super.key, required this.planId, this.item});
  final String planId;
  final ath.PlanItem? item;

  @override
  ConsumerState<PlanItemDialog> createState() => _PlanItemDialogState();
}

class _PlanItemDialogState extends ConsumerState<PlanItemDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title);
  late final _description = TextEditingController(text: widget.item?.description);
  late final _duration = TextEditingController(text: widget.item?.durationMinutes?.toString());
  late final _sets = TextEditingController(text: widget.item?.sets?.toString());
  late final _reps = TextEditingController(text: widget.item?.repetitions?.toString());
  late final _video = TextEditingController(text: widget.item?.videoUrl);

  @override
  void dispose() {
    for (final c in [_title, _description, _duration, _sets, _reps, _video]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  String? _optionalInt(AppLocalizations l, String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = int.tryParse(v!.trim());
    return n == null || n < 1 ? l.fieldInvalidNumber : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(planDetailProvider(widget.planId).notifier);
    Widget number(String key, TextEditingController c, String label) => Expanded(
      child: TextFormField(
        key: Key(key),
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (v) => _optionalInt(l, v),
      ),
    );
    return FormDialog(
      title: widget.item == null ? l.planItemAdd : l.planItemEdit,
      formKey: _form,
      onSubmit: () => runAction(context, () async {
        if (widget.item == null) {
          await notifier.addItem(
            ath.PlanItemInput((b) => b
              ..title = _title.text.trim()
              ..description = _text(_description)
              ..durationMinutes = _int(_duration)
              ..sets = _int(_sets)
              ..repetitions = _int(_reps)
              ..videoUrl = _text(_video)),
          );
        } else {
          await notifier.updateItem(
            widget.item!.id,
            ath.UpdatePlanItemRequest((b) => b
              ..title = _title.text.trim()
              ..description = _text(_description)
              ..durationMinutes = _int(_duration)
              ..sets = _int(_sets)
              ..repetitions = _int(_reps)
              ..videoUrl = _text(_video)),
          );
        }
      }),
      children: [
        TextFormField(
          key: const Key('item-title'),
          controller: _title,
          decoration: InputDecoration(labelText: l.planItemTitle),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('item-description'),
          controller: _description,
          maxLines: 2,
          decoration: InputDecoration(labelText: l.planDescription),
        ),
        formGap,
        Row(
          children: [
            number('item-duration', _duration, l.planItemDuration),
            const SizedBox(width: AppTokens.spaceSm),
            number('item-sets', _sets, l.planItemSets),
            const SizedBox(width: AppTokens.spaceSm),
            number('item-reps', _reps, l.planItemReps),
          ],
        ),
        formGap,
        TextFormField(
          key: const Key('item-video'),
          controller: _video,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l.planItemVideo),
          validator: (v) => (v ?? '').trim().isEmpty || v!.trim().startsWith('https://') ? null : l.planItemVideoInvalid,
        ),
      ],
    );
  }
}

/// Assign a plan to a team or to one player.
class AssignDialog extends ConsumerStatefulWidget {
  const AssignDialog({super.key, required this.planId});
  final String planId;

  @override
  ConsumerState<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<AssignDialog> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  bool _team = true;
  String? _teamId;
  String? _playerId;
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final teams = [
      for (final t in ref.watch(teamsProvider).value ?? const <api.Team>[])
        if (caps.canManageTraining(t.id)) t,
    ];
    return FormDialog(
      title: l.assignTitle,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref.read(assignmentsProvider(null).notifier).assign(
          planId: widget.planId,
          teamId: _team ? _teamId : null,
          playerId: _team ? null : (_playerId ?? ref.read(selectablePlayerIdsProvider).firstOrNull),
          dueOn: _due,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
        success: l.assignDone,
      ),
      children: [
        SegmentedButton<bool>(
          key: const Key('assign-target'),
          segments: [
            ButtonSegment(value: true, label: Text(l.assignToTeam)),
            ButtonSegment(value: false, label: Text(l.assignToPlayer)),
          ],
          selected: {_team},
          onSelectionChanged: (s) => setState(() => _team = s.first),
        ),
        formGap,
        if (_team)
          DropdownButtonFormField<String>(
            key: const Key('assign-team'),
            initialValue: _teamId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.assignTarget),
            items: [for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.displayLabel))],
            validator: (v) => v == null ? l.fieldRequired : null,
            onChanged: (v) => setState(() => _teamId = v),
          )
        else
          PlayerPicker(label: l.assignTarget, value: _playerId, onChanged: (v) => setState(() => _playerId = v)),
        formGap,
        DateField(
          key: const Key('assign-due'),
          label: l.assignDue,
          value: _due,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          onChanged: (d) => setState(() => _due = d),
        ),
        formGap,
        TextFormField(
          key: const Key('assign-notes'),
          controller: _notes,
          maxLines: 2,
          decoration: InputDecoration(labelText: l.noteOptional),
        ),
      ],
    );
  }
}
