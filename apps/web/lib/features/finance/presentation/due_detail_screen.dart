import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/time/dates.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../training/application/training_providers.dart' show nowProvider;
import '../application/finance_providers.dart';
import '../domain/money.dart';
import 'finance_widgets.dart';

/// One due: what is owed and why, its payments (voided ones too) and what
/// ADMIN can do with it: record a payment, change the amount, waive it, void a
/// payment.
class DueDetailScreen extends ConsumerWidget {
  const DueDetailScreen({super.key, required this.dueId});

  final String dueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final due = ref.watch(dueDetailProvider(dueId));
    return SubPage(
      title: l.financeDueTitle,
      parentPath: '/admin/finance/dues',
      child: FinanceBody<fin.DueDetail>(
        value: due,
        needs: [ref.watch(financeSettingsProvider)],
        onRetry: () {
          ref.invalidate(dueDetailProvider(dueId));
          ref.invalidate(financeSettingsProvider);
        },
        builder: (context, due) => _DueDetail(due: due),
      ),
    );
  }
}

class _DueDetail extends ConsumerWidget {
  const _DueDetail({required this.due});

  final fin.DueDetail due;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final online = financeOnline(ref);
    final text = Theme.of(context).textTheme;
    final locale = localeOf(context);
    String show(int amountMinor) =>
        money?.format(amountMinor) ?? '$amountMinor';
    final open = due.status == fin.DueStatus.OPEN;
    return PageBody(
      key: const Key('due-detail'),
      header: PageHeader(
        title: due.playerName,
        subtitle: '${due.feePlanName} · ${periodLabel(due.period, l, locale)}',
      ),
      children: [
        const FinanceOfflineNote(),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: HoopsSpace.sm,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      show(due.amountMinor),
                      key: const Key('due-amount'),
                      style: text.headlineSmall,
                    ),
                  ),
                  DueStatusChip(due.status),
                ],
              ),
              if (due.amountMinor != due.planAmountMinor)
                Text(l.financeDuePlanAmount(show(due.planAmountMinor))),
              if (due.reason != null) Text(l.financeDueReason(due.reason!)),
              Text(
                '${due.periodStart} – ${due.periodEnd}',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        if (open)
          Wrap(
            spacing: HoopsSpace.sm,
            runSpacing: HoopsSpace.sm,
            children: [
              FilledButton.icon(
                key: const Key('due-pay'),
                onPressed: online && money != null
                    ? () => showDialog<bool>(
                        context: context,
                        builder: (_) => PayDueDialog(due: due, money: money),
                      )
                    : null,
                icon: const Icon(Icons.payments_outlined),
                label: Text(l.financeActionPay),
              ),
              OutlinedButton(
                key: const Key('due-change-amount'),
                onPressed: online && money != null
                    ? () => showDialog<bool>(
                        context: context,
                        builder: (_) =>
                            ChangeAmountDialog(due: due, money: money),
                      )
                    : null,
                child: Text(l.financeActionChangeAmount),
              ),
              OutlinedButton(
                key: const Key('due-waive'),
                onPressed: online
                    ? () => showDialog<bool>(
                        context: context,
                        builder: (_) => ReasonDialog(
                          title: l.financeWaiveTitle,
                          hint: l.financeWaiveHint,
                          submitLabel: l.financeActionWaive,
                          success: l.financeWaived,
                          action: (reason) => ref
                              .read(duesProvider.notifier)
                              .waive(due.id, reason),
                        ),
                      )
                    : null,
                child: Text(l.financeActionWaive),
              ),
            ],
          ),
        SectionCard(
          title: l.financeDuePayments,
          child: due.payments.isEmpty
              ? Text(l.financeDueNoPayments)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: HoopsSpace.gap,
                  children: [
                    for (final p in due.payments)
                      _PaymentTile(payment: p, show: show, online: online),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  const _PaymentTile({
    required this.payment,
    required this.show,
    required this.online,
  });

  final fin.Payment payment;
  final String Function(int) show;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = HoopsTokens.colorsOf(context);
    final voided = payment.voided;
    return Column(
      key: Key('payment-${payment.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.xs,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${payment.paidOn} · ${payment.method.label(l)}',
                style: text.titleSmall!.copyWith(
                  decoration: voided ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(show(payment.amountMinor), style: text.titleSmall),
          ],
        ),
        Text(
          l.financePaymentRecordedBy(payment.recordedBy.displayName),
          style: text.bodySmall!.copyWith(color: c.inkMuted),
        ),
        if (payment.note != null) Text(payment.note!, style: text.bodySmall),
        if (voided) ...[
          StatusChip(l.financePaymentVoidedLabel, tone: HoopsTone.danger),
          Text(
            l.financePaymentVoidedBy(
              payment.voidedBy?.displayName ?? '',
              payment.voidedAt == null
                  ? ''
                  : isoDate(
                      ref.watch(tenantZoneProvider).wall(payment.voidedAt!),
                    ),
            ),
            style: text.bodySmall,
          ),
          if (payment.voidReason != null)
            Text(
              l.financeDueReason(payment.voidReason!),
              style: text.bodySmall,
            ),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: Key('payment-void-${payment.id}'),
              onPressed: online
                  ? () => showDialog<bool>(
                      context: context,
                      builder: (_) => ReasonDialog(
                        title: l.financeVoidTitle,
                        hint: l.financeVoidHint,
                        submitLabel: l.financeActionVoid,
                        success: l.financeVoided,
                        action: (reason) => ref
                            .read(duesProvider.notifier)
                            .voidPayment(payment.id, reason),
                      ),
                    )
                  : null,
              child: Text(l.financeActionVoid),
            ),
          ),
      ],
    );
  }
}

/// A short reason (at most 200 characters, no health or family details), then
/// [action]: waiving a due, voiding a payment.
class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.submitLabel,
    required this.success,
    required this.action,
  });

  final String title;
  final String hint;
  final String submitLabel;
  final String success;
  final Future<void> Function(String reason) action;

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: widget.title,
      formKey: _form,
      submitLabel: widget.submitLabel,
      onSubmit: () => runAction(
        context,
        () => widget.action(_reason.text.trim()),
        success: widget.success,
        errorText: financeErrorText,
      ),
      children: [Text(widget.hint), formGap, _reasonField(_reason, l)],
    );
  }
}

TextFormField _reasonField(
  TextEditingController controller,
  AppLocalizations l,
) => TextFormField(
  key: const Key('reason-field'),
  controller: controller,
  maxLength: 200,
  maxLines: 3,
  decoration: InputDecoration(
    labelText: l.financeReasonLabel,
    helperText: l.financeReasonHint,
    helperMaxLines: 3,
  ),
  validator: (v) => requiredValidator(l, v),
);

/// Changes what an open due asks for; the plan's amount stays as it was.
class ChangeAmountDialog extends ConsumerStatefulWidget {
  const ChangeAmountDialog({super.key, required this.due, required this.money});

  final fin.DueDetail due;
  final MoneyFormat money;

  @override
  ConsumerState<ChangeAmountDialog> createState() => _ChangeAmountDialogState();
}

class _ChangeAmountDialogState extends ConsumerState<ChangeAmountDialog> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.money.inputText(widget.due.amountMinor),
  );
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.financeAmountDialogTitle,
      formKey: _form,
      submitLabel: l.financeActionChangeAmount,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(duesProvider.notifier)
            .changeAmount(
              widget.due.id,
              amountMinor: widget.money.parse(_amount.text)!,
              reason: _reason.text.trim(),
            ),
        success: l.financeAmountChanged,
        errorText: financeErrorText,
      ),
      children: [
        moneyField(
          key: const Key('amount-field'),
          controller: _amount,
          money: widget.money,
          l: l,
          label: l.financeDueAmount,
        ),
        formGap,
        _reasonField(_reason, l),
      ],
    );
  }
}

/// Records the payment of an open due: the whole amount, on a day not after
/// today (in the academy's zone), by a method.
class PayDueDialog extends ConsumerStatefulWidget {
  const PayDueDialog({super.key, required this.due, required this.money});

  final fin.DueDetail due;
  final MoneyFormat money;

  @override
  ConsumerState<PayDueDialog> createState() => _PayDueDialogState();
}

class _PayDueDialogState extends ConsumerState<PayDueDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  late final DateTime _today = ref
      .read(tenantZoneProvider)
      .today(ref.read(nowProvider)());
  late DateTime _paidOn = _today;
  var _method = fin.PaymentMethod.CASH;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.financePayTitle,
      formKey: _form,
      submitLabel: l.financeActionPay,
      onSubmit: () {
        final note = _note.text.trim();
        return runAction(
          context,
          () => ref
              .read(duesProvider.notifier)
              .pay(
                widget.due.id,
                paidOn: toFinDate(_paidOn),
                method: _method,
                note: blankToNull(note),
              ),
          success: l.financePayRecorded,
          errorText: financeErrorText,
        );
      },
      children: [
        Text(l.financePayFull(widget.money.format(widget.due.amountMinor))),
        formGap,
        DateField(
          key: const Key('pay-date'),
          label: l.financePayDate,
          value: _paidOn,
          firstDate: DateTime(_today.year - 2),
          lastDate: _today,
          onChanged: (d) => setState(() => _paidOn = d),
        ),
        formGap,
        DropdownButtonFormField<fin.PaymentMethod>(
          key: const Key('pay-method'),
          initialValue: _method,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.financePayMethod),
          items: [
            for (final m in paymentMethods)
              DropdownMenuItem(value: m, child: Text(m.label(l))),
          ],
          onChanged: (v) => _method = v ?? _method,
        ),
        formGap,
        TextFormField(
          key: const Key('pay-note'),
          controller: _note,
          maxLength: 200,
          decoration: InputDecoration(
            labelText: l.financePayNote,
            helperText: l.financeReasonHint,
            helperMaxLines: 3,
          ),
        ),
      ],
    );
  }
}
