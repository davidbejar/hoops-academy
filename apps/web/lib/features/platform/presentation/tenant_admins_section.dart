import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/temporary_password_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_labels.dart';
import 'platform_validators.dart';

/// Administrators of an academy on the tenant detail page (ADR-0023): list, add, edit, remove, and a new temporary
/// password for a pending administrator (ADR-0024; no e-mail is ever sent).
/// An academy always keeps one administrator, so the only one listed cannot be removed.
class TenantAdminsSection extends ConsumerWidget {
  const TenantAdminsSection({super.key, required this.tenant});
  final api.Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final admins = tenant.status == api.TenantStatus.WITHDRAWN
        ? null
        : ref.watch(tenantAdminsProvider(tenant.id));
    final withdrawn =
        admins == null ||
        (admins.value == null &&
            admins.hasError &&
            isTenantWithdrawn(admins.error!));
    return SectionCard(
      key: const Key('admins-section'),
      title: l.adminsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HoopsSpace.gap,
        children: [
          if (admins?.value != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('admin-add'),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => AdminFormDialog(
                    tenantId: tenant.id,
                    locale: tenant.defaultLocale,
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(l.adminsAdd),
              ),
            ),
          withdrawn
              ? _Note(
                  key: const Key('admins-withdrawn'),
                  icon: Icons.block,
                  text: l.adminsWithdrawn,
                )
              : admins.value != null
              ? _AdminList(tenantId: tenant.id, admins: admins.value!)
              : admins.hasError
              ? _LoadError(
                  error: admins.error!,
                  onRetry: () =>
                      ref.invalidate(tenantAdminsProvider(tenant.id)),
                )
              : const Padding(
                  padding: EdgeInsets.all(HoopsSpace.md),
                  child: Center(
                    child: CircularProgressIndicator(
                      key: Key('admins-loading'),
                    ),
                  ),
                ),
        ],
      ),
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
      return Text(
        AppLocalizations.of(context).adminsEmpty,
        key: const Key('admins-empty'),
      );
    }
    return Column(
      spacing: HoopsSpace.sm,
      children: [
        for (final a in admins)
          _AdminTile(tenantId: tenantId, admin: a, isLast: admins.length == 1),
      ],
    );
  }
}

class _AdminTile extends ConsumerWidget {
  const _AdminTile({
    required this.tenantId,
    required this.admin,
    required this.isLast,
  });
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
    final nav = Navigator.of(context, rootNavigator: true).context;

    Future<void> remove() async {
      if (!await confirmDialog(
        context,
        message: l.adminRemoveConfirm(name),
        confirmLabel: l.adminRemoveSubmit,
      )) {
        return;
      }
      if (!context.mounted) return;
      await runAction(
        context,
        () => notifier.remove(id),
        success: l.adminRemoved,
        errorText: adminErrorText,
      );
    }

    Future<void> issue() async {
      api.TenantAdminWithPassword? issued;
      final ok = await runAction(
        context,
        () async => issued = await notifier.issueTemporaryPassword(id),
        errorText: adminErrorText,
      );
      if (!ok || !nav.mounted) return;
      await announceLogin(
        nav,
        person: name,
        email: admin.email,
        temporaryPassword: issued?.temporaryPassword,
      );
    }

    final c = HoopsTokens.colorsOf(context);
    return DecoratedBox(
      key: Key('admin-$id'),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(HoopsRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HoopsSpace.md,
          HoopsSpace.gap,
          HoopsSpace.sm,
          HoopsSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: HoopsSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: HoopsSpace.gap,
                children: [
                  InitialsAvatar(name: name, size: 36),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleSmall),
                        if (admin.email != null)
                          Text(
                            admin.email!,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        if (status != null || admin.otherRoles.isNotEmpty) ...[
                          const SizedBox(height: HoopsSpace.xs),
                          Wrap(
                            spacing: HoopsSpace.sm,
                            runSpacing: HoopsSpace.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (status != null)
                                StatusChip(
                                  status,
                                  tone:
                                      admin.invitationStatus ==
                                          api.InvitationStatus.PENDING
                                      ? HoopsTone.warning
                                      : HoopsTone.success,
                                ),
                              if (admin.invitationStatus ==
                                      api.InvitationStatus.PENDING &&
                                  admin.temporaryPasswordStatus ==
                                      api.TemporaryPasswordStatus.EXPIRED)
                                StatusChip(
                                  l.tempPasswordExpired,
                                  key: Key('admin-password-expired-$id'),
                                  tone: HoopsTone.danger,
                                ),
                              if (admin.otherRoles.isNotEmpty)
                                Text(
                                  l.adminOtherRoles(
                                    rolesText(admin.otherRoles, l),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ],
                        if (isLast) ...[
                          const SizedBox(height: HoopsSpace.sm),
                          _Note(
                            key: const Key('admin-last-note'),
                            icon: Icons.info_outline,
                            text: l.adminLastAdminNote,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (admin.invitationStatus == api.InvitationStatus.PENDING)
                  IconButton(
                    key: Key('admin-issue-$id'),
                    tooltip: l.tempPasswordIssue,
                    icon: const Icon(Icons.key_outlined),
                    onPressed: () => issue(),
                  ),
                IconButton(
                  key: Key('admin-edit-$id'),
                  tooltip: l.adminEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        AdminFormDialog(tenantId: tenantId, admin: admin),
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
        Icon(icon, size: 18, color: HoopsTokens.colorsOf(context).inkMuted),
        const SizedBox(width: HoopsSpace.sm),
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
    return Column(
      key: const Key('admins-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.sm,
      children: [
        Text('${l.adminsLoadFailed} · ${AppError.of(error).message(l)}'),
        OutlinedButton(
          key: const Key('admins-retry'),
          onPressed: onRetry,
          child: Text(l.retry),
        ),
      ],
    );
  }
}

/// Add (no [admin]) or edit (with [admin]) an administrator. Add explains promotion vs invitation; edit warns that
/// the e-mail is the login.
class AdminFormDialog extends ConsumerStatefulWidget {
  const AdminFormDialog({
    super.key,
    required this.tenantId,
    this.admin,
    this.locale,
  });
  final String tenantId;
  final api.TenantAdmin? admin;

  /// Language of the person's profile (the academy's default); add only.
  final api.ApiLocale? locale;

  @override
  ConsumerState<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends ConsumerState<AdminFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.admin?.email ?? '');
  late final _given = TextEditingController(
    text: widget.admin?.givenName ?? '',
  );
  late final _family = TextEditingController(
    text: widget.admin?.familyName ?? '',
  );

  @override
  void dispose() {
    for (final c in [_email, _given, _family]) {
      c.dispose();
    }
    super.dispose();
  }

  /// An administrator without an address may stay that way (the field is only validated once filled).
  bool keepsMissingEmail(String? v) =>
      widget.admin != null &&
      (widget.admin!.email ?? '').isEmpty &&
      (v ?? '').trim().isEmpty;

  /// Shown once the form has closed (see [FormDialog.afterClose]); never kept past that.
  Future<void> Function()? _announce;

  String? _changed(String now, String? before) =>
      now == (before ?? '') ? null : now;

  Future<bool> _submit(AppLocalizations l) async {
    final notifier = ref.read(tenantAdminsProvider(widget.tenantId).notifier);
    final (email, given, family) = (
      _email.text.trim(),
      _given.text.trim(),
      _family.text.trim(),
    );
    final admin = widget.admin;
    if (admin == null) {
      final nav = Navigator.of(context, rootNavigator: true).context;
      api.TenantAdminWithPassword? added;
      final ok = await runAction(
        context,
        () async => added = await notifier.add(
          email: email,
          givenName: given,
          familyName: family,
          locale: widget.locale ?? api.ApiLocale.es,
        ),
        errorText: adminErrorText,
      );
      if (ok) {
        _announce = () => announceLogin(
          nav,
          person: '$given $family',
          email: email,
          temporaryPassword: added?.temporaryPassword,
          done: l.adminAdded,
        );
      }
      return ok;
    }
    final (newGiven, newFamily, newEmail) = (
      _changed(given, admin.givenName),
      _changed(family, admin.familyName),
      _changed(email, admin.email),
    );
    if (newGiven == null && newFamily == null && newEmail == null)
      return true; // nothing to send
    return runAction(
      context,
      () => notifier.edit(
        admin.personId,
        givenName: newGiven,
        familyName: newFamily,
        email: newEmail,
      ),
      success: l.adminUpdated,
      errorText: adminErrorText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final editing = widget.admin != null;
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
      title: editing ? l.adminEdit : l.adminsAdd,
      submitLabel: editing ? l.save : l.adminAddSubmit,
      formKey: _form,
      onSubmit: () => _submit(l),
      afterClose: () async => _announce?.call(),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: HoopsSpace.gap),
          child: Text(
            editing ? l.adminEditEmailNote : l.adminAddHint,
            key: const Key('admin-form-note'),
          ),
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
