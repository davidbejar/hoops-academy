import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/admin_providers.dart';

class AgeCategoriesScreen extends ConsumerWidget {
  const AgeCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories = ref.watch(ageCategoriesProvider);
    return SubPage(
      title: l.adminAgeCategories,
      parentPath: '/admin',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('category-new'),
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => const CategoryDialog(),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.categoryNew),
      ),
      child: AsyncBody<List<api.AgeCategory>>(
        value: categories,
        onRetry: () => ref.invalidate(ageCategoriesProvider),
        isEmpty: (d) => d.isEmpty,
        emptyMessage: l.categoriesEmpty,
        builder: (context, data) => PageBody(
          header: PageHeader(title: l.adminAgeCategories),
          children: [
            Column(
              spacing: HoopsSpace.gap,
              children: [
                for (final c in data)
                  ListRow(
                    key: Key('category-${c.id}'),
                    leading: InitialsAvatar(
                      name: c.rank.toString(),
                      tone: HoopsTone.neutral,
                    ),
                    title: '${c.code} · ${c.name}',
                    subtitle: c.maxAge == null
                        ? l.categoryNoLimit
                        : l.categoryUpTo(c.maxAge.toString()),
                    onTap: () => showDialog<bool>(
                      context: context,
                      builder: (_) => CategoryDialog(category: c),
                    ),
                    trailing: IconButton(
                      key: Key('category-delete-${c.id}'),
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (!await confirmDialog(
                          context,
                          message: l.categoryDeleteConfirm(c.name),
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
                        await runAction(
                          context,
                          () => ref
                              .read(ageCategoriesProvider.notifier)
                              .remove(c.id),
                        );
                      },
                    ),
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

class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({super.key, this.category});
  final api.AgeCategory? category;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.category?.code);
  late final _name = TextEditingController(text: widget.category?.name);
  late final _maxAge = TextEditingController(
    text: widget.category?.maxAge?.toString() ?? '',
  );
  late final _rank = TextEditingController(
    text: widget.category?.rank.toString() ?? '',
  );

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _maxAge.dispose();
    _rank.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: widget.category == null ? l.categoryNew : l.categoryEdit,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref
            .read(ageCategoriesProvider.notifier)
            .save(
              id: widget.category?.id,
              code: _code.text.trim(),
              name: _name.text.trim(),
              maxAge: _maxAge.text.trim().isEmpty
                  ? null
                  : int.parse(_maxAge.text.trim()),
              rank: int.parse(_rank.text.trim()),
            ),
        success: l.saved,
      ),
      children: [
        TextFormField(
          key: const Key('category-code'),
          controller: _code,
          decoration: InputDecoration(labelText: l.categoryCode),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('category-name'),
          controller: _name,
          decoration: InputDecoration(labelText: l.categoryName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('category-max-age'),
          controller: _maxAge,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.categoryMaxAge),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return null;
            final n = int.tryParse(t);
            return n == null || n < 1 || n > 99 ? l.fieldInvalidNumber : null;
          },
        ),
        formGap,
        TextFormField(
          key: const Key('category-rank'),
          controller: _rank,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.categoryRank),
          validator: (v) => int.tryParse((v ?? '').trim()) == null
              ? l.fieldInvalidNumber
              : null,
        ),
      ],
    );
  }
}
