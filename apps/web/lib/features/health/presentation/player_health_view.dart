import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/clear_list.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../training/presentation/player_picker.dart' show playerNameProvider;
import '../../training/presentation/training_labels.dart' show fullDate;
import '../../training/application/training_providers.dart' show toAthDate;
import '../application/health_providers.dart';
import 'charts.dart';
import 'health_labels.dart';
import 'scale_hint.dart';

enum HealthTab { injuries, growth, tests }

/// Injuries / growth / physical tests of one player. Not scrollable itself:
/// embed it in a ListView (profile tabs, staff health page).
class PlayerHealthView extends ConsumerStatefulWidget {
  const PlayerHealthView({
    super.key,
    required this.playerId,
    this.initial = HealthTab.injuries,
  });
  final String playerId;
  final HealthTab initial;

  @override
  ConsumerState<PlayerHealthView> createState() => _PlayerHealthViewState();
}

class _PlayerHealthViewState extends ConsumerState<PlayerHealthView> {
  late HealthTab _tab = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {
      HealthTab.injuries: l.healthInjuries,
      HealthTab.growth: l.healthGrowth,
      HealthTab.tests: l.healthTests,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.md,
      children: [
        AvailabilityBadge(playerId: widget.playerId, showAvailable: true),
        Wrap(
          spacing: HoopsSpace.sm,
          runSpacing: HoopsSpace.sm,
          children: [
            for (final t in HealthTab.values)
              ChoiceChip(
                key: Key('health-tab-${t.name}'),
                label: Text(labels[t]!),
                selected: _tab == t,
                onSelected: (_) => setState(() => _tab = t),
              ),
          ],
        ),
        switch (_tab) {
          HealthTab.injuries => InjuriesSection(playerId: widget.playerId),
          HealthTab.growth => GrowthSection(playerId: widget.playerId),
          HealthTab.tests => TestsSection(playerId: widget.playerId),
        },
      ],
    );
  }
}

/// "Injured: knee" / "Available" chip fed by the open injuries.
class AvailabilityBadge extends ConsumerWidget {
  const AvailabilityBadge({
    super.key,
    required this.playerId,
    this.showAvailable = false,
  });
  final String playerId;
  final bool showAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final open = ref.watch(openInjuriesProvider).value;
    if (open == null) return const SizedBox.shrink();
    final injury = open[playerId];
    if (injury != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: StatusChip(
          l.availabilityInjured(injury.bodyPart),
          tone: HoopsTone.danger,
          icon: Icons.healing,
          key: const Key('availability-injured'),
        ),
      );
    }
    return showAvailable
        ? Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              l.availabilityAvailable,
              tone: HoopsTone.success,
              icon: Icons.check_circle_outline,
              key: const Key('availability-ok'),
            ),
          )
        : const SizedBox.shrink();
  }
}

/// Player header + health for the staff route `/players/:id/health`.
class PlayerHealthScreen extends ConsumerWidget {
  const PlayerHealthScreen({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return SubPage(
      title: ref.watch(playerNameProvider(playerId)) ?? l.healthTitle,
      parentPath: '/players/$playerId',
      child: Guarded(
        allowed: caps.canSeeModule,
        child: PageBody(
          children: [
            // Full width: a bare section would be centred by the frame.
            SizedBox(
              width: double.infinity,
              child: PlayerHealthView(playerId: playerId),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- injuries

class InjuriesSection extends ConsumerWidget {
  const InjuriesSection({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final canWrite = caps.canWriteHealth(playerId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.gap,
      children: [
        if (canWrite)
          FilledButton.icon(
            key: const Key('injury-new'),
            icon: const Icon(Icons.add),
            label: Text(l.injuryNew),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => InjuryDialog(playerId: playerId),
            ),
          ),
        AsyncBody<List<ath.Injury>>(
          value: ref.watch(injuriesProvider(playerId)),
          onRetry: () => ref.invalidate(injuriesProvider(playerId)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.injuryEmpty,
          builder: (context, data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: HoopsSpace.gap,
            children: [
              for (final i in data) _InjuryCard(injury: i, canWrite: canWrite),
            ],
          ),
        ),
      ],
    );
  }
}

class _InjuryCard extends ConsumerWidget {
  const _InjuryCard({required this.injury, required this.canWrite});
  final ath.Injury injury;
  final bool canWrite;

  Future<DateTime?> _pick(BuildContext context, DateTime initial) =>
      showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(DateTime.now().year + 2),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final i = injury;
    final open = i.status == ath.InjuryStatus.OPEN;
    final notifier = ref.read(injuriesProvider(i.playerId).notifier);
    return SectionCard(
      key: Key('injury-${i.id}'),
      title: i.bodyPart,
      actions: [
        StatusChip(
          open ? l.injuryStatusOpen : l.injuryStatusRecovered,
          tone: open ? HoopsTone.danger : HoopsTone.success,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.xs,
        children: [
          Wrap(
            spacing: HoopsSpace.sm,
            runSpacing: HoopsSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                i.severity.label(l),
                tone: i.severity == ath.InjurySeverity.SEVERE
                    ? HoopsTone.danger
                    : HoopsTone.warning,
              ),
              Text(
                fullDate(i.occurredOn),
                style: text.bodySmall!.copyWith(color: c.inkMuted),
              ),
            ],
          ),
          if (i.description != null) Text(i.description!),
          if (open && i.expectedReturnOn != null)
            Text(l.injuryReturnLine(fullDate(i.expectedReturnOn!))),
          if (!open && i.actualReturnOn != null)
            Text(l.injuryRecoveredLine(fullDate(i.actualReturnOn!))),
          if (canWrite)
            Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.sm),
              child: Wrap(
                spacing: HoopsSpace.sm,
                runSpacing: HoopsSpace.sm,
                children: [
                  TextButton.icon(
                    key: Key('injury-edit-${i.id}'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l.injuryEdit),
                    onPressed: () => showDialog<bool>(
                      context: context,
                      builder: (_) => InjuryEditDialog(injury: i),
                    ),
                  ),
                  if (open) ...[
                    TextButton.icon(
                      key: Key('injury-return-${i.id}'),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(l.injuryUpdateReturn),
                      onPressed: () async {
                        final d = await _pick(
                          context,
                          i.expectedReturnOn?.toDateTime() ?? DateTime.now(),
                        );
                        if (d == null || !context.mounted) return;
                        await runAction(
                          context,
                          () => notifier.updateExpectedReturn(i.id, d),
                          success: l.injurySaved,
                        );
                      },
                    ),
                    FilledButton.tonalIcon(
                      key: Key('injury-recover-${i.id}'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l.injuryRecover),
                      onPressed: () async {
                        final d = await _pick(context, DateTime.now());
                        if (d == null || !context.mounted) return;
                        await runAction(
                          context,
                          () => notifier.recover(i.id, d),
                          success: l.injurySaved,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class InjuryDialog extends ConsumerStatefulWidget {
  const InjuryDialog({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<InjuryDialog> createState() => _InjuryDialogState();
}

class _InjuryDialogState extends ConsumerState<InjuryDialog> {
  final _form = GlobalKey<FormState>();
  final _part = TextEditingController();
  final _description = TextEditingController();
  ath.InjurySeverity _severity = ath.InjurySeverity.MINOR;
  DateTime _on = DateTime.now();
  DateTime? _return;

  @override
  void dispose() {
    _part.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.injuryNew,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(injuriesProvider(widget.playerId).notifier)
            .create(
              occurredOn: _on,
              bodyPart: _part.text.trim(),
              severity: _severity,
              description: _description.text.trim().isEmpty
                  ? null
                  : _description.text.trim(),
              expectedReturnOn: _return,
            ),
        success: l.injurySaved,
      ),
      children: [
        TextFormField(
          key: const Key('injury-part'),
          controller: _part,
          decoration: InputDecoration(labelText: l.injuryBodyPart),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        DropdownButtonFormField<ath.InjurySeverity>(
          key: const Key('injury-severity'),
          initialValue: _severity,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.injurySeverity),
          items: [
            for (final s in [
              ath.InjurySeverity.MINOR,
              ath.InjurySeverity.MODERATE,
              ath.InjurySeverity.SEVERE,
            ])
              DropdownMenuItem(value: s, child: Text(s.label(l))),
          ],
          onChanged: (v) => setState(() => _severity = v ?? _severity),
        ),
        formGap,
        DateField(
          key: const Key('injury-date'),
          label: l.injuryOccurredOn,
          value: _on,
          onChanged: (d) => setState(() => _on = d),
        ),
        formGap,
        DateField(
          key: const Key('injury-expected'),
          label: l.injuryExpectedReturn,
          value: _return,
          firstDate: _on,
          onChanged: (d) => setState(() => _return = d),
          onClear: () => setState(() => _return = null),
        ),
        formGap,
        TextFormField(
          key: const Key('injury-description'),
          controller: _description,
          maxLines: 2,
          decoration: InputDecoration(labelText: l.injuryDescription),
        ),
      ],
    );
  }
}

/// Edits every field `UpdateInjuryRequest` offers; emptied optional fields are sent in `clear` (ADR-0032).
class InjuryEditDialog extends ConsumerStatefulWidget {
  const InjuryEditDialog({super.key, required this.injury});
  final ath.Injury injury;

  @override
  ConsumerState<InjuryEditDialog> createState() => _InjuryEditDialogState();
}

class _InjuryEditDialogState extends ConsumerState<InjuryEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _part = TextEditingController(text: widget.injury.bodyPart);
  late final _description = TextEditingController(
    text: widget.injury.description ?? '',
  );
  late ath.InjurySeverity _severity = widget.injury.severity;
  late DateTime _on = widget.injury.occurredOn.toDateTime();
  late DateTime? _expected = widget.injury.expectedReturnOn?.toDateTime();
  late DateTime? _actual = widget.injury.actualReturnOn?.toDateTime();
  bool _datesBeforeInjury = false;

  bool get _recovered => widget.injury.status == ath.InjuryStatus.RECOVERED;

  @override
  void dispose() {
    _part.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _validateDates() {
    final day = DateTime(_on.year, _on.month, _on.day);
    final before =
        (_expected != null && _expected!.isBefore(day)) ||
        (_actual != null && _actual!.isBefore(day));
    setState(() => _datesBeforeInjury = before);
    return !before;
  }

  ath.UpdateInjuryRequest _request() {
    final text = _description.text.trim();
    return ath.UpdateInjuryRequest(
      (b) => b
        ..occurredOn = toAthDate(_on)
        ..bodyPart = _part.text.trim()
        ..severity = _severity
        ..description = text.isEmpty ? null : text
        ..expectedReturnOn = _expected == null ? null : toAthDate(_expected!)
        ..actualReturnOn = _actual == null ? null : toAthDate(_actual!)
        ..clear = clearList({
          ath.UpdateInjuryRequestClearEnum.description: text.isEmpty
              ? null
              : text,
          ath.UpdateInjuryRequestClearEnum.expectedReturnOn: _expected,
          if (_recovered)
            ath.UpdateInjuryRequestClearEnum.actualReturnOn: _actual,
        }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateError = _datesBeforeInjury ? l.injuryReturnBeforeInjury : null;
    return FormDialog(
      title: l.injuryEdit,
      formKey: _form,
      validateExtra: _validateDates,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(injuriesProvider(widget.injury.playerId).notifier)
            .edit(widget.injury.id, _request()),
        success: l.injurySaved,
      ),
      children: [
        TextFormField(
          key: const Key('injury-part'),
          controller: _part,
          decoration: InputDecoration(labelText: l.injuryBodyPart),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        DropdownButtonFormField<ath.InjurySeverity>(
          key: const Key('injury-severity'),
          initialValue: _severity,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.injurySeverity),
          items: [
            for (final s in [
              ath.InjurySeverity.MINOR,
              ath.InjurySeverity.MODERATE,
              ath.InjurySeverity.SEVERE,
            ])
              DropdownMenuItem(value: s, child: Text(s.label(l))),
          ],
          onChanged: (v) => setState(() => _severity = v ?? _severity),
        ),
        formGap,
        DateField(
          key: const Key('injury-date'),
          label: l.injuryOccurredOn,
          value: _on,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _on = d),
        ),
        formGap,
        DateField(
          key: const Key('injury-expected'),
          label: l.injuryExpectedReturn,
          value: _expected,
          errorText: dateError,
          onChanged: (d) => setState(() => _expected = d),
          onClear: () => setState(() => _expected = null),
        ),
        if (_recovered) ...[
          formGap,
          DateField(
            key: const Key('injury-actual'),
            label: l.injuryRecoveredOn,
            value: _actual,
            errorText: dateError,
            onChanged: (d) => setState(() => _actual = d),
            onClear: () => setState(() => _actual = null),
          ),
        ],
        formGap,
        TextFormField(
          key: const Key('injury-description'),
          controller: _description,
          maxLines: 2,
          decoration: InputDecoration(labelText: l.injuryDescription),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------- growth

class GrowthSection extends ConsumerWidget {
  const GrowthSection({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final canWrite = ref.watch(capabilitiesProvider).canWriteHealth(playerId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.gap,
      children: [
        if (canWrite)
          FilledButton.icon(
            key: const Key('growth-add'),
            icon: const Icon(Icons.add),
            label: Text(l.growthAdd),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => MeasurementDialog(playerId: playerId),
            ),
          ),
        AsyncBody<List<ath.BodyMeasurement>>(
          value: ref.watch(measurementsProvider(playerId)),
          onRetry: () => ref.invalidate(measurementsProvider(playerId)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.growthEmpty,
          builder: (context, data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: HoopsSpace.gap,
            children: [
              GrowthChart(
                title: l.growthHeight,
                points: measurementPoints(data, height: true),
              ),
              GrowthChart(
                title: l.growthWeight,
                points: measurementPoints(data, height: false),
              ),
              for (final m in data.reversed)
                MeasurementTile(measurement: m, canWrite: canWrite),
            ],
          ),
        ),
      ],
    );
  }
}

/// One measurement row; staff and linked parents can correct or delete it.
class MeasurementTile extends ConsumerWidget {
  const MeasurementTile({
    super.key,
    required this.measurement,
    required this.canWrite,
  });
  final ath.BodyMeasurement measurement;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final m = measurement;
    final values = [
      if (m.heightCm != null) '${_num(m.heightCm!)} cm',
      if (m.weightKg != null) '${_num(m.weightKg!)} kg',
    ].join(' · ');
    return ListRow(
      key: Key('measurement-${m.id}'),
      leading: const IconTile(Icons.straighten, tone: HoopsTone.info),
      title: values,
      subtitle: fullDate(m.measuredOn),
      trailing: canWrite
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('measurement-edit-${m.id}'),
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        MeasurementDialog(playerId: m.playerId, measurement: m),
                  ),
                ),
                IconButton(
                  key: Key('measurement-delete-${m.id}'),
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (!await confirmDialog(
                      context,
                      message: l.measurementDeleteConfirm,
                      confirmLabel: l.delete,
                    ))
                      return;
                    if (!context.mounted) return;
                    await runAction(
                      context,
                      () => ref
                          .read(measurementsProvider(m.playerId).notifier)
                          .delete(m.id),
                    );
                  },
                ),
              ],
            )
          : null,
    );
  }
}

/// Adds a measurement, or corrects [measurement].
class MeasurementDialog extends ConsumerStatefulWidget {
  const MeasurementDialog({
    super.key,
    required this.playerId,
    this.measurement,
  });
  final String playerId;
  final ath.BodyMeasurement? measurement;

  @override
  ConsumerState<MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends ConsumerState<MeasurementDialog> {
  final _form = GlobalKey<FormState>();
  late final _height = TextEditingController(
    text: _initial(widget.measurement?.heightCm),
  );
  late final _weight = TextEditingController(
    text: _initial(widget.measurement?.weightKg),
  );
  late DateTime _on =
      widget.measurement?.measuredOn.toDateTime() ?? DateTime.now();
  bool _needOne = false;

  static String _initial(double? v) => v == null ? '' : _num(v);

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _optional(AppLocalizations l, String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = double.tryParse(v!.trim().replaceAll(',', '.'));
    return n == null || n <= 0 ? l.fieldInvalidNumber : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final editing = widget.measurement != null;
    return FormDialog(
      title: editing ? l.growthEdit : l.growthAdd,
      formKey: _form,
      validateExtra: () {
        final none = _parse(_height) == null && _parse(_weight) == null;
        setState(() => _needOne = none);
        return !none;
      },
      onSubmit: () => runAction(
        context,
        () => editing
            ? ref
                  .read(measurementsProvider(widget.playerId).notifier)
                  .correct(
                    widget.measurement!.id,
                    measuredOn: _on,
                    heightCm: _parse(_height),
                    weightKg: _parse(_weight),
                  )
            : ref
                  .read(measurementsProvider(widget.playerId).notifier)
                  .add(
                    measuredOn: _on,
                    heightCm: _parse(_height),
                    weightKg: _parse(_weight),
                  ),
        success: l.saved,
      ),
      children: [
        DateField(
          key: const Key('growth-date'),
          label: l.growthMeasuredOn,
          value: _on,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _on = d),
        ),
        formGap,
        TextFormField(
          key: const Key('growth-height'),
          controller: _height,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.growthHeight),
          validator: (v) => _optional(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('growth-weight'),
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.growthWeight),
          validator: (v) => _optional(l, v),
        ),
        if (_needOne)
          Padding(
            padding: const EdgeInsets.only(top: HoopsSpace.sm),
            child: Text(
              l.growthNeedOne,
              key: const Key('growth-need-one'),
              style: TextStyle(
                color: HoopsTokens.colorsOf(context).danger.foreground,
              ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------------- tests

class TestsSection extends ConsumerWidget {
  const TestsSection({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final types = {
      for (final t
          in ref.watch(testTypesProvider).value ??
              const <ath.PhysicalTestType>[])
        t.id: t,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.gap,
      children: [
        if (caps.canEnterTestResults)
          FilledButton.icon(
            key: const Key('test-add'),
            icon: const Icon(Icons.add),
            label: Text(l.testAdd),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ResultDialog(playerId: playerId),
            ),
          ),
        AsyncBody<List<ath.PhysicalTestResult>>(
          value: ref.watch(testResultsProvider(playerId)),
          onRetry: () => ref.invalidate(testResultsProvider(playerId)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.testEmpty,
          builder: (context, data) {
            final byType = <String, List<ath.PhysicalTestResult>>{};
            for (final r in data) {
              byType.putIfAbsent(r.testTypeId, () => []).add(r);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: HoopsSpace.gap,
              children: [
                for (final e in byType.entries) ...[
                  BandHistoryChart(
                    title: types[e.key]?.name ?? e.value.first.testCode,
                    unit: e.value.first.unit,
                    points: resultPoints(e.value),
                  ),
                  ScaleHint(code: e.value.first.testCode),
                  for (final r in e.value.reversed)
                    ResultTile(result: r, canWrite: caps.canEnterTestResults),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One result with its expected band and the "reference pending" flag.
class ResultTile extends ConsumerWidget {
  const ResultTile({super.key, required this.result, this.canWrite = false});
  final ath.PhysicalTestResult result;
  final bool canWrite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final r = result;
    return ListRow(
      key: Key('result-${r.id}'),
      leading: const IconTile(Icons.speed, tone: HoopsTone.info),
      title: l.testResultLine(r.unit, _num(r.value)),
      subtitle: r.ageAtMeasurement == null
          ? fullDate(r.measuredOn)
          : '${fullDate(r.measuredOn)} · ${l.testAtAge(r.ageAtMeasurement!)}',
      details: Wrap(
        spacing: HoopsSpace.xs,
        runSpacing: HoopsSpace.xs,
        children: [
          StatusChip(
            r.expectedBand == null
                ? l.testNoBand.split(' ').take(2).join(' ')
                : r.expectedBand!.label(l),
            tone: r.expectedBand == null ? HoopsTone.neutral : HoopsTone.info,
          ),
          if (r.referencePending)
            StatusChip(
              l.testReferencePending,
              tone: HoopsTone.warning,
              icon: Icons.hourglass_empty,
            ),
        ],
      ),
      trailing: canWrite
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('result-edit-${r.id}'),
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => ResultEditDialog(result: r),
                  ),
                ),
                IconButton(
                  key: Key('result-delete-${r.id}'),
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (!await confirmDialog(
                      context,
                      message: l.resultDeleteConfirm,
                      confirmLabel: l.delete,
                    ))
                      return;
                    if (!context.mounted) return;
                    await runAction(
                      context,
                      () => ref
                          .read(testResultsProvider(r.playerId).notifier)
                          .delete(r.id),
                    );
                  },
                ),
              ],
            )
          : null,
    );
  }
}

/// Corrects the value, date and notes of a stored result (the test type is fixed).
class ResultEditDialog extends ConsumerStatefulWidget {
  const ResultEditDialog({super.key, required this.result});
  final ath.PhysicalTestResult result;

  @override
  ConsumerState<ResultEditDialog> createState() => _ResultEditDialogState();
}

class _ResultEditDialogState extends ConsumerState<ResultEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _value = TextEditingController(text: _num(widget.result.value));
  late final _notes = TextEditingController(text: widget.result.notes ?? '');
  late DateTime _on = widget.result.measuredOn.toDateTime();

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = widget.result;
    return FormDialog(
      title: '${l.testEdit} · ${r.testCode}',
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(testResultsProvider(r.playerId).notifier)
            .correct(
              r.id,
              measuredOn: _on,
              value: double.parse(_value.text.trim().replaceAll(',', '.')),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
        success: l.saved,
      ),
      children: [
        TextFormField(
          key: const Key('result-value'),
          controller: _value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '${l.testValue} (${r.unit})'),
          validator: (v) =>
              double.tryParse((v ?? '').trim().replaceAll(',', '.')) == null
              ? l.fieldInvalidNumber
              : null,
        ),
        ScaleHint(code: r.testCode),
        formGap,
        DateField(
          key: const Key('result-date'),
          label: l.testMeasuredOn,
          value: _on,
          lastDate: DateTime.now(),
          onChanged: (d) => setState(() => _on = d),
        ),
        formGap,
        TextFormField(
          key: const Key('result-notes'),
          controller: _notes,
          decoration: InputDecoration(labelText: l.testNotes),
        ),
      ],
    );
  }
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// Results entry; after saving it shows the expected band right away.
class ResultDialog extends ConsumerStatefulWidget {
  const ResultDialog({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends ConsumerState<ResultDialog> {
  final _form = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _notes = TextEditingController();
  String? _typeId;
  DateTime _on = DateTime.now();
  ath.PhysicalTestResult? _saved;
  bool _busy = false;

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    ath.PhysicalTestResult? r;
    final ok = await runAction(context, () async {
      r = await ref
          .read(testResultsProvider(widget.playerId).notifier)
          .add(
            testTypeId: _typeId!,
            measuredOn: _on,
            value: double.parse(_value.text.trim().replaceAll(',', '.')),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _saved = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final saved = _saved;
    if (saved != null) {
      return AlertDialog(
        title: Text(l.testAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saved.expectedBand == null
                  ? l.testSavedNoBand
                  : l.testSavedBand(saved.expectedBand!.label(l)),
              key: const Key('result-band'),
            ),
            if (saved.referencePending)
              Padding(
                padding: const EdgeInsets.only(top: HoopsSpace.sm),
                child: StatusChip(
                  l.testReferencePending,
                  tone: HoopsTone.warning,
                  icon: Icons.hourglass_empty,
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            key: const Key('result-close'),
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      );
    }
    final types =
        ref.watch(testTypesProvider).value ?? const <ath.PhysicalTestType>[];
    return AlertDialog(
      title: Text(l.testAdd),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('result-type'),
              initialValue: _typeId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.testType),
              items: [
                for (final t in types)
                  DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.name} (${t.unit})'),
                  ),
              ],
              validator: (v) => v == null ? l.fieldRequired : null,
              onChanged: (v) => setState(() => _typeId = v),
            ),
            formGap,
            TextFormField(
              key: const Key('result-value'),
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.testValue),
              validator: (v) =>
                  double.tryParse((v ?? '').trim().replaceAll(',', '.')) == null
                  ? l.fieldInvalidNumber
                  : null,
            ),
            ScaleHint(
              code: types.where((t) => t.id == _typeId).firstOrNull?.code,
            ),
            formGap,
            DateField(
              key: const Key('result-date'),
              label: l.testMeasuredOn,
              value: _on,
              lastDate: DateTime.now(),
              onChanged: (d) => setState(() => _on = d),
            ),
            formGap,
            TextFormField(
              key: const Key('result-notes'),
              controller: _notes,
              decoration: InputDecoration(labelText: l.testNotes),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('form-cancel'),
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('form-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l.save),
        ),
      ],
    );
  }
}
