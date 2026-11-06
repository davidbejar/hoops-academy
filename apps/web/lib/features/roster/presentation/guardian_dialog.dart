import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/temporary_password_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart';
import '../../admin/presentation/members_screen.dart' show memberErrorText;
import '../data/guardians_repository.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The academy's active PARENT members by person id: whether a guardian has a login decides the login action.
final guardianMembersProvider =
    FutureProvider.autoDispose<Map<String, api.Member>>((ref) async {
      final parents = await ref
          .watch(membersRepositoryProvider)
          .list(role: api.TenantRole.PARENT, active: true);
      return {for (final m in parents) m.personId: m};
    });

/// A new guardian of [playerId] (ADMIN). With an e-mail the guardian gets a login; a login created by the call comes
/// with a temporary password, shown once after the form closes (ADR-0024), never kept.
class AddGuardianDialog extends ConsumerStatefulWidget {
  const AddGuardianDialog({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<AddGuardianDialog> createState() => _AddGuardianDialogState();
}

class _AddGuardianDialogState extends ConsumerState<AddGuardianDialog> {
  final _form = GlobalKey<FormState>();
  final _given = TextEditingController();
  final _family = TextEditingController();
  final _email = TextEditingController();

  /// Shown once the form has closed (see [FormDialog.afterClose]); never kept past that.
  Future<void> Function()? _announce;

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context, rootNavigator: true).context;
    final messenger = ScaffoldMessenger.maybeOf(nav);
    final (given, family, email) = (
      _given.text.trim(),
      _family.text.trim(),
      _email.text.trim(),
    );
    api.GuardianLinkWithPassword? added;
    final ok = await runAction(
      context,
      () async => added = await ref
          .read(guardiansRepositoryProvider)
          .create(
            playerId: widget.playerId,
            givenName: given,
            familyName: family,
            email: email.isEmpty ? null : email,
          ),
      errorText: memberErrorText,
    );
    if (!ok) return false;
    ref.invalidate(guardianMembersProvider);
    _announce = email.isEmpty
        ? () async => messenger?.showSnackBar(
            SnackBar(content: Text(l.playerGuardianAdded)),
          )
        : () => announceLogin(
            nav,
            person: '$given $family',
            email: email,
            temporaryPassword: added?.temporaryPassword,
            done: l.playerGuardianAdded,
          );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.playerGuardianAddTitle,
      formKey: _form,
      submitLabel: l.playerGuardianAdd,
      onSubmit: _submit,
      afterClose: () async => _announce?.call(),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l.playerGuardianHint, key: const Key('guardian-hint')),
        ),
        TextFormField(
          key: const Key('guardian-given'),
          controller: _given,
          decoration: InputDecoration(labelText: l.memberGivenName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('guardian-family'),
          controller: _family,
          decoration: InputDecoration(labelText: l.memberFamilyName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('guardian-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l.playerGuardianEmailOptional),
          validator: (v) {
            final value = (v ?? '').trim();
            return value.isEmpty || _emailPattern.hasMatch(value)
                ? null
                : l.fieldInvalidEmail;
          },
        ),
      ],
    );
  }
}

/// Gives the guardian [personId] a login (none yet, with an e-mail) or a new temporary password (still pending);
/// nothing for a guardian who already signs in. The password is shown once (ADR-0024).
class GuardianLoginButton extends ConsumerWidget {
  const GuardianLoginButton({
    super.key,
    required this.personId,
    required this.name,
  });

  final String personId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final m = ref.watch(guardianMembersProvider).value?[personId];
    if (m == null || !m.active || m.email == null) {
      return const SizedBox.shrink();
    }
    final noLogin = m.userId == null;
    if (!noLogin && m.invitationStatus != api.InvitationStatus.PENDING) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: Key('guardian-login-$personId'),
      tooltip: noLogin ? l.playerGuardianLogin : l.tempPasswordIssue,
      icon: const Icon(Icons.key_outlined),
      onPressed: () => _issue(context, ref, m),
    );
  }

  Future<void> _issue(BuildContext context, WidgetRef ref, api.Member m) async {
    final nav = Navigator.of(context, rootNavigator: true).context;
    api.MemberWithPassword? issued;
    final ok = await runAction(
      context,
      () async => issued = await ref
          .read(guardiansRepositoryProvider)
          .issueTemporaryPassword(personId),
      errorText: memberErrorText,
    );
    if (!ok) return;
    ref.invalidate(guardianMembersProvider);
    if (!nav.mounted) return;
    await announceLogin(
      nav,
      person: name,
      email: m.email,
      temporaryPassword: issued?.temporaryPassword,
    );
  }
}
