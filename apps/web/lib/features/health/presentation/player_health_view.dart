import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../training/presentation/player_picker.dart' show playerNameProvider;
import '../../training/presentation/training_labels.dart' show fullDate;
import '../application/health_providers.dart';
import 'charts.dart';
import 'health_labels.dart';

enum HealthTab { injuries, growth, tests }

/// Injuries / growth / physical tests of one player. Not scrollable itself:
/// embed it in a ListView (profile tabs, staff health page).
class PlayerHealthView extends ConsumerStatefulWidget {
  const PlayerHealthView({super.key, required this.playerId, this.initial = HealthTab.injuries});
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
    final labels = {HealthTab.injuries: l.healthInjuries, HealthTab.growth: l.healthGrowth, HealthTab.tests: l.healthTests};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvailabilityBadge(playerId: widget.playerId, showAvailable: true),
        const SizedBox(height: AppTokens.spaceSm),
        Wrap(
          spacing: AppTokens.spaceSm,
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
        const SizedBox(height: AppTokens.spaceSm),
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
  const AvailabilityBadge({super.key, required this.playerId, this.showAvailable = false});
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
        child: InfoChip(l.availabilityInjured(injury.bodyPart), tone: ChipTone.bad, icon: Icons.healing, key: const Key('availability-injured')),
      );
    }
    return showAvailable
        ? Align(
            alignment: Alignment.centerLeft,
            child: InfoChip(l.availabilityAvailable, tone: ChipTone.good, icon: Icons.check_circle_outline, key: const Key('availability-ok')),
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
        child: ListView(padding: const EdgeInsets.all(AppTokens.spaceMd), children: [PlayerHealthView(playerId: playerId)]),
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
      children: [
        if (canWrite)
          FilledButton.icon(
            key: const Key('injury-new'),
            icon: const Icon(Icons.add),
            label: Text(l.injuryNew),
            onPressed: () => showDialog<bool>(context: context, builder: (_) => InjuryDialog(playerId: playerId)),
          ),
        AsyncBody<List<ath.Injury>>(
          value: ref.watch(injuriesProvider(playerId)),
          onRetry: () => ref.invalidate(injuriesProvider(playerId)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.injuryEmpty,
          builder: (context, data) => Column(
            children: [for (final i in data) _InjuryCard(injury: i, canWrite: canWrite)],
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
      showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(DateTime.now().year + 2));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final i = injury;
    final open = i.status == ath.InjuryStatus.OPEN;
    final notifier = ref.read(injuriesProvider(i.playerId).notifier);
    return Card(
      key: Key('injury-${i.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(i.bodyPart, style: theme.textTheme.titleMedium)),
                InfoChip(
                  open ? l.injuryStatusOpen : l.injuryStatusRecovered,
                  tone: open ? ChipTone.bad : ChipTone.good,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceXs),
            Wrap(
              spacing: AppTokens.spaceSm,
              children: [
                InfoChip(i.severity.label(l), tone: i.severity == ath.InjurySeverity.SEVERE ? ChipTone.bad : ChipTone.warn),
                Text(fullDate(i.occurredOn), style: theme.textTheme.bodySmall),
              ],
            ),
            if (i.description != null) Text(i.description!),
            if (open && i.expectedReturnOn != null) Text(l.injuryReturnLine(fullDate(i.expectedReturnOn!))),
            if (!open && i.actualReturnOn != null) Text(l.injuryRecoveredLine(fullDate(i.actualReturnOn!))),
            if (open && canWrite)
              Wrap(
                spacing: AppTokens.spaceSm,
                children: [
                  TextButton(
                    key: Key('injury-return-${i.id}'),
                    onPressed: () async {
                      final d = await _pick(context, i.expectedReturnOn?.toDateTime() ?? DateTime.now());
                      if (d == null || !context.mounted) return;
                      await runAction(context, () => notifier.updateExpectedReturn(i.id, d), success: l.injurySaved);
                    },
                    child: Text(l.injuryUpdateReturn),
                  ),
                  FilledButton.tonal(
                    key: Key('injury-recover-${i.id}'),
                    onPressed: () async {
                      final d = await _pick(context, DateTime.now());
                      if (d == null || !context.mounted) return;
                      await runAction(context, () => notifier.recover(i.id, d), success: l.injurySaved);
                    },
                    child: Text(l.injuryRecover),
                  ),
                ],
              ),
          ],
        ),
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
        () => ref.read(injuriesProvider(widget.playerId).notifier).create(
          occurredOn: _on,
          bodyPart: _part.text.trim(),
          severity: _severity,
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
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
            for (final s in [ath.InjurySeverity.MINOR, ath.InjurySeverity.MODERATE, ath.InjurySeverity.SEVERE])
              DropdownMenuItem(value: s, child: Text(s.label(l))),
          ],
          onChanged: (v) => setState(() => _severity = v ?? _severity),
        ),
        formGap,
        DateField(key: const Key('injury-date'), label: l.injuryOccurredOn, value: _on, onChanged: (d) => setState(() => _on = d)),
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
      children: [
        if (canWrite)
          FilledButton.icon(
            key: const Key('growth-add'),
            icon: const Icon(Icons.add),
            label: Text(l.growthAdd),
            onPressed: () => showDialog<bool>(context: context, builder: (_) => MeasurementDialog(playerId: playerId)),
          ),
        AsyncBody<List<ath.BodyMeasurement>>(
          value: ref.watch(measurementsProvider(playerId)),
          onRetry: () => ref.invalidate(measurementsProvider(playerId)),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.growthEmpty,
          builder: (context, data) => Column(
            children: [
              GrowthChart(title: l.growthHeight, points: measurementPoints(data, height: true)),
              GrowthChart(title: l.growthWeight, points: measurementPoints(data, height: false)),
            ],
          ),
        ),
      ],
    );
  }
}

class MeasurementDialog extends ConsumerStatefulWidget {
  const MeasurementDialog({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends ConsumerState<MeasurementDialog> {
  final _form = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  DateTime _on = DateTime.now();
  bool _needOne = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _optional(AppLocalizations l, String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = double.tryParse(v!.trim().replaceAll(',', '.'));
    return n == null || n <= 0 ? l.fieldInvalidNumber : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.growthAdd,
      formKey: _form,
      validateExtra: () {
        final none = _num(_height) == null && _num(_weight) == null;
        setState(() => _needOne = none);
        return !none;
      },
      onSubmit: () => runAction(
        context,
        () => ref.read(measurementsProvider(widget.playerId).notifier).add(
          measuredOn: _on,
          heightCm: _num(_height),
          weightKg: _num(_weight),
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
            padding: const EdgeInsets.only(top: AppTokens.spaceSm),
            child: Text(l.growthNeedOne, key: const Key('growth-need-one'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
    final types = {for (final t in ref.watch(testTypesProvider).value ?? const <ath.PhysicalTestType>[]) t.id: t};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caps.canEnterTestResults)
          FilledButton.icon(
            key: const Key('test-add'),
            icon: const Icon(Icons.add),
            label: Text(l.testAdd),
            onPressed: () => showDialog<void>(context: context, builder: (_) => ResultDialog(playerId: playerId)),
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
              children: [
                for (final e in byType.entries) ...[
                  BandHistoryChart(
                    title: types[e.key]?.name ?? e.value.first.testCode,
                    unit: e.value.first.unit,
                    points: resultPoints(e.value),
                  ),
                  for (final r in e.value.reversed) ResultTile(result: r),
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
class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.result});
  final ath.PhysicalTestResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = result;
    return ListTile(
      key: Key('result-${r.id}'),
      dense: true,
      title: Text(l.testResultLine(r.unit, _num(r.value))),
      subtitle: Text(r.ageAtMeasurement == null
          ? fullDate(r.measuredOn)
          : '${fullDate(r.measuredOn)} · ${l.testAtAge(r.ageAtMeasurement!)}'),
      trailing: Wrap(
        spacing: AppTokens.spaceXs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InfoChip(r.expectedBand == null ? l.testNoBand.split(' ').take(2).join(' ') : r.expectedBand!.label(l)),
          if (r.referencePending) InfoChip(l.testReferencePending, tone: ChipTone.warn, icon: Icons.hourglass_empty),
        ],
      ),
    );
  }
}

String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

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
      r = await ref.read(testResultsProvider(widget.playerId).notifier).add(
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
              saved.expectedBand == null ? l.testSavedNoBand : l.testSavedBand(saved.expectedBand!.label(l)),
              key: const Key('result-band'),
            ),
            if (saved.referencePending)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceSm),
                child: InfoChip(l.testReferencePending, tone: ChipTone.warn, icon: Icons.hourglass_empty),
              ),
          ],
        ),
        actions: [FilledButton(key: const Key('result-close'), onPressed: () => Navigator.pop(context), child: Text(l.close))],
      );
    }
    final types = ref.watch(testTypesProvider).value ?? const <ath.PhysicalTestType>[];
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
              items: [for (final t in types) DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.unit})'))],
              validator: (v) => v == null ? l.fieldRequired : null,
              onChanged: (v) => setState(() => _typeId = v),
            ),
            formGap,
            TextFormField(
              key: const Key('result-value'),
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.testValue),
              validator: (v) => double.tryParse((v ?? '').trim().replaceAll(',', '.')) == null ? l.fieldInvalidNumber : null,
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
            TextFormField(key: const Key('result-notes'), controller: _notes, decoration: InputDecoration(labelText: l.testNotes)),
          ],
        ),
      ),
      actions: [
        TextButton(key: const Key('form-cancel'), onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(key: const Key('form-submit'), onPressed: _busy ? null : _submit, child: Text(l.save)),
      ],
    );
  }
}
