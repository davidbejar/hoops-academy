import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../application/admin_providers.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
        onPressed: () => showDialog<bool>(context: context, builder: (_) => const InviteMemberDialog()),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.memberInvite),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: TextField(
              key: const Key('member-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.membersSearchHint,
              ),
              onSubmitted: (v) => ref.read(memberQueryProvider.notifier).set(v),
              onChanged: (v) {
                if (v.isEmpty) ref.read(memberQueryProvider.notifier).set('');
              },
            ),
          ),
          Expanded(
            child: AsyncBody<List<api.Member>>(
              value: members,
              onRetry: () => ref.invalidate(membersProvider),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: l.membersEmpty,
              builder: (context, data) => ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [for (final m in data) _MemberTile(member: m)],
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
    return ListTile(
      key: Key('member-${member.personId}'),
      title: Text(member.displayName),
      subtitle: Text(
        [if (member.email != null) member.email!, rolesText(member.roles, l)].join(' · '),
      ),
      trailing: !member.active
          ? InfoChip(l.memberInactive, tone: ChipTone.bad)
          : member.invitationStatus == api.InvitationStatus.PENDING
          ? InfoChip(l.memberInvitationPending, tone: ChipTone.warn)
          : const Icon(Icons.chevron_right),
      onTap: () => context.go('/admin/members/${member.personId}'),
    );
  }
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
      onSubmit: () {
        return runAction(
          context,
          () => ref.read(membersProvider.notifier).invite(
            givenName: _given.text.trim(),
            familyName: _family.text.trim(),
            email: _email.text.trim(),
            roles: _roles,
          ),
          success: l.memberInvited,
        );
      },
      children: [
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
          validator: (v) => _emailPattern.hasMatch((v ?? '').trim()) ? null : l.fieldInvalidEmail,
        ),
        formGap,
        Text(l.memberRoles, style: Theme.of(context).textTheme.titleSmall),
        RolePicker(
          selected: _roles,
          onChanged: () => setState(() {}),
        ),
        if (_rolesTouched && _roles.isEmpty)
          Text(
            l.memberRolesRequired,
            key: const Key('roles-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

/// Multi-select of the five tenant roles; mutates [selected] in place.
class RolePicker extends StatelessWidget {
  const RolePicker({super.key, required this.selected, required this.onChanged});

  final Set<api.TenantRole> selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: AppTokens.spaceSm,
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.member;
    final theme = Theme.of(context);
    final isParent = m.roles.contains(api.TenantRole.PARENT);
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      children: [
        Text(m.displayName, style: theme.textTheme.titleLarge),
        if (m.email != null) Text(m.email!),
        if (!m.active) ...[
          const SizedBox(height: AppTokens.spaceSm),
          Align(alignment: Alignment.centerLeft, child: InfoChip(l.memberInactive, tone: ChipTone.bad)),
        ],
        const SizedBox(height: AppTokens.spaceLg),
        Text(l.memberRoles, style: theme.textTheme.titleMedium),
        RolePicker(selected: _roles, onChanged: () => setState(() {})),
        const SizedBox(height: AppTokens.spaceSm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: const Key('member-save-roles'),
            onPressed: _roles.isEmpty
                ? null
                : () => runAction(
                    context,
                    () => ref.read(membersProvider.notifier).replaceRoles(m.personId, {..._roles}),
                    success: l.saved,
                  ),
            child: Text(l.memberEditRoles),
          ),
        ),
        const SizedBox(height: AppTokens.spaceLg),
        Text(l.memberGuardianLinks, style: theme.textTheme.titleMedium),
        if (isParent)
          GuardianLinksEditor(guardianPersonId: m.personId)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
            child: Text(l.memberGuardianOnlyParents, style: theme.textTheme.bodySmall),
          ),
        if (m.active) ...[
          const SizedBox(height: AppTokens.spaceLg),
          OutlinedButton.icon(
            key: const Key('member-deactivate'),
            icon: const Icon(Icons.person_off_outlined),
            label: Text(l.memberDeactivate),
            onPressed: () async {
              if (!await confirmDialog(context, message: l.memberDeactivateConfirm(m.displayName))) return;
              if (!context.mounted) return;
              await runAction(
                context,
                () => ref.read(membersProvider.notifier).deactivate(m.personId),
                success: l.memberDeactivated,
              );
            },
          ),
        ],
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
          onRetry: () => ref.invalidate(guardianLinksProvider(guardianPersonId)),
          builder: (context, data) => data.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
                  child: Text(l.memberGuardianNone, key: const Key('guardian-none')),
                )
              : Column(
                  children: [
                    for (final link in data)
                      ListTile(
                        key: Key('link-${link.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(link.player.displayName),
                        trailing: IconButton(
                          tooltip: l.remove,
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            if (!await confirmDialog(
                              context,
                              message: l.memberGuardianRemoveConfirm(link.player.displayName),
                            )) {
                              return;
                            }
                            if (!context.mounted) return;
                            await runAction(
                              context,
                              () => ref.read(guardianLinksProvider(guardianPersonId).notifier).remove(link.id),
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
            builder: (_) => _PickPlayerDialog(guardianPersonId: guardianPersonId),
          ),
        ),
      ],
    );
  }
}

/// Like [AsyncBody] but sized for embedding in a scrolling column.
class AsyncBodyInline<T> extends StatelessWidget {
  const AsyncBodyInline({super.key, required this.value, required this.builder, required this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = value.value;
    if (data != null) return builder(context, data);
    if (value.hasError) {
      return TextButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).retry));
    }
    return const Padding(
      padding: EdgeInsets.all(AppTokens.spaceMd),
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
  late Future<List<api.Player>> _players = ref.read(playersRepositoryProvider).list();

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
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.playersSearchHint),
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
                  if (players == null) return const Center(child: CircularProgressIndicator());
                  return ListView(
                    children: [
                      for (final p in players)
                        ListTile(
                          key: Key('pick-player-${p.id}'),
                          title: Text(p.displayName),
                          onTap: () async {
                            final ok = await runAction(
                              context,
                              () => ref
                                  .read(guardianLinksProvider(widget.guardianPersonId).notifier)
                                  .add(p.id),
                            );
                            if (ok && context.mounted) Navigator.of(context).pop();
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
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.close))],
    );
  }
}
