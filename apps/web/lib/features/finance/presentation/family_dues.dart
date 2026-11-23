import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/time/dates.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_providers.dart';
import '../domain/currencies.dart';
import '../domain/money.dart';
import 'finance_widgets.dart';

/// The dues of one player as the family sees them: each period with its
/// state and, when paid, the day and the method. No reasons, notes or voided
/// payments (the service leaves them out). The family cannot read the
/// academy's settings, so the amount is formatted from the due's own currency.
class FamilyDues extends ConsumerWidget {
  const FamilyDues({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return FinanceBody<List<fin.PlayerDue>>(
      value: ref.watch(playerDuesProvider(playerId)),
      onRetry: () => ref.invalidate(playerDuesProvider(playerId)),
      isEmpty: (dues) => dues.isEmpty,
      emptyMessage: l.financeFamilyEmpty,
      builder: (context, dues) => Column(
        key: Key('family-dues-$playerId'),
        spacing: HoopsSpace.gap,
        children: [for (final due in dues) _FamilyDueRow(due: due)],
      ),
    );
  }
}

class _FamilyDueRow extends StatelessWidget {
  const _FamilyDueRow({required this.due});

  final fin.PlayerDue due;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = localeOf(context);
    final text = Theme.of(context).textTheme;
    final money = MoneyFormat(
      currency: due.currency,
      minorDigits: financeCurrencies[due.currency] ?? 2,
      locale: Localizations.localeOf(context).languageCode,
    );
    final paidOn = due.paidOn;
    final method = due.paymentMethod;
    return ListRow(
      key: Key('family-due-${due.id}'),
      title: due.feePlanName,
      subtitle: periodLabel(due.period, l, locale),
      details: Wrap(
        spacing: HoopsSpace.sm,
        runSpacing: HoopsSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DueStatusChip(due.status),
          if (due.status == fin.DueStatus.PAID &&
              paidOn != null &&
              method != null)
            Text(
              l.financeFamilyPaidOn(
                displayDate(locale, paidOn.toDateTime()),
                method.label(l),
              ),
              style: text.bodySmall,
            ),
        ],
      ),
      trailing: Text(money.format(due.amountMinor), style: text.titleMedium),
    );
  }
}
