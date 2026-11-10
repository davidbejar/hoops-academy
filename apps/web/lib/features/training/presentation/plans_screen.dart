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
import '../application/exercise_providers.dart';
import '../application/training_providers.dart';
import 'exercise_catalogue.dart';
import 'exercise_form.dart';
import 'plan_search.dart' show ExerciseSearchDialog;
import 'player_picker.dart';
import 'training_labels.dart' show exerciseFacts;

/// Plan library: the academy's plans, the templates (read-only, copy on use)
/// and the exercise catalogue (WP92); one search box for the three tabs.
class PlanLibraryScreen extends ConsumerWidget {
  const PlanLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return DefaultTabController(
      length: 3,
      child: SubPage(
        title: l.planLibraryTitle,
        parentPath: '/training',
        floatingActionButton: caps.canEditPlans ? const _LibraryFab() : null,
        child: Guarded(
          allowed: caps.canSeeModule,
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
                    onChanged: (v) {
                      ref.read(planSearchProvider.notifier).set(v);
                      ref.read(exerciseFilterProvider.notifier).search(v);
                    },
                  ),
                ),
              ),
              TabBar(
                tabs: [
                  Tab(key: const Key('tab-mine'), text: l.planMine),
                  Tab(key: const Key('tab-templates'), text: l.planTemplates),
                  Tab(
                    key: const Key('tab-exercises'),
                    text: l.exerciseCatalogueTab,
                  ),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _PlanList(templates: false),
                    _PlanList(templates: true),
                    ExerciseCatalogue(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "New plan" on the plan tabs, "new exercise" on the catalogue tab.
class _LibraryFab extends StatelessWidget {
  const _LibraryFab();

  static const _catalogueTab = 2;

  Future<void> _newPlan(BuildContext context) async {
    ath.TrainingPlan? created;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NewPlanDialog(onCreated: (p) => created = p),
    );
    if ((ok ?? false) && created != null && context.mounted)
      context.go('/training/plans/${created!.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: tabs,
      builder: (context, _) => tabs.index == _catalogueTab
          ? FloatingActionButton.extended(
              key: const Key('exercise-new'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const ExerciseDialog(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l.exerciseNew),
            )
          : FloatingActionButton.extended(
              key: const Key('plan-new'),
              onPressed: () => _newPlan(context),
              icon: const Icon(Icons.add),
              label: Text(l.planNew),
            ),
    );
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
          bottom: HoopsSize.fabClearance,
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
        bottom: HoopsSize.fabClearance,
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
              if (editable)
                FilledButton.tonalIcon(
                  key: const Key('plan-add-from-catalogue'),
                  icon: const Icon(Icons.library_add_outlined),
                  label: Text(l.planAddFromCatalogue),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ExerciseSearchDialog(
                      onAdd: ref
                          .read(planDetailProvider(plan.id).notifier)
                          .addExercises,
                    ),
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
    final fromCatalogue = item.exerciseId != null;
    return ListRow(
      leading: InitialsAvatar(name: '${index + 1}'),
      title: item.title,
      subtitle: exerciseFacts(
        l,
        minutes: item.durationMinutes,
        sets: item.sets,
        repetitions: item.repetitions,
      ),
      details: item.description == null && item.videoUrl == null
          ? null
          : ExerciseInfo(
              description: item.description,
              videoUrl: item.videoUrl,
            ),
      trailing: editable || fromCatalogue
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fromCatalogue)
                  CatalogueMarker(key: Key('item-from-catalogue-${item.id}')),
                if (editable)
                  IconButton(
                    key: Key('item-menu-${item.id}'),
                    tooltip: l.moreActions,
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _act(context, ref),
                  ),
              ],
            )
          : null,
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
  late final _fields = ExerciseFields(
    title: widget.item?.title,
    description: widget.item?.description,
    minutes: widget.item?.durationMinutes,
    sets: widget.item?.sets,
    repetitions: widget.item?.repetitions,
    videoUrl: widget.item?.videoUrl,
  );

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final notifier = ref.read(planDetailProvider(widget.planId).notifier);
    final f = _fields;
    final item = widget.item;
    if (item == null) {
      return notifier.addItem(
        ath.PlanItemInput(
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
    return notifier.updateItem(
      item.id,
      ath.UpdatePlanItemRequest(
        (b) => b
          ..title = f.title
          ..description = f.description
          ..durationMinutes = f.minutes
          ..sets = f.sets
          ..repetitions = f.repetitions
          ..videoUrl = f.videoUrl
          ..clear = clearList({
            ath.UpdatePlanItemRequestClearEnum.description: f.description,
            ath.UpdatePlanItemRequestClearEnum.durationMinutes: f.minutes,
            ath.UpdatePlanItemRequestClearEnum.sets: f.sets,
            ath.UpdatePlanItemRequestClearEnum.repetitions: f.repetitions,
            ath.UpdatePlanItemRequestClearEnum.videoUrl: f.videoUrl,
          }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: widget.item == null ? l.planItemAdd : l.planItemEdit,
      formKey: _form,
      onSubmit: () => runAction(context, _save),
      children: _fields.build(l, keyPrefix: 'item'),
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
