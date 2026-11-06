import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/errors/app_error.dart';
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/health_providers.dart';
import 'health_labels.dart';

/// Test types: global ones plus the academy's custom tests (ADMIN creates).
class TestTypesScreen extends ConsumerWidget {
  const TestTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    return SubPage(
      title: l.testTypesTitle,
      parentPath: '/players',
      floatingActionButton: caps.canAdminFitness
          ? FloatingActionButton.extended(
              key: const Key('type-new'),
              onPressed: () => showDialog<bool>(context: context, builder: (_) => const TestTypeDialog()),
              icon: const Icon(Icons.add),
              label: Text(l.testTypeNew),
            )
          : null,
      child: Guarded(
        allowed: caps.canSeeModule,
        child: AsyncBody<List<ath.PhysicalTestType>>(
          value: ref.watch(testTypesProvider),
          onRetry: () => ref.invalidate(testTypesProvider),
          isEmpty: (d) => d.isEmpty,
          emptyMessage: l.testTypesEmpty,
          builder: (context, data) => ListView(
            padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 88),
            children: [
              for (final t in data)
                Card(
                  child: ListTile(
                    key: Key('type-${t.id}'),
                    title: Text('${t.name} (${t.unit})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [t.code, t.higherIsBetter ? l.testTypeHigherYes : l.testTypeHigherNo, if (t.description != null) t.description!].join(' · '),
                        ),
                        const SizedBox(height: AppTokens.spaceXs),
                        InfoChip(t.global ? l.testTypeGlobal : l.testTypeCustom),
                      ],
                    ),
                    // Global types are read-only (403) and cannot be deleted (404).
                    trailing: !t.global && caps.canAdminFitness
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('type-edit-${t.id}'),
                                tooltip: l.edit,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => showDialog<bool>(context: context, builder: (_) => TestTypeDialog(type: t)),
                              ),
                              IconButton(
                                key: Key('type-delete-${t.id}'),
                                tooltip: l.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(context, ref, t),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A type that results use cannot be deleted (409 `TEST_TYPE_HAS_RESULTS`).
Future<void> _delete(BuildContext context, WidgetRef ref, ath.PhysicalTestType type) async {
  final l = AppLocalizations.of(context);
  if (!await confirmDialog(context, message: l.testTypeDeleteConfirm(type.name), confirmLabel: l.delete)) return;
  if (!context.mounted) return;
  await runAction(
    context,
    () => ref.read(testTypesProvider.notifier).delete(type.id),
    success: l.testTypeDeleted,
    errorText: (e, l) {
      final error = AppError.of(e);
      return error.code == 'TEST_TYPE_HAS_RESULTS' ? l.testTypeHasResults : error.message(l);
    },
  );
}

/// Creates a custom test type, or edits [type] (code included: another type's code is a 409).
class TestTypeDialog extends ConsumerStatefulWidget {
  const TestTypeDialog({super.key, this.type});
  final ath.PhysicalTestType? type;

  @override
  ConsumerState<TestTypeDialog> createState() => _TestTypeDialogState();
}

class _TestTypeDialogState extends ConsumerState<TestTypeDialog> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.type?.code ?? '');
  late final _name = TextEditingController(text: widget.type?.name ?? '');
  late final _unit = TextEditingController(text: widget.type?.unit ?? '');
  late final _description = TextEditingController(text: widget.type?.description ?? '');
  late bool _higher = widget.type?.higherIsBetter ?? true;

  @override
  void dispose() {
    for (final c in [_code, _name, _unit, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final editing = widget.type;
    return FormDialog(
      title: editing == null ? l.testTypeNew : l.testTypeEdit,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => editing == null
            ? ref.read(testTypesProvider.notifier).create(
                code: _code.text.trim().toUpperCase(),
                name: _name.text.trim(),
                unit: _unit.text.trim(),
                higherIsBetter: _higher,
                description: _description.text.trim().isEmpty ? null : _description.text.trim(),
              )
            : ref.read(testTypesProvider.notifier).correct(
                editing.id,
                code: _code.text.trim().toUpperCase(),
                name: _name.text.trim(),
                unit: _unit.text.trim(),
                higherIsBetter: _higher,
                description: _description.text.trim().isEmpty ? null : _description.text.trim(),
              ),
        success: l.saved,
      ),
      children: [
        TextFormField(key: const Key('type-code'), controller: _code, decoration: InputDecoration(labelText: l.testTypeCode), validator: (v) => requiredValidator(l, v)),
        formGap,
        TextFormField(key: const Key('type-name'), controller: _name, decoration: InputDecoration(labelText: l.testTypeName), validator: (v) => requiredValidator(l, v)),
        formGap,
        TextFormField(key: const Key('type-unit'), controller: _unit, decoration: InputDecoration(labelText: l.testTypeUnit), validator: (v) => requiredValidator(l, v)),
        formGap,
        SwitchListTile(
          key: const Key('type-higher'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.testTypeHigher),
          value: _higher,
          onChanged: (v) => setState(() => _higher = v),
        ),
        TextFormField(key: const Key('type-description'), controller: _description, decoration: InputDecoration(labelText: l.injuryDescription)),
      ],
    );
  }
}

/// Reference norms: effective / global / academy layer, tenant override CRUD
/// for ADMIN, "reference pending" flag on rows without a cited source.
class NormsScreen extends ConsumerWidget {
  const NormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final filter = ref.watch(normFilterProvider);
    final types = ref.watch(testTypesProvider).value ?? const <ath.PhysicalTestType>[];
    final typeById = {for (final t in types) t.id: t};
    void setFilter(NormFilter f) => ref.read(normFilterProvider.notifier).set(f);
    return SubPage(
      title: l.normsTitle,
      parentPath: '/players',
      floatingActionButton: caps.canAdminFitness
          ? FloatingActionButton.extended(
              key: const Key('norm-new'),
              onPressed: () => showDialog<bool>(context: context, builder: (_) => const NormDialog()),
              icon: const Icon(Icons.add),
              label: Text(l.normNew),
            )
          : null,
      child: Guarded(
        allowed: caps.canSeeModule,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    key: const Key('norm-scope'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'EFFECTIVE', label: Text(l.normsScopeEffective)),
                      ButtonSegment(value: 'GLOBAL', label: Text(l.normsScopeGlobal)),
                      ButtonSegment(value: 'TENANT', label: Text(l.normsScopeTenant)),
                    ],
                    selected: {filter.scope},
                    onSelectionChanged: (s) => setFilter(NormFilter(scope: s.first, testTypeId: filter.testTypeId)),
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  DropdownButtonFormField<String?>(
                    key: const Key('norm-type-filter'),
                    initialValue: filter.testTypeId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.testType, isDense: true),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.normAllTests)),
                      for (final t in types) DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) => setFilter(NormFilter(scope: filter.scope, testTypeId: v)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncBody<List<ath.PhysicalTestNorm>>(
                value: ref.watch(normsProvider),
                onRetry: () => ref.invalidate(normsProvider),
                isEmpty: (d) => d.isEmpty,
                emptyMessage: l.normEmpty,
                builder: (context, data) => ListView(
                  padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, 0, AppTokens.spaceMd, 88),
                  children: [for (final n in data) NormTile(norm: n, typeName: typeById[n.testTypeId]?.name ?? '—', canEdit: caps.canAdminFitness && !n.global)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _v(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class NormTile extends ConsumerWidget {
  const NormTile({super.key, required this.norm, required this.typeName, required this.canEdit});
  final ath.PhysicalTestNorm norm;
  final String typeName;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = norm;
    final values = n.minValue != null && n.maxValue != null
        ? l.normValues(_v(n.minValue!), _v(n.maxValue!))
        : n.minValue != null
        ? l.normValuesFrom(_v(n.minValue!))
        : n.maxValue != null
        ? l.normValuesUpTo(_v(n.maxValue!))
        : '';
    return Card(
      child: ListTile(
        key: Key('norm-${n.id}'),
        isThreeLine: true,
        title: Text('$typeName · ${n.band.label(l)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${n.gender == ath.Gender.FEMALE ? l.genderFemale : l.genderMale} · ${l.normAges(n.maxAge, n.minAge)} · $values'),
            const SizedBox(height: AppTokens.spaceXs),
            Wrap(
              spacing: AppTokens.spaceXs,
              runSpacing: AppTokens.spaceXs,
              children: [
                InfoChip(n.global ? l.normGlobalReadOnly : l.normOverride),
                if (n.referencePending) InfoChip(l.testReferencePending, tone: ChipTone.warn, icon: Icons.hourglass_empty),
                if (n.source_ != null && !n.referencePending) InfoChip(n.source_!, icon: Icons.menu_book_outlined),
              ],
            ),
          ],
        ),
        onTap: canEdit ? () => showDialog<bool>(context: context, builder: (_) => NormDialog(norm: n)) : null,
        trailing: canEdit
            ? IconButton(
                key: Key('norm-delete-${n.id}'),
                tooltip: l.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await confirmDialog(context, message: l.normDeleteConfirm, confirmLabel: l.delete)) return;
                  if (!context.mounted) return;
                  await runAction(context, () => ref.read(normsProvider.notifier).delete(n.id));
                },
              )
            : null,
      ),
    );
  }
}

class NormDialog extends ConsumerStatefulWidget {
  const NormDialog({super.key, this.norm});
  final ath.PhysicalTestNorm? norm;

  @override
  ConsumerState<NormDialog> createState() => _NormDialogState();
}

class _NormDialogState extends ConsumerState<NormDialog> {
  final _form = GlobalKey<FormState>();
  late String? _typeId = widget.norm?.testTypeId;
  late ath.Gender _gender = widget.norm?.gender ?? ath.Gender.MALE;
  late ath.NormBand _band = widget.norm?.band ?? ath.NormBand.AVERAGE;
  late final _minAge = TextEditingController(text: widget.norm?.minAge.toString());
  late final _maxAge = TextEditingController(text: widget.norm?.maxAge.toString());
  late final _minValue = TextEditingController(text: widget.norm?.minValue?.toString());
  late final _maxValue = TextEditingController(text: widget.norm?.maxValue?.toString());
  late final _source = TextEditingController(text: widget.norm?.source_);
  bool _agesBad = false;

  @override
  void dispose() {
    for (final c in [_minAge, _maxAge, _minValue, _maxValue, _source]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _d(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _optional(AppLocalizations l, String? v) =>
      (v ?? '').trim().isEmpty || double.tryParse(v!.trim().replaceAll(',', '.')) != null ? null : l.fieldInvalidNumber;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final types = ref.watch(testTypesProvider).value ?? const <ath.PhysicalTestType>[];
    final editing = widget.norm != null;
    return FormDialog(
      title: editing ? l.normEdit : l.normNew,
      formKey: _form,
      validateExtra: () {
        final lo = int.tryParse(_minAge.text.trim()), hi = int.tryParse(_maxAge.text.trim());
        final bad = lo != null && hi != null && hi < lo;
        setState(() => _agesBad = bad);
        return !bad;
      },
      onSubmit: () => runAction(
        context,
        () => ref.read(normsProvider.notifier).save(
          ath.PhysicalTestNormInput((b) => b
            ..testTypeId = _typeId
            ..gender = _gender
            ..minAge = int.parse(_minAge.text.trim())
            ..maxAge = int.parse(_maxAge.text.trim())
            ..band = _band
            ..minValue = _d(_minValue)
            ..maxValue = _d(_maxValue)
            ..source_ = _source.text.trim().isEmpty ? null : _source.text.trim()),
          normId: widget.norm?.id,
        ),
        success: l.saved,
      ),
      children: [
        DropdownButtonFormField<String>(
          key: const Key('norm-type'),
          initialValue: _typeId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.testType),
          items: [for (final t in types) DropdownMenuItem(value: t.id, child: Text(t.name))],
          validator: (v) => v == null ? l.fieldRequired : null,
          onChanged: editing ? null : (v) => setState(() => _typeId = v),
        ),
        formGap,
        DropdownButtonFormField<ath.Gender>(
          key: const Key('norm-gender'),
          initialValue: _gender,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.normGender),
          items: [
            DropdownMenuItem(value: ath.Gender.MALE, child: Text(l.genderMale)),
            DropdownMenuItem(value: ath.Gender.FEMALE, child: Text(l.genderFemale)),
          ],
          onChanged: (v) => setState(() => _gender = v ?? _gender),
        ),
        formGap,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('norm-min-age'),
                controller: _minAge,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.normMinAge),
                validator: (v) => int.tryParse((v ?? '').trim()) == null ? l.fieldInvalidNumber : null,
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm),
            Expanded(
              child: TextFormField(
                key: const Key('norm-max-age'),
                controller: _maxAge,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.normMaxAge, errorText: _agesBad ? l.normAgesInvalid : null, errorMaxLines: 3),
                validator: (v) => int.tryParse((v ?? '').trim()) == null ? l.fieldInvalidNumber : null,
              ),
            ),
          ],
        ),
        formGap,
        DropdownButtonFormField<ath.NormBand>(
          key: const Key('norm-band-field'),
          initialValue: _band,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.normBand),
          items: [for (final b in normBands) DropdownMenuItem(value: b, child: Text(b.label(l)))],
          onChanged: (v) => setState(() => _band = v ?? _band),
        ),
        formGap,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('norm-min-value'),
                controller: _minValue,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.normMinValue),
                validator: (v) => _optional(l, v),
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm),
            Expanded(
              child: TextFormField(
                key: const Key('norm-max-value'),
                controller: _maxValue,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.normMaxValue),
                validator: (v) => _optional(l, v),
              ),
            ),
          ],
        ),
        formGap,
        TextFormField(key: const Key('norm-source'), controller: _source, decoration: InputDecoration(labelText: l.normSource)),
      ],
    );
  }
}
