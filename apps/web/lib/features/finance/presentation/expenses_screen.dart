import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/time/dates.dart';
import '../../../core/export/server_csv_export.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../training/application/training_providers.dart' show nowProvider;
import '../application/finance_providers.dart';
import '../domain/money.dart';
import 'finance_widgets.dart';

/// The academy's expenses: list with filters, record, correct, delete, and
/// the CSV of what the filters show (ADMIN, decision 99).
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final expenses = ref.watch(expensesProvider);
    final settings = ref.watch(financeSettingsProvider);
    final money = ref.watch(moneyFormatProvider);
    final query = ref.watch(expenseQueryProvider);
    final online = financeOnline(ref);
    final needsCurrency = settings.hasValue && money == null;
    return SubPage(
      title: l.financeExpensesTitle,
      parentPath: '/admin/finance',
      actions: [
        ServerCsvExportButton(
          key: const Key('expenses-export'),
          what: 'expenses',
          tooltip: l.financeExportExpensesTooltip,
          errorText: financeErrorText,
          fetch: (language) => ref
              .read(financeRepositoryProvider)
              .exportExpenses(
                ref.read(expenseQueryProvider),
                language: language,
              ),
        ),
      ],
      floatingActionButton: money == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('expense-new'),
              onPressed: online
                  ? () => showDialog<bool>(
                      context: context,
                      builder: (_) => ExpenseDialog(money: money),
                    )
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l.financeExpenseNew),
            ),
      child: PageBody(
        header: PageHeader(title: l.financeExpensesTitle),
        children: [
          const FinanceOfflineNote(),
          if (needsCurrency)
            NoCurrencyNotice(message: l.financeNoCurrencyExpenseNotice),
          const _Filters(),
          FinanceBody<fin.ExpensePage>(
            value: expenses,
            needs: [settings],
            onRetry: () {
              ref.invalidate(expensesProvider);
              ref.invalidate(financeSettingsProvider);
            },
            isEmpty: (page) => page.items.isEmpty,
            emptyMessage: query.hasFilter
                ? l.financeExpensesEmptyFiltered
                : l.financeExpensesEmpty,
            builder: (context, page) => _ExpenseList(page: page),
          ),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(expenseQueryProvider);
    final notifier = ref.read(expenseQueryProvider.notifier);
    final compact = WidthClass.of(context).isCompact;

    DateField day(String key, String label, fin.Date? value, bool isFrom) =>
        DateField(
          key: Key(key),
          label: label,
          value: value?.toDateTime(),
          onChanged: (d) {
            final date = toFinDate(d);
            isFrom ? notifier.filter(from: date) : notifier.filter(to: date);
          },
          onClear: () =>
              isFrom ? notifier.filter(from: null) : notifier.filter(to: null),
        );

    final category = DropdownButtonFormField<fin.ExpenseCategory?>(
      key: const Key('expenses-filter-category'),
      initialValue: query.category,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.financeFilterCategory),
      items: [
        DropdownMenuItem<fin.ExpenseCategory?>(value: null, child: Text(l.all)),
        for (final c in expenseCategories)
          DropdownMenuItem<fin.ExpenseCategory?>(
            value: c,
            child: Text(c.label(l)),
          ),
      ],
      onChanged: (v) => notifier.filter(category: v),
    );
    final from = day(
      'expenses-filter-from',
      l.financeFilterFrom,
      query.from,
      true,
    );
    final to = day('expenses-filter-to', l.financeFilterTo, query.to, false);
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: HoopsSpace.sm,
            children: [
              category,
              Row(
                spacing: HoopsSpace.sm,
                children: [
                  Expanded(child: from),
                  Expanded(child: to),
                ],
              ),
            ],
          )
        : Wrap(
            spacing: HoopsSpace.gap,
            runSpacing: HoopsSpace.gap,
            children: [
              for (final field in [category, from, to])
                SizedBox(width: 240, child: field),
            ],
          );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.page});

  final fin.ExpensePage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final locale = localeOf(context);
    final text = Theme.of(context).textTheme;
    final online = financeOnline(ref);
    final meta = page.page;
    final notifier = ref.read(expenseQueryProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HoopsSpace.gap,
      children: [
        Text(
          l.financeExpensesCount(meta.totalElements),
          key: const Key('expenses-count'),
          style: text.titleSmall,
        ),
        for (final e in page.items)
          ListRow(
            key: Key('expense-${e.id}'),
            title: e.description,
            subtitle:
                '${e.category.label(l)} · '
                '${displayDate(locale, e.spentOn.toDateTime())}',
            trailing: Text(
              money?.format(e.amountMinor) ?? '${e.amountMinor}',
              style: text.titleMedium,
            ),
            onTap: online && money != null
                ? () => _menu(context, ref, e, money)
                : null,
          ),
        Pager(
          keyPrefix: 'expenses',
          page: meta.page,
          totalPages: meta.totalPages,
          onPage: notifier.goToPage,
        ),
        const SizedBox(height: HoopsSize.appBar),
      ],
    );
  }

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    fin.Expense expense,
    MoneyFormat money,
  ) async {
    final l = AppLocalizations.of(context);
    final choice = await showActionSheet<String>(
      context,
      title: expense.description,
      actions: [
        SheetAction(
          icon: Icons.edit_outlined,
          label: l.financeExpenseEdit,
          value: 'edit',
        ),
        SheetAction(
          icon: Icons.delete_outline,
          label: l.financeExpenseDelete,
          value: 'delete',
          destructive: true,
        ),
      ],
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'edit') {
      await showDialog<bool>(
        context: context,
        builder: (_) => ExpenseDialog(money: money, expense: expense),
      );
      return;
    }
    if (!await confirmDialog(context, message: l.financeExpenseDeleteConfirm)) {
      return;
    }
    if (!context.mounted) return;
    await runAction(
      context,
      () => ref.read(expensesProvider.notifier).delete(expense.id),
      success: l.financeExpenseDeleted,
      errorText: financeErrorText,
    );
  }
}

/// Records an expense, or corrects one: only what changed is sent, and an
/// emptied note is cleared.
class ExpenseDialog extends ConsumerStatefulWidget {
  const ExpenseDialog({super.key, required this.money, this.expense});

  final MoneyFormat money;
  final fin.Expense? expense;

  @override
  ConsumerState<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends ConsumerState<ExpenseDialog> {
  final _form = GlobalKey<FormState>();
  late final DateTime _today = ref
      .read(tenantZoneProvider)
      .today(ref.read(nowProvider)());
  late DateTime _day = widget.expense?.spentOn.toDateTime() ?? _today;
  late fin.ExpenseCategory? _category = widget.expense?.category;
  late final _amount = TextEditingController(
    text: widget.expense == null
        ? null
        : widget.money.inputText(widget.expense!.amountMinor),
  );
  late final _description = TextEditingController(
    text: widget.expense?.description,
  );
  late final _note = TextEditingController(text: widget.expense?.note);

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  fin.Date get _spentOn => toFinDate(_day);

  Future<bool> _submit(AppLocalizations l) {
    final notifier = ref.read(expensesProvider.notifier);
    final original = widget.expense;
    final description = _description.text.trim();
    final note = _note.text.trim();
    final amount = widget.money.parse(_amount.text)!;
    return runAction(
      context,
      () async {
        if (original == null) {
          await notifier.create(
            fin.CreateExpenseRequest(
              (b) => b
                ..spentOn = _spentOn
                ..category = _category
                ..amountMinor = amount
                ..description = description
                ..note = blankToNull(note),
            ),
          );
          return;
        }
        final clearNote = note.isEmpty && original.note != null;
        final request = fin.UpdateExpenseRequest(
          (b) => b
            ..spentOn = _spentOn == original.spentOn ? null : _spentOn
            ..category = _category == original.category ? null : _category
            ..amountMinor = amount == original.amountMinor ? null : amount
            ..description = description == original.description
                ? null
                : description
            ..note = note.isEmpty || note == original.note ? null : note
            ..clear = clearNote
                ? SetBuilder<fin.UpdateExpenseRequestClearEnum>([
                    fin.UpdateExpenseRequestClearEnum.note,
                  ])
                : null,
        );
        if (_isEmpty(request)) return;
        await notifier.edit(original.id, request);
      },
      success: l.financeExpenseSaved,
      errorText: financeErrorText,
    );
  }

  static bool _isEmpty(fin.UpdateExpenseRequest r) =>
      r.spentOn == null &&
      r.category == null &&
      r.amountMinor == null &&
      r.description == null &&
      r.note == null &&
      r.clear == null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: widget.expense == null
          ? l.financeExpenseNew
          : l.financeExpenseEdit,
      formKey: _form,
      onSubmit: () => _submit(l),
      children: [
        DateField(
          key: const Key('expense-day'),
          label: l.financeExpenseDay,
          value: _day,
          firstDate: DateTime(_today.year - 3),
          lastDate: DateTime(_today.year + 1, 12, 31),
          onChanged: (d) => setState(() => _day = d),
        ),
        formGap,
        DropdownButtonFormField<fin.ExpenseCategory>(
          key: const Key('expense-category'),
          initialValue: _category,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.financeExpenseCategory),
          items: [
            for (final c in expenseCategories)
              DropdownMenuItem(value: c, child: Text(c.label(l))),
          ],
          validator: (v) => v == null ? l.fieldRequired : null,
          onChanged: (v) => _category = v,
        ),
        formGap,
        moneyField(
          key: const Key('expense-amount'),
          controller: _amount,
          money: widget.money,
          l: l,
          label: l.financeExpenseAmount,
        ),
        formGap,
        TextFormField(
          key: const Key('expense-description'),
          controller: _description,
          maxLength: 120,
          decoration: InputDecoration(labelText: l.financeExpenseDescription),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('expense-note'),
          controller: _note,
          maxLength: 200,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l.financeExpenseNote,
            helperText: l.financeExpenseHint,
            helperMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
