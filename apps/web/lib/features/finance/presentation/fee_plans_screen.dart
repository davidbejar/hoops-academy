import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../training/application/training_providers.dart' show nowProvider;
import '../../tenant/application/tenant_providers.dart';
import '../application/finance_lookups.dart';
import '../application/finance_providers.dart';
import '../domain/money.dart';
import '../domain/periods.dart';
import 'finance_widgets.dart';
import 'generate_dues_dialog.dart';

/// The academy's fee plans: who is charged what, how often.
class FeePlansScreen extends ConsumerWidget {
  const FeePlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final plans = ref.watch(feePlansProvider);
    final settings = ref.watch(financeSettingsProvider);
    final lookups = ref.watch(financeLookupsProvider).value;
    final money = ref.watch(moneyFormatProvider);
    final online = financeOnline(ref);
    final needsCurrency = settings.hasValue && money == null;
    return SubPage(
      title: l.financePlansTitle,
      parentPath: '/admin/finance',
      floatingActionButton: needsCurrency || money == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('plan-new'),
              onPressed: online
                  ? () => showDialog<bool>(
                      context: context,
                      builder: (_) => const FeePlanDialog(),
                    )
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l.financePlanNew),
            ),
      child: FinanceBody(
        value: plans,
        needs: [settings, ref.watch(financeLookupsProvider)],
        onRetry: () {
          ref.invalidate(feePlansProvider);
          ref.invalidate(financeSettingsProvider);
          ref.invalidate(financeLookupsProvider);
        },
        builder: (context, data) => PageBody(
          header: PageHeader(title: l.financePlansTitle),
          children: [
            const FinanceOfflineNote(),
            if (needsCurrency)
              SectionCard(
                key: const Key('finance-no-currency'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: HoopsSpace.gap,
                  children: [
                    Text(l.financeNoCurrencyNotice),
                    FilledButton(
                      key: const Key('finance-no-currency-action'),
                      onPressed: () => context.go('/admin/finance/settings'),
                      child: Text(l.financeCurrencyChoose),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                key: const Key('plans-show-archived'),
                label: Text(l.financePlanShowArchived),
                selected: ref.watch(showArchivedPlansProvider),
                onSelected: (v) =>
                    ref.read(showArchivedPlansProvider.notifier).set(v),
              ),
            ),
            if (data.isEmpty && !needsCurrency)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l.financePlansEmpty,
              )
            else
              Column(
                spacing: HoopsSpace.gap,
                children: [
                  for (final plan in data)
                    _PlanRow(
                      plan: plan,
                      lookups: lookups,
                      money: money,
                      online: online,
                    ),
                  const SizedBox(height: HoopsSize.appBar),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends ConsumerWidget {
  const _PlanRow({
    required this.plan,
    required this.lookups,
    required this.money,
    required this.online,
  });

  final fin.FeePlan plan;
  final FinanceLookups? lookups;
  final MoneyFormat? money;
  final bool online;

  String _target(AppLocalizations l) {
    final team = lookups?.teamName(plan.teamId);
    if (plan.teamId != null) return l.financePlanForTeam(team ?? '?');
    final category = lookups?.categoryName(plan.ageCategoryId);
    return l.financePlanForCategory(category ?? '?');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final season = lookups?.seasonName(plan.seasonId);
    return ListRow(
      key: Key('plan-${plan.id}'),
      title: plan.name,
      subtitle: [_target(l), ?season].join(' · '),
      onTap: online
          ? () => showDialog<bool>(
              context: context,
              builder: (_) => FeePlanDialog(plan: plan),
            )
          : null,
      details: Wrap(
        spacing: HoopsSpace.sm,
        runSpacing: HoopsSpace.sm,
        children: [
          StatusChip(plan.cadence.label(l), tone: HoopsTone.info),
          if (plan.archived)
            StatusChip(l.financePlanArchived, tone: HoopsTone.neutral),
          if (plan.hasDues)
            StatusChip(l.financePlanHasDues, tone: HoopsTone.accent),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            money?.format(plan.amountMinor) ?? '${plan.amountMinor}',
            style: text.titleMedium,
          ),
          IconButton(
            key: Key('plan-menu-${plan.id}'),
            tooltip: l.moreActions,
            icon: const Icon(Icons.more_vert),
            onPressed: online ? () => _menu(context, ref) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final choice = await showActionSheet<String>(
      context,
      title: plan.name,
      actions: [
        SheetAction(
          icon: Icons.edit_outlined,
          label: l.financePlanEdit,
          value: 'edit',
        ),
        if (!plan.archived)
          SheetAction(
            icon: Icons.playlist_add_outlined,
            label: l.financePlanGenerate,
            value: 'generate',
          ),
        if (plan.archived)
          SheetAction(
            icon: Icons.unarchive_outlined,
            label: l.financePlanUnarchive,
            value: 'unarchive',
          )
        else
          SheetAction(
            icon: Icons.archive_outlined,
            label: l.financePlanArchive,
            value: 'archive',
          ),
        if (!plan.hasDues)
          SheetAction(
            icon: Icons.delete_outline,
            label: l.financePlanDelete,
            value: 'delete',
            destructive: true,
          ),
      ],
    );
    if (choice == null || !context.mounted) return;
    final notifier = ref.read(feePlansProvider.notifier);
    switch (choice) {
      case 'edit':
        await showDialog<bool>(
          context: context,
          builder: (_) => FeePlanDialog(plan: plan),
        );
      case 'generate':
        await showDialog<bool>(
          context: context,
          builder: (_) => GenerateDuesDialog(initialPlanId: plan.id),
        );
      case 'archive':
        if (!await confirmDialog(
              context,
              message: l.financePlanArchiveConfirm,
            ) ||
            !context.mounted) {
          return;
        }
        await runAction(
          context,
          () => notifier.setArchived(plan.id, true),
          success: l.financePlanArchivedMsg,
          errorText: financeErrorText,
        );
      case 'unarchive':
        await runAction(
          context,
          () => notifier.setArchived(plan.id, false),
          success: l.financePlanUnarchivedMsg,
          errorText: financeErrorText,
        );
      case 'delete':
        if (!await confirmDialog(
              context,
              message: l.financePlanDeleteConfirm,
            ) ||
            !context.mounted) {
          return;
        }
        await runAction(
          context,
          () => notifier.delete(plan.id),
          success: l.financePlanDeleted,
          errorText: financeErrorText,
        );
    }
  }
}

/// Create a fee plan, or change the name, amount, last period and automatic
/// generation of one (its season, target, cadence and, once it has dues, its
/// first period are fixed).
class FeePlanDialog extends ConsumerStatefulWidget {
  const FeePlanDialog({super.key, this.plan});

  final fin.FeePlan? plan;

  @override
  ConsumerState<FeePlanDialog> createState() => _FeePlanDialogState();
}

class _FeePlanDialogState extends ConsumerState<FeePlanDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name);
  late final _amount = TextEditingController();
  String? _seasonId;
  var _forTeam = true;
  String? _teamId;
  String? _categoryId;
  var _cadence = fin.FeeCadence.MONTHLY;
  String? _first;
  String? _last;
  var _auto = true;
  var _initialised = false;

  fin.FeePlan? get _plan => widget.plan;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Takes the plan's values, or the defaults of a new one, once the lookups
  /// and the money format are there.
  void _init(FinanceLookups lookups, MoneyFormat money) {
    if (_initialised) return;
    _initialised = true;
    final plan = _plan;
    if (plan != null) {
      _seasonId = plan.seasonId;
      _forTeam = plan.teamId != null;
      _teamId = plan.teamId;
      _categoryId = plan.ageCategoryId;
      _cadence = plan.cadence;
      _first = plan.firstPeriod;
      _last = plan.lastPeriod;
      _auto = plan.autoGenerate;
      _amount.text = money.inputText(plan.amountMinor);
    } else {
      _seasonId = lookups.defaultSeason?.id;
      _first = _suggestedFirst(lookups);
    }
  }

  List<String> _periods(FinanceLookups lookups) {
    final season = lookups.season(_seasonId);
    if (season == null) return const [];
    return periodKeysIn(
      _cadence,
      season.startsOn.toDateTime(),
      season.endsOn.toDateTime(),
    );
  }

  String? _suggestedFirst(FinanceLookups lookups) {
    if (_cadence == fin.FeeCadence.SEASON) return null;
    final today = ref.read(tenantZoneProvider).today(ref.read(nowProvider)());
    return suggestedPeriod(_periods(lookups), _cadence, today);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lookups = ref.watch(financeLookupsProvider).value;
    final money = ref.watch(moneyFormatProvider);
    if (lookups == null || money == null) {
      return const AlertDialog(
        content: SizedBox(
          height: HoopsSpace.xxxl,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    _init(lookups, money);
    final editing = _plan != null;
    final locale = localeOf(context);
    final periods = _periods(lookups);
    final firstFixed = editing && _plan!.hasDues;
    final teams = _seasonId == null
        ? const <api.Team>[]
        : lookups.teamsOfSeason(_seasonId!);
    return FormDialog(
      title: editing ? l.financePlanEdit : l.financePlanNew,
      formKey: _form,
      onSubmit: () => _submit(context, money, l),
      children: [
        TextFormField(
          key: const Key('plan-name'),
          controller: _name,
          maxLength: 80,
          decoration: InputDecoration(labelText: l.financePlanName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        if (editing) ...[
          _FixedInfo(plan: _plan!, lookups: lookups),
          formGap,
        ] else ...[
          if (lookups.seasons.isEmpty)
            Text(l.financeNoSeasons)
          else
            DropdownButtonFormField<String>(
              key: const Key('plan-season'),
              initialValue: _seasonId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.financePlanSeason),
              items: [
                for (final s in lookups.seasons.reversed)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() {
                _seasonId = v;
                _teamId = null;
                _first = _suggestedFirst(lookups);
                _last = null;
              }),
            ),
          formGap,
          DropdownButtonFormField<bool>(
            key: const Key('plan-target-kind'),
            initialValue: _forTeam,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.financePlanTargetKind),
            items: [
              DropdownMenuItem(
                value: true,
                child: Text(l.financePlanTargetTeam),
              ),
              DropdownMenuItem(
                value: false,
                child: Text(l.financePlanTargetCategory),
              ),
            ],
            onChanged: (v) => setState(() => _forTeam = v ?? true),
          ),
          formGap,
          if (_forTeam)
            KeyedSubtree(
              key: ValueKey('team-of-$_seasonId'),
              child: DropdownButtonFormField<String>(
                key: const Key('plan-team'),
                initialValue: _teamId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.financePlanTeam,
                  helperText: teams.isEmpty ? l.financeNoTeamsInSeason : null,
                ),
                items: [
                  for (final t in teams)
                    DropdownMenuItem<String>(value: t.id, child: Text(t.name)),
                ],
                validator: (v) => v == null ? l.fieldRequired : null,
                onChanged: (v) => _teamId = v,
              ),
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('plan-category'),
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.financePlanCategory),
              items: [
                for (final c in lookups.categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              validator: (v) => v == null ? l.fieldRequired : null,
              onChanged: (v) => _categoryId = v,
            ),
          formGap,
          DropdownButtonFormField<fin.FeeCadence>(
            key: const Key('plan-cadence'),
            initialValue: _cadence,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.financePlanCadence),
            items: [
              for (final c in const [
                fin.FeeCadence.MONTHLY,
                fin.FeeCadence.QUARTERLY,
                fin.FeeCadence.SEASON,
              ])
                DropdownMenuItem(value: c, child: Text(c.label(l))),
            ],
            onChanged: (v) => setState(() {
              _cadence = v ?? _cadence;
              _first = _suggestedFirst(lookups);
              _last = null;
            }),
          ),
          formGap,
        ],
        moneyField(
          key: const Key('plan-amount'),
          controller: _amount,
          money: money,
          l: l,
          label: l.financePlanAmount,
        ),
        if (editing) ...[
          const SizedBox(height: HoopsSpace.xs),
          Text(
            l.financePlanNewAmountNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_cadence != fin.FeeCadence.SEASON) ...[
          formGap,
          KeyedSubtree(
            key: ValueKey('first-$_cadence-$_seasonId'),
            child: DropdownButtonFormField<String>(
              key: const Key('plan-first'),
              initialValue: _first,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.financePlanFirstPeriod,
                helperText: firstFixed ? l.financePlanFirstPeriodFixed : null,
                helperMaxLines: 3,
              ),
              items: [
                for (final key in periods)
                  DropdownMenuItem(
                    value: key,
                    child: Text(periodLabel(key, l, locale)),
                  ),
              ],
              validator: (v) => v == null ? l.fieldRequired : null,
              onChanged: firstFixed
                  ? null
                  : (v) => setState(() {
                      _first = v;
                      final first = v == null ? null : Period.tryParse(v);
                      final last = _last == null
                          ? null
                          : Period.tryParse(_last!);
                      if (first != null &&
                          last != null &&
                          last.compareTo(first) < 0) {
                        _last = null;
                      }
                    }),
            ),
          ),
          formGap,
          KeyedSubtree(
            key: ValueKey('last-$_cadence-$_seasonId-$_first'),
            child: DropdownButtonFormField<String?>(
              key: const Key('plan-last'),
              initialValue: _last,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.financePlanLastPeriod),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.financePlanToSeasonEnd),
                ),
                for (final key in periods)
                  if (_first == null ||
                      Period.tryParse(key)!
                              .compareTo(Period.tryParse(_first!)!) >=
                          0)
                    DropdownMenuItem<String?>(
                      value: key,
                      child: Text(periodLabel(key, l, locale)),
                    ),
              ],
              onChanged: (v) => _last = v,
            ),
          ),
        ],
        formGap,
        SwitchListTile(
          key: const Key('plan-auto'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.financePlanAutoGenerate),
          subtitle: Text(l.financePlanAutoGenerateHint),
          value: _auto,
          onChanged: (v) => setState(() => _auto = v),
        ),
      ],
    );
  }

  Future<bool> _submit(
    BuildContext context,
    MoneyFormat money,
    AppLocalizations l,
  ) {
    final amount = money.parse(_amount.text)!;
    final notifier = ref.read(feePlansProvider.notifier);
    final plan = _plan;
    if (plan == null) {
      final request = fin.CreateFeePlanRequest(
        (b) => b
          ..name = _name.text.trim()
          ..seasonId = _seasonId
          ..teamId = _forTeam ? _teamId : null
          ..ageCategoryId = _forTeam ? null : _categoryId
          ..amountMinor = amount
          ..cadence = _cadence
          ..firstPeriod = _cadence == fin.FeeCadence.SEASON ? null : _first
          ..lastPeriod = _cadence == fin.FeeCadence.SEASON ? null : _last
          ..autoGenerate = _auto,
      );
      return runAction(
        context,
        () => notifier.create(request),
        success: l.financePlanSaved,
        errorText: financeErrorText,
      );
    }
    final name = _name.text.trim();
    final seasonCadence = plan.cadence == fin.FeeCadence.SEASON;
    final request = fin.UpdateFeePlanRequest((b) {
      if (name != plan.name) b.name = name;
      if (amount != plan.amountMinor) b.amountMinor = amount;
      if (!seasonCadence && !plan.hasDues && _first != plan.firstPeriod) {
        b.firstPeriod = _first;
      }
      if (!seasonCadence && _last != plan.lastPeriod) {
        if (_last == null) {
          b.clear = SetBuilder<fin.UpdateFeePlanRequestClearEnum>([
            fin.UpdateFeePlanRequestClearEnum.lastPeriod,
          ]);
        } else {
          b.lastPeriod = _last;
        }
      }
      if (_auto != plan.autoGenerate) b.autoGenerate = _auto;
    });
    final changed =
        request.name != null ||
        request.amountMinor != null ||
        request.firstPeriod != null ||
        request.lastPeriod != null ||
        request.clear != null ||
        request.autoGenerate != null;
    if (!changed) return Future.value(true);
    return runAction(
      context,
      () => notifier.edit(plan.id, request),
      success: l.financePlanSaved,
      errorText: financeErrorText,
    );
  }
}

/// What a plan is fixed to once created, in words.
class _FixedInfo extends StatelessWidget {
  const _FixedInfo({required this.plan, required this.lookups});

  final fin.FeePlan plan;
  final FinanceLookups lookups;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final target = plan.teamId != null
        ? l.financePlanForTeam(lookups.teamName(plan.teamId) ?? '?')
        : l.financePlanForCategory(
            lookups.categoryName(plan.ageCategoryId) ?? '?',
          );
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            target,
            ?lookups.seasonName(plan.seasonId),
            plan.cadence.label(l),
          ].join(' · '),
          key: const Key('plan-fixed-info'),
          style: text.titleSmall,
        ),
        const SizedBox(height: HoopsSpace.xs),
        Text(l.financePlanImmutableNote, style: text.bodySmall),
      ],
    );
  }
}
