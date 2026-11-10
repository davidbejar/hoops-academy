import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_screen.dart' show TenantStatusChip;

/// How long typing pauses before the search runs.
const usersSearchDebounce = Duration(milliseconds: 350);

/// The Users area of the application admin (WP99): every login with its
/// memberships per academy; a membership opens that academy's detail.
class PlatformUsersScreen extends ConsumerStatefulWidget {
  const PlatformUsersScreen({super.key});

  @override
  ConsumerState<PlatformUsersScreen> createState() =>
      _PlatformUsersScreenState();
}

class _PlatformUsersScreenState extends ConsumerState<PlatformUsersScreen> {
  Timer? _debounce;
  late final TextEditingController _search = TextEditingController(
    text: ref.read(usersQueryProvider).text,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      usersSearchDebounce,
      () => ref.read(usersQueryProvider.notifier).search(text),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tooShort =
        _search.text.trim().isNotEmpty &&
        _search.text.trim().length < minUsersQueryLength;
    return Guarded(
      allowed: ref.watch(isSuperAdminProvider),
      child: Scaffold(
        body: Column(
          children: [
            ContentFrame(
              child: Padding(
                padding: const EdgeInsets.only(top: HoopsSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: HoopsSpace.gap,
                  children: [
                    PageHeader(title: l.usersTitle),
                    TextField(
                      key: const Key('users-search'),
                      controller: _search,
                      maxLength: maxUsersQueryLength,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.usersSearchHint,
                        helperText: tooShort ? l.usersSearchTooShort : null,
                        counterText: '',
                        isDense: true,
                      ),
                      onChanged: _onChanged,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AsyncBody<api.PlatformUserPage>(
                value: ref.watch(platformUsersProvider),
                onRetry: () => ref.invalidate(platformUsersProvider),
                isEmpty: (p) => p.items.isEmpty,
                emptyMessage: l.usersEmpty,
                builder: (context, page) => PageBody(
                  children: [
                    Column(
                      spacing: HoopsSpace.gap,
                      children: [
                        for (final user in page.items) _UserCard(user),
                        _Pager(page: page.page),
                        const SizedBox(height: HoopsSpace.sm),
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

class _UserCard extends StatelessWidget {
  const _UserCard(this.user);

  final api.PlatformUser user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final email = user.email;
    final name = _nameOf(user);
    return SectionCard(
      key: Key('user-${user.id}'),
      padding: const EdgeInsets.symmetric(vertical: HoopsSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HoopsSpace.md,
              vertical: HoopsSpace.xs,
            ),
            child: Row(
              spacing: HoopsSpace.gap,
              children: [
                InitialsAvatar(name: name ?? email ?? '?'),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name != null) Text(name, style: text.titleMedium),
                      Text(
                        email ?? l.usersNoEmail,
                        style: text.bodyMedium!.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user.memberships.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HoopsSpace.md,
                vertical: HoopsSpace.xs,
              ),
              child: Text(
                l.usersNoMemberships,
                style: text.bodyMedium!.copyWith(color: c.inkMuted),
              ),
            ),
          for (final m in user.memberships) _MembershipRow(user: user, m: m),
        ],
      ),
    );
  }
}

/// The login's name: the person's name in its first academy (a login has no
/// name of its own; the e-mail is the fallback).
String? _nameOf(api.PlatformUser user) {
  if (user.memberships.isEmpty) return null;
  final m = user.memberships.first;
  return '${m.givenName} ${m.familyName}'.trim();
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({required this.user, required this.m});

  final api.PlatformUser user;
  final api.PlatformUserMembership m;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final roles = [for (final r in m.roles) r.label(l)].join(', ');
    return InkWell(
      key: Key('user-${user.id}-${m.tenantId}'),
      onTap: () => context.go('/app-admin/academies/${m.tenantId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HoopsSpace.md,
          vertical: HoopsSpace.sm,
        ),
        child: Row(
          spacing: HoopsSpace.gap,
          children: [
            Icon(Icons.apartment_outlined, color: c.inkMuted, size: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.tenantName, style: text.titleSmall),
                  Text(
                    roles,
                    style: text.bodySmall!.copyWith(color: c.inkMuted),
                  ),
                  if (!m.active ||
                      m.tenantStatus != api.TenantStatus.ACTIVE) ...[
                    const SizedBox(height: HoopsSpace.xs),
                    Wrap(
                      spacing: HoopsSpace.xs,
                      children: [
                        if (!m.active) StatusChip(l.usersInactiveMember),
                        if (m.tenantStatus != api.TenantStatus.ACTIVE)
                          TenantStatusChip(m.tenantStatus),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.page});

  final api.PageMeta page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.totalPages <= 1) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final notifier = ref.read(usersQueryProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('users-prev'),
          tooltip: l.auditPreviousPage,
          icon: const Icon(Icons.chevron_left),
          onPressed: page.page > 0
              ? () => notifier.goToPage(page.page - 1)
              : null,
        ),
        Text(l.auditPageOf(page.page + 1, page.totalPages)),
        IconButton(
          key: const Key('users-next'),
          tooltip: l.auditNextPage,
          icon: const Icon(Icons.chevron_right),
          onPressed: page.page + 1 < page.totalPages
              ? () => notifier.goToPage(page.page + 1)
              : null,
        ),
      ],
    );
  }
}
