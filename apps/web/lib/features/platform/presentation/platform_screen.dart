import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_labels.dart';

class TenantStatusChip extends StatelessWidget {
  const TenantStatusChip(this.status, {super.key});
  final api.TenantStatus status;

  @override
  Widget build(BuildContext context) => InfoChip(
    status.label(AppLocalizations.of(context)),
    tone: status.tone,
    icon: switch (status) {
      api.TenantStatus.ACTIVE => Icons.check_circle_outline,
      api.TenantStatus.SUSPENDED => Icons.pause_circle_outline,
      _ => Icons.block,
    },
  );
}

/// Tenants of the platform (super_admin).
class PlatformScreen extends ConsumerWidget {
  const PlatformScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(tenantFilterProvider);
    void setFilter(TenantFilter f) => ref.read(tenantFilterProvider.notifier).set(f);
    return Guarded(
      allowed: ref.watch(isSuperAdminProvider),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('tenant-new'),
          onPressed: () => showDialog<bool>(context: context, builder: (_) => const CreateTenantDialog()),
          icon: const Icon(Icons.add),
          label: Text(l.platformNew),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceMd),
                  child: TextField(
                    key: const Key('tenant-search'),
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.platformSearchHint, isDense: true),
                    onSubmitted: (v) => setFilter(TenantFilter(status: filter.status, query: v)),
                    onChanged: (v) {
                      if (v.isEmpty && filter.query.isNotEmpty) setFilter(TenantFilter(status: filter.status));
                    },
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
                  child: Row(
                    children: [
                      ChoiceChip(
                        key: const Key('status-all'),
                        label: Text(l.all),
                        selected: filter.status == null,
                        onSelected: (_) => setFilter(TenantFilter(query: filter.query)),
                      ),
                      for (final s in [api.TenantStatus.ACTIVE, api.TenantStatus.SUSPENDED, api.TenantStatus.WITHDRAWN])
                        Padding(
                          padding: const EdgeInsets.only(left: AppTokens.spaceSm),
                          child: ChoiceChip(
                            key: Key('status-${s.name}'),
                            label: Text(s.label(l)),
                            selected: filter.status == s,
                            onSelected: (_) => setFilter(TenantFilter(status: s, query: filter.query)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: AsyncBody<List<api.Tenant>>(
                    value: ref.watch(tenantsProvider),
                    onRetry: () => ref.invalidate(tenantsProvider),
                    isEmpty: (d) => d.isEmpty,
                    emptyMessage: l.platformEmpty,
                    builder: (context, data) => ListView(
                      padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceMd, 88),
                      children: [
                        for (final t in data)
                          Card(
                            child: ListTile(
                              key: Key('tenant-${t.id}'),
                              title: Text(t.name),
                              subtitle: Text(t.slug),
                              trailing: TenantStatusChip(t.status),
                              onTap: () => context.go('/platform/${t.id}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _slugPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class CreateTenantDialog extends ConsumerStatefulWidget {
  const CreateTenantDialog({super.key});

  @override
  ConsumerState<CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends ConsumerState<CreateTenantDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _timezone = TextEditingController(text: 'Europe/Madrid');
  final _email = TextEditingController();
  final _given = TextEditingController();
  final _family = TextEditingController();
  api.ApiLocale _locale = api.ApiLocale.es;

  @override
  void dispose() {
    for (final c in [_name, _slug, _timezone, _email, _given, _family]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget field(String key, TextEditingController c, String label, {String? Function(String?)? validator, TextInputType? type}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            key: Key(key),
            controller: c,
            keyboardType: type,
            decoration: InputDecoration(labelText: label),
            validator: validator ?? (v) => requiredValidator(l, v),
          ),
        );
    return FormDialog(
      title: l.platformNew,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => ref.read(tenantsProvider.notifier).create(
          name: _name.text.trim(),
          slug: _slug.text.trim(),
          timezone: _timezone.text.trim(),
          locale: _locale,
          adminEmail: _email.text.trim(),
          adminGivenName: _given.text.trim(),
          adminFamilyName: _family.text.trim(),
        ),
        success: l.tenantCreated,
      ),
      children: [
        field('tenant-name', _name, l.tenantName),
        field('tenant-slug', _slug, l.tenantSlug, validator: (v) => _slugPattern.hasMatch((v ?? '').trim()) ? null : l.tenantSlugInvalid),
        field('tenant-timezone', _timezone, l.tenantTimezone),
        DropdownButtonFormField<api.ApiLocale>(
          key: const Key('tenant-locale'),
          initialValue: _locale,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.tenantLocale),
          items: [
            DropdownMenuItem(value: api.ApiLocale.es, child: Text(l.languageName_es)),
            DropdownMenuItem(value: api.ApiLocale.en, child: Text(l.languageName_en)),
            DropdownMenuItem(value: api.ApiLocale.id, child: Text(l.languageName_id)),
          ],
          onChanged: (v) => setState(() => _locale = v ?? _locale),
        ),
        formGap,
        field(
          'tenant-admin-email',
          _email,
          l.tenantAdminEmail,
          type: TextInputType.emailAddress,
          validator: (v) => _emailPattern.hasMatch((v ?? '').trim()) ? null : l.fieldInvalidEmail,
        ),
        field('tenant-admin-given', _given, l.tenantAdminGivenName),
        field('tenant-admin-family', _family, l.tenantAdminFamilyName),
      ],
    );
  }
}
