import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_providers.dart';
import '../domain/money.dart';
import '../domain/periods.dart';

/// Whether the device is online; finance is read-only without a connection
/// (nothing is queued).
bool financeOnline(WidgetRef ref) => ref.watch(onlineProvider).value ?? true;

/// "Offline: you can read the finances but not change them", shown at the top
/// of every finance screen that has writes.
class FinanceOfflineNote extends ConsumerWidget {
  const FinanceOfflineNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (financeOnline(ref)) return const SizedBox.shrink();
    return NoticeBanner(
      key: const Key('finance-offline'),
      tone: HoopsTone.warning,
      icon: Icons.cloud_off,
      message: AppLocalizations.of(context).financeOfflineReadOnly,
    );
  }
}

/// Like [AsyncBody], except that an operation the service does not answer yet
/// (501) gets its own clear message instead of the generic failure.
///
/// [needs] are other reads the screen cannot be drawn without (the academy's
/// currency, the names of teams): until they are there the screen loads, so
/// amounts never flash as bare numbers.
class FinanceBody<T> extends StatelessWidget {
  const FinanceBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.needs = const [],
    this.isEmpty,
    this.emptyMessage,
    this.emptyAction,
  });

  final AsyncValue<T> value;
  final List<AsyncValue<Object?>> needs;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) {
    if (value.value == null && value.hasError && isNotYetServed(value.error!)) {
      return NotYetServed(onRetry: onRetry);
    }
    if (value.value != null) {
      for (final need in needs) {
        if (need.hasValue) continue;
        if (need.hasError) {
          return AppErrorView(
            error: AppError.of(need.error!),
            onRetry: onRetry,
          );
        }
        return const LoadingView();
      }
    }
    return AsyncBody<T>(
      value: value,
      builder: builder,
      onRetry: onRetry,
      isEmpty: isEmpty,
      emptyMessage: emptyMessage,
      emptyAction: emptyAction,
    );
  }
}

/// "Choose the academy's currency first", with the way to the settings; shown
/// where an amount is needed (plans, expenses) and no currency exists yet.
class NoCurrencyNotice extends StatelessWidget {
  const NoCurrencyNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      key: const Key('finance-no-currency'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.gap,
        children: [
          Text(message),
          FilledButton(
            key: const Key('finance-no-currency-action'),
            onPressed: () => context.go('/admin/finance/settings'),
            child: Text(l.financeCurrencyChoose),
          ),
        ],
      ),
    );
  }
}

/// The service does not serve this part yet.
class NotYetServed extends StatelessWidget {
  const NotYetServed({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      key: const Key('finance-not-yet'),
      icon: Icons.construction_outlined,
      tone: HoopsTone.info,
      title: l.financeNotYetAvailable,
      action: onRetry == null
          ? null
          : FilledButton(
              key: const Key('retry-button'),
              onPressed: onRetry,
              child: Text(l.retry),
            ),
    );
  }
}

/// The message for a failed finance call: the service's business codes in the
/// user's words, 501 as "not available yet", anything else the generic text.
String financeErrorText(Object error, AppLocalizations l) {
  final e = AppError.of(error);
  if (e.status == 501) return l.financeNotYetAvailable;
  return switch (e.code) {
    'DUE_NOT_OPEN' => l.financeErrorDueNotOpen,
    'CURRENCY_LOCKED' => l.financeErrorCurrencyLocked,
    'UNKNOWN_CURRENCY' => l.financeErrorUnknownCurrency,
    'CURRENCY_NOT_SET' => l.financeErrorCurrencyNotSet,
    'FEE_PLAN_HAS_DUES' => l.financeErrorFeePlanHasDues,
    'FEE_PLAN_ARCHIVED' => l.financeErrorFeePlanArchived,
    'PAID_ON_IN_FUTURE' => l.financeErrorPaidOnInFuture,
    'PAYMENT_ALREADY_VOIDED' => l.financeErrorPaymentAlreadyVoided,
    'PERIOD_OUTSIDE_PLAN' => l.financeErrorPeriodOutsidePlan,
    'PERIOD_OUTSIDE_SEASON' => l.financeErrorPeriodOutsideSeason,
    'TOO_MANY_DUES' => l.financeErrorTooManyDues,
    'TEAM_NOT_IN_SEASON' => l.financeErrorTeamNotInSeason,
    'CONCURRENT_MODIFICATION' => l.financeErrorConcurrentModification,
    _ => e.message(l),
  };
}

/// The fixed expense categories (decision 99), in the contract's order and
/// without the generator's fallback value.
const expenseCategories = [
  fin.ExpenseCategory.COURT_RENTAL,
  fin.ExpenseCategory.SALARIES,
  fin.ExpenseCategory.KIT,
  fin.ExpenseCategory.TOURNAMENT_FEES,
  fin.ExpenseCategory.TRAVEL,
  fin.ExpenseCategory.OTHER,
];

extension ExpenseCategoryLabel on fin.ExpenseCategory {
  String label(AppLocalizations l) {
    if (this == fin.ExpenseCategory.COURT_RENTAL) {
      return l.financeCategoryCourtRental;
    }
    if (this == fin.ExpenseCategory.SALARIES) return l.financeCategorySalaries;
    if (this == fin.ExpenseCategory.KIT) return l.financeCategoryKit;
    if (this == fin.ExpenseCategory.TOURNAMENT_FEES) {
      return l.financeCategoryTournamentFees;
    }
    if (this == fin.ExpenseCategory.TRAVEL) return l.financeCategoryTravel;
    return l.financeCategoryOther;
  }
}

extension FeeCadenceLabel on fin.FeeCadence {
  String label(AppLocalizations l) {
    if (this == fin.FeeCadence.MONTHLY) return l.financeCadenceMonthly;
    if (this == fin.FeeCadence.QUARTERLY) return l.financeCadenceQuarterly;
    return l.financeCadenceSeason;
  }
}

extension DueStatusLabel on fin.DueStatus {
  String label(AppLocalizations l) {
    if (this == fin.DueStatus.PAID) return l.financeStatusPaid;
    if (this == fin.DueStatus.WAIVED) return l.financeStatusWaived;
    return l.financeStatusOpen;
  }

  HoopsTone get tone {
    if (this == fin.DueStatus.PAID) return HoopsTone.success;
    if (this == fin.DueStatus.WAIVED) return HoopsTone.neutral;
    return HoopsTone.warning;
  }
}

extension PaymentMethodLabel on fin.PaymentMethod {
  String label(AppLocalizations l) {
    if (this == fin.PaymentMethod.CASH) return l.financeMethodCash;
    if (this == fin.PaymentMethod.BANK_TRANSFER) {
      return l.financeMethodBankTransfer;
    }
    if (this == fin.PaymentMethod.CARD) return l.financeMethodCard;
    return l.financeMethodOther;
  }
}

/// The payment methods an ADMIN can record (without the generator's fallback).
const paymentMethods = [
  fin.PaymentMethod.CASH,
  fin.PaymentMethod.BANK_TRANSFER,
  fin.PaymentMethod.CARD,
  fin.PaymentMethod.OTHER,
];

class DueStatusChip extends StatelessWidget {
  const DueStatusChip(this.status, {super.key});

  final fin.DueStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusChip(status.label(AppLocalizations.of(context)), tone: status.tone);
}

/// A period key in words: `septiembre de 2026`, `T3 2026`, `Temporada completa`.
String periodLabel(String key, AppLocalizations l, String locale) {
  final period = Period.tryParse(key);
  if (period == null) return key;
  return switch (period.kind) {
    PeriodKind.month => DateFormat.yMMMM(locale).format(period.start),
    PeriodKind.quarter => l.financePeriodQuarter(period.number, period.year),
    PeriodKind.season => l.financePeriodSeason,
  };
}

String localeOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// A field for an amount of the academy's currency: shows the number as the
/// locale writes it and reads it back with [MoneyFormat.parse].
TextFormField moneyField({
  required Key key,
  required TextEditingController controller,
  required MoneyFormat money,
  required AppLocalizations l,
  required String label,
}) => TextFormField(
  key: key,
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: InputDecoration(labelText: label, suffixText: money.currency),
  validator: (v) {
    if (money.parse(v ?? '') != null) return null;
    return (v ?? '').trim().isEmpty
        ? l.fieldRequired
        : l.financeAmountInvalid(money.example);
  },
);
