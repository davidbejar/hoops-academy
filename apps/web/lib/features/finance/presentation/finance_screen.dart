import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_providers.dart';
import 'finance_widgets.dart';

/// The finance area's hub: the academy's currency, the fee plans and the dues.
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(financeSettingsProvider);
    return SubPage(
      title: l.financeTitle,
      parentPath: '/admin',
      child: FinanceBody(
        value: settings,
        onRetry: () => ref.invalidate(financeSettingsProvider),
        builder: (context, data) {
          final entries = [
            (
              Icons.currency_exchange_outlined,
              l.financeSettingsTitle,
              data.currency ?? l.financeCurrencyNotSet,
              '/admin/finance/settings',
              'finance-settings',
            ),
            (
              Icons.receipt_long_outlined,
              l.financePlansTitle,
              null,
              '/admin/finance/plans',
              'finance-plans',
            ),
            (
              Icons.price_check_outlined,
              l.financeDuesTitle,
              null,
              '/admin/finance/dues',
              'finance-dues',
            ),
            (
              Icons.shopping_bag_outlined,
              l.financeExpensesTitle,
              null,
              '/admin/finance/expenses',
              'finance-expenses',
            ),
            (
              Icons.balance_outlined,
              l.financeBalanceTitle,
              null,
              '/admin/finance/balance',
              'finance-balance',
            ),
          ];
          return PageBody(
            key: const Key('finance-hub'),
            header: PageHeader(title: l.financeTitle),
            children: [
              Column(
                spacing: HoopsSpace.gap,
                children: [
                  for (final (icon, title, subtitle, path, key) in entries)
                    ListRow(
                      key: Key(key),
                      leading: IconTile(icon),
                      title: title,
                      subtitle: subtitle,
                      onTap: () => context.go(path),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
