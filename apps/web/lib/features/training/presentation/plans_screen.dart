import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/api/clear_list.dart';
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../roster/presentation/eligibility_widgets.dart' show TeamLabel;
import '../application/training_providers.dart';
import 'player_picker.dart';
import 'training_labels.dart' show fabClearance;

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
              ContentFrame(
                child: Padding(
                  padding: const EdgeInsets.only(top: HoopsSpace.md),
                  child: TextField(
                    key: const Key('plan-search'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.planSearchHint,
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        ref.read(planSearchProvider.notifier).set(v),
                  ),
                ),
              ),
              TabBar(
                tabs: [
                  Tab(key: const Key('tab-mine'), text: l.planMine),
                  Tab(key: const Key('tab-templates'), text: l.planTemplates),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _PlanList(templates: false),
                    _PlanList(templates: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _newPlan(BuildContext context, WidgetRef ref) async {
    ath.TrainingPlan? created;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NewPlanDialog(onCreated: (p) => created = p),
    );
    if ((ok ?? false) && created != null && context.mounted)
      context.go('/training/plans/${created!.id}');
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
              .create(
                _name.text.trim(),
                description: _description.text.trim().isEmpty
                    ? null
                    : _description.text.trim(),
              ),
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

  /// The description and, on a template, "use" (copy, then open the copy).
  Widget? _details(
    BuildContext context,
    WidgetRef ref,
    ath.TrainingPlanSummary p,
  ) {
    final l = AppLocalizations.of(context);
    final canUse = templates && ref.watch(capabilitiesProvider).canEditPlans;
    if (p.description == null && !canUse) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.sm,
      children: [
        if (p.description != null) Text(p.description!),
        if (canUse)
          FilledButton.tonal(
            key: Key('plan-use-${p.id}'),
            onPressed: () async {
              ath.TrainingPlan? copy;
              final ok = await runAction(
                context,
                () async => copy = await ref
                    .read(planLibraryProvider(true).notifier)
                    .copy(p.id),
                success: l.planCopied,
              );
              if (ok && copy != null && context.mounted)
                context.go('/training/plans/${copy!.id}');
            },
            child: Text(l.planUse),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AsyncBody<List<ath.TrainingPlanSummary>>(
      value: ref.watch(planLibraryProvider(templates)),
      onRetry: () => ref.invalidate(planLibraryProvider(templates)),
      isEmpty: (d) => d.isEmpty,
      emptyMessage: templates ? l.planEmptyTemplates : l.planEmptyMine,
      builder: (context, data) => ListView.separated(
        padding: const EdgeInsets.only(
          top: HoopsSpace.md,
          bottom: fabClearance,
        ),
        itemCount: data.length,
        separatorBuilder: (_, _) => const SizedBox(height: HoopsSpace.gap),
        itemBuilder: (context, i) {
          final p = data[i];
          return ContentFrame(
            child: ListRow(
              key: Key('plan-${p.id}'),
              leading: IconTile(
                templates ? Icons.auto_stories_outlined : Icons.list_alt,
                tone: templates ? HoopsTone.info : HoopsTone.accent,
              ),
              title: p.name,
              subtitle: l.planSummary(p.itemCount, p.totalDurationMinutes),
              details: _details(context, ref, p),
              onTap: () => context.go('/training/plans/${p.id}'),
            ),
          );
        },
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
              if (!await confirmDialog(
                context,
                message: l.planDeleteConfirm,
                confirmLabel: l.delete,
              ))
                return;
              if (!context.mounted) return;
              final ok = await runAction(
                context,
                () => ref
                    .read(planLibraryProvider(false).notifier)
                    .delete(planId),
              );
              if (ok && context.mounted) context.go('/training/plans');
            },
          ),
      ],
      floatingActionButton: editable
          ? FloatingActionButton.extended(
              key: const Key('item-add'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => PlanItemDialog(planId: planId),
              ),
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

  Future<void> _useTemplate(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    ath.TrainingPlan? copy;
    final ok = await runAction(
      context,
      () async => copy = await ref
          .read(planLibraryProvider(true).notifier)
          .copy(plan.id),
      success: l.planCopied,
    );
    if (ok && copy != null && context.mounted)
      context.go('/training/plans/${copy!.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final caps = ref.watch(capabilitiesProvider);
    return ListView(
      padding: EdgeInsets.only(
        top: WidthClass.of(context).sectionGap,
        bottom: fabClearance,
      ),
      children: [
        ContentFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: HoopsSpace.gap,
            children: [
              if (plan.description != null)
                Text(plan.description!, style: text.bodyLarge),
              StatusChip(
                l.planSummary(plan.itemCount, plan.totalDurationMinutes),
                icon: Icons.timer_outlined,
              ),
              if (plan.template)
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: HoopsSpace.gap,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: HoopsSpace.gap,
                        children: [
                          const IconTile(
                            Icons.lock_outline,
                            tone: HoopsTone.info,
                          ),
                          Expanded(
                            child: Text(
                              l.planTemplateReadOnly,
                              key: const Key('template-hint'),
                            ),
                          ),
                        ],
                      ),
                      if (caps.canEditPlans)
                        FilledButton(
                          key: const Key('plan-use'),
                          onPressed: () => _useTemplate(context, ref),
                          child: Text(l.planUse),
                        ),
                    ],
                  ),
                ),
              if (!plan.template && caps.canAssignPlans)
                FilledButton.icon(
                  key: const Key('plan-assign'),
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: Text(l.planAssign),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => AssignDialog(planId: plan.id),
                  ),
                ),
              const SizedBox(height: HoopsSpace.sm),
              Semantics(
                header: true,
                child: Text(l.planItems, style: text.titleLarge),
              ),
              if (plan.items.isEmpty)
                Text(
                  l.planNoItems,
                  style: text.bodyMedium!.copyWith(color: c.inkMuted),
                ),
              for (var i = 0; i < plan.items.length; i++)
                _ItemRow(
                  key: Key('item-${plan.items[i].id}'),
                  plan: plan,
                  index: i,
                  editable: editable,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One exercise of a plan: its position, facts and (when editable) the
/// actions sheet: edit, move up / down, delete.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    super.key,
    required this.plan,
    required this.index,
    required this.editable,
  });
  final ath.TrainingPlan plan;
  final int index;
  final bool editable;

  Future<void> _act(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final i = index;
    final item = plan.items[i];
    final notifier = ref.read(planDetailProvider(plan.id).notifier);
    final v = await showActionSheet<String>(
      context,
      title: item.title,
      actions: [
        SheetAction(icon: Icons.edit_outlined, label: l.edit, value: 'edit'),
        if (i > 0)
          SheetAction(
            icon: Icons.arrow_upward,
            label: l.planItemMoveUp,
            value: 'up',
          ),
        if (i < plan.items.length - 1)
          SheetAction(
            icon: Icons.arrow_downward,
            label: l.planItemMoveDown,
            value: 'down',
          ),
        SheetAction(
          icon: Icons.delete_outline,
          label: l.delete,
          value: 'delete',
          destructive: true,
        ),
      ],
    );
    if (v == null || !context.mounted) return;
    if (v == 'edit') {
      await showDialog<bool>(
        context: context,
        builder: (_) => PlanItemDialog(planId: plan.id, item: item),
      );
    } else if (v == 'up') {
      await runAction(context, () => notifier.move(i, i - 1));
    } else if (v == 'down') {
      await runAction(context, () => notifier.move(i, i + 1));
    } else if (v == 'delete') {
      if (!await confirmDialog(
        context,
        message: l.planItemDeleteConfirm,
        confirmLabel: l.delete,
      ))
        return;
      if (!context.mounted) return;
      await runAction(context, () => notifier.deleteItem(item.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final item = plan.items[index];
    return ListRow(
      leading: InitialsAvatar(name: '${index + 1}'),
      title: item.title,
      subtitle: _facts(l, item),
      details: item.description == null && item.videoUrl == null
          ? null
          : _ItemInfo(item: item),
      trailing: editable
          ? IconButton(
              key: Key('item-menu-${item.id}'),
              tooltip: l.moreActions,
              icon: const Icon(Icons.more_vert),
              onPressed: () => _act(context, ref),
            )
          : null,
    );
  }
}

String? _facts(AppLocalizations l, ath.PlanItem item) {
  final facts = [
    if (item.durationMinutes != null)
      l.sessionDurationMinutes(item.durationMinutes!),
    if (item.sets != null && item.repetitions != null)
      l.planItemSetsReps(item.repetitions!, item.sets!),
  ];
  return facts.isEmpty ? null : facts.join(' · ');
}

/// The description and the video link of an exercise.
class _ItemInfo extends StatelessWidget {
  const _ItemInfo({required this.item});
  final ath.PlanItem item;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.xs,
      children: [
        if (item.description != null) Text(item.description!),
        if (item.videoUrl != null)
          Row(
            spacing: HoopsSpace.xs,
            children: [
              Icon(Icons.play_circle_outline, color: c.brand),
              Expanded(
                child: SelectableText(
                  item.videoUrl!,
                  style: text.bodySmall!.copyWith(color: c.accentText),
                ),
              ),
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
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late final _duration = TextEditingController(
    text: widget.item?.durationMinutes?.toString(),
  );
  late final _sets = TextEditingController(text: widget.item?.sets?.toString());
  late final _reps = TextEditingController(
    text: widget.item?.repetitions?.toString(),
  );
  late final _video = TextEditingController(text: widget.item?.videoUrl);

  @override
  void dispose() {
    for (final c in [_title, _description, _duration, _sets, _reps, _video]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  String? _optionalInt(AppLocalizations l, String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = int.tryParse(v!.trim());
    return n == null || n < 1 ? l.fieldInvalidNumber : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(planDetailProvider(widget.planId).notifier);
    Widget number(String key, TextEditingController c, String label) =>
        Expanded(
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
            ath.PlanItemInput(
              (b) => b
                ..title = _title.text.trim()
                ..description = _text(_description)
                ..durationMinutes = _int(_duration)
                ..sets = _int(_sets)
                ..repetitions = _int(_reps)
                ..videoUrl = _text(_video),
            ),
          );
        } else {
          await notifier.updateItem(
            widget.item!.id,
            ath.UpdatePlanItemRequest(
              (b) => b
                ..title = _title.text.trim()
                ..description = _text(_description)
                ..durationMinutes = _int(_duration)
                ..sets = _int(_sets)
                ..repetitions = _int(_reps)
                ..videoUrl = _text(_video)
                ..clear = clearList({
                  ath.UpdatePlanItemRequestClearEnum.description: b.description,
                  ath.UpdatePlanItemRequestClearEnum.durationMinutes:
                      b.durationMinutes,
                  ath.UpdatePlanItemRequestClearEnum.sets: b.sets,
                  ath.UpdatePlanItemRequestClearEnum.repetitions: b.repetitions,
                  ath.UpdatePlanItemRequestClearEnum.videoUrl: b.videoUrl,
                }),
            ),
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
            const SizedBox(width: HoopsSpace.sm),
            number('item-sets', _sets, l.planItemSets),
            const SizedBox(width: HoopsSpace.sm),
            number('item-reps', _reps, l.planItemReps),
          ],
        ),
        formGap,
        TextFormField(
          key: const Key('item-video'),
          controller: _video,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l.planItemVideo),
          validator: (v) =>
              (v ?? '').trim().isEmpty || v!.trim().startsWith('https://')
              ? null
              : l.planItemVideoInvalid,
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
        () => ref
            .read(assignmentsProvider(null).notifier)
            .assign(
              planId: widget.planId,
              teamId: _team ? _teamId : null,
              playerId: _team
                  ? null
                  : (_playerId ??
                        ref.read(selectablePlayerIdsProvider).firstOrNull),
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
            items: [
              for (final t in teams)
                DropdownMenuItem(value: t.id, child: Text(t.displayLabel)),
            ],
            validator: (v) => v == null ? l.fieldRequired : null,
            onChanged: (v) => setState(() => _teamId = v),
          )
        else
          PlayerPicker(
            label: l.assignTarget,
            value: _playerId,
            onChanged: (v) => setState(() => _playerId = v),
          ),
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
