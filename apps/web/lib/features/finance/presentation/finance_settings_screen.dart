import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_providers.dart';
import '../domain/currencies.dart';
import 'finance_widgets.dart';

/// The academy's currency: one for everything, chosen by ADMIN and fixed once
/// the first due exists (ADR-0056).
class FinanceSettingsScreen extends ConsumerWidget {
  const FinanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(financeSettingsProvider);
    final online = financeOnline(ref);
    return SubPage(
      title: l.financeSettingsTitle,
      parentPath: '/admin/finance',
      child: FinanceBody(
        value: settings,
        onRetry: () => ref.invalidate(financeSettingsProvider),
        builder: (context, data) {
          final locked = data.currencyLocked;
          final text = Theme.of(context).textTheme;
          return PageBody(
            header: PageHeader(title: l.financeSettingsTitle),
            children: [
              const FinanceOfflineNote(),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: HoopsSpace.gap,
                  children: [
                    Row(
                      spacing: HoopsSpace.sm,
                      children: [
                        Expanded(
                          child: Text(
                            data.currency ?? l.financeCurrencyNotSet,
                            key: const Key('currency-current'),
                            style: text.headlineSmall,
                          ),
                        ),
                        if (locked)
                          StatusChip(
                            l.financeCurrencyLockedChip,
                            tone: HoopsTone.neutral,
                            icon: Icons.lock_outline,
                          ),
                      ],
                    ),
                    Text(l.financeCurrencyHint, style: text.bodyMedium),
                    if (locked)
                      Text(
                        l.financeCurrencyLockedNote,
                        key: const Key('currency-locked'),
                        style: text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        key: const Key('currency-choose'),
                        onPressed: locked || !online
                            ? null
                            : () => _choose(context, ref),
                        child: Text(
                          data.currency == null
                              ? l.financeCurrencyChoose
                              : l.financeCurrencyChange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const CurrencyPickerDialog(),
    );
    if (code == null || !context.mounted) return;
    final sure = await confirmDialog(
      context,
      message: l.financeCurrencyConfirm(code),
    );
    if (!sure || !context.mounted) return;
    await runAction(
      context,
      () => ref.read(financeSettingsProvider.notifier).chooseCurrency(code),
      success: l.financeCurrencySaved,
      errorText: financeErrorText,
    );
  }
}

/// Picks one of the currencies the service accepts, found by code.
class CurrencyPickerDialog extends StatefulWidget {
  const CurrencyPickerDialog({super.key});

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = localeOf(context);
    final codes = [
      for (final code in financeCurrencies.keys)
        if (code.contains(_query.trim().toUpperCase())) code,
    ];
    return PickerDialog<String>(
      title: l.financeCurrencyPickerTitle,
      future: SynchronousFuture(codes),
      emptyText: l.noResults,
      height: 420,
      header: Padding(
        padding: const EdgeInsets.only(bottom: HoopsSpace.sm),
        child: TextField(
          key: const Key('currency-search'),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l.financeCurrencySearch,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      itemBuilder: (context, code) => ListTile(
        key: Key('currency-$code'),
        title: Text(code),
        trailing: Text(
          NumberFormat.simpleCurrency(
            locale: locale,
            name: code,
          ).currencySymbol,
        ),
        onTap: () => Navigator.of(context).pop(code),
      ),
    );
  }
}
