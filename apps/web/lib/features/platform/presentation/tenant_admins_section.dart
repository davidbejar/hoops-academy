import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart' show InfoChip, ChipTone;
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_labels.dart';
import 'platform_validators.dart';

/// Administrators of an academy on the tenant detail page (ADR-0023): list, add, edit, remove, resend invitation.
/// An academy always keeps one administrator, so the only one listed cannot be removed.
class TenantAdminsSection extends ConsumerWidget {
  const TenantAdminsSection({super.key, required this.tenant});
  final api.Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final admins = tenant.status == api.TenantStatus.WITHDRAWN ? null : ref.watch(tenantAdminsProvider(tenant.id));
    final withdrawn = admins == null || (admins.value == null && admins.hasError && isTenantWithdrawn(admins.error!));
    return Column(
      key: const Key('admins-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTokens.spaceSm,
          runSpacing: AppTokens.spaceXs,
          children: [
            Text(l.adminsTitle, style: Theme.of(context).textTheme.titleMedium),
            if (admins?.value != null)
              OutlinedButton.icon(
                key: const Key('admin-add'),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => AdminFormDialog(tenantId: tenant.id, locale: tenant.defaultLocale),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(l.adminsAdd),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceSm),
        if (withdrawn)
          _Note(key: const Key('admins-withdrawn'), icon: Icons.block, text: l.adminsWithdrawn)
        else if (admins.value != null)
          _AdminList(tenantId: tenant.id, admins: admins.value!)
        else if (admins.hasError)
          _LoadError(error: admins.error!, onRetry: () => ref.invalidate(tenantAdminsProvider(tenant.id)))
        else
          const Padding(
            padding: EdgeInsets.all(AppTokens.spaceMd),
            child: Center(child: CircularProgressIndicator(key: Key('admins-loading'))),
          ),
      ],
    );
  }
}

class _AdminList extends StatelessWidget {
  const _AdminList({required this.tenantId, required this.admins});
  final String tenantId;
  final List<api.TenantAdmin> admins;

  @override
  Widget build(BuildContext context) {
    if (admins.isEmpty) {
      return Text(AppLocalizations.of(context).adminsEmpty, key: const Key('admins-empty'));
    }
    return Column(
      children: [for (final a in admins) _AdminTile(tenantId: tenantId, admin: a, isLast: admins.length == 1)],
    );
  }
}

class _AdminTile extends ConsumerWidget {
  const _AdminTile({required this.tenantId, required this.admin, required this.isLast});
  final String tenantId;
  final api.TenantAdmin admin;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = admin.personId;
    final notifier = ref.read(tenantAdminsProvider(tenantId).notifier);
    final name = '${admin.givenName} ${admin.familyName}';
    final status = admin.invitationStatus.label(l);

    Future<void> remove() async {
      if (!await confirmDialog(context, message: l.adminRemoveConfirm(name), confirmLabel: l.adminRemoveSubmit)) return;
      if (!context.mounted) return;
      await runAction(context, () => notifier.remove(id), success: l.adminRemoved, errorText: adminErrorText);
    }

    return Card(
      key: Key('admin-$id'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceMd, AppTokens.spaceSm, AppTokens.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall),
                  if (admin.email != null) Text(admin.email!, style: theme.textTheme.bodyMedium),
                  if (status != null || admin.otherRoles.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spaceXs),
                    Wrap(
                      spacing: AppTokens.spaceSm,
                      runSpacing: AppTokens.spaceXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (status != null)
                          InfoChip(
                            status,
                            tone: admin.invitationStatus == api.InvitationStatus.PENDING ? ChipTone.warn : ChipTone.good,
                          ),
                        if (admin.otherRoles.isNotEmpty)
                          Text(l.adminOtherRoles(rolesText(admin.otherRoles, l)), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                  if (isLast) ...[
                    const SizedBox(height: AppTokens.spaceSm),
                    _Note(key: const Key('admin-last-note'), icon: Icons.info_outline, text: l.adminLastAdminNote),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (admin.invitationStatus == api.InvitationStatus.PENDING)
                  IconButton(
                    key: Key('admin-resend-$id'),
                    tooltip: l.adminResend,
                    icon: const Icon(Icons.forward_to_inbox_outlined),
                    onPressed: () => runAction(
                      context,
                      () => notifier.resendInvitation(id),
                      success: l.adminInvitationResent,
                      errorText: adminErrorText,
                    ),
                  ),
                IconButton(
                  key: Key('admin-edit-$id'),
                  tooltip: l.adminEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => AdminFormDialog(tenantId: tenantId, admin: admin),
                  ),
                ),
                IconButton(
                  key: Key('admin-remove-$id'),
                  tooltip: l.adminRemove,
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: isLast ? null : remove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppTokens.spaceSm),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      key: const Key('admins-error'),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.adminsLoadFailed} · ${AppError.of(error).message(l)}'),
            const SizedBox(height: AppTokens.spaceSm),
            OutlinedButton(key: const Key('admins-retry'), onPressed: onRetry, child: Text(l.retry)),
          ],
        ),
      ),
    );
  }
}

/// Add (no [admin]) or edit (with [admin]) an administrator. Add explains promotion vs invitation; edit warns that
/// the e-mail is the login.
class AdminFormDialog extends ConsumerStatefulWidget {
  const AdminFormDialog({super.key, required this.tenantId, this.admin, this.locale});
  final String tenantId;
  final api.TenantAdmin? admin;

  /// Language of the invitation e-mail (the academy's default); add only.
  final api.ApiLocale? locale;

  @override
  ConsumerState<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends ConsumerState<AdminFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.admin?.email ?? '');
  late final _given = TextEditingController(text: widget.admin?.givenName ?? '');
  late final _family = TextEditingController(text: widget.admin?.familyName ?? '');

  @override
  void dispose() {
    for (final c in [_email, _given, _family]) {
      c.dispose();
    }
    super.dispose();
  }

  /// An administrator without an address may stay that way (the field is only validated once filled).
  bool keepsMissingEmail(String? v) => widget.admin != null && (widget.admin!.email ?? '').isEmpty && (v ?? '').trim().isEmpty;

  String? _changed(String now, String? before) => now == (before ?? '') ? null : now;

  Future<bool> _submit(AppLocalizations l) async {
    final notifier = ref.read(tenantAdminsProvider(widget.tenantId).notifier);
    final (email, given, family) = (_email.text.trim(), _given.text.trim(), _family.text.trim());
    final admin = widget.admin;
    if (admin == null) {
      return runAction(
        context,
        () async {
          final added = await notifier.add(email: email, givenName: given, familyName: family, locale: widget.locale ?? api.ApiLocale.es);
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(added.invitationStatus == api.InvitationStatus.PENDING ? l.adminInvited : l.adminAdded)),
          );
        },
        errorText: adminErrorText,
      );
    }
    final (newGiven, newFamily, newEmail) = (_changed(given, admin.givenName), _changed(family, admin.familyName), _changed(email, admin.email));
    if (newGiven == null && newFamily == null && newEmail == null) return true; // nothing to send
    return runAction(
      context,
      () => notifier.edit(admin.personId, givenName: newGiven, familyName: newFamily, email: newEmail),
      success: l.adminUpdated,
      errorText: adminErrorText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final editing = widget.admin != null;
    Widget field(String key, TextEditingController c, String label, {String? Function(String?)? validator, TextInputType? type}) => Padding(
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
      title: editing ? l.adminEdit : l.adminsAdd,
      submitLabel: editing ? l.save : l.adminAddSubmit,
      formKey: _form,
      onSubmit: () => _submit(l),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(editing ? l.adminEditEmailNote : l.adminAddHint, key: const Key('admin-form-note')),
        ),
        field(
          'admin-email',
          _email,
          l.memberEmail,
          type: TextInputType.emailAddress,
          validator: (v) => keepsMissingEmail(v) ? null : emailValidator(l, v),
        ),
        field('admin-given', _given, l.memberGivenName),
        field('admin-family', _family, l.memberFamilyName),
      ],
    );
  }
}
