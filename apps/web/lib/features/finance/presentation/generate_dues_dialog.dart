import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../training/application/training_providers.dart' show nowProvider;
import '../application/finance_lookups.dart';
import '../application/finance_providers.dart';
import '../domain/periods.dart';
import 'finance_widgets.dart';

/// Creates the missing dues of one period of a plan, after showing how many
/// that would be (decision 98: by hand, with a preview).
class GenerateDuesDialog extends ConsumerStatefulWidget {
  const GenerateDuesDialog({super.key, this.initialPlanId});

  final String? initialPlanId;

  @override
  ConsumerState<GenerateDuesDialog> createState() => _GenerateDuesDialogState();
}

class _GenerateDuesDialogState extends ConsumerState<GenerateDuesDialog> {
  final _form = GlobalKey<FormState>();
  String? _planId;
  String? _period;
  fin.DueGeneration? _preview;
  var _initialised = false;

  /// The periods the plan charges, from its first to its last (or the end of
  /// its season).
  List<String> _periods(fin.FeePlan plan, FinanceLookups lookups) {
    final season = lookups.season(plan.seasonId);
    if (season == null) return const [];
    return planPeriodKeys(
      cadence: plan.cadence,
      firstPeriod: plan.firstPeriod,
      lastPeriod: plan.lastPeriod,
      seasonStart: season.startsOn.toDateTime(),
      seasonEnd: season.endsOn.toDateTime(),
    );
  }

  String? _suggested(fin.FeePlan plan, FinanceLookups lookups) {
    final today = ref.read(tenantZoneProvider).today(ref.read(nowProvider)());
    return suggestedPeriod(_periods(plan, lookups), plan.cadence, today);
  }

  void _choosePlan(String? id, List<fin.FeePlan> plans, FinanceLookups l) {
    _planId = id;
    final plan = plans.where((p) => p.id == id).firstOrNull;
    _period = plan == null ? null : _suggested(plan, l);
    _preview = null;
  }

  Future<void> _calculate(BuildContext context) async {
    final planId = _planId!;
    final period = _period!;
    final ok = await runAction(context, () async {
      final preview = await ref
          .read(duesProvider.notifier)
          .previewGeneration(planId, period);
      if (!mounted) return;
      setState(() => _preview = preview);
    }, errorText: financeErrorText);
    if (!ok && mounted) setState(() => _preview = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final plans = ref.watch(feePlansProvider).value;
    final lookups = ref.watch(financeLookupsProvider).value;
    if (plans == null || lookups == null) {
      return const AlertDialog(
        content: SizedBox(
          height: HoopsSpace.xxxl,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final active = [
      for (final p in plans)
        if (!p.archived) p,
    ];
    if (active.isEmpty) {
      return AlertDialog(
        title: Text(l.financeGenerateTitle),
        content: Text(l.financeGenerateNoPlans, key: const Key('gen-no-plans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.close),
          ),
        ],
      );
    }
    if (!_initialised) {
      _initialised = true;
      _choosePlan(
        active.any((p) => p.id == widget.initialPlanId)
            ? widget.initialPlanId
            : active.first.id,
        active,
        lookups,
      );
    }
    final plan = active.firstWhere((p) => p.id == _planId);
    final periods = _periods(plan, lookups);
    final locale = localeOf(context);
    final preview = _preview;
    final current =
        preview != null &&
        preview.feePlanId == _planId &&
        preview.period == _period;
    return FormDialog(
      title: l.financeGenerateTitle,
      formKey: _form,
      submitLabel: l.financeGenerate,
      canSubmit: current && preview.created > 0,
      onSubmit: () {
        final notifier = ref.read(duesProvider.notifier);
        var created = 0;
        return runAction(context, () async {
          created = (await notifier.generate(plan.id, _period!)).created;
        }, errorText: financeErrorText).then((ok) {
          if (ok && context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(l.financeGenerated(created))),
            );
          }
          return ok;
        });
      },
      children: [
        Text(l.financeGenerateIntro),
        formGap,
        DropdownButtonFormField<String>(
          key: const Key('gen-plan'),
          initialValue: _planId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.financeGeneratePlan),
          items: [
            for (final p in active)
              DropdownMenuItem(value: p.id, child: Text(p.name)),
          ],
          onChanged: (v) => setState(() => _choosePlan(v, active, lookups)),
        ),
        formGap,
        KeyedSubtree(
          key: ValueKey('period-of-$_planId'),
          child: DropdownButtonFormField<String>(
            key: const Key('gen-period'),
            initialValue: _period,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.financeGeneratePeriod),
            items: [
              for (final key in periods)
                DropdownMenuItem(
                  value: key,
                  child: Text(periodLabel(key, l, locale)),
                ),
            ],
            onChanged: (v) => setState(() {
              _period = v;
              _preview = null;
            }),
          ),
        ),
        formGap,
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('gen-preview'),
            onPressed: _period == null ? null : () => _calculate(context),
            child: Text(l.financeGeneratePreview),
          ),
        ),
        if (current) ...[
          formGap,
          Text(
            l.financeGeneratePreviewResult(preview.created, preview.existing),
            key: const Key('gen-preview-result'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ],
    );
  }
}
