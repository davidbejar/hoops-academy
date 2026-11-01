import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/destination_labels.dart';
import '../../core/session/session.dart';
import '../../core/session/session_providers.dart';
import '../../core/tenancy/tenant_selection.dart';
import '../../features/me/domain/current_user.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme.dart';

/// Lists the caller's academies (from `/me`) and stores the choice.
class TenantSwitcherScreen extends ConsumerWidget {
  const TenantSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final user = switch (session) {
      NeedsTenant(:final user) => user,
      Ready(:final user) => user,
      _ => null,
    };
    final activeId = ref.watch(activeTenantIdProvider);
    final memberships = user?.memberships ?? const <TenantMembership>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.switchAcademy),
        automaticallyImplyLeading: activeId != null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.maxContentWidth),
            child: ListView(
              key: const Key('tenant-list'),
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              children: [
                Text(
                  l.chooseAcademyTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTokens.spaceXs),
                Text(l.chooseAcademySubtitle),
                const SizedBox(height: AppTokens.spaceMd),
                for (final m in memberships)
                  Card(
                    child: ListTile(
                      key: Key('tenant-${m.tenantId}'),
                      leading: CircleAvatar(child: Text(_initial(m.tenantName))),
                      title: Text(m.tenantName),
                      subtitle: Text(
                        l.rolesInAcademy(
                          m.roles.map((r) => r.label(l)).join(', '),
                        ),
                      ),
                      trailing: m.tenantId == activeId
                          ? const Icon(Icons.check_circle)
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        await ref
                            .read(selectedTenantIdProvider.notifier)
                            .select(m.tenantId);
                        if (context.mounted) context.go('/');
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initial(String name) =>
      name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
}
