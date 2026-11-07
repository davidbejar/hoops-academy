import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/temporary_password_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../application/admin_providers.dart';
import 'member_edit_dialog.dart';

final memberEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Localised text for a failed member action, chosen by the server's error code (never its English detail).
String memberErrorText(Object error, AppLocalizations l) {
  final e = AppError.of(error);
  return switch (e.code) {
    'INVITATION_NOT_PENDING' => l.memberErrorNotPending,
    'LOGIN_SHARED' => l.memberErrorLoginShared,
    'LOGIN_REQUIRES_EMAIL' => l.memberErrorLoginRequiresEmail,
    'EMAIL_TAKEN' => l.memberErrorEmailTaken,
    'IDENTITY_PROVIDER_UNAVAILABLE' => l.adminErrorIdentityProvider,
    _ => e.message(l),
  };
}

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final members = ref.watch(membersProvider);
    return SubPage(
      title: l.adminMembers,
      parentPath: '/admin',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('member-invite'),
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => const InviteMemberDialog(),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.memberInvite),
      ),
      child: Column(
        children: [
          ContentFrame(
            child: Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.md),
              child: TextField(
                key: const Key('member-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.membersSearchHint,
                ),
                onSubmitted: (v) =>
                    ref.read(memberQueryProvider.notifier).set(v),
                onChanged: (v) {
                  if (v.isEmpty) ref.read(memberQueryProvider.notifier).set('');
                },
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<api.Member>>(
              value: members,
              onRetry: () => ref.invalidate(membersProvider),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: l.membersEmpty,
              builder: (context, data) => PageBody(
                children: [
                  Column(
                    spacing: HoopsSpace.gap,
                    children: [
                      for (final m in data) _MemberTile(member: m),
                      const SizedBox(height: HoopsSize.appBar),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});
  final api.Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final details = [
      if (member.email != null) member.email!,
      rolesText(member.roles, l),
    ].join(' · ');
    final expired =
        member.active &&
        member.invitationStatus == api.InvitationStatus.PENDING &&
        member.temporaryPasswordStatus == api.TemporaryPasswordStatus.EXPIRED;
    return ListRow(
      key: Key('member-${member.personId}'),
      leading: InitialsAvatar(name: member.displayName),
      title: member.displayName,
      subtitle: details,
      trailing: !member.active
          ? _TrailingChip(StatusChip(l.memberInactive, tone: HoopsTone.danger))
          : expired
          ? _TrailingChip(
              StatusChip(
                l.tempPasswordExpired,
                key: Key('member-password-expired-${member.personId}'),
                tone: HoopsTone.danger,
              ),
            )
          : member.invitationStatus == api.InvitationStatus.PENDING
          ? _TrailingChip(
              StatusChip(l.memberInvitationPending, tone: HoopsTone.warning),
            )
          : null,
      onTap: () => context.go('/admin/members/${member.personId}'),
    );
  }
}

/// Keeps a status chip from squeezing the name on a phone: long labels wrap.
class _TrailingChip extends StatelessWidget {
  const _TrailingChip(this.chip);
  final Widget chip;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 120),
    child: chip,
  );
}

class InviteMemberDialog extends ConsumerStatefulWidget {
  const InviteMemberDialog({super.key});

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _form = GlobalKey<FormState>();
  final _given = TextEditingController();
  final _family = TextEditingController();
  final _email = TextEditingController();
  final Set<api.TenantRole> _roles = {};
  bool _rolesTouched = false;

  @override
  void dispose() {
    _given.dispose();
    _family.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Invites the member; a login created by the call comes with a temporary password, shown once then dropped.
  Future<bool> _submit() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context, rootNavigator: true).context;
    final (given, family, email) = (
      _given.text.trim(),
      _family.text.trim(),
      _email.text.trim(),
    );
    api.MemberWithPassword? invited;
    final ok = await runAction(
      context,
      () async => invited = await ref
          .read(membersProvider.notifier)
          .invite(
            givenName: given,
            familyName: family,
            email: email,
            roles: _roles,
          ),
      errorText: memberErrorText,
    );
    if (ok) {
      _announce = () => announceLogin(
        nav,
        person: '$given $family',
        email: email,
        temporaryPassword: invited?.temporaryPassword,
        done: l.memberAdded,
      );
    }
    return ok;
  }

  /// Shown once the form has closed (see [FormDialog.afterClose]); never kept past that.
  Future<void> Function()? _announce;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.memberInviteTitle,
      formKey: _form,
      submitLabel: l.memberInvite,
      validateExtra: () {
        setState(() => _rolesTouched = true);
        return _roles.isNotEmpty;
      },
      onSubmit: _submit,
      afterClose: () async => _announce?.call(),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: HoopsSpace.gap),
          child: Text(l.memberInviteHint, key: const Key('invite-hint')),
        ),
        TextFormField(
          key: const Key('invite-given'),
          controller: _given,
          decoration: InputDecoration(labelText: l.memberGivenName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('invite-family'),
          controller: _family,
          decoration: InputDecoration(labelText: l.memberFamilyName),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        TextFormField(
          key: const Key('invite-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l.memberEmail),
          validator: (v) => memberEmailPattern.hasMatch((v ?? '').trim())
              ? null
              : l.fieldInvalidEmail,
        ),
        formGap,
        Text(l.memberRoles, style: Theme.of(context).textTheme.titleSmall),
        RolePicker(selected: _roles, onChanged: () => setState(() {})),
        if (_rolesTouched && _roles.isEmpty)
          Text(
            l.memberRolesRequired,
            key: const Key('roles-error'),
            style: TextStyle(
              color: HoopsTokens.colorsOf(context)
                  .tone(HoopsTone.danger)
                  .foreground,
            ),
          ),
      ],
    );
  }
}

/// Multi-select of the five tenant roles; mutates [selected] in place.
class RolePicker extends StatelessWidget {
  const RolePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<api.TenantRole> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: HoopsSpace.sm,
      children: [
        for (final role in grantableRoles)
          FilterChip(
            key: Key('role-${role.name}'),
            label: Text(role.label(l)),
            selected: selected.contains(role),
            onSelected: (on) {
              on ? selected.add(role) : selected.remove(role);
              onChanged();
            },
          ),
      ],
    );
  }
}

/// One member: roles editor, deactivate, and (for parents) guardian links.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final members = ref.watch(membersProvider);
    api.Member? member;
    for (final m in members.value ?? const <api.Member>[]) {
      if (m.personId == personId) member = m;
    }
    return SubPage(
      title: member?.displayName ?? l.adminMembers,
      parentPath: '/admin/members',
      child: AsyncBody<List<api.Member>>(
        value: members,
        onRetry: () => ref.invalidate(membersProvider),
        isEmpty: (_) => member == null,
        builder: (context, _) => _MemberDetail(member: member!),
      ),
    );
  }
}

class _MemberDetail extends ConsumerStatefulWidget {
  const _MemberDetail({required this.member});
  final api.Member member;

  @override
  ConsumerState<_MemberDetail> createState() => _MemberDetailState();
}

class _MemberDetailState extends ConsumerState<_MemberDetail> {
  late final Set<api.TenantRole> _roles = {...widget.member.roles};

  /// New temporary password for a pending member, or the first login of a guardian without one (WP58): shown once,
  /// then dropped.
  Future<void> _issuePassword() async {
    final m = widget.member;
    final nav = Navigator.of(context, rootNavigator: true).context;
    api.MemberWithPassword? issued;
    final ok = await runAction(
      context,
      () async => issued = await ref
          .read(membersProvider.notifier)
          .issueTemporaryPassword(m.personId),
      errorText: memberErrorText,
    );
    if (!ok || !nav.mounted) return;
    await announceLogin(
      nav,
      person: m.displayName,
      email: m.email,
      temporaryPassword: issued?.temporaryPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.member;
    final pending = m.invitationStatus == api.InvitationStatus.PENDING;
    final firstGuardianLogin =
        m.userId == null &&
        m.email != null &&
        m.roles.contains(api.TenantRole.PARENT);
    final theme = Theme.of(context);
    final isParent = m.roles.contains(api.TenantRole.PARENT);
    return PageBody(
      header: PageHeader(
        title: m.displayName,
        subtitle: m.email,
        actions: [
          OutlinedButton.icon(
            key: const Key('member-edit'),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l.memberEdit),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => MemberEditDialog(member: m),
            ),
          ),
          if ((pending || firstGuardianLogin) && m.active)
            OutlinedButton.icon(
              key: const Key('member-issue-password'),
              icon: const Icon(Icons.key_outlined),
              label: Text(l.tempPasswordIssue),
              onPressed: _issuePassword,
            ),
        ],
      ),
      children: [
        if (!m.active || pending)
          Wrap(
            spacing: HoopsSpace.sm,
            runSpacing: HoopsSpace.xs,
            children: [
              if (!m.active)
                StatusChip(l.memberInactive, tone: HoopsTone.danger)
              else ...[
                StatusChip(l.memberInvitationPending, tone: HoopsTone.warning),
                if (m.temporaryPasswordStatus ==
                    api.TemporaryPasswordStatus.EXPIRED)
                  StatusChip(
                    l.tempPasswordExpired,
                    key: const Key('member-password-expired'),
                    tone: HoopsTone.danger,
                  ),
              ],
            ],
          ),
        SectionCard(
          title: l.memberRoles,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: HoopsSpace.gap,
            children: [
              RolePicker(selected: _roles, onChanged: () => setState(() {})),
              FilledButton(
                key: const Key('member-save-roles'),
                onPressed: _roles.isEmpty
                    ? null
                    : () => runAction(
                        context,
                        () => ref.read(membersProvider.notifier).replaceRoles(
                          m.personId,
                          {..._roles},
                        ),
                        success: l.saved,
                      ),
                child: Text(l.memberEditRoles),
              ),
            ],
          ),
        ),
        SectionCard(
          title: l.memberGuardianLinks,
          child: isParent
              ? GuardianLinksEditor(guardianPersonId: m.personId)
              : Text(
                  l.memberGuardianOnlyParents,
                  style: theme.textTheme.bodySmall,
                ),
        ),
        if (m.active)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('member-deactivate'),
              icon: const Icon(Icons.person_off_outlined),
              label: Text(l.memberDeactivate),
              onPressed: () async {
                if (!await confirmDialog(
                  context,
                  message: l.memberDeactivateConfirm(m.displayName),
                )) {
                  return;
                }
                if (!context.mounted) return;
                await runAction(
                  context,
                  () =>
                      ref.read(membersProvider.notifier).deactivate(m.personId),
                  success: l.memberDeactivated,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Guardian (parent) <-> player links of one parent.
class GuardianLinksEditor extends ConsumerWidget {
  const GuardianLinksEditor({super.key, required this.guardianPersonId});
  final String guardianPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final links = ref.watch(guardianLinksProvider(guardianPersonId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AsyncBodyInline<List<api.GuardianLink>>(
          value: links,
          onRetry: () =>
              ref.invalidate(guardianLinksProvider(guardianPersonId)),
          builder: (context, data) => data.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: HoopsSpace.sm),
                  child: Text(
                    l.memberGuardianNone,
                    key: const Key('guardian-none'),
                  ),
                )
              : Column(
                  spacing: HoopsSpace.sm,
                  children: [
                    for (final link in data)
                      ListRow(
                        key: Key('link-${link.id}'),
                        leading: InitialsAvatar(
                          name: link.player.displayName,
                          size: 36,
                        ),
                        title: link.player.displayName,
                        trailing: IconButton(
                          tooltip: l.remove,
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            if (!await confirmDialog(
                              context,
                              message: l.memberGuardianRemoveConfirm(
                                link.player.displayName,
                              ),
                            )) {
                              return;
                            }
                            if (!context.mounted) return;
                            await runAction(
                              context,
                              () => ref
                                  .read(
                                    guardianLinksProvider(guardianPersonId)
                                        .notifier,
                                  )
                                  .remove(link.id),
                            );
                          },
                        ),
                      ),
                  ],
                ),
        ),
        TextButton.icon(
          key: const Key('guardian-add'),
          icon: const Icon(Icons.add_link),
          label: Text(l.memberGuardianAdd),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) =>
                _PickPlayerDialog(guardianPersonId: guardianPersonId),
          ),
        ),
      ],
    );
  }
}

/// Like [AsyncBody] but sized for embedding in a scrolling column.
class AsyncBodyInline<T> extends StatelessWidget {
  const AsyncBodyInline({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = value.value;
    if (data != null) return builder(context, data);
    if (value.hasError) {
      return TextButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).retry),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(HoopsSpace.md),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PickPlayerDialog extends ConsumerStatefulWidget {
  const _PickPlayerDialog({required this.guardianPersonId});
  final String guardianPersonId;

  @override
  ConsumerState<_PickPlayerDialog> createState() => _PickPlayerDialogState();
}

class _PickPlayerDialogState extends ConsumerState<_PickPlayerDialog> {
  String _query = '';
  late Future<List<api.Player>> _players = ref
      .read(playersRepositoryProvider)
      .list();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.memberGuardianAdd),
      content: SizedBox(
        width: 360,
        height: 360,
        child: Column(
          children: [
            TextField(
              key: const Key('pick-player-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.playersSearchHint,
              ),
              onSubmitted: (v) => setState(() {
                _query = v;
                _players = ref.read(playersRepositoryProvider).list(query: v);
              }),
            ),
            Expanded(
              child: FutureBuilder<List<api.Player>>(
                key: ValueKey(_query),
                future: _players,
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text(l.errorUnknown));
                  final players = snap.data;
                  if (players == null)
                    return const Center(child: CircularProgressIndicator());
                  return ListView(
                    children: [
                      for (final p in players)
                        ListRow(
                          key: Key('pick-player-${p.id}'),
                          leading: InitialsAvatar(
                            name: p.displayName,
                            size: 36,
                          ),
                          title: p.displayName,
                          onTap: () async {
                            final ok = await runAction(
                              context,
                              () => ref
                                  .read(
                                    guardianLinksProvider(
                                      widget.guardianPersonId,
                                    ).notifier,
                                  )
                                  .add(p.id),
                            );
                            if (ok && context.mounted)
                              Navigator.of(context).pop();
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}
