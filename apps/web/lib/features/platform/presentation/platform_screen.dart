import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/temporary_password_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_labels.dart';
import 'platform_validators.dart';

class TenantStatusChip extends StatelessWidget {
  const TenantStatusChip(this.status, {super.key});
  final api.TenantStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
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
    void setFilter(TenantFilter f) =>
        ref.read(tenantFilterProvider.notifier).set(f);
    return Guarded(
      allowed: ref.watch(isSuperAdminProvider),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('tenant-new'),
          onPressed: () => showDialog<bool>(
            context: context,
            builder: (_) => const CreateTenantDialog(),
          ),
          icon: const Icon(Icons.add),
          label: Text(l.platformNew),
        ),
        body: Column(
          children: [
            ContentFrame(
              maxWidth: WidthClass.readingMax,
              child: Padding(
                padding: const EdgeInsets.only(top: HoopsSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: HoopsSpace.gap,
                  children: [
                    PageHeader(
                      title: l.platformTitle,
                      actions: [
                        OutlinedButton.icon(
                          key: const Key('platform-requests'),
                          icon: const Icon(Icons.mark_email_unread_outlined),
                          label: Text(l.platformRequests),
                          onPressed: () => context.go('/platform/requests'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('platform-activity'),
                          icon: const Icon(Icons.history),
                          label: Text(l.platformActivity),
                          onPressed: () => context.go('/platform/activity'),
                        ),
                      ],
                    ),
                    TextField(
                      key: const Key('tenant-search'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.platformSearchHint,
                        isDense: true,
                      ),
                      onSubmitted: (v) => setFilter(
                        TenantFilter(status: filter.status, query: v),
                      ),
                      onChanged: (v) {
                        if (v.isEmpty && filter.query.isNotEmpty) {
                          setFilter(TenantFilter(status: filter.status));
                        }
                      },
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: HoopsSpace.sm,
                        children: [
                          ChoiceChip(
                            key: const Key('status-all'),
                            label: Text(l.all),
                            selected: filter.status == null,
                            onSelected: (_) =>
                                setFilter(TenantFilter(query: filter.query)),
                          ),
                          for (final s in [
                            api.TenantStatus.ACTIVE,
                            api.TenantStatus.SUSPENDED,
                            api.TenantStatus.WITHDRAWN,
                          ])
                            ChoiceChip(
                              key: Key('status-${s.name}'),
                              label: Text(s.label(l)),
                              selected: filter.status == s,
                              onSelected: (_) => setFilter(
                                TenantFilter(status: s, query: filter.query),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AsyncBody<List<api.Tenant>>(
                value: ref.watch(tenantsProvider),
                onRetry: () => ref.invalidate(tenantsProvider),
                isEmpty: (d) => d.isEmpty,
                emptyMessage: l.platformEmpty,
                builder: (context, data) => PageBody(
                  children: [
                    Column(
                      spacing: HoopsSpace.gap,
                      children: [
                        for (final t in data)
                          ListRow(
                            key: Key('tenant-${t.id}'),
                            leading: InitialsAvatar(name: t.name),
                            title: t.name,
                            subtitle: t.slug,
                            trailing: TenantStatusChip(t.status),
                            onTap: () => context.go('/platform/${t.id}'),
                          ),
                        const SizedBox(height: HoopsSize.appBar),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _slugPattern = RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$');

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

  /// Creates the academy; the first administrator's temporary password (new login) is shown once, then dropped.
  Future<bool> _submit() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context, rootNavigator: true).context;
    final (email, given, family) = (
      _email.text.trim(),
      _given.text.trim(),
      _family.text.trim(),
    );
    api.TenantWithPassword? created;
    final ok = await runAction(
      context,
      () async => created = await ref
          .read(tenantsProvider.notifier)
          .create(
            name: _name.text.trim(),
            slug: _slug.text.trim(),
            timezone: _timezone.text.trim(),
            locale: _locale,
            adminEmail: email,
            adminGivenName: given,
            adminFamilyName: family,
          ),
    );
    if (ok) {
      _announce = () => announceLogin(
        nav,
        person: '$given $family',
        email: email,
        temporaryPassword: created?.temporaryPassword,
        done: l.tenantCreated,
      );
    }
    return ok;
  }

  /// Shown once the form has closed (see [FormDialog.afterClose]); never kept past that.
  Future<void> Function()? _announce;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget field(
      String key,
      TextEditingController c,
      String label, {
      String? Function(String?)? validator,
      TextInputType? type,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: HoopsSpace.gap),
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
      onSubmit: _submit,
      afterClose: () async => _announce?.call(),
      children: [
        field('tenant-name', _name, l.tenantName),
        field(
          'tenant-slug',
          _slug,
          l.tenantSlug,
          validator: (v) => _slugPattern.hasMatch((v ?? '').trim())
              ? null
              : l.tenantSlugInvalid,
        ),
        field('tenant-timezone', _timezone, l.tenantTimezone),
        DropdownButtonFormField<api.ApiLocale>(
          key: const Key('tenant-locale'),
          initialValue: _locale,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.tenantLocale),
          items: [
            DropdownMenuItem(
              value: api.ApiLocale.es,
              child: Text(l.languageName_es),
            ),
            DropdownMenuItem(
              value: api.ApiLocale.en,
              child: Text(l.languageName_en),
            ),
            DropdownMenuItem(
              value: api.ApiLocale.id,
              child: Text(l.languageName_id),
            ),
          ],
          onChanged: (v) => setState(() => _locale = v ?? _locale),
        ),
        formGap,
        field(
          'tenant-admin-email',
          _email,
          l.tenantAdminEmail,
          type: TextInputType.emailAddress,
          validator: (v) => emailValidator(l, v),
        ),
        field('tenant-admin-given', _given, l.tenantAdminGivenName),
        field('tenant-admin-family', _family, l.tenantAdminFamilyName),
      ],
    );
  }
}
